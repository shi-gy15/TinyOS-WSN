#include "Queue.h"

module Queue {
  provides interface Queue;
}

implementation {
	// Queue
	struct QueueNode* head;
  struct QueueNode* back;
  int currentIndex;

	command void initQueue() {
		head = NULL;
    currentIndex = 1;
	}

	command bool isEmpty() {
		if (head==NULL)
			return TRUE;
		else
			return FALSE;
	}

  command void enQueue(SenseMsg* msg) {
		struct QueueNode newNode;
    if (isEmpty()) {
      head = &newNode;
      head->index = currentIndex;
      head->data.temperature = msg->temperature;
      head->data.humidity = msg->humidity;
      head->data.radiation = msg->radiation;
      head->next = NULL;
      back = head;
    }
    else {
      back->next = &newNode;
			back = back->next;
      back->index = currentIndex;
      back->data.temperature = msg->temperature;
      back->data.humidity = msg->humidity;
      back->data.radiation = msg->radiation;
      back->next = NULL;
    }
    currentIndex ++;
  }

  command SenseMsg* deQueue() {
    SenseMsg tmp ;

    tmp.temperature = 0;
    tmp.humidity = 0;
    tmp.radiation = 0;

    if (isEmpty()) {
      return NULL;
    }
    else {
      tmp.temperature = head->data.temperature;
      tmp.humidity = head->data.humidity;
      tmp.radiation = head->data.radiation;

      head = head->next;

      return &tmp;
    }
  }
}