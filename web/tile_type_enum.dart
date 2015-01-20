part of TextFueledCombat;

class TileType<int> extends Enum<int>
{
  const TileType(int val) : super(val);
  
  //Number of Tile types, update if more are added!
  static const TYPE_COUNT = 7;
  
  static const TileType WOOD_TILE = const TileType(0);
  static const TileType VOID = const TileType(1);
  static const TileType GRASS = const TileType(2);
  static const TileType DIRT = const TileType(3);
  static const TileType WATER = const TileType(4);
  static const TileType DRY_LAND = const TileType(5);
  static const TileType LAVA = const TileType(6);
}