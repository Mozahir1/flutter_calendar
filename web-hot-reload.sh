#!/bin/bash

# Flutter Calendar View - Web Hot Reload Development
# This script runs Flutter web with hot reload for rapid development

echo "🔥 Starting Flutter Calendar Web with Hot Reload..."

# Navigate to example directory
cd example

# Check if Flutter web is enabled
echo "📋 Checking Flutter web configuration..."
flutter config --enable-web

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run with hot reload on web
echo "🌐 Starting web development server with hot reload..."
echo "📱 Open your browser to: http://localhost:8080"
echo "🔄 Hot reload is enabled - save files to see changes instantly"
echo "⏹️  Press 'q' to quit, 'r' to hot reload, 'R' to hot restart"
echo ""

# Run Flutter web with hot reload
flutter run -d web-server --web-port 8080 
