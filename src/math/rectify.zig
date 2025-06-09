const std = @import("std");
const zing = @import("../root.zig");

pub const Rectification = enum {
    FULL,
    POSITIVE_HALF,
    NEGATIVE_HALF,
};

pub fn rectify(track: zing.Track, rectification: Rectification) void {
    switch (rectification) {
        .FULL => {
            for (0..track.data.len) |i| {
                track.data[i] = @abs(track.data[i]);
            }
        },
        .POSITIVE_HALF => {
            for (0..track.data.len) |i| {
                if (track.data[i] < 0) {
                    track.data[i] = 0;
                }
            }
        },
        .NEGATIVE_HALF => {
            for (0..track.data.len) |i| {
                if (track.data[i] > 0) {
                    track.data[i] = 0;
                }
            }
        },
    }
}
