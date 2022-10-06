/// @description INIT GAME

rollback_define_input({
	left:  [ord("A"), gp_padl],
	right: [ord("D"), gp_padr],
	up:	   [ord("W"), gp_padu],
	down:  [ord("S"), gp_padd],
	swap:  [ord("K"), gp_face1],
	push:  [ord("L"), gp_shoulderr, gp_shoulderl]
})


rollback_define_player(obj_Swapper);

var _joined = rollback_join_game();

if (!_joined) {
	rollback_create_game(2, true, "North America");	
}

GameState = STATE.BEGIN;
GameStarted = false;

SecondSwitch = false;
Gamestate = -1;
PlayTimer = 0;
SplitSecondCounter = 0;
MoveTickIncrement = 1;
BlinkImage = 0;
DEBUGMODE = false;

SplitSecondCooldown = 12;
SplitSecondCounter = 12;
FlipSecondCooldown = 60;
FlipSecondCounter = 60;
BlinkTimeCooldown = 4;
BlinkTimeCounter = 4;
MoveTickCooldown = 60 * MoveTickIncrement;
MoveTickCounter = 60;

Tilesize = 28;
yBottom = 392;

DifficultyCooldown = (60*60) // 3600
DifficultyCounter = 60*60;

Boards = obj_PlayerBoards;

enum BLOCKTYPE {
	BLANK = 0,
	TRASH = 1,
	RED = 2,
	BLUE = 3,
	GREEN = 4,
	ORANGE = 5,
	PINK = 6
}

enum BLOCKSTATE {
	NULL = 0,
	ACTIVE = 1,
	BLINK = 2,
	DYING = 3,
	DEAD = 4,
	FALLING = 5,
	SWAPPING = 6
}

enum BOARDSTATE {
	STOP = 0,
	GO = 1,
	PUSH = 2
}

enum STATE {
	BEGIN = 1,
	DURING = 2,
	END = 3,
}




