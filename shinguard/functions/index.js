const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");
const {setGlobalOptions} = require("firebase-functions/v2");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

initializeApp();
setGlobalOptions({region: "us-central1", maxInstances: 10});

const invalidTokenCodes = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

exports.sendFriendRequestNotification = onDocumentCreated(
  "users/{recipientUid}/friendRequests/{senderUid}",
  async (event) => {
    const request = event.data;
    if (!request) {
      logger.warn("Friend request event did not include a document.", {
        eventId: event.id,
      });
      return;
    }

    const {recipientUid, senderUid} = event.params;
    const requestData = request.data();
    const senderName = String(requestData.fromUsername || "A ShinPulse athlete");
    const tokenSnapshot = await getFirestore()
      .collection("users")
      .doc(recipientUid)
      .collection("fcmTokens")
      .get();
    const registrations = tokenSnapshot.docs
      .map((document) => ({
        document,
        token: document.get("token"),
      }))
      .filter(({token}) => typeof token === "string" && token.length > 0);

    if (registrations.length === 0) {
      await request.ref.set(
        {
          notificationStatus: "no-registered-devices",
          notificationUpdatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
      logger.info("Friend request stored without a push target.", {
        recipientUid,
        senderUid,
      });
      return;
    }

    const response = await getMessaging().sendEachForMulticast({
      tokens: registrations.map(({token}) => token),
      notification: {
        title: "New friend request",
        body: `${senderName} wants to connect with you.`,
      },
      data: {
        type: "friend_request",
        senderUid,
        route: "contacts",
      },
      android: {
        priority: "high",
        collapseKey: `friend-request-${senderUid}`,
        notification: {
          channelId: "friend_requests",
          tag: `friend-request-${senderUid}`,
          sound: "default",
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-collapse-id": `friend-request-${senderUid}`,
        },
        payload: {
          aps: {
            sound: "default",
            threadId: "friend-requests",
          },
        },
      },
    });

    const cleanup = [];
    response.responses.forEach((result, index) => {
      if (!result.success && invalidTokenCodes.has(result.error?.code)) {
        cleanup.push(registrations[index].document.ref.delete());
      }
    });
    await Promise.all(cleanup);
    await request.ref.set(
      {
        notificationStatus: response.successCount > 0 ? "sent" : "failed",
        notificationSuccessCount: response.successCount,
        notificationFailureCount: response.failureCount,
        notificationUpdatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    logger.info("Friend request push processed.", {
      recipientUid,
      senderUid,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  },
);
