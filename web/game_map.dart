part of TextFueledCombat;


/**
 * The [GameMap] class represents the layout of a map within the game where combat will take place.
 * It uses a 2D array to represent its grid.
 */
class GameMap implements TileBasedMap
{
  Map<TileType, Tile> _tileTypes;
  List<int> _traversableTypes;
  List<Character> playerTeam, enemyTeam;
  Array2d<int> _grid;
  Array2d<String> _units;
  Array2d<Sprite> _spriteGrid;
  FileProcessor fileProcessor;
  Pathfinder finder;
  Random _rng;
  
  int get width => _grid[0].length;
  int get height => _grid.array.length;
  
  GameMap(int height, int width)
  {
    //create an integer 2D array
    _grid = new Array2d<int>(height, width);
    _units = new Array2d<String>(height, width);
    _spriteGrid = new Array2d<Sprite>(height, width);
    _tileTypes = new Map<TileType, Tile>();
    _traversableTypes = new List<int>();
    playerTeam = new List<Character>();
    enemyTeam = new List<Character>();
    _rng = new Random();
    //arbitrary max search distance of 10...perhaps determine based on map size?
    //Or mobility of characters?
    
    //add an instance of each kind of tile to the map
    _tileTypes[TileType.DIRT] = new Tile(TileType.DIRT);
    _tileTypes[TileType.DRY_LAND] = new Tile(TileType.DRY_LAND);
    _tileTypes[TileType.GRASS] = new Tile(TileType.GRASS);
    _tileTypes[TileType.LAVA] = new Tile(TileType.LAVA);
    _tileTypes[TileType.VOID] = new Tile(TileType.VOID);
    _tileTypes[TileType.WATER] = new Tile(TileType.WATER);
    _tileTypes[TileType.WOOD_TILE] = new Tile(TileType.WOOD_TILE);
    
    fileProcessor = new FileProcessor();
    //Build the list of all int values for traversable TileTypes. This is used in map
    //generation to ensure certain parts of the map, e.g. the borders, are traversable.
    _tileTypes.forEach((TileType tt, Tile tile) {
      if (tile._traversable == true) {
        _traversableTypes.add(tt.value);
      }
    });
    
    //init units array with all cells as empty strings.
    for (int i = 0; i < _units.array.length; i++) {
      for (int j = 0; j < _units[0].length; j++) {
        _units[i][j] = "";
      }
    }
  }
  
  void addTile(TileType type, int row, int col)
  {
    if (!_tileTypes.containsKey(type)) {
      _tileTypes[type] = new Tile(type);
    }
    _grid[row][col] = type.value;
  }
  
  /**
   * This function may or may not be used in the future, at least in its current form. It is presently
   * just a mock-up done to illustrate how I would figure out what type of [Tile] is at a
   * given position.
   */
  TileType whatTile(int row, int col)
  {
    int tileVal = _grid[row][col];
    return _tileTypes.keys.firstWhere((TileType toTest) {
      return toTest.value == tileVal; 
    });
  }
  
  void setSpriteAt(Sprite sprite, int row, int col)
  {
    _spriteGrid[row][col] = sprite;
  }
  
  Sprite getSpriteAt(int row, int col)
  {
    return _spriteGrid[row][col];
  }
  
  void setUnitAt(String unit, int row, int col)
  {
    _units[row][col] = unit;  
  }
  
  String getUnitAt(int row, int col)
  {
    return _units[row][col];
  }
  
  testFindPath(Mover mover)
  {
    Path path = finder.findPath(mover, 0, 0, 0, 8,7.0);
    //print(_grid.toString());
    print("Printing path steps...");
    for (int i = 0; i < path.length; i++) {
      print("(${path._steps[i].x},${path._steps[i].y})");
    }
  }
  
  Future<bool> generateMap(File file)
  {
    return fileProcessor.analyseTxtFile(file)
      .then((_) {
        //TODO Consider somehow logging what characters were (not?) used 
        //to make the map so that other parts of game do not use same chars?
        //But how to impose min. file size?
        List<String> countKeys = fileProcessor._charCountsTile.keys.toList();
        int rand;
        String randKey;
        for (int i = 0; i < _grid.array.length; i++) {
          for (int j = 0; j < _grid[0].length; j++) {
            if (i == 0 || j == 0 || i == height - 1 || j == width - 1) {
              //Dealing with a border tile, just roll for a traversable.
              _grid[i][j] = _rollTraversableType();
              countKeys = fileProcessor._charCountsTile.keys.toList();
            } else {
              //Need to ensure countKeys does not contain any chars that were
              //removed from the charCounts map.
              countKeys = fileProcessor._charCountsTile.keys.toList();
              //For each "grid square" randomly pick a char from the list of keys and store the
              //int value (representing a TileType) that that char maps to in the grid square.
              //Continue to reselect a char until a TileType that fits well is found.
              do {
                rand = _rng.nextInt(countKeys.length);
                randKey = countKeys[rand];
              } while (!_tileFitsWell(fileProcessor._charTileMappings[randKey], i, j));
              _grid[i][j] = fileProcessor._charTileMappings[randKey];
              fileProcessor._takeChar(randKey);
            }
          }
        }
        //Now that the map is set up, initialise the Pathfinder. This cannot be done
        //in the constructor because the map needs to be set up so that the
        //Pathfinder can access Tile cost values.
        finder = new AStarPathFinder(this, 10);
        //Initialise _charCountsAttack to be a copy of _charCountsTile's state
        //after the GameMap is fully set up. This is later used for assigning
        //characters' attack capabilities.
        fileProcessor._charCountsAttack.addAll(fileProcessor._charCountsTile);
    });
  }
  
  /**
   * This function is used during map generation in an attempt to prevent bad map
   * configurations by ensuring that a lot of untraversable terrain is not close
   * together on the map. 
   */
  bool _tileFitsWell(int tileTypeInt, int row, int col)
  {
    TileType tileType = _tileTypes.keys
    .firstWhere((TileType t) {
      return t.value == tileTypeInt;
    });
    TileType temp;
    int strikeCount = 0; //Track how many adjacent tiles are untraversable.
                         //Two(?) strikes, and you're out.
    
    Tile tile = _tileTypes[tileType];
    if (tile._traversable == true) {
      //In this case a new traversable tile is being put in, so no problems.
      return true;
    } else {
      //begin testing what tiles are around the current tile
      //Test NW adjacent
      if (row > 0 && col > 0) {
        temp = this.whatTile(row - 1, col - 1);
        if (!_tileTypes[temp]._traversable) {
           strikeCount++;
        }
      }
      //Test N adjacent
      if (row > 0) {
        temp = this.whatTile(row - 1, col);
        if (!_tileTypes[temp]._traversable) {
          strikeCount++;
        }
      }
      //Test NE adjacent
      if (row > 0 && col < _grid[0].length - 1) {
        temp = this.whatTile(row - 1, col + 1);
        if (!_tileTypes[temp]._traversable) {
          strikeCount++;
        }
      }
      //Test W adjacent
      if (col > 0) {
        temp = this.whatTile(row, col - 1);
        if (!_tileTypes[temp]._traversable) {
          strikeCount++;
        }
      }
    }
    return strikeCount < 1;
  }
  
  int _rollTraversableType()
  {
    int rand;
    int tileInt;
    List<String> traversableChars = fileProcessor._charTileMappings.keys.where((String mapKey) {
      tileInt = fileProcessor._charTileMappings[mapKey];
      return _traversableTypes.contains(tileInt);
    }).toList();
    rand = _rng.nextInt(traversableChars.length);
    String chosen = traversableChars[rand];
    int ret = fileProcessor._charTileMappings[chosen];
    fileProcessor._takeChar(chosen);
    return ret;
  }
  
  //Method implementations mandated by TileBasedMap interface
  int getWidthInTiles() => width;
  int getHeightInTiles() => height;
  
  pathfinderVisited(int x, int y)
  {
    //probably won't be used, inherited intended is for debugging new heuristics
  }
  
  //TODO Consider reworking for cases where some characters can move over
  //"untraversable" tiles, e.g. flyers? Probably not going to be a feature in FYP
  //version..
  bool blocked(Mover mover, int row, int col)
  {
    if (mover == null) {
      return !_traversableTypes.contains(_grid[row][col]);
    } else if ((mover as Character).type == CharType.PLAYER) {
      bool enemyIsAtDest = enemyTeam.any((Character c) {
        return c.name == _units[row][col];
      });
      return !_traversableTypes.contains(_grid[row][col]) || enemyIsAtDest;
    } else if ((mover as Character).type == CharType.ENEMY) {
      bool enemyIsAtDest = enemyTeam.any((Character c) {
        return c.name == _units[row][col];
      });
      return !_traversableTypes.contains(_grid[row][col]) || enemyIsAtDest;
    }
  }
  
  double getCost(Mover mover, int startRow, int startCol, int targetRow, int targetCol)
  {
    //Cover our bases; this should only be used to test moving from one tile to another
    //directly (nondiagonally!) adjacent tile.
    if (targetRow - startRow !=0 && targetCol - startCol != 0) {
      throw('Error: Diagonal movement not allowed.');
    //Difference > 1 in either case means an attempt to assess moving to a tile that
    //is not directly adjacent. This is out of scope of the intended use.
    } else if (targetRow - startRow > 1 || targetCol - startCol > 1) {
      throw('Error: Trying to assess moving to a tile that is not directly adjacent');
    } else {
      //If you get here, it's a valid tile (i.e. directly adjacent) to check!
      TileType currType = whatTile(targetRow, targetCol);
      double mc = _tileTypes[currType]._moveCost.toDouble();
      return mc;
    }
  }
}
