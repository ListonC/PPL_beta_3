/// @description MANAGE ALARMS


if (GameState == STATE.DURING) {
	FlipSecondCounter -= 1;
	if (FlipSecondCounter <= 0) {
		FlipSecondCounter = FlipSecondCooldown;	
		alarm_set(1, FlipSecondCooldown);
	}

	SplitSecondCounter -= 1;
	if (SplitSecondCounter <= 0) {
		SplitSecondCounter = SplitSecondCooldown;
		alarm_set(2, SplitSecondCooldown);
	}

	BlinkTimeCounter -= 1;
	if (BlinkTimeCounter <= 0) {
		BlinkTimeCounter = BlinkTimeCooldown;
		alarm_set(3, BlinkTimeCooldown);
	}

	MoveTickCounter -= 1;
	if (MoveTickCounter <= 0) {
		MoveTickCooldown = 60 * MoveTickIncrement;
		MoveTickCounter = MoveTickCooldown;
		alarm_set(4, MoveTickCooldown)
	}

	DifficultyCounter -= 1;
	if (DifficultyCooldown <= 0) {
		DifficultyCounter = DifficultyCooldown;
		alarm_set(5, DifficultyCooldown);
	}
}