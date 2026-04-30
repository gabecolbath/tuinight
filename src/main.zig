const std = @import("std");
const uuid = @import("uuid");
const tuinight = @import("tuinight");
const uno = @import("games/uno/game.zig");


const print = std.debug.print;


const Game = uno.Game;
const Hand = uno.Hand;
const Uuid = uuid.Uuid;
const Map = std.AutoArrayHashMapUnmanaged;


pub fn main() !void {
    var dpa = std.heap.DebugAllocator(.{}){};
    defer _ = dpa.deinit();

    var game = try Game.init(dpa.allocator(), .{});
    defer game.deinit();


    const players: []const []const u8 = &.{
        "Gabe",
        "Kade",
        "Michael",
        "Dan",
    };

    const ids: []const Uuid = &.{
        uuid.v4.new(),
        uuid.v4.new(),
        uuid.v4.new(),
        uuid.v4.new(),
    };

    var player_map = try Map(Uuid, []const u8).init(dpa.allocator(), ids, players);
    defer player_map.deinit(dpa.allocator());

    for (player_map.keys()) |id| {
        const new_hand = try Hand.empty(game.arena.allocator());
        game.hands.putAssumeCapacity(id, new_hand);
    }

    game.start();

    for (player_map.keys()) |id| {
        const name = player_map.get(id) orelse continue;
        const hand = game.hands.get(id) orelse continue;

        hand.print(name);
    }

    std.debug.print("Gabe's Turn\n\n", .{});
    const name = players[0];
    const id = ids[0];
    const hand = game.hands.getPtr(id).?;
    hand.print(name); print("\n", .{});
    game.play(hand, 0);
    hand.print(name); print("\n", .{});

    game.decks.discard.print();
}
