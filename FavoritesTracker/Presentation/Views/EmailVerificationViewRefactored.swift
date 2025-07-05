import SwiftUI

/// Demonstration view showing refactored EmailVerificationViewModel usage with decomposed ViewModels
struct EmailVerificationViewRefactored: View {
    @StateObject private var viewModel = EmailVerificationViewModelRefactored()
    @State private var showEmailChangeSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                emailStatusSection
                emailActionsSection
                
                if viewModel.hasAnyError {
                    errorSection
                }
                
                if viewModel.hasAnySuccess {
                    successSection
                }
            }
            .navigationTitle("Email Verification")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEmailChangeSheet) {
                emailChangeSheet
            }
        }
        .task {
            await viewModel.reloadUserData()
        }
    }
    
    // MARK: - Email Status Section
    
    private var emailStatusSection: some View {
        Section("Current Email") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Email Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.verificationStatusViewModel.currentEmail)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    if viewModel.verificationStatusViewModel.isEmailVerified {
                        Label("Verified", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Not Verified", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Email Actions Section
    
    private var emailActionsSection: some View {
        Section("Actions") {
            // Email Verification Button
            if !viewModel.verificationStatusViewModel.isEmailVerified {
                HStack {
                    Button("Send Verification Email") {
                        Task {
                            await viewModel.verificationStatusViewModel.sendEmailVerification()
                        }
                    }
                    .disabled(!viewModel.verificationStatusViewModel.canSendVerification)
                    
                    Spacer()
                    
                    if viewModel.verificationStatusViewModel.isSendingVerification {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            
            // Email Change Button
            HStack {
                Button("Change Email Address") {
                    showEmailChangeSheet = true
                }
                .disabled(viewModel.isPerformingAnyAction)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Refresh Data Button
            HStack {
                Button("Refresh Status") {
                    Task {
                        await viewModel.reloadUserData()
                    }
                }
                .disabled(viewModel.isPerformingAnyAction)
                
                Spacer()
                
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Error Section
    
    private var errorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                if let error = viewModel.verificationStatusViewModel.verificationError {
                    ErrorMessageView(message: error)
                }
                
                if let error = viewModel.emailChangeViewModel.newEmailError {
                    ErrorMessageView(message: error)
                }
                
                if let error = viewModel.emailChangeViewModel.updateEmailError {
                    ErrorMessageView(message: error)
                }
            }
        }
    }
    
    // MARK: - Success Section
    
    private var successSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                if let success = viewModel.verificationStatusViewModel.verificationSuccessMessage {
                    SuccessMessageView(message: success)
                }
                
                if let success = viewModel.emailChangeViewModel.updateEmailSuccessMessage {
                    SuccessMessageView(message: success)
                }
            }
        }
    }
    
    // MARK: - Email Change Sheet
    
    private var emailChangeSheet: some View {
        NavigationView {
            Form {
                Section("Change Email Address") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.emailChangeViewModel.currentEmail)
                            .font(.body)
                            .padding(.bottom, 8)
                        
                        Text("New Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter new email address", text: $viewModel.emailChangeViewModel.newEmail)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    if let error = viewModel.emailChangeViewModel.newEmailError {
                        ErrorMessageView(message: error)
                    }
                }
                
                if let error = viewModel.emailChangeViewModel.updateEmailError {
                    Section {
                        ErrorMessageView(message: error)
                    }
                }
                
                if let success = viewModel.emailChangeViewModel.updateEmailSuccessMessage {
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
                        viewModel.clearEmailForm()
                        showEmailChangeSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        Task {
                            await viewModel.emailChangeViewModel.updateEmail()
                            if viewModel.emailChangeViewModel.hasUpdateEmailSuccess {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showEmailChangeSheet = false
                                }
                            }
                        }
                    }
                    .disabled(!viewModel.emailChangeViewModel.canUpdateEmail)
                }
            }
            .overlay {
                if viewModel.emailChangeViewModel.isUpdatingEmail {
                    LoadingOverlayWithMessage(message: "Updating email address...")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EmailVerificationViewRefactored()
}