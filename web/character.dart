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
  
  //REMOVE GETTER...or rather SETTER??
  String get name => _name;
  Sprite get sprite => _sprite;
  set sprite(Sprite sprite)
  {
    _sprite = sprite;
  }
  
  Character(String name, CharType type, Point pos)
  {
    _name = name;
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
  
  void attack(Character other)
  {
    other._hpCurrent -= this._attackPower;
  }
  
  void moveTo(int x, int y, GameMap map, Game game, Pathfinder finder)
  {
    if (x >= map.width || y >= map.height || x < 0 || y < 0) {
      //out of bounds => error
    } else if (_manhattanDist(_pos.x, _pos.y, x, y) > _mobility) {
      //If manhattan distance from current pos to target > mobility then the
      //character certainly can't get there
      // =>error
    } else {
      Path path = finder.findPath(this, _pos.x, _pos.y, x, y);
      bool movingHorizontally = false, movingVertically = false;
      if (path == null) {
        //either the destination is blocked, or too costly to reach
        //TODO Play "error sound" before breaking out of the function?
        return;
      }
      //Since it is growable width is not that important, but path.length is
      //will always be more than enough so it's a good choice. 
      Array2d pathData = new Array2d(path.length, 2);
      if (path._steps[1].x != path._steps[0].x)  {
        movingHorizontally = true;
        pathData.array[0] = ([path._steps[1], 0]);
      } else {
        movingVertically = true;
        pathData.array[1] = ([path._steps[1], 1]);
      }
      for (int i = 2; i < path.length; i++) {
        //if next tile movement is same direction as previous (whether horizontal
        //or vertical), just continue
        if (movingHorizontally && path._steps[i].x != path._steps[i - 1].x ||
         movingVertically && path._steps[i].y != path._steps[i - 1].y) {
          continue;
        } else if (movingHorizontally) {
          //Path was horizontal up to now but next path point changes y not x,
          //meaning the character will have to start moving vertically next.
          pathData.array[i] = ([path._steps[i - 1], 0]);
          movingHorizontally = false;
          movingVertically = true;
        } else if (movingVertically) {
          //Path was vertical up to now but next path point changes x not y,
          //meaning the character will have to start moving horizontally next.
          pathData.array.add([path._steps[i - 1], 1]);
          movingHorizontally = true;
          movingVertically = false;
        }
        //Before animating, check if first and second "tween steps" can be merged;
        //that is, if both are horizontal or vertical
        if (pathData[0][1] == pathData[1][1]) {
          pathData.array.removeAt(1);
        }
        int destX, destY;
        for (int i = 0; i < pathData.array.length; i++) {
          if ( pathData[i][1] == 0) {
            destX = pathData[i][0].x * TILE_DIM + MAP_OFFSETX;
            game.add.tween(_sprite)
            .to({'x' : destX}, 1000, Easing.Quadratic.InOut, true);
          } else {
            int destY = pathData[i][0].y * TILE_DIM + MAP_OFFSETY;
            game.add.tween(_sprite)
            .to({'y' : destY}, 1000, Easing.Quadratic.InOut, true);
          }
        }
        //unit has moved, blank its previous location in units array
        map._units[_pos.x][_pos.y] = "";
        //set new location
        map._units[x][y] = _name;
        _pos.x = x;
        _pos.y = y;
      }
    }
  }
  
  void moveToFix(int x, int y, GameMap map, Game game, Pathfinder finder)
  {
    if (x >= map.width || y >= map.height || x < 0 || y < 0) {
      //out of bounds => error
    } else if (_manhattanDist(_pos.x, _pos.y, x, y) > _mobility) {
      //If manhattan distance from current pos to target > mobility then the
      //character certainly can't get there
      // =>error
    } else {
      String blah;
      Path path = finder.findPath(this, _pos.x, _pos.y, x, y, _mobility.toDouble());
      if (path == null) {
        TileType tt = map.whatTile(y, x);
        window.alert("Path blocked! At ($x,$y) there is a tile of type ${tt.value}");
        for (int a = 0; a < map.height; a++) {
          var temp = "";
          for (int b = 0; b < map.width; b++) {
            bool boolL = map.blocked(null, a, b);
            temp += boolL.toString() + " ";
          }
          print(temp);
        }
        return;
      }
      print("Printing path steps...");
      for (int i = 0; i < path.length; i++) {
        print("(${path._steps[i].x},${path._steps[i].y})");
      }
      print("Path End");
      Point p = _gridToWorld(path._steps[0]);    
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
  
  int _manhattanDist(int x1, int y1, int x2, int y2) => Math.abs(x2 - x1) + Math.abs(y2 - y1);
  Point _gridToWorld(Point p) => new Point(p.x * TILE_DIM  + MAP_OFFSETX, p.y * TILE_DIM + MAP_OFFSETY - CHAR_HEIGHT);
  
  initSprite(Game game)
  {
    switch(_type) {
      case CharType.PLAYER: _sprite = game.add
          .sprite(_pos.x * TILE_DIM +MAP_OFFSETX,
                  _pos.y * TILE_DIM + MAP_OFFSETY - CHAR_HEIGHT,
                  'roshan');
      break;
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
