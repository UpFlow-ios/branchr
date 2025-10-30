import Foundation
import CryptoKit

/// Handles MusicKit developer JWT generation for Branchr
final class MusicKitService {
    static let shared = MusicKitService()

    private let keyID = "S8S2CSHCZ7" // MusicKit Key ID
    private let teamID = "69Y49KN8KD" // Apple Developer Team ID
    private let mediaIdentifier = "69Y49KN8KD.media.com.joedormond.branchr2025"
    private let privateKeyFile = "AuthKey_S8S2CSHCZ7.p8" // Must exist in app bundle

    private var cachedToken: String?
    private var tokenExpiration: Date?

    /// Generate or return cached JWT
    func generateDeveloperToken() throws -> String {
        if let token = cachedToken,
           let expiration = tokenExpiration,
           Date() < expiration {
            return token
        }

        guard let privateKeyURL = Bundle.main.url(forResource: privateKeyFile, withExtension: nil) else {
            throw NSError(domain: "MusicKitService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing .p8 private key file."])
        }

        let privateKeyData = try Data(contentsOf: privateKeyURL)
        let privateKey = try P256.Signing.PrivateKey(pemRepresentation: String(data: privateKeyData, encoding: .utf8)!)

        let header: [String: Any] = ["alg": "ES256", "kid": keyID]
        let iat = Int(Date().timeIntervalSince1970)
        let exp = iat + (60 * 60 * 12) // 12-hour token lifespan
        let payload: [String: Any] = ["iss": teamID, "iat": iat, "exp": exp]

        func base64Encode(_ dict: [String: Any]) -> String {
            let data = try! JSONSerialization.data(withJSONObject: dict, options: [])
            return data.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }

        let headerPart = base64Encode(header)
        let payloadPart = base64Encode(payload)
        let signingInput = "\(headerPart).\(payloadPart)"

        let signature = try privateKey.signature(for: Data(signingInput.utf8))
        let signaturePart = signature.derRepresentation.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let token = "\(signingInput).\(signaturePart)"

        cachedToken = token
        tokenExpiration = Date().addingTimeInterval(60 * 60 * 12)

        return token
    }
    
    /// Get or generate user token for Apple Music playback
    func getUserToken() async throws -> String {
        // This will be implemented when Apple Music user authorization is added
        throw NSError(domain: "MusicKitService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User token not yet implemented. Use MusicKit authorization flow."])
    }
}

