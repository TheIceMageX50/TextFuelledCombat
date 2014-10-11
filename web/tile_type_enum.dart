part of TextFueledCombat;

class TileType<int> extends Enum<int>
{
  const TileType(int val) : super(val);
  static const TileType WOOD_TILE = const TileType(0);
  static const TileType WOOD_WALL = const TileType(1);
  static const TileType VOID = const TileType(2);
}