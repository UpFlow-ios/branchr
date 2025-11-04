#!/usr/bin/env node

/**
 * 🎵 Branchr Backend Server - MusicKit JWT Endpoint
 *
 * Example Express.js server for serving MusicKit Developer Tokens securely.
 * 
 * ⚠️ SECURITY NOTES:
 * - This is a template/example - implement proper authentication before production
 * - Use HTTPS in production
 * - Rate limit token requests
 * - Implement proper error handling and logging
 * - Store private keys securely (not in version control)
 */

const express = require('express');
const { generateMusicKitJWT } = require('./generate_musickit_jwt');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// ============================================================================
// MIDDLEWARE
// ============================================================================

// Enable CORS for iOS app (adjust origins for production)
app.use(cors({
    origin: ['http://localhost:3000', 'https://api.branchr.app'],
    credentials: true
}));

// Parse JSON bodies
app.use(express.json());

// ============================================================================
// AUTHENTICATION MIDDLEWARE (Example)
// ============================================================================

/**
 * Example authentication middleware
 * Replace with your actual auth system (JWT, OAuth, etc.)
 */
function authenticateRequest(req, res, next) {
    // Example: Check for API key in header
    const apiKey = req.headers['x-api-key'];

    // TODO: Implement proper authentication
    // For now, we'll allow all requests (NEVER do this in production!)
    if (!apiKey) {
        console.warn('⚠️ Request without API key');
        // Uncomment to enforce authentication:
        // return res.status(401).json({ error: 'Unauthorized' });
    }

    next();
}

// ============================================================================
// ROUTES
// ============================================================================

/**
 * GET /api/musickit/token
 * 
 * Returns a fresh MusicKit Developer Token (JWT)
 * 
 * Response:
 * {
 *   "developerToken": "eyJhbGciOiJFUzI1NiIs...",
 *   "expiresAt": "2025-07-27T00:00:00.000Z",
 *   "keyId": "S8S2CSHCZ7",
 *   "teamId": "69Y49KN8KD"
 * }
 */
app.get('/api/musickit/token', authenticateRequest, (req, res) => {
    try {
        console.log('📥 MusicKit token request received');

        // Generate JWT token
        const token = generateMusicKitJWT();

        // Decode to get expiration (for response)
        const jwt = require('jsonwebtoken');
        const decoded = jwt.decode(token, { complete: true });
        const expiresAt = new Date(decoded.payload.exp * 1000);

        // Return token
        res.json({
            developerToken: token,
            expiresAt: expiresAt.toISOString(),
            keyId: process.env.MUSICKIT_KEY_ID || 'S8S2CSHCZ7',
            teamId: process.env.MUSICKIT_TEAM_ID || '69Y49KN8KD'
        });

        console.log('✅ Token generated and sent');

    } catch (error) {
        console.error('❌ Error generating token:', error);
        res.status(500).json({
            error: 'Failed to generate token',
            message: error.message
        });
    }
});

/**
 * GET /api/health
 * Simple health check endpoint
 */
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'branchr-musickit-backend' });
});

// ============================================================================
// ERROR HANDLING
// ============================================================================

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('❌ Server error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
});

// ============================================================================
// SERVER START
// ============================================================================

app.listen(PORT, () => {
    console.log('\n🎵 Branchr MusicKit Backend Server');
    console.log('═══════════════════════════════════════════════════════\n');
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`📡 Endpoints:`);
    console.log(`   GET  /api/musickit/token - Generate JWT token`);
    console.log(`   GET  /api/health         - Health check`);
    console.log('\n⚠️  Remember to implement proper authentication!');
    console.log('═══════════════════════════════════════════════════════\n');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('\n👋 Shutting down server...');
    process.exit(0);
});

