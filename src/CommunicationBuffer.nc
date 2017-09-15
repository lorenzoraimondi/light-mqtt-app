interface CommunicationBuffer {

	command error_t start();
	event void startDone(error_t err);
	command error_t addRequest(uint8_t type, uint8_t* args);
	event void receive(message_t* msg, void* payload, uint8_t len);

}
