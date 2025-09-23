# Web Development Setup for Flutter Calendar View

This document explains how to set up and use the web development environment for testing your Flutter calendar changes.

## 🚀 Quick Start

### Option 1: Development with Hot Reload (Recommended)
```bash
./web-dev.sh
```
- **Best for**: Active development and testing
- **Features**: Hot reload, instant updates, debugging tools
- **URL**: http://localhost:8080

### Option 2: Production Build
```bash
./web-build-production.sh
```
- **Best for**: Final testing before deployment
- **Features**: Optimized build, minified code, production performance
- **Output**: `example/build/web/` directory

### Option 3: Serve Built App
```bash
./web-serve.sh
```
- **Best for**: Testing production builds locally
- **Features**: Static files, faster loading, production simulation
- **URL**: http://localhost:8080

## 📋 Prerequisites

- Flutter SDK (>=3.24.3)
- Dart SDK (>=3.5.3)
- Python 3 (for local server) or Node.js (alternative)

## 🔧 Available Scripts

| Script | Purpose | Command |
|--------|---------|---------|
| `web-dev.sh` | Development with hot reload | `./web-dev.sh` |
| `web-build-production.sh` | Production build | `./web-build-production.sh` |
| `web-serve.sh` | Serve built app | `./web-serve.sh` |

## 🌐 Web Server Options

### Python (Built-in)
```bash
cd example/build/web
python3 -m http.server 8080
```

### Node.js (Alternative)
```bash
npm install
npm run serve
```

## 🎯 Development Workflow

1. **Start Development Server**:
   ```bash
   ./web-dev.sh
   ```

2. **Make Changes**: Edit your calendar code in the `lib/` directory

3. **See Changes**: Browser automatically refreshes with hot reload

4. **Test Features**: Use browser dev tools for debugging

5. **Build for Production**: When ready, run `./web-build-production.sh`

## 🔍 Browser Testing

- **Chrome**: Best Flutter web support
- **Firefox**: Good compatibility
- **Safari**: Basic support
- **Edge**: Good compatibility

## 📱 Responsive Testing

Use browser dev tools to test different screen sizes:
- Mobile: 375x667 (iPhone SE)
- Tablet: 768x1024 (iPad)
- Desktop: 1920x1080

## 🐛 Debugging

- **Flutter Inspector**: Available in browser dev tools
- **Console Logs**: Check browser console for errors
- **Network Tab**: Monitor API calls and resources
- **Performance**: Use browser performance tools

## 🚀 Deployment

The production build (`example/build/web/`) can be deployed to:
- GitHub Pages
- Netlify
- Vercel
- Firebase Hosting
- Any static web hosting service

## ⚡ Performance Tips

- Use `flutter build web --release` for production builds
- Test on different devices and browsers
- Monitor bundle size and loading times
- Use browser dev tools for performance analysis

## 🔄 Hot Reload Commands

When using hot reload mode:
- `r`: Hot reload (refresh changes)
- `R`: Hot restart (full restart)
- `q`: Quit development server
- `h`: Show help

## 📁 File Structure

```
flutter_calendar_view/
├── web-dev.sh              # Development with hot reload
├── web-build-production.sh # Production build
├── web-serve.sh            # Serve built app
├── package.json            # Node.js scripts
├── example/                # Example app
│   ├── lib/               # Source code
│   └── build/web/         # Web build output
└── WEB_DEVELOPMENT.md      # This file
```

## 🆘 Troubleshooting

### Flutter Web Not Enabled
```bash
flutter config --enable-web
```

### Port Already in Use
Change port in scripts: `--web-port 8081`

### Build Errors
```bash
flutter clean
flutter pub get
flutter build web
```

### Hot Reload Not Working
- Check browser console for errors
- Try hot restart (`R`) instead of hot reload (`r`)
- Restart the development server

## 🔮 Future-Proof Features

- **Auto-detection**: Scripts automatically detect Flutter version
- **Compatibility**: Works with current and future Flutter versions
- **Fallback options**: Multiple server options for different environments
- **Error handling**: Clear error messages and troubleshooting steps
