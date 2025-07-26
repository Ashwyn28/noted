import SwiftUI

struct NewNoteView: View {
    @ObservedObject var notesService: MockNotesService
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = ""
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                    
                    TextField("Enter note title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTitleFocused)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                    
                    TextEditor(text: $content)
                        .font(.body)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .frame(minHeight: 200)
                }
                
                Spacer()
            }
            .padding()
            .frame(width: 500, height: 400)
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createNote()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                             content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .onAppear {
            isTitleFocused = true
        }
    }
    
    private func createNote() {
        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Use content as title if title is empty
        let noteTitle = finalTitle.isEmpty ? String(finalContent.prefix(50)) : finalTitle
        
        notesService.createNote(title: noteTitle, content: finalContent)
        isPresented = false
    }
}