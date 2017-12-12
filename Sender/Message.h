#ifndef MESSAGE_H
#define MESSAGE_H

typedef nx_struct SenseMsg{
    nx_uint16_t temperature;
    nx_uint16_t humidity;
    nx_uint16_t radiation;
} SenseMsg;

typedef nx_struct AckMsg{
    nx_uint16_t index;
} AckMsg;

enum {
    AM_TEMPERATURE_MSG = 6,
    AM_HUMIDITY_MSG,
    AM_RADIATION_MSG,
    AM_SENSE_MSG = 10,
    AM_ACK_MSG = 20,
};

#endif