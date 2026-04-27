const std = @import("std");
const uuid = @import("uuid");
const rand = std.crypto.random;
const assert = std.debug.assert;


const MAX_NUM_PLAYERS = 8;
const CARD_VAL_ACTION = 20;
const CARD_VAL_WILD = 20;
const STANDARD_DECK_SIZE = 108;


const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const List = std.ArrayList;
const Map = std.AutoArrayHashMapUnmanaged;
const Uuid = uuid.Uuid;


pub const Card = struct {

    pub const Face = union(enum) {
        number: u8,
        action_skip: void,
        action_reverse: void,
        action_draw: u8,
        wild: void,
        wild_draw: u8,
    };

    pub const Color = enum {
        red,
        green,
        blue,
        yellow,
        none,
    };


    // Card data.
    val: u8,
    face: Face,
    color: Color,

    // Playability flag.
    playable: bool,


    pub fn number(num: u8, color: Color) Card {
        return Card{
            .val = num,
            .face = .{ .number = num },
            .color = color,
        };
    }

    pub fn skip(color: Color) Card {
        return Card{
            .val = CARD_VAL_ACTION,
            .face = .skip,
            .color = color,
        };
    }

    pub fn reverse(color: Color) Card {
        return Card{
            .val = CARD_VAL_ACTION,
            .face = .reverse,
            .color = color,
        };
    }

    pub fn draw(draws: u8, color: Color) Card {
        return Card{
            .val = CARD_VAL_ACTION,
            .face = .{ .draw = draws },
            .color = color,
        };
    }

    pub fn wild() Card {
        return Card{
            .val = CARD_VAL_WILD,
            .face = .wild,
            .color = .none,
        };
    }

    pub fn wildDraw(draws: u8) Card {
        return Card{
            .val = CARD_VAL_WILD,
            .face = .{ .wild_draw = draws },
            .color = .none,
        };
    }
};


pub const DrawPile = struct {

    // Memory management.
    arena: Arena,

    // Card data.
    cards: List(Card),
    size: usize,

    // Hand dealing.
    hand_buffer: []Card,

    pub fn standard(allocator: Allocator) !DrawPile {

        // Initialize arena allocator.
        var arena = Arena.init(allocator);
        errdefer arena.deinit();

        // Initialize card data.
        var cards = try List(Card).initCapacity(arena.allocator(), STANDARD_DECK_SIZE);
        for (0..4) |c| {

            // Get color.
            const color = @as(Card.Color, @enumFromInt(c));

            // Number Cards - 0.
            cards.appendAssumeCapacity(Card.number(0, color));

            // Number Cards - 1:9.
            for (0..9) |i| {
                cards.appendAssumeCapacity(Card.number(i, color));
                cards.appendAssumeCapacity(Card.number(i, color));
            }

            // Skip Cards.
            cards.appendAssumeCapacity(Card.skip(color));
            cards.appendAssumeCapacity(Card.skip(color));

            // Reverse Cards.
            cards.appendAssumeCapacity(Card.reverse(color));
            cards.appendAssumeCapacity(Card.reverse(color));

            // Draw Two Cards.
            cards.appendAssumeCapacity(Card.draw(2, color));
            cards.appendAssumeCapacity(Card.draw(2, color));

            // Wild Cards.
            cards.appendAssumeCapacity(Card.wild());

            // Wild Draw Cards.
            cards.appendAssumeCapacity(Card.wildDraw(4));
        }

        // Initialize hand buffer.
        const hand_buffer = try arena.allocator().alloc(Card, STANDARD_DECK_SIZE);

        // Return initialized draw pile.
        return DrawPile{
            .arena = arena,
            .cards = cards,
            .size = STANDARD_DECK_SIZE,
            .hand_buffer = hand_buffer,
        };
    }

    pub fn deinit(self: *DrawPile) void {

        // Deinitialize underlying arena allocator.
        self.arena.deinit();
    }

    pub fn count(self: *DrawPile) usize {

        // Return len of cards list items.
        return self.cards.items.len;
    }

    pub fn shuffle(self: *DrawPile) void {

        // Randomize card positions.
        rand.shuffle(self.cards.items);
    }

    pub fn draw(self: *DrawPile) ?Card {

        // Pop from cards list and return result.
        return self.cards.pop();
    }

    pub fn deal(self: *DrawPile, num_cards: usize) ?[]Card {

        // Check if pile has sufficient amount of cards.
        if (num_cards >= self.cards.items.len) {
            return null;
        }

        // Draw cards from deck and place in hand buffer.
        for (0..num_cards) |i| {
            self.hand_buffer[i] = self.draw().?;
        }

        // Return slice of hand buffer containing dealt cards.
        return self.hand_buffer[0..num_cards];
    }
};


pub const DiscardPile = struct {

    // Memory management.
    arena: Arena,

    // Card data.
    cards: List(Card),
    size: usize,


    pub fn standard(allocator: Allocator) !DiscardPile {

        // Initialize arena allocator.
        var arena = Arena.init(allocator);
        errdefer arena.deinit();

        // Initialize card data.
        const cards = try List(Card).initCapacity(arena.allocator(), STANDARD_DECK_SIZE);

        // Return initialized DiscardPile.
        return DiscardPile{
            .arena = arena,
            .cards = cards,
            .size = STANDARD_DECK_SIZE,
        };
    }

    pub fn deinit(self: *DiscardPile) void {

        // Deinitialize underlying arena allocator.
        self.arena.deinit();
    }

    pub fn count(self: *DiscardPile) usize {

        // Return len of cards list items.
        return self.cards.items.len;
    }

    pub fn play(self: *DiscardPile, card: Card) void {

        // Append card to cards list.
        self.cards.appendAssumeCapacity(card);
    }

    pub fn last(self: *DiscardPile) Card {

        // Assume there is always a top card.
        assert(self.cards.items.len >= 1);

        // Return last card in the list.
        const i = self.cards.items.len - 1;
        return self.cards.items[i];
    }

    pub fn recolor(self: *DiscardPile, color: Card.Color) void {

        // Assume there is always a top card.
        assert(self.cards.items.len >= 1);

        // Set the color of the last card in the list.
        const i = self.cards.items.len - 1;
        self.cards.items[i].color = color;
    }

    pub fn replenish(self: *DiscardPile, draw_pile: *DrawPile) void {

        // Assume there is always a top card.
        assert(self.cards.items.len >= 1);

        // Pop the top card.
        const top_card = self.cards.pop();

        // Append the rest to the draw pile.
        draw_pile.cards.appendSliceAssumeCapacity(self.cards.items);
        self.cards.clearRetainingCapacity();

        // Put the top card back in the discard pile.
        self.cards.appendAssumeCapacity(top_card);
    }
};


pub const Hand = struct {

    // Memory management.
    arena: Arena,

    // Card data.
    cards: List(Card),
    size: usize,

    pub fn standard(allocator: Allocator) !Hand {

        // Initialize arena allocator.
        var arena = Arena.init(allocator);
        errdefer arena.deinit();

        // Initialize card data.
        const cards = try List(Card).initCapacity(arena.allocator(), STANDARD_DECK_SIZE);

        // Return Hand.
        return Hand{
            .arena = arena,
            .cards = cards,
            .size = STANDARD_DECK_SIZE,
        };
    }

    pub fn deinit(self: *Hand) void {

        // Deinitialize underlying arena.
        self.arena.deinit();
    }

    pub fn draw(self: *Hand, card: Card) void {

        // Append to card list.
        self.cards.appendAssumeCapacity(card);
    }

    pub fn deal(self: *Hand, cards: []Card) void {

        // Append slice to card list.
        self.cards.appendSliceAssumeCapacity(cards);
    }

    pub fn play(self: *Hand, hand_pos: usize) Card {

        // Remove in-order from the card list and return the removed card.
        return self.cards.orderedRemove(hand_pos);
    }
};


pub const Turn = struct {

    // Memory management.
    arena: Arena,

    // Turn data.
    order: List(Uuid),

    // Turn state.
    index: usize,
    reversed: bool,
    penalty: u8,


    pub fn init(allocator: Allocator) !Turn {

        // Initialize arena allocator.
        var arena = Arena.init(allocator);
        errdefer arena.deinit();

        // Initialize order list.
        const order = try List(Uuid).initCapacity(arena.allocator(), MAX_NUM_PLAYERS);

        // Return initialized Turn.
        return Turn{
            .arena = arena,
            .order = order,
            .index = 0,
            .reversed = false,
            .penalty = 0,
        };
    }

    pub fn deinit(self: *Turn) void {

        // Deinitialize underlying arena.
        self.arena.deinit();
    }

    pub fn orderOf(self: *Turn, player_id: Uuid) ?usize {

        // Find matching player and return nothing if not found.
        for (self.order.items, 0..) |possible_match, i| {
            if (possible_match == player_id) {
                return i;
            } else continue;
        } else return null;
    }

    pub fn append(self: *Turn, player_id: Uuid) void {

        // Append new player id to order list.
        self.order.appendAssumeCapacity(player_id);
    }

    pub fn remove(self: *Turn, player_id: Uuid) void {

        // Find player with ID and do nothing if not found.
        const index = self.orderOf(player_id) orelse return;

        // Remove turn in order.
        _ = self.order.orderedRemove(index);

        // Adjust current index.
        self.index %= self.order.items.len;
    }

    pub fn current(self: *Turn) Uuid {

        // Return player id stored in order.
        return self.order.items[self.index];
    }

    pub fn reverse(self: *Turn) void {

        // Not operator on reversed flag.
        self.reversed = !self.reversed;
    }

    pub fn stackPenalty(self: *Turn, penalty: u8) void {

        // Add penalty to stored penalty.
        self.penalty += penalty;
    }

    pub fn clearPenalty(self: *Turn) void {

        // Set stored penalty to 0.
        self.penalty = 0;
    }

    pub fn next(self: *Turn) void {

        // Increment index based on whether reversed or not.
        const n = self.order.items.len;
        self.index += n;
        self.index += if (self.reversed) -1 else 1;
        self.index %= n;
    }
};


pub const Options = struct {
};


pub const Game = struct {

    // Memory management.
    arena: Arena,

    // Deck data.
    draw_pile: DrawPile,
    discard_pile: DiscardPile,

    // Hands data.
    hands: Map(Uuid, Hand),

    // Turn data.
    turn: Turn,

    // Game options.
    opts: Options,


    pub fn init(allocator: Allocator, opts: Options) !Game {

        // Initialize arena allocator.
        var arena = Arena.init(allocator);
        errdefer arena.deinit();

        // Initialize piles.
        var draw_pile = try DrawPile.standard(arena.allocator());
        var discard_pile = try DiscardPile.standard(arena.allocator());
        draw_pile.shuffle();
        discard_pile.play(draw_pile.draw().?);

        // Initialize hands.
        const hands = Map(Uuid, Hand){};
        try hands.ensureTotalCapacity(arena.allocator(), MAX_NUM_PLAYERS);

        // Initialize turns.
        const turns = try Turn.init(arena.allocator());

        // Return initialized game.
        return Game{
            .arena = arena,
            .draw_pile = draw_pile,
            .discard_pile = discard_pile,
            .hands = hands,
            .turns = turns,
            .opts = opts,
        };
    }

    pub fn deinit(self: *Game) void {

        // Deinitialize underlying arena.
        self.arena.deinit();
    }

    
};
