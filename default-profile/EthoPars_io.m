function [pars, docs] = EthoPars_io
error('No! Do the other thing!');
pars.port_name = '';
docs.port_name = strjoin({
'The port identifier for the default Arduino-based digital I/O system. Check'
'the Arduino documentation for help with identifying this. On Windows, this'
'will be something like "COM1"; on Linux, something like "/dev/ttyACM0"; and on'
'on Mac OS, something like "/dev/cu.usbmodem0".'
});

pars.reward_pin = 2;
docs.reward_pin = strjoin({
'The digital I/O pin number on the Arduino connected to the reward device.'
});

pars.reward_signal = 1;
docs.reward_signal = strjoin({
'The logic value for activating the reward device, 0 or 1. In most cases this'
'should be configured in the Arduino sketch rather than here, and 1 will work'
'just fine.'
});
