//
// Created by chungphb on 25/5/21.
//

#pragma once
#include <atomic>

#include <supg/core/gateway.h>

namespace supg {

struct simulator;

struct device {
public:
    void run();
    void stop();
    void add_gateway(std::shared_ptr<gateway> gateway);
    friend struct simulator;

private:
    void uplink_loop();
    void send_join_request();
    void send_data();
    void derive_session_keys(const lora::join_accept_payload& join_accept);
    void send_uplink(lora::phy_payload phy_payload);
    void downlink_loop();
    void handle_data(lora::phy_payload phy_payload);

private:
    lora::eui64 _dev_eui;
    lora::eui64 _join_eui;
    lora::aes128key _app_key;
    std::atomic<bool> _joined{false};
    uint16_t _dev_nonce = 200;
    uint16_t _last_dev_nonce = 0;
    size_t _uplink_interval = 10;
    std::vector<byte> _payload;
    uint8_t _f_port = 0;
    lora::dev_addr _dev_addr;
    uint32_t _f_cnt_up = 0;
    uint32_t _f_cnt_down = 0;
    lora::aes128key _app_s_key;
    lora::aes128key _nwk_s_key;
    std::shared_ptr<channel<gw::downlink_frame>> _downlink_frames;
    std::vector<std::shared_ptr<gateway>> _gateways;
    gw::uplink_tx_info _uplink_tx_info;
    std::future<void> _uplink_loop;
    std::future<void> _downlink_loop;
    bool _stopped = false;
    struct downlink_data_info {
        bool _confirmed;
        bool _ack;
        uint32_t _f_cnt_down;
        uint8_t _f_port;
        std::vector<byte> _data;
    };
    std::function<void(downlink_data_info)> _downlink_data_handler;
};

}
