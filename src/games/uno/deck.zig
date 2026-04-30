const std = @import("std");
const random = std.crypto.random;
const lib = struct {
    const card = @import("card.zig");
};


const DECK_CAPACITY = 108;


const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const List = std.ArrayList;
const Card = lib.card.Card;


pub const Deck = struct {

    const Position = union(enum) {
        rand: void,
        above: void,
        top: void,
        at: usize,
    };


    arena: Arena,
    cards: List(Card),


    pub fn empty(allocator: Allocator) !Deck {
        var arena = Arena.init(allocator);
        errdefer arena.deinit();
        const cards = try List(Card).initCapacity(arena.allocator(), DECK_CAPACITY);

        return Deck{
            .arena = arena,
            .cards = cards,
        };
    }

    pub fn standard(allocator: Allocator) !Deck {

        var self = try Deck.empty(allocator);

        for (0..4) |c| {

            const color = @as(Card.Color, @enumFromInt(c));

            // Number Cards - 0.
            self.cards.appendAssumeCapacity(Card.number(0, color));

            // Number Cards - 1:9.
            for (1..10) |i| {
                const num = @as(u8, @intCast(i));

                self.cards.appendAssumeCapacity(Card.number(num, color));
                self.cards.appendAssumeCapacity(Card.number(num, color));
            }

            // Skip Cards.
            self.cards.appendAssumeCapacity(Card.skip(color));
            self.cards.appendAssumeCapacity(Card.skip(color));

            // Reverse Cards.
            self.cards.appendAssumeCapacity(Card.reverse(color));
            self.cards.appendAssumeCapacity(Card.reverse(color));

            // Draw Two Cards.
            self.cards.appendAssumeCapacity(Card.draw(2, color));
            self.cards.appendAssumeCapacity(Card.draw(2, color));

            // Wild Cards.
            self.cards.appendAssumeCapacity(Card.wild());

            // Wild Draw Cards.
            self.cards.appendAssumeCapacity(Card.wildDraw(4));
        }

        return self;
    }

    pub fn capacity(self: *const Deck) usize {
        return self.cards.capacity;
    }

    pub fn count(self: *const Deck) usize {
        return self.cards.items.len;
    }

    pub fn shuffle(self: *Deck) void {
        random.shuffle(Card, self.cards.items);
    }

    pub fn insert(self: *Deck, card: Card, pos: Position) void {
        const i = self.index(pos);
        self.cards.insertAssumeCapacity(i, card);
    }

    pub fn burn(self: *Deck, dst: *Deck, src_pos: Position, dst_pos: Position) void {
        const burned = self.pick(src_pos);
        dst.insert(burned, dst_pos);
    }

    pub fn pick(self: *Deck, pos: Position) Card {
        const i = self.index(pos);
        return self.cards.orderedRemove(i);
    }

    pub fn peek(self: *Deck, pos: Position) Card {
        const i = self.index(pos);
        return self.cards.items[i];
    }

    pub fn point(self: *Deck, pos: Position) *Card {
        const i = self.index(pos);
        return &self.cards.items[i];
    }

    pub fn findNext(self: *Deck, match: Card) ?Position {
        var i = self.index(.above);
        while (i > 0) : (i -= 1) {
            if (self.cards.items[i-1].eql(match)) {
                return self.position(i - 1);
            } else continue;
        } else return null;
    }

    pub fn findNextTag(self: *Deck, match: Card.Tag) ?Position {
        var i = self.index(.above);
        while (i > 0) : (i -= 1) {
            if (self.cards.items[i-1].face.tag().eql(match)) {
                return self.position(i - 1);
            } else continue;
        } else return null;
    }

    pub fn findNextFace(self: *Deck, match: Card.Face) ?Position {
        var i = self.index(.above);
        while (i > 0) : (i -= 1) {
            if (self.cards.items[i-1].face.eql(match)) {
                return self.position(i - 1);
            } else continue;
        } else return null;
    }

    pub fn findNextColor(self: *Deck, match: Card.Color) ?Position {
        var i = self.index(.above);
        while (i > 0) : (i -= 1) {
            if (self.cards.items[i-1].color.eql(match)) {
                return self.position(i - 1);
            } else continue;
        } else return null;
    }

    pub fn print(self: *const Deck) void {
        var i = self.index(.above);
        while (i > 0) : (i -= 1) {
            std.debug.print("{d}\t", .{i});
            self.cards.items[i-1].print();
        }
    }

    fn index(self: *const Deck, pos: Position) usize {
        return switch (pos) {
            .rand => random.uintLessThan(usize, self.count()),
            .above => self.count(),
            .top => self.count() - 1,
            .at => |i| self.count() - i,
        };
    }

    fn position(self: *const Deck, i: usize) Position {
        return .{ .at = self.count() - i };
    }
};
