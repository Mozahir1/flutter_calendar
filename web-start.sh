#!/bin/bash

# Flutter Calendar View - Smart Web Development
# This script properly manages Flutter web processes

echo "🚀 Starting Flutter Calendar Web Development..."

# Function to kill existing processes
kill_existing() {
    echo "🧹 Cleaning up existing processes..."
    pkill -f flutter 2>/dev/null || true
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    sleep 2
}

# Function to start the server
start_server() {
    echo "📋 Checking Flutter web configuration..."
    flutter config --enable-web

    echo "📦 Getting dependencies..."
    cd example
    flutter pub get

    echo "🌐 Starting web development server with hot reload..."
    echo "📱 Open your browser to: http://localhost:8080/flutter_calendar_view"
    echo "🔄 Hot reload is enabled - save files to see changes instantly"
    echo "⏹️  Press 'q' to quit, 'r' to hot reload, 'R' to hot restart"
    echo ""

    # Run Flutter web with hot reload
    flutter run -d web-server --web-port 8080
}

# Function to stop the server
stop_server() {
    echo "🛑 Stopping Flutter web server..."
    kill_existing
    echo "✅ Server stopped."
}

# Handle script arguments
case "${1:-start}" in
    "start")
        kill_existing
        start_server
        ;;
    "stop")
        stop_server
        ;;
    "restart")
        stop_server
        sleep 1
        start_server
        ;;
    *)
        echo "Usage: $0 [start|stop|restart]"
        echo "  start   - Start the web server (default)"
        echo "  stop    - Stop the web server"
        echo "  restart - Restart the web server"
        exit 1
        ;;
esac
