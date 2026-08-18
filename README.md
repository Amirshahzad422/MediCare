# MediCare - Telemedicine Application

MediCare is a comprehensive, full-stack telemedicine application built using **Flutter**, **Firebase**, and **Riverpod**. It provides a complete digital healthcare ecosystem connecting patients with certified medical professionals.

This project was developed as a core deliverable for the **Verxeon Technologies Internship Program**.

## 🌟 Features

### 🧑‍⚕️ For Patients
- **Doctor Discovery:** Advanced search and filtering by specialty, city, availability, rating, and fee.
- **Appointment Booking:** Real-time slot selection with concurrency checks to prevent double bookings.
- **Secure Payments:** Integrated **Stripe** checkout for consultation fees.
- **Video Consultations:** High-quality, low-latency live video calls powered by **Agora WebRTC**.
- **Digital Prescriptions:** Receive downloadable PDF prescriptions directly after a consultation.
- **E-Pharmacy:** Browse medicines, add to cart, and order with real-time delivery tracking.
- **Real-Time Chat:** Instant messaging with doctors.

### 🩺 For Doctors
- **Professional Dashboard:** Manage daily schedules, upcoming appointments, and patient records.
- **Digital Prescription Builder:** Generate professional, formatted PDF prescriptions within the app.
- **Earnings & Reviews:** Track consultation earnings and read patient feedback.
- **Flexible Scheduling:** Define business hours and availability days.

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart) targeting Android, iOS, and Web.
- **State Management:** Flutter Riverpod.
- **Backend Services:** Firebase (Authentication, Cloud Firestore, Cloud Storage).
- **Video Calling:** Agora RTC Engine.
- **Payments:** Stripe API (flutter_stripe).
- **Push Notifications:** Firebase Cloud Messaging (FCM).
- **PDF Generation:** pdf and printing packages.

## 🗄️ Database Schema (Firestore)

- users: Core profile data (uid, 
ame, phone, 
ole: 1/2).
- doctors: Extended profile for doctors (specialty, fee, slots, businessStartHour, 
eviews).
- appointments: Consultation records (patientId, doctorId, status, date, slot, mount).
- chats & messages: Real-time text communication between users.
- medicines & orders: E-commerce catalog and patient orders.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.10.7 or higher)
- Firebase Project configured (Auth, Firestore, Storage)
- Agora App ID and Token Server (for Video Calls)
- Stripe Publishable and Secret Keys

### Installation

1. **Clone the repository:**
   `bash
   git clone https://github.com/verxeon-ai/MediCare.git
   cd MediCare
   `

2. **Install dependencies:**
   `bash
   flutter pub get
   `

3. **Configure Firebase:**
   - Place your google-services.json in android/app/.
   - Place your GoogleService-Info.plist in ios/Runner/.

4. **Run the App:**
   `bash
   flutter run
   `

## 🔐 Role-Based Access
MediCare uses a strict role-based routing mechanism (RoleGuard). 
- **Patient Role (1):** Redirected to the Patient Discovery Portal.
- **Doctor Role (2):** Redirected to the Doctor Management Dashboard.


