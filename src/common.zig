// https://github.com/eclipse/paho.mqtt.c/blob/master/src/MQTTClient.h
// https://github.com/eclipse/paho.mqtt.c/blob/6b1e202a701ffcdaa277b5644ed291287a70a7aa/src/MQTTClientPersistence.h#L69
// The MQTTClient API is not thread safe, whereas the MQTTAsync API is.

const config = @import("config");
pub const MqttClient = if (config.mode == .sync) @import("MqttClient.zig")
    else @compileError("Async client was selected at build time");
pub const MqttAsync = if (config.mode == .@"async") @import("MqttAsync.zig")
    else @compileError("Sync client was selected at build time");

pub const MQTTVersion = enum(c_int) {
    default = 0,
    v3_1 = 3,
    v3_1_1 = 4,
    v5 = 5,
};

pub const QoS = enum(c_int) {
    // message may not be delivered
    FireAndForget = 0,
    // message will be delivered, but may be delivered more than once in some circumstances
    AtLeastOnce = 1,
    // message will be delivered exactly once
    OnceAndOneOnly = 2,
};

pub const Persistence = enum(c_int) {
    Default = 0, // file system-based persistence mechanism
    None = 1, // memory-based persistence mechanism
    User = 2, // application-specific persistence mechanism
};

const PropertyCode = enum(c_int) {
    PAYLOAD_FORMAT_INDICATOR = 1,
    MESSAGE_EXPIRY_INTERVAL = 2,
    CONTENT_TYPE = 3,
    RESPONSE_TOPIC = 8,
    CORRELATION_DATA = 9,
    SUBSCRIPTION_IDENTIFIER = 11,
    SESSION_EXPIRY_INTERVAL = 17,
    ASSIGNED_CLIENT_IDENTIFER = 18,
    SERVER_KEEP_ALIVE = 19,
    AUTHENTICATION_METHOD = 21,
    AUTHENTICATION_DATA = 22,
    REQUEST_PROBLEM_INFORMATION = 23,
    WILL_DELAY_INTERVAL = 24,
    REQUEST_RESPONSE_INFORMATION = 25,
    RESPONSE_INFORMATION = 26,
    SERVER_REFERENCE = 28,
    REASON_STRING = 31,
    RECEIVE_MAXIMUM = 33,
    TOPIC_ALIAS_MAXIMUM = 34,
    TOPIC_ALIAS = 35,
    MAXIMUM_QOS = 36,
    RETAIN_AVAILABLE = 37,
    USER_PROPERTY = 38,
    MAXIMUM_PACKET_SIZE = 39,
    WILDCARD_SUBSCRIPTION_AVAILABLE = 40,
    SUBSCRIPTION_IDENTIFIERS_AVAILABLE = 41,
    SHARED_SUBSCRIPTION_AVAILABLE = 42, // value is 241
};

pub const WillOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'W' },
    struct_version: c_int = 1,
    topicName: ?[*:0]u8 = null,
    message: ?[*:0]u8 = null,
    retained: c_int = 0,
    qos: QoS = .FireAndForget,
    payload: extern struct {
        len: c_int = 0, // binary payload length
        data: ?*const anyopaque = null, // binary payload data
    } = .{},
};

pub const NameValue = extern struct {
    name: [*:0]const u8,
    value: [*:0]const u8,
};

pub const MQTTLenString = extern struct {
    len: c_int,
    data: [*:0]u8,
};

pub const MqttProperty = extern struct {
    identifier: PropertyCode,
    value: extern union {
        byte: c_char,
        integer2: c_ushort,
        integer4: c_uint,
        str: extern struct {
            data: MQTTLenString,
            value: MQTTLenString,
        },
    },
};

pub const MqttProperties = extern struct {
    count: c_int = 0,
    max_count: c_int = 0,
    length: c_int = 0,
    array: ?*MqttProperty = null,
};

pub const MqttResponse = extern struct {
    version: c_int = 1,
    reasonCode: MqttReasonCode = .SUCCESS,
    reasonCodeCount: c_int = 0,
    reasonCodes: ?*MqttReasonCode = null,
    properties: ?*MqttProperties = null,

    extern fn MQTTResponse_free(response: MqttResponse) callconv(.C) void;

    pub fn free(response: MqttResponse) void {
        MQTTResponse_free(response);
    }
};

pub const MqttMessage = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'M' },
    struct_version: c_int = 1,
    payloadlen: c_int,
    payload: *anyopaque,
    qos: QoS = .FireAndForget,
    retained: c_int = 0,
    dup: c_int = 0,
    msgid: c_int = 0,
    properties: MqttProperties = .{},
};

pub const InitOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'G' },
    struct_version: c_int = 0,
    // 1 = we do openssl init, 0 = leave it to the application
    do_openssl_init: c_int,
};

pub const SslVersion = enum(c_int) {
    Default = 0,
    TLS_1_0 = 1,
    TLS_1_1 = 2,
    TLS_1_2 = 3,
};

pub const SslOptions = extern struct {
    struct_id: [4]c_char = .{ 'M', 'Q', 'T', 'S' },
    struct_version: c_int = 5,
    trustStore: ?[*:0]const u8 = null,
    keyStore: ?[*:0]const u8 = null,
    privateKey: ?[*:0]const u8 = null,
    privateKeyPassword: ?[*:0]const u8 = null,
    enabledCipherSuites: ?[*:0]const u8 = null,
    enableServerCertAuth: c_int = 1,
    sslVersion: SslVersion = .Default,
    verify: c_int = 0,
    CApath: ?[*:0]const u8 = null,
    ssl_error_cb: ?*const fn (str: [*:0]const u8, len: usize, u: *anyopaque) callconv(.C) c_int = null,
    ssl_error_context: ?*anyopaque = null,
    ssl_psk_cb: ?*const fn (hint: [*:0]const u8, identity: [*:0]u8, max_identity_len: c_uint, pks: [*:0]const u8, max_psk_len: c_uint, u: ?*anyopaque) callconv(.C) c_uint = null,
    ssl_psk_context: ?*anyopaque = null,
    disableDefaultTrustStore: c_int = 0,
    protos: ?[*]const u8 = null,
    protos_len: c_uint = 0,
};

pub const LibError = error{
    // A generic error code indicating the failure of an MQTT client operation
    Failure,
    // Application-specific persistence functions must return this error code
    // if there is a problem executing the function
    Persistance,
    // The client is disconnected
    Disconnected,
    // The maximum number of messages allowed to be simultaneously in-flight
    // has been reached
    MaxMsgInflight,
    // An invalid UTF-8 string has been detected
    BadUTF8Str,
    // A NULL parameter has been supplied when this is invalid
    NullParam,
    // The topic has been truncated (the topic string includes embedded NULL
    // characters). String functions will not access the full topic. Use the
    // topic length value to access the full topic.
    TopicNameTruncated,
    // A structure parameter does not have the correct eyecatcher and version number
    BadStructure,
    // A QoS value that falls outside of the acceptable range (0,1,2)
    BadQoS,
    // Attempting SSL connection using non-SSL version of library
    SSLNotSupported,
    // unrecognized MQTT version
    BadMqttVersion,
    // protocol prefix in serverURI should be:
    //   - `tcp://` or `mqtt://` - Insecure TCP
    //   - `ssl://` or `mqtts://` - Encrypted SSL/TLS
    //   - `ws://` - Insecure websockets
    //   - `wss://` - Secure web sockets
    // The TLS enabled prefixes (ssl, mqtts, wss) are only valid if a TLS
    // version of the library is linked with
    BadProtocol,
    // option not applicable to the requested version of MQTT
    BadMqttOption,
    // call not applicable to the requested version of MQTT
    WrongMqttVersion,
    // 0 length will topic on connect
    ZeroLenWillTopic,
};

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
        -10 => error.SSLNotSupported,
        -11 => error.BadMqttVersion,
        -14 => error.BadProtocol,
        -15 => error.BadMqttOption,
        -16 => error.WrongMqttVersion,
        -17 => error.ZeroLenWillTopic,
        else => {
            if (std.debug.runtime_safety) {
                std.debug.print("unexpected errno: {d}\n", .{rc});
                std.debug.dumpCurrentStackTrace(null);
            }
            return error.Failure;
        },
    };
}

pub const MqttReasonCode = enum(c_int) {
    _,
};

pub const SuccessReason = enum {
    Success, // alias: NORMAL_DISCONNECTION, GRANTED_QOS_0
    GrantedQoS1,
    GrantedQoS2,
    DisconnectWithWillMsg,
};

pub const ProtocolError = error{
    NoMatchingSubscribers,
    NoSubscriptionFound,
    ContinueAuthentication,
    ReAuthenticate,
    UnspecifiedError,
    MalformedPacket,
    ProtocolError,
    ImplementationSpecificError,
    UnsupportedProtocolVersion,
    ClientIdentifierNotValid,
    BadUserNameOrPassword,
    NotAuthorized,
    ServerUnavailable,
    ServerBusy,
    Banned,
    ServerShuttingDown,
    BadAuthenticationMethod,
    KeepAliveTimeout,
    SessionTakenOver,
    TopicFilterInvalid,
    TopicNameInvalid,
    PacketIdentifierInUse,
    PacketIdentifierNotFound,
    ReceiveMaximumExceeded,
    TopicAliasInvalid,
    PacketTooLarge,
    MessageRateTooHigh,
    QuotaExceeded,
    AdministrativeAction,
    PayloadFormatInvalid,
    RetainNotSupported,
    QoSNotSupported,
    UseAnotherServer,
    ServerMoved,
    SharedSubscriptionsNotSupported,
    ConnectionRateExceeded,
    MaximumConnectTime,
    SubscriptionIdentifiersNotSupported,
    WildcardSubscriptionNotSupported,
};

pub const Error = LibError || ProtocolError;
pub fn reason(code: MqttReasonCode) Error!SuccessReason {
    const rc = @intFromEnum(code);
    if (rc == 0) return .Success;

    // error codes smaller than 0 are library errors
    if (rc < 0) {
        try errno(rc);
        unreachable;
    }

    // error codes larger than 0 are protocol errors
    return switch (rc) {
        1 => .GrantedQoS1,
        2 => .GrantedQoS2,
        4 => .DisconnectWithWillMsg,
        16 => error.NoMatchingSubscribers,
        17 => error.NoSubscriptionFound,
        24 => error.ContinueAuthentication,
        25 => error.ReAuthenticate,
        128 => error.UnspecifiedError,
        129 => error.MalformedPacket,
        130 => error.ProtocolError,
        131 => error.ImplementationSpecificError,
        132 => error.UnsupportedProtocolVersion,
        133 => error.ClientIdentifierNotValid,
        134 => error.BadUserNameOrPassword,
        135 => error.NotAuthorized,
        136 => error.ServerUnavailable,
        137 => error.ServerBusy,
        138 => error.Banned,
        139 => error.ServerShuttingDown,
        140 => error.BadAuthenticationMethod,
        141 => error.KeepAliveTimeout,
        142 => error.SessionTakenOver,
        143 => error.TopicFilterInvalid,
        144 => error.TopicNameInvalid,
        145 => error.PacketIdentifierInUse,
        146 => error.PacketIdentifierNotFound,
        147 => error.ReceiveMaximumExceeded,
        148 => error.TopicAliasInvalid,
        149 => error.PacketTooLarge,
        150 => error.MessageRateTooHigh,
        151 => error.QuotaExceeded,
        152 => error.AdministrativeAction,
        153 => error.PayloadFormatInvalid,
        154 => error.RetainNotSupported,
        155 => error.QoSNotSupported,
        156 => error.UseAnotherServer,
        157 => error.ServerMoved,
        158 => error.SharedSubscriptionsNotSupported,
        159 => error.ConnectionRateExceeded,
        160 => error.MaximumConnectTime,
        161 => error.SubscriptionIdentifiersNotSupported,
        162 => error.WildcardSubscriptionNotSupported,
        else => {
            if (std.debug.runtime_safety) {
                std.debug.print("unexpected failure reason: {d}\n", .{rc});
                std.debug.dumpCurrentStackTrace(null);
            }
            return error.Failure;
        },
    };
}
