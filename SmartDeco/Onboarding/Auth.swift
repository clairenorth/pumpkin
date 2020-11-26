//
//  Auth.swift
//  pumpkin
//
//  Created by Barnett, Olivia on 11/25/20.
//  Copyright © 2020 Barnett, Olivia. All rights reserved.
//

import Foundation
import Crypto

public class AuthenticationClient {

  private static let serviceName = "SmartDecoService"

  // Use Keychain service to check if previously logged in.
  var isSignedIn: Bool {
    guard let currentUser = Settings.currentUser else {
      return false
    }

    do {
      let password = try KeychainPasswordItem(service: AuthenticationClient.serviceName,
                                              account: currentUser.email)
        .readPassword()
      return password.count > 0
    }
    catch {
      return false
    }
  }

  private func passwordHash(from email: String, password: String) -> String {
    let salt = "x4vV8bGgqqmQwgCoyXFQj+(o.nUNQhVP7ND"
    let inputData = Data("\(password).\(email).\(salt)".utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
  }

  // Sign in and cache log in information
  func signIn(_ user: User, password: String) throws {
    let finalHash = passwordHash(from: user.email, password: password)
    try KeychainPasswordItem(service: AuthenticationClient.serviceName,
                             account: user.email).savePassword(finalHash)

    Settings.currentUser = user
  }

  // Sign out and remove login information from Keychains
  func signOut() throws {
    guard let currentUser = Settings.currentUser else {
      return
    }

    try KeychainPasswordItem(service: AuthenticationClient.serviceName,
                             account: currentUser.email).deleteItem()

    Settings.currentUser = nil
  }
}

final class Settings {

  private enum Keys: String {
    case user = "current_user"
  }

  static var currentUser: User? {
    get {
      guard let data = UserDefaults.standard.data(forKey: Keys.user.rawValue) else {
        return nil
      }
      return try? JSONDecoder().decode(User.self, from: data)
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        UserDefaults.standard.set(data, forKey: Keys.user.rawValue)
      } else {
        UserDefaults.standard.removeObject(forKey: Keys.user.rawValue)
      }
      UserDefaults.standard.synchronize()
    }
  }
}

struct KeychainPasswordItem {
  // MARK: Types

  enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unexpectedItemData
    case unhandledError(status: OSStatus)
  }

  // MARK: Properties

  let service: String

  private(set) var account: String

  let accessGroup: String?

  // MARK: Initialization

  init(service: String, account: String, accessGroup: String? = nil) {
    self.service = service
    self.account = account
    self.accessGroup = accessGroup
  }

  // MARK: Keychain access

  func readPassword() throws -> String  {
    /*
     Build a query to find the item that matches the service, account and
     access group.
     */
    var query = KeychainPasswordItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecReturnAttributes as String] = kCFBooleanTrue
    query[kSecReturnData as String] = kCFBooleanTrue

    // Try to fetch the existing keychain item that matches the query.
    var queryResult: AnyObject?
    let status = withUnsafeMutablePointer(to: &queryResult) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }

    // Check the return status and throw an error if appropriate.
    guard status != errSecItemNotFound else { throw KeychainError.noPassword }
    guard status == noErr else { throw KeychainError.unhandledError(status: status) }

    // Parse the password string from the query result.
    guard let existingItem = queryResult as? [String : AnyObject],
      let passwordData = existingItem[kSecValueData as String] as? Data,
      let password = String(data: passwordData, encoding: String.Encoding.utf8)
      else {
        throw KeychainError.unexpectedPasswordData
    }

    return password
  }

  func savePassword(_ password: String) throws {
    // Encode the password into a Data object.
    let encodedPassword = password.data(using: String.Encoding.utf8)!

    do {
      // Check for an existing item in the keychain.
      try _ = readPassword()

      // Update the existing item with the new password.
      var attributesToUpdate = [String : AnyObject]()
      attributesToUpdate[kSecValueData as String] = encodedPassword as AnyObject?

      let query = KeychainPasswordItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
      let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

      // Throw an error if an unexpected status was returned.
      guard status == noErr else { throw KeychainError.unhandledError(status: status) }
    }
    catch KeychainError.noPassword {
      /*
       No password was found in the keychain. Create a dictionary to save
       as a new keychain item.
       */
      var newItem = KeychainPasswordItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
      newItem[kSecValueData as String] = encodedPassword as AnyObject?

      // Add a the new item to the keychain.
      let status = SecItemAdd(newItem as CFDictionary, nil)

      // Throw an error if an unexpected status was returned.
      guard status == noErr else { throw KeychainError.unhandledError(status: status) }
    }
  }

  mutating func renameAccount(_ newAccountName: String) throws {
    // Try to update an existing item with the new account name.
    var attributesToUpdate = [String : AnyObject]()
    attributesToUpdate[kSecAttrAccount as String] = newAccountName as AnyObject?

    let query = KeychainPasswordItem.keychainQuery(withService: service, account: self.account, accessGroup: accessGroup)
    let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

    // Throw an error if an unexpected status was returned.
    guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }

    self.account = newAccountName
  }

  func deleteItem() throws {
    // Delete the existing item from the keychain.
    let query = KeychainPasswordItem.keychainQuery(withService: service, account: account, accessGroup: accessGroup)
    let status = SecItemDelete(query as CFDictionary)

    // Throw an error if an unexpected status was returned.
    guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
  }

  // MARK: Convenience

  private static func keychainQuery(withService service: String, account: String? = nil, accessGroup: String? = nil) -> [String : AnyObject] {
    var query = [String : AnyObject]()
    query[kSecClass as String] = kSecClassGenericPassword
    query[kSecAttrService as String] = service as AnyObject?

    if let account = account {
      query[kSecAttrAccount as String] = account as AnyObject?
    }

    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
    }

    return query
  }
}

