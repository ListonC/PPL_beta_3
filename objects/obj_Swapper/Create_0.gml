/// @description Insert description here
// You can write your code in this editor

Game = obj_GameManager;
Grid = noone;
Boards = obj_PlayerBoards;
IsPlayerOne = true;

if (player_id == 0) {
	Grid = Boards.P1Grid;
	IsPlayerOne = true;
	Boards.P1Swapper = id;
} else if (player_id == 1) {
	Grid = Boards.P2Grid;
	IsPlayerOne = false;
	Boards.P2Swapper = id;
}

function SpawnVector(_x, _y, _size, _bottom, _margin) constructor {
	x = _margin + (_x * _size);
	y = _bottom - (_y * _size);
	xspot = _x;
	yspot = _y;
}

MySpots = ds_grid_create(6,13);
var _bot = Game.yBottom - Game.Tilesize;
for (var c = 0; c < 6; c++) {
	for (var r = 1; r < 13; r ++) {
		if (IsPlayerOne) {
			MySpots[# c, r] = new SpawnVector(c,r, Game.Tilesize, _bot, Boards.P1xMargin);
		} else {
			MySpots[# c, r] = new SpawnVector(c,r, Game.Tilesize, _bot, Boards.P2xMargin);	
		}
	}
}

MySpot = MySpots[# 3,3];
MyTicks = 0;
CanMove = true;
CanSwap = false;
MoveCool = 10;
x = MySpot.x;
y = MySpot.y;


//Functions
function MoveLeft() {
	if (!CanMove) { exit; } // don't bother if the cooldown hasn't happened
	
	if (MySpot.xspot > 0) {
		var _x = MySpot.xspot - 1;
		var _y = MySpot.yspot;
		MySpot = MySpots[# _x, _y];
		x = MySpot.x;
		y = MySpot.y;
	} else { exit; } // don't execute those two lines below.
	CanMove = false;
	alarm_set(0, MoveCool);
}

function MoveRight() {
	if (!CanMove) { exit; } // don't bother if the cooldown hasn't happened
	
	if (MySpot.xspot < 4) { // the swapper is two-tiles wide, gotta stop at 5
		var _x = MySpot.xspot + 1;
		var _y = MySpot.yspot;
		MySpot = MySpots[# _x, _y];
		x = MySpot.x;
		y = MySpot.y;		
	} else { exit; } // don't execute those two lines below.
	CanMove = false;
	alarm_set(0, MoveCool);
}

function MoveUp() {
	if (!CanMove) { exit; } // don't bother if the cooldown hasn't happened
	
	if (MySpot.yspot < 12) {
		var _x = MySpot.xspot;
		var _y = MySpot.yspot + 1;
		MySpot = MySpots[# _x, _y];
		x = MySpot.x;
		y = MySpot.y;			
	} else { exit; } // don't execute those two lines below.
	CanMove = false;
	alarm_set(0, MoveCool);
}

function MoveDown() {
	if (!CanMove) { exit; } // don't bother if the cooldown hasn't happened
	
	if (MySpot.yspot > 1) {
		var _x = MySpot.xspot;
		var _y = MySpot.yspot - 1;
		MySpot = MySpots[# _x, _y];
		x = MySpot.x;
		y = MySpot.y;			
	} else { exit; } // don't execute those two lines below.
	CanMove = false;
	alarm_set(0, MoveCool);
}

// Begin Step
function PushBlock() {
	if (IsPlayerOne) {
		if (Boards.P1BoardState != BOARDSTATE.STOP) {
			Boards.P1BoardState = BOARDSTATE.PUSH;
		}
	} else {
		if (Boards.P2BoardState != BOARDSTATE.STOP) {
			Boards.P2BoardState = BOARDSTATE.PUSH	
		}
	}
}

// Begin Step
function ReleasePush() {
	
	// deal with this later.
}

// Step
function SwapBlock(_block) {
	if (!CanSwap) { exit; } // Don't bother if you can't move yet.
	
}