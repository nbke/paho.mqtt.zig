const std = @import("std");
const common = @import("common.zig");
const Error = common.Error;
const InitOptions = common.InitOptions;
const LibError = common.LibError;
const MqttMessage = common.MqttMessage;
const MqttProperties = common.MqttProperties;
const MqttReasonCode = common.MqttReasonCode;
const MQTTVersion = common.MQTTVersion;
const NameValue = common.NameValue;
const Persistence = common.Persistence;
const SslOptions = common.SslOptions;
const WillOptions = common.WillOptions;
const QoS = common.QoS;
const Self = @This();

const Handle = *anyopaque;
handle: Handle,

pub const AsyncToken = enum(c_int) {
    _,
};

pub const CreateOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'C', 'O' },
    struct_version: c_int = 2,
    sendWhileDisconnected: c_int = 0,
    maxBufferedMessages: c_int = 100,
    MQTTVersion: MQTTVersion = .v5,
    allowDisconnectedSendAtAnyTime: c_int = 0,
    deleteOldestMessages: c_int = 0,
    restoreMessages: c_int = 1,
    persistQoS0: c_int = 1,
};

pub const ConnectOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'C' },
    struct_version: c_int = 8,
    keepAliveInterval: c_int = 60,
    cleansession: c_int = 0,
    maxInflight: c_int = 65535,
    will: ?*WillOptions = null,
    username: ?[*:0]u8 = null,
    password: ?[*:0]u8 = null,
    connectTimeout: c_int = 30,
    retryInterval: c_int = 0,
    ssl: ?*SslOptions = null,
    onSuccess: ?*const OnSuccessCB = null,
    onFailure: ?*const OnFailureCB = null,
    context: ?*anyopaque = null,
    serverURIcount: c_int = 0,
    serverURIs: ?[*][*:0]const u8 = null,
    MqttVersion: MQTTVersion = .v5,
    automaticReconnect: c_int = 0,
    minRetryInterval: c_int = 1,
    maxRetryInterval: c_int = 60,
    binarypw: extern struct {
        len: c_int = 0, // binary password length
        data: ?*const anyopaque = null, // binary password data
    } = .{},
    cleanstart: c_int = 1,
    connectProperties: ?*MqttProperties = null,
    willProperties: ?*MqttProperties = null,
    onSuccess5: ?*const OnSuccess5CB = null,
    onFailure5: ?*const OnFailure5CB = null,
    httpHeaders: ?*const NameValue = null,
    httpProxy: ?*[*:0]const u8 = null,
    httpsProxy: ?*[*:0]const u8 = null,
};

pub const OnFailureCB = fn (context: ?*anyopaque, response: *FailureData) callconv(.C) void;
pub const FailureData = extern struct {
    token: AsyncToken = @enumFromInt(0),
    code: c_int = 0,
    message: ?[*:0]const u8 = null,
};

pub const OnFailure5CB = fn (context: ?*anyopaque, response: *FailureData5) callconv(.C) void;
pub const FailureData5 = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'F', 'D' },
    struct_version: c_int = 0,
    token: AsyncToken = @enumFromInt(0),
    reasonCode: MqttReasonCode = @enumFromInt(0),
    properties: MqttProperties = .{},
    code: c_int = 0,
    message: ?[*:0]const u8 = null,
    packet_type: c_int = 0,
};

pub const OnSuccessCB = fn (context: ?*anyopaque, response: *SuccessData) callconv(.C) void;
pub const SuccessData = extern struct {
    token: AsyncToken,
    alt: extern union {
        qos: QoS,
        qosList: [*]QoS,
        @"pub": extern struct {
            message: MqttMessage,
            destinationName: [*:0]u8,
        },
        connect: extern struct {
            serverURI: [*:0]u8,
            mqttVersion: MQTTVersion,
            sessionPresent: c_int,
        },
    },
};

pub const OnSuccess5CB = fn (context: ?*anyopaque, response: *SuccessData5) callconv(.C) void;
pub const SuccessData5 = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'S', 'D' },
    struct_version: c_int = 0,
    token: AsyncToken = @enumFromInt(0),
    reasonCode: MqttReasonCode = @enumFromInt(0),
    properties: MqttProperties = .{},
    alt: extern union { sub: extern struct {
        reasonCodeCount: c_int,
        reasonCodes: ?[*]MqttReasonCode,
    }, @"pub": extern struct {
        message: MqttMessage,
        destinationName: ?[*:0]u8,
    }, connect: extern struct {
        serverURI: [*:0]u8,
        mqttVersion: MQTTVersion,
        sessionPresent: c_int,
    }, unsub: extern struct {
        reasonCodeCount: c_int,
        reasonCodes: ?[*]MqttReasonCode,
    } } = .{ .sub = .{ .reasonCodeCount = 0, .reasonCodes = null } },
};

// synonym for ResponseOptions
pub const ResponseOptions = CallOptions;
pub const CallOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'R' },
    struct_version: c_int = 1,
    onSuccess: ?*const OnSuccessCB = null,
    onFailure: ?*const OnFailureCB = null,
    context: ?*anyopaque = null,
    token: AsyncToken = @enumFromInt(0),
    onSuccess5: ?*const OnSuccess5CB = null,
    onFailure5: ?*const OnFailure5CB = null,
    properties: MqttProperties = .{},
    subscribeOptions: SubscribeOptions = .{},
    subscribeOptionsCount: c_int = 0,
    subscribeOptionsList: ?[*]SubscribeOptions = null,
};

pub const SubscribeOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'S', 'O' },
    struct_version: c_int = 0,
    noLocal: u8 = 0,
    retainAsPublished: u8 = 0,
    retainHandling: u8 = 0,
};

pub const DisconnectOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'D' },
    struct_version: c_int = 1,
    timeout: c_int = 0,
    onSuccess: ?*const OnSuccessCB = null,
    onFailure: ?*const OnFailureCB = null,
    context: ?*anyopaque = null,
    properties: MqttProperties = .{},
    reasonCode: MqttReasonCode = @enumFromInt(0),
    onSuccess5: ?*const OnSuccess5CB = null,
    onFailure5: ?*const OnFailure5CB = null,
};

pub const TraceLevel = enum(c_int) {
    Maximum = 1,
    Medium,
    Minimum,
    Protocol,
    Error,
    Severe,
    Fatal,
};

extern fn MQTTAsync_global_init(inits: *InitOptions) callconv(.C) void;

extern fn MQTTAsync_create(handle: *Handle, serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque) callconv(.C) c_int;
extern fn MQTTAsync_createWithOptions(handle: *Handle, serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque, options: *CreateOptions) callconv(.C) c_int;
extern fn MQTTAsync_destroy(handle: *Handle) callconv(.C) void;

extern fn MQTTAsync_connect(handle: Handle, options: *ConnectOptions) callconv(.C) c_int;
extern fn MQTTAsync_disconnect(handle: Handle, options: *const DisconnectOptions) callconv(.C) c_int;
extern fn MQTTAsync_isConnected(handle: Handle) callconv(.C) c_int;

pub const ConnectionLostCB = fn (context: ?*anyopaque, cause: ?[*:0]u8) callconv(.C) void;
pub const MessageArrivedCB = fn (context: ?*anyopaque, topicName: [*:0]u8, topicLen: c_int, message: *MqttMessage) callconv(.C) c_int;
pub const DeliveryCompleteCB = fn (context: ?*anyopaque, tok: AsyncToken) callconv(.C) void;
extern fn MQTTAsync_setCallbacks(handle: Handle, context: ?*anyopaque, cl: ?*const ConnectionLostCB, ma: *const MessageArrivedCB, dc: ?*const DeliveryCompleteCB) callconv(.C) c_int;

pub const ConnectedCB = fn (context: ?*anyopaque, cause: ?[*:0]u8) callconv(.C) void;
extern fn MQTTAsync_setConnected(handle: Handle, context: ?*anyopaque, co: *const ConnectedCB) callconv(.C) c_int;

pub const DisconnectedCB = fn (context: ?*anyopaque, properties: *MqttProperties, reasonCode: MqttReasonCode) callconv(.C) void;
extern fn MQTTAsync_setDisconnected(handle: Handle, context: ?*anyopaque, co: *const DisconnectedCB) callconv(.C) c_int;

extern fn MQTTAsync_waitForCompletion(handle: Handle, dt: AsyncToken, timeout: c_ulong) callconv(.C) c_int;
extern fn MQTTAsync_sendMessage(handle: Handle, destinationName: [*:0]const u8, msg: *const MqttMessage, response: *CallOptions) callconv(.C) c_int;
extern fn MQTTAsync_subscribe(handle: Handle, topic: [*:0]const u8, qos: QoS, response: *ResponseOptions) callconv(.C) c_int;
extern fn MQTTAsync_subscribeMany(handle: Handle, count: c_int, topic: [*][*:0]const u8, qos: [*]const QoS, response: *ResponseOptions) callconv(.C) c_int;
extern fn MQTTAsync_unsubscribe(handle: Handle, topic: [*:0]const u8, response: *ResponseOptions) callconv(.C) c_int;
extern fn MQTTAsync_unsubscribeMany(handle: Handle, count: c_int, topic: [*][*:0]const u8, response: *ResponseOptions) callconv(.C) c_int;

extern fn MQTTAsync_getPendingTokens(handle: Handle, tokens: *?[*]AsyncToken) callconv(.C) c_int;

extern fn MQTTAsync_freeMessage(msg: **MqttMessage) callconv(.C) void;
extern fn MQTTAsync_free(ptr: *anyopaque) callconv(.C) void;

extern fn MQTTAsync_setTraceLevel(level: TraceLevel) callconv(.C) void;
const TraceCallback = fn (level: TraceLevel, message: [*:0]u8) callconv(.C) void;
extern fn MQTTAsync_setTraceCallback(callback: *const TraceCallback) callconv(.C) void;

pub fn errno(rc: c_int) LibError!void {
    return switch (rc) {
        0 => {},
        -1 => error.Failure,
        -2 => error.Persistance,
        -3 => error.Disconnected,
        -4 => error.MaxMsgInflight,
        -5 => error.BadUTF8Str,
        -6 => error.NullParam,
        -7 => error.TopicNameTruncated,
        -8 => error.BadStructure,
        -9 => error.BadQoS,
        -10 => error.NoMoreMsgIDs,
        -11 => error.OperationIncomplete,
        -12 => error.MaxBufferedMessages,
        -13 => error.SSLNotSupported,
        -14 => error.BadProtocol,
        -15 => error.BadMqttOption,
        -16 => error.WrongMqttVersion,
        -17 => error.ZeroLenWillTopic,
        -18 => error.CommandIgnored,
        -19 => error.InvalidMaxBuffered,
        else => {
            if (std.debug.runtime_safety) {
                std.debug.print("unexpected errno: {d}\n", .{rc});
                std.debug.dumpCurrentStackTrace(null);
            }
            return error.Failure;
        },
    };
}

pub fn globalInit(init_opt: *InitOptions) void {
    MQTTAsync_global_init(init_opt);
}

pub fn create(serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque) LibError!Self {
    var handle: Handle = undefined;
    try errno(MQTTAsync_create(&handle, serverURI, clientId, persistence_type, persistence_context));
    return .{ .handle = handle };
}

pub fn createWithOptions(serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque, options: *CreateOptions) LibError!Self {
    var handle: Handle = undefined;
    try errno(MQTTAsync_createWithOptions(&handle, serverURI, clientId, persistence_type, persistence_context, options));
    return .{ .handle = handle };
}

pub fn destroy(client: *Self) void {
    MQTTAsync_destroy(&client.handle);
    client.handle = undefined;
}

pub fn connect(client: Self, options: *ConnectOptions) Error!void {
    const rc = MQTTAsync_connect(client.handle, options);
    if (rc > 0) return switch (rc) {
        1 => error.UnsupportedProtocolVersion,
        2 => error.ClientIdentifierNotValid,
        3 => error.ServerUnavailable,
        4 => error.BadUserNameOrPassword,
        5 => error.NotAuthorized,
        else => unreachable,
    };
    return errno(rc);
}

pub fn disconnect(client: Self, options: *const DisconnectOptions) LibError!void {
    return errno(MQTTAsync_disconnect(client.handle, options));
}

pub fn isConnected(client: Self) bool {
    return MQTTAsync_isConnected(client.handle) != 0;
}

pub fn setCallbacks(client: Self, context: ?*anyopaque, cl: ?*const ConnectionLostCB, ma: *const MessageArrivedCB, dc: ?*const DeliveryCompleteCB) LibError!void {
    return errno(MQTTAsync_setCallbacks(client.handle, context, cl, ma, dc));
}

pub fn setConnected(client: Self, context: ?*anyopaque, co: *const ConnectedCB) LibError!void {
    return errno(MQTTAsync_setConnected(client.handle, context, co));
}

pub fn setDisconnected(client: Self, context: ?*anyopaque, co: *const DisconnectedCB) LibError!void {
    return errno(MQTTAsync_setDisconnected(client.handle, context, co));
}

pub fn waitForCompletion(client: Self, dt: AsyncToken, timeout: c_ulong) LibError!void {
    return errno(MQTTAsync_waitForCompletion(client.handle, dt, timeout));
}

pub fn sendMessage(client: Self, destinationName: [*:0]const u8, msg: *const MqttMessage, response: *CallOptions) LibError!void {
    return errno(MQTTAsync_sendMessage(client.handle, destinationName, msg, response));
}

pub fn subscribe(client: Self, topic: [*:0]const u8, qos: QoS, response: *ResponseOptions) LibError!void {
    return errno(MQTTAsync_subscribe(client.handle, topic, qos, response));
}

pub fn subscribeMany(client: Self, count: c_int, topic: [*][*:0]const u8, qos: [*]const QoS, response: *ResponseOptions) LibError!void {
    return errno(MQTTAsync_subscribeMany(client.handle, count, topic, qos, response));
}

pub fn unsubscribe(client: Self, topic: [*:0]const u8, response: *ResponseOptions) LibError!void {
    return errno(MQTTAsync_unsubscribe(client.handle, topic, response));
}

pub fn unsubscribeMany(client: Self, count: c_int, topic: [*][*:0]const u8, response: *ResponseOptions) LibError!void {
    return errno(MQTTAsync_unsubscribeMany(client.handle, count, topic, response));
}

pub fn getPendingTokens(client: Self, tokens: *?[*]AsyncToken) LibError!void {
    return errno(MQTTAsync_getPendingTokens(client.handle, tokens));
}

pub fn freeMessage(msg: **MqttMessage) void {
    MQTTAsync_freeMessage(msg);
}

pub fn free(ptr: *anyopaque) void {
    MQTTAsync_free(ptr);
}

pub fn setTraceLevel(level: TraceLevel) void {
    MQTTAsync_setTraceLevel(level);
}

pub fn setTraceCallback(callback: *const TraceCallback) void {
    MQTTAsync_setTraceCallback(callback);
}
