import SwiftUI
import CoreData
import CryptoKit

// MARK: - AuthViewModel
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUserID: String = ""
    @Published var currentUserName: String = ""
    @Published var currentEmail: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    private let defaults = UserDefaults.standard
    private let kLoggedInUserID = "trackflow_logged_in_user_id"
    private let kLoggedInEmail  = "trackflow_logged_in_email"
    private let kLoggedInName   = "trackflow_logged_in_name"

    init() {
        // Restore session
        if let uid = defaults.string(forKey: kLoggedInUserID), !uid.isEmpty {
            currentUserID   = uid
            currentEmail    = defaults.string(forKey: kLoggedInEmail) ?? ""
            currentUserName = defaults.string(forKey: kLoggedInName) ?? ""
            isLoggedIn = true
        }
    }

    // MARK: - Register
    func register(name: String, email: String, password: String,
                  context: NSManagedObjectContext) {
        errorMessage = ""
        let trimEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        let trimName  = name.trimmingCharacters(in: .whitespaces)

        guard !trimName.isEmpty else { errorMessage = "Please enter your name."; return }
        guard trimEmail.contains("@") else { errorMessage = "Enter a valid email."; return }
        guard password.count >= 6 else { errorMessage = "Password must be at least 6 characters."; return }

        // Check for existing account
        let req = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        req.predicate = NSPredicate(format: "email == %@", trimEmail)
        let existing = (try? context.fetch(req)) ?? []
        guard existing.isEmpty else { errorMessage = "An account with this email already exists."; return }

        isLoading = true
        let uid = UUID().uuidString
        let profile = UserProfile(context: context)
        profile.id        = UUID()
        profile.email     = trimEmail
        profile.name      = trimName
        profile.createdAt = Date()

        // Store hashed password in Keychain
        KeychainHelper.save(key: "pwd_\(uid)", value: hash(password))

        // Store UID → email mapping so login can find the profile
        defaults.set(uid, forKey: "uid_for_\(trimEmail)")
        defaults.set(trimName, forKey: "name_for_\(trimEmail)")

        do {
            try context.save()
            persistSession(uid: uid, email: trimEmail, name: trimName)
        } catch {
            errorMessage = "Registration failed. Please try again."
        }
        isLoading = false
    }

    // MARK: - Login
    func login(email: String, password: String, context: NSManagedObjectContext) {
        errorMessage = ""
        let trimEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard trimEmail.contains("@"), !password.isEmpty else {
            errorMessage = "Please enter a valid email and password."; return
        }

        isLoading = true

        guard let uid = defaults.string(forKey: "uid_for_\(trimEmail)") else {
            errorMessage = "No account found with this email."
            isLoading = false; return
        }

        let storedHash = KeychainHelper.read(key: "pwd_\(uid)") ?? ""
        guard storedHash == hash(password) else {
            errorMessage = "Incorrect password."
            isLoading = false; return
        }

        let name = defaults.string(forKey: "name_for_\(trimEmail)") ?? "User"
        persistSession(uid: uid, email: trimEmail, name: name)
        isLoading = false
    }

    // MARK: - Logout
    func logout() {
        defaults.removeObject(forKey: kLoggedInUserID)
        defaults.removeObject(forKey: kLoggedInEmail)
        defaults.removeObject(forKey: kLoggedInName)
        currentUserID   = ""
        currentEmail    = ""
        currentUserName = ""
        isLoggedIn = false
    }

    // MARK: - Helpers
    private func persistSession(uid: String, email: String, name: String) {
        currentUserID   = uid
        currentEmail    = email
        currentUserName = name
        defaults.set(uid,   forKey: kLoggedInUserID)
        defaults.set(email, forKey: kLoggedInEmail)
        defaults.set(name,  forKey: kLoggedInName)
        isLoggedIn = true
    }

    private func hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Keychain Helper
struct KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
