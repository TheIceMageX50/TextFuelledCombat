part of TextFueledCombat;

/**
 * Instances of this class are used to represent characters, creatures, etc. both
 * playable and nonplayable.
 */
class Character
{
  /* TODO split into individual comments?
   * _hp stores the Character's "Hit Points". Reaching 0 HP means that the Character
   * has been defeated.
   * 
   * _attack stores the amount of damage the Character will do upon attacking
   * another.
   * 
   * _mobility means the number of tiles the Character can move over in one turn.
   * Of course, that is assuming moveCost == 1 on all tiles, which is not always
   * true.
   */
  int _hpMax;
  int _hpCurrent, _attackPower, _mobility;
  Point _pos;
  Sprite _sprite;
  CharType _type;
  
  //REMOVER GETTER, 
  Sprite get sprite => _sprite;
  set sprite(Sprite sprite)
  {
    _sprite = sprite;
  }
  
  Character(CharType type, Point pos)
  {
    _pos = pos;
    _type = type;
    
    switch (type) {
      case CharType.PLAYER: 
        _hpMax = 100;
        _attackPower = 10;
        _mobility = 7;
      break;
      default: throw "Error: Invalid type argument supplied.";
    }
  }
  
  attack(Character other)
  {
    other._hpCurrent -= this._attackPower;
  }
  
  moveTo(int x, int y, GameMap map, Game game)
  {
    if (x < map.width && y < map.height && x >= 0 && y >= 0) {
      _pos.x = x;
      _pos.y = y;
    } else {
      //What are you doing? You can't move off the map...
    }
  }
  
  initSprite(Game game)
  {
    switch(_type) {
      //32x32 are tile dimensions, 46 is height of sprite
      case CharType.PLAYER: _sprite = game.add.sprite(_pos.x * 32 + 96, _pos.y * 32 + 64 - 46, 'roshan');
      break;
    }
  }
}

class CharType<int> extends Enum<int>
{
  const CharType(int val) : super(val);
  
  static const PLAYER = const CharType(0);
  static const ENEMY = const CharType(1);
}
