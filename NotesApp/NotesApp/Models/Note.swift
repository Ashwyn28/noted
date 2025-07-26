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
    
    // Create from C struct
    init(from cNote: LibNotes.CNote) {
        self.id = cNote.id
        self.title = String(cString: cNote.title)
        self.content = String(cString: cNote.content)
        self.createdAt = Date(timeIntervalSince1970: TimeInterval(cNote.created_at))
        self.updatedAt = Date(timeIntervalSince1970: TimeInterval(cNote.updated_at))
        
        // Parse tags JSON (simple implementation)
        let tagsString = String(cString: cNote.tags)
        if let data = tagsString.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [String] {
            self.tags = jsonArray
        } else {
            self.tags = []
        }
    }
    
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

struct SearchResult: Identifiable {
    let id = UUID()
    let noteId: UInt64
    let rank: Double
    let snippet: String
    
    init(from cResult: LibNotes.CSearchResult) {
        self.noteId = cResult.note_id
        self.rank = cResult.rank
        self.snippet = String(cString: cResult.snippet)
    }
}