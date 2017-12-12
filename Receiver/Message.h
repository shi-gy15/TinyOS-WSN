#ifndef MESSAGE_H
#define MESSAGE_H

typedef nx_struct Temperature_Msg{
    nx_uint16_t temperature;
} Temperature_Msg;

enum {AM_TEMPERATURE_MSG = 6};

#endif