const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

exports.sendEmailOtp = functions.https.onCall(async (data, context) => {
  const { email } = data;

  if (!email || !email.includes('@')) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid email address required.');
  }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 5 * 60 * 1000;

  await admin.firestore().collection('emailOtps').doc(email).set({
    code,
    expiresAt,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await transporter.sendMail({
    from: `"MediCare" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Your MediCare OTP',
    html: `
      <h1>Your OTP is <strong>${code}</strong></h1>
      <p>This code expires in 5 minutes.</p>
    `,
  });

  return { success: true };
});