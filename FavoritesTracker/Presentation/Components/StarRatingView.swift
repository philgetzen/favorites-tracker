import SwiftUI

/// A reusable star rating view component that supports half-star displays
struct StarRatingView: View {
    let rating: Double
    let maxRating: Int
    let starSize: CGFloat
    let color: Color
    
    init(rating: Double, maxRating: Int = 5, starSize: CGFloat = 16, color: Color = .yellow) {
        self.rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                starImage(for: index)
                    .foregroundColor(color)
                    .font(.system(size: starSize))
            }
        }
    }
    
    private func starImage(for index: Int) -> Image {
        let starValue = Double(index)
        
        if rating >= starValue {
            // Full star
            return Image(systemName: "star.fill")
        } else if rating >= starValue - 0.5 {
            // Half star
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            // Empty star
            return Image(systemName: "star")
        }
    }
}

/// Interactive star rating view that allows tapping to set ratings
struct InteractiveStarRatingView: View {
    @Binding var rating: Double
    let maxRating: Int
    let starSize: CGFloat
    let color: Color
    let allowHalfStars: Bool
    
    init(
        rating: Binding<Double>,
        maxRating: Int = 5,
        starSize: CGFloat = 20,
        color: Color = .yellow,
        allowHalfStars: Bool = true
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.color = color
        self.allowHalfStars = allowHalfStars
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                starImage(for: index)
                    .foregroundColor(color)
                    .font(.system(size: starSize))
                    .onTapGesture { location in
                        handleTap(at: index, location: location)
                    }
                    .contentShape(Rectangle())
            }
        }
    }
    
    private func starImage(for index: Int) -> Image {
        let starValue = Double(index)
        
        if rating >= starValue {
            return Image(systemName: "star.fill")
        } else if rating >= starValue - 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
    
    private func handleTap(at index: Int, location: CGPoint) {
        if allowHalfStars {
            // Determine if tap was on left or right half of star
            let isLeftHalf = location.x < starSize / 2
            rating = isLeftHalf ? Double(index) - 0.5 : Double(index)
        } else {
            rating = Double(index)
        }
        
        // Ensure rating stays within bounds
        rating = max(0, min(Double(maxRating), rating))
    }
}

// MARK: - Previews

#Preview("Star Rating Display") {
    VStack(spacing: 20) {
        StarRatingView(rating: 0, maxRating: 5)
        StarRatingView(rating: 1.5, maxRating: 5)
        StarRatingView(rating: 3.0, maxRating: 5)
        StarRatingView(rating: 4.5, maxRating: 5)
        StarRatingView(rating: 5.0, maxRating: 5)
    }
    .padding()
}

#Preview("Interactive Star Rating") {
    @Previewable @State var rating: Double = 3.5
    
    return VStack(spacing: 20) {
        Text("Rating: \(rating, specifier: "%.1f")")
            .font(.headline)
        
        InteractiveStarRatingView(rating: $rating)
        
        Button("Reset") {
            rating = 0
        }
    }
    .padding()
}