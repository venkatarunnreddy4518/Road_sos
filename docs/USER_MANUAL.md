# Roadside Help — User Manual

**Version**: 0.1.0 | **Platform**: Android · iOS · Web

---

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Signing In](#signing-in)
4. [Finding a Helper (Seeker Mode)](#finding-a-helper-seeker-mode)
5. [Tracking Your Request](#tracking-your-request)
6. [Rating a Helper](#rating-a-helper)
7. [Becoming a Helper (Provider Mode)](#becoming-a-helper-provider-mode)
8. [Managing Requests as a Provider](#managing-requests-as-a-provider)
9. [Profile & Settings](#profile--settings)
10. [Language Settings](#language-settings)
11. [Request History](#request-history)
12. [Troubleshooting](#troubleshooting)
13. [Privacy & Data](#privacy--data)

---

## Introduction

**Roadside Help** connects stranded drivers with nearby mechanics, tow-truck operators, petrol pumps, puncture shops, and battery-boost services in real time — similar to Uber/Rapido, but for roadside emergencies.

The app works in two modes:
- **Seeker** — you need help.
- **Provider** — you offer help.

Any registered user can switch between modes at any time from their profile.

---

## Getting Started

### System Requirements

| Platform | Minimum version |
|----------|----------------|
| Android | 8.0 (API 26) |
| iOS | 13.0 |
| Web browser | Chrome 90+ / Edge 90+ / Firefox 88+ |

### Permissions Required

| Permission | Why |
|-----------|-----|
| Location (precise) | Finding nearby helpers / sharing your location as a provider |
| Phone | One-tap call to helper |
| Internet | Real-time tracking and chat |

---

## Signing In

Roadside Help supports four sign-in methods:

### 1. Phone OTP
1. Enter your 10-digit mobile number.
2. Tap **Send OTP**.
3. Enter the 6-digit code received via SMS.
4. Tap **Verify**.

> In the development / demo build, any phone number is accepted and the OTP is always `000000`.

### 2. Email & Password
1. Tap **Email / Password**.
2. Enter your email address and password.
3. Tap **Sign In**. First-time users tap **Create Account** instead.

### 3. Google Sign-In
1. Tap **Continue with Google**.
2. Select your Google account.
3. Grant location permission when prompted.

> In the development build, Google sign-in uses a demo identity.

### 4. Guest Mode
Tap **Continue as Guest** to browse helpers and categories without creating an account. Guest users cannot submit requests or switch to Provider mode.

---

## Finding a Helper (Seeker Mode)

1. After signing in, the **Home** screen shows a map centered on your current location.
2. Scroll the category grid or use the **Search** bar to find the service type you need:
   - Puncture / Tyre
   - Fuel / Petrol
   - Mechanic
   - Towing
   - Battery
3. Tap a category to see a list of nearby helpers sorted by distance.
4. Tap a helper card to view their details: name, rating, distance, and contact options.
5. From the detail screen you can:
   - **Call** — opens your phone dialer.
   - **SMS** — opens your messaging app.
   - **Directions** — opens Google Maps / Apple Maps.
   - **Request** — sends a formal service request (requires sign-in).
6. Tap **Request Help** and confirm your pickup location on the map.

> **Offline mode**: if internet is unavailable, the app shows the last-cached list of nearby helpers. The "Offline — cached results" banner will appear at the top of the screen.

---

## Tracking Your Request

Once a helper accepts your request:

1. A **Tracking** screen appears showing the helper's live location on the map.
2. The **Status Timeline** at the bottom shows the current step:
   - Pending → Accepted → En Route → On Site → Completed
3. You can **Cancel** the request (before the helper is On Site) by tapping the red **Cancel** button.
4. Once the helper marks the job **Completed**, you are prompted to rate them.

---

## Rating a Helper

1. After completion, a 1–5 star rating dialog appears.
2. Optionally add a short comment.
3. Tap **Submit Rating**.

Your rating contributes to the helper's public average, which other seekers can see.

---

## Becoming a Helper (Provider Mode)

1. Go to **Profile** (bottom-right tab).
2. Tap **Switch to Provider Mode**.
3. Fill in your provider profile:
   - Service type (e.g., Mechanic, Towing)
   - Vehicle / equipment description
   - Service radius (km)
4. Tap **Save & Go Live**.

You are now visible to seekers within your service radius. Your real-time GPS location is shared with seekers who have an active request for you.

---

## Managing Requests as a Provider

1. When a new request is nearby, a notification and an **Incoming Request** card appear.
2. Tap **Accept** to take the job (first provider to accept wins).
3. Advance the status as you work:
   - **En Route** → tap when you start travelling.
   - **On Site** → tap when you arrive.
   - **Completed** → tap when the job is done.
4. If you cannot take a job, tap **Ignore** to dismiss the card.

---

## Profile & Settings

Access your profile via the **Profile** tab (bottom navigation).

| Section | What you can change |
|---------|-------------------|
| Personal info | Display name, phone number |
| Vehicle info | Make, model, registration |
| Provider profile | Service type, radius, availability |
| Account | Change password, sign out, delete account |

---

## Language Settings

1. Go to **Profile → Settings → Language**.
2. Select from:
   - English
   - हिन्दी (Hindi)
   - తెలుగు (Telugu)
   - தமிழ் (Tamil)
3. The app language changes immediately and is remembered across app restarts.

---

## Request History

- **Seeker history**: Profile → My Requests — shows all past service requests with status and helper details.
- **Provider history**: Profile → Completed Jobs — shows all jobs you have fulfilled with ratings received.

---

## Troubleshooting

| Problem | Solution |
|---------|---------|
| "No helpers found nearby" | Ensure location permission is granted. Try zooming out on the map. |
| OTP not received | Wait 60 seconds and tap **Resend OTP**. Check spam/junk folder for email OTPs. |
| App shows "Offline — cached results" | Check your internet connection. Cached helpers are shown from your last online session. |
| Helper location not updating | Pull down to refresh on the Tracking screen. |
| Can't switch to Provider mode | You must be signed in with a full account (not Guest). |
| Google sign-in fails | Ensure Google Play Services are up to date (Android). |

---

## Privacy & Data

- **Location data**: your precise location is only shared with a helper during an active request. It is not stored permanently.
- **Contact details**: phone numbers are visible to matched helpers to enable direct communication.
- **Ratings**: all ratings are public and attributed to your display name.
- **Data deletion**: to delete your account and all associated data, go to Profile → Account → Delete Account.

For security concerns or to report a vulnerability, see [SECURITY.md](SECURITY.md).
