# Midterm Lab Exam  
Course: Mobile Application Development
1305216 Mobile Application Development
Score: 10% Raw score

**Duration:** 3 Hours  
**Type:** Individual Lab Exam  

---

# Exam Title

**Smart Class Check-in & Learning Reflection App**

---

# Scenario

A university wants to build a simple **mobile application** that allows students to **check in to class** and **reflect on their learning experience**.

The system must help confirm that:

- Students are **physically present in the classroom**
- Students **participated in the class session**

To achieve this, the system will use:

- **GPS Location**
- **QR Code scanning**
- **Student learning reflection**

You will design and implement a **prototype mobile application using Flutter** and integrate it with **Firebase**.

---

# Draft Requirements

You are given **incomplete draft requirements**.  

Your task is to:

1. Interpret the requirements
2. Define missing details
3. Write a **Product Requirement Spec**
4. Use **AI tools if needed** to help build the system

---

# System Features

## 1. Class Check-in (Before Class)

Students must perform the following steps:

1. Press **Check-in**
2. The system records:
   - GPS Location
   - Timestamp
3. Scan the **class QR Code** or other solutions

Students **must** then fill in the following information:

- What topic was covered in the **previous class**
- What topic they **expect to learn today**
- Their **mood before class**

Mood scale:

| Score | Mood |
|------|------|
| 1 | 😡 Very negative |
| 2 | 🙁 Negative |
| 3 | 😐 Neutral |
| 4 | 🙂 Positive |
| 5 | 😄 Very positive |

---

## 2. Class Completion (After Class)

At the end of the class, students must:

1. Press **Finish Class**
2. Scan the **QR Code again**
3. Record **GPS location**

Students must also fill in:

- **What they learned today** (short text)
- **Feedback** about the class or the instructor

---

# Your Tasks

You must complete the following parts.

---

# Part 1 — Product Requirement Document (PRD)

Before coding, write a **short Product Requirement Document** describing the system.

Include at least:

- Problem Statement
- Target User
- Feature List
- User Flow
- Data Fields
- Tech Stack

Length guideline:

**~1 page**

You may write in **Markdown (.md)**.

---

# Part 2 — Mobile Application (Flutter)

Develop a **Flutter application (MVP)** that implements the system.

Minimum screens:

1. Home Screen
2. Check-in Screen
3. Finish Class Screen

Minimum functionality:

- Get **GPS location**
- **Scan QR Code or others**
- **Form input**
- Save data

---

# Part 3 — Data Storage

The system must be able to **store check-in and check-out data**.
- Use localStorage or SQLite for MVP version

---

# Part 4 — Deployment

Deploy at least **one component** using **Firebase Hosting**.

Examples:

- Flutter Web version
- Demo page that reads Firebase data
- Landing page for your app

The deployed URL must be accessible.

---

# Deliverables

Submit the following:

### 1. Product Requirement Document
Format:

- Markdown (.md)

---

### 2. Source Code

Upload to:

**GitHub Repository**

---

### 3. Firebase Deployment

Submit:

- Firebase URL

---

### 4. README

Your repository must include a README containing:

- Project description
- Setup instructions
- How to run the app
- Firebase configuration notes

---

### 5. AI Usage Report (Short)

Briefly explain:

- What AI tools you used
- What AI helped you generate
- What you modified or implemented yourself

Example:
AI was used to generate Flutter UI scaffolding and QR scanner integration.
I modified the form validation and Firebase data structure manually.

---

# Suggested Time Allocation

| Task | Time |
|-----|-----|
Requirement Analysis + PRS | 30 min |
Flutter Development | 90 min |
Firebase Integration | 30 min |
Deployment + README | 30 min |

Total:

**180 minutes**

---

# Allowed Resources

You are allowed to use:

- AI tools (ChatGPT, Gemini, Claude, Github Copilot etc.)
- Official documentation
- Flutter / Firebase libraries

However:

You **must understand and be able to explain your solution**.

The instructor may ask questions about your implementation.

---

# Important Notes

This exam evaluates more than coding.

It measures your ability to:

- Interpret requirements
- Design a simple system
- Use AI effectively
- Build a working prototype
- Deploy software

Focus on **shipping a working system**, not perfection.

---

# Academic Integrity

- Work must be **individual**
- Copying from other students is **not allowed**
- AI assistance is allowed but must be **acknowledged**

Failure to explain your work may result in **score reduction**.

---

# Good Luck 🚀

Think like a **software engineer building a real product**.




# Midterm Lab Rubric  
## Smart Class Check-in & Learning Reflection App

Total Score: **100 points**

---

# 1. Requirement Analysis & Product Spec (15 pts)

| Score | Criteria |
|------|---------|
| 13–15 | Clear understanding of the problem. PRS is well structured with clear features, user flow, and system idea. |
| 9–12 | Mostly clear requirement interpretation, but some details missing. |
| 5–8 | Basic understanding but PRS is incomplete or unclear. |
| 0–4 | Misinterprets the problem or PRS is largely missing. |

---

# 2. System Design (10 pts)

| Score | Criteria |
|------|---------|
| 8–10 | Logical user flow and system structure. Data fields and workflow are well defined. |
| 5–7 | System flow mostly works but lacks clarity in some areas. |
| 2–4 | Flow is confusing or poorly defined. |
| 0–1 | No clear design or workflow explanation. |

---

# 3. Flutter Application Implementation (30 pts)

Evaluation considers:

- Navigation
- Form input
- QR code scanning
- GPS location retrieval
- Saving data

| Score | Criteria |
|------|---------|
| 26–30 | Most required features work correctly and app is functional. |
| 20–25 | Major features implemented but some parts incomplete. |
| 10–19 | Partial implementation; several features missing. |
| 0–9 | Very limited functionality or application not working. |

---

# 4. Firebase Integration (15 pts)

| Score | Criteria |
|------|---------|
| 13–15 | Firebase correctly integrated; data is stored and retrieved successfully. |
| 9–12 | Firebase partially integrated but mostly functional. |
| 5–8 | Limited Firebase functionality. |
| 0–4 | No working Firebase integration. |

---

# 5. Deployment (10 pts)

| Score | Criteria |
|------|---------|
| 9–10 | Application successfully deployed and accessible via URL. |
| 6–8 | Deployment mostly works but has minor issues. |
| 3–5 | Deployment attempted but incomplete. |
| 0–2 | No deployment available. |

---

# 6. Code Quality (10 pts)

| Score | Criteria |
|------|---------|
| 9–10 | Code is organized, readable, and structured well. |
| 6–8 | Code structure is acceptable but could be improved. |
| 3–5 | Code is messy or difficult to follow. |
| 0–2 | Poor structure or incomplete code. |

---

# 7. AI Usage & Engineering Judgment (10 pts)

| Score | Criteria |
|------|---------|
| 9–10 | AI used effectively and student demonstrates clear understanding of generated code. |
| 6–8 | AI used appropriately but explanations are limited. |
| 3–5 | Heavy reliance on AI with limited understanding. |
| 0–2 | Unable to explain the implementation or AI usage. |

---
