import SwiftUI

/// Rich text editor with formatting controls for notes and descriptions
struct RichTextEditorView: View {
    @Binding var text: String
    @State private var isBold: Bool = false
    @State private var isItalic: Bool = false
    @State private var selectedFormat: TextFormat = .body
    @FocusState private var isTextFieldFocused: Bool
    
    let placeholder: String
    let minHeight: CGFloat
    
    init(text: Binding<String>, placeholder: String = "Enter text...", minHeight: CGFloat = 120) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Formatting toolbar
            formatToolbar
            
            // Text editor
            textEditor
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var formatToolbar: some View {
        HStack(spacing: 16) {
            // Text format picker
            Picker("Format", selection: $selectedFormat) {
                ForEach(TextFormat.allCases, id: \.self) { format in
                    Text(format.displayName)
                        .tag(format)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 120)
            
            Spacer()
            
            // Bold button
            Button(action: { isBold.toggle() }) {
                Image(systemName: "bold")
                    .foregroundColor(isBold ? .blue : .secondary)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(width: 32, height: 32)
            .background(isBold ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            
            // Italic button  
            Button(action: { isItalic.toggle() }) {
                Image(systemName: "italic")
                    .foregroundColor(isItalic ? .blue : .secondary)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(width: 32, height: 32)
            .background(isItalic ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            
            // Quick formatting buttons
            Button(action: insertBulletPoint) {
                Image(systemName: "list.bullet")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(width: 32, height: 32)
            .cornerRadius(6)
        }
        .padding(.horizontal, 4)
    }
    
    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            // Background for text editor
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            // Text editor
            TextEditor(text: $text)
                .font(currentFont)
                .padding(12)
                .background(Color.clear)
                .focused($isTextFieldFocused)
                .onChange(of: text) { _, newValue in
                    // Apply formatting as user types
                    applyFormattingToText()
                }
            
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .font(currentFont)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: minHeight)
    }
    
    private var currentFont: Font {
        let baseFont: Font
        
        switch selectedFormat {
        case .title:
            baseFont = .title2
        case .heading:
            baseFont = .headline
        case .subheading:
            baseFont = .subheadline
        case .body:
            baseFont = .body
        case .caption:
            baseFont = .caption
        }
        
        // Apply weight modifications
        if isBold && isItalic {
            return baseFont.weight(.bold).italic()
        } else if isBold {
            return baseFont.weight(.bold)
        } else if isItalic {
            return baseFont.italic()
        } else {
            return baseFont
        }
    }
    
    private func insertBulletPoint() {
        let cursorPosition = text.endIndex
        let bulletText = text.isEmpty ? "• " : "\n• "
        text.insert(contentsOf: bulletText, at: cursorPosition)
        isTextFieldFocused = true
    }
    
    private func applyFormattingToText() {
        // Simple markdown-style formatting could be added here
        // For now, we rely on the font styling in the UI
    }
}

enum TextFormat: String, CaseIterable {
    case title = "title"
    case heading = "heading"
    case subheading = "subheading"
    case body = "body"
    case caption = "caption"
    
    var displayName: String {
        switch self {
        case .title: return "Title"
        case .heading: return "Heading"
        case .subheading: return "Subheading"
        case .body: return "Body"
        case .caption: return "Caption"
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewContainer: View {
        @State private var sampleText = """
        This is a sample rich text note with multiple paragraphs.
        
        • Bullet point one
        • Bullet point two
        
        You can format text with different styles and weights.
        """
        
        var body: some View {
            VStack {
                Text("Rich Text Editor Demo")
                    .font(.title2)
                    .padding()
                
                RichTextEditorView(
                    text: $sampleText,
                    placeholder: "Enter your notes here...",
                    minHeight: 150
                )
                .padding()
                
                Spacer()
            }
        }
    }
    
    return PreviewContainer()
}