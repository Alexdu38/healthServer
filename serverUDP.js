var dgram = require('dgram'); 
var server = dgram.createSocket("udp4"); 
server.bind();
server.setBroadcast(true)
server.setMulticastTTL(128);
server.addMembership('230.185.192.108'); 