/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const axios = require("axios");
require("dotenv").config();


admin.initializeApp();

exports.notifyPostLiked = onDocumentWritten(
    "posts/{postId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;

      if (!before || !after) {
        return; // Skip if the document is newly created or deleted
      }

      // Check if the `likedBy` array was updated
      const beforeLikes = before.likedBy || [];
      const afterLikes = after.likedBy || [];

      if (afterLikes.length <= beforeLikes.length) {
        return; // No new like added
      }

      // Get the new liker
      const newLikeUserId = afterLikes[afterLikes.length - 1];

      // Get the post owner's userId
      const postOwnerId = after.userId;

      // Retrieve the post owner's FCM token
      const userCollection = admin.firestore().collection("users");
      const postOwnerDoc = await userCollection.doc(postOwnerId).get();
      const postOwnerData = postOwnerDoc.data();
      const fcmToken = postOwnerData && postOwnerData.fcmToken;

      if (!fcmToken) {
        console.error(`No FCM token found for user: ${postOwnerId}`);
        return;
      }

      // Retrieve the liker’s name
      const likerDoc = await userCollection.doc(newLikeUserId).get();
      const likerData = likerDoc.data();
      const likerName = likerData && likerData.name;

      if (!likerName) {
        console.error(`No name found for liker: ${newLikeUserId}`);
        return;
      }

      // Get the post's image URL
      const postImageUrl = getImageUrl(after.imageUrl);

      // Create the notification message with image
      const message = {
        token: fcmToken,
        notification: {
          title: `${likerName}`,
          body: `Liked your post!`,
          image: postImageUrl, // Adds the image to the notification
        },
      };

      // Send the notification
      try {
        await admin.messaging().send(message);
        console.log(`Notification sent to post owner: ${postOwnerId}`);
      } catch (error) {
        console.error("Error sending like notification:", error);
      }
    },
);

exports.notifyPostcommented = onDocumentWritten(
    "posts/{postId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;

      if (!before || !after) {
        return; // Skip if the document is newly created or deleted
      }

      // Check if the `comments` array was updated
      const beforeComments = before.comments || [];
      const afterComments = after.comments || [];

      if (afterComments.length <= beforeComments.length) {
        return; // No new comment added
      }

      // Get the new commenter
      const newComment = afterComments[afterComments.length - 1];
      const newCommenterUserId = afterComments[afterComments.length - 1].userId;

      // Get the post owner's userId
      const postOwnerId = after.userId;

      // Retrieve the post owner's FCM token
      const userCollection = admin.firestore().collection("users");
      const postOwnerDoc = await userCollection.doc(postOwnerId).get();
      const postOwnerData = postOwnerDoc.data();
      const fcmToken = postOwnerData && postOwnerData.fcmToken;

      if (!fcmToken) {
        console.error(`No FCM token found for user: ${postOwnerId}`);
        return;
      }

      // Retrieve the commenter's name
      const commenterDoc = await userCollection.doc(newCommenterUserId).get();
      const commenterData = commenterDoc.data();
      const commenterName = commenterData && commenterData.name;
      const comment = newComment.text;

      if (!commenterName) {
        console.error(`No name found for liker: ${newCommenterUserId}`);
        return;
      }

      // Get the post's image URL
      const postImageUrl = getImageUrl(after.imageUrl);

      // Create the notification message with image
      const message = {
        token: fcmToken,
        notification: {
          title: `${commenterName}`,
          body: `commented on your post: ${comment}`,
          image: postImageUrl, // Adds the image to the notification
        },
      };

      // Send the notification
      try {
        await admin.messaging().send(message);
        console.log(`Notification sent to post owner: ${postOwnerId}`);
      } catch (error) {
        console.error("Error sending like notification:", error);
      }
    },
);

/**
 * Cleans the image URL to ensure it ends with ?alt=media.
 * @param {string} postImageUrl - The original image URL from Firestore.
 * @return {string} - The cleaned image URL.
 */
function getImageUrl(postImageUrl) {
  if (postImageUrl.includes("?")) {
    return postImageUrl.split("?")[0] + "?alt=media";
  }
  return postImageUrl + "?alt=media";
}

exports.notifyFriendRequest = onDocumentCreated(
    "friendRequests/{requestId}",
    async (event) => {
      const data = event.data;
      console.log("Received Data:", data);
      const toUserId = data._fieldsProto.toUserId.stringValue;
      const fromUserName = data._fieldsProto.fromUserName.stringValue;
      console.log(toUserId);
      console.log(fromUserName);


      const userCollection = admin.firestore().collection("users");
      const userDoc = await userCollection.doc(toUserId).get();
      const userData = userDoc.data();
      const fcmToken = userData && userData.fcmToken;

      if (!fcmToken) {
        console.error(`No FCM token found for user: ${toUserId}`);
        return;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: "New Friend Request!",
          body: `${fromUserName} sent you a friend request.`,
        },
      };

      try {
        await admin.messaging().send(message);
        console.log(`Notification sent to user: ${toUserId}`);
      } catch (error) {
        console.error("Error sending friend request notification:", error);
      }
    });


exports.notifyPostLiked = onDocumentWritten(
    "posts/{postId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;

      if (!before || !after) {
        return; // Skip if the document is newly created or deleted
      }

      // Check if the `likedBy` array was updated
      const beforeLikes = before.likedBy || [];
      const afterLikes = after.likedBy || [];

      if (afterLikes.length <= beforeLikes.length) {
        return; // No new like added
      }

      // Get the new liker
      const newLikeUserId = afterLikes[afterLikes.length - 1];

      // Get the post owner's userId
      const postOwnerId = after.userId;

      // Retrieve the post owner's FCM token
      const userCollection = admin.firestore().collection("users");
      const postOwnerDoc = await userCollection.doc(postOwnerId).get();
      const postOwnerData = postOwnerDoc.data();
      const fcmToken = postOwnerData && postOwnerData.fcmToken;

      if (!fcmToken) {
        console.error(`No FCM token found for user: ${postOwnerId}`);
        return;
      }

      // Retrieve the liker’s name
      const likerDoc = await userCollection.doc(newLikeUserId).get();
      const likerData = likerDoc.data();
      const likerName = likerData && likerData.name;

      if (!likerName) {
        console.error(`No name found for liker: ${newLikeUserId}`);
        return;
      }

      // Get the post's image URL
      const postImageUrl = getImageUrl(after.imageUrl);

      // Create the notification message with image
      const message = {
        token: fcmToken,
        notification: {
          title: `${likerName}`,
          body: `Liked your post!`,
          image: postImageUrl, // Adds the image to the notification
        },
      };

      // Send the notification
      try {
        await admin.messaging().send(message);
        console.log(`Notification sent to post owner: ${postOwnerId}`);
      } catch (error) {
        console.error("Error sending like notification:", error);
      }
    },
);

exports.notifyFriendRequest = onDocumentWritten(
    "users/{userId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;

      if (!before || !after) {
        return; // Skip if the document is newly created or deleted
      }

      // Check if the friends array was updated
      const beforeFriends = before.friends || [];
      const afterFriends = after.friends || [];

      if (afterFriends.length <= beforeFriends.length) {
        return; // No new friend added
      }

      // Get the new friend
      const newFriendId = afterFriends[afterFriends.length - 1];

      // Get the userId of who is receiving the notification
      const currUser = after.userId;

      // Retrieve the post owner's FCM token
      const userCollection = admin.firestore().collection("users");
      const postOwnerDoc = await userCollection.doc(currUser).get();
      const postOwnerData = postOwnerDoc.data();
      const fcmToken = postOwnerData && postOwnerData.fcmToken;

      if (!fcmToken) {
        console.error(`No FCM token found for user: ${currUser}`);
        return;
      }

      // Retrieve the friend's name
      const friendDoc = await userCollection.doc(newFriendId).get();
      const friendData = friendDoc.data();
      const friendName = friendData && friendData.name;

      if (!friendName) {
        console.error(`No name found for liker: ${friendName}`);
        return;
      }

      // Create the notification
      const message = {
        token: fcmToken,
        notification: {
          title: `${friendName}`,
          body: `Accepted your follow request!`,
        },
      };

      // Send the notification
      try {
        await admin.messaging().send(message);
        console.log(`Notification sent to post owner: ${currUser}`);
      } catch (error) {
        console.error("Error sending like notification:", error);
      }
    },
);

exports.enrichRestaurant = onDocumentCreated(
    "posts/{postId}",
    async (event) => {
      const post = event.data.data();
      const {restaurantName, location, review} = post;

      if (!restaurantName) return;

      const restaurantId = restaurantName.toLowerCase().replace(/\s+/g, "_");
      const db = admin.firestore();
      const existingDoc = await db
          .collection("restaurants")
          .doc(restaurantId)
          .get();

      if (existingDoc.exists) return;

      // --- Google Places API ---
      let city = "";
      if (location && typeof location === "string" && location.includes(",")) {
        const [lat, lng] = location.split(",").map(parseFloat);

        try {
          const geoRes = await axios.get(
              `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${process.env.GOOGLE_API_KEY}`,
          );

          const addressComponents =
            (geoRes.data.results &&
              geoRes.data.results[0] &&
              geoRes.data.results[0].address_components) ||
            [];


          const cityComponent = addressComponents.find(
              (comp) =>
                comp.types.includes("locality") ||
                comp.types.includes("administrative_area_level_2"),
          );

          city = (cityComponent && cityComponent.long_name) || "";
        } catch (err) {
          console.error("Reverse geocoding failed:", err.message);
        }
      }

      const query = encodeURIComponent(restaurantName + " near " + city);


      const googleUrl = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${query}&key=${process.env.GOOGLE_API_KEY}`;

      let place = null;
      try {
        const googleRes = await axios.get(googleUrl);
        console.log("Google Places API result:",
            JSON.stringify(googleRes.data, null, 2));
        place = (googleRes.data.results && googleRes.data.results[0]) || null;
      } catch (err) {
        console.error("Google Places lookup failed:", err.message);
      }

      // --- OpenAI Tagging ---
      let tags = [];
      if (review) {
        try {
          const gptRes = await axios.post("https://api.openai.com/v1/chat/completions", {
            model: "gpt-3.5-turbo",
            messages: [
              {
                role: "system",
                content:
                    "Extract short, comma-separated keywords" +
                    "describing the restaurant's " +
                    "vibe or purpose from this review " +
                    "(e.g. romantic, beach, group-friendly, " +
                    "casual, rooftop).",
              },
              {
                role: "user",
                content: review,
              },
            ],
          }, {
            headers: {
              "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
              "Content-Type": "application/json",
            },
          });

          const tagText = gptRes.data.choices[0].message.content;
          tags = tagText
              .split(/[,|\n]/)
              .map((t) => t.trim().toLowerCase())
              .filter(Boolean);
        } catch (err) {
          console.error("OpenAI tag extraction failed:", err.message);
        }
      }

      // --- Save to Firestore under restaurants/{id} ---
      await db.collection("restaurants").doc(restaurantId).set({
        name: restaurantName,
        location: (place && place.geometry && place.geometry.location) || null,
        formattedAddress: (place && place.formatted_address) || "",
        googleRating: (place && place.rating) || null,
        priceLevel: (place && place.price_level) || null,
        tags,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Enriched and saved restaurant: ${restaurantName}`);
    },
);

exports.retagRestaurantOnUpdate = onDocumentWritten(
    "restaurants/{restaurantId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;

      if (
        !before ||
        !after ||
        JSON.stringify(before) === JSON.stringify(after)
      ) {
        return;
      }
      const {description} = after;
      if (!description) return;

      let tags = [];
      try {
        const gptRes = await axios.post("https://api.openai.com/v1/chat/completions", {
          model: "gpt-3.5-turbo",
          messages: [{
            role: "system",
            content: "Extract short, comma-separated keywords describing "+
            "a restaurant based on its description.",
          }, {
            role: "user",
            content: description,
          }],
        }, {
          headers: {
            "Authorization": `Bearer ${process.env.OPENAI_API_KEY}`,
            "Content-Type": "application/json",
          },
        });

        const text = gptRes.data.choices[0].message.content;
        tags = text
            .split(/[,|\n]/)
            .map((t) => t.trim().toLowerCase())
            .filter(Boolean);
      } catch (err) {
        console.error("OpenAI re-tagging failed:", err.message);
      }

      await admin
          .firestore()
          .collection("restaurants")
          .doc(event.params.restaurantId)
          .update({
            tags,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
    },
);
