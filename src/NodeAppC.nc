#include "../res/PACKETS.h"

configuration NodeAppC {

} implementation {

        components MainC, NodeC as App, RandomC;
	
	components CommunicationBufferC;    

	components new AMSenderC(AM_MY_MSG);
        components new AMReceiverC(AM_MY_MSG);
        components ActiveMessageC;

	components MultiSensorC;

        components new TimerMilliC() as ConnectTimeoutTimer;
        components new TimerMilliC() as SubscribeTimeoutTimer;
        components new TimerMilliC() as SendTimer;
	components new TimerMilliC() as TimerTemp;
	components new TimerMilliC() as TimerHum;
	components new TimerMilliC() as TimerLum;
        
	RandomC <- MainC.SoftwareInit;

        App.AMPacket -> AMSenderC;
        App.RadioPacket -> AMSenderC;
        App.Communicator -> CommunicationBufferC;
	App.Sensor -> MultiSensorC;
        App.Boot -> MainC.Boot;
        App.ConnectTimeoutTimer -> ConnectTimeoutTimer;
        App.SubscribeTimeoutTimer -> SubscribeTimeoutTimer;
	
        CommunicationBufferC.Receive -> AMReceiverC;
        CommunicationBufferC.AMSend -> AMSenderC;
        CommunicationBufferC.RadioControl -> ActiveMessageC;	
        CommunicationBufferC.SendTimer -> SendTimer;
	CommunicationBufferC.PacketAcknowledgements -> ActiveMessageC;

	MultiSensorC.TimerTemp -> TimerTemp;
	MultiSensorC.TimerHum -> TimerHum;
	MultiSensorC.TimerLum -> TimerLum;
	MultiSensorC.Random -> RandomC;

}
