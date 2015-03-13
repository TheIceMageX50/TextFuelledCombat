part of TextFueledCombat;

int manhattanDist(int x1, int y1, int x2, int y2) => Math.abs(x2 - x1) + Math.abs(y2 - y1);

Sprite addGameButton(
  Game game,
  int x,
  int y,
  String key,
  String buttonText,
  InputFunc onDown)
{
  Sprite sprite = new Sprite(game, 50, 50, key);
  BitmapData bmp = game.add.bitmapData(sprite.width, sprite.height);
  bmp.draw(sprite);
  bmp.ctx.fillText(buttonText, bmp.width / 4, bmp.height / 2);
  
  sprite = game.add.sprite(x, y, bmp);
  sprite..inputEnabled = true
    ..events.onInputDown.add(onDown);
  return sprite;
}
