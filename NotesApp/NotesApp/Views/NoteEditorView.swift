import SwiftUI

struct NoteEditorView: View {
    let note: Note
    @ObservedObject var notesService: NotesService
    
    @State private var title: String
    @State private var content: String
    @State private var hasUnsavedChanges = false
    @FocusState private var isContentFocused: Bool
    
    init(note: Note, notesService: NotesService) {
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
                    .textFieldStyle(.plain)
                    .font(.title2.bold())
                    .onChange(of: title) { _, _ in
                        hasUnsavedChanges = true
                    }
                
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
            ScrollView {
                VStack {
                    TextEditor(text: $content)
                        .focused($isContentFocused)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .onChange(of: content) { _, _ in
                            hasUnsavedChanges = true
                        }
                        .frame(minHeight: 400)
                    
                    Spacer()
                }
                .padding()
            }
            
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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    // Toggle preview mode
                } label: {
                    Image(systemName: "eye")
                }
                
                Button {
                    // Export note
                    exportNote()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
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
        savePanel.allowedContentTypes = [.plainText, .markdown]
        savePanel.nameFieldStringValue = title.isEmpty ? "Untitled" : title
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let noteContent = "# \(title)\n\n\(content)"
                try? noteContent.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}