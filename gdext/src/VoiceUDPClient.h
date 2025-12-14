#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include <opus.h>
#include <sodium.h>

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
typedef SOCKET socket_t;
#define SOCKET_INVALID INVALID_SOCKET
#define CLOSE_SOCKET closesocket
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
typedef int socket_t;
#define SOCKET_INVALID (-1)
#define CLOSE_SOCKET close
#endif

namespace godot {

class VoiceUDPClient : public RefCounted {
    GDCLASS(VoiceUDPClient, RefCounted);

public:
    // Audio constants
    static constexpr int SAMPLE_RATE = 48000;
    static constexpr int CHANNELS = 2;
    static constexpr int FRAME_DURATION_MS = 20;
    static constexpr int FRAME_SIZE = (SAMPLE_RATE / 1000) * FRAME_DURATION_MS; // 960 samples
    static constexpr int MAX_PACKET_SIZE = 4000;
    static constexpr int BITRATE = 128000;

    VoiceUDPClient();
    ~VoiceUDPClient();

    // Connection management
    Error connect_to_server(const String &ip, int port);
    void disconnect();
    bool is_connected() const;

    // IP Discovery - returns Dictionary with "ip" and "port" keys
    Dictionary perform_ip_discovery(int ssrc);

    // Encryption key from session description
    void set_secret_key(const PackedByteArray &key);

    // SSRC for this voice connection
    void set_ssrc(int ssrc);
    int get_ssrc() const;

    // Audio transmission
    // PCM data should be 16-bit signed integer, stereo, 48kHz
    // Frame size should be 960 samples (20ms) * 2 channels * 2 bytes = 3840 bytes
    Error send_audio_frame(const PackedByteArray &pcm_data);

    // Send silence frames (5 frames of silence to signal end of speaking)
    void send_silence_frames();

    // Get current sequence number
    int get_sequence() const;

    // Get current timestamp
    int get_timestamp() const;

protected:
    static void _bind_methods();

private:
    // Socket
    socket_t _socket = SOCKET_INVALID;
    struct sockaddr_in _server_addr;
    std::atomic<bool> _connected{false};

    // Voice state
    std::atomic<int> _ssrc{0};
    std::atomic<uint16_t> _sequence{0};
    std::atomic<uint32_t> _timestamp{0};

    // Encryption
    std::vector<uint8_t> _secret_key;
    std::atomic<uint32_t> _nonce_counter{0};  // Incremental nonce for aead_xchacha20_poly1305_rtpsize
    std::mutex _key_mutex;

    // Opus encoder
    OpusEncoder *_encoder = nullptr;
    std::mutex _encoder_mutex;

    // Helper methods
    PackedByteArray build_rtp_header();
    PackedByteArray encrypt_audio(const PackedByteArray &rtp_header, const std::vector<uint8_t> &opus_data);
    bool init_opus_encoder();
    void cleanup_opus_encoder();

    // Platform-specific
    static bool init_sockets();
    static void cleanup_sockets();
    static bool _sockets_initialized;
};

} // namespace godot
