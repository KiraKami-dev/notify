const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

exports.sendNotification = onRequest(async (request, response) => {
  const {token, title, body} = request.body;

  // Check if the token and message content are provided
  if (!token || !title || !body) {
    return response.status(400).send("Missing required fields: token, title, or body");
  }

  // Prepare the message payload
  const message = {
    notification: {
      title: title,
      body: body
    },
    token: token // The FCM token of the device you want to send the notification to
  };

  try {
    // Send the notification
    const responseFCM = await admin.messaging().send(message);
    logger.info("Notification sent successfully", {response: responseFCM});
    response.status(200).send("Notification sent successfully");
  } catch (error) {
    logger.error("Error sending notification", {error: error});
    response.status(500).send("Error sending notification");
  }
});
