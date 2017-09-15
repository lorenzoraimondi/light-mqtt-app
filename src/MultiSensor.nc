interface MultiSensor {

	command error_t start(uint8_t topic);
	event void newValue(uint16_t value);

}
