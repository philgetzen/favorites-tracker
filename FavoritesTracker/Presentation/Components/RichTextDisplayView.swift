import SwiftUI

/// Component for displaying rich text with basic formatting support
struct RichTextDisplayView: View {
    let text: String
    let style: DisplayStyle
    let lineLimit: Int?
    
    init(text: String, style: DisplayStyle = .body, lineLimit: Int? = nil) {
        self.text = text
        self.style = style
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        if text.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(formattedTextBlocks, id: \.id) { block in
                    textBlock(block)
                }
            }
        }
    }
    
    private var formattedTextBlocks: [TextBlock] {
        parseRichText(text)
    }
    
    @ViewBuilder
    private func textBlock(_ block: TextBlock) -> some View {
        switch block.type {
        case .paragraph:
            Text(block.content)
                .font(style.font)
                .foregroundColor(style.color)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
            
        case .bulletPoint:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(style.font.weight(.medium))
                    .foregroundColor(style.color)
                
                Text(block.content)
                    .font(style.font)
                    .foregroundColor(style.color)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
        case .heading:
            Text(block.content)
                .font(style.headingFont)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func parseRichText(_ input: String) -> [TextBlock] {
        var blocks: [TextBlock] = []
        let lines = input.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                continue // Skip empty lines
            }
            
            // Check for bullet points
            if trimmedLine.hasPrefix("• ") || trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                let content = String(trimmedLine.dropFirst(2))
                blocks.append(TextBlock(
                    id: "bullet-\(index)",
                    type: .bulletPoint,
                    content: content
                ))
            }
            // Check for headings (lines that are all caps or start with #)
            else if trimmedLine.hasPrefix("#") {
                let content = trimmedLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                blocks.append(TextBlock(
                    id: "heading-\(index)",
                    type: .heading,
                    content: content
                ))
            }
            // Regular paragraph
            else {
                blocks.append(TextBlock(
                    id: "paragraph-\(index)",
                    type: .paragraph,
                    content: trimmedLine
                ))
            }
        }
        
        return blocks
    }
}

// MARK: - Supporting Types

struct TextBlock {
    let id: String
    let type: TextBlockType
    let content: String
}

enum TextBlockType {
    case paragraph
    case bulletPoint
    case heading
}

enum DisplayStyle {
    case caption
    case body
    case large
    case detail
    
    var font: Font {
        switch self {
        case .caption: return .caption
        case .body: return .body
        case .large: return .title3
        case .detail: return .subheadline
        }
    }
    
    var headingFont: Font {
        switch self {
        case .caption: return .caption.weight(.semibold)
        case .body: return .headline
        case .large: return .title2
        case .detail: return .subheadline.weight(.semibold)
        }
    }
    
    var color: Color {
        switch self {
        case .caption: return .secondary
        case .body: return .secondary
        case .large: return .primary
        case .detail: return .secondary
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewContainer: View {
        let sampleText = """
        # Product Review
        
        This is a comprehensive review of my favorite coffee maker.
        
        • Excellent build quality
        • Easy to clean
        • Makes great coffee
        • Good value for money
        
        Overall, I would highly recommend this product to anyone looking for a reliable coffee maker. The design is sleek and modern, fitting well in any kitchen.
        
        # Final Thoughts
        
        Would definitely buy again!
        """
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Rich Text Display Demo")
                    .font(.title2)
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Body Style")
                            .font(.headline)
                        RichTextDisplayView(text: sampleText, style: .body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("Detail Style (Limited)")
                            .font(.headline)
                        RichTextDisplayView(text: sampleText, style: .detail, lineLimit: 3)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
    }
    
    return PreviewContainer()
}