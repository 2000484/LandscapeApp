# Local Testing Guide

This guide will help you test the LandscapeApp locally using the Garmin Connect IQ SDK.

## Prerequisites

### 1. Install Connect IQ SDK

**Option A: Using SDK Manager (Recommended)**
1. Download the SDK Manager from [Garmin Developer](https://developer.garmin.com/connect-iq/sdk/)
2. Run the installer and select Linux as your platform
3. The SDK Manager will download and install the latest SDK

**Option B: Manual Installation**
1. Visit [Garmin Connect IQ SDK Downloads](https://developer.garmin.com/connect-iq/sdk/)
2. Download the latest Linux SDK (connectiq-sdk-lin-x.x.x.zip)
3. Extract to a location like `~/connectiq-sdk`
4. Note the installation path

### 2. Set Environment Variable

Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
export CIQ_SDK_HOME=/path/to/connectiq-sdk
export PATH=$CIQ_SDK_HOME/bin:$PATH
```

Replace `/path/to/connectiq-sdk` with your actual SDK path.

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### 3. Verify Installation

```bash
echo $CIQ_SDK_HOME
monkeyc --version
```

## Testing the App

### Method 1: Using the Build Script (Easiest)

Simply run:
```bash
./build_and_run.sh
```

This will:
- Build the app
- Launch the Vivoactive 5 simulator
- Load the app in the simulator

### Method 2: Manual Build and Run

**Build the app:**
```bash
monkeyc -o bin/LandscapeApp.prg -f monkey.jungle -y developer_key -w
```

**Run in simulator:**
```bash
monkeydo bin/LandscapeApp.prg vivoactive5
```

### Method 3: Using VS Code Extension

1. Install the **Monkey C** extension by Garmin in VS Code
2. Open Command Palette (`Ctrl+Shift+P`)
3. Run: **Monkey C: Build for Device** → Select `vivoactive5`
4. Run: **Monkey C: Run** → The simulator will launch

## Using the Simulator

Once the simulator launches:
- The app will load on the virtual Vivoactive 5 watch
- Use your mouse to interact with the touchscreen
- Use keyboard shortcuts for buttons (usually shown in the simulator)
- Test all features: GPS tracking, task selection, metrics, etc.

## Testing on a Real Device

1. Connect your Garmin Vivoactive 5 via USB
2. Build the app: `./build_and_run.sh` (it will create `bin/LandscapeApp.prg`)
3. Copy `bin/LandscapeApp.prg` to the `GARMIN/Apps` folder on your device
4. Safely eject the device
5. Find the app in your device's activity menu

## Troubleshooting

### "monkeyc: command not found"
- Make sure `CIQ_SDK_HOME` is set correctly
- Add `$CIQ_SDK_HOME/bin` to your PATH
- Verify the SDK is installed correctly

### Build errors
- Check that all source files are present
- Verify `manifest.xml` syntax
- Look for syntax errors in `.mc` files

### Simulator won't launch
- Ensure you have Java installed (`java --version`)
- Try running the simulator manually: `connectiq` or `simulator`
- Check SDK documentation for graphics driver requirements

## Project Structure

```
LandscapeApp/
├── manifest.xml          # App configuration
├── monkey.jungle         # Build configuration
├── developer_key         # Auto-generated signing key (DO NOT COMMIT)
├── build_and_run.sh      # Build and test script
├── source/               # MonkeyC source code
│   ├── LandscapingApp.mc
│   └── LandscapingView.mc
├── resources/            # App resources
│   ├── drawables/
│   ├── settings/
│   └── strings/
└── bin/                  # Build output (DO NOT COMMIT)
```

## Next Steps

After testing locally:
1. Fix any bugs or issues you discover
2. Test all features thoroughly
3. Build for release when ready
4. Submit to Connect IQ Store

## Resources

- [Connect IQ Documentation](https://developer.garmin.com/connect-iq/api-docs/)
- [Connect IQ Tutorials](https://developer.garmin.com/connect-iq/connect-iq-basics/)
- [API Reference](https://developer.garmin.com/connect-iq/api-docs/Toybox.html)
