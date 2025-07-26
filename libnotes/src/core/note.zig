const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Note = struct {
    id: u64,
    title: []const u8,
    content: []const u8,
    created_at: u64,
    updated_at: u64,
    tags: []const []const u8,

    pub fn init(allocator: Allocator, title: []const u8, content: []const u8) !Note {
        const now = @as(u64, @intCast(std.time.timestamp()));
        
        return Note{
            .id = 0, // Will be set by database
            .title = try allocator.dupe(u8, title),
            .content = try allocator.dupe(u8, content),
            .created_at = now,
            .updated_at = now,
            .tags = &[_][]const u8{},
        };
    }

    pub fn deinit(self: *Note, allocator: Allocator) void {
        allocator.free(self.title);
        allocator.free(self.content);
        for (self.tags) |tag| {
            allocator.free(tag);
        }
        allocator.free(self.tags);
    }

    pub fn update(self: *Note, allocator: Allocator, title: ?[]const u8, content: ?[]const u8) !void {
        if (title) |new_title| {
            allocator.free(self.title);
            self.title = try allocator.dupe(u8, new_title);
        }
        
        if (content) |new_content| {
            allocator.free(self.content);
            self.content = try allocator.dupe(u8, new_content);
        }
        
        self.updated_at = @as(u64, @intCast(std.time.timestamp()));
    }

    pub fn addTag(self: *Note, allocator: Allocator, tag: []const u8) !void {
        const new_tags = try allocator.alloc([]const u8, self.tags.len + 1);
        @memcpy(new_tags[0..self.tags.len], self.tags);
        new_tags[self.tags.len] = try allocator.dupe(u8, tag);
        
        allocator.free(self.tags);
        self.tags = new_tags;
    }
};