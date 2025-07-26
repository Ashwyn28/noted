const std = @import("std");
const c = @cImport({
    @cInclude("sqlite3.h");
});
const Note = @import("note.zig").Note;
const Allocator = std.mem.Allocator;

pub const Database = struct {
    db: ?*c.sqlite3,
    allocator: Allocator,

    pub fn init(allocator: Allocator, db_path: []const u8) !Database {
        var db: ?*c.sqlite3 = null;
        const path_cstr = try allocator.dupeZ(u8, db_path);
        defer allocator.free(path_cstr);

        const result = c.sqlite3_open(path_cstr.ptr, &db);
        if (result != c.SQLITE_OK) {
            return error.DatabaseOpenFailed;
        }

        var database = Database{
            .db = db,
            .allocator = allocator,
        };

        try database.createTables();
        return database;
    }

    pub fn deinit(self: *Database) void {
        if (self.db) |db| {
            _ = c.sqlite3_close(db);
        }
    }

    fn createTables(self: *Database) !void {
        const create_notes_sql =
            \\CREATE TABLE IF NOT EXISTS notes (
            \\  id INTEGER PRIMARY KEY AUTOINCREMENT,
            \\  title TEXT NOT NULL,
            \\  content TEXT NOT NULL,
            \\  created_at INTEGER NOT NULL,
            \\  updated_at INTEGER NOT NULL,
            \\  tags TEXT DEFAULT '[]'
            \\);
        ;

        const create_fts_sql =
            \\CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
            \\  title, content, tags,
            \\  content='notes',
            \\  content_rowid='id'
            \\);
        ;

        const create_trigger_sql =
            \\CREATE TRIGGER IF NOT EXISTS notes_fts_insert AFTER INSERT ON notes BEGIN
            \\  INSERT INTO notes_fts(rowid, title, content, tags) 
            \\  VALUES (new.id, new.title, new.content, new.tags);
            \\END;
            \\
            \\CREATE TRIGGER IF NOT EXISTS notes_fts_delete AFTER DELETE ON notes BEGIN
            \\  DELETE FROM notes_fts WHERE rowid = old.id;
            \\END;
            \\
            \\CREATE TRIGGER IF NOT EXISTS notes_fts_update AFTER UPDATE ON notes BEGIN
            \\  DELETE FROM notes_fts WHERE rowid = old.id;
            \\  INSERT INTO notes_fts(rowid, title, content, tags) 
            \\  VALUES (new.id, new.title, new.content, new.tags);
            \\END;
        ;

        try self.execSql(create_notes_sql);
        try self.execSql(create_fts_sql);
        try self.execSql(create_trigger_sql);
    }

    fn execSql(self: *Database, sql: []const u8) !void {
        const sql_cstr = try self.allocator.dupeZ(u8, sql);
        defer self.allocator.free(sql_cstr);

        const result = c.sqlite3_exec(self.db, sql_cstr.ptr, null, null, null);
        if (result != c.SQLITE_OK) {
            return error.SqlExecutionFailed;
        }
    }

    pub fn saveNote(self: *Database, note: *Note) !void {
        const sql = "INSERT INTO notes (title, content, created_at, updated_at, tags) VALUES (?, ?, ?, ?, ?)";
        const sql_cstr = try self.allocator.dupeZ(u8, sql);
        defer self.allocator.free(sql_cstr);

        var stmt: ?*c.sqlite3_stmt = null;
        var result = c.sqlite3_prepare_v2(self.db, sql_cstr.ptr, -1, &stmt, null);
        if (result != c.SQLITE_OK) return error.StatementPrepareFailed;
        defer _ = c.sqlite3_finalize(stmt);

        const title_cstr = try self.allocator.dupeZ(u8, note.title);
        defer self.allocator.free(title_cstr);
        const content_cstr = try self.allocator.dupeZ(u8, note.content);
        defer self.allocator.free(content_cstr);

        _ = c.sqlite3_bind_text(stmt, 1, title_cstr.ptr, -1, null);
        _ = c.sqlite3_bind_text(stmt, 2, content_cstr.ptr, -1, null);
        _ = c.sqlite3_bind_int64(stmt, 3, @as(c_longlong, @intCast(note.created_at)));
        _ = c.sqlite3_bind_int64(stmt, 4, @as(c_longlong, @intCast(note.updated_at)));
        _ = c.sqlite3_bind_text(stmt, 5, "[]", -1, null); // Empty tags for now

        result = c.sqlite3_step(stmt);
        if (result != c.SQLITE_DONE) return error.StatementExecutionFailed;

        note.id = @as(u64, @intCast(c.sqlite3_last_insert_rowid(self.db)));
    }

    pub fn getAllNotes(self: *Database) ![]Note {
        const sql = "SELECT id, title, content, created_at, updated_at, tags FROM notes ORDER BY updated_at DESC";
        const sql_cstr = try self.allocator.dupeZ(u8, sql);
        defer self.allocator.free(sql_cstr);

        var stmt: ?*c.sqlite3_stmt = null;
        var result = c.sqlite3_prepare_v2(self.db, sql_cstr.ptr, -1, &stmt, null);
        if (result != c.SQLITE_OK) return error.StatementPrepareFailed;
        defer _ = c.sqlite3_finalize(stmt);

        var notes = std.ArrayList(Note).init(self.allocator);
        defer notes.deinit();

        while (c.sqlite3_step(stmt) == c.SQLITE_ROW) {
            const id = @as(u64, @intCast(c.sqlite3_column_int64(stmt, 0)));
            const title_ptr = c.sqlite3_column_text(stmt, 1);
            const content_ptr = c.sqlite3_column_text(stmt, 2);
            const created_at = @as(u64, @intCast(c.sqlite3_column_int64(stmt, 3)));
            const updated_at = @as(u64, @intCast(c.sqlite3_column_int64(stmt, 4)));

            const title = std.mem.span(@as([*:0]const u8, @ptrCast(title_ptr)));
            const content = std.mem.span(@as([*:0]const u8, @ptrCast(content_ptr)));

            const note = Note{
                .id = id,
                .title = try self.allocator.dupe(u8, title),
                .content = try self.allocator.dupe(u8, content),
                .created_at = created_at,
                .updated_at = updated_at,
                .tags = &[_][]const u8{},
            };

            try notes.append(note);
        }

        return notes.toOwnedSlice();
    }
};