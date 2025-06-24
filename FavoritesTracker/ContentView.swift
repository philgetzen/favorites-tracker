import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "heart.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Favorites Tracker")
                .font(.title)
            Text("Modular tracking for your favorite things")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview("Default") {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("iPad", traits: .landscapeLeft) {
    ContentView()
}

#Preview("Comprehensive") {
    ContentView()
}