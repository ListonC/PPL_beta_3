/// @description START THE GAME

GameState = STATE.DURING;

alarm_set(1, FlipSecondCooldown);
alarm_set(2, SplitSecondCooldown);
alarm_set(3, BlinkTimeCooldown);

Boards.P1BoardState = BOARDSTATE.GO;
Boards.P2BoardState = BOARDSTATE.GO;