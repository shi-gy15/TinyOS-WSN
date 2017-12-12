#ifndef QUEUE_H
#define QUEUE_H

#include "Message.h"

struct QueueNode{
    int index;
    SenseMsg data;
    struct QueueNode * next; 
};

typedef struct QueueNode QueueHead;

#endif