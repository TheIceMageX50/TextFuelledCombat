part of TextFueledCombat;

/**
 * A [Tile] represents an individual square of the grid of a [GameMap].
 */
class Tile
{
  TileType _type;
  bool _traversable;
  int _moveCost;
  
  Tile(TileType type)
  {
    //_moveCost = cost;
    this._type = type;
    switch (type) {
      case TileType.WOOD_TILE : _traversable = true; 
                                _moveCost = 1;
      break;
      case TileType.WOOD_WALL:
      case TileType.VOID: _traversable = false;
      break;
      default: throw new UnknownTileException('Invalid TileType value supplied.');
    }
  }
  
  TileType getType() =>  _type;
  bool isTraversable() => _traversable;
  int getCost() => _moveCost;
  
  operator ==(Tile other) => _type == other._type;
}