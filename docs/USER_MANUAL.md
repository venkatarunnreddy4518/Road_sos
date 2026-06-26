# Roadside SOS — User Manual

Welcome to **Roadside SOS**, a two-sided marketplace for roadside emergencies. This manual covers everything a seeker (stranded user) and a helper (service provider) need to get up and running.

**Live App**: <https://help-ashy.vercel.app>

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
   - [Creating an Account](#creating-an-account)
   - [Signing In](#signing-in)
   - [Guest Access](#guest-access)
3. [For Seekers — Requesting Help](#for-seekers--requesting-help)
   - [Finding Nearby Helpers](#finding-nearby-helpers)
   - [Submitting an SOS Request](#submitting-an-sos-request)
   - [Tracking Your Request](#tracking-your-request)
   - [Completing a Request & Leaving a Review](#completing-a-request--leaving-a-review)
   - [My SOS Requests History](#my-sos-requests-history)
4. [For Helpers — Provider Mode](#for-helpers--provider-mode)
   - [Registering as a Provider](#registering-as-a-provider)
   - [Accepting Requests](#accepting-requests)
   - [Updating Request Status](#updating-request-status)
5. [App Features](#app-features)
   - [Language Selection](#language-selection)
   - [Profile & Settings](#profile--settings)
   - [Emergency Contacts](#emergency-contacts)
   - [Offline Mode](#offline-mode)
6. [Troubleshooting](#troubleshooting)
7. [Support](#support)

---

## Overview

Roadside SOS connects **stranded users** with nearby **mechanics, puncture shops, petrol pumps, towing services, and battery jump-start providers** in real time.

| Role | What They Do |
|------|-------------|
| **Seeker** | Submits an emergency request and tracks help arriving on a live map |
| **Helper / Provider** | Receives nearby requests, accepts jobs, and updates status to completion |

---

## Getting Started

### Creating an Account

The app supports four sign-in methods:

| Method | Description |
|--------|-------------|
| **Email + Password** | Standard sign-up with email verification |
| **Phone OTP** | Enter your mobile number and verify with a one-time code sent via SMS |
| **Google Sign-In** | One-tap sign-in with your Google account |
| **Guest Access** | Browse and submit requests without creating an account |

To create an account:
1. Open the app at <https://help-ashy.vercel.app>.
2. Tap **Sign Up** on the welcome screen.
3. Choose your preferred sign-in method.
4. Follow the on-screen prompts to complete registration.

### Signing In

1. Open the app and tap **Sign In**.
2. Choose your sign-in method (Email, Phone, or Google).
3. Enter your credentials and tap **Continue**.

> **Note**: If third-party OAuth (Google) or SMS keys are not configured in the backend environment, the app automatically falls back to sandboxed development mocks — sign-in will still work.

### Guest Access

Tap **Continue as Guest** on the welcome screen to use the app without creating an account. Guest sessions have full access to the map and request flow but cannot view request history across sessions.

---

## For Seekers — Requesting Help

### Finding Nearby Helpers

1. After signing in, the app opens to the **Home / Map screen**.
2. Allow the app to access your device location when prompted.
3. The map (powered by OpenStreetMap) displays **available helpers** as markers near your current GPS position.
4. Tap any helper marker to view their:
   - Service type (e.g., Puncture Repair, Towing)
   - Distance from you
   - Star rating

> **Offline**: If you have no internet connection, the app falls back to a locally cached list of helpers near your last known GPS coordinates.

### Submitting an SOS Request

1. Tap the **SOS button** (centre of the bottom navigation bar) to open the emergency request flow.
2. Select your **emergency category**:
   - 🔧 Puncture Repair
   - ⛽ Petrol / Fuel Delivery
   - 🔋 Battery Jump-Start
   - 🚗 Towing Service
   - 🛠️ General Mechanic
3. Add an optional **note** (e.g., "Flat rear tyre, near highway marker 42").
4. Confirm your location shown on the map. Drag the pin if needed.
5. Tap **Request Help Now** to submit.

The request is sent to all nearby active helpers for that category — **first to accept wins** the job.

### Tracking Your Request

After submitting, the app transitions to the **Tracking Screen** automatically:

- A **status timeline** shows the current step: `Requested → Accepted → En Route → Arrived → Completed`.
- The helper's **live position marker** moves on the map as they travel toward you.
- The screen shows estimated distance and helper details (name, rating, contact).

The tracking screen polls the backend every few seconds to refresh the helper's location.

### Completing a Request & Leaving a Review

When the helper taps **Complete Service**:
1. The tracking screen shows a **Completed** status with the final `fare amount`.
2. A **Review Dialog** appears automatically — rate the helper from **1–5 stars** and leave an optional comment.
3. Tap **Submit Review** to save.

Your review updates the helper's rolling average rating visible to future seekers.

### My SOS Requests History

Access your past requests from the **Profile → My SOS Requests** screen:
- Switch between the **Seeker** tab (requests you submitted) and the **Helper** tab (requests you fulfilled as a provider).
- Each entry shows the service category, status chip, fare amount, and date.

---

## For Helpers — Provider Mode

### Registering as a Provider

Any user can become a helper by completing the Provider onboarding flow:

1. Go to **Profile → Become a Provider**.
2. Fill in:
   - **Service type** (e.g., Mechanic, Puncture Shop)
   - **Contact number**
   - **Current location** (auto-stamped from GPS, or adjust manually on the map)
3. Tap **Register as Provider**.

Your helper profile is now active and visible to seekers nearby.

### Accepting Requests

When in **Provider Mode**:
1. The app shows a **live inbox** of open requests near your location.
2. Each request card shows the emergency category, distance, and the seeker's note.
3. Tap **Accept Request** on a card to claim the job.
   - This is **first-accept-wins**: if another helper accepts first, the request will be removed from your inbox.
4. Once accepted, the seeker is notified and you are shown directions to their location.

### Updating Request Status

After accepting, use the status buttons on the active request card:

| Button | Sets Status To |
|--------|---------------|
| **Start Journey** | `EN_ROUTE` |
| **Mark Arrived** | `ARRIVED` |
| **Complete Service** | `COMPLETED` |

The seeker's tracking screen updates in real time with each status change. When you tap **Complete Service**, the request is finalized and the fare is stamped automatically from the service category's base fare.

---

## App Features

### Language Selection

The app supports four languages:

| Language | Script |
|----------|--------|
| English | Latin |
| हिन्दी (Hindi) | Devanagari |
| తెలుగు (Telugu) | Telugu |
| தமிழ் (Tamil) | Tamil |

To change language: **Profile → Settings → Language**. The full app updates within 2 seconds and the preference is saved across sessions.

### Profile & Settings

Access from the **Profile tab** (bottom navigation):
- Edit your name and contact details
- View your request history (Seeker & Helper tabs)
- Manage payment methods
- Read Safety Guidelines
- Access Help & Support
- Refer & Earn (share the app with friends)

### Emergency Contacts

Store emergency contacts for quick access during a roadside situation:
1. Go to **Profile → Emergency Contacts**.
2. Tap **Add Contact** and enter name and phone number.
3. During a crisis, tap any contact to call them directly from the app.

### Offline Mode

When internet connectivity is lost:
- The app automatically switches to an **offline cache** of the nearest helpers based on your last known GPS location.
- You can still initiate a **direct call or SMS** to a cached helper from the map.
- Requests submitted offline are queued and synced when connectivity is restored.

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| Map shows no helpers nearby | Ensure location permissions are granted; try refreshing or zooming out |
| SOS button is unresponsive | Check your internet connection; the app needs to reach the backend to submit a request |
| Backend slow on first load | The Render free-tier backend sleeps after inactivity — the first request may take 30–50 s to cold-start |
| Google Sign-In not working | Ensure your browser allows pop-ups for the app domain |
| Request stuck in "Requested" | No helpers may be available in your area; try again or use the direct call fallback |
| Location pin is wrong | Drag the map pin to your exact location before tapping "Request Help Now" |

---

## Support

- **In-app**: Profile → Help & Support → one-tap helpline call
- **GitHub / GitLab Issues**: Open a bug report at the project repository
- **Security issues**: Follow the [Security Policy](SECURITY.md) — do not open a public issue

---

*Roadside SOS — built with FastAPI, Flutter, and PostgreSQL.*
