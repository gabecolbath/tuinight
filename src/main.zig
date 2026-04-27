const std = @import("std");
const tuinight = @import("tuinight");
const uno = @import("games/uno.zig");


const print = std.debug.print;


pub fn main() !void {
    var dpa = std.heap.DebugAllocator(.{}){};
    defer _ = dpa.deinit();

    var deck = try uno.Deck.standard(dpa.allocator());
    deck.shuffle();
    defer deck.arena.deinit();

    const players: []const []const u8 = &.{
        "Gabe",
        "Kade",
        "Michael",
        "Dan",
    };

    for (players[0..]) |name| {
        const hand = deck.deal(7).?;
        print("{s}'s 'Hand:\n", .{name});
        for (hand) |card|
            card.print();
        print("\n", .{});
    }
}
