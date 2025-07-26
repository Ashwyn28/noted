import SwiftUI

struct NotesListView: View {
    @ObservedObject var notesService: NotesService
    @Binding var selectedNote: Note?
    
    var body: some View {
        List(notesService.notes, selection: $selectedNote) { note in
            ForEach(notesService.notes) { note in 
                Button {
                    selectedNote = note
                } label: {
                    NoteRowView(note: note)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .listStyle(.sidebar)
        .overlay {
            if notesService.notes.isEmpty && !notesService.isLoading {
                VStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No notes yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Create your first note to get started")
                        .foregroundColor(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay {
            if notesService.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            }
        }
        .contextMenu(forSelectionType: Note.self) { notes in
            if notes.count == 1, let note = notes.first {
                Button("Delete") {
                    notesService.deleteNote(note)
                    if selectedNote?.id == note.id {
                        selectedNote = nil
                    }
                }
            }
        }
        .refreshable {
            notesService.loadNotes()
        }
    }
}

struct NoteRowView: View {
    let note: Note
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(note.preview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(dateFormatter.string(from: note.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.tertiary)
                
                Spacer()
                
                if !note.tags.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(note.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }
                        
                        if note.tags.count > 2 {
                            Text("+\(note.tags.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}