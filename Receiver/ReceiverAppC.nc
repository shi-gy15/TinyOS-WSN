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
	App.SAMSend -> SerialActiveMessageC.AMSend[AM_SENSEMSG];
	App.AMSend -> ActiveMessageC.AMSend[AM_ACKMSG];
	App.Receive -> ActiveMessageC.Receive[AM_SENSEMSG];
	App.RadioControl -> ActiveMessageC;
	App.SerialControl -> SerialActiveMessageC;
}