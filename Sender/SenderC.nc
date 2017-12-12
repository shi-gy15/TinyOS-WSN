
#include "Message.h"
#include "Queue.h"

#define WND_SIZE 5
#define SENSE_TIMER_PERIOD 2000
#define SEND_TIMER_PERIOD 2000

// why not "@safe()"?
module SenderC {
	uses interface Boot;
	uses interface Timer<TMilli> as SenseTimer;
	uses interface Timer<TMilli> as SendTimer;
	uses interface Leds;
	uses interface Read<uint16_t> as ReadTemperature;
	uses interface Read<uint16_t> as ReadHumidity;
	uses interface Read<uint16_t> as ReadRadiation;
	uses interface Packet;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as RadioControl;
}

implementation {
	// led0(red): sense
	// led2(blue): send

	//nodeId
	int nodeId = 1;

	bool busy;
	message_t packet;
	SenseMsg temp;
	SenseMsg sample;

	// Queue
	struct QueueNode* head;
  struct QueueNode* back;
  int currentIndex;

	void initQueue() {
		head = NULL;
    currentIndex = 1;
	}

	bool isEmpty() {
		if (head==NULL)
			return TRUE;
		else
			return FALSE;
	}

  void enQueue(SenseMsg* msg) {
		struct QueueNode newNode;
    if (isEmpty()) {
      head = &newNode;
      head->index = currentIndex;
			head->data.index = currentIndex;
			head->data.nodeId = nodeId;
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
			back->data.index = currentIndex;
			back->data.nodeId = nodeId;
      back->data.temperature = msg->temperature;
      back->data.humidity = msg->humidity;
      back->data.radiation = msg->radiation;
      back->next = NULL;
    }
    currentIndex ++;
  }

  SenseMsg* deQueue() {
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

	void GBNSenderSend() {
		SenseMsg* msg ;
		int i;
		struct QueueNode* p = head;
		SenseMsg * payload;

		for (i=0;i<WND_SIZE;i++)
		{
			if (p == NULL)
				break;

			msg = &(p->data);
			
			payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			if (payload == NULL) {
				return;
			}
			payload->temperature = msg->temperature;
			payload->humidity = msg->humidity;
			payload->radiation = msg->radiation;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
				busy = TRUE;
			}

			p = p->next;
		}
	}

	message_t* GBNSenderReceive(message_t* msg, void* payload, uint8_t len) {
		AckMsg* rcvPayload;

		int AckIndex = 0;
		struct QueueNode * p = head;

		if (len != sizeof(AckMsg)) {
			return msg;
		}

		rcvPayload = (AckMsg*) payload;
		
		AckIndex = rcvPayload->index;

		// 去除队列中的元素
		while (p->index <= AckIndex && p!=NULL ){
			deQueue();
			p = head;	
		}

		return msg;
	}

	

	// check if msg includes right data
	// return 0 if passes
	// else return not 0
	uint8_t checkMsg(SenseMsg* msg) {
		if (msg == NULL) {
			return 1;
		}
		if (msg->temperature == sample.temperature ||
			msg->humidity == sample.humidity ||
			msg->radiation == sample.radiation) {
				return 2;
			}
		return 0;
	}


	event void Boot.booted() {
		// todo
		busy = FALSE;

		initQueue();

		// init sample
		sample.temperature = 0;
		sample.humidity = 0;
		sample.radiation = 0;
		//data = NULL;
		call RadioControl.start();
	}

	event void RadioControl.startDone(error_t err) {
		// todo
		if (err == SUCCESS) {
			call SenseTimer.startPeriodic(SENSE_TIMER_PERIOD);
			call SendTimer.startPeriodic(SEND_TIMER_PERIOD);
		} else {
			call RadioControl.start();
		}
	}

	event void RadioControl.stopDone(error_t err) {
		// todo
	}

	event void SenseTimer.fired() {
		SenseMsg res;
		// todo
		call Leds.led0Toggle();
		//temp = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
		temp.temperature = 0;
		temp.humidity = 0;
		temp.radiation = 0;
		call ReadTemperature.read();
		call ReadHumidity.read();
		call ReadRadiation.read();

		if (checkMsg(&temp) == 0) {
			res = temp;
			enQueue(&res);
		}
		call Leds.led0Toggle();
	}

	event void SendTimer.fired() {
		SenseMsg* msg ;

		// todo
		call Leds.led2Toggle();

		GBNSenderSend();

		call Leds.led2Toggle();
	}

	event void ReadTemperature.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			temp.temperature = val;
		}
	}

	event void ReadHumidity.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			temp.humidity = val;
		}
	}

	event void ReadRadiation.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			temp.radiation = val;
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		// todo
		if (&packet == msg) {
			call Leds.led0Toggle();
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		return GBNSenderReceive(msg, payload, len);
	}
}