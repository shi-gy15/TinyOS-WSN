
#include "Message.h"

#define QUEUE_MAX_LENGTH 50

module SenderC {
	uses interface Boot;
	uses interface Timer<TMilli> as SenseTimer;
	uses interface Timer<TMilli> as SendTimer;
	uses interface Timer<TMilli> as ResetTimer;
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

	uses interface Receive as WorkReceive;
}

implementation {
	//配置参数
	int WND_SIZE = 5;
	int SENSE_TIMER_PERIOD = 500;
	int SEND_TIMER_PERIOD = 1000;
	uint32_t startTime;

	bool busy;//
	message_t packet;
	SenseMsg temp;

	int readFlag = 0;

	// Queue
	SenseMsg queue[QUEUE_MAX_LENGTH];
	int head;
	int back;
	// 最后一个元素是queue[back-1]
	int currentIndex = 1;

	int sendStart;
	int sendEnd;
	int sendCurrent;

	void startTimer() {
		call SenseTimer.startPeriodic(SENSE_TIMER_PERIOD);
		call SendTimer.startPeriodic(SEND_TIMER_PERIOD);
		startTime = call SenseTimer.getNow();
	}

	void stopTimer() {
		call SenseTimer.stop();
		call SendTimer.stop();	
	}

	void initQueue() {
		head = 0;
    	back = 0;
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
		queue[back].nodeId = TOS_NODE_ID;
		queue[back].temperature = msg.temperature;
		queue[back].humidity = msg.humidity;
		queue[back].radiation = msg.radiation;
		queue[back].currentTime = msg.currentTime;

			
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

		if ( !isEmpty() ){
			payload = (SenseMsg*) (call Packet.getPayload(&packet, sizeof(SenseMsg)));
			if (payload == NULL) {
				return;
			}
			payload->index = queue[sendCurrent].index;
			payload->nodeId = queue[sendCurrent].nodeId;
			payload->currentTime = queue[sendCurrent].currentTime;

			payload->temperature = queue[sendCurrent].temperature;
			payload->humidity = queue[sendCurrent].humidity;
			payload->radiation = queue[sendCurrent].radiation;

			call Leds.led1On();
			if (call AMSend.send(1, &packet, sizeof(SenseMsg)) == SUCCESS) {
				busy = TRUE;
			}

			sendCurrent += 1;
			if (sendCurrent >= QUEUE_MAX_LENGTH)
				sendCurrent -= QUEUE_MAX_LENGTH;
		}
	}

	void GBNSenderSend() {
		int i;
		int p=head;		

		if ( isEmpty() )
			return;

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

		// 去除队列中的元素
		while (queue[p].index <= AckIndex){
			deQueue();
			p = head;	
			if (isEmpty())
				break;
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

			call ResetTimer.startOneShot(1000);
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
		call Leds.led0Toggle();
		temp.temperature = 0;
		temp.humidity = 0;
		temp.radiation = 0;
		temp.currentTime = call SenseTimer.getNow() - startTime;
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

	event void ResetTimer.fired() {
		busy = FALSE;
		readFlag = 0;
		//初始化队列
		initQueue();
		//开始采集和发送
		startTimer();
	}

	event void ReadTemperature.readDone(error_t result, uint16_t val) {
		SenseMsg * payload;
		
		if (result == SUCCESS) {
			temp.temperature = val;
		}

		readFlag += 1;
		if (readFlag == 3){
			enQueue(temp);

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
		if (len == sizeof(AckMsg))
			return GBNSenderReceive(msg, payload, len);
		else
			return msg;
	}

	event message_t* WorkReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(WorkMsg))
			return WorkInstruct(msg, payload, len);
		else
			return msg;
	}
}
