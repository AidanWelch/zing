const std = @import("std");
const zing = @import("zing");
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const opts: zing.TrackOptions = .{
        .sample_rate = 48000,
        .allocator = allocator,
    };

    var bass_beat = try zing.sin(opts, 2, 3);
    try zing.speed(&bass_beat, 0.1);

    //var t1 = try zing.square(opts, 3, 3);
    //zing.rectify(t1, .POSITIVE_HALF);

    //try zing.multiply(
    //    &t1,
    //    bass_beat,
    //);

    //try zing.push(&t1, try t1.duplicate());

    //try t1.show();
    //try t1.play();
    //t1.free();

    try bass_beat.show();
    bass_beat.free();
}
