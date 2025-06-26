import SwiftUI

/// Advanced search component with multi-field search and comprehensive filtering
struct AdvancedSearchView: View {
    @Binding var searchQuery: String
    @Binding var searchFilters: SearchFilters
    @Binding var isPresented: Bool
    
    let onSearch: (String, SearchFilters) -> Void
    let onClear: () -> Void
    
    @State private var localFilters: SearchFilters
    @State private var selectedSortOption: SortOption = .newest
    @State private var showingFilterDetails = false
    
    init(
        searchQuery: Binding<String>,
        searchFilters: Binding<SearchFilters>,
        isPresented: Binding<Bool>,
        onSearch: @escaping (String, SearchFilters) -> Void,
        onClear: @escaping () -> Void
    ) {
        self._searchQuery = searchQuery
        self._searchFilters = searchFilters
        self._isPresented = isPresented
        self.onSearch = onSearch
        self.onClear = onClear
        self._localFilters = State(initialValue: searchFilters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search input
                searchInputSection
                
                // Quick filters
                quickFiltersSection
                
                // Advanced filters (expandable)
                if showingFilterDetails {
                    advancedFiltersSection
                }
                
                Spacer()
                
                // Action buttons
                actionButtonsSection
            }
            .padding()
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .disabled(localFilters.isEmpty)
                }
            }
        }
        .onAppear {
            localFilters = searchFilters
        }
    }
    
    private var searchInputSection: some View {
        VStack(spacing: 12) {
            TextField("Search items, descriptions, tags...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            
            Text("Search across names, descriptions, tags, and custom fields")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 16)
    }
    
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Filters")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                // Favorites filter
                FilterToggleView(
                    title: "Favorites Only",
                    icon: "heart.fill",
                    isOn: $localFilters.favoritesOnly
                )
                
                // Recent items filter
                FilterToggleView(
                    title: "Recent Items",
                    icon: "clock.fill",
                    isOn: $localFilters.recentItemsOnly
                )
                
                // Has images filter
                FilterToggleView(
                    title: "With Photos",
                    icon: "photo.fill",
                    isOn: $localFilters.hasImagesOnly
                )
                
                // Has notes filter
                FilterToggleView(
                    title: "With Notes",
                    icon: "text.alignleft",
                    isOn: $localFilters.hasNotesOnly
                )
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Show more filters button
            Button(action: { showingFilterDetails.toggle() }) {
                HStack {
                    Text("Advanced Filters")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: showingFilterDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var advancedFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            
            // Rating filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Rating")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Minimum: \(localFilters.minimumRating, specifier: "%.1f")")
                            .font(.caption)
                        Spacer()
                        Text("Maximum: \(localFilters.maximumRating, specifier: "%.1f")")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    RangeSlider(
                        minValue: $localFilters.minimumRating,
                        maxValue: $localFilters.maximumRating,
                        range: 0...5,
                        step: 0.5
                    )
                }
            }
            
            // Date range filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Date Range")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("From")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: Binding(
                            get: { localFilters.dateFrom ?? Date().addingTimeInterval(-365*24*60*60) },
                            set: { localFilters.dateFrom = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("To")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: Binding(
                            get: { localFilters.dateTo ?? Date() },
                            set: { localFilters.dateTo = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                    }
                }
            }
            
            // Tags filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TagSelectorView(selectedTags: $localFilters.includeTags)
            }
            
            // Sort options
            VStack(alignment: .leading, spacing: 8) {
                Text("Sort By")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Sort By", selection: $localFilters.sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.top, 8)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: performSearch) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            if !localFilters.isEmpty {
                Button(action: clearSearch) {
                    Text("Clear All")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .frame(height: 44)
            }
        }
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        searchFilters = localFilters
        onSearch(searchQuery, localFilters)
        isPresented = false
    }
    
    private func clearSearch() {
        searchQuery = ""
        localFilters = SearchFilters()
        searchFilters = localFilters
        onClear()
        isPresented = false
    }
    
    private func resetFilters() {
        localFilters = SearchFilters()
    }
}

// MARK: - Supporting Views

struct FilterToggleView: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isOn ? .white : .blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isOn ? .white : .blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack {
                    Text("Min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Slider(value: $minValue, in: range.lowerBound...min(maxValue, range.upperBound), step: step)
                }
                
                Spacer()
                
                VStack {
                    Text("Max")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Slider(value: $maxValue, in: max(minValue, range.lowerBound)...range.upperBound, step: step)
                }
            }
        }
    }
}

struct TagSelectorView: View {
    @Binding var selectedTags: [String]
    @State private var searchText = ""
    
    let availableTags = ["favorite", "new", "expensive", "vintage", "electronics", "books", "excellent", "good"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search tags...", text: $searchText)
                .textFieldStyle(.roundedBorder)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(filteredTags, id: \.self) { tag in
                    Button(action: { toggleTag(tag) }) {
                        Text(tag)
                            .font(.caption)
                            .foregroundColor(selectedTags.contains(tag) ? .white : .blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedTags.contains(tag) ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var filteredTags: [String] {
        if searchText.isEmpty {
            return availableTags
        } else {
            return availableTags.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewContainer: View {
        @State private var searchQuery = ""
        @State private var searchFilters = SearchFilters()
        @State private var isPresented = true
        
        var body: some View {
            AdvancedSearchView(
                searchQuery: $searchQuery,
                searchFilters: $searchFilters,
                isPresented: $isPresented,
                onSearch: { query, filters in
                    print("Search: \(query) with filters: \(filters)")
                },
                onClear: {
                    print("Clear search")
                }
            )
        }
    }
    
    return PreviewContainer()
}