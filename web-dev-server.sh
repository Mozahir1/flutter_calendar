#!/bin/bash

# Flutter Calendar View - Web Development Server
# This script sets up a fast web development environment for testing calendar changes

echo "🚀 Starting Flutter Calendar Web Development Server..."

# Navigate to example directory
cd example

# Check if Flutter web is enabled
echo "📋 Checking Flutter web configuration..."
flutter config --enable-web

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web with optimizations for development
echo "🔨 Building for web (development mode)..."
flutter build web  

# Start a simple HTTP server
echo "🌐 Starting web server..."
echo "📱 Open your browser to: http://localhost:8080"
echo "🔄 Press Ctrl+C to stop the server"
echo ""

# Use Python's built-in HTTP server (available on most systems)
if command -v python3 &> /dev/null; then
    cd build/web
    python3 -m http.server 8080
elif command -v python &> /dev/null; then
    cd build/web
    python -m SimpleHTTPServer 8080
else
    echo "❌ Python not found. Please install Python or use: flutter run -d web-server --web-port 8080"
    exit 1
fi
