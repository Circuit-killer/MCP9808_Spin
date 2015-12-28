# MCP9808 Spin Driver

Driver for the MCP9808 temperature sensor in SPIN for the Propeller
micro-controller. An example of use with extensive testing routines is included
and all functions are thoroughly documented for ease of getting up and running
quickly. This driver also allows for different addresses since the device is
address selectable. The main thing of note is that temperatures returned at
temperature * 100, so 2018 is 20.18 C.
