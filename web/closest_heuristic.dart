part of TextFueledCombat;

/**
 * A heuristic that uses the tile that is closest to the target
 * as the next best tile.
 * 
 * This class is based entirely on the same class from Kevin Glass' pathfinding
 * tutorial, altered in some ways due to various differences between Dart and Java.
 * 
 * Kevin's tutorial: http://www.cokeandcode.com/main/tutorials/path-finding/
 */
class ClosestHeuristic implements AStarHeuristic
{
  /**
   * @see AStarHeuristic#getCost(TileBasedMap, Mover, int, int, int, int)
   */
  double getCost(TileBasedMap map, Mover mover, int x, int y, int tx, int ty)
  {   
    int dx = tx - x;
    int dy = ty - y;
    
    double result = Math.sqrt((dx * dx)+(dy * dy));
    
    return result;
  }

}