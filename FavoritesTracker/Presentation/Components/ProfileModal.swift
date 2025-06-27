import SwiftUI

/// Modal view that appears when user taps their profile icon
/// Provides options to edit display name and sign out
struct ProfileModal: View {
    @Binding var isPresented: Bool
    let currentUser: User?
    let onSignOut: @Sendable () async -> Void
    let onUpdateDisplayName: @Sendable (String) async throws -> Void
    
    @State private var isEditingName = false
    @State private var editedDisplayName = ""
    @State private var isUpdatingName = false
    @State private var updateError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                profileHeader
                
                // User Information
                userInformation
                
                // Actions
                actionButtons
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            editedDisplayName = currentUser?.displayName ?? ""
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            UserInitialsView(
                displayName: currentUser?.displayName,
                size: 80,
                backgroundColor: .blue
            )
            
            VStack(spacing: 4) {
                Text(currentUser?.displayName ?? "No name set")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text(currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let isVerified = currentUser?.isEmailVerified {
                    HStack(spacing: 4) {
                        Image(systemName: isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(isVerified ? .green : .orange)
                        Text(isVerified ? "Email verified" : "Email not verified")
                            .font(.caption)
                            .foregroundColor(isVerified ? .green : .orange)
                    }
                }
            }
        }
    }
    
    // MARK: - User Information
    
    private var userInformation: some View {
        VStack(spacing: 16) {
            // Display Name Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Display Name")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(isEditingName ? "Cancel" : "Edit") {
                        if isEditingName {
                            editedDisplayName = currentUser?.displayName ?? ""
                        }
                        isEditingName.toggle()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                if isEditingName {
                    VStack(spacing: 12) {
                        TextField("Enter your name", text: $editedDisplayName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                Task {
                                    await updateDisplayName()
                                }
                            }
                        
                        HStack {
                            Button(isUpdatingName ? "Saving..." : "Save") {
                                Task {
                                    await updateDisplayName()
                                }
                            }
                            .disabled(editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUpdatingName)
                            .buttonStyle(.borderedProminent)
                            
                            if isUpdatingName {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if let error = updateError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Text(currentUser?.displayName ?? "Not set")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await signOut()
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateDisplayName() async {
        let trimmedName = editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            updateError = "Display name cannot be empty"
            return
        }
        
        guard trimmedName != currentUser?.displayName else {
            isEditingName = false
            return
        }
        
        await MainActor.run {
            isUpdatingName = true
            updateError = nil
        }
        
        do {
            // Add timeout to prevent hanging
            try await withTimeout(seconds: 10) {
                try await onUpdateDisplayName(trimmedName)
            }
            
            await MainActor.run {
                isEditingName = false
                isUpdatingName = false
            }
        } catch {
            await MainActor.run {
                if error is TimeoutError {
                    updateError = "Update timed out. Please try again."
                } else {
                    updateError = error.localizedDescription
                }
                isUpdatingName = false
            }
        }
    }
    
    // MARK: - Timeout Helper
    
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {
        let localizedDescription = "Operation timed out"
    }
    
    private func signOut() async {
        await onSignOut()
        isPresented = false
    }
}

// MARK: - Preview Provider

#Preview("Profile Modal") {
    ProfileModal(
        isPresented: .constant(true),
        currentUser: User(
            id: "preview-id",
            email: "john.doe@example.com",
            displayName: "John Doe",
            photoURL: nil,
            isEmailVerified: true
        ),
        onSignOut: {
            print("Sign out tapped")
        },
        onUpdateDisplayName: { newName in
            print("Update display name to: \(newName)")
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    )
}

#Preview("Profile Modal - No Display Name") {
    ProfileModal(
        isPresented: .constant(true),
        currentUser: User(
            id: "preview-id",
            email: "jane.smith@example.com",
            displayName: nil,
            photoURL: nil,
            isEmailVerified: false
        ),
        onSignOut: {
            print("Sign out tapped")
        },
        onUpdateDisplayName: { newName in
            print("Update display name to: \(newName)")
        }
    )
}