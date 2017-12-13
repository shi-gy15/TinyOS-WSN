configuration ReceiverAppC {
	// .
}

implementation {
	components ReceiverC as App;

	components MainC, LedsC;
	components ActiveMessageC;
	components SerialActiveMessageC;

	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
	App.Packet -> ActiveMessageC.Packet;
	App.SPacket -> SerialActiveMessageC.Packet;
	App.SAMSend -> SerialActiveMessageC.AMSend[AM_SENSE_MSG];
	App.AMSend -> ActiveMessageC.AMSend[AM_ACK_MSG];
	App.Receive -> ActiveMessageC.Receive[AM_SENSE_MSG];
	App.RadioControl -> ActiveMessageC;
	App.SerialControl -> SerialActiveMessageC;
}