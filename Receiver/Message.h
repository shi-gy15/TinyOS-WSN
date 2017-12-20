#ifndef MESSAGE_H
#define MESSAGE_H

typedef nx_struct SenseMsg{
    nx_uint16_t index;
    nx_uint16_t nodeId;
    nx_uint32_t currentTime;

    nx_uint16_t temperature;
    nx_uint16_t humidity;
    nx_uint16_t radiation;
} SenseMsg;

typedef nx_struct AckMsg{
    nx_uint16_t index;
} AckMsg;

typedef nx_struct WorkMsg{
    nx_uint16_t status;         // 1 开始工作 2 暂停
    nx_uint16_t sensePeriod;    // 毫秒数
    nx_uint16_t sendPeriod;     // 毫秒数
    nx_uint16_t windowSize;     // 窗口大小
} WorkMsg;

enum {
    AM_SENSEMSG = 10,
    AM_ACKMSG = 20,
    AM_WORKMSG = 30
};

#endif