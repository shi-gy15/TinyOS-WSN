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
    nx_uint16_t nodeId;
    nx_uint16_t index;
} AckMsg;

enum {
    AM_SENSEMSG = 10,
    AM_ACKMSG = 20
};

#endif
