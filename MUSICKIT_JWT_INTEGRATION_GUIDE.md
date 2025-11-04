# 🎵 Branchr MusicKit JWT Integration Guide

Complete guide for integrating Apple Music (MusicKit) with Branchr using secure JWT tokens.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Setup Instructions](#setup-instructions)
4. [iOS Integration](#ios-integration)
5. [Backend Setup](#backend-setup)
6. [Security Best Practices](#security-best-practices)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

Branchr uses **MusicKit** to provide Apple Music integration for DJ mode during group rides. The integration requires:

- **Developer Token (JWT)**: Authenticates your app with Apple's MusicKit API
- **User Token**: Authorizes access to the user's Apple Music account
- **MusicKit Entitlements**: Enabled in Apple Developer Portal

### Key Files

| File | Purpose |
|------|---------|
| `backend/generate_musickit_jwt.js` | Node.js script to generate JWT tokens |
| `backend/server.js` | Example Express.js server for token endpoint |
| `Services/MusicKitService.swift` | Swift service for MusicKit integration |
| `Services/MusicService.swift` | Playback and music management service |

---

## 🏗️ Architecture

```
┌─────────────────┐
│  iOS App        │
│  (Branchr)       │
│                 │
│  MusicService   │◄───┐
│       │         │    │
│       ▼         │    │
│  MusicKitService│    │
│       │         │    │
└───────┼─────────┘    │
        │              │
        │              │
        │ GET Token    │ User Authorization
        │              │
        ▼              │
┌─────────────────┐    │
│  Backend Server │    │
│  (Express.js)   │    │
│                 │    │
│  /api/musickit/ │    │
│  token          │    │
│       │         │    │
│       ▼         │    │
│  generateMusic  │    │
│  KitJWT()       │    │
│       │         │    │
│       ▼         │    │
│  .p8 Private    │    │
│  Key File       │    │
└─────────────────┘    │
                       │
                       │
┌──────────────────────┘
│
│  Apple MusicKit API
│  - Catalog Search
│  - Playback
│  - User Library
└──────────────────────┘
```

---

## 🚀 Setup Instructions

### Step 1: Get Your MusicKit Credentials

1. **Apple Developer Portal**
   - Go to [developer.apple.com](https://developer.apple.com)
   - Navigate to **Certificates, Identifiers & Profiles**
   - Under **Keys**, create a new MusicKit Key
   - Download the `.p8` private key file
   - Note the **Key ID** (e.g., `S8S2CSHCZ7`)
   - Note your **Team ID** (e.g., `69Y49KN8KD`)

2. **App ID Configuration**
   - Ensure your App ID has **MusicKit** capability enabled
   - Bundle ID: `com.joedormond.branchr2025`

### Step 2: Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Place your private key file
# Should be at: ../AuthKey_S8S2CSHCZ7.p8

# Test JWT generation
npm run generate-jwt
```

**Expected Output:**
```
🎵 Branchr MusicKit JWT Generator
═══════════════════════════════════════════════════════

📋 Configuration:
   Key ID: S8S2CSHCZ7
   Team ID: 69Y49KN8KD
   ...
   
✅ JWT Generated Successfully!
📝 Developer Token (JWT):
eyJhbGciOiJFUzI1NiIs...
```

### Step 3: iOS App Configuration

1. **Add Private Key to Xcode** (Development Only)
   - Drag `AuthKey_S8S2CSHCZ7.p8` into your Xcode project
   - ✅ **IMPORTANT**: Uncheck "Copy items if needed"
   - ✅ Ensure it's added to the app target (NOT the bundle)
   - ⚠️ **For production**: Remove from bundle, use backend only

2. **Verify Entitlements**
   - Open `branchr.entitlements`
   - Ensure these keys exist:
     ```xml
     <key>com.apple.developer.music-user-token</key>
     <true/>
     <key>com.apple.developer.music.subscription-service</key>
     <true/>
     ```

3. **Verify Info.plist**
   - Open `branchr/Info.plist`
   - Ensure `NSAppleMusicUsageDescription` exists:
     ```xml
     <key>NSAppleMusicUsageDescription</key>
     <string>Branchr requires access to Apple Music for DJ playback and interactive audio experiences.</string>
     ```

---

## 📱 iOS Integration

### Basic Usage

```swift
import MusicKit

// Initialize MusicKitService
let musicKitService = MusicKitService.shared

// Configure MusicKit (call once at app launch)
await musicKitService.configureMusicKit(useBackend: false) // false = use local key

// Request user authorization
do {
    let userToken = try await musicKitService.requestUserToken()
    print("✅ User authorized: \(userToken)")
} catch {
    print("❌ Authorization failed: \(error)")
}

// Search catalog
do {
    let response = try await musicKitService.searchCatalog(term: "Calvin Harris")
    print("Found \(response.songs.count) songs")
} catch {
    print("Search failed: \(error)")
}
```

### Integration with MusicService

`MusicService.swift` already uses MusicKit for playback. To use `MusicKitService` for token management:

```swift
// In MusicService.swift init() or app launch:
Task {
    await MusicKitService.shared.configureMusicKit()
}
```

---

## 🔧 Backend Setup

### Development Server

```bash
cd backend
npm install
npm start
```

Server runs on `http://localhost:3000`

### Production Deployment

1. **Environment Variables**
   ```bash
   MUSICKIT_KEY_ID=S8S2CSHCZ7
   MUSICKIT_TEAM_ID=69Y49KN8KD
   MUSICKIT_KEY_PATH=/secure/path/to/AuthKey_S8S2CSHCZ7.p8
   NODE_ENV=production
   PORT=3000
   ```

2. **Update iOS App**
   ```swift
   // In MusicKitService.swift, update:
   private let backendTokenURL = "https://api.branchr.app/musickit/token"
   ```

3. **Use Backend Token**
   ```swift
   await musicKitService.configureMusicKit(useBackend: true)
   ```

### Authentication

**⚠️ CRITICAL**: Implement authentication before production!

```javascript
// Example: API Key authentication
function authenticateRequest(req, res, next) {
    const apiKey = req.headers['x-api-key'];
    
    if (apiKey !== process.env.API_KEY) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    
    next();
}

app.get('/api/musickit/token', authenticateRequest, ...);
```

---

## 🔒 Security Best Practices

### ✅ DO:

1. **Never commit private keys**
   - Add `*.p8` to `.gitignore`
   - Use environment variables for paths
   - Store keys in secure vaults (AWS Secrets Manager, etc.)

2. **Use HTTPS in production**
   - Never serve tokens over HTTP
   - Use SSL/TLS certificates

3. **Implement rate limiting**
   - Prevent token abuse
   - Use Redis or similar for rate limiting

4. **Cache tokens server-side**
   - Tokens are valid for 180 days
   - Cache to reduce key file reads

5. **Rotate keys periodically**
   - Set reminder for 170 days
   - Generate new tokens before expiration

### ❌ DON'T:

1. **Never embed .p8 keys in iOS app bundle**
   - Keys can be extracted from app bundles
   - Always use backend for production

2. **Don't log full tokens**
   - Log only first/last few characters
   - Example: `eyJhbGci...xyz`

3. **Don't expose tokens in URLs**
   - Use POST requests with body
   - Or use Authorization headers

---

## 🐛 Troubleshooting

### Error: "Client not found" (404)

**Problem**: App bundle ID not registered for MusicKit

**Solution**:
1. Go to Apple Developer Portal
2. Select your App ID
3. Enable **MusicKit** capability
4. Regenerate provisioning profile
5. Re-download and install profile in Xcode

### Error: "Failed to request developer token"

**Problem**: Developer token generation failed

**Solutions**:
1. Verify `.p8` key file exists in bundle (dev) or backend path (prod)
2. Check Key ID and Team ID match Apple Developer Portal
3. Ensure private key is valid PEM format
4. Try regenerating JWT: `npm run generate-jwt`

### Error: "User denied Apple Music access"

**Problem**: User declined authorization prompt

**Solution**:
- Show informative message
- Direct user to Settings > Branchr > Apple Music
- Re-request authorization after explanation

### Error: "Missing .p8 private key file"

**Problem**: Key file not found in app bundle

**Solutions**:
- **Development**: Add key to Xcode project (uncheck "Copy items")
- **Production**: Use backend endpoint instead
- Set `useBackend: true` in `configureMusicKit()`

### Catalog Search Returns Empty

**Problem**: MusicKit not properly configured

**Solutions**:
1. Verify user is authorized: `checkAuthorizationStatus()`
2. Ensure developer token is valid (check expiration)
3. Try library playback as fallback (works without catalog access)

---

## 📚 Additional Resources

- [Apple MusicKit Documentation](https://developer.apple.com/documentation/musickit)
- [MusicKit Developer Token Guide](https://developer.apple.com/documentation/applemusicapi/getting_keys_and_creating_tokens)
- [JWT.io](https://jwt.io) - JWT token decoder/debugger

---

## ✅ Checklist

- [ ] MusicKit key created in Apple Developer Portal
- [ ] `.p8` key file downloaded
- [ ] App ID has MusicKit capability enabled
- [ ] Entitlements file includes MusicKit keys
- [ ] Info.plist includes `NSAppleMusicUsageDescription`
- [ ] Backend server running (production)
- [ ] JWT generation working (`npm run generate-jwt`)
- [ ] iOS app requests authorization successfully
- [ ] Catalog search returns results
- [ ] Music playback works

---

## 🎉 Success!

Once all steps are complete, you should be able to:
- ✅ Generate JWT tokens (backend)
- ✅ Request user authorization (iOS)
- ✅ Search Apple Music catalog
- ✅ Play music during rides

**Next Steps:**
- Implement backend authentication
- Deploy backend to production server
- Add token refresh logic
- Implement catalog search UI
- Add playlist management features

---

**Questions?** Check the troubleshooting section or review Apple's MusicKit documentation.

