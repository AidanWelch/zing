const std = @import("std");
const track = @import("./track.zig");

pub const Track = track.Track;
pub const TrackData = track.TrackData;
pub const TrackDataAllocator = track.TrackDataAllocator;
pub const TransformFunction = track.TransformFunction;

pub const add = @import("./math/add.zig").add;
pub const invert = @import("./math/invert.zig").invert;
pub const multiply = @import("./math/multiply.zig").multiply;
pub const offset = @import("./math/offset.zig").offset;
pub const scale = @import("./math/scale.zig").scale;

pub const sin = @import("./sounds/sin.zig").sin;
pub const slope = @import("./sounds/slope.zig").slope;
