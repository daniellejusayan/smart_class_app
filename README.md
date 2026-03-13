# smart_class_app# Smart Class Check-in & Learning Reflection App

## Project Description

This project is a prototype mobile application built using Flutter that allows students to check in to class and reflect on their learning experience.

The system verifies attendance using GPS location and QR code scanning while also collecting short reflections from students before and after class.

---

## Features

• Class check-in using QR code scanning
• GPS location verification
• Pre-class reflection form
• Post-class learning reflection
• Local data storage using SQLite
• Firebase hosting for deployment

---

## Tech Stack

Flutter
Dart
mobile_scanner (QR scanning)
geolocator (GPS location)
sqflite (local database)
shared_preferences (local storage)
Firebase Hosting

---

## Project Structure

lib/

main.dart
screens/
home_screen.dart
checkin_screen.dart
finish_class_screen.dart

services/
location_service.dart
database_service.dart

models/
attendance_model.dart

---

## Setup Instructions

1. Install Flutter
2. Clone the repository

git clone <repository-url>

3. Navigate to project folder

cd smart_class_app

4. Install dependencies

flutter pub get

5. Run the application

flutter run

---

## Firebase Deployment

Firebase Hosting is used to deploy a web page for the system.

Deployment steps:

firebase login
firebase init hosting
firebase deploy

---

## Notes

This project is an MVP prototype designed for demonstration purposes.
Data is stored locally on the device and not yet synchronized with a cloud database.

---
