import Foundation
import CommonCrypto

import Foundation
import CommonCrypto

class AESDecryption {
    private let key: String
    private let iv: String
    private let encryptedText: String
    
    init(key: String, iv: String, encryptedText: String) {
        self.key = key
        self.iv = iv
        self.encryptedText = encryptedText
    }
    
    func decrypt() -> String? {
        let (keyBytes, ivBytes, ciphertextBytes) = prepareEncryptionData()
        return decryptData(keyBytes: keyBytes, ivBytes: ivBytes, ciphertextBytes: ciphertextBytes)
    }
    
    private func prepareEncryptionData() -> ([UInt8], [UInt8], [UInt8]) {
        guard let keyData = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8),
              let ciphertextData = Data(base64Encoded: encryptedText) else {
            print("Error: Invalid encryption keys or ciphertext.")
            return ([], [], [])
        }

        var keyBytes = [UInt8](repeating: 0, count: keyData.count)
        keyData.copyBytes(to: &keyBytes, count: keyData.count)

        var ivBytes = [UInt8](repeating: 0, count: ivData.count)
        ivData.copyBytes(to: &ivBytes, count: ivData.count)

        var ciphertextBytes = [UInt8](repeating: 0, count: ciphertextData.count)
        ciphertextData.copyBytes(to: &ciphertextBytes, count: ciphertextData.count)

        return (keyBytes, ivBytes, ciphertextBytes)
    }

    private func decryptData(keyBytes: [UInt8], ivBytes: [UInt8], ciphertextBytes: [UInt8]) -> String? {
        do {
            let decryptedData = try QCCAESPadCBCDecrypt(key: keyBytes, iv: ivBytes, cyphertext: ciphertextBytes)
            let decryptedDataObject = Data(decryptedData)

            if let decryptedString = String(data: decryptedDataObject, encoding: .utf8) {
                return decryptedString
            } else {
                print("Decryption Error: Decrypted data is not a valid UTF-8 string.")
                return nil
            }
        } catch {
            print("Decryption Error: Failed to decrypt data - \(error.localizedDescription)")
            return nil
        }
    }
    
    
    func QCCAESPadCBCDecrypt(key: [UInt8], iv: [UInt8], cyphertext: [UInt8]) throws -> [UInt8] {

        // The key size must be 128, 192, or 256.
        //
        // The IV size must match the block size.
        //
        // The ciphertext must be a multiple of the block size.

        guard
            [kCCKeySizeAES128, kCCKeySizeAES192, kCCKeySizeAES256].contains(key.count),
            iv.count == kCCBlockSizeAES128,
            cyphertext.count.isMultiple(of: kCCBlockSizeAES128)
        else {
            throw QCCError(code: kCCParamError)
        }

        // Padding can expand the data on encryption, but on decryption the data can
        // only shrink so we use the cyphertext size as our plaintext size.

        var plaintext = [UInt8](repeating: 0, count: cyphertext.count)
        var plaintextCount = 0
        let err = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            key, key.count,
            iv,
            cyphertext, cyphertext.count,
            &plaintext, plaintext.count,
            &plaintextCount
        )
        guard err == kCCSuccess else {
            throw QCCError(code: err)
        }
        
        // Trim any unused bytes off the plaintext.
        
        assert(plaintextCount <= plaintext.count)
        plaintext.removeLast(plaintext.count - plaintextCount)

        return plaintext
    }

}

struct QCCError: Error {
    var code: CCCryptorStatus
}

extension QCCError {
    init(code: Int) {
        self.init(code: CCCryptorStatus(code))
    }
}
