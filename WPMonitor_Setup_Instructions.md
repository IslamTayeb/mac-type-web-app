# WPMonitor Setup Instructions

## Important Requirements

1. **Disable App Sandboxing**: ✅ Already fixed - The app now runs without sandboxing to allow global keyboard monitoring.

2. **Grant Accessibility Permissions**:
   - When you first run the app, macOS will prompt you to grant accessibility permissions
   - Go to System Preferences > Security & Privacy > Privacy > Accessibility
   - Add WPMonitor to the list and check the box to enable it
   - The app will automatically open this settings pane if permissions aren't granted

3. **Build and Run**:
   - Open the project in Xcode
   - Select "My Mac" as the build target
   - Build and run (⌘+R)
   - The app will appear in your menu bar showing "0 WPM"

## Testing the App

1. **Check Console Logs**:
   - Open Console.app (found in /Applications/Utilities/)
   - Filter by "wpmonitor" to see debug logs
   - You should see messages like:
     - "WPMonitor starting..."
     - "Starting keyboard monitoring..."
     - "Current accessibility status: true/false"
     - "Keyboard monitoring started successfully"

2. **Verify It's Working**:
   - Type in any application
   - The WPM counter in the menu bar should update
   - Click on the menu bar item to see detailed statistics
   - Press space after typing words to register them

## Troubleshooting

### If keyboard monitoring isn't working

1. **Check Accessibility Permissions**:
   - Quit the app completely
   - Remove WPMonitor from Accessibility permissions if it's there
   - Run the app again and re-grant permissions when prompted

2. **Check Console for Errors**:
   - Look for any error messages in Console.app
   - Common issues:
     - "Failed to create event tap" - permissions issue
     - "Event tap was disabled" - system disabled the tap (app will auto-retry)

3. **Restart the App**:
   - Sometimes macOS requires a fresh start after granting permissions
   - Quit the app using the "Quit" button in the popover
   - Restart it from Xcode

4. **Check Activity Monitor**:
   - Open Activity Monitor
   - Search for "WPMonitor"
   - Make sure it's running and not using excessive CPU

## How It Works

- The app monitors all keyboard events system-wide
- It counts keystrokes and tracks when words are completed (space/enter/tab)
- WPM is calculated based on words typed in the last 60 seconds
- Statistics are saved and persist between app launches
- Daily stats reset at midnight

## Security Note

This app requires accessibility permissions because it needs to monitor keyboard events across all applications. This is necessary for accurate WPM tracking but means the app can technically see what you type. The app only counts keystrokes and words - it doesn't log or store the actual content you type.
