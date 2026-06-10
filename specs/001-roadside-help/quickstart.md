# Quickstart: Roadside Help Feature

This guide describes how to set up, run, and verify the Roadside Help feature implementation.

## Prerequisites

- **Flutter SDK**: 3.x installed and configured.
- **Android Studio / Xcode**: For emulator/simulator support.
- **Mock Backend**: A local server or mock JSON file mimicking the `/v1/helpers/sync` API.

## Setup & Installation

1. **Clone and Install**:
   ```bash
   git checkout 001-roadside-help
   flutter pub get
   ```

2. **Local Database Initialization**:
   The app initializes the SQLite database on the first launch. Ensure the device has sufficient storage.

3. **Localization Setup**:
   Verify that the `.arb` files in `lib/core/i18n/` are present. Run `flutter gen-l10n` if localization strings are missing.

## Running the App

1. **Launch Emulator**: Start an Android Emulator or iOS Simulator.
2. **Run App**:
   ```bash
   flutter run
   ```

## Verification Scenarios

### 1. Happy Path: Find Nearest Helper
- **Step**: Open app $\rightarrow$ Select "Puncture" $\rightarrow$ Observe sorted list.
- **Expected**: 3 nearest puncture shops appear, sorted nearest-first, with distance and a working call button.

### 2. Offline Mode
- **Step**: Run app once $\rightarrow$ Disable Network $\rightarrow$ Select problem type.
- **Expected**: Cached helpers are displayed. User's GPS position is visible on the map. Call/SMS buttons still work.

### 3. Language Switch
- **Step**: Go to Settings $\rightarrow$ Change language to "Hindi".
- **Expected**: All UI text (buttons, labels, headers) updates to Hindi immediately without restarting.

### 4. Edge Case: Far-Away Helpers
- **Step**: Mock the location to a remote area with no helpers within 15km.
- **Expected**: The nearest helpers are still shown, but visually flagged as "far away".

## Debugging Tips

- **API Logs**: Check the console for `HTTP 200` on `/v1/helpers/sync`.
- **DB Inspector**: Use `App Inspection` in Android Studio to verify the `helpers` table content.
- **GPS Mocking**: Use the emulator's extended controls to set a custom GPS location for distance testing.
