
#include "Message.h"

#define WND_SIZE 10
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
	uses interface SplitControl as RadioControl;
}

implementation {
	// led0(red): sense
	// led2(blue): send

	bool busy;
	message_t packet;
	SenseMsg* dataQueue[WND_SIZE];
	uint16_t qFront;
	uint16_t qBack;
	uint16_t qLen;
	SenseMsg temp;
	SenseMsg sample;


	void initQueue() {
		// init packet queue
		for (uint16_t i = 0; i < WND_SIZE; i++) {
			dataQueue[i] = NULL;
		}
		// qFront: first element
		// qBack: last element's next
		qFront = WND_SIZE;
		qBack = WND_SIZE;
		qLen = 0;
	}



	uint8_t isEmpty() {
		return (qFront == WND_SIZE && qBack == WND_SIZE);
	}

	void enqueue(SenseMsg* msg) {
		if (qLen == 0) {
			dataQueue[0] = msg;
			qFront = 0;
			qBack = 0;
			qLen++;
		}
		else if (qLen < WND_SIZE) {
			qBack = qBack % WND_SIZE;
			dataQueue[qBack] = msg;
			qBack++;
			qLen++;
		}
		else {
			return;
		}
	}

	SenseMsg* dequeue() {
		if (qLen == 0) {
			return NULL;
		}
		else {
			SenseMsg* res = dataQueue[qFront];
			qFront++;
			qFront = qFront % WND_SIZE;
			qLen--;
			return res;
		}
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

		call initQueue();

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
		// todo
		call Leds.led0Toggle();
		//temp = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
		temp.temperature = 0;
		temp.humidity = 0;
		temp.radiation = 0;
		call ReadTemperature.read();
		call ReadHumidity.read();
		call ReadRadiation.read();

		if (call checkMsg(&temp) == 0) {
			SenseMsg res = temp;
			call enqueue(&res);
		}
		call Leds.led0Toggle();
	}

	event void SendTimer.fired() {
		// todo
		call Leds.led2Toggle();
		SenseMsg* msg = (call dequeue());
		if (msg != NULL) {
			SenseMsg* payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			if (payload == NULL) {
				return;
			}
			payload->temperature = msg->temperature;
			payload->humidity = msg->humidity;
			payload->radiation = msg->radiation;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
		call Leds.led2Toggle();
	}

	event void ReadTemperature.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			temp->temperature = val;
		}
	}

	event void ReadHumidity.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			temp->humidity = val;
		}
	}

	event void ReadRadiation.readDone(error_t result, uint16_t val) {
		if (result == SUCCESS) {
			temp->radiation = val;
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		// todo
		if (&packet == msg) {
			call Leds.led0Toggle();
			busy = FALSE;
		}
	}
}