/// @description DRAW SWAPPER

draw_sprite(sprite_index, image_index, x, y-MyTicks);


if (Game.DEBUGMODE) {
	draw_set_font(fnt_Small);
	var _mrg = Game.Tilesize div 4;
	for (var c = 0; c < 6; c++) {
		for (var r = 1; r < 13; r++) {
			var _this = MySpots[# c,r];
			draw_set_color(c_white);
			draw_set_alpha(1.0)
			draw_text(_this.x + _mrg, _this.y + _mrg, string(_this.xspot) + "," + string(_this.yspot));
			draw_set_color(c_gray);
			draw_set_alpha(0.50)
			draw_rectangle(_this.x, _this.y, _this.x + Game.Tilesize, _this.y + Game.Tilesize, false);
		}
	}

}