const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();

exports.sendNotification = onRequest(async (request, response) => {
  const {token, title, body, image} = request.body;

  // Check if the token and message content are provided
  if (!token || !title || !body) {
    return response.status(400).send("Missing fields: token, title, or body");
  }

  // Prepare the message payload
  const message = {
    notification: {
      title: title,
      body: body,
      image: image,
    }, data: {
      image,
    },
    token: token,
  };

  try {
    const responseFCM = await admin.messaging().send(message);
    logger.info("Notification sent successfully", {response: responseFCM});
    response.status(200).send("Notification sent successfully");
  } catch (error) {
    logger.error("Error sending notification", {error: error});
    response.status(500).send("Error sending notification");
  }
});
