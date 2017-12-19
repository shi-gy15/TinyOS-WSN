
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
	int m_nodeId = 1;
	int r_nodeId = 2;

	bool busy;
	uint16_t ack;
	message_t packet;
	message_t pkt2;
	SenseMsg temp;
	SenseMsg sample;

	int readFlag = 0;

	// Queue
	SenseMsg m_queue[QUEUE_MAX_LENGTH];
	int m_head;
	int m_back;
	// 最后一个元素是queue[back-1]
	int m_currentIndex;
	int m_sendStart;
	int m_sendEnd;
	int m_sendCurrent;

	// the receive Queue
	SenseMsg r_queue[QUEUE_MAX_LENGTH];
	int r_head;
	int r_back;
	// 最后一个元素是queue[back-1]
	int r_currentIndex;
	int r_sendStart;
	int r_sendEnd;
	int r_sendCurrent;

	void initQueue() {
		m_head = 0;
    	m_back = 0;
		m_currentIndex = 1;
		r_head = 0;
    	r_back = 0;
		r_currentIndex = 1;
	}

	bool isEmpty(int flag) {
		if(flag == 0){
			if (m_head==m_back)
				return TRUE;
			else
				return FALSE;
		}
		if(flag == 1){
			if (r_head==r_back)
				return TRUE;
			else
				return FALSE;
		}
	}
	
	bool isFull(int flag) {
		if(flag == 0){
			if (m_back + 1 == m_head || m_back + 1 == m_head + QUEUE_MAX_LENGTH)
				return TRUE;
			else
				return FALSE;
		}
		if(flag == 1){
			if (r_back + 1 == r_head || r_back + 1 == r_head + QUEUE_MAX_LENGTH)
				return TRUE;
			else
				return FALSE;
		}
	}

	void enQueue(SenseMsg msg,int flag) {
		if (isFull(flag))
				return ;

		if(flag == 0){

			m_queue[m_back].index = m_currentIndex;
			m_queue[m_back].nodeId = m_nodeId;
			m_queue[back].temperature = msg.temperature;
			m_queue[back].humidity = msg.humidity;
			m_queue[back].radiation = msg.radiation;

			
			m_back = m_back + 1;
			if (m_back >= QUEUE_MAX_LENGTH)
				m_back = m_back - QUEUE_MAX_LENGTH;

			m_currentIndex ++;
		}
		if(flag == 1){

			r_queue[r_back].index = r_currentIndex;
			r_queue[r_back].nodeId = r_nodeId;
			r_queue[back].temperature = msg.temperature;
			r_queue[back].humidity = msg.humidity;
			r_queue[back].radiation = msg.radiation;

			
			r_back = r_back + 1;
			if (r_back >= QUEUE_MAX_LENGTH)
				r_back = r_back - QUEUE_MAX_LENGTH;

			r_currentIndex ++;
		}
	}

	void deQueue(int flag) {

    	if (isEmpty(flag)) {
      		return;
    	}

    	if(flag == 0){
    		m_head = m_head + 1;
			if (m_head >= QUEUE_MAX_LENGTH)
				m_head = m_head - QUEUE_MAX_LENGTH;

      		return;
		}
		if(flag == 1){
    		r_head = r_head + 1;
			if (r_head >= QUEUE_MAX_LENGTH)
				r_head = r_head - QUEUE_MAX_LENGTH;

      		return;
		}
	}

	void sendCurrentPacket() {
		SenseMsg * payload;

		int m_test = m_sendCurrent - 1;
		int r_test = r_sendCurrent - 1;
		if (m_test < 0)
			m_test += QUEUE_MAX_LENGTH;
		
		//  send first to other nodes
		if(m_test < m_sendEnd){
			payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			if (payload == NULL) {
				return;
			}
			payload->index = m_queue[m_sendCurrent].index;
			payload->nodeId = m_queue[m_sendCurrent].nodeId;
			payload->currentTime = 100;

			payload->temperature = m_queue[m_sendCurrent].temperature;
			payload->humidity = m_queue[m_sendCurrent].humidity;
			payload->radiation = m_queue[m_sendCurrent].radiation;

			call Leds.led1On();
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
				busy = TRUE;
			}

			m_sendCurrent += 1;
			if (m_sendCurrent >= QUEUE_MAX_LENGTH)
				m_sendCurrent -= QUEUE_MAX_LENGTH;
			return;
		}

		if(r_test < r_sendEnd){
			payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			if (payload == NULL) {
				return;
			}
			payload->index = r_queue[sendCurrent].index;
			payload->nodeId = r_queue[sendCurrent].nodeId;
			payload->currentTime = 100;

			payload->temperature = r_queue[sendCurrent].temperature;
			payload->humidity = r_queue[sendCurrent].humidity;
			payload->radiation = r_queue[sendCurrent].radiation;

			call Leds.led1On();
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(SenseMsg)) == SUCCESS) {
				busy = TRUE;
			}

			r_sendCurrent += 1;
			if (r_sendCurrent >= QUEUE_MAX_LENGTH)
				r_sendCurrent -= QUEUE_MAX_LENGTH;
			return;
		}
	}

	void GBNSenderSend() {
		int i;
		int p = m_head;	
		int q = r_head;	

		m_sendStart = m_head;
		r_sendStart = r_head;

		for (i=0;i<WND_SIZE;i++)
		{	
			if (p == m_back - 1 || i == WND_SIZE - 1)
				break;
			
			p = p + 1;
			if (p >= QUEUE_MAX_LENGTH)
				p = p - QUEUE_MAX_LENGTH;
		}

		m_sendEnd = p;

		m_sendCurrent = sendStart;

		for (i=0;i<WND_SIZE;i++)
		{	
			if (q == r_back - 1 || i == WND_SIZE - 1)
				break;
			
			q = q + 1;
			if (q >= QUEUE_MAX_LENGTH)
				q = q - QUEUE_MAX_LENGTH;
		}
		
		r_sendEnd = q;

		r_sendCurrent = sendStart;

		sendCurrentPacket();
	}

	message_t* GBNSenderReceive(message_t* msg, void* payload, uint8_t len) {
		AckMsg* rcvPayload;
		SenseMsg* rcvSensePayload;
		AckMsg* sndackPayload;

		int AckIndex = 0;
		int id = 0;
		int p = m_head;

		if (len == sizeof(AckMsg)) {
			rcvPayload = (AckMsg*) payload;

			AckIndex = rcvPayload->index;
			id = rcvPayload->nodeId;
			// 去除队列中的元素

			while (m_queue[p].index <= AckIndex && id == m_nodeId){
				deQueue(0);
				p = m_head;	
				if (isEmpty(0))
					break;
			}

			while (m_queue[p].index <= AckIndex && id == r_nodeId){
				deQueue(1);
				p = r_head;
				if (isEmpty(1)))
					break;
			}

			return msg;
		}
		
		if (len == sizeof(SenseMsg)) {
			rcvSensePayload = (AckMsg*) payload;
			if(rcvSensePayload->index == ack + 1){
				enQueue(*rcvSensePayload,1);
				ack++;
			}

			sndackPayload = (AckMsg*) call Packet.getPayload(&pkt2, sizeof(AckMsg));

			if (sndackPayload == NULL) {
				return NULL;
			}

			sndackPayload->index = ack;

			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt2, sizeof(AckMsg)) == SUCCESS) {
				busy = TRUE;
			}
			return msg;
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
		ack = 0;

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
			enQueue(temp,0);
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
			enQueue(temp,0);
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
			enQueue(temp,0);
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
