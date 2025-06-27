import SwiftUI

/// User account management interface
struct AccountSettingsView: View {
    @StateObject private var viewModel = AccountSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                profileSection
                emailSection
                passwordSection
                dangerSection
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showChangeEmail) {
            changeEmailSheet
        }
        .sheet(isPresented: $viewModel.showChangePassword) {
            changePasswordSheet
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.")
        }
        .alert("Account Settings", isPresented: .constant(viewModel.hasError)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Display Name", text: $viewModel.displayName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                    
                    Text("This name will be visible to other users")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isUpdatingProfile {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if viewModel.canUpdateProfile {
                    Button("Update") {
                        Task {
                            await viewModel.updateDisplayName()
                        }
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .controlSize(.small)
                }
            }
        }
    }
    
    // MARK: - Email Section
    
    private var emailSection: some View {
        Section("Email") {
            HStack {
                Image(systemName: "envelope.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.email)
                        .font(.body)
                    
                    HStack {
                        Image(systemName: viewModel.isEmailVerified ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(viewModel.isEmailVerified ? .green : .orange)
                        
                        Text(viewModel.isEmailVerified ? "Verified" : "Not Verified")
                            .font(.caption)
                            .foregroundColor(viewModel.isEmailVerified ? .green : .orange)
                    }
                }
                
                Spacer()
            }
            
            if !viewModel.isEmailVerified {
                Button(action: {
                    Task {
                        await viewModel.sendEmailVerification()
                    }
                }) {
                    HStack {
                        if viewModel.isSendingVerification {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Send Verification Email")
                        }
                    }
                }
                .disabled(!viewModel.canSendVerification)
            }
            
            Button("Change Email Address") {
                viewModel.showChangeEmail = true
            }
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Password Section
    
    private var passwordSection: some View {
        Section("Security") {
            Button("Change Password") {
                viewModel.showChangePassword = true
            }
            .foregroundColor(.accentColor)
            
            Button("Sign Out") {
                Task {
                    await viewModel.signOut()
                }
            }
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Danger Section
    
    private var dangerSection: some View {
        Section("Danger Zone") {
            Button("Delete Account") {
                viewModel.showDeleteConfirmation = true
            }
            .foregroundColor(.red)
        }
    }
    
    // MARK: - Change Email Sheet
    
    private var changeEmailSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Email Address")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter new email", text: $viewModel.newEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if let emailError = viewModel.newEmailError {
                        Text(emailError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Text("You will need to verify your new email address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.clearEmailForm()
                        viewModel.showChangeEmail = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        Task {
                            await viewModel.updateEmail()
                        }
                    }
                    .disabled(!viewModel.canUpdateEmail)
                }
            }
        }
    }
    
    // MARK: - Change Password Sheet
    
    private var changePasswordSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Group {
                                if viewModel.showCurrentPassword {
                                    TextField("Current password", text: $viewModel.currentPassword)
                                } else {
                                    SecureField("Current password", text: $viewModel.currentPassword)
                                }
                            }
                            .textContentType(.password)
                            
                            Button(action: viewModel.toggleCurrentPasswordVisibility) {
                                Image(systemName: viewModel.showCurrentPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if let currentPasswordError = viewModel.currentPasswordError {
                            Text(currentPasswordError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Group {
                                if viewModel.showNewPassword {
                                    TextField("New password", text: $viewModel.newPassword)
                                } else {
                                    SecureField("New password", text: $viewModel.newPassword)
                                }
                            }
                            .textContentType(.newPassword)
                            
                            Button(action: viewModel.toggleNewPasswordVisibility) {
                                Image(systemName: viewModel.showNewPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if let newPasswordError = viewModel.newPasswordError {
                            Text(newPasswordError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Confirm New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Group {
                                if viewModel.showConfirmPassword {
                                    TextField("Confirm new password", text: $viewModel.confirmNewPassword)
                                } else {
                                    SecureField("Confirm new password", text: $viewModel.confirmNewPassword)
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
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.clearPasswordForm()
                        viewModel.showChangePassword = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        Task {
                            await viewModel.changePassword()
                        }
                    }
                    .disabled(!viewModel.canChangePassword)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AccountSettingsView()
}