const std = @import("std");
const lib = struct {
    const card = @import("card.zig");
};


const HAND_CAPACITY = 108;


const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const List = std.ArrayList;
const Card = lib.card.Card;


pub const Hand = struct {

    arena: Arena,
    cards: List(Card),


    pub fn empty(allocator: Allocator) !Hand {
        var arena = Arena.init(allocator);
        errdefer arena.deinit();
        const cards = try List(Card).initCapacity(arena.allocator(), HAND_CAPACITY);

        return Hand{
            .arena = arena,
            .cards = cards,
        };
    }

    pub fn count(self: *const Hand) usize {
        return self.cards.items.len;
    }

    pub fn peek(self: *const Hand, pos: usize) Card {
        return self.cards.items[pos];
    }

    pub fn pick(self: *Hand, pos: usize) Card {
        return self.cards.orderedRemove(pos);
    }

    pub fn append(self: *Hand, card: Card) void {
        self.cards.appendAssumeCapacity(card);
    }

    pub fn print(self: *const Hand, lbl: []const u8) void {
        std.debug.print("{s}\n", .{lbl});
        for (self.cards.items, 0..) |card, i| {
            std.debug.print("\t{d: <2}\t", .{i});
            card.print();
        }
    }
};
