# Real-World Authentication Setup

This guide explains how to configure Google OAuth and Twilio SMS for production authentication.

## Overview

The app supports three authentication methods:
1. **Email + Password** - Works out of the box (no setup needed)
2. **Phone OTP via SMS** - Requires Twilio
3. **Google Sign-In** - Requires Google OAuth credentials

## 1. Google Sign-In Setup

### Step 1: Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project:
   - Click "Select a Project" → "NEW PROJECT"
   - Name: "Roadside Help" (or your choice)
   - Click "CREATE"

3. Enable Google+ API:
   - Search for "Google+ API" in the search bar
   - Click on it and press "ENABLE"

4. Create OAuth 2.0 Credentials:
   - Go to **Credentials** in the left sidebar
   - Click "Create Credentials" → "OAuth 2.0 Client ID"
   - If prompted, configure consent screen first:
     - Choose "External" user type
     - Fill in app name, user support email, developer email
     - Add scopes: `email`, `profile`
     - Add test users (your Gmail account)

5. Create the Client ID:
   - Application Type: **Web application**
   - Name: "Flutter Web"
   - Authorized JavaScript origins:
     ```
     http://localhost:60335
     http://localhost:8000
     http://localhost:3000
     ```
   - Authorized redirect URIs:
     ```
     http://localhost:60335/callback
     http://localhost:8000/callback
     ```
   - Click "CREATE"

6. Copy your **Client ID** (looks like: `xxx.apps.googleusercontent.com`)

### Step 2: Update Backend Configuration

Edit `backend/.env`:

```bash
GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID_HERE
```

Example:
```bash
GOOGLE_CLIENT_ID=123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com
```

### Step 3: Run Flutter with Google Sign-In

Stop the current Flutter app (press `q` in the terminal) and restart with:

```bash
cd c:\Users\Venkat Arunn Reddy\speckit_project\help

# Run on Chrome with Google credentials
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID_HERE \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID_HERE
```

Or on Windows desktop:
```bash
flutter run -d windows \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID_HERE \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID_HERE
```

### Step 4: Test Google Sign-In

1. Open the app in browser/desktop
2. On Welcome screen, click "Continue with Google"
3. You'll be redirected to Google login
4. After login, you'll be automatically signed in to the app

---

## 2. Twilio SMS Setup

### Step 1: Create Twilio Account

1. Go to [Twilio Console](https://www.twilio.com/console)
2. Sign up for a free account (includes $15 credit for testing)
3. Verify your phone number
4. In the dashboard, copy:
   - **Account SID** (starts with `AC`)
   - **Auth Token** (hidden by default, click eye icon to reveal)

### Step 2: Get a Phone Number

1. Go to **Phone Numbers** in left sidebar → **Manage Numbers**
2. Click "Get your first Twilio phone number"
3. Accept the suggested number (or customize)
4. Copy the phone number (e.g., `+1XXXXXXXXXX`)

### Step 3: Update Backend Configuration

Edit `backend/.env`:

```bash
TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID
TWILIO_FROM_NUMBER=+1XXXXXXXXXX
```

Example:
```bash
TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
TWILIO_FROM_NUMBER=+12125551234
```

### Step 4: Test Phone OTP

1. Restart the backend:
   ```bash
   cd backend
   python -m uvicorn app.main:app --reload --port 8000
   ```

2. In the Flutter app:
   - Select "Phone" tab
   - Enter your actual phone number (with country code)
   - Click "Continue"
   - You'll receive an SMS with a 6-digit code
   - Enter the code to verify

---

## Environment Variables Summary

### Backend (`backend/.env`)

```bash
# Database
DATABASE_URL=sqlite:///./roadside_help.db

# JWT (keep secret in production!)
JWT_SECRET=your-long-random-secret-string-here
JWT_ALGORITHM=HS256
ACCESS_TTL_MINUTES=60
REFRESH_TTL_DAYS=30

# Google OAuth (REQUIRED for real Google Sign-In)
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com

# Twilio SMS (REQUIRED for real OTP)
TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_FROM_NUMBER=+1XXXXXXXXXX

# CORS
CORS_ORIGINS=http://localhost:60335,http://localhost:8000

# Seed location
SEED_CENTER_LAT=17.4239
SEED_CENTER_LNG=78.4738
```

### Flutter Build Variables

When running Flutter, pass these variables:

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your-client-id.apps.googleusercontent.com
```

---

## Testing Checklist

- [ ] Google Sign-In configured in Google Cloud Console
- [ ] `GOOGLE_CLIENT_ID` set in `backend/.env`
- [ ] Backend restarted after updating .env
- [ ] Flutter app running with `--dart-define` variables
- [ ] Can click "Continue with Google" and sign in
- [ ] Twilio account created with phone number
- [ ] `TWILIO_*` credentials set in `backend/.env`
- [ ] Can enter phone number and receive SMS
- [ ] Can verify OTP code from SMS
- [ ] Can register with email/password
- [ ] Can sign in with existing email/password

---

## Security Notes

⚠️ **IMPORTANT**: Never commit real credentials to Git!

```bash
# .gitignore should contain:
backend/.env
```

Your `.env` file is already in `.gitignore`, so credentials won't be accidentally committed.

For production:
1. Use strong JWT_SECRET (minimum 32 characters)
2. Use environment variables or secrets manager
3. Enable HTTPS for all API calls
4. Restrict CORS_ORIGINS to your actual domain
5. Use production databases (PostgreSQL recommended)

---

## Troubleshooting

### Google Sign-In shows "Popup blocked"
- Allow popups for the domain in browser settings
- Or disable popup blocker for localhost

### Twilio SMS not arriving
- Check phone number format (must include country code)
- Verify Twilio account has credits
- Check console logs for API errors
- Test number must be verified in Twilio trial account

### "Invalid audience" error from Google
- Ensure Client ID matches in both Flutter and Backend
- Clear browser cache
- Check that Server Client ID is set in Flutter

### Backend returns "Google mock mode" still enabled
- Verify `GOOGLE_CLIENT_ID` is set in `.env`
- Restart backend server
- Check `GET http://localhost:8000/health` - should show `"google_mock_mode": false`

---

## Production Deployment

For production, update:

1. **Backend `.env`**:
   - Use PostgreSQL instead of SQLite
   - Strong JWT_SECRET
   - Real Google OAuth credentials for your domain
   - Real Twilio credentials

2. **Flutter build**:
   - Use production domain instead of localhost
   - Update GOOGLE_CLIENT_ID to production value
   - Build with `flutter build web --release`

3. **API Configuration**:
   - Update `API_BASE_URL` to production backend URL
   - Update CORS_ORIGINS to production domain
   - Enable HTTPS everywhere
