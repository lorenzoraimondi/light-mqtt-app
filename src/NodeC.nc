#include "../res/PACKETS.h"
#include "../res/NODE_CONFIG.h"

module NodeC {

	uses {

		interface Boot;
		
		interface AMPacket;
		interface Packet as RadioPacket;
		interface CommunicationBuffer as Communicator;

		interface MultiSensor as Sensor;
                 
		interface Timer<TMilli> as ConnectTimeoutTimer;
		interface Timer<TMilli> as SubscribeTimeoutTimer;
	
	}

} implementation {

	uint8_t state = 0;

	void* con_payload;	
	void* pub_payload;
	void* sub_payload;
	void* connack_payload;
	void* puback_payload;
	void* suback_payload;
  
    
	//BROKER VARIABLES
	bool connected_nodes[N_NODES];
	bool topic_subs[N_TOPICS][N_NODES];
	bool qos_subs[N_TOPICS][N_NODES];
	uint8_t idProcessed[N_NODES];


	//NODE VARIABLES
	uint8_t pub_topic;
	bool pub_qos;
	uint8_t subscriptions[6]; 
	
//***************** FUNCTIONS ********************//

//First function called after node booting.
//Requests the connection to Broker and starts a timer in case it gets no response.
void connect(){

	if(call Communicator.addRequest(CONNECT,NULL) == SUCCESS){

		dbg("comm", "[NODE %u] CONNECT requested to Communicator\n",TOS_NODE_ID);

	} else {

		dbg("error", "[ERROR] CONNECT request failed!\n");

	}
	
	call ConnectTimeoutTimer.startOneShot(20000);

}

//Requests the subscription to Broker and starts a timer in case it gets no response.
void subscribe(){	

	if(call Communicator.addRequest(SUBSCRIBE,subscriptions) == SUCCESS){

		dbg("comm", "[NODE %u] SUBSCRIBE requested to Communicator\n",TOS_NODE_ID);

	} else {
	
		dbg("error", "[ERROR] SUBSCRIBE request failed!\n");
		
	}

	call SubscribeTimeoutTimer.startOneShot(20000);

}

//Requests publish of the input value  to the Broker.
//Note that it does not require any topic id, since in our case a node can publish only on a single topic
//decided at note startup.
void publish(uint16_t value){

	uint8_t args[4] = {pub_topic,value,pub_qos,BROKER_ID};

	if(call Communicator.addRequest(PUBLISH,args) == SUCCESS){

		dbg("comm", "[NODE %u] Enqueuing PUBLISH [Topic: %s | Payload: %u]\n",TOS_NODE_ID, \
			((args[0] == 0) ? "TEMP" : (args[0] == 1) ? "HUM" : "LUM"), args[1]);

	} 

}

//***************** TASKS ********************//


//Handles the connection of a new node in the BROKER: saves its connection and requests to the Communicator
//to send the CONNACK message.
task void connectionHandler(){
	
	ConnectMessage *con_m;
	uint8_t arg;
	uint8_t i;
	
	con_m=(ConnectMessage*)con_payload;

	//dbg("node", "[BROKER]   Received CONNECT [m_id:%u] from %u\n",con_m->ID,con_m->clientID);
	dbg("node", "[BROKER] Received CONNECT [Src: %u]\n",con_m->clientID);
	
	arg = con_m->clientID;

	if(call Communicator.addRequest(CONNACK,&arg) == SUCCESS){

			dbg("comm", "[BROKER] Enqueuing CONNACK to %u\n",arg);

	} 
	
	connected_nodes[arg-2] = 1;

	for(i = 0; i < N_NODES; i++){
		dbg("debug","[BROKER] Node %d: %d\n",i+2,connected_nodes[i]);
	}

}

//Handles the subscription of a new node in the Broker: saves its subscription and requests to the Communicator
//to send the SUBACK message.
task void subscriptionHandler(){ 
	
	SubscribeMessage *sub_m;
	uint8_t client;
	
	uint8_t i;	//Only for debug prints
	

	sub_m=(SubscribeMessage*)sub_payload;
	client = sub_m->clientID;

	//dbg("radio", "[BROKER] Received SUBSCRIBE [m_id:%u] from %u\n",sub_m->ID,client);
	dbg("node", "[BROKER] Received SUBSCRIBE [Src: %u]\n", client);
		
	if(sub_m->topic1){

		dbg("node", "[BROKER] Subscribing node %d to topic \"TEMPERATURE\"\n", client);
		topic_subs[0][client-2] = 1;
		qos_subs[0][client-2] = sub_m->qos1;

	}
	if(sub_m->topic2){

		dbg("node", "[BROKER] Subscribing node %d to topic \"HUMIDITY\"\n", client);
		topic_subs[1][client-2] = 1;
		qos_subs[1][client-2] = sub_m->qos2;

	}
	if(sub_m->topic3){

		dbg("node", "[BROKER] Subscribing node %d to topic \"LUMINOSITY\"\n", client);
		topic_subs[2][client-2] = 1;
		qos_subs[2][client-2] = sub_m->qos3;

	}


	for(i = 0; i < N_TOPICS; i++){
		
		dbg("debug","[BROKER]   %d %d %d %d %d %d %d %d\n", 
			topic_subs[i][0],
			topic_subs[i][1],
			topic_subs[i][2],
			topic_subs[i][3],
			topic_subs[i][4],
			topic_subs[i][5],
			topic_subs[i][6],
			topic_subs[i][7]
		);
			
	}

	if(call Communicator.addRequest(SUBACK,&client) == SUCCESS){

		dbg("comm", "[BROKER] Enqueuing SUBACK to %u\n",client);

	} 
	
}

//BROKER CODE:
//Handles the publication of a new message by a node: request to the Communicator the publishing to every subscribed
//node, and sends PUBACK based on QoS.
//
//NODE CODE:
//Handles the reception from the BROKER of a new publicated message: prints the message and handles QoS.
task void publicationHandler(){

	if(TOS_NODE_ID == 1){	//BROKER CODE

		PublishMessage *pub_m;
		uint8_t client;
		uint8_t n;
		uint8_t args[4];
		bool qos;
				

		pub_m=(PublishMessage*)pub_payload; 

		if(pub_m->ID != idProcessed[(pub_m->clientID)-2]){

			idProcessed[(pub_m->clientID)-2] = pub_m->ID;

			client = pub_m->clientID;
			qos = pub_m->qos;
			args[0] = pub_m->topicID;
			args[1] = pub_m->payload;

			dbg("node", "[BROKER] Received PUBLISH [Src: %u | Topic: %s | QoS: %u | Payload: %d]\n", client, \
				(args[0] == 0) ? "TEMP" : (args[0] == 1 ? "HUM" : "LUM"), qos, args[1]);
	
			if(qos == 1){
			
				if(call Communicator.addRequest(PUBACK,&client) == SUCCESS){

					dbg("comm", "[BROKER] Enqueuing PUBACK to %u\n",client);

				} 

			}

			for(n = 0; n < N_NODES; n++){

				if((n+2)!= client && connected_nodes[n] && topic_subs[args[0]][n]){

					args[2] = qos_subs[args[0]][n];
					args[3] = n + 2;
			
					if(call Communicator.addRequest(PUBLISH,args) == SUCCESS){

						dbg("comm","[BROKER] Enqueuing PUBLISH [Dest: %u | Topic: %s | QoS: %u | Payload: %u]\n",
							(n+2),(args[0] == 0) ? "TEMP" : ((args[0] == 1) ? "HUM" : "LUM"), args[2], args[1]);

					} else { dbg("error","[ERROR] PUBLISH enqueuing failed!\n"); }
		
				} 
			}


		}
			

		
		
		
	} else {			//NODE CODE		
		
		PublishMessage *pub_m;	
		uint8_t topic, dest;
		
		pub_m = (PublishMessage*)pub_payload;
		topic = pub_m->topicID;
		dest = BROKER_ID;

		dbg("node", "[NODE %u] Received MESSAGE [Topic: %s | QoS: %u |Payload: %u]\n",TOS_NODE_ID, \
			(topic == 0) ? "TEMP" : ((topic == 1) ? "HUM" : "LUM"), subscriptions[2*topic+1],pub_m->payload);

		if(subscriptions[(2*topic)+1]){ //IF QoS == 1
			
			if(call Communicator.addRequest(PUBACK, &dest) == SUCCESS){

				dbg("comm", "[NODE %u] Enqueuing PUBACK to BROKER\n", TOS_NODE_ID);

			} 

		}

	}
		
}

//Handles the receipt of the CONNACK from the BROKER. Stops the reconnect timer and triggers subscribe.
task void connackHandler(){
	
	AckMessage* ackm=(AckMessage*)connack_payload;

	//dbg("node", "[NODE %u] Received CONNACK for [m_id:%u]\n",TOS_NODE_ID,ackm->ID);
	dbg("node", "[NODE %u] Received CONNACK [Src: %u]\n",TOS_NODE_ID, ackm->clientID);

	state = NODE_CONNECTED;

	call ConnectTimeoutTimer.stop();
	
	if( subscriptions[0] || subscriptions[2] || subscriptions[4])
		subscribe();

}

//Handles receipt of the SUBACK from the BROKER. Stops the resubscribe timer and
//if the node is configured as a publisher starts the sensing activity.
task void subackHandler(){

	
	AckMessage* ackm=(AckMessage*)suback_payload;

	//dbg("node", "[NODE %u] Received SUBACK for [m_id:%u]\n",TOS_NODE_ID,ackm->ID);
	dbg("node", "[NODE %u] Received SUBACK [Src: %u]\n",TOS_NODE_ID, ackm->clientID);

	state = NODE_ACTIVE;

	call SubscribeTimeoutTimer.stop();

}

//BROKER CODE:
//Handles receipt of PUBACK from node.
//
//NODE CODE:
//Handles receipt of PUBACK from BROKER.
task void pubackHandler(){

	AckMessage* ackm=(AckMessage*)puback_payload;

	if(TOS_NODE_ID == 1){	//BROKER CODE

		//dbg("node", "[BROKER] Received PUBACK for [m_id:%u]\n",ackm->ID);
		dbg("node", "[BROKER] Received PUBACK [Src: %u]\n",ackm->clientID);

	} else {		//NODE CODE

		//dbg("node", "[NODE %u] Received PUBACK for [m_id:%u]\n",TOS_NODE_ID,ackm->ID);
		dbg("node", "[NODE %u] Received PUBACK [Src: %u]\n",TOS_NODE_ID, ackm->clientID);

	}

}

//***************** Boot interface ********************//

//Trigger BROKER/NODE config after its booting and starts Communicator and relative Radio components.
//Node configuration is done by reading 'NODE_CONFIG.h'
event void Boot.booted() {

	uint8_t c;
	
	if(TOS_NODE_ID == 1){
		
		for(c = 0; c < N_NODES; c++)
			idProcessed[c] = 0;


		dbg("boot","[BROKER] Application booted.\n");

		state = NODE_ACTIVE;
		
        } else {		//NODE CODE		

		dbg("boot","[NODE %u] Application booted.\n",TOS_NODE_ID);

		state = NODE_BOOTED;	

		/*********NODE CONFIGURATION**********/
		pub_topic = PUBLICATION_TOPIC[TOS_NODE_ID-2];
		pub_qos = PUBLICATION_QOS[TOS_NODE_ID-2];
		subscriptions[0] = SUBSCRIPTIONS_TOPIC[0][TOS_NODE_ID-2];
		subscriptions[1] = SUBSCRIPTIONS_QOS[0][TOS_NODE_ID-2];
		subscriptions[2] = SUBSCRIPTIONS_TOPIC[1][TOS_NODE_ID-2];
		subscriptions[3] = SUBSCRIPTIONS_QOS[1][TOS_NODE_ID-2];
		subscriptions[4] = SUBSCRIPTIONS_TOPIC[2][TOS_NODE_ID-2];
		subscriptions[5] = SUBSCRIPTIONS_QOS[2][TOS_NODE_ID-2];
		/*************************************/

		if(pub_topic < 3){

			call Sensor.start(pub_topic);

		}

	}
        
        call Communicator.start();

} 

//***************** Communicator interface ********************//

//NODE CODE: if successfull startup, triggers connection to BROKER
event void Communicator.startDone(error_t err){

        if(err == SUCCESS) {

		if(TOS_NODE_ID == 1)
	                dbg("node","[BROKER] Communicator started!\n");
		else
			dbg("node","[NODE %u] Communicator started!\n", TOS_NODE_ID);
               
		if(TOS_NODE_ID != BROKER_ID){

			dbg("node","[NODE %u] Connecting!\n",TOS_NODE_ID);
			
			connect();
		
		}
        
	} else {

	        call Communicator.start();

        }

}  

//Handles receipt of messages from Communicator module.
//Messages are recognized using their length and the correct action is then triggered.
//event message_t* Communicator.receive(message_t* buf,void* payload, uint8_t len) {
event void Communicator.receive(message_t* buf, void* payload, uint8_t len) {
	
	if(TOS_NODE_ID == 1){	//BROKER CODE

		switch(len){

			case sizeof(ConnectMessage):
				con_payload = payload;
				post connectionHandler();
				break; 
			case sizeof(SubscribeMessage):
				sub_payload = payload;
				post subscriptionHandler();
				break;
			case sizeof(PublishMessage):
				pub_payload = payload;
				post publicationHandler();
				break;
			case sizeof(AckMessage):
				puback_payload = payload;
				post pubackHandler();
				break;				

		}
			

	} else {		//NODE CODE

		if(len == sizeof(AckMessage)){

			AckMessage* ack_m=(AckMessage*)payload;

			switch(ack_m->code){

				case CONNACK:
					connack_payload = payload;
					post connackHandler();	    	
					break;	
				case SUBACK:
					suback_payload = payload;
					post subackHandler();
					break;
				case PUBACK:
					puback_payload = payload;
					post pubackHandler();
					break;
					
			}		
		} else if(len == sizeof(PublishMessage)){

			pub_payload = payload;
			post publicationHandler();

		} else {

			dbg("error", "[ERROR] INVALID PACKET\n");	
	
		}
	
	}	    

}    
    
//Triggers new connection attempt
event void ConnectTimeoutTimer.fired(){

	if(state == NODE_BOOTED)
		connect();

}

//Triggers new subscription attempt
event void SubscribeTimeoutTimer.fired(){

	if(state == NODE_CONNECTED)
		subscribe();

}

//***************** Sensor interface ********************//

//Triggers publishing of the new message coming from the sensor.
//Note that only the value is useful since QoS/Topic are decided a priori.
event void Sensor.newValue(uint16_t value){

		if(state >= NODE_CONNECTED){
			publish(value);	
		}

	}
    
}
