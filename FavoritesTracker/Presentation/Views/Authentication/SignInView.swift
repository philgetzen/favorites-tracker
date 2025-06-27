import SwiftUI

/// Clean sign-in interface with email/password fields and validation
struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Navigation state
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    actionSection
                    alternativeActionsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(false)
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Sign in to continue tracking your favorites")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if let emailError = viewModel.emailError {
                    Text(emailError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Group {
                        if viewModel.showPassword {
                            TextField("Enter your password", text: $viewModel.password)
                        } else {
                            SecureField("Enter your password", text: $viewModel.password)
                        }
                    }
                    .textContentType(.password)
                    
                    Button(action: viewModel.togglePasswordVisibility) {
                        Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let passwordError = viewModel.passwordError {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            // Sign In Button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                HStack {
                    if viewModel.isSigningIn {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canSignIn ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSignIn)
            
            // Forgot Password
            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Alternative Actions Section
    
    private var alternativeActionsSection: some View {
        VStack(spacing: 16) {
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            // Sign Up Button
            Button("Create New Account") {
                showSignUp = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    SignInView()
}