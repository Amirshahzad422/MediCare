const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();

exports.onAppointmentCreated = functions.firestore
  .document('appointments/{appId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { doctorId, patientId, doctorName, patientName, date, slot } = data;

    const patientMsg = `Your appointment with ${doctorName || 'your doctor'} on ${date} at ${slot} is confirmed.`;
    const doctorMsg = `New appointment booked by ${patientName || 'a patient'} on ${date} at ${slot}.`;

    await sendNotificationToUser(patientId, 'Appointment Confirmed', patientMsg, 'appointment');
    await sendNotificationToUser(doctorId, 'New Appointment', doctorMsg, 'appointment');
  });

exports.onAppointmentUpdated = functions.firestore
  .document('appointments/{appId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    const { doctorId, patientId, doctorName, patientName, date, slot } = after;

    if (before.status !== after.status) {
      if (after.status === 2) {
        // Completed
        await sendNotificationToUser(patientId, 'Appointment Completed', `Your consultation with ${doctorName || 'your doctor'} is complete. Please leave a review!`, 'appointment');
        await sendNotificationToUser(doctorId, 'Appointment Completed', `Consultation with ${patientName || 'a patient'} marked as complete.`, 'appointment');
      } else if (after.status === 3) {
        // Cancelled
        await sendNotificationToUser(patientId, 'Appointment Cancelled', `Your appointment with ${doctorName || 'your doctor'} was cancelled.`, 'appointment');
        await sendNotificationToUser(doctorId, 'Appointment Cancelled', `Appointment with ${patientName || 'a patient'} was cancelled.`, 'appointment');
      }
    } else if (before.date !== after.date || before.slot !== after.slot) {
      // Rescheduled
      await sendNotificationToUser(patientId, 'Appointment Rescheduled', `Your appointment with ${doctorName || 'your doctor'} is now on ${date} at ${slot}.`, 'appointment');
      await sendNotificationToUser(doctorId, 'Appointment Rescheduled', `Appointment with ${patientName || 'a patient'} rescheduled to ${date} at ${slot}.`, 'appointment');
    }
  });

exports.onPrescriptionCreated = functions.firestore
  .document('prescriptions/{prescriptionId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { patientId, doctorName } = data;

    const patientMsg = `${doctorName || 'Your doctor'} has written a new prescription for you.`;
    await sendNotificationToUser(patientId, 'New Prescription', patientMsg, 'prescription');
  });

exports.onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { patientId, orderNo } = data;

    const msg = `Your order #${orderNo} has been placed successfully.`;
    await sendNotificationToUser(patientId, 'Order Placed', msg, 'order');
  });

exports.onOrderUpdated = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== after.status) {
      const { patientId, orderNo, status } = after;
      const msg = `Your order #${orderNo} status has been updated to: ${status}.`;
      await sendNotificationToUser(patientId, 'Order Update', msg, 'order');
    }
  });

exports.onReviewCreated = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { doctorId, patientName, rating } = data;

    const doctorMsg = `${patientName || 'A patient'} left you a ${rating}-star review.`;
    await sendNotificationToUser(doctorId, 'New Review', doctorMsg, 'review');
  });

async function sendNotificationToUser(userId, title, body, type) {
  if (!userId) return;

  await admin.firestore().collection('users').doc(userId).collection('notifications').add({
    title,
    body,
    type,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  if (userDoc.exists) {
    const token = userDoc.data().fcmToken;
    if (token) {
      try {
        await admin.messaging().send({
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: type,
          }
        });
        console.log(`Push sent to ${userId}`);
      } catch (error) {
        console.error('Error sending push:', error);
      }
    }
  }
}