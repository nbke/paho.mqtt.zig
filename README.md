# paho.mqtt.zig
Unofficial bindings to paho.mqtt.zig

```zig
pub fn build(b: *std.Build) void {
    // ...

    const paho_mqtt_zig = b.dependency("paho_mqtt_zig", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("paho_mqtt_zig", paho_mqtt_zig.module("paho_mqtt_zig"));
}
```

Options:
- `.client_mode`: Select MqttClient with `sync` and MqttAsync with `async`. Defaults to sync.
- `.enable_ssl`: If true, link OpenSSL for TLS support. Disabled by default.
- `.high_perf_mode`: If true, disable tracing and heap tracking. Enabled by default.

Here is an example of the async client with TLS support:
```zig
const paho_mqtt_zig = b.dependency("paho_mqtt_zig", .{
    .target = target,
    .optimize = optimize,
    .client_mode = .@"async",
    .enable_ssl = true,
});
```

## License
Eclipse Public License v2, same as paho.mqtt.c
