const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const {getFunctions} = require("firebase-admin/functions");
const {onTaskDispatched} = require("firebase-functions/v2/tasks");

admin.initializeApp();

exports.sendNotification = onRequest(async (request, response) => {
  const {token, title, body, image} = request.body;

  if (!token || !title || !body) {
    return response.status(400).send("Missing fields: token, title, or body");
  }

  const message = {
    notification: {
      title,
      body,
      image,
    },
    data: {
      image: image || "",
    },
    token,
  };

  try {
    const responseFCM = await admin.messaging().send(message);
    logger.info("Notification sent successfully", {response: responseFCM});
    response.status(200).send("Notification sent successfully");
  } catch (error) {
    logger.error("Error sending notification", {error});
    response.status(500).send("Error sending notification");
  }
});

// Function to handle scheduled notifications
exports.handleScheduledNotification = onTaskDispatched(
    {
      retryConfig: {
        maxAttempts: 5,
        minBackoffSeconds: 60,
      },
      rateLimits: {
        maxConcurrentDispatches: 10,
      },
    },
    async (data) => {
      const {token, title, body, image, taskId} = data;

      if (!token || !title || !body) {
        throw new Error("Missing required fields");
      }

      const message = {
        notification: {
          title,
          body,
          image,
        },
        data: {
          taskId: taskId || "",
          image: image || "",
        },
        token,
      };

      try {
        const responseFCM = await admin.messaging().send(message);
        logger.info("Scheduled notification sent successfully", {
          taskId,
          response: responseFCM,
        });
      } catch (error) {
        logger.error("Error sending scheduled notification", {
          taskId,
          error,
        });
        throw new Error("Notification dispatch failed");
      }
    },
);

// Function to schedule notifications
exports.scheduleNotification = onRequest(async (req, res) => {
  const {token, title, body, image, scheduledTime, taskId} = req.body;

  if (!token || !title || !body || !scheduledTime) {
    return res.status(400).send("Missing required fields");
  }

  try {
    const queue = getFunctions().taskQueue("handleScheduledNotification");

    await queue.enqueue(
        {token, title, body, image, taskId},
        {
          scheduleTime: new Date(scheduledTime),
        },
    );

    res.status(200).send("Notification task scheduled successfully");
  } catch (error) {
    logger.error("Error enqueuing task", {error});
    res.status(500).send("Failed to schedule notification");
  }
},
);
