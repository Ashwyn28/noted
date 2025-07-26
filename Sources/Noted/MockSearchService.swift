import Foundation
import Combine

@MainActor
class MockSearchService: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchQuery = "" {
        didSet {
            searchSubject.send(searchQuery)
        }
    }
    
    private let searchSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let notesService: MockNotesService
    
    init(notesService: MockNotesService) {
        self.notesService = notesService
        
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
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Simple mock search - find notes containing the query
            let results = self.notesService.notes.compactMap { note -> SearchResult? in
                let titleMatch = note.title.localizedCaseInsensitiveContains(query)
                let contentMatch = note.content.localizedCaseInsensitiveContains(query)
                
                if titleMatch || contentMatch {
                    // Create a simple snippet
                    let snippet = self.createSnippet(from: note.content, query: query)
                    let rank = titleMatch ? 2.0 : 1.0 // Higher rank for title matches
                    
                    return SearchResult(
                        noteId: note.id,
                        rank: rank,
                        snippet: snippet
                    )
                }
                return nil
            }.sorted { $0.rank > $1.rank }
            
            self.isSearching = false
            self.searchResults = results
        }
    }
    
    private func createSnippet(from content: String, query: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        
        // Find the first line containing the query
        for line in lines {
            if line.localizedCaseInsensitiveContains(query) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 100 {
                    return String(trimmed.prefix(100)) + "..."
                }
                return trimmed
            }
        }
        
        // Fallback to first non-empty line
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                if trimmed.count > 100 {
                    return String(trimmed.prefix(100)) + "..."
                }
                return trimmed
            }
        }
        
        return "No preview available"
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

// Mock SearchResult since we're not using the C API
struct SearchResult: Identifiable {
    let id = UUID()
    let noteId: UInt64
    let rank: Double
    let snippet: String
}