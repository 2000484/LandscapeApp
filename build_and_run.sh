#!/bin/bash
# Build and run the LandscapeApp in the simulator

set -e

# Check if SDK is installed
if [ -z "$CIQ_SDK_HOME" ]; then
    echo "❌ Error: CIQ_SDK_HOME is not set."
    echo ""
    echo "Please install the Connect IQ SDK and set the environment variable:"
    echo "  export CIQ_SDK_HOME=/path/to/connectiq-sdk"
    echo ""
    echo "Add this to your ~/.bashrc or ~/.zshrc to make it permanent."
    exit 1
fi

if [ ! -f "$CIQ_SDK_HOME/bin/monkeyc" ]; then
    echo "❌ Error: monkeyc compiler not found at $CIQ_SDK_HOME/bin/monkeyc"
    exit 1
fi

echo "✅ Connect IQ SDK found at: $CIQ_SDK_HOME"
echo ""

# Build the app
echo "🔨 Building LandscapeApp..."
"$CIQ_SDK_HOME/bin/monkeyc" \
    -o bin/LandscapeApp.prg \
    -f monkey.jungle \
    -y developer_key \
    -w

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    
    # Run in simulator
    echo "🚀 Starting simulator..."
    "$CIQ_SDK_HOME/bin/monkeydo" bin/LandscapeApp.prg vivoactive5
else
    echo "❌ Build failed!"
    exit 1
fi
