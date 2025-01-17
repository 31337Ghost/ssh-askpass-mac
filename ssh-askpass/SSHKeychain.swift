//
// SSHKeychain.swift
// This file is part of ssh-askpass-mac
//
// Copyright (c) 2019, Lukas Zronek
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

class SSHKeychain {
    
    static let shared = SSHKeychain()
    
    struct DefaultValues {
        static let itemClass = kSecClassGenericPassword
        static let LabelPrefix = "SSH: "
        static let Description = "OpenSSH private key passphrase"
        static let Service = "SSH"
        static let Accessible = kSecAttrAccessibleWhenUnlocked
    }
    
    enum PatternType {
        case prompt
        case failedAttempt
        case confirmation
    }
    
    static let patterns: KeyValuePairs = [
        "^Enter passphrase for (.*?)( \\(will confirm each use\\))?: $": PatternType.prompt,
        "^Bad passphrase, try again for (.*?)( \\(will confirm each use\\))?: $": PatternType.failedAttempt,
        "^Allow use of key (.*)\\?": PatternType.confirmation,
        "^Add key (.*) \\(.*\\) to agent\\?$": PatternType.confirmation
    ]
    
    var message = String()
    var keypath = String()
    var isConfirmation = false
    var failedAttempt = false
    
    private init() {}
    
    class func setup(message: String) {
        shared.message = message
        
        for (pattern, type) in patterns {
            if let keypath = message.parseKeyPath(pattern: pattern) {
                switch type {
                case PatternType.prompt:
                    shared.keypath = keypath
                case PatternType.failedAttempt:
                    shared.keypath = keypath
                    shared.failedAttempt = true
                case PatternType.confirmation:
                    shared.keypath = keypath
                    shared.isConfirmation = true
                }
                break
            }
        }
    }
    
    func get() -> String? {
        var result: AnyObject?
        let query: [CFString: AnyObject] = [
            kSecClass: DefaultValues.itemClass,
            kSecAttrAccount: keypath as CFString,
            kSecMatchLimitOne: kSecMatchLimitOne,
            kSecReturnData: kCFBooleanTrue
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == noErr, let data = result as? Data, let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        return password
    }
    
    func add(password: String) -> OSStatus {
        var status: OSStatus

        let label = "\(DefaultValues.LabelPrefix)\(keypath)"
        
        // no apps are trusted to access the keychain item
        var accessRef: SecAccess?
        status = SecAccessCreate(label as CFString, [] as CFArray, &accessRef)
        if status != errSecSuccess {
            return status
        }
        
        let query: [CFString: Any] = [
            kSecClass: DefaultValues.itemClass,
            kSecAttrLabel: label,
            kSecAttrDescription: DefaultValues.Description,
            kSecAttrService: DefaultValues.Service,
            kSecAttrAccessible: DefaultValues.Accessible,
            kSecAttrAccess: accessRef!,
            kSecAttrAccount: keypath,
            kSecValueData: password
        ]
        
        status = SecItemAdd(query as CFDictionary, nil)
        
        return status
    }
    
    func delete() -> OSStatus {
        let query: [CFString: Any] = [
            kSecClass: DefaultValues.itemClass,
            kSecAttrAccount: keypath
        ]
        return SecItemDelete(query as CFDictionary)
    }
}
