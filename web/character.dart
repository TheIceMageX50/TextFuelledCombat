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
  final int _hpMax;
  int _hpCurrent, _attackPower, _mobility;
  Point<int> _pos;
  
  Character(int hp, int attackPower, int mobility)
  {
    _hpMax = hp;
    
    _attack = attack;
    _mobility = mobility;
  }
  
  attack(Character other)
  {
    other._hpCurrent -= this._attack;
  }
  
  moveTo(int x, int y)
  {
    _pos.x = x;
    _pos.y = y;
  }
}

class CharType<int> extends Enum<int>
{
  const CharType(int val) : super(val);
  
  static const PLAYER = const CharType(0);
  static const ENEMY = const CharType(1);
}
