import SwiftUI

struct ContentView: View {
    @StateObject private var notesService = NotesService()
    @StateObject private var searchService = SearchService()
    @State private var selectedNote: Note?
    @State private var showingNewNote = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search notes...", text: $searchService.searchQuery)
                        .textFieldStyle(.plain)
                    
                    if !searchService.searchQuery.isEmpty {
                        Button {
                            searchService.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Notes list or search results
                if !searchService.searchQuery.isEmpty {
                    SearchResultsView(searchService: searchService, 
                                    notesService: notesService,
                                    selectedNote: $selectedNote)
                } else {
                    NotesListView(notesService: notesService, 
                                selectedNote: $selectedNote)
                }
            }
            .frame(minWidth: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            // Detail view
            if let note = selectedNote {
                NoteEditorView(note: note, notesService: notesService)
            } else {
                VStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("Select a note to begin editing")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Or create a new note using the + button")
                        .foregroundColor(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NewNoteView(notesService: notesService, isPresented: $showingNewNote)
        }
        .alert("Error", isPresented: .constant(notesService.error != nil)) {
            Button("OK") {
                notesService.error = nil
            }
        } message: {
            Text(notesService.error ?? "Unknown error")
        }
    }
}