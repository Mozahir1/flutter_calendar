#!/bin/bash

# Flutter Calendar View - Foreground Web Development
# This script runs Flutter web in the foreground so key commands work

echo "🚀 Starting Flutter Calendar Web Development (Foreground Mode)..."

# Navigate to example directory
cd example

# Check if Flutter web is enabled
echo "📋 Checking Flutter web configuration..."
flutter config --enable-web

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run with hot reload on web in foreground
echo "🌐 Starting web development server with hot reload..."
echo "📱 Open your browser to: http://localhost:8080/flutter_calendar_view"
echo "🔄 Hot reload is enabled - save files to see changes instantly"
echo "⏹️  Press 'q' to quit, 'r' to hot reload, 'R' to hot restart"
echo ""

# Run Flutter web with hot reload in foreground
flutter run -d web-server --web-port 8080
