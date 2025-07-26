import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var searchService: SearchService
    @ObservedObject var notesService: NotesService
    @Binding var selectedNote: Note?
    
    var body: some View {
        VStack {
            if searchService.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchService.searchResults.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No results found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Try different search terms")
                        .foregroundColor(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(searchService.searchResults) { result in
                        SearchResultRowView(
                            result: result,
                            notesService: notesService,
                            selectedNote: $selectedNote
                        )
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}

struct SearchResultRowView: View {
    let result: SearchResult
    @ObservedObject var notesService: NotesService
    @Binding var selectedNote: Note?
    
    private var matchingNote: Note? {
        notesService.notes.first { $0.id == result.noteId }
    }
    
    var body: some View {
        Button {
            if let note = matchingNote {
                selectedNote = note
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if let note = matchingNote {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("Note #\(result.noteId)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Show search snippet with highlighting
                Text(attributedSnippet)
                    .font(.caption)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Text("Relevance: \(String(format: "%.1f", result.rank))")
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                    
                    Spacer()
                    
                    if let note = matchingNote {
                        Text(DateFormatter.shortDateTime.string(from: note.updatedAt))
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
    
    private var attributedSnippet: AttributedString {
        // Convert HTML-like snippet to AttributedString
        var attributedString = AttributedString(result.snippet)
        
        // Simple highlighting - replace <mark> tags with bold styling
        let snippet = result.snippet
        let markedRanges = findMarkedRanges(in: snippet)
        
        // Apply bold styling to marked text
        for range in markedRanges.reversed() {
            if let attrRange = Range(range, in: attributedString) {
                attributedString[attrRange].font = .caption.bold()
                attributedString[attrRange].foregroundColor = .primary
            }
        }
        
        return attributedString
    }
    
    private func findMarkedRanges(in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchText = text
        
        while let startRange = searchText.range(of: "<mark>"),
              let endRange = searchText.range(of: "</mark>", range: startRange.upperBound..<searchText.endIndex) {
            
            let contentStart = startRange.upperBound
            let contentEnd = endRange.lowerBound
            
            if contentStart < contentEnd {
                ranges.append(contentStart..<contentEnd)
            }
            
            searchText = String(searchText[endRange.upperBound...])
        }
        
        return ranges
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}