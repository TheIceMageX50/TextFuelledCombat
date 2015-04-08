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
    ..events.onInputDown.add(onDown)
    ..buttonMode = true;
  return sprite;
}

String rgbToHex(int r, int g, int b)
{
    return "0x" + ((1 << 24) + (r << 16) + (g << 8) + b).toString().substring(1);
}

String getPortraitKey(CharType ct)
{
  switch (ct) {
    case CharType.PLAYER: return 'playerPortrait';
    case CharType.ENEMY: return 'devilPortrait';
    default: throw new Exception('Invalid CharType supplied for getPortraitKey call');
  }
}

Sprite createHpBar(Game game, int x, int y)
{
  BitmapData bmp = game.add.bitmapData(104, 24);
  bmp.draw('hpBar');
  bmp.rect(2, 2, 100, 20, '#00FF00');
  
  return game.add.sprite(x, y, bmp);
}

/**
 * [current] - the current HP of the [Character] in question.
 * [max] - the max HP of the [Character] in question.
 * [currentBar] - The currently displayed HP bar [Sprite]
 */
void redrawHpBar(Game game, Character char)
{
  int percent = ((char._hpCurrent / char._hpMax) * 100).toInt();
  BitmapData bmp = game.add.bitmapData(char.hpBar.width, char.hpBar.height);
  bmp.draw(char.hpBar);
  bmp.rect(2, 2, percent, 20, '#00FF00');
  bmp.rect(2 + percent + 1, 2, 100 - percent, 20, '#000000');
  char.hpBar.loadTexture(bmp);
}

void addAtkButtonTooltip(Game game, Sprite button, String tooltip)
{
  Sprite tooltipSprite;
  
  button.events.onInputOver.add((Sprite sprite, Pointer p) {
    //window.alert('over button!');
    BitmapData bmp = game.make.bitmapData(275, 40);
    bmp.fill(0, 0, 0, 0.5);
    bmp.ctx.setFillColorRgb(255, 255, 255);
    bmp.ctx.fillText(tooltip, 15, bmp.height / 2);
    tooltipSprite = game.add.sprite(button.position.x, button.position.y - 45, bmp);
  });
  
  button.events.onInputOut.add((Sprite sprite, Pointer p) {
    tooltipSprite.destroy();
  });
  
  //without this tooltip will persist if button is clicked.
  button.events.onInputDown.add((Sprite sprite, Pointer p) {
    tooltipSprite.destroy();
  });
}
