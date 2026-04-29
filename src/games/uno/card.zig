const std = @import("std");


const ACTION_CARD_VALUE = 20;
const WILD_CARD_VALUE = 50;


pub const Card = struct {

    pub const Tag = enum {
        number,
        action_skip,
        action_reverse,
        action_draw,
        wild,
        wild_draw,


        pub fn eql(self: Tag, other: Tag) bool {
            return self == other;
        }
    };

    pub const Face = union(Tag) {
        number: struct { val: u8 },
        action_skip: void,
        action_reverse: void,
        action_draw: struct { penalty: u8 },
        wild: void,
        wild_draw: struct { penalty: u8 },


        pub fn getNumber(self: Face) ?u8 {
            return switch (self) {
                .number => |data| data.val,
                else => null,
            };
        }

        pub fn getDraws(self: Face) ?u8 {
            return switch (self) {
                .action_draw => |data| data.penalty,
                .wild_draw => |data| data.penalty,
                else => null,
            };
        }

        pub fn isNumber(self: Face) bool {
            return switch (self) {
                .number => |_| true,
                else => false,
            };
        }

        pub fn isAction(self: Face) bool {
            return switch (self) {
                .action_skip => true,
                .action_reverse => true,
                .action_draw => |_| true,
                else => false,
            };
        }

        pub fn isWild(self: Face) bool {
            return switch (self) {
                .wild => true,
                .wild_draw => true,
                else => false,
            };
        }

        pub fn isDraw(self: Face) bool {
            return switch (self) {
                .action_draw => true,
                .wild_draw => true,
                else => false,
            };
        }

        pub fn tag(self: Face) Tag {
            return std.meta.Tag(self);
        }

        pub fn eql(self: Face, other: Face) bool {
            return std.meta.eql(self, other);
        }
    };

    pub const Color = enum {
        red,
        green,
        blue,
        yellow,
        none,

        pub fn eql(self: Color, other: Color) bool {
            return self == other;
        }
    };


    value: u8,
    face: Face,
    color: Color,


    pub fn number(num: u8, color: Color) Card {
        return Card{
            .val = num,
            .face = .{ .number = num },
            .color = color,
        };
    }

    pub fn skip(color: Color) Card {
        return Card{
            .value = ACTION_CARD_VALUE,
            .face = .skip,
            .color = color,
        };
    }

    pub fn reverse(color: Color) Card {
        return Card{
            .val = ACTION_CARD_VALUE,
            .face = .reverse,
            .color = color,
        };
    }

    pub fn draw(draws: u8, color: Color) Card {
        return Card{
            .val = ACTION_CARD_VALUE,
            .face = .{ .draw = draws },
            .color = color,
        };
    }

    pub fn wild() Card {
        return Card{
            .val = WILD_CARD_VALUE,
            .face = .wild,
            .color = .none,
        };
    }

    pub fn wildDraw(draws: u8) Card {
        return Card{
            .val = WILD_CARD_VALUE,
            .face = .{ .wild_draw = draws },
            .color = .none,
        };
    }

    pub fn eql(self: Card, other: Card) bool {
        return std.meta.eql(self, other);
    }
};
