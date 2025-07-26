import SwiftUI

@main
struct NotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Note") {
                    // Send notification to create new note
                    NotificationCenter.default.post(name: .createNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(replacing: .help) {
                Button("Noted Help") {
                    // Open help
                }
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

extension Notification.Name {
    static let createNewNote = Notification.Name("createNewNote")
}