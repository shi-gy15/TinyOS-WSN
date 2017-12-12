
#include "Message.h"

// why not "@safe()"?
module ReceiverC {
	uses {
		interface Boot;
		interface Leds;
		interface Packet;
		interface AMSend;
		interface Receive;
		interface SplitControl as RadioControl;
		interface SplitControl as SerialControl;
	}
}

implementation {
	bool busy;
	message_t pkt;

	event void Boot.booted() {
		// todo
		busy = FALSE;
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
		




		Temperature_Msg* rcvPayload;
		Temperature_Msg* sndPayload;

		if (len != sizeof(Temperature_Msg)) {
			return msg;
		}

		// call Leds.led0Toggle();
		// call Leds.led2Toggle();

		call Leds.led1Toggle();
		// call Leds.led1Toggle();
		/*if (len != sizeof(Temperature_Msg)) {

			if (len == 8) {

				call Leds.led1Toggle();
			}
			return NULL;
		}*/
		//call Leds.led1Toggle();
		//call Leds.led2Toggle();
		rcvPayload = (Temperature_Msg*) payload;
		sndPayload = (Temperature_Msg*) call Packet.getPayload(&pkt, sizeof(Temperature_Msg));
		if (sndPayload == NULL) {
			return NULL;
		}
		
		sndPayload->temperature = rcvPayload->temperature;
		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(Temperature_Msg)) == SUCCESS) {
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
}