part of TextFueledCombat;

/**
 * The [GameMap] class represents the layout of a map within the game where combat will take place.
 * It applies the Flyweight design pattern (https://en.wikipedia.org/wiki/Flyweight_pattern) to [Tile]
 * instances combined with a 2D array to represent its grid.
 */
class GameMap
{
  List<Tile> _tiles;
  Array2d<int> _grid;
  
  GameMap(int width, int height)
  {
    //create an integer 2D array
    _grid = new Array2d(width, height, defaultValue: int);
    _tiles = new List<Tile>();
  }
  
  void addTile(Tile tile, int row, int col)
  {
    if (!_tiles.contains(tile)) {
      _tiles.add(tile);
    }
    _grid[row][col] = tile.getType().value;
  }
  
  /**
   * This function may or may not be used in the future, at least in its current form. It is presently
   * just a mock-up done to illustrate how I would figure out what type of [Tile] is at a
   * given position.
   */
  Tile whatTile(int row, int col)
  {
    int tileVal = _grid[row][col];
    return _tiles.firstWhere((Tile toTest) {
      return toTest.getType().value == tileVal; 
    });
  }
}