import SwiftUI

/// Registration form with validation and terms acceptance
struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    termsSection
                    actionSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("Join FavoritesTracker")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your account to start tracking your favorite items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Display Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter your display name", text: $viewModel.displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.name)
                    .autocapitalization(.words)
                
                if let displayNameError = viewModel.displayNameError {
                    Text(displayNameError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
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
                    .textContentType(.newPassword)
                    
                    Button(action: viewModel.togglePasswordVisibility) {
                        Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Password Strength Indicator
                if !viewModel.password.isEmpty {
                    HStack {
                        Text("Strength: ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.passwordStrength.description)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(viewModel.passwordStrength.color))
                    }
                }
                
                if let passwordError = viewModel.passwordError {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Group {
                        if viewModel.showConfirmPassword {
                            TextField("Confirm your password", text: $viewModel.confirmPassword)
                        } else {
                            SecureField("Confirm your password", text: $viewModel.confirmPassword)
                        }
                    }
                    .textContentType(.newPassword)
                    
                    Button(action: viewModel.toggleConfirmPasswordVisibility) {
                        Image(systemName: viewModel.showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let confirmPasswordError = viewModel.confirmPasswordError {
                    Text(confirmPasswordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    viewModel.acceptedTerms.toggle()
                }) {
                    Image(systemName: viewModel.acceptedTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(viewModel.acceptedTerms ? .accentColor : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("I agree to the Terms of Service")
                        .font(.subheadline)
                    
                    Button("Read Terms of Service") {
                        // TODO: Show terms of service
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    viewModel.acceptedPrivacy.toggle()
                }) {
                    Image(systemName: viewModel.acceptedPrivacy ? "checkmark.square.fill" : "square")
                        .foregroundColor(viewModel.acceptedPrivacy ? .accentColor : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("I agree to the Privacy Policy")
                        .font(.subheadline)
                    
                    Button("Read Privacy Policy") {
                        // TODO: Show privacy policy
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            // Create Account Button
            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                HStack {
                    if viewModel.isSigningUp {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canSignUp ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSignUp)
            
            // Sign In Alternative
            HStack {
                Text("Already have an account?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Sign In") {
                    dismiss()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpView()
}