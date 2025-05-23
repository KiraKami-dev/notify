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
      region: "us-central1",
    },
    async (data) => {
      logger.info("Task received", {data});
      const {token, title, body, image, taskId} = data;

      if (!token || !title || !body) {
        logger.error("Missing required fields in task data", {data});
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
  logger.info("Received schedule notification request", {
    body: req.body,
    headers: req.headers,
  });

  const {token, title, body, image, scheduledTime, taskId} = req.body;

  // Validate request body
  if (!req.body || typeof req.body !== "object") {
    logger.error("Invalid request body", {body: req.body});
    return res.status(400).send("Invalid request body");
  }

  // Log each field for debugging
  logger.info("Request fields", {
    token: token ? "present" : "missing",
    title: title ? "present" : "missing",
    body: body ? "present" : "missing",
    scheduledTime: scheduledTime ? "present" : "missing",
    taskId: taskId ? "present" : "missing",
  });

  if (!token || !title || !body || !scheduledTime) {
    logger.error("Missing required fields", {
      token: !!token,
      title: !!title,
      body: !!body,
      scheduledTime: !!scheduledTime,
    });
    return res.status(400).send("Missing required fields");
  }

  try {
    const queue = getFunctions().taskQueue("handleScheduledNotification", {
      region: "us-central1",
      extensionId: "",
    });

    // Parse the scheduled time and ensure it's in UTC
    const scheduledDate = new Date(scheduledTime);
    logger.info("Processing scheduled time", {
      original: scheduledTime,
      parsed: scheduledDate.toISOString(),
      utc: scheduledDate.toUTCString(),
    });

    // Validate the scheduled time
    if (isNaN(scheduledDate.getTime())) {
      logger.error("Invalid scheduled time format", {scheduledTime});
      return res.status(400).send("Invalid scheduled time format");
    }

    // Check if the time is in the future
    if (scheduledDate <= new Date()) {
      logger.error("Scheduled time must be in the future", {
        scheduledTime: scheduledDate.toISOString(),
        currentTime: new Date().toISOString(),
      });
      return res.status(400).send("Scheduled time must be in the future");
    }

    logger.info("Enqueueing task", {
      taskId,
      scheduledTime: scheduledDate.toISOString(),
      token,
    });

    const taskData = {
      token,
      title,
      body,
      image: image || "",
      taskId: taskId || "",
    };

    await queue.enqueue(taskData, {
      scheduleTime: scheduledDate,
    });

    logger.info("Task enqueued successfully", {
      taskId,
      scheduledTime: scheduledDate.toISOString(),
    });

    res.status(200).send("Notification task scheduled successfully");
  } catch (error) {
    logger.error("Error enqueuing task", {
      error: error.message,
      stack: error.stack,
      taskId,
      scheduledTime,
    });
    res.status(500).send("Failed to schedule notification");
  }
});
