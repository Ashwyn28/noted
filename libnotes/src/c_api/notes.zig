const std = @import("std");
const Note = @import("../core/note.zig").Note;
const Database = @import("../core/database.zig").Database;
const SearchEngine = @import("../core/search.zig").SearchEngine;
const types = @import("types.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var global_allocator = gpa.allocator();
var global_database: ?Database = null;
var global_search_engine: ?SearchEngine = null;

// Initialize the notes library
export fn notes_init(db_path: [*:0]const u8) c_int {
    const path = std.mem.span(db_path);
    
    global_database = Database.init(global_allocator, path) catch {
        return types.NOTES_ERROR_DATABASE;
    };

    global_search_engine = SearchEngine.init(global_allocator, &global_database.?);
    
    return types.NOTES_OK;
}

// Cleanup resources
export fn notes_cleanup() void {
    if (global_database) |*db| {
        db.deinit();
        global_database = null;
    }
    global_search_engine = null;
    _ = gpa.deinit();
}

// Create a new note
export fn notes_create(title: [*:0]const u8, content: [*:0]const u8) u64 {
    if (global_database == null) return 0;

    const title_span = std.mem.span(title);
    const content_span = std.mem.span(content);

    var note = Note.init(global_allocator, title_span, content_span) catch return 0;
    global_database.?.saveNote(&note) catch return 0;

    return note.id;
}

// Get all notes
export fn notes_get_all() types.CNotesResult {
    if (global_database == null) {
        return types.CNotesResult{
            .notes = undefined,
            .count = 0,
            .error_code = types.NOTES_ERROR_DATABASE,
            .error_message = "Database not initialized",
        };
    }

    const notes = global_database.?.getAllNotes() catch {
        return types.CNotesResult{
            .notes = undefined,
            .count = 0,
            .error_code = types.NOTES_ERROR_DATABASE,
            .error_message = "Failed to fetch notes",
        };
    };

    // Convert to C-compatible format
    const c_notes = global_allocator.alloc(types.CNote, notes.len) catch {
        return types.CNotesResult{
            .notes = undefined,
            .count = 0,
            .error_code = types.NOTES_ERROR_MEMORY,
            .error_message = "Memory allocation failed",
        };
    };

    for (notes, 0..) |note, i| {
        const title_cstr = global_allocator.dupeZ(u8, note.title) catch {
            return types.CNotesResult{
                .notes = undefined,
                .count = 0,
                .error_code = types.NOTES_ERROR_MEMORY,
                .error_message = "Memory allocation failed",
            };
        };
        
        const content_cstr = global_allocator.dupeZ(u8, note.content) catch {
            return types.CNotesResult{
                .notes = undefined,
                .count = 0,
                .error_code = types.NOTES_ERROR_MEMORY,
                .error_message = "Memory allocation failed",
            };
        };

        c_notes[i] = types.CNote{
            .id = note.id,
            .title = title_cstr.ptr,
            .content = content_cstr.ptr,
            .created_at = note.created_at,
            .updated_at = note.updated_at,
            .tags = "[]", // Empty tags for now
        };
    }

    return types.CNotesResult{
        .notes = c_notes.ptr,
        .count = c_notes.len,
        .error_code = types.NOTES_OK,
        .error_message = "",
    };
}

// Search notes
export fn notes_search(query: [*:0]const u8, limit: u32) types.CSearchResults {
    if (global_search_engine == null) {
        return types.CSearchResults{
            .results = undefined,
            .count = 0,
            .error_code = types.NOTES_ERROR_DATABASE,
            .error_message = "Search engine not initialized",
        };
    }

    const query_span = std.mem.span(query);
    const results = global_search_engine.?.search(query_span, limit) catch {
        return types.CSearchResults{
            .results = undefined,
            .count = 0,
            .error_code = types.NOTES_ERROR_DATABASE,
            .error_message = "Search failed",
        };
    };

    // Convert to C-compatible format
    const c_results = global_allocator.alloc(types.CSearchResult, results.len) catch {
        return types.CSearchResults{
            .results = undefined,
            .count = 0,
            .error_code = types.NOTES_ERROR_MEMORY,
            .error_message = "Memory allocation failed",
        };
    };

    for (results, 0..) |result, i| {
        const snippet_cstr = global_allocator.dupeZ(u8, result.snippet) catch {
            return types.CSearchResults{
                .results = undefined,
                .count = 0,
                .error_code = types.NOTES_ERROR_MEMORY,
                .error_message = "Memory allocation failed",
            };
        };

        c_results[i] = types.CSearchResult{
            .note_id = result.note_id,
            .rank = result.rank,
            .snippet = snippet_cstr.ptr,
        };
    }

    return types.CSearchResults{
        .results = c_results.ptr,
        .count = c_results.len,
        .error_code = types.NOTES_OK,
        .error_message = "",
    };
}

// Free memory allocated for results
export fn notes_free_results(results: types.CNotesResult) void {
    if (results.notes) |notes| {
        for (0..results.count) |i| {
            global_allocator.free(std.mem.span(notes[i].title));
            global_allocator.free(std.mem.span(notes[i].content));
        }
        global_allocator.free(notes[0..results.count]);
    }
}

export fn notes_free_search_results(results: types.CSearchResults) void {
    if (results.results) |search_results| {
        for (0..results.count) |i| {
            global_allocator.free(std.mem.span(search_results[i].snippet));
        }
        global_allocator.free(search_results[0..results.count]);
    }
}