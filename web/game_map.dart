part of TextFueledCombat;


/**
 * The [GameMap] class represents the layout of a map within the game where combat will take place.
 * It uses a 2D array to represent its grid.
 */
class GameMap
{
  Map<TileType, Tile> _tileTypes;
  Array2d<int> _grid;
  FileProcessor fileProcessor;
  
  GameMap(int width, int height)
  {
    //create an integer 2D array
    _grid = new Array2d(width, height);
    _tileTypes = new Map<TileType, Tile>();
    //add an instance of each kind of tile to the map
    _tileTypes[TileType.DIRT] = new Tile(TileType.DIRT);
    _tileTypes[TileType.DRY_LAND] = new Tile(TileType.DRY_LAND);
    _tileTypes[TileType.GRASS] = new Tile(TileType.GRASS);
    _tileTypes[TileType.LAVA] = new Tile(TileType.LAVA);
    _tileTypes[TileType.VOID] = new Tile(TileType.VOID);
    _tileTypes[TileType.WATER] = new Tile(TileType.WATER);
    _tileTypes[TileType.WOOD_TILE] = new Tile(TileType.WOOD_TILE);
    
    fileProcessor = new FileProcessor();
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
  
  Future<bool> generateMap(File file)
  {
    return fileProcessor.analyseTxtFile(file)
      .then((_) {
        //TODO Consider somehow logging what characters were (not?) used 
        //to make the map so that other parts of game do not use same chars?
        //But how to impose min. file size?
        List<String> countKeys = fileProcessor._charCounts.keys.toList();
        Random rng = new Random();
        int rand;
        String randKey;
        for (int i = 0; i < _grid.array.length; i++) {
          for (int j = 0; j < _grid[0].length; j++) {
            //for each "grid square" randomly pick a char from the list of keys and store the int value (representing a TileType)
            //that that char maps to in the grid square.
            rand = rng.nextInt(countKeys.length);
            randKey = countKeys[rand];
            _grid[i][j] = fileProcessor._charTileMappings[randKey];
          }
        }
    });
  }
}
