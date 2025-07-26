const std = @import("std");

// C-compatible types for Swift interop
pub const CNote = extern struct {
    id: u64,
    title: [*:0]const u8,
    content: [*:0]const u8,
    created_at: u64,
    updated_at: u64,
    tags: [*:0]const u8, // JSON array string
};

pub const CSearchResult = extern struct {
    note_id: u64,
    rank: f64,
    snippet: [*:0]const u8,
};

pub const CNotesResult = extern struct {
    notes: [*]CNote,
    count: usize,
    error_code: i32,
    error_message: [*:0]const u8,
};

pub const CSearchResults = extern struct {
    results: [*]CSearchResult,
    count: usize,
    error_code: i32,
    error_message: [*:0]const u8,
};

// Error codes
pub const NOTES_OK = 0;
pub const NOTES_ERROR_INVALID_PARAM = -1;
pub const NOTES_ERROR_DATABASE = -2;
pub const NOTES_ERROR_NOT_FOUND = -3;
pub const NOTES_ERROR_MEMORY = -4;