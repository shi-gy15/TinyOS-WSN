
#include "Message.h"

#define QUEUE_MAX_LENGTH 50

module SenderC {
	uses interface Boot;
	uses interface Timer<TMilli> as SenseTimer;
	uses interface Timer<TMilli> as SendTimer;
	uses interface Leds;
	uses interface Read<uint16_t> as ReadTemperature;
	uses interface Read<uint16_t> as ReadHumidity;
	uses interface Read<uint16_t> as ReadRadiation;
	uses interface Packet;
	uses interface AMSend as AMSendAck;
	uses interface AMSend as AMSendMsg;
	uses interface Receive;
	uses interface Receive as MsgReceive;
	uses interface Receive as WorkReceive;

	uses interface SplitControl as RadioControl;

	uses interface SplitControl as SerialControl;	
	uses interface AMSend as SerialAMSend;
}

implementation {
	//配置参数
	int WND_SIZE = 5;
	int SENSE_TIMER_PERIOD = 500;
	int SEND_TIMER_PERIOD = 1000;

	//nodeId
	int m_nodeId = 1;
	int r_nodeId = 2;

	bool busy;
	uint16_t ack;
	message_t pkt1;
	message_t pkt2;
	SenseMsg temp;

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
	int r_sendStart;
	int r_sendEnd;
	int r_sendCurrent;

	void startTimer() {
		call SenseTimer.startPeriodic(SENSE_TIMER_PERIOD);
		call SendTimer.startPeriodic(SEND_TIMER_PERIOD);
	}

	void stopTimer() {
		call SenseTimer.stop();
		call SendTimer.stop();	
	}

	void initQueue() {
		m_head = 0;
    	m_back = 0;
		m_currentIndex = 1;
		r_head = 0;
    	r_back = 0;
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
			m_queue[m_back].temperature = msg.temperature;
			m_queue[m_back].humidity = msg.humidity;
			m_queue[m_back].radiation = msg.radiation;
			m_queue[m_back].currentTime = msg.currentTime;

			
			m_back = m_back + 1;
			if (m_back >= QUEUE_MAX_LENGTH)
				m_back = m_back - QUEUE_MAX_LENGTH;

			m_currentIndex ++;
		}
		if(flag == 1){

			r_queue[r_back].index = msg.index;
			r_queue[r_back].nodeId = msg.nodeId;
			r_queue[r_back].temperature = msg.temperature;
			r_queue[r_back].humidity = msg.humidity;
			r_queue[r_back].radiation = msg.radiation;
			r_queue[r_back].currentTime = msg.currentTime;

			
			r_back = r_back + 1;
			if (r_back >= QUEUE_MAX_LENGTH)
				r_back = r_back - QUEUE_MAX_LENGTH;
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
			
			//call Leds.led0Toggle();

      		return;
		}
		if(flag == 1){
    		r_head = r_head + 1;
			if (r_head >= QUEUE_MAX_LENGTH)
				r_head = r_head - QUEUE_MAX_LENGTH;

      		return;
		}
	}

	void sendAck(){
		AckMsg* sndackPayload;
		sndackPayload = (AckMsg*) call Packet.getPayload(&pkt2, sizeof(AckMsg));

		if (sndackPayload == NULL) {
			return;
		}

		sndackPayload->index = ack;
		sndackPayload->nodeId = 1;

		if (call AMSendAck.send(2, &pkt2, sizeof(AckMsg)) == SUCCESS) {
			busy = TRUE;
		}
	}

	void sendCurrentPacket() {
		SenseMsg * payload;

		int m_test = m_sendCurrent - 1;
		int r_test = r_sendCurrent - 1;

		if(m_test < 0)
			m_test += QUEUE_MAX_LENGTH;
		if(r_test < 0)
			r_test += QUEUE_MAX_LENGTH;
		
		if(busy == TRUE)
			return;
		
		//  send first to other nodes
		if(!isEmpty(0)){
			if(m_test != m_sendEnd){
				payload = (SenseMsg*) (call Packet.getPayload(&pkt1, sizeof(SenseMsg)));
				if (payload == NULL) {
					return;
				}
				payload->index = m_queue[m_sendCurrent].index;
				payload->nodeId = m_queue[m_sendCurrent].nodeId;
				payload->currentTime = m_queue[m_sendCurrent].currentTime;

				payload->temperature = m_queue[m_sendCurrent].temperature;
				payload->humidity = m_queue[m_sendCurrent].humidity;
				payload->radiation = m_queue[m_sendCurrent].radiation;

				call Leds.led1On();
				if (call AMSendMsg.send(0, &pkt1, sizeof(SenseMsg)) == SUCCESS) {
					busy = TRUE;
				}

				m_sendCurrent += 1;
				if (m_sendCurrent >= QUEUE_MAX_LENGTH)
					m_sendCurrent -= QUEUE_MAX_LENGTH;
				return;
			}
		}
		if(!isEmpty(1)){
			if(r_test != r_sendEnd){
				payload = (SenseMsg*) (call Packet.getPayload(&pkt1, sizeof(SenseMsg)));
				if (payload == NULL) {
					return;
				}
				payload->index = r_queue[r_sendCurrent].index;
				payload->nodeId = r_queue[r_sendCurrent].nodeId;
				payload->currentTime = r_queue[r_sendCurrent].currentTime;

				payload->temperature = r_queue[r_sendCurrent].temperature;
				payload->humidity = r_queue[r_sendCurrent].humidity;
				payload->radiation = r_queue[r_sendCurrent].radiation;

				//call Leds.led1On();
				if (call AMSendMsg.send(0, &pkt1, sizeof(SenseMsg)) == SUCCESS) {
					busy = TRUE;
				}

				r_sendCurrent += 1;
				if (r_sendCurrent >= QUEUE_MAX_LENGTH)
					r_sendCurrent -= QUEUE_MAX_LENGTH;
				return;
			}
		}
		if(r_test == r_sendEnd){
			sendAck();
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

		m_sendCurrent = m_sendStart;

		for (i=0;i<WND_SIZE;i++)
		{	
			if (q == r_back - 1 || i == WND_SIZE - 1)
				break;
			
			q = q + 1;
			if (q >= QUEUE_MAX_LENGTH)
				q = q - QUEUE_MAX_LENGTH;
		}
		
		r_sendEnd = q;

		r_sendCurrent = r_sendStart;
		
		sendCurrentPacket();
	}

	message_t* ReceiveAck(message_t* msg, void* payload, uint8_t len) {
		AckMsg* rcvPayload;
		
		int AckIndex = 0;
		int id = 0;
		int p = m_head;
		int q = r_head;
		
		
		
		if (len != sizeof(AckMsg))
			return msg;
	
		rcvPayload = (AckMsg*) payload;

		AckIndex = rcvPayload->index;
		id = rcvPayload->nodeId;
		// 去除队列中的元素
		if(id == m_nodeId){

			while (m_queue[p].index <= AckIndex){
				call Leds.led0Toggle();
				deQueue(0);
				p = m_head;	
				if (isEmpty(0))
					break;
			}
		}
		
		if(id == r_nodeId){
			while (r_queue[q].index <= AckIndex){
				deQueue(1);
				q = r_head;
				if (isEmpty(1))
					break;
			}
		}

		return msg;

	}

	message_t* ReceiveMsg(message_t* msg, void* payload, uint8_t len) {

		SenseMsg* rcvSensePayload;

		if (len != sizeof(SenseMsg))
			return msg;

		rcvSensePayload = (SenseMsg*) payload;

		if(rcvSensePayload->index == ack + 1){
			enQueue(*rcvSensePayload,1);
			ack++;
		}

		return msg;
	}

	message_t* WorkInstruct(message_t* msg, void* payload, uint8_t len) {
		WorkMsg* rcvPayload;
		int status;

		if (len != sizeof(WorkMsg)) {
			return msg;
		}

		rcvPayload = (WorkMsg*) payload;
		
		status = rcvPayload->status;

		if (status == 1){	// 1 开始
			SEND_TIMER_PERIOD = rcvPayload->sendPeriod;
			SENSE_TIMER_PERIOD = rcvPayload->sensePeriod;
			WND_SIZE = rcvPayload->windowSize;

			//结束采集和发送
			stopTimer();
			//初始化队列
			initQueue();
			//开始采集和发送
			startTimer();
		}
		else {
			//结束采集和发送
			stopTimer();
		}

		return msg;
	}

	event void Boot.booted() {
		// todo
		busy = FALSE;
		readFlag = 0;
		ack = 0;

		initQueue();

		call RadioControl.start();
		call SerialControl.start();
	}

	event void RadioControl.startDone(error_t err) {
		// todo
		if (err == SUCCESS) {
			//  startTimer();
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
		temp.temperature = 0;
		temp.humidity = 0;
		temp.radiation = 0;
		temp.currentTime = call SenseTimer.getNow();
		call ReadTemperature.read();
		call ReadHumidity.read();
		call ReadRadiation.read();
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

	event void AMSendAck.sendDone(message_t* msg, error_t err) {
		// todo
		if (&pkt2 == msg) {
			call Leds.led1Off();
			busy = FALSE;
		}

		
	}

	event void AMSendMsg.sendDone(message_t* msg, error_t err) {
		// todo
		if (&pkt1 == msg) {
			call Leds.led1Off();
			busy = FALSE;
		}
		sendCurrentPacket();
	}

	event void SerialAMSend.sendDone(message_t* msg, error_t err) {
		if (&pkt1 == msg) {
			call Leds.led1Off();
			busy = FALSE;
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		return ReceiveAck(msg, payload, len);
	}

	event message_t* MsgReceive.receive(message_t* msg, void* payload, uint8_t len) {
		return ReceiveMsg(msg, payload, len);
	}

	event message_t* WorkReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(WorkMsg))
			return WorkInstruct(msg, payload, len);
		else
			return msg;
	}
}
