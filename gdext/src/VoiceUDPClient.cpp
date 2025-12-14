#include "VoiceUDPClient.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <cstring>

namespace godot {

bool VoiceUDPClient::_sockets_initialized = false;

void VoiceUDPClient::_bind_methods() {
    // Connection
    ClassDB::bind_method(D_METHOD("connect_to_server", "ip", "port"), &VoiceUDPClient::connect_to_server);
    ClassDB::bind_method(D_METHOD("disconnect"), &VoiceUDPClient::disconnect);
    ClassDB::bind_method(D_METHOD("is_connected"), &VoiceUDPClient::is_connected);

    // IP Discovery
    ClassDB::bind_method(D_METHOD("perform_ip_discovery", "ssrc"), &VoiceUDPClient::perform_ip_discovery);

    // Configuration
    ClassDB::bind_method(D_METHOD("set_secret_key", "key"), &VoiceUDPClient::set_secret_key);
    ClassDB::bind_method(D_METHOD("set_ssrc", "ssrc"), &VoiceUDPClient::set_ssrc);
    ClassDB::bind_method(D_METHOD("get_ssrc"), &VoiceUDPClient::get_ssrc);

    // Audio
    ClassDB::bind_method(D_METHOD("send_audio_frame", "pcm_data"), &VoiceUDPClient::send_audio_frame);
    ClassDB::bind_method(D_METHOD("send_silence_frames"), &VoiceUDPClient::send_silence_frames);

    // State
    ClassDB::bind_method(D_METHOD("get_sequence"), &VoiceUDPClient::get_sequence);
    ClassDB::bind_method(D_METHOD("get_timestamp"), &VoiceUDPClient::get_timestamp);
}

VoiceUDPClient::VoiceUDPClient() {
    if (!_sockets_initialized) {
        init_sockets();
    }

    // Initialize libsodium
    if (sodium_init() < 0) {
        ERR_PRINT("VoiceUDPClient: Failed to initialize libsodium");
    }
}

VoiceUDPClient::~VoiceUDPClient() {
    disconnect();
    cleanup_opus_encoder();
}

bool VoiceUDPClient::init_sockets() {
#ifdef _WIN32
    WSADATA wsa_data;
    if (WSAStartup(MAKEWORD(2, 2), &wsa_data) != 0) {
        ERR_PRINT("VoiceUDPClient: Failed to initialize Winsock");
        return false;
    }
#endif
    _sockets_initialized = true;
    return true;
}

void VoiceUDPClient::cleanup_sockets() {
#ifdef _WIN32
    WSACleanup();
#endif
    _sockets_initialized = false;
}

Error VoiceUDPClient::connect_to_server(const String &ip, int port) {
    if (_connected) {
        disconnect();
    }

    // Create UDP socket
    _socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (_socket == SOCKET_INVALID) {
        ERR_PRINT("VoiceUDPClient: Failed to create UDP socket");
        return ERR_CANT_CREATE;
    }

    // Set up server address
    std::memset(&_server_addr, 0, sizeof(_server_addr));
    _server_addr.sin_family = AF_INET;
    _server_addr.sin_port = htons(static_cast<uint16_t>(port));

    CharString ip_utf8 = ip.utf8();
    if (inet_pton(AF_INET, ip_utf8.get_data(), &_server_addr.sin_addr) <= 0) {
        ERR_PRINT("VoiceUDPClient: Invalid IP address: " + ip);
        CLOSE_SOCKET(_socket);
        _socket = SOCKET_INVALID;
        return ERR_INVALID_PARAMETER;
    }

    // Initialize Opus encoder
    if (!init_opus_encoder()) {
        ERR_PRINT("VoiceUDPClient: Failed to initialize Opus encoder");
        CLOSE_SOCKET(_socket);
        _socket = SOCKET_INVALID;
        return ERR_CANT_CREATE;
    }

    _connected = true;
    _sequence = 0;
    _timestamp = 0;

    UtilityFunctions::print("VoiceUDPClient: Connected to ", ip, ":", port);
    return OK;
}

void VoiceUDPClient::disconnect() {
    _connected = false;

    if (_socket != SOCKET_INVALID) {
        CLOSE_SOCKET(_socket);
        _socket = SOCKET_INVALID;
    }

    cleanup_opus_encoder();
}

bool VoiceUDPClient::is_connected() const {
    return _connected;
}

Dictionary VoiceUDPClient::perform_ip_discovery(int ssrc) {
    Dictionary result;

    if (!_connected || _socket == SOCKET_INVALID) {
        ERR_PRINT("VoiceUDPClient: Not connected");
        return result;
    }

    // Build IP discovery request packet (74 bytes)
    // Type: 0x0001 (request)
    // Length: 70 (always)
    // SSRC: 4 bytes
    // Rest: padding
    std::vector<uint8_t> request(74, 0);

    // Type (big endian): 0x0001
    request[0] = 0x00;
    request[1] = 0x01;

    // Length (big endian): 70
    request[2] = 0x00;
    request[3] = 0x46; // 70

    // SSRC (big endian)
    request[4] = (ssrc >> 24) & 0xFF;
    request[5] = (ssrc >> 16) & 0xFF;
    request[6] = (ssrc >> 8) & 0xFF;
    request[7] = ssrc & 0xFF;

    // Send request
    ssize_t sent = sendto(_socket, reinterpret_cast<const char *>(request.data()),
                          request.size(), 0,
                          reinterpret_cast<struct sockaddr *>(&_server_addr),
                          sizeof(_server_addr));

    if (sent < 0) {
        ERR_PRINT("VoiceUDPClient: Failed to send IP discovery request");
        return result;
    }

    // Receive response
    std::vector<uint8_t> response(74, 0);
    struct sockaddr_in from_addr;
    socklen_t from_len = sizeof(from_addr);

    // Set receive timeout (1 second - keep short to not block main thread)
    struct timeval tv;
    tv.tv_sec = 1;
    tv.tv_usec = 0;
    setsockopt(_socket, SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char *>(&tv), sizeof(tv));

    ssize_t received = recvfrom(_socket, reinterpret_cast<char *>(response.data()),
                                response.size(), 0,
                                reinterpret_cast<struct sockaddr *>(&from_addr),
                                &from_len);

    if (received < 74) {
        ERR_PRINT("VoiceUDPClient: Failed to receive IP discovery response");
        return result;
    }

    // Verify response type (0x0002)
    if (response[0] != 0x00 || response[1] != 0x02) {
        ERR_PRINT("VoiceUDPClient: Invalid IP discovery response type");
        return result;
    }

    // Extract IP address (starts at byte 8, null-terminated string, max 64 bytes)
    std::string ip_str;
    for (int i = 8; i < 72; ++i) {
        if (response[i] == 0) break;
        ip_str += static_cast<char>(response[i]);
    }

    // Extract port (last 2 bytes, big endian)
    uint16_t port = (static_cast<uint16_t>(response[72]) << 8) | response[73];

    result["ip"] = String(ip_str.c_str());
    result["port"] = static_cast<int>(port);

    UtilityFunctions::print("VoiceUDPClient: IP Discovery result - IP: ", ip_str.c_str(), ", Port: ", port);

    return result;
}

void VoiceUDPClient::set_secret_key(const PackedByteArray &key) {
    std::lock_guard<std::mutex> lock(_key_mutex);
    _secret_key.resize(key.size());
    std::memcpy(_secret_key.data(), key.ptr(), key.size());
    UtilityFunctions::print("VoiceUDPClient: Secret key set, length: ", key.size());
}

void VoiceUDPClient::set_ssrc(int ssrc) {
    _ssrc = ssrc;
}

int VoiceUDPClient::get_ssrc() const {
    return _ssrc;
}

bool VoiceUDPClient::init_opus_encoder() {
    std::lock_guard<std::mutex> lock(_encoder_mutex);

    if (_encoder) {
        opus_encoder_destroy(_encoder);
        _encoder = nullptr;
    }

    int error = 0;
    _encoder = opus_encoder_create(SAMPLE_RATE, CHANNELS, OPUS_APPLICATION_AUDIO, &error);

    if (error != OPUS_OK || !_encoder) {
        ERR_PRINT("VoiceUDPClient: Failed to create Opus encoder: " + String(opus_strerror(error)));
        return false;
    }

    // Configure encoder
    opus_encoder_ctl(_encoder, OPUS_SET_BITRATE(BITRATE));
    opus_encoder_ctl(_encoder, OPUS_SET_SIGNAL(OPUS_SIGNAL_MUSIC));
    opus_encoder_ctl(_encoder, OPUS_SET_INBAND_FEC(1));
    opus_encoder_ctl(_encoder, OPUS_SET_PACKET_LOSS_PERC(15));

    return true;
}

void VoiceUDPClient::cleanup_opus_encoder() {
    std::lock_guard<std::mutex> lock(_encoder_mutex);

    if (_encoder) {
        opus_encoder_destroy(_encoder);
        _encoder = nullptr;
    }
}

PackedByteArray VoiceUDPClient::build_rtp_header() {
    PackedByteArray header;
    header.resize(12);

    uint8_t *data = header.ptrw();

    // Version (2), Padding (0), Extension (0), CSRC count (0)
    data[0] = 0x80;

    // Marker (0), Payload type (0x78 = 120 for Opus)
    data[1] = 0x78;

    // Sequence (big endian)
    uint16_t seq = _sequence++;
    data[2] = (seq >> 8) & 0xFF;
    data[3] = seq & 0xFF;

    // Timestamp (big endian)
    uint32_t ts = _timestamp.load();
    data[4] = (ts >> 24) & 0xFF;
    data[5] = (ts >> 16) & 0xFF;
    data[6] = (ts >> 8) & 0xFF;
    data[7] = ts & 0xFF;

    // Update timestamp for next frame
    _timestamp += FRAME_SIZE;

    // SSRC (big endian)
    uint32_t ssrc = static_cast<uint32_t>(_ssrc.load());
    data[8] = (ssrc >> 24) & 0xFF;
    data[9] = (ssrc >> 16) & 0xFF;
    data[10] = (ssrc >> 8) & 0xFF;
    data[11] = ssrc & 0xFF;

    return header;
}

PackedByteArray VoiceUDPClient::encrypt_audio(const PackedByteArray &rtp_header, const std::vector<uint8_t> &opus_data) {
    std::lock_guard<std::mutex> lock(_key_mutex);

    // Key size for XChaCha20-Poly1305 is 32 bytes
    if (_secret_key.size() != crypto_aead_xchacha20poly1305_ietf_KEYBYTES) {
        ERR_PRINT("VoiceUDPClient: Invalid secret key size. Expected 32, got " + String::num_int64(_secret_key.size()));
        return PackedByteArray();
    }

    // For aead_xchacha20_poly1305_rtpsize:
    // - Nonce is a 32-bit incremental integer
    // - This 4-byte nonce is appended to the packet
    // - For encryption, pad it to 24 bytes (xchacha20poly1305 nonce size)
    
    // Build the 4-byte nonce (will be appended to packet)
    uint32_t nonce_int = _nonce_counter++;
    uint8_t nonce_bytes[4];
    nonce_bytes[0] = (nonce_int >> 24) & 0xFF;
    nonce_bytes[1] = (nonce_int >> 16) & 0xFF;
    nonce_bytes[2] = (nonce_int >> 8) & 0xFF;
    nonce_bytes[3] = nonce_int & 0xFF;
    
    // Pad to 24 bytes for XChaCha20 (4 bytes nonce + 20 bytes zeros)
    std::vector<uint8_t> nonce(crypto_aead_xchacha20poly1305_ietf_NPUBBYTES, 0);
    std::memcpy(nonce.data(), nonce_bytes, 4);

    // Encrypt using AEAD XChaCha20-Poly1305
    // Ciphertext includes the 16-byte auth tag
    std::vector<uint8_t> ciphertext(opus_data.size() + crypto_aead_xchacha20poly1305_ietf_ABYTES);
    unsigned long long ciphertext_len;

    // Additional authenticated data is the RTP header
    if (crypto_aead_xchacha20poly1305_ietf_encrypt(
            ciphertext.data(), &ciphertext_len,
            opus_data.data(), opus_data.size(),
            rtp_header.ptr(), rtp_header.size(),  // AAD: RTP header
            nullptr,  // nsec (not used)
            nonce.data(),
            _secret_key.data()) != 0) {
        ERR_PRINT("VoiceUDPClient: Encryption failed");
        return PackedByteArray();
    }

    // Build final packet: RTP header + encrypted audio + 4-byte nonce
    // (rtpsize mode appends the 4-byte nonce at the end)
    PackedByteArray packet;
    packet.resize(rtp_header.size() + ciphertext_len + 4);

    uint8_t *packet_data = packet.ptrw();
    std::memcpy(packet_data, rtp_header.ptr(), rtp_header.size());
    std::memcpy(packet_data + rtp_header.size(), ciphertext.data(), ciphertext_len);
    std::memcpy(packet_data + rtp_header.size() + ciphertext_len, nonce_bytes, 4);

    return packet;
}

Error VoiceUDPClient::send_audio_frame(const PackedByteArray &pcm_data) {
    if (!_connected || _socket == SOCKET_INVALID) {
        return ERR_CONNECTION_ERROR;
    }

    std::lock_guard<std::mutex> lock(_encoder_mutex);

    if (!_encoder) {
        ERR_PRINT("VoiceUDPClient: Opus encoder not initialized");
        return ERR_UNCONFIGURED;
    }

    // Expected PCM data size: FRAME_SIZE * CHANNELS * sizeof(int16_t)
    const int expected_size = FRAME_SIZE * CHANNELS * 2;
    if (pcm_data.size() != expected_size) {
        ERR_PRINT("VoiceUDPClient: Invalid PCM data size. Expected " + String::num_int64(expected_size) +
                  ", got " + String::num_int64(pcm_data.size()));
        return ERR_INVALID_PARAMETER;
    }

    // Encode to Opus
    std::vector<uint8_t> opus_data(MAX_PACKET_SIZE);
    const opus_int16 *pcm_ptr = reinterpret_cast<const opus_int16 *>(pcm_data.ptr());

    int opus_len = opus_encode(_encoder, pcm_ptr, FRAME_SIZE,
                               opus_data.data(), static_cast<int>(opus_data.size()));

    if (opus_len < 0) {
        ERR_PRINT("VoiceUDPClient: Opus encoding failed: " + String(opus_strerror(opus_len)));
        return ERR_QUERY_FAILED;
    }

    opus_data.resize(opus_len);

    // Build RTP header
    PackedByteArray rtp_header = build_rtp_header();

    // Encrypt
    PackedByteArray packet = encrypt_audio(rtp_header, opus_data);
    if (packet.size() == 0) {
        return ERR_QUERY_FAILED;
    }

    // Send
    ssize_t sent = sendto(_socket, reinterpret_cast<const char *>(packet.ptr()),
                          packet.size(), 0,
                          reinterpret_cast<struct sockaddr *>(&_server_addr),
                          sizeof(_server_addr));

    if (sent < 0) {
        ERR_PRINT("VoiceUDPClient: Failed to send audio packet");
        return ERR_CONNECTION_ERROR;
    }

    return OK;
}

void VoiceUDPClient::send_silence_frames() {
    // Discord expects 5 frames of silence (0xF8, 0xFF, 0xFE) to indicate end of speaking
    // This is pre-encoded Opus silence

    if (!_connected || _socket == SOCKET_INVALID) {
        return;
    }

    std::lock_guard<std::mutex> lock(_key_mutex);

    if (_secret_key.size() != crypto_secretbox_KEYBYTES) {
        return;
    }

    // Opus silence frame
    const std::vector<uint8_t> silence_opus = {0xF8, 0xFF, 0xFE};

    for (int i = 0; i < 5; ++i) {
        PackedByteArray rtp_header = build_rtp_header();
        PackedByteArray packet = encrypt_audio(rtp_header, silence_opus);

        if (packet.size() > 0) {
            sendto(_socket, reinterpret_cast<const char *>(packet.ptr()),
                   packet.size(), 0,
                   reinterpret_cast<struct sockaddr *>(&_server_addr),
                   sizeof(_server_addr));
        }
    }
}

int VoiceUDPClient::get_sequence() const {
    return static_cast<int>(_sequence.load());
}

int VoiceUDPClient::get_timestamp() const {
    return static_cast<int>(_timestamp.load());
}

} // namespace godot
