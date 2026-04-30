const std = @import("std");
const uuid = @import("uuid");
const assert = std.debug.assert;
const lib = struct {
    const card = @import("card.zig");
    const deck = @import("deck.zig");
    const hand = @import("hand.zig");
};


const MAX_PLAYER_COUNT = 8;
const DEAL_COUNT = 7;


const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const List = std.ArrayList;
const Map = std.AutoArrayHashMapUnmanaged;
const Uuid = uuid.Uuid;

pub const Card = lib.card.Card;
pub const Deck = lib.deck.Deck;
pub const Hand = lib.hand.Hand;


pub const Game = struct {

    pub const Options = struct {
        // TODO
    };

    pub const Decks = struct {
        main: Deck,
        discard: Deck,
    };


    arena: Arena,
    opts: Options,
    decks: Decks,
    hands: Map(Uuid, Hand),
    started: bool = false,


    pub fn init(allocator: Allocator, opts: Options) !Game {
        var arena = Arena.init(allocator);
        errdefer arena.deinit();

        const decks = Decks{
            .main = try Deck.standard(arena.allocator()),
            .discard = try Deck.empty(arena.allocator()),
        };

        var hands = Map(Uuid, Hand){};
        try hands.ensureTotalCapacity(arena.allocator(), MAX_PLAYER_COUNT);

        return Game{
            .arena = arena,
            .opts = opts,
            .decks = decks,
            .hands = hands,
        };
    }

    pub fn deinit(self: *Game) void {
        self.arena.deinit();
    }

    pub fn start(self: *Game) void {
        self.started = true;

        self.decks.main.shuffle();
        const first = self.decks.main.findNextTag(.number).?;
        self.decks.main.burn(&self.decks.discard, first, .above);

        for (self.hands.values()) |*hand| self.deal(hand);
    }

    pub fn draw(self: *Game, hand: *Hand) void {
        assert(self.started);
        const drawn = self.decks.main.pick(.top);
        hand.append(drawn);
    }

    pub fn play(self: *Game, hand: *Hand, pos: usize) void {
        assert(self.started);
        const played = hand.pick(pos);
        self.decks.discard.insert(played, .above);
    }

    pub fn deal(self: *Game, hand: *Hand) void {
        assert(self.started);
        for (0..DEAL_COUNT) |_| self.draw(hand);
    }
};
