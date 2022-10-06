/// @description GAME STARTED
if (!GameStarted) {
	alarm_set(0, 180)	
}

if (rollback_game_running) {
	GameStarted = true;	
}