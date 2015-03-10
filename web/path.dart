part of TextFueledCombat;

/**
 * A path determined by some path finding algorithm. A series of steps from
 * the starting location to the target location. This includes a step for the
 * initial location.
 * 
 * These classes are based entirely on the same class from Kevin Glass' pathfinding
 * tutorial, altered in some ways due to various differences between Dart and Java.
 * 
 * Kevin's tutorial: http://www.cokeandcode.com/main/tutorials/path-finding/
 */
class Path
{
  /** The list of steps building up this path */
  List<Node> _steps;
  
  int get length => _steps.length;
  
  /**
   * Create an empty path
   */
  Path()
  {
    _steps = new List<Node>(); 
  }
  
  /**
   * Get the step at a given index in the path
   * 
   * @param index The index of the step to retrieve. Note this should
   * be >= 0 and < getLength();
   * @return The step information, the position on the map.
   */
  Node getStep(int index) => _steps[0];
  
  //getX(index), getY(index) removed because whatever is using Path.getStep can simply
  //have code like path.getStep(0).x; path.getStep(0).y;
  
  /**
   * Append a step to the path.  
   * 
   * @param x The x coordinate of the new step
   * @param y The y coordinate of the new step
   */
  void appendStep(Node node) 
  {
    _steps.add(node);
  }

  /**
   * Prepend a step to the path.  
   * 
   * @param x The x coordinate of the new step
   * @param y The y coordinate of the new step
   */
  void prependStep(Node node)
  {
    _steps.insert(0, node);
  }
  
  /**
   * Check if this path contains the given step
   * 
   * @param x The x coordinate of the step to check for
   * @param y The y coordinate of the step to check for
   * @return True if the path contains the given step
   */
  bool contains(int x, int y) => _steps.contains(new Node(x,y));
  
  void removeLast()
  {
    _steps.removeLast();
  }
  
  void removeFrom(int index) {
    _steps = _steps.sublist(0, index);
  }
  
  String toString() => _steps.toString();
}
  
/**
 * A single step within the path
 * 
 */
class Step 
{
  /** The x coordinate at the given step */
  int _x;
  /** The y coordinate at the given step */
  int _y;
  
  int get x => _x;
  int get y => _y;
  /**
   * Create a new step
   * 
   * @param x The x coordinate of the new step
   * @param y The y coordinate of the new step
   */
  Step(int x, int y) {
    _x = x;
    _y = y;
  }

  operator ==(Step other) => x == other.x && y == other.y;
}
