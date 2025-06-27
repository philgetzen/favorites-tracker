import SwiftUI

/// Password reset email interface
struct ForgotPasswordView: View {
    @StateObject var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    if viewModel.resetEmailSent {
                        successSection
                    } else {
                        formSection
                    }
                    
                    actionSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Reset Password")
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
            Image(systemName: viewModel.resetEmailSent ? "checkmark.circle.fill" : "lock.rotation")
                .font(.system(size: 60))
                .foregroundColor(viewModel.resetEmailSent ? .green : .accentColor)
            
            VStack(spacing: 8) {
                Text(viewModel.resetEmailSent ? "Email Sent!" : "Forgot Password?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.resetEmailSent ? 
                     "Check your email for password reset instructions" :
                     "Enter your email address and we'll send you instructions to reset your password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
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
    }
    
    // MARK: - Success Section
    
    private var successSection: some View {
        VStack(spacing: 16) {
            Text("We sent a password reset email to:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(viewModel.email)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            VStack(spacing: 8) {
                Text("Check your email and follow the instructions to reset your password.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Don't see the email? Check your spam folder.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            if viewModel.resetEmailSent {
                // Resend Button
                Button(action: {
                    Task {
                        await viewModel.resendPasswordReset()
                    }
                }) {
                    HStack {
                        if viewModel.isSendingReset {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Resend Email")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isSendingReset)
                
                // Done Button
                Button("Done") {
                    dismiss()
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
                
            } else {
                // Send Reset Button
                Button(action: {
                    Task {
                        await viewModel.sendPasswordReset()
                    }
                }) {
                    HStack {
                        if viewModel.isSendingReset {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Email")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.canSendReset ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canSendReset)
                
                // Back to Sign In
                Button("Back to Sign In") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ForgotPasswordView()
}

#Preview("Success State") {
    ForgotPasswordView()
}