/// @description MOVEMENT


if (Game.GameState == STATE.DURING) {
	
	if (IsPlayerOne) {
		MyTicks = Boards.P1Ticks;
	} else {
		MyTicks = Boards.P2Ticks;	
	}
	
	var _input = rollback_get_input()

	if (_input.left) {
		MoveLeft();
	}

	if (_input.right) {
		MoveRight();	
	}

	if (_input.up) {
		MoveUp();	
	}

	if (_input.down) {
		MoveDown();	
	}
}