import Foundation
import Combine

class NotesService: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var isInitialized = false
    
    init() {
        initializeDatabase()
    }
    
    deinit {
        if isInitialized {
            LibNotes.notes_cleanup()
        }
    }
    
    private func initializeDatabase() {
        // Get app support directory
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, 
                                                   in: .userDomainMask).first else {
            error = "Could not access application support directory"
            return
        }
        
        let notesDirectoryURL = appSupportURL.appendingPathComponent("Noted")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: notesDirectoryURL, 
                                       withIntermediateDirectories: true)
        
        let dbURL = notesDirectoryURL.appendingPathComponent("notes.db")
        let dbPath = dbURL.path
        
        let result = dbPath.withCString { cString in
            LibNotes.notes_init(cString)
        }
        
        if result == LibNotes.NOTES_OK {
            isInitialized = true
            loadNotes()
        } else {
            error = "Failed to initialize database"
        }
    }
    
    func loadNotes() {
        guard isInitialized else { return }
        
        isLoading = true
        error = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = LibNotes.notes_get_all()
            
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if result.error_code == LibNotes.NOTES_OK {
                    var loadedNotes: [Note] = []
                    
                    if let notesPtr = result.notes {
                        for i in 0..<Int(result.count) {
                            let cNote = notesPtr[i]
                            let note = Note(from: cNote)
                            loadedNotes.append(note)
                        }
                    }
                    
                    self?.notes = loadedNotes
                    LibNotes.notes_free_results(result)
                } else {
                    let errorMsg = String(cString: result.error_message)
                    self?.error = "Failed to load notes: \(errorMsg)"
                }
            }
        }
    }
    
    func createNote(title: String, content: String) {
        guard isInitialized else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let noteId = title.withCString { titleCString in
                content.withCString { contentCString in
                    LibNotes.notes_create(titleCString, contentCString)
                }
            }
            
            DispatchQueue.main.async {
                if noteId > 0 {
                    self?.loadNotes() // Reload to get the new note
                } else {
                    self?.error = "Failed to create note"
                }
            }
        }
    }
    
    func deleteNote(_ note: Note) {
        // TODO: Implement delete functionality in Zig core
        // For now, just remove from local array
        notes.removeAll { $0.id == note.id }
    }
    
    func updateNote(_ note: Note, title: String, content: String) {
        // TODO: Implement update functionality in Zig core
        // For now, create a new note and remove the old one
        createNote(title: title, content: content)
        deleteNote(note)
    }
}