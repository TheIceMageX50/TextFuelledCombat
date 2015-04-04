part of TextFueledCombat;

/**
 * Instances of this class are used to represent characters, creatures, etc. both
 * playable and nonplayable.
 */
class Character implements Mover
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
  String _name;
  Point _pos;
  Sprite _sprite, hpBar;
  CharType _type;
  bool _tired;
  bool _hasMoved;
  Map<AttackType, int> _attackCharges;
  List<AttackType> _weaknesses;
  
  static List<AttackType> ALL_TYPES = [AttackType.AIR, AttackType.WATER,
                                       AttackType.FIRE, AttackType.EARTH,
                                       AttackType.SWORD, AttackType.MACE];
  
  String get name => _name;
  Sprite get sprite => _sprite;
  bool get tired => _tired;
  bool get hasMoved => _hasMoved;
  int get hpMax => _hpMax;
  int get hpCurrent => _hpCurrent;
  int get mobility => _mobility;
  CharType get type => _type;
  List<AttackType> get weaknesses => _weaknesses;
  Map<AttackType, int> get attackCharges => _attackCharges;
  Point get pos => _pos;
  
  set tired(bool isTired)
  {
    _tired = isTired;
  }
  
  set hasMoved(bool moved)
  {
    _hasMoved = moved;
  }
  
  Character(String name, CharType type, Point pos)
  {
    _name = name;
    //_pos = new Point(pos.y, pos.x);
    _pos = pos;
    _type = type;
    _tired = false;
    _hasMoved = false;
    _attackCharges = new Map<AttackType, int>();
    _weaknesses = new List<AttackType>();
    
    _attackCharges[AttackType.FIRE] = 0;
    _attackCharges[AttackType.WATER] = 0;
    _attackCharges[AttackType.EARTH] = 0;
    _attackCharges[AttackType.AIR] = 0;
    _attackCharges[AttackType.SWORD] = 0;
    _attackCharges[AttackType.MACE] = 0;
    
    //TODO Set up weaknesses list, most likely depending on CharType
    switch (type) {
      case CharType.PLAYER: 
        _hpMax = 100;
        _hpCurrent = 100;
        _attackPower = 10;
        _mobility = 7;
        _weaknesses.add(AttackType.MACE);
      break;
      case CharType.ENEMY:
        _hpMax = 100;
        _hpCurrent = 100;
        _attackPower = 8;
        _mobility = 7;
        _weaknesses.add(AttackType.WATER);
      break;
      default: throw "Error: Invalid type argument supplied.";
    }
  }
  
  void attack(AttackType atkType, Character other)
  {
    int diffX, diffY, damage;
    diffX = Math.abs(_pos.x - other._pos.x);
    diffY = Math.abs(_pos.y - other._pos.y);
    //window.alert('Trying to attack! points: ${_pos.x},${_pos.y} ${other._pos.x},${other._pos.y} diffs:$diffX $diffY');
    //Attacks are melee-range; using XOR logic requires character to be
    //nondiagonally adjacent to their target to attack.
    if ((diffX == 1 || diffY == 1) && !(diffX == 1 && diffY == 1) && !(diffX > 1 || diffY > 1)) {
      damage = _attackPower;
      if (other._weaknesses.contains(atkType.value)) {
        damage *= WEAKNESS_DMG_MULTIPLIER;
      }
      other._hpCurrent -= damage;
      //window.alert('${other.name} has ${other._hpCurrent} HP left!');
      if (other._hpCurrent <= 0) {
        other._sprite.kill();
      }
      _attackCharges[atkType]--;
      _tired = true;
    } else {
      throw new AttackRangeException('Target out of range!');
    }
  }
  
  void addCharge(int type)
  {
    AttackType attType = ALL_TYPES.firstWhere((AttackType att) {
      return att.value == type;
    });
    if (_attackCharges.containsKey(attType)) {
      _attackCharges[attType]++;
    } else {
      throw new Exception('Invalid AttackType');
    }
  }
  
  bool hasCharge(AttackType at) => _attackCharges[at] > 0;
  
  bool isWeakTo(AttackType type) => _weaknesses.any((AttackType atkType) => atkType == type);
  
  Future<bool> moveTo(int x, int y, GameMap map, Game game, {Pathfinder finder, Path precomputed})
  {
    if (y >= map.width || x >= map.height || x < 0 || y < 0) {
      //out of bounds => error
    } else if (manhattanDist(_pos.x, _pos.y, x, y) > _mobility) {
      //If manhattan distance from current pos to target > mobility then the
      //character certainly can't get there
      // =>error
    } else {
      String blah;
      Path path;
      //Pathfinder should only be used *within* this function iff moving a player char.
      if (finder != null) {
        path = finder.findPath(this, _pos.x, _pos.y, x, y, _mobility.toDouble());
      } else {
        path = precomputed;
      }
      if (path == null) {
        TileType tt = map.whatTile(x, y);
        window.alert("Path blocked! At ($x,$y) there is a tile of type ${tt.value}");
        //for (int a = 0; a < map.height; a++) {
        //  var temp = "";
        //  for (int b = 0; b < map.width; b++) {
        //    bool boolL = map.blocked(null, a, b);
        //    temp += boolL.toString() + " ";
        //  }
        //  print(temp);
        //}
        return null;
      }
      print("Printing path steps...");
      for (int i = 0; i < path.length; i++) {
        print("(${path._steps[i].x},${path._steps[i].y})");
      }
      print("Path End");
      Completer comp = new Completer();
      List<Tween> moveTweens = new List<Tween>();
      for (int i = 0; i < path.length - 1; i++) {
        Point p1 = _gridToWorld(path._steps[i+1]);
        moveTweens.add(
          game.add.tween(_sprite)
            .to({'x' : p1.x, 'y' : p1.y}, 600, Easing.Quadratic.InOut));
      }
      //"Chain" the tweens via onComplete
      for (int i = 0; i < moveTweens.length - 1; i++) {
        moveTweens[i].onComplete.addOnce((_) => moveTweens[i+ 1].start());
      }
      moveTweens.last.onComplete.addOnce((_) => comp.complete(true));
      //start the first tween step
      moveTweens[0].start();
      //unit has moved, blank its previous location in units array
      map._units[_pos.x][_pos.y] = "";
      //set new location
      map._units[x][y] = _name;
      _pos.x = x;
      _pos.y = y;
      _hasMoved = true;
      
      //Don't leave this function until the tweening is done.
      return comp.future;
    }
  }
  
  Point _gridToWorld(Node p) => new Point(p.y * TILE_DIM  + MAP_OFFSETX, p.x * TILE_DIM + MAP_OFFSETY - CHAR_HEIGHT);
  
  initSprite(Game game)
  {
    switch(_type) {
      case CharType.PLAYER: _sprite = game.add
          .sprite(_pos.y * TILE_DIM +MAP_OFFSETX,
                  _pos.x * TILE_DIM + MAP_OFFSETY - CHAR_HEIGHT,
                  'roshan');
      break;
      case CharType.ENEMY: _sprite = game.add
          .sprite(_pos.y * TILE_DIM +MAP_OFFSETX,
                  _pos.x * TILE_DIM + MAP_OFFSETY - CHAR_HEIGHT,
                  'devil');
    }
  }
 
  operator== (Character other) => _name == other._name;
}

class CharType<int> extends Enum<int>
{
  const CharType(int val) : super(val);
  
  static const PLAYER = const CharType(0);
  static const ENEMY = const CharType(1);
}

class AttackType<int> extends Enum<int>
{
  const AttackType(int val) : super(val);
  
  static const TYPE_COUNT = 6;
  
  static const FIRE = const AttackType(0);
  static const WATER = const AttackType(1);
  static const EARTH = const AttackType(2);
  static const AIR = const AttackType(3);
  static const SWORD = const AttackType(4);
  static const MACE = const AttackType(5);
}
