import Foundation
import Combine

// Mock implementation for demo purposes
@MainActor
class MockNotesService: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        loadMockNotes()
    }
    
    private func loadMockNotes() {
        notes = [
            Note(
                id: 1,
                title: "Welcome to Noted",
                content: """
                # Welcome to Noted!
                
                This is your first note. Noted is a powerful note-taking app built with:
                
                - **Zig core** for blazing-fast performance
                - **SwiftUI** for beautiful native macOS interface  
                - **SQLite FTS5** for instant full-text search
                
                ## Features
                
                - Create and edit notes with Markdown support
                - Search through all your notes instantly
                - Export to various formats
                - Native macOS integration
                
                Try creating a new note with ⌘N or use the search to find this note!
                """,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-3600)
            ),
            Note(
                id: 2,
                title: "Meeting Notes - Project Alpha",
                content: """
                ## Attendees
                - Alice Johnson
                - Bob Smith  
                - Carol Wilson
                
                ## Agenda
                1. Project timeline review
                2. Resource allocation
                3. Next milestones
                
                ## Action Items
                - [ ] Update project timeline
                - [ ] Schedule follow-up meeting
                - [ ] Review budget allocation
                """,
                createdAt: Date().addingTimeInterval(-7200),
                updatedAt: Date().addingTimeInterval(-1800)
            ),
            Note(
                id: 3,
                title: "Recipe: Chocolate Chip Cookies",
                content: """
                ## Ingredients
                - 2¼ cups all-purpose flour
                - 1 tsp baking soda
                - 1 tsp salt
                - 1 cup butter, softened
                - ¾ cup granulated sugar
                - ¾ cup brown sugar
                - 2 large eggs
                - 2 tsp vanilla extract
                - 2 cups chocolate chips
                
                ## Instructions
                1. Preheat oven to 375°F
                2. Mix dry ingredients in bowl
                3. Cream butter and sugars
                4. Add eggs and vanilla
                5. Combine wet and dry ingredients
                6. Fold in chocolate chips
                7. Bake for 9-11 minutes
                """,
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-172800),
                tags: ["recipe", "dessert", "baking"]
            )
        ]
    }
    
    func createNote(title: String, content: String) {
        let newNote = Note(
            id: UInt64(notes.count + 1),
            title: title,
            content: content,
            createdAt: Date(),
            updatedAt: Date()
        )
        notes.insert(newNote, at: 0)
    }
    
    func updateNote(_ note: Note, title: String, content: String) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.title = title
            updatedNote.content = content
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
    }
    
    func loadNotes() {
        // Simulate loading
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
        }
    }
}