#!/bin/bash

# Flutter Calendar View - Serve Built Web App
# Serves the built web app locally

echo "🌐 Serving Flutter Calendar Web App..."

# Check if build exists
if [ ! -d "example/build/web" ]; then
    echo "❌ No web build found. Run ./web-build-production.sh first."
    exit 1
fi

# Navigate to build directory
cd example/build/web

echo "📱 Serving at: http://localhost:8080"
echo "⏹️  Press Ctrl+C to stop the server"
echo ""

# Try different server options
if command -v python3 &> /dev/null; then
    python3 -m http.server 8080
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer 8080
elif command -v npx &> /dev/null; then
    npx serve -s . -l 8080
else
    echo "❌ No suitable web server found. Please install Python or Node.js."
    exit 1
fi
