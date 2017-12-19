
configuration SenderAppC {
	// .
	// sense and transfer by radio
}

implementation {
	components SenderC as App;

	components MainC, LedsC;
	components new TimerMilliC() as SenseTimer;
	components new TimerMilliC() as SendTimer;
	components ActiveMessageC;
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
	App.ReadTemperature -> SenseTH.Temperature;
	App.ReadHumidity -> SenseTH.Humidity;
	App.ReadRadiation -> SenseR.Read;
	App.Packet -> ActiveMessageC;
	App.AMSend -> ActiveMessageC.AMSend[AM_SENSEMSG];
	App.Receive -> ActiveMessageC.Receive[AM_ACKMSG];	
	App.RadioControl -> ActiveMessageC;

	App.SerialAMSend -> SerialActiveMessageC.AMSend[AM_SENSEMSG];
	App.SerialControl -> SerialActiveMessageC;
}
