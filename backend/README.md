# 🎵 Branchr MusicKit Backend Services

Backend services for generating and serving Apple Music Developer Tokens (JWTs) securely.

## 📋 Prerequisites

- **Node.js** 16.0.0 or higher
- **npm** or **yarn**
- **Apple Developer Account** with MusicKit enabled
- **Private Key File** (`AuthKey_S8S2CSHCZ7.p8`) downloaded from Apple Developer Portal

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Place Your Private Key

Ensure `AuthKey_S8S2CSHCZ7.p8` is in the project root (one level up from `backend/`):

```
branchr/
├── AuthKey_S8S2CSHCZ7.p8  ← Place here
├── backend/
│   └── generate_musickit_jwt.js
└── ...
```

### 3. Generate JWT

```bash
npm run generate-jwt
```

This will output a JWT token valid for 180 days.

## ⚙️ Configuration

You can customize the script using environment variables:

```bash
MUSICKIT_KEY_ID=S8S2CSHCZ7 \
MUSICKIT_TEAM_ID=69Y49KN8KD \
MUSICKIT_KEY_PATH=../AuthKey_S8S2CSHCZ7.p8 \
npm run generate-jwt
```

## 🔒 Security Best Practices

1. **Never commit private keys** - Add `.p8` files to `.gitignore`
2. **Store JWTs securely** - Use environment variables or secure vaults
3. **Regenerate before expiration** - Set calendar reminder for 170 days
4. **Use HTTPS endpoints** - Always serve tokens over encrypted connections
5. **Implement token rotation** - Rotate tokens periodically for security

## 📡 Production Integration

For production, create an HTTPS endpoint that:

1. Validates request authentication
2. Generates fresh JWTs on-demand
3. Caches tokens (they're valid for 180 days)
4. Returns tokens to authenticated iOS clients

Example Express.js endpoint:

```javascript
app.get('/api/musickit/token', authenticateUser, async (req, res) => {
    const token = generateMusicKitJWT();
    res.json({ developerToken: token });
});
```

## 🔗 Related Files

- **Swift Integration**: `Services/MusicKitService.swift`
- **Playback Service**: `Services/MusicService.swift`
- **Setup Guide**: `APPLE_MUSIC_DEVELOPER_TOKEN_SETUP.md`

