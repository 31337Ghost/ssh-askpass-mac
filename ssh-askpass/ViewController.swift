//
// ViewController.swift
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

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var infoTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var keychainCheckBox: NSButtonCell!
    
    let sshKeychain = SSHKeychain.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !sshKeychain.message.isEmpty {
            infoTextField.stringValue = sshKeychain.message
        }
        
        if sshKeychain.isConfirmation {
            passwordTextField.isHidden = true
            if let controlView = keychainCheckBox.controlView {
                controlView.isHidden = true
            }
        } else if sshKeychain.keypath.isEmpty {
            keychainCheckBox.state = NSControl.StateValue.off
            keychainCheckBox.isEnabled = false
        } else {
            if let obj = UserDefaults.standard.object(forKey: "useKeychain") {
                if let useKeychain = obj as? Bool {
                    if (useKeychain) {
                        keychainCheckBox.state = NSControl.StateValue.on
                    } else {
                        keychainCheckBox.state = NSControl.StateValue.off
                    }
                }
            }
        }
    }

    @IBAction func cancel(_ sender: Any) {
        exit(1)
    }
    
    @IBAction func ok(_ sender: Any) {
        exit(0)
    }
    
    @IBAction func useKeychainChanged(_ sender: NSButtonCell) {
        var useKeychain:Bool = false
        if (sender.state == NSControl.StateValue.on) {
            useKeychain = true
        }
        UserDefaults.standard.set(useKeychain, forKey: "useKeychain")
    }
    
    func keychainError(status: OSStatus) {
        error(messageText: "Keychain Error", informativeText: SecCopyErrorMessageString(status, nil)! as String)
    }
    
    func error(messageText: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        #if swift(>=4.2)
        let cautionName = NSImage.cautionName
        #else
        let cautionName = NSImage.Name.caution
        #endif
        alert.icon = NSImage(named: cautionName)
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    func ask(messageText: String, informativeText: String, okButtonTitle: String, completionHandler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        #if swift(>=4.2)
        let cautionName = NSImage.cautionName
        #else
        let cautionName = NSImage.Name.caution
        #endif
        alert.icon = NSImage(named: cautionName)
        _ = alert.addButton(withTitle: okButtonTitle)
        _ = alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: self.view.window!, completionHandler: completionHandler)
    }
}
