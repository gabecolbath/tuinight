const std = @import("std");
const uuid = @import("uuid");
const lib = struct {
    const card = @import("card.zig");
    const deck = @import("deck.zig");
    const hand = @import("hand.zig");
};


const MAX_PLAYER_COUNT = 8;
const DEAL_SIZE = 7;


const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const List = std.ArrayList;
const Map = std.AutoArrayHashMapUnmanaged;
const Uuid = uuid.Uuid;
const Card = lib.card.Card;
const Deck = lib.deck.Deck;
const Hand = lib.hand.Hand;


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

    pub fn draw(self: *Game, player: Uuid) void {
        var hand = self.fetchHand(player) orelse return;

        const drawn = self.decks.main.pick(.top);
        hand.append(drawn);

        self.updateHand(player, hand);
    }

    pub fn play(self: *Game, player: Uuid, card: usize) void {
        var hand = self.fetchHand(player) orelse return;

        const played = hand.pick(card);
        self.decks.discard.insert(played, .top);

        self.updateHand(player, hand);
    }

    pub fn deal(self: *Game, player: Uuid) void {
        var hand = self.fetchHand(player) orelse return;

        for (0..DEAL_SIZE) |_| {
            const dealt = self.decks.main.pick(.top);
            hand.append(dealt);
        }

        self.updateHand(player, hand);
    }

    fn fetchHand(self: *Game, player: Uuid) ?Hand {
        return self.hands.get(player);
    }

    fn updateHand(self: *Game, player: Uuid, hand: Hand) void {
        self.hands.putAssumeCapacity(player, hand);
    }
};
