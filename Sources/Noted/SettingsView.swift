import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize = 14.0
    @AppStorage("fontFamily") private var fontFamily = "System"
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("showWordCount") private var showWordCount = true
    
    var body: some View {
        TabView {
            // General settings
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Editor") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Font Size:")
                            Spacer()
                            Slider(value: $fontSize, in: 10...24, step: 1)
                                .frame(width: 120)
                            Text("\(Int(fontSize))pt")
                                .frame(width: 30)
                        }
                        
                        HStack {
                            Text("Font Family:")
                            Spacer()
                            Picker("Font", selection: $fontFamily) {
                                Text("System").tag("System")
                                Text("Monaco").tag("Monaco")
                                Text("Menlo").tag("Menlo")
                                Text("SF Mono").tag("SF Mono")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                        
                        Toggle("Auto-save changes", isOn: $autoSave)
                        Toggle("Show word count", isOn: $showWordCount)
                    }
                    .padding()
                }
                
                GroupBox("Search") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Search includes:")
                            Spacer()
                        }
                        
                        VStack(alignment: .leading) {
                            Toggle("Note titles", isOn: .constant(true))
                                .disabled(true)
                            Toggle("Note content", isOn: .constant(true))
                                .disabled(true)
                            Toggle("Tags", isOn: .constant(true))
                                .disabled(true)
                        }
                        .padding(.leading)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // Advanced settings
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Storage") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Database location:")
                            Spacer()
                        }
                        
                        HStack {
                            Text("~/Library/Application Support/Noted/notes.db")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Show in Finder") {
                                showDatabaseInFinder()
                            }
                            .buttonStyle(.link)
                        }
                        
                        Divider()
                        
                        HStack {
                            Button("Export All Notes...") {
                                exportAllNotes()
                            }
                            
                            Spacer()
                            
                            Button("Import Notes...") {
                                importNotes()
                            }
                        }
                    }
                    .padding()
                }
                
                GroupBox("Performance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Search indexing: SQLite FTS5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Core engine: Zig native library")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("Advanced", systemImage: "gearshape.2")
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func showDatabaseInFinder() {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, 
                                                   in: .userDomainMask).first else { return }
        
        let notesDirectoryURL = appSupportURL.appendingPathComponent("Noted")
        NSWorkspace.shared.open(notesDirectoryURL)
    }
    
    private func exportAllNotes() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "notes-export-\(DateFormatter.filenameSafe.string(from: Date()))"
        
        savePanel.begin { response in
            if response == .OK {
                // TODO: Implement export functionality
            }
        }
    }
    
    private func importNotes() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        
        openPanel.begin { response in
            if response == .OK {
                // TODO: Implement import functionality
            }
        }
    }
}

extension DateFormatter {
    static let filenameSafe: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }()
}