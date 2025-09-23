#!/bin/bash

# Flutter Calendar View - Production Web Build
# Future-proof production build script

echo "🏗️  Building Flutter Calendar for Web Production..."

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

# Build for web with production optimizations
echo "🔨 Building for web (production mode)..."
flutter build web --release

echo "✅ Production build complete!"
echo "📁 Build files are in: example/build/web/"
echo "🌐 You can serve these files with any web server"
echo ""
echo "💡 To test the production build locally:"
echo "   cd example/build/web && python3 -m http.server 8080"
echo "   Then open: http://localhost:8080"
