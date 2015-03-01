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
    this._type = type;
    switch (type) {
      case TileType.DIRT:
      case TileType.GRASS:
      case TileType.WATER:
      case TileType.WOOD_TILE: _traversable = true; 
                               _moveCost = 1;
      break;
      case TileType.DRY_LAND: _traversable = true;
                              _moveCost = 2;
      break;
      case TileType.LAVA:
      case TileType.VOID: _traversable = false;
                          _moveCost = 1000;
      break;
      default: throw new UnknownTileException('Invalid TileType value supplied.');
    }
  }
  
  TileType getType() =>  _type;
  bool isTraversable() => _traversable;
  int getCost() => _moveCost;
  
  //For debugging purposes
  String toString() => "_type: ${_type.value}, _traversable: $_traversable, _moveCost: $_moveCost";
  
  operator ==(Tile other) => _type == other._type;
}