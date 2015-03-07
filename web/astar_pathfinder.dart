part of TextFueledCombat;

/**
 * A path finder implementation that uses the AStar heuristic based algorithm
 * to determine a path. 
 * 
 * The AStarPathfinder and Node classes are based entirely on the same classes
 * from Kevin Glass' pathfinding tutorial, altered in some ways due to various
 * differences between Dart and Java. The SortedList idea is also from Kevin's
 * implementation, but in this Dart code that class is actually pretty much my own
 * work because I felt extending the preexisting Dart ListBase class was better than
 * adapting Kevin's implementation to Dart, and still achieves the same goal.
 * 
 * Kevin's tutorial: http://www.cokeandcode.com/main/tutorials/path-finding/
 */

class AStarPathFinder implements Pathfinder
{
  /** The set of nodes that have been searched through */
  List<Node> _closed = new List<Node>();
  /** The set of nodes that we do not yet consider fully searched */
  SortedList _open = new SortedList();
  
  /** The map being searched */
  TileBasedMap map;
  /** The maximum depth of search we're willing to accept before giving up */
  int _maxSearchDistance;
  
  /** The complete set of nodes across the map */
  Array2d<Node> _nodes;
  /** True if we allow diaganol movement */
  bool _allowDiagMovement;
  /** The heuristic we're applying to determine which nodes to search first */
  AStarHeuristic _heuristic;

  /**
   * Create a path finder 
   * 
   * @param heuristic The heuristic used to determine the search order of the map
   * @param map The map to be searched
   * @param maxSearchDistance The maximum depth we'll search before giving up
   * @param allowDiagMovement True if the search should try diagonal movement
   */
  AStarPathFinder(
                  TileBasedMap map,
                  int maxSearchDistance, 
                  [bool allowDiagMovement = false,
                  AStarHeuristic heuristic])
  {
    if (heuristic == null) {
      _heuristic = new ClosestHeuristic();
    }
    this.map = map;
    _maxSearchDistance = maxSearchDistance;
    _allowDiagMovement = allowDiagMovement;
    
    int mapWidth = map.getWidthInTiles();
    int mapHeight = map.getHeightInTiles();
    print("mapheight $mapHeight .. mapwidth $mapWidth");
    _nodes = new Array2d(mapHeight, mapWidth);
    for (int x = 0; x < mapHeight; x++) {
      for (int y = 0; y < mapWidth; y++) {
        _nodes[x][y] = new Node(x,y);
        //Getting the cost to move to "target" (coords x,y) from (x - 1,y) will work
        //in all cases except if x == 0. In that case the RangeError is caught and
        //the code calculates moving from (x + 1,y) instead.
        try {
          _nodes[x][y]._cost = map.getCost(null, x - 1, y, x, y);
        } on RangeError catch(e) {
          //print("x is $x .. y is $y");
          _nodes[x][y]._cost = map.getCost(null, x + 1, y, x, y);
        }
      }
    }
  }
  
  /**
   * @see PathFinder#findPath(Mover, int, int, int, int)
   */
  Path findPath(Mover mover, int sx, int sy, int tx, int ty, [double maxCost = double.INFINITY])
  {
    //Easy first check, if the destination is blocked, we can't get there.
    if (map.blocked(mover, ty, tx)) {
      print("Destination blocked! :(");
      return null;
    }
    
    //Initial state for A*. The closed group is empty. Only the starting
    //tile is in the open list and it's already there.
    _nodes[sx][sy]._cost = 0.0;
    _nodes[sx][sy]._depth = 0;
    _closed.clear();
    _open.clear();
    _open.add(_nodes[sx][sy]);
    
    _nodes[tx][ty]._parent = null;
    
    //while we haven't exceeded our max search depth
    int maxDepth = 0;
    while (maxDepth < _maxSearchDistance && _open.length != 0) {
      // pull out the first node in our open list, this is determined to 
      // be the most likely to be the next step based on our heuristic

      Node current = getFirstInOpen();
      if (current == _nodes[tx][ty]) {
        break;
      }
      
      removeFromOpen(current);
      addToClosed(current);
      
      // search through all the neighbours of the current node evaluating
      // them as next steps

      for (int x = -1; x < 2; x++) {
        for (int y = -1; y < 2; y++) {
          // not a neighbour, its the current tile
          if (x == 0 && y == 0) {
            continue;
          } 
          // if we're not allowing diagonal movement then only one of x or y 
          //can be set.
          if (!_allowDiagMovement) {
            if (x != 0 && y != 0) {
              continue;
            }
          }
          // determine the location of the neighbour and evaluate it
          int xp = x + current._x;
          int yp = y + current._y;
          
          if (isValidLocation(mover,sx,sy,xp,yp)) {
            //the cost to get to this node is cost the current plus the movement
            //cost to reach this node. Note that the heuristic value is only used
            //in the sorted open list
            double nextStepCost = current._cost + getMovementCost(mover, current._x, current._y, xp, yp);
            //If nextStepCost exceeds the maxCost, the path is too long
            if (nextStepCost > maxCost) {
              continue;
            }
            
            Node neighbour = _nodes[xp][yp];
            map.pathfinderVisited(xp, yp);
            
            // if the new cost we've determined for this node is lower than 
            // it has been previously makes sure the node hasn'e've
            // determined that there might have been a better path to get to

            // this node so it needs to be reevaluated

            if (nextStepCost < neighbour._cost) {
              if (inOpenList(neighbour)) {
                removeFromOpen(neighbour);
              }
              if (inClosedList(neighbour)) {
                removeFromClosed(neighbour);
              }
            }
            
            //if the node hasn't already been processed and discarded then
            //reset its cost to our current cost and add it as a next possible
            //step (i.e. to the open list)

            if (!inOpenList(neighbour) && !(inClosedList(neighbour))) {
              neighbour._cost = nextStepCost;
              neighbour._heuristicCost = getHeuristicCost(mover, xp, yp, tx, ty);
              maxDepth = Math.max(maxDepth, neighbour.setParent(current));
              addToOpen(neighbour);
            }
          }
        }
      }
    }

    //Since we've run out of search there was no path. Just return null
    if (_nodes[tx][ty]._parent == null) {
      print("No path found! D:");
      return null;
    }
    
    // At this point we've definitely found a path so we can uses the parent
    // references of the nodes to find out way from the target location back
    // to the start recording the nodes on the way.
    Path path = new Path();
    Node target = _nodes[tx][ty];
    print("Path cost: ${target._cost}");
    while (target != _nodes[sx][sy]) {
      path.prependStep(target._x, target._y);
      target = target._parent;
    }
    path.prependStep(sx,sy);
    
    // thats it, we have our path 

    return path;
  }

  /**
   * Get the first element from the open list. This is the next
   * one to be searched.
   * 
   * @return The first element in the open list
   */
  Node getFirstInOpen() => _open.first;
  
  /**
   * Add a node to the open list
   * 
   * @param node The node to be added to the open list
   */
  addToOpen(Node node)
  {
    _open.add(node);
  }
  
  /**
   * Check if a node is in the open list
   * 
   * @param node The node to check for
   * @return True if the node given is in the open list
   */
  bool inOpenList(Node node) => _open.contains(node);
  
  /**
   * Remove a node from the open list
   * 
   * @param node The node to remove from the open list
   */
  removeFromOpen(Node node)
  {
    _open.remove(node);
  }
  
  /**
   * Add a node to the closed list
   * 
   * @param node The node to add to the closed list
   */
  addToClosed(Node node)
  {
    _closed.add(node);
  }
  
  /**
   * Check if the node supplied is in the closed list
   * 
   * @param node The node to search for
   * @return True if the node specified is in the closed list
   */
  bool inClosedList(Node node) => _closed.contains(node);
  
  /**
   * Remove a node from the closed list
   * 
   * @param node The node to remove from the closed list
   */
  removeFromClosed(Node node)
  {
    _closed.remove(node);
  }
  
  /**
   * Check if a given location is valid for the supplied mover
   * 
   * @param mover The mover that would hold a given location
   * @param sx The starting x coordinate
   * @param sy The starting y coordinate
   * @param x The x coordinate of the location to check
   * @param y The y coordinate of the location to check
   * @return True if the location is valid for the given mover
   */
  bool isValidLocation(Mover mover, int sx, int sy, int x, int y)
  {
    bool invalid = (x < 0) || (y < 0) || (y >= map.getWidthInTiles()) || (x >= map.getHeightInTiles());
    
    if (!invalid && (sx != x || sy != y)) {
      invalid = map.blocked(mover, y, x);
    }
    
    return !invalid;
  }
  
  /**
   * Get the cost to move through a given location
   * 
   * @param mover The entity that is being moved
   * @param sx The x coordinate of the tile whose cost is being determined
   * @param sy The y coordiante of the tile whose cost is being determined
   * @param tx The x coordinate of the target location
   * @param ty The y coordinate of the target location
   * @return The cost of movement through the given tile
   */
  double getMovementCost(Mover mover, int sx, int sy, int tx, int ty) {
    return map.getCost(mover, sx, sy, tx, ty);
  }

  /**
   * Get the heuristic cost for the given location. This determines in which 
   * order the locations are processed.
   * 
   * @param mover The entity that is being moved
   * @param x The x coordinate of the tile whose cost is being determined
   * @param y The y coordiante of the tile whose cost is being determined
   * @param tx The x coordinate of the target location
   * @param ty The y coordinate of the target location
   * @return The heuristic cost assigned to the tile
   */
  double getHeuristicCost(Mover mover, int x, int y, int tx, int ty) {
    return _heuristic.getCost(map, mover, x, y, tx, ty);
  }
  
}

/** 
 * A single node in the search graph
 */
class Node implements Comparable
{
  /** The x coordinate of the node */
  int _x;
  /** The y coordinate of the node */
  int _y;
  /** The path cost for this node */
  double _cost;
  /** The parent of this node, how we reached it in the search */
  Node _parent;
  /** The heuristic cost of this node */
  double _heuristicCost;
  /** The search depth of this node */
  int _depth;
  
  /**
   * Create a new node
   * 
   * @param x The x coordinate of the node
   * @param y The y coordinate of the node
   */
  Node(int x, int y)
  {
    _x = x;
    _y = y;
  }
  
  /**
   * Set the parent of this node
   * 
   * @param parent The parent node which lead us to this node
   * @return The depth we have no reached in searching
   */
  int setParent(Node parent)
  {
    _depth = parent._depth + 1;
    this._parent = parent;
    
    return _depth;
  }
  
  /**
   * @see Comparable#compareTo(Object)
   */
  int compareTo(Node other)
  {    
    double f = _heuristicCost + _cost;
    double of = other._heuristicCost + other._cost;
    
    if (f < of) {
      return -1;
    } else if (f > of) {
      return 1;
    } else {
      return 0;
    }
  }
}

class SortedList<T> extends ListBase<T>
{
  List<T> l = new List<T>();
  
  get length => l.length;
  set length(int len)
  {
    l.length = len;
  }
  
  operator[] (int i) => l[i];
  operator[]= (int index, T t)
  {
    l[index] = t;
  }
  
  /**
   * Overrided add function which sorts.
   */
  add(Object o)
  {
    length == 0;
    super.add(o);
    super.sort();
  }
}
