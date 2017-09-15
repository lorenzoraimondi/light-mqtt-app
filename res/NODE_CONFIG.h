#ifndef NODE_CONFIG_H
#define NODE_CONFIG_H

#define N_NODES 8
#define N_TOPICS 3

#define BROKER_ID 1
#define CAPACITY 200

#define NODE_BOOTED 0
#define NODE_CONNECTED 1
#define NODE_ACTIVE 2

#define CONNECT 1
#define CONNACK 2
#define SUBSCRIBE 3
#define SUBACK 4
#define PUBLISH 5
#define PUBACK 6

#define TIME_PERIOD_TEMP 180000
#define TIME_PERIOD_HUM 300000
#define TIME_PERIOD_LUM 60000

#define TEMP_RANGE 60
#define HUM_RANGE 100
#define LUM_RANGE 100

/****************************
Publication Topics

0: topic 1
1: topic 2
2: topic 3
3: no publishing
****************************/
		
	
uint8_t PUBLICATION_TOPIC[N_NODES] = {
/*NODE |2|3|4|5|6|7|8|9|*/
	2,0,0,1,2,1,3,0

};

/****************************
Publication QoS

0: QoS = 0
1: QoS = 1
2: no publishing
****************************/
uint8_t PUBLICATION_QOS[N_NODES] = {

/*NODE |2|3|4|5|6|7|8|9|*/
	1,1,0,1,0,0,2,1

};

/****************************
Subscriptions topic
0: Not subscribed
1: Subscribed
****************************/
uint8_t SUBSCRIPTIONS_TOPIC[N_TOPICS][N_NODES] = {

/*NODE  |2|3|4|5|6|7|8|9|*/
/*T0*/	{1,0,0,0,1,1,1,1},//TEMP
/*T1*/	{1,0,1,1,0,0,1,1},//HUM
/*T2*/	{0,1,1,0,1,0,1,1} //LUM

};

/****************************
Subscriptions QoS
0: QoS = 0
1: QoS = 1
****************************/
uint8_t SUBSCRIPTIONS_QOS[N_TOPICS][N_NODES] = {

/*NODE  |2|3|4|5|6|7|8|9|*/
/*T0*/	{1,0,0,0,0,1,0,1},//TEMP
/*T1*/	{1,0,0,1,0,0,0,1},//HUM
/*T2*/	{0,0,1,0,0,0,0,1} //LUM

};

#endif

