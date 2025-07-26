import SwiftUI

struct NoteEditorView: View {
    let note: Note
    @ObservedObject var notesService: MockNotesService
    
    @State private var title: String
    @State private var content: String
    @State private var hasUnsavedChanges = false
    @FocusState private var isContentFocused: Bool
    
    init(note: Note, notesService: MockNotesService) {
        self.note = note
        self.notesService = notesService
        self._title = State(initialValue: note.title)
        self._content = State(initialValue: note.content)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                TextField("Note title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2.bold())
                
                Spacer()
                
                if hasUnsavedChanges {
                    Button("Save") {
                        saveNote()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("s", modifiers: .command)
                }
                
                Button {
                    // Share note
                    shareNote()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Editor area
            VStack {
                TextEditor(text: $content)
                    .font(.body)
                    .padding(8)
                    .background(Color.clear)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onTapGesture {
                        isContentFocused = true
                    }
                    .focused($isContentFocused)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Status bar
            HStack {
                Text("Created: \(DateFormatter.shortDateTime.string(from: note.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if note.createdAt != note.updatedAt {
                    Text("• Updated: \(DateFormatter.shortDateTime.string(from: note.updatedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            isContentFocused = true
        }
        .onDisappear {
            if hasUnsavedChanges {
                saveNote()
            }
        }
    }
    
    private var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private func saveNote() {
        guard hasUnsavedChanges else { return }
        
        notesService.updateNote(note, title: title, content: content)
        hasUnsavedChanges = false
    }
    
    private func shareNote() {
        let shareText = "\(title)\n\n\(content)"
        let activityVC = NSSharingServicePicker(items: [shareText])
        
        if let window = NSApp.keyWindow {
            activityVC.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
    
    private func exportNote() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = title.isEmpty ? "Untitled" : title
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let noteContent = "# \(title)\n\n\(content)"
                try? noteContent.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}