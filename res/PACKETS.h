#ifndef PACKETS_H
#define PACKETS_H



typedef nx_struct ConnectMessage {

	nx_uint8_t ID;
	nx_uint8_t clientID;

} ConnectMessage;

typedef nx_struct AckMessage {

	nx_uint8_t ID;
	nx_uint8_t clientID;
	nx_uint8_t code;
	
} AckMessage;

typedef nx_struct SubscribeMessage {

	nx_uint8_t ID;	
	nx_uint8_t clientID;	
	nx_uint8_t topic1;
	nx_uint8_t topic2;
	nx_uint8_t topic3;
	nx_uint8_t qos1;
	nx_uint8_t qos2;
	nx_uint8_t qos3;

} SubscribeMessage;

typedef nx_struct PublishMessage {

	nx_uint8_t ID;
	nx_uint8_t clientID;	
	nx_uint8_t topicID;
	nx_uint8_t qos;
	nx_uint8_t payload;

} PublishMessage;

enum{

	AM_MY_MSG = 6,

};

#endif
