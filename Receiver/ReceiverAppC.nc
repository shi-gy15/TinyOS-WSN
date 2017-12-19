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

	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
	App.Packet -> ActiveMessageC.Packet;
	App.SPacket -> SerialActiveMessageC.Packet;
	App.SAMSend -> SerialActiveMessageC.AMSend[AM_SENSEMSG];
	App.AMSend -> Ack_AMSender;
	App.Receive -> Packet_AMReceiver;
	App.RadioControl -> ActiveMessageC;
	App.SerialControl -> SerialActiveMessageC;
}