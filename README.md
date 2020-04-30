# Drones-Game
A game written in x86 Assembly.

A 100x100 game board. Suppose group of N drones which see the same target from different points of view and from different distance.
Each drone tries to detect where is the target on the game board, in order to destroy it.
Drones may destroy the target only if the target is in drone’s field-of-view, and if the target is no more than some maximal distance from the drone. 
When the current target is destroyed, some new target appears on the game board in some randomly chosen place. 
The first drone that destroys T targets is the winner of the game. 
Each drone has three-dimensional position on the game board: coordinate x, coordinate y, and direction (angle from x-axis). 
Drones move randomly chosen distance in randomly chosen angle from their current place.

![Image of Game](https://www.cs.bgu.ac.il/~caspl192/wiki.files/assign3/ass3_fig1.png)
