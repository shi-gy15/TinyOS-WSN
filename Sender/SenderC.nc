
#include "Message.h"
#include "Queue.h"

#define WND_SIZE 5
#define QUEUE_MAX_LENGTH 50
#define SENSE_TIMER_PERIOD 2000
#define SEND_TIMER_PERIOD 6000

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

	uses interface SplitControl as SerialControl;	
	uses interface AMSend as SerialAMSend;
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

	int readFlag = 0;

	// Queue
	SenseMsg queue[QUEUE_MAX_LENGTH];
	int head;
	int back;
	// 最后一个元素是queue[back-1]
	int currentIndex;

	int sendStart;
	int sendEnd;
	int sendCurrent;

	void initQueue() {
		head = 0;
    back = 0;
		currentIndex = 1;
	}

	bool isEmpty() {
		if (head==back)
			return TRUE;
		else
			return FALSE;
	}
	
	bool isFull() {
		if (back + 1 == head || back + 1 == head + QUEUE_MAX_LENGTH)
			return TRUE;
		else
			return FALSE;
	}

  void enQueue(SenseMsg msg) {
		if (isFull())
			return ;

    queue[back].index = currentIndex;
		queue[back].nodeId = nodeId;
    queue[back].temperature = msg.temperature;
    queue[back].humidity = msg.humidity;
    queue[back].radiation = msg.radiation;

		
		back = back + 1;
		if (back >= QUEUE_MAX_LENGTH)
			back = back - QUEUE_MAX_LENGTH;

    currentIndex ++;
  }

  SenseMsg deQueue() {
    SenseMsg tmp ;

		tmp.index = -1;
		tmp.nodeId = -1;
    tmp.temperature = 0;
    tmp.humidity = 0;
    tmp.radiation = 0;

    if (isEmpty()) {
      return tmp;
    }
    else {
			tmp.index = queue[head].index;
			tmp.nodeId = queue[head].nodeId;
      tmp.temperature = queue[head].temperature;
      tmp.humidity = queue[head].humidity;
      tmp.radiation = queue[head].radiation;

      head = head + 1;
			if (head >= QUEUE_MAX_LENGTH)
				head = head - QUEUE_MAX_LENGTH;

      return tmp;
    }
  }

	void sendCurrentPacket() {
		SenseMsg * payload;
		int test = sendCurrent-1;
		if (test < 0)
			test += QUEUE_MAX_LENGTH;
		
		if ( test == sendEnd )
			return;

		//  send first to other nodes
		payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
		if (payload == NULL) {
			return;
		}
		payload->index = queue[sendCurrent].index;
		payload->nodeId = queue[sendCurrent].nodeId;
		payload->currentTime = 100;

		payload->temperature = queue[sendCurrent].temperature;
		payload->humidity = queue[sendCurrent].humidity;
		payload->radiation = queue[sendCurrent].radiation;

		call Leds.led1On();
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
			busy = TRUE;
		}

		if (call SerialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
			busy = TRUE;
		}

		sendCurrent += 1;
		if (sendCurrent >= QUEUE_MAX_LENGTH)
			sendCurrent -= QUEUE_MAX_LENGTH;
	}

	void GBNSenderSend() {
		int i;
		int p=head;		

		sendStart = head;

		for (i=0;i<WND_SIZE;i++)
		{	
			if (p == back - 1 || i == WND_SIZE - 1)
				break;
			
			p = p+1;
			if (p >= QUEUE_MAX_LENGTH)
				p = p - QUEUE_MAX_LENGTH;
		}
		sendEnd = p;

		sendCurrent = sendStart;

		sendCurrentPacket();
	}

	message_t* GBNSenderReceive(message_t* msg, void* payload, uint8_t len) {
		AckMsg* rcvPayload;

		int AckIndex = 0;
		int p = head;

		if (len != sizeof(AckMsg)) {
			return msg;
		}

		rcvPayload = (AckMsg*) payload;
		
		AckIndex = rcvPayload->index;

		// output to screen
		rcvPayload = (AckMsg*) (call Packet.getPayload(&packet, sizeof(AckMsg)));
		if (rcvPayload == NULL) {
			return;
		}
		rcvPayload->index = AckIndex;

		// 去除队列中的元素
		while (queue[p].index <= AckIndex){
			deQueue();
			p = head;	
			if (isEmpty())
				break;
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
		readFlag = 0;

		initQueue();

		// init sample
		sample.temperature = 0;
		sample.humidity = 0;
		sample.radiation = 0;
		//data = NULL;
		call RadioControl.start();
		call SerialControl.start();
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

	event void SerialControl.startDone(error_t err) {
		if (err != SUCCESS){
		    call SerialControl.start();
		}
	}

	event void SerialControl.stopDone(error_t err) {
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
		SenseMsg * payload;
		
		if (result == SUCCESS) {
			temp.temperature = val;
		}

		readFlag += 1;
		if (readFlag == 3){
			enQueue(temp);

			// // output to screen
			// payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			// if (payload == NULL) {
			// 	return;
			// }
			// payload->index = 0;
			// payload->nodeId = nodeId;
			// payload->currentTime = 100;

			// payload->temperature = temp.temperature;
			// payload->humidity = temp.humidity;
			// payload->radiation = temp.radiation;

			// call Leds.led1Toggle();
			// if (call SerialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
			// 	busy = TRUE;
			// }

			readFlag = 0;
		}
	}

	event void ReadHumidity.readDone(error_t result, uint16_t val) {
		SenseMsg * payload;

		if (result == SUCCESS) {
			temp.humidity = val;
		}

		readFlag += 1;
		if (readFlag == 3){
			enQueue(temp);

			// // output to screen
			// payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			// if (payload == NULL) {
			// 	return;
			// }
			// payload->index = 0;
			// payload->nodeId = nodeId;
			// payload->currentTime = 100;

			// payload->temperature = temp.temperature;
			// payload->humidity = temp.humidity;
			// payload->radiation = temp.radiation;

			// call Leds.led1Toggle();
			// if (call SerialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
			// 	busy = TRUE;
			// }

			readFlag = 0;
		}
	}

	event void ReadRadiation.readDone(error_t result, uint16_t val) {
		SenseMsg * payload;

		if (result == SUCCESS) {
			temp.radiation = val;
		}

		readFlag += 1;
		if (readFlag == 3){
			enQueue(temp);

			// // output to screen
			// payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			// if (payload == NULL) {
			// 	return;
			// }
			// payload->index = 0;
			// payload->nodeId = nodeId;
			// payload->currentTime = 100;

			// payload->temperature = temp.temperature;
			// payload->humidity = temp.humidity;
			// payload->radiation = temp.radiation;

			// call Leds.led1Toggle();
			// if (call SerialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
			// 	busy = TRUE;
			// }

			readFlag = 0;
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		// todo
		if (&packet == msg) {
			call Leds.led1Off();
			busy = FALSE;
		}

		sendCurrentPacket();
	}

	event void SerialAMSend.sendDone(message_t* msg, error_t err) {
		if (&packet == msg) {
			call Leds.led1Off();
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		return GBNSenderReceive(msg, payload, len);
	}
}
