import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 88, height: 88)
                                Text(initials)
                                    .font(.custom("Georgia-Bold", size: 32))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color(hex: "#3b82f6").opacity(0.4), radius: 16, y: 6)

                            Text(authVM.currentUserName)
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(.white)
                            Text(authVM.currentEmail)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(hex: "#475569"))
                        }
                        .padding(.top, 32)

                        // Info card
                        VStack(spacing: 0) {
                            ProfileRow(icon: "person.fill", label: "Name", value: authVM.currentUserName)
                            Divider().background(Color(hex: "#0f1e35"))
                            ProfileRow(icon: "envelope.fill", label: "Email", value: authVM.currentEmail)
                            Divider().background(Color(hex: "#0f1e35"))
                            ProfileRow(icon: "icloud.fill", label: "Sync", value: "CoreData + CloudKit")
                        }
                        .background(Color(hex: "#0a1628"))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: "#1e3a5f"), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // About card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "#475569"))
                                .kerning(2)
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                            Divider().background(Color(hex: "#0f1e35"))
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(Color(hex: "#60a5fa"))
                                Text("TrackFlow v1.0")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#94a3b8"))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                        }
                        .background(Color(hex: "#0a1628"))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: "#1e293b"), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // Sign out
                        Button {
                            showLogoutAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(Color(hex: "#f87171"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(hex: "#2d1515"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: "#ef4444").opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#060d1a"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Sign Out?", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) { authVM.logout() }
            } message: {
                Text("You'll need to sign in again to access your tasks.")
            }
        }
        .preferredColorScheme(.dark)
    }

    var initials: String {
        let parts = authVM.currentUserName.split(separator: " ")
        let letters = parts.compactMap { $0.first }.prefix(2)
        return letters.map(String.init).joined().uppercased()
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#475569"))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#64748b"))
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#94a3b8"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
