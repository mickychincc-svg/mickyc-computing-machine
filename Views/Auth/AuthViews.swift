import SwiftUI
import CoreData

// MARK: - Auth Flow Container
struct AuthFlowView: View {
    @State private var showRegister = false

    var body: some View {
        ZStack {
            AppBackground()
            if showRegister {
                RegisterView(showRegister: $showRegister)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else {
                LoginView(showRegister: $showRegister)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showRegister)
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @Binding var showRegister: Bool

    @State private var email    = ""
    @State private var password = ""
    @State private var showPwd  = false
    @FocusState private var focused: Field?
    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Logo area
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color(hex: "#3b82f6").opacity(0.5), radius: 20, y: 8)

                    Text("TrackFlow")
                        .font(.custom("Georgia-Bold", size: 32))
                        .foregroundColor(.white)

                    Text("Sign in to continue")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#64748b"))
                }
                .padding(.top, 70)
                .padding(.bottom, 44)

                // Form
                VStack(spacing: 14) {
                    AuthField(icon: "envelope", placeholder: "Email", text: $email,
                              isSecure: false, focused: $focused, field: .email)

                    AuthField(icon: "lock", placeholder: "Password", text: $password,
                              isSecure: !showPwd, focused: $focused, field: .password,
                              trailingAction: {
                        Button { showPwd.toggle() } label: {
                            Image(systemName: showPwd ? "eye.slash" : "eye")
                                .foregroundColor(Color(hex: "#475569"))
                                .font(.system(size: 15))
                        }
                    })

                    if !authVM.errorMessage.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(authVM.errorMessage)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#f87171"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .transition(.opacity)
                    }

                    Button {
                        authVM.login(email: email, password: password, context: context)
                    } label: {
                        HStack(spacing: 8) {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)

                // Register link
                HStack(spacing: 6) {
                    Text("Don't have an account?")
                        .foregroundColor(Color(hex: "#475569"))
                    Button("Create one") { showRegister = true }
                        .foregroundColor(Color(hex: "#60a5fa"))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14))
                .padding(.top, 28)
            }
        }
        .onTapGesture { focused = nil }
    }
}

// MARK: - Register View
struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.managedObjectContext) var context
    @Binding var showRegister: Bool

    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var showPwd  = false
    @FocusState private var focused: Field?
    enum Field { case name, email, password, confirm }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 72, height: 72)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color(hex: "#3b82f6").opacity(0.5), radius: 20, y: 8)

                    Text("Create Account")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(.white)
                    Text("Start tracking your goals")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#64748b"))
                }
                .padding(.top, 60)
                .padding(.bottom, 36)

                VStack(spacing: 14) {
                    AuthField(icon: "person", placeholder: "Full Name", text: $name,
                              isSecure: false, focused: $focused, field: .name)
                    AuthField(icon: "envelope", placeholder: "Email", text: $email,
                              isSecure: false, focused: $focused, field: .email)
                    AuthField(icon: "lock", placeholder: "Password (min 6 chars)", text: $password,
                              isSecure: !showPwd, focused: $focused, field: .password,
                              trailingAction: {
                        Button { showPwd.toggle() } label: {
                            Image(systemName: showPwd ? "eye.slash" : "eye")
                                .foregroundColor(Color(hex: "#475569"))
                                .font(.system(size: 15))
                        }
                    })
                    AuthField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirm,
                              isSecure: !showPwd, focused: $focused, field: .confirm)

                    if !authVM.errorMessage.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(authVM.errorMessage)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#f87171"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }

                    Button {
                        guard password == confirm else {
                            authVM.errorMessage = "Passwords don't match."
                            return
                        }
                        authVM.register(name: name, email: email, password: password, context: context)
                    } label: {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Color(hex: "#3b82f6"), Color(hex: "#6366f1")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)

                HStack(spacing: 6) {
                    Text("Already have an account?")
                        .foregroundColor(Color(hex: "#475569"))
                    Button("Sign in") { showRegister = false }
                        .foregroundColor(Color(hex: "#60a5fa"))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14))
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
        }
        .onTapGesture { focused = nil }
    }
}

// MARK: - Auth Field
struct AuthField<Trailing: View>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    var focused: FocusState<LoginView.Field?>.Binding? = nil
    var field: LoginView.Field? = nil
    @ViewBuilder var trailingAction: () -> Trailing

    init(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool,
         focused: FocusState<LoginView.Field?>.Binding? = nil,
         field: LoginView.Field? = nil,
         @ViewBuilder trailingAction: @escaping () -> Trailing = { EmptyView() }) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.focused = focused
        self.field = field
        self.trailingAction = trailingAction
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#475569"))
                .frame(width: 20)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(placeholder.lowercased().contains("email") ? .emailAddress : .default)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.white)
            trailingAction()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(Color(hex: "#0a1628"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#1e3a5f"), lineWidth: 1)
        )
    }
}
