part of TextFueledCombat;

class Tile
{
  TileType type;
  bool traversable;
  int moveCost;
  
  Tile(TileType type, [int cost = 1])
  {
    moveCost = cost;
    this.type = type;
    switch (type) {
      case TileType.WOOD_TILE : traversable = true;
      break;
      case TileType.WOOD_WALL:
      case TileType.VOID: traversable = false;
      break;
      default: throw new UnknownTileException('Invalid TileType value supplied.');
    }
  }
}