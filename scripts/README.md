# 🎵 Branchr JWT Token Generator

Quick script to generate Apple Music Developer Tokens (JWT) for Branchr.

## 🚀 Quick Start

```bash
cd scripts
npm install
node generateDeveloperToken.js
```

## 📋 What It Does

Generates a secure JWT token that authenticates Branchr with Apple's MusicKit API.

**Token Details:**
- **Algorithm:** ES256 (Elliptic Curve)
- **Key ID:** S8S2CSHCZ7
- **Team ID:** 69Y49KN8KD
- **Expiration:** 180 days
- **Private Key:** `../Resources/AuthKey_S8S2CSHCZ7.p8`

## 📝 Usage

### Generate Token

```bash
node generateDeveloperToken.js
```

### Output

The script will print:
- ✅ The JWT token (starts with `eyJ...`)
- 🕓 Expiration date (ISO format)
- 📊 Token details (algorithm, key ID, issuer, etc.)

### Example Output

```
✅ Generated Developer Token:

eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlM4UzJDU0hDWjcifQ...

🕓 Expires At: 2026-05-02T20:15:43.000Z
```

## 🔧 Integration

### Development (Quick Test)

1. Copy the generated token
2. In `MusicKitService.swift`, you can temporarily hardcode it:
   ```swift
   private let developerToken = "eyJhbGciOiJFUzI1NiIs..."
   ```

### Production (Recommended)

Use the backend endpoint instead:
- Token is generated server-side
- Served via HTTPS endpoint
- Never embedded in app bundle

See `../backend/generate_musickit_jwt.js` for backend implementation.

## 🔒 Security

- ⚠️ **Never commit tokens to Git**
- ⚠️ **Never commit `.p8` private key files**
- ✅ Store tokens in environment variables
- ✅ Use backend endpoint for production
- ✅ Regenerate before expiration

## 📦 Dependencies

- **Node.js** 16.0+
- **jsonwebtoken** (installed via `npm install`)

## 🐛 Troubleshooting

### Error: "Private key file not found"

Ensure `AuthKey_S8S2CSHCZ7.p8` exists in:
```
../Resources/AuthKey_S8S2CSHCZ7.p8
```

### Error: "Missing dependency: jsonwebtoken"

Install dependencies:
```bash
npm install
```

### Error: "Invalid JWT format"

- Verify the `.p8` file is valid PEM format
- Download directly from Apple Developer Portal
- Ensure file hasn't been corrupted

---

**Need Help?** See `../MUSICKIT_JWT_INTEGRATION_GUIDE.md` for complete setup instructions.

