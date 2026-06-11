# Wiring real Twilio (SMS) & Google sign-in

The code already supports both providers; you only supply **your own credentials**. Keep secrets
in **`backend/.env`** (gitignored) and pass the Google client ids to the app via `--dart-define`
at build/run time. **Never commit live keys.**

When credentials are absent the app falls back to clearly-labelled dev mocks
(phone OTP `000000`; a demo Google identity), so the prototype always runs.

---

## 1. Twilio — real SMS OTP

1. Create a Twilio account → get a phone number (Console → Phone Numbers).
2. From the Console dashboard copy **Account SID** and **Auth Token**.
3. Put them in `backend/.env`:

   ```
   TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   TWILIO_AUTH_TOKEN=your-auth-token
   TWILIO_FROM_NUMBER=+1XXXXXXXXXX
   ```

4. Restart the backend. `GET /health` should now show `"sms_mock_mode": false`.

That's the whole change — `POST /auth/phone/request-otp` will send a real SMS via
`app/services/sms.py` (Twilio Messages API) and no longer return `dev_code`.

> Trial accounts can only text **verified** numbers and prefix a trial banner. Watch Twilio
> spend; this prototype has no rate-limiting.

---

## 2. Google sign-in — real OAuth

You need OAuth client IDs from **Google Cloud Console → APIs & Services → Credentials**. Create
the OAuth consent screen first, then create clients per platform you target.

### Backend (token verification)

The backend verifies the Google ID token's **audience** against `GOOGLE_CLIENT_ID` (comma-separated
list allowed). Put the **Web client id** (and any platform client ids whose tokens you'll accept):

```
# backend/.env
GOOGLE_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
```

Restart the backend → `GET /health` shows `"google_mock_mode": false`.

### Web app

Create an **OAuth Web client** (Authorized JS origin `http://localhost:8080`, etc.). Run with:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000 `
  --dart-define=GOOGLE_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
```

Also add this meta tag to `web/index.html` inside `<head>`:

```html
<meta name="google-signin-client_id" content="WEB_CLIENT_ID.apps.googleusercontent.com">
```

### Android

1. Create an **OAuth Android client**: package `com.roadsidehelp` + your signing **SHA-1**
   (`cd android && ./gradlew signingReport`, or `keytool -list -v -keystore <debug.keystore>`).
2. Android exchanges for an ID token whose audience is the **Web** client id, so pass it as the
   server client id:

   ```powershell
   flutter run -d <android> --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
     --dart-define=GOOGLE_SERVER_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
   ```

   Ensure the backend `GOOGLE_CLIENT_ID` includes that same Web client id.

### iOS

1. Create an **OAuth iOS client** (bundle id `com.roadsidehelp`). Note its **iOS client id** and
   the **reversed client id** (e.g. `com.googleusercontent.apps.123-abc`).
2. Add the reversed client id as a URL scheme in `ios/Runner/Info.plist`:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR-REVERSED-CLIENT-ID</string>
       </array>
     </dict>
   </array>
   ```

3. Run with `--dart-define=GOOGLE_CLIENT_ID=IOS_CLIENT_ID.apps.googleusercontent.com` and include
   the iOS client id in the backend `GOOGLE_CLIENT_ID` list.

---

## Quick verification

| Check | Expected |
|-------|----------|
| `GET /health` | `sms_mock_mode:false`, `google_mock_mode:false` once creds are set |
| Phone sign-in | Real SMS received; `dev_code` no longer returned |
| Google button | Native Google account picker; backend logs a successful `/auth/google` |

If a Google sign-in fails with `audience mismatch`, the token's `aud` isn't in the backend's
`GOOGLE_CLIENT_ID` list — add that client id and restart.
