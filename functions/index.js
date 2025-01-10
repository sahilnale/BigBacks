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
const admin = require("firebase-admin");

admin.initializeApp();

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
