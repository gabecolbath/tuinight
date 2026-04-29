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

        var self = try Deck.new(allocator);

        for (0..4) |c| {

            const color = @as(Card.Color, @enumFromInt(c));

            // Number Cards - 0.
            self.cards.appendAssumeCapacity(Card.number(0, color));

            // Number Cards - 1:9.
            for (0..9) |i| {
                self.cards.appendAssumeCapacity(Card.number(i, color));
                self.cards.appendAssumeCapacity(Card.number(i, color));
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
    }

    pub fn capacity(self: *Deck) usize {
        return self.cards.capacity;
    }

    pub fn count(self: *Deck) usize {
        return self.cards.items.len;
    }

    pub fn shuffle(self: *Deck) usize {
        random.shuffle(self.cards.items);
    }

    pub fn insert(self: *Deck, card: Card, pos: Position) void {
        const i = self.index(pos);
        self.cards.insertAssumeCapacity(i, card);
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
        var i = self.index(.{ .at = 0 });
        while (i >= 0) : (i -= 1) {
            if (self.cards.items[i].eql(match)) {
                return self.position(i);
            } else continue;
        } else return null;
    }

    pub fn findNextTag(self: *Deck, match: Card.Tag) ?Position {
        var i = self.index(.{ .at = 0 });
        while (i >= 0) : (i -= 1) {
            if (self.cards.items[i].face.tag().eql(match)) {
                return self.position(i);
            } else continue;
        } else return null;
    }

    pub fn findNextFace(self: *Deck, match: Card.Face) ?Position {
        var i = self.index(.{ .at = 0 });
        while (i >= 0) : (i -= 1) {
            if (self.cards.items[i].face.eql(match)) {
                return self.position(i);
            } else continue;
        } else return null;
    }

    pub fn findNextColor(self: *Deck, match: Card.Color) ?Position {
        var i = self.index(.{ .at = 0 });
        while (i >= 0) : (i -= 1) {
            if (self.cards.items[i].color.eql(match)) {
                return self.position(i);
            } else continue;
        } else return null;
    }

    fn index(self: *Deck, pos: Position) usize {
        return switch (pos) {
            .rand => random.uintLessThan(usize, self.count()),
            .top => self.count() - 1,
            .at => |i| self.count() - 1 - i,
        };
    }

    fn position(self: *Deck, i: usize) Position {
        return .{ .at = self.count() - i };
    }
};
