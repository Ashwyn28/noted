import Foundation

struct Note: Identifiable, Hashable {
    let id: UInt64
    var title: String
    var content: String
    let createdAt: Date
    var updatedAt: Date
    var tags: [String]
    
    init(id: UInt64, title: String, content: String, createdAt: Date, updatedAt: Date, tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
    }
    
    // Create from C struct (when Zig integration is available)
    // init(from cNote: LibNotes.CNote) { ... }
    
    var preview: String {
        let maxLength = 100
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }
    
    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// SearchResult moved to MockSearchService to avoid conflicts