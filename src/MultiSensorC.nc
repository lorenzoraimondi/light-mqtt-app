module MultiSensorC {

	uses interface Timer<TMilli> as TimerTemp;
	uses interface Timer<TMilli> as TimerHum;
	uses interface Timer<TMilli> as TimerLum;
	uses interface Random;
	
	provides interface MultiSensor as Sensor;

} implementation {

//***************** TimerTemp interface ********************//

	//Once the timer runs out, signal to the node the new "virtually sensed" value
	event void TimerTemp.fired(){
		
		signal Sensor.newValue((call Random.rand16()%TEMP_RANGE));

	}

//***************** TimerHum interface ********************//

	//Once the timer runs out, signal to the node the new "virtually sensed" value
	event void TimerHum.fired(){
		
		signal Sensor.newValue((call Random.rand16()%HUM_RANGE));

	}

//***************** TimerLum interface ********************//

	//Once the timer runs out, signal to the node the new "virtually sensed" value
	event void TimerLum.fired(){
		
		signal Sensor.newValue((call Random.rand16()%HUM_RANGE));

	}

//***************** Sensor interface ********************//

	//Starts the periodic timer wrt the @param topic
	command error_t Sensor.start(uint8_t topic){
		
		if(topic == 0){
			call TimerTemp.startPeriodic(TIME_PERIOD_TEMP);		
		}
	
		if(topic == 1){
			call TimerHum.startPeriodic(TIME_PERIOD_HUM);		
		}
	
		if(topic == 2){
			call TimerLum.startPeriodic(TIME_PERIOD_LUM);		
		}

		return SUCCESS;
	
	}

}
