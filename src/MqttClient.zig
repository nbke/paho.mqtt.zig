const common = @import("common.zig");
const errno = common.errno;
const InitOptions = common.InitOptions;
const LibError = common.LibError;
const MqttMessage = common.MqttMessage;
const MqttProperties = common.MqttProperties;
const MqttResponse = common.MqttResponse;
const MQTTVersion = common.MQTTVersion;
const NameValue = common.NameValue;
const Persistence = common.Persistence;
const SslOptions = common.SslOptions;
const WillOptions = common.WillOptions;
const Self = @This();

const Handle = *anyopaque;
handle: Handle,

pub const DeliveryToken = enum(c_int) {
    _,
};

pub const CreateOptions = extern struct {
    // The eyecatcher for this structure.  must be MQCO.
    struct_id: [4]c_char = .{ 'M', 'Q', 'C', 'O' },
    // The version number of this structure.  Must be 0
    struct_version: c_int = 0,
    // Whether the MQTT version is 3.1, 3.1.1, or 5.  To use V5, this must be set.
    // MQTT V5 has to be chosen here, because during the create call the message persistence
    // is initialized, and we want to know whether the format of any persisted messages
    // is appropriate for the MQTT version we are going to connect with.  Selecting 3.1 or
    // 3.1.1 and attempting to read 5.0 persisted messages will result in an error on create.
    MQTTVersion: MQTTVersion,
};

pub const ConnectOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'C' },
    struct_version: c_int = 8,
    keepAliveInterval: c_int = 60,
    cleansession: c_int = 0,
    reliable: c_int = 1,
    will: ?*WillOptions = null,
    username: ?[*:0]u8 = null,
    password: ?[*:0]u8 = null,
    connectTimeout: c_int = 30,
    retryInterval: c_int = 0,
    ssl: ?*SslOptions = null,
    serverURIcount: c_int = 0,
    serverURIs: ?[*][*:0]const u8 = null,
    MqttVersion: MQTTVersion = .v5,
    returned: extern struct {
        serverURI: ?[*:0]const u8 = null, // the serverURI connected to */
        MQTTVersion: c_int = 0, // the MQTT version used to connect with */
        sessionPresent: c_int = 0, // if the MQTT version is 3.1.1, the value of sessionPresent returned in the connack */
    } = .{},
    binarypw: extern struct {
        len: c_int = 0, // binary password length
        data: ?*const anyopaque = null, // binary password data
    } = .{},
    maxInflightMessages: c_int = -1,
    cleanstart: c_int = 1,
    httpHeaders: ?*const NameValue = null,
    httpProxy: ?*[*:0]const u8 = null,
    httpsProxy: ?*[*:0]const u8 = null,
};

extern fn MQTTClient_global_init(init_opt: *InitOptions) callconv(.C) void;

extern fn MQTTClient_create(handle: *Handle, serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque) callconv(.C) c_int;
extern fn MQTTClient_createWithOptions(handle: *Handle, serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque, options: *CreateOptions) callconv(.C) c_int;
extern fn MQTTClient_destroy(handle: *Handle) callconv(.C) void;

extern fn MQTTClient_waitForCompletion(handle: Handle, dt: DeliveryToken, timeout: c_ulong) callconv(.C) c_int;

extern fn MQTTClient_connect(handle: Handle, options: *ConnectOptions) callconv(.C) c_int;
extern fn MQTTClient_connect5(handle: Handle, options: *ConnectOptions, connectProperties: ?*MqttProperties, willProperties: ?*MqttProperties) callconv(.C) MqttResponse;
extern fn MQTTClient_disconnect(handle: Handle, timeout: c_int) callconv(.C) c_int;

extern fn MQTTClient_publishMessage5(handle: Handle, topicName: [*:0]const u8, msg: *MqttMessage, dt: *DeliveryToken) callconv(.C) MqttResponse;

pub const ConnectionLostCB = fn (context: ?*anyopaque, cause: ?[*:0]u8) callconv(.C) void;
pub const MessageArrivedCB = fn (context: ?*anyopaque, topicName: [*:0]u8, topicLen: c_int, message: *MqttMessage) callconv(.C) c_int;
pub const DeliveryCompleteCB = fn (context: ?*anyopaque, dt: DeliveryToken) callconv(.C) void;
extern fn MQTTClient_setCallbacks(handle: Handle, context: ?*anyopaque, cl: ?*const ConnectionLostCB, ma: *const MessageArrivedCB, dc: ?*const DeliveryCompleteCB) callconv(.C) c_int;

extern fn MQTTClient_freeMessage(msg: **MqttMessage) callconv(.C) void;
extern fn MQTTClient_free(ptr: *anyopaque) callconv(.C) void;

pub fn globalInit(init_opt: *InitOptions) void {
    MQTTClient_global_init(init_opt);
}

pub fn create(serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque) LibError!Self {
    var handle: Handle = undefined;
    try errno(MQTTClient_create(&handle, serverURI, clientId, persistence_type, persistence_context));
    return .{ .handle = handle };
}

pub fn createWithOptions(serverURI: [*:0]const u8, clientId: [*:0]const u8, persistence_type: Persistence, persistence_context: ?*anyopaque, options: *CreateOptions) LibError!Self {
    var handle: Handle = undefined;
    try errno(MQTTClient_createWithOptions(&handle, serverURI, clientId, persistence_type, persistence_context, options));
    return .{ .handle = handle };
}

pub fn destroy(client: *Self) void {
    MQTTClient_destroy(&client.handle);
    client.handle = undefined;
}

pub fn waitForCompletion(client: Self, dt: DeliveryToken, timeout: c_ulong) LibError!void {
    return errno(MQTTClient_waitForCompletion(client.handle, dt, timeout));
}

pub fn connect(client: Self, options: *ConnectOptions) LibError!void {
    return errno(MQTTClient_connect(client.handle, options));
}

pub fn connect5(client: Self, options: *ConnectOptions, connectProperties: ?*MqttProperties, willProperties: ?*MqttProperties) MqttResponse {
    return MQTTClient_connect5(client.handle, options, connectProperties, willProperties);
}

pub fn disconnect(client: Self, timeout: c_int) LibError!void {
    return errno(MQTTClient_disconnect(client.handle, timeout));
}

pub fn publishMessage5(client: Self, topicName: [*:0]const u8, msg: *MqttMessage, dt: *DeliveryToken) MqttResponse {
    return MQTTClient_publishMessage5(client.handle, topicName, msg, dt);
}

pub fn setCallbacks(client: Self, context: ?*anyopaque, cl: ?*const ConnectionLostCB, ma: *const MessageArrivedCB, dc: ?*const DeliveryCompleteCB) LibError!void {
    return errno(MQTTClient_setCallbacks(client.handle, context, cl, ma, dc));
}

pub fn freeMessage(msg: **MqttMessage) void {
    MQTTClient_freeMessage(msg);
}

pub fn free(ptr: *anyopaque) void {
    MQTTClient_free(ptr);
}
