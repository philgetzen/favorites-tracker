import SwiftUI

/// Refactored AccountSettingsView using decomposed ViewModels
struct AccountSettingsViewRefactored: View {
    @StateObject private var viewModel = AccountSettingsViewModelRefactored()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Management Section
                profileSection
                
                // Email Management Section
                emailSection
                
                // Security Section
                securitySection
                
                // Account Actions Section
                accountActionsSection
                
                // Status Messages
                if viewModel.hasAnyError || viewModel.hasAnySuccess {
                    messagesSection
                }
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showChangePassword) {
                passwordChangeSheet
            }
            .sheet(isPresented: $viewModel.showChangeEmail) {
                emailChangeSheet
            }
            .alert("Delete Account", isPresented: $viewModel.accountActions.showDeleteConfirmation) {
                deleteAccountAlert
            }
            .disabled(viewModel.isPerformingAnyAction)
        }
        .onAppear {
            Task {
                await viewModel.reloadAllUserData()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section("Profile") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Display Name", text: $viewModel.profileManagement.displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Update") {
                        Task {
                            await viewModel.profileManagement.updateDisplayName()
                        }
                    }
                    .disabled(!viewModel.profileManagement.canUpdateProfile)
                }
                
                if viewModel.profileManagement.isUpdatingProfile {
                    ProgressView("Updating...")
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - Email Section
    
    private var emailSection: some View {
        Section("Email") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Email Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.profileManagement.email)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    if viewModel.profileManagement.isEmailVerified {
                        Label("Verified", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Not Verified", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    if !viewModel.profileManagement.isEmailVerified {
                        Button("Send Verification") {
                            Task {
                                await viewModel.emailVerification.verificationStatusViewModel.sendEmailVerification()
                            }
                        }
                        .disabled(!viewModel.emailVerification.verificationStatusViewModel.canSendVerification)
                        
                        if viewModel.emailVerification.verificationStatusViewModel.isSendingVerification {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Change Email") {
                        viewModel.showEmailChangeSheet()
                    }
                }
            }
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section("Security") {
            Button("Change Password") {
                viewModel.showPasswordChangeSheet()
            }
        }
    }
    
    // MARK: - Account Actions Section
    
    private var accountActionsSection: some View {
        Section("Account Actions") {
            Button("Sign Out") {
                Task {
                    await viewModel.accountActions.signOut()
                }
            }
            .disabled(!viewModel.accountActions.canSignOut)
            
            Button("Delete Account", role: .destructive) {
                viewModel.accountActions.showDeleteAccountConfirmation()
            }
            .disabled(viewModel.accountActions.isPerformingAction)
        }
    }
    
    // MARK: - Messages Section
    
    private var messagesSection: some View {
        Section {
            if let error = viewModel.profileManagement.profileError {
                ErrorMessageView(message: error)
            }
            
            if let success = viewModel.profileManagement.profileSuccessMessage {
                SuccessMessageView(message: success)
            }
            
            if let error = viewModel.emailVerification.verificationError {
                ErrorMessageView(message: error)
            }
            
            if let success = viewModel.emailVerification.verificationSuccessMessage {
                SuccessMessageView(message: success)
            }
            
            if let error = viewModel.accountActions.actionError {
                ErrorMessageView(message: error)
            }
            
            if let success = viewModel.accountActions.actionSuccessMessage {
                SuccessMessageView(message: success)
            }
        }
    }
    
    // MARK: - Password Change Sheet
    
    private var passwordChangeSheet: some View {
        NavigationView {
            Form {
                Section("Current Password") {
                    HStack {
                        if viewModel.passwordChange.showCurrentPassword {
                            TextField("Current Password", text: $viewModel.passwordChange.currentPassword)
                        } else {
                            SecureField("Current Password", text: $viewModel.passwordChange.currentPassword)
                        }
                        
                        Button {
                            viewModel.passwordChange.toggleCurrentPasswordVisibility()
                        } label: {
                            Image(systemName: viewModel.passwordChange.showCurrentPassword ? "eye.slash" : "eye")
                        }
                    }
                    
                    if let error = viewModel.passwordChange.currentPasswordError {
                        ErrorMessageView(message: error)
                    }
                }
                
                Section("New Password") {
                    HStack {
                        if viewModel.passwordChange.showNewPassword {
                            TextField("New Password", text: $viewModel.passwordChange.newPassword)
                        } else {
                            SecureField("New Password", text: $viewModel.passwordChange.newPassword)
                        }
                        
                        Button {
                            viewModel.passwordChange.toggleNewPasswordVisibility()
                        } label: {
                            Image(systemName: viewModel.passwordChange.showNewPassword ? "eye.slash" : "eye")
                        }
                    }
                    
                    if let error = viewModel.passwordChange.newPasswordError {
                        ErrorMessageView(message: error)
                    }
                    
                    HStack {
                        if viewModel.passwordChange.showConfirmPassword {
                            TextField("Confirm New Password", text: $viewModel.passwordChange.confirmNewPassword)
                        } else {
                            SecureField("Confirm New Password", text: $viewModel.passwordChange.confirmNewPassword)
                        }
                        
                        Button {
                            viewModel.passwordChange.toggleConfirmPasswordVisibility()
                        } label: {
                            Image(systemName: viewModel.passwordChange.showConfirmPassword ? "eye.slash" : "eye")
                        }
                    }
                    
                    if let error = viewModel.passwordChange.confirmPasswordError {
                        ErrorMessageView(message: error)
                    }
                }
                
                if let error = viewModel.passwordChange.generalError {
                    Section {
                        ErrorMessageView(message: error)
                    }
                }
                
                if let success = viewModel.passwordChange.successMessage {
                    Section {
                        SuccessMessageView(message: success)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.hidePasswordChangeSheet()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        Task {
                            await viewModel.passwordChange.changePassword()
                        }
                    }
                    .disabled(!viewModel.passwordChange.canChangePassword)
                }
            }
            .overlay {
                if viewModel.passwordChange.isChangingPassword {
                    LoadingOverlayWithMessage(message: "Updating password...")
                }
            }
        }
    }
    
    // MARK: - Email Change Sheet
    
    private var emailChangeSheet: some View {
        NavigationView {
            Form {
                Section("New Email Address") {
                    TextField("Email", text: $viewModel.emailVerification.newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    if let error = viewModel.emailVerification.newEmailError {
                        ErrorMessageView(message: error)
                    }
                }
                
                if let error = viewModel.emailVerification.updateEmailError {
                    Section {
                        ErrorMessageView(message: error)
                    }
                }
                
                if let success = viewModel.emailVerification.updateEmailSuccessMessage {
                    Section {
                        SuccessMessageView(message: success)
                    }
                }
            }
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.hideEmailChangeSheet()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        Task {
                            await viewModel.emailVerification.updateEmail()
                        }
                    }
                    .disabled(!viewModel.emailVerification.canUpdateEmail)
                }
            }
            .overlay {
                if viewModel.emailVerification.isUpdatingEmail {
                    LoadingOverlayWithMessage(message: "Updating email...")
                }
            }
        }
    }
    
    // MARK: - Delete Account Alert
    
    private var deleteAccountAlert: some View {
        Group {
            TextField(viewModel.accountActions.deleteConfirmationPrompt, text: $viewModel.accountActions.deleteConfirmationText)
            
            Button("Delete Account", role: .destructive) {
                Task {
                    await viewModel.accountActions.deleteAccount()
                }
            }
            .disabled(!viewModel.accountActions.canDeleteAccount)
            
            Button("Cancel", role: .cancel) {
                viewModel.accountActions.cancelDeleteAccount()
            }
        }
    }
}

// MARK: - Supporting Views

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
            .font(.caption)
    }
}

struct SuccessMessageView: View {
    let message: String
    
    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .foregroundColor(.green)
            .font(.caption)
    }
}

struct LoadingOverlayWithMessage: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                Text(message)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AccountSettingsViewRefactored_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsViewRefactored()
            .preferredColorScheme(.light)
        
        AccountSettingsViewRefactored()
            .preferredColorScheme(.dark)
    }
}
#endif