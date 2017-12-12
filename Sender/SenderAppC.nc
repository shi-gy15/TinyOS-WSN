
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
	App.AMSend -> ActiveMessageC.AMSend[AM_SENSE_MSG];
	App.RadioControl -> ActiveMessageC;
}