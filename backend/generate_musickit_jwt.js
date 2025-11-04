#!/usr/bin/env node

/**
 * 🎵 Branchr MusicKit JWT Generator
 * 
 * Generates a secure Apple Music Developer Token (JWT) for use with the MusicKit API.
 * This token authenticates Branchr's backend with Apple's MusicKit service.
 * 
 * ⚠️ SECURITY NOTE:
 * - This script should run on your backend server, NOT in the iOS app
 * - The .p8 private key file should NEVER be included in the app bundle
 * - Generate JWTs server-side and expose them via a secure HTTPS endpoint
 * 
 * Usage:
 *   node generate_musickit_jwt.js
 * 
 * Environment Variables (optional):
 *   MUSICKIT_KEY_PATH - Path to .p8 private key file (default: ../AuthKey_S8S2CSHCZ7.p8)
 *   MUSICKIT_KEY_ID - MusicKit Key ID (default: S8S2CSHCZ7)
 *   MUSICKIT_TEAM_ID - Apple Developer Team ID (default: 69Y49KN8KD)
 */

const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

// ============================================================================
// CONFIGURATION
// ============================================================================

const MUSICKIT_KEY_ID = process.env.MUSICKIT_KEY_ID || 'S8S2CSHCZ7';
const MUSICKIT_TEAM_ID = process.env.MUSICKIT_TEAM_ID || '69Y49KN8KD';
const MUSICKIT_KEY_PATH = process.env.MUSICKIT_KEY_PATH || path.join(__dirname, '../AuthKey_S8S2CSHCZ7.p8');

// Token expiration: 180 days (as recommended by Apple)
const TOKEN_EXPIRY_DAYS = 180;
const TOKEN_EXPIRY_SECONDS = TOKEN_EXPIRY_DAYS * 24 * 60 * 60;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Reads the private key file from disk
 * @returns {string} PEM-formatted private key
 */
function loadPrivateKey() {
    try {
        const keyPath = path.resolve(MUSICKIT_KEY_PATH);

        if (!fs.existsSync(keyPath)) {
            throw new Error(`❌ Private key file not found at: ${keyPath}`);
        }

        const privateKey = fs.readFileSync(keyPath, 'utf8');

        // Basic validation: ensure it's a valid PEM file
        if (!privateKey.includes('BEGIN PRIVATE KEY') && !privateKey.includes('BEGIN EC PRIVATE KEY')) {
            throw new Error('❌ Invalid private key format. Expected PEM format.');
        }

        console.log(`✅ Loaded private key from: ${keyPath}`);
        return privateKey;
    } catch (error) {
        console.error('❌ Error loading private key:', error.message);
        process.exit(1);
    }
}

/**
 * Generates the JWT payload for Apple Music API
 * @returns {Object} JWT payload object
 */
function generatePayload() {
    const now = Math.floor(Date.now() / 1000); // Current Unix timestamp (seconds)
    const expiration = now + TOKEN_EXPIRY_SECONDS;

    return {
        iss: MUSICKIT_TEAM_ID,           // Issuer: Your Apple Developer Team ID
        iat: now,                         // Issued At: Current timestamp
        exp: expiration                   // Expiration: 180 days from now
    };
}

/**
 * Generates the JWT header
 * @returns {Object} JWT header object
 */
function generateHeader() {
    return {
        alg: 'ES256',                     // Algorithm: Elliptic Curve Digital Signature Algorithm
        kid: MUSICKIT_KEY_ID              // Key ID: Your MusicKit Key ID from Apple Developer Portal
    };
}

// ============================================================================
// MAIN JWT GENERATION
// ============================================================================

/**
 * Main function to generate the Apple Music Developer Token
 */
function generateMusicKitJWT() {
    console.log('\n🎵 Branchr MusicKit JWT Generator\n');
    console.log('═══════════════════════════════════════════════════════\n');

    // Display configuration
    console.log('📋 Configuration:');
    console.log(`   Key ID: ${MUSICKIT_KEY_ID}`);
    console.log(`   Team ID: ${MUSICKIT_TEAM_ID}`);
    console.log(`   Key Path: ${path.resolve(MUSICKIT_KEY_PATH)}`);
    console.log(`   Expiry: ${TOKEN_EXPIRY_DAYS} days\n`);

    // Load private key
    const privateKey = loadPrivateKey();

    // Generate JWT components
    const header = generateHeader();
    const payload = generatePayload();

    // Sign the JWT
    try {
        const token = jwt.sign(payload, privateKey, {
            algorithm: 'ES256',
            header: header,
            expiresIn: `${TOKEN_EXPIRY_DAYS}d`
        });

        // Verify token format
        const parts = token.split('.');
        if (parts.length !== 3) {
            throw new Error('Invalid JWT format generated');
        }

        // Display success
        console.log('✅ JWT Generated Successfully!\n');
        console.log('═══════════════════════════════════════════════════════\n');
        console.log('📝 Developer Token (JWT):\n');
        console.log(token);
        console.log('\n═══════════════════════════════════════════════════════\n');

        // Display token info
        const decoded = jwt.decode(token, { complete: true });
        console.log('📊 Token Details:');
        console.log(`   Algorithm: ${decoded.header.alg}`);
        console.log(`   Key ID: ${decoded.header.kid}`);
        console.log(`   Issuer: ${decoded.payload.iss}`);
        console.log(`   Issued At: ${new Date(decoded.payload.iat * 1000).toISOString()}`);
        console.log(`   Expires At: ${new Date(decoded.payload.exp * 1000).toISOString()}`);
        console.log(`   Valid For: ${TOKEN_EXPIRY_DAYS} days\n`);

        // Security reminder
        console.log('⚠️  SECURITY REMINDER:');
        console.log('   • Never commit this token to version control');
        console.log('   • Store tokens securely (environment variables, secure vault)');
        console.log('   • Regenerate tokens before expiration');
        console.log('   • Use HTTPS endpoints to serve tokens to iOS app\n');

        return token;

    } catch (error) {
        console.error('❌ Error generating JWT:', error.message);

        if (error.message.includes('PEM')) {
            console.error('\n💡 Tip: Ensure your .p8 file is in valid PEM format.');
            console.error('   Download the key file directly from Apple Developer Portal.');
        }

        if (error.message.includes('ES256')) {
            console.error('\n💡 Tip: Ensure you\'re using Node.js with crypto support for ES256.');
            console.error('   Update Node.js if needed: npm install -g n && n latest');
        }

        process.exit(1);
    }
}

// ============================================================================
// EXECUTION
// ============================================================================

// Check if jsonwebtoken is installed
try {
    require.resolve('jsonwebtoken');
} catch (error) {
    console.error('❌ Missing dependency: jsonwebtoken');
    console.error('\n📦 Install it with:');
    console.error('   npm install jsonwebtoken\n');
    process.exit(1);
}

// Generate the JWT
const token = generateMusicKitJWT();

// Export for use in other modules (if imported)
if (require.main === module) {
    // Script was run directly
    process.exit(0);
} else {
    // Script was imported as a module
    module.exports = { generateMusicKitJWT };
}

