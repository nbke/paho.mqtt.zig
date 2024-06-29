const std = @import("std");
const Step = std.Build.Step;
const ResolvedTarget = std.Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const Mode = enum { sync, @"async" };
    const mode = b.Option(Mode, "client_mode", "Select either sync or async client") orelse .sync;
    const enable_ssl = b.option(bool, "enable_ssl", "Link OpenSSL for TLS encryption") orelse false;
    const high_perf_mode = b.option(bool, "high_perf_mode", "Disable tracing and heap tracking") orelse true;

    const module = b.addModule("paho_mqtt_zig", .{
        .root_source_file = b.path("src/common.zig"),
    });

    const config = b.addOptions();
    config.addOption(Mode, "mode", mode);
    config.addOption(bool, "enable_ssl", enable_ssl);
    config.addOption(bool, "high_perf_mode", high_perf_mode);
    module.addOptions("config", config);

    const dep_paho_mqtt_c = b.dependency("paho_mqtt_c", .{});
    const lib_paho_mqtt_c = b.addStaticLibrary(.{
        .name = "paho_mqtt_c",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .pic = pie,
        .strip = strip,
    });
    module.linkLibrary(lib_paho_mqtt_c);

    const config_h = b.addConfigHeader(.{
        .style = .{ .cmake = dep_paho_mqtt_c.path("src/VersionInfo.h.in") },
        .include_path = "VersionInfo.h",
    }, .{
        .BUILD_TIMESTAMP = "1970-1-1",
        .CLIENT_VERSION = "1.13.3", // TODO read files from tarball
    });
    lib_paho_mqtt_c.addConfigHeader(config_h);

    lib_paho_mqtt_c.addIncludePath(dep_paho_mqtt_c.path("include"));

    var sources = std.ArrayList([]const u8).init(b.allocator);
    switch (mode) {
        .sync => sources.append("MQTTClient.c") catch @panic("OOM"),
        .@"async" => sources.appendSlice(&.{
            "MQTTAsync.c",
            "MQTTAsyncUtils.c",
        }) catch @panic("OOM"),
    }
    sources.appendSlice(&.{
        "MQTTTime.c",
        "MQTTProtocolClient.c",
        "Clients.c",
        "utf-8.c",
        "MQTTPacket.c",
        "MQTTPacketOut.c",
        "Messages.c",
        "Tree.c",
        "Socket.c",
        "Log.c",
        "MQTTPersistence.c",
        "Thread.c",
        "MQTTProtocolOut.c",
        "MQTTPersistenceDefault.c",
        "SocketBuffer.c",
        "LinkedList.c",
        "MQTTProperties.c",
        "MQTTReasonCodes.c",
        "Base64.c",
        "SHA1.c",
        "WebSocket.c",
        "Proxy.c",
    }) catch @panic("OOM");
    if (!high_perf_mode) sources.appendSlice(&.{
        "StackTrace.c",
        "Heap.c",
    }) catch @panic("OOM");
    if (enable_ssl) sources.append("SSLSocket.c") catch @panic("OOM");

    const cflags: []const []const u8 = &.{
        "-pedantic",
        "-Wall",
        "-Wextra",
        "-Wshadow",
        "-Wpointer-arith",
        "-Wcast-align",
        "-Wwrite-strings",
        "-Wstrict-prototypes",
        "-Wmissing-prototypes",
        "-Wno-long-long",
        "-Wno-format-extra-args",
    };

    lib_paho_mqtt_c.addCSourceFiles(.{
        .root = dep_paho_mqtt_c.path("src"),
        .files = sources.items,
        .flags = cflags,
    });
    lib_paho_mqtt_c.root_module.addCMacro("PAHO_MQTT_STATIC", "1");
    if (high_perf_mode) lib_paho_mqtt_c.root_module.addCMacro("HIGH_PERFORMANCE", "1");

    if (enable_ssl) {
        const opts = .{ .target = target, .optimize = optimize };
        if (b.lazyDependency("openssl", opts)) |dep_openssl| {
            lib_paho_mqtt_c.root_module.addCMacro("OPENSSL", "1");
            var openssl_artifact = dep_openssl.artifact("openssl");
            openssl_artifact.root_module.pic = pie;
            openssl_artifact.root_module.strip = strip;
            lib_paho_mqtt_c.linkLibrary(openssl_artifact);
        }
    }
}