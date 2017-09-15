#include "../res/PACKETS.h"
#include "../res/NODE_CONFIG.h"

module CommunicationBufferC {

	uses {
        
		interface AMSend; 
		interface Receive;
		interface SplitControl as RadioControl;
		interface PacketAcknowledgements;            
		interface Timer<TMilli> as SendTimer;

	}
	
	//Message buffer managed as a FIFO queue
	provides interface CommunicationBuffer as Buffer;

} implementation {

	message_t buffer[CAPACITY];
	am_addr_t address[CAPACITY];
	uint8_t length[CAPACITY];
	bool qos[CAPACITY];
	uint8_t head;
	uint8_t tail;	
	uint8_t m_id;	//Message ID	
	bool radio_busy;
	bool full;

	
//***************** FUNCTIONS ********************//
	
	//Add to the queue a new ConnectMessage and starts SendTimer if needed
	void addConnect(){

		ConnectMessage* con_m;
		con_m = (ConnectMessage*)(call AMSend.getPayload(&buffer[tail],sizeof(ConnectMessage)));

		con_m->clientID = TOS_NODE_ID;
		con_m->ID = m_id;

		m_id+=1;

		dbg("debug", "CONTENT IN COMMUNICATOR CONNECT: %u %u\n",con_m->ID,con_m->clientID);

		address[tail] = BROKER_ID;
		length[tail] = sizeof(ConnectMessage);
		tail = (tail+1)%CAPACITY;
	
		if(tail == head) {
	
			full = TRUE;
		}
	
		if(!(call SendTimer.isRunning())){

		        call SendTimer.startOneShot(1000);

	    	}

	}

	//Add to the queue a new ConnackMessage and starts SendTimer if needed
	void addConnack(uint8_t dest){

		AckMessage* ack_m;
		ack_m = (AckMessage*)(call AMSend.getPayload(&buffer[tail],sizeof(AckMessage)));

		ack_m->clientID = TOS_NODE_ID;
		ack_m->ID = m_id;
		ack_m->code = CONNACK;
	
		m_id+=1;

		dbg("debug", "CONTENT IN COMMUNICATOR CONNECT: %u %u %u\n",ack_m->ID,ack_m->clientID,ack_m->code);
		address[tail] = dest;
		length[tail] = sizeof(AckMessage);
		tail = (tail+1)%CAPACITY;
	
		if(tail == head) {
	
			full = TRUE;
		}
	
		if(!(call SendTimer.isRunning())){

		        call SendTimer.startOneShot(1000);

	    	}
	}

	//Add to the queue a new SubscribeMessage and starts SendTimer if needed
	void addSubscribe(uint8_t* args){

		SubscribeMessage* sub_m;
		sub_m = (SubscribeMessage*)(call AMSend.getPayload(&buffer[tail],sizeof(SubscribeMessage)));
		
		sub_m->ID = m_id;
		sub_m->clientID = TOS_NODE_ID;
		sub_m->topic1 = args[0];
		sub_m->qos1 = args[1];
		sub_m->topic2 = args[2];
		sub_m->qos2 = args[3];
		sub_m->topic3 = args[4];
		sub_m->qos3 = args[5];

		m_id+=1;

		dbg("debug", "CONTENT IN COMMUNICATOR CONNECT: %u %u %u\n",sub_m->ID,sub_m->clientID);

		address[tail] = BROKER_ID;
		length[tail] = sizeof(SubscribeMessage);
		tail = (tail+1)%CAPACITY;
	
		if(tail == head) {
	
			full = TRUE;
		}
	
		if(!(call SendTimer.isRunning())){

		        call SendTimer.startOneShot(1000);

	    	}
	}

	//Add to the queue a new SubackMessage and starts SendTimer if needed
	void addSuback(uint8_t dest){

		AckMessage* ack_m;
		ack_m = (AckMessage*)(call AMSend.getPayload(&buffer[tail],sizeof(AckMessage)));

		ack_m->clientID = TOS_NODE_ID;
		ack_m->ID = m_id;
		ack_m->code = SUBACK;
	
		m_id+=1;

		dbg("debug", "CONTENT IN COMMUNICATOR CONNECT: %u %u %u\n",ack_m->ID,ack_m->clientID,ack_m->code);
		address[tail] = dest;
		length[tail] = sizeof(AckMessage);
		tail = (tail+1)%CAPACITY;
	
		if(tail == head) {
	
			full = TRUE;
		}
	
		if(!(call SendTimer.isRunning())){

		        call SendTimer.startOneShot(1000);

	    	}
	}

	//Add to the queue a new PublishMessage and starts SendTimer if needed
	void addPublish(uint8_t* args){

		PublishMessage* pub_m;
		pub_m = (PublishMessage*)(call AMSend.getPayload(&buffer[tail],sizeof(PublishMessage)));
		
		pub_m->ID = m_id;
		pub_m->clientID = TOS_NODE_ID;
		pub_m->topicID = args[0];
		pub_m->payload = args[1];
		pub_m->qos = args[2];
		
		m_id+=1;

		dbg("debug", "CONTENT IN COMMUNICATOR CONNECT: %u %u %u\n",pub_m->ID,pub_m->clientID); 
		
		address[tail] = args[3];
		length[tail] = sizeof(PublishMessage);
		qos[tail] = pub_m->qos;
		tail = (tail+1)%CAPACITY;
	
		if(tail == head) {
	
			full = TRUE;
		}
	
		if(!(call SendTimer.isRunning())){

		        call SendTimer.startOneShot(1000);

	    	}
	}

	//Add to the queue a new PubackMessage and starts SendTimer if needed
	void addPuback(uint8_t dest){
		

		AckMessage* ack_m;
		ack_m = (AckMessage*)(call AMSend.getPayload(&buffer[tail],sizeof(AckMessage)));

		ack_m->clientID = TOS_NODE_ID;
		ack_m->ID = m_id;
		ack_m->code = PUBACK;

		m_id+=1;
	
		dbg("debug", "CONTENUTO IN COMMUNICATOR CONNECT: %u %u %u\n",ack_m->ID,ack_m->clientID,ack_m->code);
		address[tail] = dest;
		length[tail] = sizeof(AckMessage);
		qos[tail] = 1;
		tail = (tail+1)%CAPACITY;
	
		if(tail == head) {
	
			full = TRUE;
		}
	
		if(!(call SendTimer.isRunning())){

		        call SendTimer.startOneShot(1000);

	    	}

	}

	//Utility function to get informations from messages, for debugging uses.
	void printSendingInfo(uint8_t adrs, message_t* p, uint8_t len){

		PublishMessage *pub_m;
		AckMessage *ack_m;

		switch(len){

			case sizeof(ConnectMessage):
				dbg("node","[NODE %u] Sending CONNECT [Dest: %u]\n", TOS_NODE_ID, adrs);
				break; 
			case sizeof(SubscribeMessage):
				dbg("node","[NODE %u] Sending SUBSCRIBE [Dest: %u]\n", TOS_NODE_ID, adrs);
				break;
			case sizeof(PublishMessage):
				pub_m = (PublishMessage*)(call AMSend.getPayload(p,len));
				if(TOS_NODE_ID == 1){
					dbg("node","[BROKER] Sending PUBLISH [Dest: %u | Topic: %s | QoS: %u | Payload: %u]\n", 
						adrs,( (pub_m->topicID==0) ? "TEMP" : (pub_m->topicID==1) ? "HUM" : "LUM" ), 
						pub_m->qos, pub_m->payload);
				} else {
					dbg("node","[NODE %u] Sending PUBLISH [Dest: %u | Topic: %s | QoS: %u | Payload: %u]\n", 
						TOS_NODE_ID,adrs,( (pub_m->topicID==0) ? "TEMP" : (pub_m->topicID==1) ? "HUM" : "LUM" ), 
						pub_m->qos, pub_m->payload);
				}
				break;
			case sizeof(AckMessage):
				ack_m=(AckMessage*)(call AMSend.getPayload(p,len));
				switch(ack_m->code){

					case CONNACK:
						dbg("node","[BROKER] Sending CONNACK [Dest: %d]\n", adrs);   	
						break;	
					case SUBACK:
						dbg("node","[BROKER] Sending SUBACK [Dest: %d]\n", adrs);
						break;
					case PUBACK:
						if(TOS_NODE_ID == 1)
							dbg("node","[BROKER] Sending PUBACK [Dest: %d]\n", adrs);
						else
							dbg("node","[NODE %u] Sending PUBACK [Dest: %d]\n", TOS_NODE_ID, adrs);
						break;	
				}
				break;				

		}
			
	}

	//Task used to send the head message in the queue. Radio resource is locked and will be released only
	//once the send has been done by the AMSend interface.
	task void sendTask(){

		message_t* p = &buffer[head];
			
		if(!radio_busy && !full){
			
			radio_busy = TRUE;

			if(qos[head] == 1){

				call PacketAcknowledgements.requestAck(p);				
				
			}

			
			
			if(call AMSend.send(address[head],p,length[head]) == SUCCESS){
				
				full = FALSE;

				printSendingInfo(address[head],p,length[head]);
				dbg("debug","[NODE %u]   SENDING message to %d from queue position %d\n", TOS_NODE_ID, address[head], head);

			} 					
					
		}

		//If there are messages and a timer is not running, starts the timer
		if(head!=tail && !(call SendTimer.isRunning())){

	                call SendTimer.startOneShot(1000);

            	}

	}


//***************** Timer interfaces ********************//

	//Triggers queue message sending
	event void SendTimer.fired(){

		if(head!=tail){

			post sendTask();

		}

	}

//***************** RadioControl interface ********************//

	event void RadioControl.startDone(error_t err){

		if(err == SUCCESS) {

			if(TOS_NODE_ID == 1)
				dbg("comm","[BROKER] Radio on!\n");
			else
				dbg("comm","[NODE %u] Radio on!\n", TOS_NODE_ID); 
			
	       		signal Buffer.startDone(SUCCESS);
		
		} else {

			call RadioControl.start();

		}

	}  
	
	event void RadioControl.stopDone(error_t err){}

//***************** AMSend interface ********************//

	//If sending has been successfull, "removes" message from the queue and release radio lock.
	event void AMSend.sendDone(message_t* buf,error_t err) {
		
		if(&buffer[head] == buf && err == SUCCESS ) {
		
			if(qos[head] == 0 || ( qos[head] == 1 && call PacketAcknowledgements.wasAcked(buf) ) ){
					
				head = (head+1)%CAPACITY;
				dbg("debug","[NODE %u] SENT queue position %u. New head: %u\n", TOS_NODE_ID, 
					(head == 0) ? (CAPACITY - 1) : head-1, head);

				if(head == tail){	

					full = FALSE;

				}

			} else if(!(call PacketAcknowledgements.wasAcked(buf))){
				dbg("error", "[ERROR] Receiver node FAILED in receiving packet!\n");
			} 

		} else {

		        dbg("error", "[ERROR] SEND FAILED \n");
			
		}

		radio_busy = FALSE;

		if(!(call SendTimer.isRunning())){

	                call SendTimer.startOneShot(1000);

            	}

	}    

//***************** Receive interface ********************//

	//Pass the message received from the Radio interface the the node principal module
	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		
			signal Buffer.receive(buf, payload, len);

			return buf; 

		}
	


//***************** Buffer interface ********************//

	//Starts buffer component initializing queue parameters.
	command error_t Buffer.start(){
		
		radio_busy = FALSE;
		head = 0;
		tail = 0;
		m_id = 1;
		full = FALSE;

		if(call RadioControl.start() == SUCCESS)
			return SUCCESS;

		return FAIL;
	
	}

	//Command needed by the node to add new requests to the sending queue. 
	//Depending on the @param type of request triggers the correct handling function.
	command error_t Buffer.addRequest(uint8_t type, uint8_t* args){

		dbg("debug","[NODE %u] NEW REQUEST. head: %u, tail:%u\n",TOS_NODE_ID,head,tail);

		if(!full){	
		
			switch(type){

				case CONNECT:
					addConnect();
					return SUCCESS;
				case CONNACK:
					addConnack(args[0]);
					return SUCCESS;
				case SUBSCRIBE:
					addSubscribe(args);
					return SUCCESS;
				case SUBACK:
					addSuback(args[0]);
					return SUCCESS;
				case PUBLISH:
					addPublish(args);
					return SUCCESS;
				case PUBACK:
					addPuback(args[0]);
					return SUCCESS;
			
			}

		} else 
			dbg("error", "[ERROR] FULL QUEUE: impossible to enqueue message\n");
		
		return FAIL;
	
	}
	
}
