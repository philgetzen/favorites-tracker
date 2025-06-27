import SwiftUI

/// A reusable component that displays user initials in a circular avatar
/// Falls back to "?" if no display name is available
struct UserInitialsView: View {
    let displayName: String?
    let size: CGFloat
    let backgroundColor: Color
    let textColor: Color
    
    init(
        displayName: String?,
        size: CGFloat = 40,
        backgroundColor: Color = .blue,
        textColor: Color = .white
    ) {
        self.displayName = displayName
        self.size = size
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    var body: some View {
        Circle()
            .fill(backgroundColor.gradient)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: fontSize, weight: .medium, design: .default))
                    .foregroundColor(textColor)
            )
    }
    
    // MARK: - Private Computed Properties
    
    private var initials: String {
        guard let displayName = displayName, !displayName.isEmpty else {
            return "?"
        }
        
        return extractInitials(from: displayName)
    }
    
    private var fontSize: CGFloat {
        size * 0.4 // Font size should be 40% of the circle size
    }
    
    // MARK: - Private Methods
    
    private func extractInitials(from name: String) -> String {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameComponents = cleanedName.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        switch nameComponents.count {
        case 0:
            return "?"
        case 1:
            // Single name: take first two characters or just first if only one character
            let firstComponent = nameComponents[0]
            if firstComponent.count >= 2 {
                return String(firstComponent.prefix(2)).uppercased()
            } else {
                return String(firstComponent.prefix(1)).uppercased()
            }
        default:
            // Multiple names: take first letter of first and last name
            let firstInitial = String(nameComponents.first?.prefix(1) ?? "").uppercased()
            let lastInitial = String(nameComponents.last?.prefix(1) ?? "").uppercased()
            return firstInitial + lastInitial
        }
    }
}

// MARK: - Preview Provider

#Preview("User Initials - Various Names") {
    VStack(spacing: 20) {
        HStack(spacing: 15) {
            UserInitialsView(displayName: "John Doe")
            UserInitialsView(displayName: "Jane Smith", backgroundColor: .green)
            UserInitialsView(displayName: "Alice Johnson", backgroundColor: .purple)
        }
        
        HStack(spacing: 15) {
            UserInitialsView(displayName: "Bob", backgroundColor: .orange)
            UserInitialsView(displayName: "Catherine Elizabeth Windsor", backgroundColor: .red)
            UserInitialsView(displayName: nil, backgroundColor: .gray)
        }
        
        HStack(spacing: 15) {
            UserInitialsView(displayName: "X", backgroundColor: .pink)
            UserInitialsView(displayName: "   ", backgroundColor: .brown)
            UserInitialsView(displayName: "María José", backgroundColor: .cyan)
        }
        
        // Different sizes
        HStack(spacing: 15) {
            UserInitialsView(displayName: "John Doe", size: 30)
            UserInitialsView(displayName: "John Doe", size: 50)
            UserInitialsView(displayName: "John Doe", size: 60)
        }
    }
    .padding()
}