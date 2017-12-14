
#include "Message.h"

// why not "@safe()"?
module ReceiverC {
	uses {
		interface Boot;
		interface Leds;
		interface Packet;
		interface Packet as SPacket;
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
	uint16_t ack;
	message_t pkt;
    SenseMsg sample;

	event void Boot.booted() {
		// todo
		busy = FALSE;
		ack = 0;
		call RadioControl.start();
		call SerialControl.start();
	}

	event void RadioControl.startDone(error_t err) {
		// todo
		if (err != SUCCESS) {
			call RadioControl.start();
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

		if (len != sizeof(SenseMsg)) {
			return msg;
		}

		rcvPayload = (SenseMsg*) payload;
		call Leds.led1Toggle();

		//right condition
		if (rcvPayload->index == ack + 1){
		    ack++;
		    //send sensemsg
		    sndPayload = (SenseMsg*) call SPacket.getPayload(&pkt, sizeof(SenseMsg));

		    if (sndPayload == NULL) {
			    return NULL;
		    }
		    sndPayload->radiation = rcvPayload->radiation;
		    sndPayload->humidity = rcvPayload->humidity;
		    sndPayload->temperature = rcvPayload->temperature;

		    sndPayload->index = rcvPayload->index;
				sndPayload->currentTime = rcvPayload->currentTime;
				sndPayload->nodeId = rcvPayload->nodeId;

		    if (call SAMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SenseMsg)) == SUCCESS) {
			    sbusy = TRUE;
		    }
		}

		//send ack
		sndackPayload = (AckMsg*) call Packet.getPayload(&pkt, sizeof(AckMsg));

        if (sndackPayload == NULL) {
            return NULL;
        }

        sndackPayload->index = ack;

        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AckMsg)) == SUCCESS) {
            busy = TRUE;
        }

	    return msg;

	}

    event void AMSend.sendDone(message_t* msg, error_t err) {
		// todo
		if (&pkt == msg) {
			call Leds.led1Toggle();
			busy = FALSE;
		}
	}

	event void SAMSend.sendDone(message_t* msg, error_t err) {
		// todo
		if (&pkt == msg) {
			call Leds.led1Toggle();
			sbusy = FALSE;
		}
	}
}