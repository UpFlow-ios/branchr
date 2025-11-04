#!/usr/bin/env node

/**
 * 🎵 Branchr - Apple Music Developer Token Generator
 * 
 * Generates a JWT Developer Token for Apple MusicKit API authentication.
 * 
 * Usage:
 *   node generateDeveloperToken.js
 * 
 * Output:
 *   - Developer Token (JWT string)
 *   - Expiration date
 *   - Token details
 */

const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');

// ============================================================================
// CONFIGURATION
// ============================================================================

const TEAM_ID = '69Y49KN8KD';
const KEY_ID = 'S8S2CSHCZ7';
const KEY_FILE_PATH = path.join(__dirname, '../Resources/AuthKey_S8S2CSHCZ7.p8');
const TOKEN_EXPIRY_DAYS = 180;
const TOKEN_EXPIRY_SECONDS = TOKEN_EXPIRY_DAYS * 24 * 60 * 60;

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Loads the private key from the .p8 file
 */
function loadPrivateKey() {
    try {
        if (!fs.existsSync(KEY_FILE_PATH)) {
            throw new Error(`❌ Private key file not found at: ${KEY_FILE_PATH}`);
        }

        const privateKey = fs.readFileSync(KEY_FILE_PATH, 'utf8');

        // Basic validation
        if (!privateKey.includes('BEGIN') || !privateKey.includes('PRIVATE KEY')) {
            throw new Error('❌ Invalid private key format. Expected PEM format.');
        }

        console.log(`✅ Loaded private key from: ${path.basename(KEY_FILE_PATH)}`);
        return privateKey;
    } catch (error) {
        console.error('❌ Error loading private key:', error.message);
        process.exit(1);
    }
}

/**
 * Generates the JWT payload
 */
function generatePayload() {
    const now = Math.floor(Date.now() / 1000);
    const expiration = now + TOKEN_EXPIRY_SECONDS;

    return {
        iss: TEAM_ID,           // Issuer: Team ID
        iat: now,               // Issued At: Current timestamp
        exp: expiration         // Expiration: 180 days from now
    };
}

/**
 * Generates the JWT header
 */
function generateHeader() {
    return {
        alg: 'ES256',           // Algorithm: Elliptic Curve Digital Signature Algorithm
        kid: KEY_ID             // Key ID: MusicKit Key ID from Apple Developer Portal
    };
}

// ============================================================================
// MAIN GENERATION
// ============================================================================

function generateDeveloperToken() {
    console.log('\n🎵 Branchr - Apple Music Developer Token Generator\n');
    console.log('═══════════════════════════════════════════════════════\n');

    // Display configuration
    console.log('📋 Configuration:');
    console.log(`   Team ID: ${TEAM_ID}`);
    console.log(`   Key ID: ${KEY_ID}`);
    console.log(`   Key File: ${KEY_FILE_PATH}`);
    console.log(`   Expiry: ${TOKEN_EXPIRY_DAYS} days (${TOKEN_EXPIRY_DAYS * 24} hours)\n`);

    // Load private key
    const privateKey = loadPrivateKey();

    // Generate JWT components
    const header = generateHeader();
    const payload = generatePayload();

    // Calculate expiration date for display
    const expirationDate = new Date(payload.exp * 1000);

    // Sign the JWT
    try {
        const token = jwt.sign(payload, privateKey, {
            algorithm: 'ES256',
            header: header
        });

        // Verify token format
        const parts = token.split('.');
        if (parts.length !== 3) {
            throw new Error('Invalid JWT format generated');
        }

        // Display success
        console.log('═══════════════════════════════════════════════════════\n');
        console.log('✅ Generated Developer Token:\n');
        console.log(token);
        console.log('\n═══════════════════════════════════════════════════════\n');

        // Display token details
        console.log('📊 Token Details:');
        console.log(`   Algorithm: ${header.alg}`);
        console.log(`   Key ID: ${header.kid}`);
        console.log(`   Issuer: ${payload.iss}`);
        console.log(`   Issued At: ${new Date(payload.iat * 1000).toISOString()}`);
        console.log(`   Expires At: ${expirationDate.toISOString()}`);
        console.log(`   Valid For: ${TOKEN_EXPIRY_DAYS} days\n`);

        // Security reminder
        console.log('⚠️  SECURITY REMINDER:');
        console.log('   • Never commit this token to version control');
        console.log('   • Store tokens securely (environment variables, secure vault)');
        console.log('   • Regenerate tokens before expiration');
        console.log('   • For production, use backend endpoint to serve tokens\n');

        // Copy instructions
        console.log('📋 Next Steps:');
        console.log('   1. Copy the token above (starts with eyJ...)');
        console.log('   2. For development: Paste into MusicKitService.swift');
        console.log('   3. For production: Use backend endpoint instead');
        console.log('   4. Test MusicKit authorization in your app\n');

        return token;

    } catch (error) {
        console.error('❌ Error generating JWT:', error.message);

        if (error.message.includes('PEM')) {
            console.error('\n💡 Tip: Ensure your .p8 file is in valid PEM format.');
            console.error('   Download the key file directly from Apple Developer Portal.');
        }

        if (error.message.includes('ES256')) {
            console.error('\n💡 Tip: Ensure jsonwebtoken package supports ES256.');
            console.error('   Install: npm install jsonwebtoken');
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

// Generate the token
const token = generateDeveloperToken();

// Export for use in other modules (if imported)
if (require.main === module) {
    // Script was run directly
    process.exit(0);
} else {
    // Script was imported as a module
    module.exports = { generateDeveloperToken };
}

