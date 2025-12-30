# Sparkle Update Integration Guide

This guide explains how the Sparkle update system is integrated into **BatteryBoi** and details the steps required to release a new version.

## Integration Overview

The application uses **Sparkle** to manage updates. The logic is encapsulated in `UpdateManager` (`BatteryBoi/Core/Update/BBUpdateManager.swift`).

- **Background Checks**: The `SPUUpdater` is configured to check for updates automatically (`automaticallyChecksForUpdates = true`) with a 12-hour interval.
- **Custom UI Notification**: When an update is found in the background, `UpdateManager` updates its `available` property. This triggers a "New Update" indicator in the app's UI (e.g., `UpdatePromptView`).
- **User Action**: When the user clicks the "New Update" indicator or the "Check for Updates" button in Settings, `UpdateManager.shared.triggerUpdate()` is called. This invokes Sparkle's standard user interface (`SPUStandardUserDriver`) to present the update dialog, allowing the user to view release notes and install the update.
- **Configuration**:
    - **Feed URL**: `$(ENV_APPCAST_URL)` (defined in `BBEnviroments.xcconfig`).
    - **Public Key**: `$(ENV_SPARKLE_PUBLIC)` (defined in `BBEnviroments.xcconfig`).

## Release Process

Follow these steps to deploy a new update.

### 1. Prerequisite Checks
- Ensure you have the **Private Key** (EdDSA) corresponding to the `SUPublicEDKey` defined in `Info.plist` / `BBEnviroments.xcconfig`.
- Ensure you have the `generate_appcast` tool installed (usually found in the Sparkle distribution `bin/` directory).

### 2. Update Version
1.  Open the project in Xcode.
2.  Select the **BatteryBoi** target.
3.  Increment the **Version** (Marketing Version, e.g., `1.0.1` -> `1.0.2`).
4.  Increment the **Build** (Project Version, e.g., `10` -> `11`).

### 3. Archive and Export
1.  In Xcode, go to **Product > Archive**.
2.  Once archived, the Organizer window will open.
3.  Select the archive and click **Distribute App**.
4.  Select **Developer ID** -> **Upload** (to submit to Apple for notarization service) or **Export** (if you want to notarize manually, though Upload -> Export is easier).
    - *Recommended*: Select **Export** -> **Developer ID**.
    - Choose **Automatically manage signing**.
5.  Export the app to a local folder (e.g., `~/Desktop/BatteryBoi_v1.0.2`).

### 4. Notarization
If you chose "Export" without uploading to the notarization service in the previous step, you must notarize the app now. macOS requires apps to be notarized to run without security warnings.
1.  Compress the app: `Zip` the `.app` bundle or create a `.dmg`.
2.  Run `xcrun notarytool`:
    ```bash
    xcrun notarytool submit BatteryBoi.zip --keychain-profile "YourProfileName" --wait
    ```
    *(You may need to set up an app-specific password and keychain profile first using `xcrun notarytool store-credentials`).*
3.  **Staple** the ticket:
    ```bash
    xcrun stapler staple BatteryBoi.app
    ```
    *(If you notarized a zip, staple the App bundle, then re-zip or create the final DMG).*

### 5. Generate Appcast
1.  Move the final, signed, notarized, and stapled archive (e.g., `BatteryBoi.zip` or `BatteryBoi.dmg`) to a folder dedicated to your releases.
2.  Run the `generate_appcast` tool pointing to that folder.
    ```bash
    /path/to/sparkle/bin/generate_appcast /path/to/release_folder
    ```
3.  The tool will parse the file, sign the update using your **Private Key** (it will ask for the key or look for it in the keychain), and update/create the `appcast.xml` file.

### 6. Upload
1.  Upload the new archive (e.g., `BatteryBoi_v1.0.2.zip`) to your server (the location corresponding to `ENV_APPCAST_URL`).
2.  Upload the updated `appcast.xml` to the same location (or wherever the URL points).

### 7. Verification
1.  Launch an older version of BatteryBoi.
2.  Click "Check for Updates" in Settings.
3.  Verify that the new update is detected and the Sparkle window appears.

## Troubleshooting

- **Update not detected**: Check if the `ENV_APPCAST_URL` is reachable and the `appcast.xml` is valid. Ensure `SUPublicEDKey` matches the private key used to sign the update.
- **Signature validation failed**: This usually means the `SUPublicEDKey` in the app doesn't match the key used by `generate_appcast`.
- **"Update is improperly signed"**: Ensure the update file (zip/dmg) itself is signed with your Developer ID Application certificate and Notarized.
