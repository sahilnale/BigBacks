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


exports.notifyFriendAccepted = onDocumentWritten(
    "users/{userId}",
    async (event) => {
      const before = event.data.before.exists ? event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;

      if (!before || !after) {
        console.log("Skipped: document created or deleted");
        return;
      }

      const beforeFriends = before.friends || [];
      const afterFriends = after.friends || [];

      if (afterFriends.length <= beforeFriends.length) {
        console.log("Skipped: no new friend added");
        return;
      }

      const beforeSet = new Set(beforeFriends);
      const newFriendId = afterFriends.find((id) => !beforeSet.has(id));

      if (!newFriendId) {
        console.log("No new friend detected");
        return;
      }

      const currUser = event.params.userId;
      console.log("Friend accepted:", currUser, "added", newFriendId);

      const userCollection = admin.firestore().collection("users");

      const postOwnerDoc = await userCollection.doc(currUser).get();
      const postOwnerData = postOwnerDoc.data();
      const fcmToken = postOwnerData && postOwnerData.fcmToken;

      if (!fcmToken) {
        console.log("No FCM token for:", currUser);
        return;
      }

      const friendDoc = await userCollection.doc(newFriendId).get();
      const friendData = friendDoc.data();
      const friendName = friendData && friendData.name;

      if (!friendName) {
        console.log("No name found for new friend:", newFriendId);
        return;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: `${friendName}`,
          body: `Accepted your follow request!`,
        },
      };

      try {
        await admin.messaging().send(message);
        console.log("✅ Notification sent to:", currUser);
      } catch (err) {
        console.error("❌ Error sending notification:", err);
      }
    },
);


exports.notifyFriendRequest = onDocumentCreated(
    "friendRequests/{requestId}",
    async (event) => {
      console.log("✅ notifyFriendRequest triggered!");
      const data = event.data && event.data.data();
      console.log("📦 Raw event data:", data);

      if (!data) {
        console.warn("❗ No data in event");
        return;
      }

      const toUserId = data.toUserId;
      const fromUserName = data.fromUserName;

      console.log(`Friend request sent to: ${toUserId} from: ${fromUserName}`);

      if (!toUserId || !fromUserName) {
        console.warn("❗ Missing required fields: toUserId or fromUserName");
        return;
      }

      // Lookup user
      const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(toUserId)
          .get();
      const userData = userDoc.data();
      const fcmToken = userData && userData.fcmToken;

      if (!fcmToken) {
        console.warn(`No FCM token for user: ${toUserId}`);
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
      } catch (err) {
        console.error("Error sending notification:", err);
      }
    },
);


exports.notifyFriendsOnNewPost = onDocumentCreated(
    "posts/{postId}",
    async (event) => {
      const post = event.data.data();
      const userId = post.userId;
      const postImageUrl = getImageUrl(post.imageUrl);

      const userCollection = admin.firestore().collection("users");
      const userDoc = await userCollection.doc(userId).get();
      const userData = userDoc.data();
      const userName = userData && userData.name;
      const friends = (userData && userData.friends) || [];

      if (!userName || friends.length === 0) return;

      for (const friendId of friends) {
        const friendDoc = await userCollection.doc(friendId).get();
        const friendData = friendDoc.data();
        const fcmToken = friendData && friendData.fcmToken;

        if (!fcmToken) continue;

        const message = {
          token: fcmToken,
          notification: {
            title: `${userName} posted!`,
            body: `Check out their new post.`,
            image: postImageUrl,
          },
        };

        try {
          await admin.messaging().send(message);
          console.log(`Post notification sent to: ${friendId}`);
        } catch (err) {
          console.error(`Error sending post notification to ${friendId}:`, err);
        }
      }
    },
);
