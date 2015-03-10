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
  Sprite _sprite;
  CharType _type;
  bool _tired;
  
  String get name => _name;
  Sprite get sprite => _sprite;
  bool get tired => _tired;
  int get hpMax => _hpMax;
  int get hpCurrent => _hpCurrent;
  int get mobility => _mobility;
  Point get pos => _pos;
  
  set tired(bool isTired)
  {
    _tired = isTired;
  }
  
  Character(String name, CharType type, Point pos)
  {
    _name = name;
    //_pos = new Point(pos.y, pos.x);
    _pos = pos;
    _type = type;
    _tired = false;
    
    switch (type) {
      case CharType.PLAYER: 
        _hpMax = 100;
        _hpCurrent = 100;
        _attackPower = 10;
        _mobility = 7;
      break;
      case CharType.ENEMY:
        _hpMax = 100;
        _hpCurrent = 100;
        _attackPower = 8;
        _mobility = 7;
      break;
      default: throw "Error: Invalid type argument supplied.";
    }
  }
  
  void attack(Character other)
  {
    int diffX, diffY;
    diffX = Math.abs(_pos.x - other._pos.x);
    diffY = Math.abs(_pos.y - other._pos.y);
    //window.alert('Trying to attack! points: ${_pos.x},${_pos.y} ${other._pos.x},${other._pos.y} diffs:$diffX $diffY');
    //Attacks are melee-range; using XOR logic requires character to be
    //nondiagonally adjacent to their target to attack.
    if ((diffX == 1 || diffY == 1) && !(diffX == 1 && diffY == 1)) {
      other._hpCurrent -= this._attackPower;
      window.alert('${other.name} has ${other._hpCurrent} HP left!');
      if (other._hpCurrent <= 0) {
        other._sprite.kill();
      }
    } else {
      throw new Exception('Target out of range!');
    }
  }
  
  void moveToFix(int x, int y, GameMap map, Game game, {Pathfinder finder, Path precomputed})
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
        return;
      }
      print("Printing path steps...");
      for (int i = 0; i < path.length; i++) {
        print("(${path._steps[i].x},${path._steps[i].y})");
      }
      print("Path End");    
      Tween tween = game.add.tween(_sprite);
      for (int i = 0; i < path.length - 1; i++) {
        Point p1 = _gridToWorld(path._steps[i+1]);
        tween.to({'x' : p1.x, 'y' : p1.y}, 600, Easing.Quadratic.InOut, true);
      }      
      //unit has moved, blank its previous location in units array
      map._units[_pos.x][_pos.y] = "";
      //set new location
      map._units[x][y] = _name;
      _pos.x = x;
      _pos.y = y;
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
