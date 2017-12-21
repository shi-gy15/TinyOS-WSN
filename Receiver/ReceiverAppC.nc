configuration ReceiverAppC {
	// .
}

implementation {
	components ReceiverC as App;

	components MainC, LedsC;
	components ActiveMessageC;
	components SerialActiveMessageC;
	components new AMSenderC(AM_ACKMSG) as Ack_AMSender;
	components new AMReceiverC(AM_SENSEMSG) as Packet_AMReceiver;
	components new AMSenderC(AM_WORKMSG) as Work_AMSender;

	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
	App.Packet -> ActiveMessageC.Packet;
	App.SPacket -> SerialActiveMessageC.Packet;
	App.SAMSend -> SerialActiveMessageC.AMSend[AM_SENSEMSG];
	App.WorkSend -> Work_AMSender.AMSend;
	App.WorkAcks -> Work_AMSender.Acks;
	App.AMSend -> Ack_AMSender;
	App.Receive -> Packet_AMReceiver;
	App.RadioControl -> ActiveMessageC;
	App.SerialControl -> SerialActiveMessageC;

	App.WorkReceive -> SerialActiveMessageC.Receive[AM_WORKMSG];
}