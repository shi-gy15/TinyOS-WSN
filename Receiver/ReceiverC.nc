
#include "Message.h"
#include "Queue.h"

#define QUEUE_MAX_LENGTH 50

// why not "@safe()"?
module ReceiverC {
	uses {
		interface Boot;
		interface Leds;
		interface Packet;
		interface Packet as SPacket;

		interface AMSend as WorkSend;
		interface Receive as WorkReceive;
		interface PacketAcknowledgements as WorkAcks;

		interface AMSend as SAMSend;
		interface AMSend;
		interface Receive;


		interface SplitControl as RadioControl;
		interface SplitControl as SerialControl;
	}
}

implementation {
	bool sbusy;
	bool busy;
	uint16_t ack[10];
	message_t pkt1;
	message_t pkt2;
	message_t work_pkt;
	SenseMsg temp;

	//配置参数
	int STATUS = 1;
	int WND_SIZE = 5;
	int SENSE_TIMER_PERIOD = 500;
	int SEND_TIMER_PERIOD = 1000;
	//配置消息
	WorkMsg instruction; 
	
	// Queue
	SenseMsg queue[QUEUE_MAX_LENGTH];
	int head;
	int back;

	event void Boot.booted() {
		// todo
		busy = FALSE;
		sbusy = FALSE;
		ack[1] = 0;
		ack[2] = 0;
		head = 0;
		back = 0;
		call RadioControl.start();
		call SerialControl.start();
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

		queue[back].index = msg.index;
		queue[back].nodeId = msg.nodeId;
    	queue[back].temperature = msg.temperature;
    	queue[back].humidity = msg.humidity;
    	queue[back].radiation = msg.radiation;
		queue[back].currentTime = msg.currentTime;

		back = back + 1;
		call Leds.led0Toggle();
		if (back >= QUEUE_MAX_LENGTH)
			back = back - QUEUE_MAX_LENGTH;

	}

	SenseMsg deQueue() {
		SenseMsg tmp ;

		tmp.index = -1;
		tmp.nodeId = -1;
    	tmp.temperature = 0;
    	tmp.humidity = 0;
    	tmp.radiation = 0;
		tmp.currentTime = 0;

    	if (isEmpty()) {
      		return tmp;
    	}
    	else {
			tmp.index = queue[head].index;
			tmp.nodeId = queue[head].nodeId;
    		tmp.temperature = queue[head].temperature;
    		tmp.humidity = queue[head].humidity;
    		tmp.radiation = queue[head].radiation;
			tmp.currentTime = queue[head].currentTime;
			head = head + 1;
			if (head >= QUEUE_MAX_LENGTH)
				head = head - QUEUE_MAX_LENGTH;
			call Leds.led1Toggle();
      		return tmp;
    	}
	}

	void sendSenseMsg(){
		SenseMsg* sndPayload;
		
		if(sbusy){
			return;
		}
		sndPayload = (SenseMsg*) call SPacket.getPayload(&pkt1, sizeof(SenseMsg));
		
		if (sndPayload == NULL) {
			 return;
		}

		sndPayload->index = queue[head].index;
		sndPayload->nodeId = queue[head].nodeId;
		sndPayload->temperature = queue[head].temperature;
		sndPayload->radiation = queue[head].radiation;
		sndPayload->humidity = queue[head].humidity;
		sndPayload->currentTime = queue[head].currentTime;

		deQueue();

		if (call SAMSend.send(AM_BROADCAST_ADDR, &pkt1, sizeof(SenseMsg)) == SUCCESS) {
			sbusy = TRUE;
			call Leds.led2Toggle();
		}
	}

	void sendWorkMsg() {
		WorkMsg* sndPayload;
		
		sndPayload = (WorkMsg*) call SPacket.getPayload(&work_pkt, sizeof(WorkMsg));
		
		if (sndPayload == NULL) {
			 return;
		}

		sndPayload->status = STATUS;
		sndPayload->windowSize = WND_SIZE;
		sndPayload->sendPeriod = SEND_TIMER_PERIOD;
		sndPayload->sensePeriod = SENSE_TIMER_PERIOD;

		if (call WorkSend.send(AM_BROADCAST_ADDR, &work_pkt, sizeof(WorkMsg)) == SUCCESS) {
			sbusy = TRUE;
		}
	}

	event void RadioControl.startDone(error_t err) {
		// todo
		if (err != SUCCESS) {
			call RadioControl.start();
		}
		else {
			// sendWorkMsg();
		}
		//call Leds.led0Toggle();
	}

	event void RadioControl.stopDone(error_t err) {
		// todo
	}

	event void SerialControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call SerialControl.start();
		}
		//call Leds.led2Toggle();
	}

	event void SerialControl.stopDone(error_t err) {
		// todo
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		SenseMsg* rcvPayload;
		SenseMsg* sndPayload;
		AckMsg* sndackPayload;
		int nodeId;

		call Leds.led1On();
		if (len != sizeof(SenseMsg)) {
			return msg;
		}

		rcvPayload = (SenseMsg*) payload;

		nodeId = rcvPayload->nodeId;

		//right condition
		if (rcvPayload->index == ack[nodeId] + 1){
			call Leds.led2On();
			ack[nodeId]++;
			
			temp.nodeId = rcvPayload->nodeId;
			temp.index = rcvPayload->index;
			temp.temperature = rcvPayload->temperature;
			temp.radiation = rcvPayload->radiation;
			temp.humidity = rcvPayload->humidity;
			temp.currentTime = rcvPayload->currentTime;
			
			enQueue(temp);

			//send sensemsg
			//call Leds.led1Toggle();
			sendSenseMsg();
		}
		
		//send ack
		sndackPayload = (AckMsg*) call Packet.getPayload(&pkt2, sizeof(AckMsg));

        if (sndackPayload == NULL) {
            return NULL;
        }

        sndackPayload->index = ack[nodeId];
		sndackPayload->nodeId = nodeId;
		
        if (call AMSend.send(1, &pkt2, sizeof(AckMsg)) == SUCCESS) {
            busy = TRUE;
        }

	    return msg;

	}

	event message_t* WorkReceive.receive(message_t* msg, void* payload, uint8_t len) {	
		WorkMsg* rcvPayload;

		if (len != sizeof(WorkMsg)) {
			call Leds.led1On();
			return msg;
		}

		call Leds.led2On();
		rcvPayload = (WorkMsg*) payload;
		STATUS = rcvPayload->status;
		SEND_TIMER_PERIOD = rcvPayload->sendPeriod;
		SENSE_TIMER_PERIOD = rcvPayload->sensePeriod;
		WND_SIZE = rcvPayload->windowSize;

		ack[1] = 0;
		ack[2] = 0;

		sendWorkMsg();
	    return msg;
	}

    event void AMSend.sendDone(message_t* msg, error_t err) {
		// todo
		if (&pkt2 == msg) {
			//call Leds.led1Toggle();
			busy = FALSE;
		}
	}

	event void SAMSend.sendDone(message_t* msg, error_t err) {
		// todo
		if (&pkt1 == msg) {
			//call Leds.led2Toggle();
			sbusy = FALSE;
		}
		if (!isEmpty()){
			sendSenseMsg();
		}
	}

	event void WorkSend.sendDone(message_t* msg, error_t err) {
		if (&work_pkt == msg) {
			sbusy = FALSE;
			//  如果发送失败 重新发送
			//if (!call WorkAcks.wasAcked())
			//	sendWorkMsg();
		}
	}
}