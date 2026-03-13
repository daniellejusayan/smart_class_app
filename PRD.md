# Product Requirement Document (PRD)
## Smart Class Check-in & Learning Reflection App

---

# 1. Problem Statement

Universities need a reliable way to confirm that students are physically present in class and actively participating in the learning process.

Traditional attendance methods such as manual roll calls or sign-in sheets are inefficient and vulnerable to proxy attendance. Additionally, instructors have limited insight into student learning experiences during class.

This project aims to develop a simple mobile application that allows students to check in to class using GPS and QR code verification while also submitting learning reflections before and after the class session.

The application ensures that students are physically present and encourages engagement by asking them to reflect on their learning expectations and outcomes.

---

# 2. Target Users

Primary Users:
- University students attending in-person classes

Secondary Users:
- Instructors who want reliable attendance tracking
- University administrators monitoring student participation

---

# 3. Product Goals

The system should:

1. Verify student presence in the classroom
2. Record attendance with time and location
3. Prevent remote or proxy attendance
4. Encourage students to reflect on learning
5. Store attendance and reflection data for review

---

# 4. Core Features

## 4.1 Class Check-in (Before Class)

Students must complete the following steps before class begins:

1. Press **Check-in button**
2. Application captures:
   - GPS location
   - Current timestamp
3. Student scans the **class QR code**
4. Student completes reflection form:
   - Topic covered in previous class
   - Expected topic for today's class
   - Mood before class (1–5 scale)

The check-in is saved locally in the device database.

---

## 4.2 Class Completion (After Class)

At the end of the class session students must:

1. Press **Finish Class**
2. Scan the **QR code again**
3. Record GPS location
4. Complete reflection form:
   - What they learned today
   - Feedback about the class or instructor

This information is stored together with the original check-in record.

---

# 5. User Flow

### Step 1 – Open App
User launches the application.

### Step 2 – Home Screen
User sees two main options:

- Check-in
- Finish Class

### Step 3 – Check-in Flow
1. Tap **Check-in**
2. System retrieves GPS location
3. Student scans QR code
4. Student fills reflection form
5. Data is saved

### Step 4 – Finish Class Flow
1. Tap **Finish Class**
2. Student scans QR code again
3. System records GPS location
4. Student submits learning reflection
5. Data is saved

---

# 6. Data Fields

The application stores the following information.

## Check-in Data

| Field | Type |
|------|------|
| student_id | String |
| checkin_time | Timestamp |
| checkin_location | GPS Coordinates |
| qr_code_value | String |
| previous_topic | Text |
| expected_topic | Text |
| mood | Integer (1-5) |

## Class Completion Data

| Field | Type |
|------|------|
| checkout_time | Timestamp |
| checkout_location | GPS Coordinates |
| qr_code_value | String |
| learned_today | Text |
| feedback | Text |

---

# 7. System Architecture

The application consists of the following components:

### Mobile App
Flutter mobile application for student interaction.

### Local Storage
SQLite database or local storage used to store attendance and reflection data on the device.

### Firebase Hosting
A deployed web component used for:
- Landing page
- Demo interface
- Optional data viewer

---

# 8. Tech Stack

| Layer | Technology |
|------|------------|
| Mobile Framework | Flutter |
| Programming Language | Dart |
| QR Code Scanner | mobile_scanner package |
| Location Service | geolocator package |
| Local Database | SQLite / sqflite |
| Backend Hosting | Firebase Hosting |
| Version Control | GitHub |

---

# 9. Minimum Screens (MVP)

The application includes the following screens:

1. Home Screen  
   - Navigation to check-in or finish class

2. Check-in Screen  
   - QR Scanner  
   - Reflection Form  
   - Mood selection  

3. Finish Class Screen  
   - QR Scanner  
   - Learning reflection form  

---

# 10. Non-Functional Requirements

- The app should load within 3 seconds
- Location must be retrieved within 5 seconds
- User interface must be simple and easy to use
- Data should persist locally even if the app closes

---

# 11. Future Improvements

Potential enhancements include:

- Cloud database integration with Firebase Firestore
- Instructor dashboard to view attendance
- Student authentication system
- Attendance analytics
- Push notifications for class reminders

---