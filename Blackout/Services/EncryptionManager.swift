import Foundation
import CryptoKit

class EncryptionManager {
    static let shared = EncryptionManager()
    
    private func getEncryptionKey() throws -> SymmetricKey {
        // In a real app, you'd want to securely store and retrieve this key
        // This is just a simple example
        let keyData = "YourSecretKey".data(using: .utf8)!
        return SymmetricKey(data: keyData)
    }
    
    func encrypt(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        let key = try getEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
} 