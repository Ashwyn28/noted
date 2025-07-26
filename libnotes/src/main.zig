const std = @import("std");

// Export C API
pub const c_api = struct {
    pub usingnamespace @import("c_api/notes.zig");
    pub usingnamespace @import("c_api/types.zig");
};

// Core modules for internal use and testing
pub const core = struct {
    pub const Note = @import("core/note.zig").Note;
    pub const Database = @import("core/database.zig").Database;
    pub const SearchEngine = @import("core/search.zig").SearchEngine;
};

test "note creation and basic operations" {
    const allocator = std.testing.allocator;
    
    var note = try core.Note.init(allocator, "Test Note", "This is test content");
    defer note.deinit(allocator);
    
    try std.testing.expect(std.mem.eql(u8, note.title, "Test Note"));
    try std.testing.expect(std.mem.eql(u8, note.content, "This is test content"));
    try std.testing.expect(note.tags.len == 0);
}

test "database operations" {
    const allocator = std.testing.allocator;
    
    // Use in-memory database for testing
    var db = try core.Database.init(allocator, ":memory:");
    defer db.deinit();
    
    var note = try core.Note.init(allocator, "Test Note", "Test content");
    defer note.deinit(allocator);
    
    try db.saveNote(&note);
    try std.testing.expect(note.id > 0);
    
    const notes = try db.getAllNotes();
    defer {
        for (notes) |*n| {
            var mut_note = n.*;
            mut_note.deinit(allocator);
        }
        allocator.free(notes);
    }
    
    try std.testing.expect(notes.len == 1);
    try std.testing.expect(std.mem.eql(u8, notes[0].title, "Test Note"));
}