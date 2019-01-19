# Flappy Bird verilog implementation

* This project implements Flappy Bird using Verilog. The project can be used on FPGA.
* Implementation is in [FA.v](./FA.v)
* [What is Flappy Bird? ](http://flappybird.io)

### How to play?
* The red square is the bird that can be controlled by "KEY[1]". Each time you press, the bird will flap. You can also press and hold "KEY[1]".
* Flap between the pipes and collect the coins, which are represented by the yellow squares.
* The number of coins collected is shown on "HEX0" and "HEX1" (hexadecimal).
* Avoid crashing into the pipes or falling onto the ground! Otherwise, you will lose and "LEDR[0]" will light up.
* Press "KEY[0]" to reset the game.

### Gameplay (2 sessions)
[![IMAGE ALT TEXT](http://img.youtube.com/vi/AvKw8V-zZKM/0.jpg)](https://youtu.be/AvKw8V-zZKM)

### How to Compile Verilog code in Quartus Prime 16.0?
[![IMAGE ALT TEXT](http://img.youtube.com/vi/UX5_v0UBo7c/0.jpg)](https://youtu.be/UX5_v0UBo7c)

### Exploring the blocks used on the FPGA chip
[![IMAGE ALT TEXT](http://img.youtube.com/vi/0gz7_QyOUn0/0.jpg)](https://youtu.be/0gz7_QyOUn0)
