
configuration SenderAppC {
	// .
	// sense and transfer by radio
}

implementation {
	components SenderC as App;

	components MainC, LedsC;
	components new TimerMilliC() as SenseTimer;
	components new TimerMilliC() as SendTimer;
	components new TimerMilliC() as ResetTimer;
	components ActiveMessageC;
	components new AMSenderC(AM_SENSEMSG) as Packet_AMSend;
	components new AMReceiverC(AM_ACKMSG) as Ack_AMReceive;
	components new AMReceiverC(AM_WORKMSG) as Work_AMReceive;
	components new SensirionSht11C() as SenseTH;
	components new HamamatsuS1087ParC() as SenseR;

	components SerialActiveMessageC;
	// T: temperature
	// H: humidity
	// R: radiation

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.SenseTimer -> SenseTimer;
	App.SendTimer -> SendTimer;
	App.ResetTimer -> ResetTimer;
	App.ReadTemperature -> SenseTH.Temperature;
	App.ReadHumidity -> SenseTH.Humidity;
	App.ReadRadiation -> SenseR.Read;
	App.Packet -> ActiveMessageC;
	App.AMSend -> Packet_AMSend.AMSend;
	App.Receive -> Ack_AMReceive.Receive;	
	App.RadioControl -> ActiveMessageC;

	App.SerialAMSend -> SerialActiveMessageC.AMSend[AM_SENSEMSG];
	App.SerialControl -> SerialActiveMessageC;

	App.WorkReceive -> Work_AMReceive.Receive;
}
