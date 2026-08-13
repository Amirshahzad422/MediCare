# MediCare — Full-Stack Telemedicine App

> A production-level telemedicine Flutter app connecting patients with certified doctors.
> Built with Flutter · Firebase · Riverpod

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter (Dart) |
| State Management | Flutter Riverpod |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| PDF | pdf + printing packages |
| Camera | camera package |
| Image Picker | image_picker package |

---

## Setup

### 1. Install
```
flutter pub get
```

### 2. Firebase
google-services.json (Android) and firebase_options.dart are already configured.

### 3. Run
```
flutter run
```

---

## Patient Journey

1. Register as Patient ? OTP ? land on Home
2. Home: browse specialty chips, featured doctors, testimonials
3. Find Doctor: filter by specialty, city, fee, rating
4. Book: pick date + slot + type
5. Pay: promo codes MEDICARE10 (10 off), FIRST20 (20 off)
6. Appointments: join call, reschedule, cancel
7. Video Call: both parties join shared Firestore room ? LIVE ? in-call chat
8. Prescriptions: view medicine list, download PDF
9. Pharmacy: order medicines from prescription
10. Profile: tap camera icon to upload photo (no URL needed)

## Doctor Journey

1. Register as Doctor ? complete profile (specialty, fee, photo)
2. Dashboard > Today: see today's appointments ? Join Consultation button
3. Dashboard > Schedule: toggle availability, see slots
4. Dashboard > Earnings: total earnings, patients seen
5. Dashboard > Records: all issued prescriptions
6. FAB: Write Prescription ? patient name, diagnosis, medicines, notes ? Issue

## Simultaneous Video Call Architecture

Patient taps Join ? Firestore call room created (status: ringing)
Doctor taps Join  ? room updated (status: connected)
Both stream watchCall() ? both see LIVE status
Both stream watchMessages() ? real-time shared chat
Either ends call ? Firestore updated ? both get end dialog

## Promo Codes

- MEDICARE10 = 10 USD off
- FIRST20    = 20 USD off (first-time patients)

## Firestore Collections

| Collection | Purpose |
|---|---|
| users | Patient and Doctor profiles |
| doctors | Doctor listings |
| appointments | All bookings |
| prescriptions | Issued prescriptions |
| calls | Call room state |
| calls/{id}/messages | In-call chat |
| orders | Pharmacy orders |
