const std = @import("std");
const c = @cImport({
    @cInclude("sqlite3.h");
});
const Database = @import("database.zig").Database;
const Allocator = std.mem.Allocator;

pub const SearchResult = struct {
    note_id: u64,
    rank: f64,
    snippet: []const u8,

    pub fn deinit(self: *SearchResult, allocator: Allocator) void {
        allocator.free(self.snippet);
    }
};

pub const SearchEngine = struct {
    database: *Database,
    allocator: Allocator,

    pub fn init(allocator: Allocator, database: *Database) SearchEngine {
        return SearchEngine{
            .database = database,
            .allocator = allocator,
        };
    }

    pub fn search(self: *SearchEngine, query: []const u8, limit: u32) ![]SearchResult {
        const sql = 
            \\SELECT notes_fts.rowid, bm25(notes_fts), 
            \\       snippet(notes_fts, 1, '<mark>', '</mark>', '...', 32) as snippet
            \\FROM notes_fts 
            \\WHERE notes_fts MATCH ? 
            \\ORDER BY bm25(notes_fts) 
            \\LIMIT ?
        ;

        const sql_cstr = try self.allocator.dupeZ(u8, sql);
        defer self.allocator.free(sql_cstr);

        const query_cstr = try self.allocator.dupeZ(u8, query);
        defer self.allocator.free(query_cstr);

        var stmt: ?*c.sqlite3_stmt = null;
        var result = c.sqlite3_prepare_v2(self.database.db, sql_cstr.ptr, -1, &stmt, null);
        if (result != c.SQLITE_OK) return error.StatementPrepareFailed;
        defer _ = c.sqlite3_finalize(stmt);

        _ = c.sqlite3_bind_text(stmt, 1, query_cstr.ptr, -1, null);
        _ = c.sqlite3_bind_int(stmt, 2, @as(c_int, @intCast(limit)));

        var results = std.ArrayList(SearchResult).init(self.allocator);
        defer results.deinit();

        while (c.sqlite3_step(stmt) == c.SQLITE_ROW) {
            const note_id = @as(u64, @intCast(c.sqlite3_column_int64(stmt, 0)));
            const rank = c.sqlite3_column_double(stmt, 1);
            const snippet_ptr = c.sqlite3_column_text(stmt, 2);
            
            const snippet_span = std.mem.span(@as([*:0]const u8, @ptrCast(snippet_ptr)));
            const snippet = try self.allocator.dupe(u8, snippet_span);

            const search_result = SearchResult{
                .note_id = note_id,
                .rank = rank,
                .snippet = snippet,
            };

            try results.append(search_result);
        }

        return results.toOwnedSlice();
    }

    pub fn searchSimilar(self: *SearchEngine, note_id: u64, limit: u32) ![]SearchResult {
        // Get the note content first
        const get_note_sql = "SELECT title, content FROM notes WHERE id = ?";
        const get_note_cstr = try self.allocator.dupeZ(u8, get_note_sql);
        defer self.allocator.free(get_note_cstr);

        var get_stmt: ?*c.sqlite3_stmt = null;
        var result = c.sqlite3_prepare_v2(self.database.db, get_note_cstr.ptr, -1, &get_stmt, null);
        if (result != c.SQLITE_OK) return error.StatementPrepareFailed;
        defer _ = c.sqlite3_finalize(get_stmt);

        _ = c.sqlite3_bind_int64(get_stmt, 1, @as(c_longlong, @intCast(note_id)));

        if (c.sqlite3_step(get_stmt) != c.SQLITE_ROW) {
            return error.NoteNotFound;
        }

        const title_ptr = c.sqlite3_column_text(get_stmt, 0);
        const content_ptr = c.sqlite3_column_text(get_stmt, 1);
        
        const title = std.mem.span(@as([*:0]const u8, @ptrCast(title_ptr)));
        const content = std.mem.span(@as([*:0]const u8, @ptrCast(content_ptr)));

        // Extract key terms (simple approach - split on spaces, take longer words)
        var terms = std.ArrayList([]const u8).init(self.allocator);
        defer terms.deinit();

        var title_iter = std.mem.split(u8, title, " ");
        while (title_iter.next()) |word| {
            if (word.len > 3) try terms.append(word);
        }

        var content_iter = std.mem.split(u8, content, " ");
        var word_count: u32 = 0;
        while (content_iter.next()) |word| {
            if (word.len > 3 and word_count < 10) {
                try terms.append(word);
                word_count += 1;
            }
        }

        if (terms.items.len == 0) return &[_]SearchResult{};

        // Build search query
        const query = try std.mem.join(self.allocator, " OR ", terms.items);
        defer self.allocator.free(query);

        const search_sql = 
            \\SELECT notes_fts.rowid, bm25(notes_fts), 
            \\       snippet(notes_fts, 1, '<mark>', '</mark>', '...', 32) as snippet
            \\FROM notes_fts 
            \\WHERE notes_fts MATCH ? AND notes_fts.rowid != ?
            \\ORDER BY bm25(notes_fts) 
            \\LIMIT ?
        ;

        const search_cstr = try self.allocator.dupeZ(u8, search_sql);
        defer self.allocator.free(search_cstr);

        const query_cstr = try self.allocator.dupeZ(u8, query);
        defer self.allocator.free(query_cstr);

        var search_stmt: ?*c.sqlite3_stmt = null;
        result = c.sqlite3_prepare_v2(self.database.db, search_cstr.ptr, -1, &search_stmt, null);
        if (result != c.SQLITE_OK) return error.StatementPrepareFailed;
        defer _ = c.sqlite3_finalize(search_stmt);

        _ = c.sqlite3_bind_text(search_stmt, 1, query_cstr.ptr, -1, null);
        _ = c.sqlite3_bind_int64(search_stmt, 2, @as(c_longlong, @intCast(note_id)));
        _ = c.sqlite3_bind_int(search_stmt, 3, @as(c_int, @intCast(limit)));

        var results = std.ArrayList(SearchResult).init(self.allocator);
        defer results.deinit();

        while (c.sqlite3_step(search_stmt) == c.SQLITE_ROW) {
            const found_note_id = @as(u64, @intCast(c.sqlite3_column_int64(search_stmt, 0)));
            const rank = c.sqlite3_column_double(search_stmt, 1);
            const snippet_ptr = c.sqlite3_column_text(search_stmt, 2);
            
            const snippet_span = std.mem.span(@as([*:0]const u8, @ptrCast(snippet_ptr)));
            const snippet = try self.allocator.dupe(u8, snippet_span);

            const search_result = SearchResult{
                .note_id = found_note_id,
                .rank = rank,
                .snippet = snippet,
            };

            try results.append(search_result);
        }

        return results.toOwnedSlice();
    }
};