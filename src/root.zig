const std = @import("std");
const track = @import("./track.zig");

pub const Track = track.Track;
pub const TrackData = track.TrackData;
pub const TrackOptions = track.TrackOptions;
pub const Rectification = @import("./math/rectify.zig").Rectification;

pub const add = @import("./math/add.zig").add;
pub const invert = @import("./math/invert.zig").invert;
pub const multiply = @import("./math/multiply.zig").multiply;
pub const offset = @import("./math/offset.zig").offset;
pub const push = @import("./math/push.zig").push;
pub const rectify = @import("./math/rectify.zig").rectify;
pub const scale = @import("./math/scale.zig").scale;
pub const speed = @import("./math/speed.zig").speed;

pub const silence = @import("./sounds/silence.zig").silence;
pub const sin = @import("./sounds/sin.zig").sin;
pub const slope = @import("./sounds/slope.zig").slope;
pub const square = @import("./sounds/square.zig").square;
