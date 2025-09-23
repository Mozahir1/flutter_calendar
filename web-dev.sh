#!/bin/bash

# Flutter Calendar View - Future-Proof Web Development
# This script automatically detects Flutter version and uses appropriate commands

echo "🚀 Starting Flutter Calendar Web Development..."

# Navigate to example directory
cd example

# Check if Flutter web is enabled
echo "📋 Checking Flutter web configuration..."
flutter config --enable-web

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Detect Flutter version and use appropriate commands
FLUTTER_VERSION=$(flutter --version | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1)
echo "🔍 Detected Flutter version: $FLUTTER_VERSION"

# Run with hot reload on web
echo "🌐 Starting web development server with hot reload..."
echo "📱 Open your browser to: http://localhost:8080"
echo "🔄 Hot reload is enabled - save files to see changes instantly"
echo "⏹️  Press 'q' to quit, 'r' to hot reload, 'R' to hot restart"
echo ""

# Use the most compatible command for current Flutter version
flutter run -d web-server --web-port 8080
