# light-mqtt-app

TinyOS project for Internet of Things course @ Politecnico di Milano

The project consisted in the design and the implementation of a publish-subscribe application using TinyOS. 
The implemented protocol is a lightweight version of MQTT, capable of managing up to 8 nodes connected in a star topology. The central node, the MQTT Broker, can handle Clients connections, subscriptions, and publications. 
The Broker also supports two Quality of Service constraints, requested by publishing and subscribing nodes: with QoS = 0, publications and acknowledgments are sent with an "at most one" fashion, while with QoS = 1 "at least one" approach is used.
Along with the source code is provided the Python script to be used for TOSSIM simulation.


More details are available in the Report document.
