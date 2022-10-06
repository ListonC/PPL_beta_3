/// @description Init vars

// taco salads

Mask = spr_BlockMask;
Game = obj_GameManager;

P1BoardState = BOARDSTATE.STOP;
P2BoardState = BOARDSTATE.STOP;
P1Ticks = 0;
P2Ticks = 0;

P1Grid = ds_grid_create(6,25);
P2Grid = ds_grid_create(6,25);

P1Swapper = noone;
P2Swapper = noone;

P1xMargin = 28;
P2xMargin = 616;

ListFall = ds_list_create();
ListMatch = ds_list_create();
ListRooks = ds_list_create();
ListChunkResolve = ds_list_create();
ListTrash = ds_list_create();
ListBlinks = ds_list_create();
ListSwaps = ds_list_create();
ListDying = ds_list_create();
ListScrolls = ds_list_create();
FallsNeeded = false;

TrashChunks = ds_list_create();
TrashSide = 0; // dump trash on left or right.
TotalBlinks = 0;
ScrollSpawnBlock = noone;
ScrollSpawnChain = noone;
ChainCount = 0;

DebugLoops = 0;

ListColors = ds_list_create();
ColorCounter = 0;

ListColors[| 0] = BLOCKTYPE.BLUE;
ListColors[| 1] = BLOCKTYPE.GREEN;
ListColors[| 2] = BLOCKTYPE.ORANGE;
ListColors[| 3] = BLOCKTYPE.PINK;
ListColors[| 4] = BLOCKTYPE.RED;

function FetchColor() {
	ColorCounter += 1;
	if (ColorCounter > 4) {
		ColorCounter = 0;	
	}
	ColorCounter = clamp(ColorCounter, 0, 4) // probably unneccessary, but just in case...
	
	return ListColors[| ColorCounter];
}

function SpawnBlock(_type, x_slot, y_slot) constructor 
{
	type  = _type;
	xSlot = x_slot;
	ySlot = y_slot;
	state = BLOCKSTATE.NULL;
	isNervous = false;
	imageframe = 1;
	blinks = 40;
	chain = 0;
	x = 0;
	xOrigin = 0;
	xTarget = 0;
	y = 0;
	yOrigin = 0;
	yTarget = 0;
	progress = 0;
	myChunk = noone;
	isMatched = false;
	wasConsidered = false;
	dyingtime = 0;
	ministep = function(_id)
			   { 
					if (type == BLOCKTYPE.BLANK) {
						exit;   
					}
					if (dyingtime <= 0 and state != BLOCKSTATE.DYING) {
						exit;	
					}
					if (dyingtime > 0) {
						dyingtime -= 1;	
					}
					if (dyingtime <= 0 and state == BLOCKSTATE.DYING) {
						state = BLOCKSTATE.DEAD;
						var _spot = ds_list_find_index(_id.ListDying, self);
						ds_list_delete(_id.ListDying, _spot);
					}
			   }
}

// ResolveMatches
function SpawnScroll(_ischain, _integer, _yspot, _xspot, _id) constructor {
	// need the id to cheat the obj_Playerboard function use.
	Control = _id
	isChain = _ischain; // there are only two types, so a bool is used here
	myNumber = _integer;
	y = Control.GetYTarget(_yspot);
	x = Control.GetXTarget(_xspot);
	Lifespan = 180;
	ColorOne = COL_TEL2;
	ColorTwo = COL_TEL3;
	MyColor = c_white;
	if (_ischain) {
		ColorOne = COL_RED2;
		ColorTwo = COL_RED3;
	}
}


// Gotta provide some colored blocks to start with
for (var i = 0; i < 6; i++) {
	for (var j =0; j <= 24; j++) {
		var _ty = BLOCKTYPE.BLANK; // _ty means Type
		if (j < 4) {
			_ty = FetchColor();
		}
		P1Grid[# i,j] = new SpawnBlock(_ty, i, j);
		P2Grid[# i,j] = new SpawnBlock(_ty, i, j);
	}
}

// SwapMovement, FallMovement, PromoteBlocks
function CheckForMatch(_grid, _block) {
 
	// Block-centric approach.
	// imagine a "rook" on a chess board. It moves left as long as there are matches.
	// when it can't move left anymore/no match, it counts number of moves+origin block. Then
	// it moves to the right until there are no matches, and adds the number of moves. 
	// if moves+origin is 3 or more, then isMatch for each of those blocks is Yes.
	// Repeat this process downwards and then upwards. 

	if (_block.state == BLOCKSTATE.NULL or _block.type == BLOCKTYPE.BLANK) {
		exit;	
	}
	
	if (_block.wasConsidered) {
		exit;	
	}
	
	
	TotalMatches = 0;
	SmallMatches = 0;
	HorizontalThree = false;
	VerticalThree = false;
	var Rook = {
		leftsteps : 1, // we start at 1 because the origin block is counted in a match
		downsteps : 1,
		rightsteps: 1,
		upsteps   : 1,
		type      : _block.type
	}
	
	// First, left-direction.
	if (_block.xSlot > 0) {
		
		for (var _walk = _block.xSlot; _walk > 0; _walk--) {
			var _next = _grid[# _walk-1, _block.ySlot];
			if (_next.state != BLOCKSTATE.ACTIVE or _next.type != _block.type) {
				break;	// block is not eligble for matches, get out.
			} else if (_next.type == _block.type) {
				// we have a match.
				Rook.leftsteps += 1;
			}
		}
		if (Rook.leftsteps > 2) {
			TotalMatches += 1;	
		} else if (Rook.leftsteps == 2) {
			SmallMatches += 1;
		}
	}
	// Then, walk to the right.
	if (_block.xSlot < 5) {
			
		for (var _walk = _block.xSlot; _walk < 5; _walk++) {
			var _next = _grid[# _walk+1, _block.ySlot];
			if (_next.state != BLOCKSTATE.ACTIVE or _next.type != _block.type) {
				break;
			} else if (_next.type == _block.type) {
				Rook.rightsteps += 1;
			}
		}
		if (Rook.rightsteps > 2) {
			TotalMatches += 1;	
		} else if (Rook.rightsteps == 2) {
			SmallMatches += 1;	
		}
	}
	
	// this is a concession for middle blocks in a trio of blocks.
	if (SmallMatches == 2) {
		HorizontalThree = true;
		SmallMatches = 0;
	} else {
		SmallMatches = 0;
	}
	
	
	// Then, walk downwards.
	if (_block.ySlot > 1) {
		
		for (var _walk = _block.ySlot; _walk > 0; _walk--) {
			var _next = _grid[# _block.xSlot, _walk-1];
			if (_next.state != BLOCKSTATE.ACTIVE or _next.type != _block.type) {
				break;	
			} else if (_next.type == _block.type) {
				Rook.downsteps += 1;
			}
		}
		if (Rook.downsteps > 2) {
			TotalMatches += 1;	
		} else if (Rook.downsteps == 2) {
			SmallMatches += 1;
		}
	}
	
	//Then walk upwards
	if (_block.ySlot < 12) {
		
		for (var _walk = _block.ySlot; _walk < 12; _walk++) {
			var _next = _grid[# _block.xSlot, _walk+1];
			if (_next.state != BLOCKSTATE.ACTIVE or _next.type != _block.type) {
				break;	
			} else if (_next.type == _block.type) {
				Rook.upsteps += 1;	
			}
		}
		if (Rook.upsteps > 2) {
			TotalMatches += 1;
		} else if (Rook.upsteps == 2) {
			SmallMatches += 1;
		}
	}
	
	if (SmallMatches == 2) {
		VerticalThree = true;
		SmallMatches = 0;
	}
	
	// Was there a match?
	if (TotalMatches == 0 and HorizontalThree == false and VerticalThree == false) {
		exit;
	} 
	
	if (TotalMatches > 0){
		_block.isMatched = true; // origin block is match
		_block.wasConsidered = true; // origin block ran this function
		ds_list_add(ListMatch, _block); // add to the list of blocks to die
		// Now, we gotta set the rest of the blocks to isMatched
		// and if necessary, branch from them as well.
		if (Rook.leftsteps > 2) {
			for (var step = 1; step < Rook.leftsteps; step++) {
				var _next = _grid[# _block.xSlot-step, _block.ySlot];
				_next.isMatched = true;
				if (_next.wasConsidered == false) { // have we not ran this function on this block?
					CheckForMatch(_grid, _next);	// run a search with this block, too.
				} // this block will eventually be wasConsidered = true.
			}
		}
		if (Rook.downsteps > 2) {
			for (var step = 1; step < Rook.downsteps; step++) {
				var _next = _grid[# _block.xSlot, _block.ySlot-step];
				_next.isMatched = true;
				if (_next.wasConsidered == false) {
					CheckForMatch(_grid, _next);
				}
			}
		}
		if (Rook.rightsteps > 2) {
			for (var step = 1; step < Rook.rightsteps; step++) {
				var _next = _grid[# _block.xSlot+step, _block.ySlot];
				_next.isMatched = true;
				if (_next.wasConsidered == false) {
					CheckForMatch(_grid, _next);
				}
			}
		}
		if (Rook.upsteps > 2) {
			for (var step = 1; step < Rook.upsteps; step++) {
				var _next = _grid[# _block.xSlot, _block.ySlot+step];
				_next.isMatched = true;
				if (_next.wasConsidered == false) {
					CheckForMatch(_grid, _next);
				}
			}
		}
	ds_list_add(ListRooks, Rook);
	}
	
	if (HorizontalThree) {
		_block.isMatched = true;
		_block.wasConsidered = true;
		ds_list_add(ListMatch, _block);
		if (_block.xSlot > 0) {
			var _leftblock = _grid[# _block.xSlot-1, _block.ySlot];
			_leftblock.isMatched = true;
			if (_leftblock.wasConsidered == false) {
				CheckForMatch(_grid, _leftblock);
			}
		}
		if (_block.xSlot < 5) {
			var _rightblock = _grid[# _block.xSlot+1, _block.ySlot];
			_rightblock.isMatched = true;
			if (_rightblock.wasConsidered == false) {
				CheckForMatch(_grid, _rightblock);	
			}
		}
	}

	if (VerticalThree) {
		_block.isMatched = true;
		_block.wasConsidered = true;
		ds_list_add(ListMatch, _block);
		if (_block.ySlot > 1) {
			var _downblock = _grid[# _block.xSlot, _block.ySlot-1];
			_downblock.isMatched = true;
			if (_downblock.wasConsidered == false) {
				CheckForMatch(_grid, _downblock);
			}
		}
		if (_block.ySlot < 12) {
			var _upblock = _grid[# _block.xSlot, _block.ySlot+1];
			_upblock.isMatched = true;
			if (_upblock.wasConsidered == false) {
				CheckForMatch(_grid, _upblock);	
			}
		}
	}
}


function PromoteBlocks(_player) {
		var _grid;
		// promote the color blocks
		// reset the ticks
		if (_player == 0) { // player one
			P1Ticks = 0;
			_grid = P1Grid;
			if (P1Swapper.MySpot.yspot < 12) {
					MySpot = MySpots[# MySpot.xspot, MySpot.yspot + 1]	
				}
			}
		if (_player == 1) { // player two
			P2Ticks = 0;
			_grid = P2Grid;
			if (P2Swapper.MySpot.yspot < 12) {
						MySpot = MySpots[# MySpot.xspot, MySpot.yspot + 1]	
			}			
		}
	
	// move all blocks 'up' one y_slot
	// delete the top row
	// spawn new row at bottom.
	// shuffle the bottom row
	// reset TickStep
	
	// have to delete top row first
	for (var i = 0; i < 6; i++) {
		var _block = _grid[# i, 24];
		if (is_struct(_block)) {
			delete _block;
		}
	}	
	// time to promote all blocks upwards
	for (var i = 0; i < 6; i++) {
		for (var j = 23; j >= 0; j--) { // we have to start from the top
			var _block = _grid[# i,j];
			_block.ySlot += 1;
			if (j == 0 and _block.state == BLOCKSTATE.NULL) {
				_block.state = BLOCKSTATE.ACTIVE;
			}
			_grid[# i,j+1] = _block; 
			if (_block.state == BLOCKSTATE.ACTIVE and
			    _block.type != BLOCKTYPE.TRASH and
				_block.type != BLOCKTYPE.BLANK) {
					if (j > 9 and j < 13) {
						_block.isNervous = true;	
					} else {
						_block.isNervous = false;	
					}
				}
		}
	}	
	// time to spawn blocks at bottom row
	for (var i = 0; i < 6; i++) {
		//now I gotta spawn a new block...
		var _ty = FetchColor();
		_grid[# i,0] = new SpawnBlock(_ty, i, 0)
		_grid[# i,0].state = BLOCKSTATE.NULL;
	}
	// need to shuffle the bottom row to make sure
	// there aren't any premature matches
	for (var i = 1; i < 6; i++) { // we start at 2nd slot, '1'
		// only need to check to the left.
		var _up = _grid[# i, 1];
		var _this = _grid[# i,0];
		while (_up.type == _this.type) {
			_this.type = FetchColor();
		}
	}
	
	// Now, we need to run a CheckForMatch on the newly promoted Row 1
	for (var i = 0; i < 6; i++) {
		var _check = _grid[# i, 1];
		CheckForMatch(_grid, _check);
	}	
}

function PlaceBlocks() {
	for (var i = 0; i < 6; i++) {
		for (var j =0; j < 24; j++) {
			var _block = P1Grid[# i, j];
			if (_block.state != BLOCKSTATE.SWAPPING or 
				_block.state != BLOCKSTATE.FALLING)
				_block.x = P1xMargin + (i * Game.Tilesize);
				_block.y = yMargin - (j * Game.Tilesize) - P1Ticks;
				if (_block.type == BLOCKTYPE.BLANK) {
					_block.state = BLOCKSTATE.ACTIVE; // need this so we can swap blanks.	
				}
				if (_block.ySlot < 10) {
					_block.isNervous = false;	
				}
			var _block = P2Grid[# i, j];
			if (_block.state != BLOCKSTATE.SWAPPING or 
				_block.state != BLOCKSTATE.FALLING)
				_block.x = P2xMargin + (i * Game.Tilesize);
				_block.y = yMargin - (j * Game.Tilesize) - P2Ticks;
				if (_block.type == BLOCKTYPE.BLANK) {
					_block.state = BLOCKSTATE.ACTIVE; // need this so we can swap blanks.	
				}
				if (_block.ySlot < 10) {
					_block.isNervous = false;	
				}
		}
	}
}

function PlaceScrolls() {
	if (ds_list_empty(ListScrolls)) {
		exit;	
	}
	
	for (var s = 0; s < ds_list_size(ListScrolls); s++) {
		var _scroll = ListScrolls[| s];	
		if (_scroll.Lifespan <= 0) {
			ds_list_delete(ListScrolls, s);
			delete _scroll;
			exit;
		}
		_scroll.Lifespan -= 1;
		_scroll.y -= 0.25;
		_scroll.y = clamp(_scroll.y, 30, 360);
		if (Game.BlinkImage) {
			_scroll.MyColor = _scroll.ColorOne;
		} else {
			_scroll.MyColor = _scroll.ColorTwo;	
		}
	}
}

// SwapMovement
function GetXTarget(x_slot) {
	// Used by SwapBlock function
	return xMargin + (x_slot * Game.Tilesize)
}

// FallMovement
function GetYTarget(y_slot) {
	return yMargin - (y_slot * Game.Tilesize) - TickStep // 364 - X * 28;
}

// Begin Step
function SwapMovement(_grid, _block) {
	if (_block.state == BLOCKSTATE.SWAPPING and _block.progress < 1) {
		var _distance = _block.x - _block.xTarget;
		var _direction = _block.xOrigin - _block.xTarget;
		if (_distance < 1) {
			_block.x = _block.xTarget;
			_block.state = BLOCKSTATE.ACTIVE;
			_block.progress = 0;
			var _spot = ds_list_find_index(ListSwaps, _block);
			ds_list_delete(ListSwaps, _spot);
			CheckForMatch(_grid, _block);
			exit;
		}
	
		var _channel = animcurve_get_channel(ac_Swap, 0);
		if (_direction < 0) { // we need to move right
			_block.x += Game.Tilesize * (animcurve_channel_evaluate(_channel, _block.progress));	
		} else if (_direction > 0) {// we need to move left
			_block.x -= Game.Tilesize * (animcurve_channel_evaluate(_channel, _block.progress));
		}
		_block.progress += 0.10; // should complete transition in ten frames
		_block.progress = clamp(_block.progress, 0, 1); // probably unecessary, but just in case		
	}
}

// TickTimer, SwapBlock
function FallCheck(_grid) {
	// purpose: find eligible blocks with blanks underneath 
	// and change their status to FALLING
	for (var i = 0; i < 6; i++) {
		for (var j = 2; j < 24; j++) {
			// we don't need to check 0 because it will always
			// have a solid block underneath. We can skip 1 similarly
			// but we will check if 1 is blank.
			var _this = _grid[# i, j];
			var _under = _grid[# i, j-1];
			
			if (_under.type == BLOCKTYPE.BLANK) { // no underneath block?
				// need to make sure the top block isn't blank
				// or trash. Trash blocks are special and need 
				// to fall down together as Chunks.
				if (_this.type != BLOCKTYPE.TRASH and
					_this.type != BLOCKTYPE.BLANK) {
						// is the block ACTIVE ie not swapping, dying, falling etc
						if (_this.state == BLOCKSTATE.ACTIVE) {
							_this.state = BLOCKSTATE.FALLING;
							ds_list_add(ListFall, _this);
							FallsNeeded = true;
						}				
					}
				// Now, to determine if a Trash Chunk needs to fall.
				if (_this.type == BLOCKTYPE.TRASH and _this.state == BLOCKSTATE.ACTIVE) {
					// we need to unpack this ds_list and check below each.
					// this method will lead to redundancy but it's all I can think of
					var _list = _this.myChunk;
					var _width = _list[| ds_list_size(_list)-2]
					
					var _clear = true;
					// now unpack _list and check under each block
					for (var c = 0; c < ds_list_size(_list)-2; c++) {
						var _trashblock = _list[| c];
						var _under = _grid[# _trashblock.xSlot, _trashblock.ySlot-1];
						if (_under.type != BLOCKTYPE.BLANK) {
							_clear = false;
							break; // no need to test the other blocks.
						}
					}
					
					if (_clear) { // everything under the trash chunk is blank
						for (var c = 0; c < ds_list_size(_list)-2; c++) {
							var _trashblock = _list[| c];
							_trashblock.state = BLOCKSTATE.FALLING;
							ds_list_add(ListFall, _trashblock);
							FallsNeeded = true;
						}
					}
				}
			}
		}
	}
}

// FallMovement
function ResolveChains() {
	if (ChainCount < 1) {
		exit;	
	}
	
	var _cc = ChainCount;
	_cc = clamp(_cc, 1, 12);
	var _scroll = new SpawnScroll(true, _cc, ScrollSpawnChain.ySlot, ScrollSpawnChain.xSlot, id);
	ds_list_add(ListScrolls, _scroll);
	
}

// Begin Step
function FallMovement(_grid, _block) {
	// _block is falling.
	// we just need to swap the 1 blank block underneath.
	// first we swap the ySlots between the two.
	// then we set the yOrigin and yTarget
	// then we place the y of each using ac_BlockFall
	// when the distance between yOrigin and yTarget is 0...
	// we need to check to see if the next block below is BLANK
	// and if so, start the whole process over again.
	// if not, we change block status to ACTIVE and remove it 
	// from the ListFall ds_list
	
	var _y = _block.ySlot;
	var _under = 0;
	if (_y > 0) {
		_under = _grid[# _block.xSlot, _y-1];
	}
	// NOTE: We shouldn't swap if the bottom block is not a blank, but movement progress needs to be made.

	if (is_struct(_under)) {
		if (_under.type == BLOCKTYPE.BLANK) {
			if (_block.progress == 0) { // don't do this if progress isn't 0 because it means the block is travelling
				// set up the temps to swap to.
				var temp_block = _block.ySlot;
				var temp_under = _under.ySlot;
		
				// swap the ySlots.
				_block.ySlot = temp_under;
				_under.ySlot = temp_block;
		
				// set the yOrigin
				_block.yOrigin = _block.y;
				_under.yOrigin = _under.y;
		
				// set the yTarget
				_block.yTarget = GetYTarget(_block.ySlot);
				_under.y = GetYTarget(_under.ySlot); // this block is BLANK and should teleport
				
				// Update the Grid
				_grid[# _block.xSlot, _block.ySlot] = _block;
				_grid[# _under.xSlot, _under.ySlot] = _under;
				
			}
		}
	}
	// Next, we have to determine how much _block has travelled, if at all
	var _target = GetYTarget(_block.ySlot);
	var _distance = _block.y - _target; // for some reason, this is returning -33 at the start.
	
	_distance = clamp(_distance, -28, 0);
	_distance = floor(_distance);
	if (_distance == 0) { // the journey is complete
		// before we reset anything, we need to check what's underneath 
		// _block again. If it's another BLANK, we need to restart the whole process.
		if (_block.ySlot > 0) {
			var _next = _grid[# _block.xSlot, _block.ySlot - 1];
			if (_next.type == BLOCKTYPE.BLANK) {
				// we should fall another block.
				_block.progress = 0; // thus the starting If() runs again.
			} else if (_next.type != BLOCKTYPE.BLANK) {
				// we need to reset this block and remove it from the list.
				_block.progress = 0;
				_block.state = BLOCKSTATE.ACTIVE;
				CheckForMatch(_block);
				if (_block.isMatched == true) {
					ChainCount += 1;
					ScrollSpawnChain = _block;
					ResolveChains();
				}
				
				var spot = ds_list_find_index(ListFall, _block);
				ds_list_delete(ListFall, spot);
				
				// when this list is Empty, it means nothing is falling anymore.
			}
		}
		
	} else if (_distance < 0) { // this number should always start out at -28
		var _channel = animcurve_get_channel(ac_BlockFall, 0);
		_block.y += Game.Tilesize * (animcurve_channel_evaluate(_channel, _block.progress))
			
		_block.progress += 0.10;
		_block.progress = clamp(_block.progress, 0, 1); // again, probably uneccsary
	}
	if (_block.progress >= 1) {
		_block.y = GetYTarget(_block.ySlot);	
	}
}
	
// End Step
function SpecialScore() {
	// just check single rooks
	for (var L = 0; L < ds_list_size(ListRooks); L++) {
		var _rook = ListRooks[| L];
		var str = string(_rook);
		
		switch (str) {
			case Game.RedCross:
				show_debug_message("You got the red cross!")
				// Do the special stuff later
			break;
			
			case Game.GoldCrux:
				show_debug_message("You got the gold crucifix!")
				// Do the special stuff later
			break;
			
			default:
				// show_debug_message("Nothing special.");
			break;
		}
	}
}	

// Alarm 1, in ResolveMatches
function ResolveCombos() {
	if (TotalBlinks < 4) { // only 3?
		TotalBlinks = 0;
		exit;
	}
	var _blinks = TotalBlinks-1;
	_blinks = clamp(_blinks, 3, 12);
	var _scroll = new SpawnScroll(false, _blinks, ScrollSpawnBlock.ySlot, ScrollSpawnBlock.xSlot, id);
	ds_list_add(ListScrolls, _scroll);	
	TotalBlinks = 0;
}

// End Step
function ResolveMatches(_grid) {
	// There are matches in ListMatch
	// We need to unpack that List and mark each block state as BLINK
	// If any of those blocks is adjacent to a Trash block, then 
	// we need to add that Chunk to a ResolveGarbage list. 
	
	// In order to count Combos of more than 1 color type
	// we need to tally the ListMatch here in the End Step and resolve the 
	// Combos in the Begin Step
	TotalBlinks += ds_list_size(ListMatch);
	StopFrames += (ds_list_size(ListMatch) * 22);
	StopFrames = clamp(StopFrames, 0, 100);
	alarm_set(1,8);
	
	
	if (ds_list_size(ListMatch) > 3) {
		for(var r = 0; r < ds_list_size(ListMatch)-1; r++) {
			if (ScrollSpawnBlock == noone) {
				ScrollSpawnBlock = ListMatch[| 0];
				ScrollSpawnChain = ListMatch[| 1];
			}
			// which number is biggest.
			var _a = ListMatch[| r].ySlot;
			var _b = ListMatch[| r+1].ySlot;
			
			if (_b > _a) {
				ScrollSpawnBlock = ListMatch[| r+1];
				ScrollSpawnChain = ListMatch[| r];
			} else {
				ScrollSpawnBlock = ListMatch[| r];
				ScrollSpawnChain = ListMatch[| r+1]
			}
		}
	}
	
	for (var i = 0; i < ds_list_size(ListMatch); i++) {
		var _this = ListMatch[| i];
		_this.state = BLOCKSTATE.BLINK;
		ds_list_add(ListBlinks, _this);
		var _left, _down, _right, _up;
		if (_this.xSlot > 0) { // what is left of us?
			_left = _grid[# _this.xSlot-1, _this.ySlot];
			if (_left.type == BLOCKTYPE.TRASH) { // is it garbage?
				// we need to add the chunk to a list
				var _chunk = _left.myChunk;
				// we need to make sure we haven't already done this.
				if (ds_list_find_index(ListTrash, _chunk)) {
					ds_list_add(ListChunkResolve, _chunk);
					// gotta remove the Trash we just added to the Resolve list
					// we don't want two of the same references floating around
					var _entry = ds_list_find_index(ListTrash, _chunk);
					ds_list_delete(ListTrash, _entry);
				}
			}
		}
		if (_this.ySlot > 0) { // what is under us?
			_down = _grid[# _this.xSlot, _this.ySlot-1];
			if (_down.type == BLOCKTYPE.TRASH) { // is it garbage?
				// we need to add the chunk to a list
				var _chunk = _down.myChunk;
				// we need to make sure we haven't already done this.
				if (ds_list_find_index(ListTrash, _chunk)) {
					ds_list_add(ListChunkResolve, _chunk);

					var _entry = ds_list_find_index(ListTrash, _chunk);
					ds_list_delete(ListTrash, _entry);
				}
			}
		}
		if (_this.xSlot < 5) { // what is right of us?
			_right = _grid[# _this.xSlot+1, _this.ySlot];
			if (_right.type == BLOCKTYPE.TRASH) { // is it garbage?
				// we need to add the chunk to a list
				var _chunk = _right.myChunk;
				// we need to make sure we haven't already done this.
				if (ds_list_find_index(ListTrash, _chunk)) {
					ds_list_add(ListChunkResolve, _chunk);
					
					var _entry = ds_list_find_index(ListTrash, _chunk);
					ds_list_delete(ListTrash, _entry);
				}
			}
		}
		if (_this.ySlot < 12) { // what is above us?
			_up = _grid[# _this.xSlot, _this.ySlot+1];
			if (_up.type == BLOCKTYPE.TRASH) { // is it garbage?
				// we need to add the chunk to a list
				var _chunk = _up.myChunk;
				// we need to make sure we haven't already done this.
				if (ds_list_find_index(ListTrash, _chunk)) {
					ds_list_add(ListChunkResolve, _chunk);
					
					var _entry = ds_list_find_index(ListTrash, _chunk);
					ds_list_delete(ListTrash, _entry);
				}
			}
		}		
	}
	ds_list_clear(ListMatch);
	// Now all of our matched blocks are BLINK status
	// And any adjacent trash has been moved to ListChunkResolve
}

// End Step
function ResolveBlinks() {
	// Unpack the list of Blinking blocks
	// set ImageFrame to G.BlinkTimer
	// Reduce blinks by 1
	// If blinks reaches 0, set state to DYING and
	// remove from ListBlinks
	
	for (var i = 0; i < ds_list_size(ListBlinks); i++) {
		var _block = ds_list_find_value(ListBlinks, i);
		if (_block.blinks > 0) {
			_block.blinks -= 2;
			_block.imageframe = Game.BlinkImage;
		}
		if (_block.blinks <= 0) {
			_block.state = BLOCKSTATE.DYING;
			_block.blinks = 40;
			_block.imageframe = 2;
			_block.wasConsidered = false;
			_block.isMatched = false;
			ds_list_add(ListDying, _block);
			var _spot = ds_list_find_index(ListBlinks, _block);
			ds_list_delete(ListBlinks, _spot);
		}
	}
}
	
// End Step
function ResolveDying(_grid) {
	// iterate at 1
	// Run for loops covering the play field
	// if the block is Dying, create a callback function
	// where, once activated, the block status is changed to DEAD
	// create a new timesource that activates just once, and takes
	// the iter * spot in the for loop for number of frames
	
	
	for (var r = 12; r >= 1; r--) {
		for (var c = 0; c < 6; c++) {
			var _block = _grid[# c, r];
			if (_block.state == BLOCKSTATE.DYING and _block.wasConsidered == false) {
				_block.dyingtime = 1 + (_block.xSlot + _block.ySlot) * 10;
				_block.wasConsidered = true;
			}
		}
	}
}
	
// End Step
function DestinedDeath(_grid) {
	// search the playfield for block state DEAD
	// check the block's imageframes, if less than 7, increment 1
	// if 7 or more, convert block to Blank and ACTIVE status.
	
	for (var r = 13; r > 0; r--) {
		for (var c = 0; c < 6; c++) {
			var _this = _grid[# c, r];
			if (_this.state == BLOCKSTATE.DEAD) {
				if (ds_list_size(ListDying) > 0) {
					var _spot = ds_list_find_index(ListDying, _this);
					if (_spot > -1) {
						ds_list_delete(ListDying, _spot);	
					}		
				}
				if (_this.imageframe < 8) {
					_this.imageframe += 0.10;	
				} else {
					// we need to convert this block.
					if (_this.type != BLOCKTYPE.TRASH) {
						_this.state = BLOCKSTATE.ACTIVE;
						_this.type = BLOCKTYPE.BLANK;
					}
				}
			}
		}
	}
}
	
PlaceBlocks();