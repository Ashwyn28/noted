import Foundation
import Combine

class SearchService: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchQuery = "" {
        didSet {
            searchSubject.send(searchQuery)
        }
    }
    
    private let searchSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Debounce search queries
        searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.searchResults = []
                } else {
                    self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = query.withCString { queryCString in
                LibNotes.notes_search(queryCString, 20) // Limit to 20 results
            }
            
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if result.error_code == LibNotes.NOTES_OK {
                    var results: [SearchResult] = []
                    
                    if let resultsPtr = result.results {
                        for i in 0..<Int(result.count) {
                            let cResult = resultsPtr[i]
                            let searchResult = SearchResult(from: cResult)
                            results.append(searchResult)
                        }
                    }
                    
                    self?.searchResults = results
                    LibNotes.notes_free_search_results(result)
                } else {
                    // Handle search error
                    self?.searchResults = []
                }
            }
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}