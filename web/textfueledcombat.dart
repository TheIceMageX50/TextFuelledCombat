import 'lib/tfc_dart.dart';
import 'package:play_phaser/phaser.dart';
import 'dart:html';

Pathfinder finder;

void main()
{

  new Tfc();
  //TODO Title screen and/or startup sequence?
}

class Tfc
{
  GameMap map;
  
  Tfc()
  {
    map = new GameMap(16, 16);
    
    Game game = new Game(800, 600, AUTO, 'canvasDiv');
    game.stage.setBackgroundColor(0xADD8E6);
    State state, state2; 
    state = new FileWaitState(map);
    game.state.add('wait', state);
    game.state.start('wait');
    
    state2 = new MapRenderState(map, 'assets');
    game.state.add('maprender', state2);
  }
  
  void _addTile(int i, int j)
  {
    bool isEven = i % 2 == 0;
    switch (isEven) {
      case true: map.addTile(TileType.WOOD_TILE, i, j);
      break;
      case false: map.addTile(TileType.VOID, i, j);
    }
  }
}

//Currently this is a state for testing rendering stuff
class MapRenderState extends State
{
  GameMap map;
  String assetPath;
  Sprite playerChar;
  List<Character> playerTeam, enemyTeam;
  Character selected;
  
  MapRenderState(GameMap map, String assetPath)
  {
    this.map = map;
    this.assetPath = assetPath; 
    playerTeam = new List<Character>();
    enemyTeam = new List<Character>();
  }
  
  preload()
  {  
    //character sprites
    game.load.image('roshan', '$assetPath/roshan.png');
    //tile sprites
    game.load.image('dirt', '$assetPath/dirt.png');
    game.load.image('dryland', '$assetPath/wood_ph.png');
    game.load.image('grass', '$assetPath/grass.png');
    game.load.image('lava', '$assetPath/lava.png');
    game.load.image('void', '$assetPath/void.png');
    game.load.image('water', '$assetPath/water.png');
    game.load.image('wood', '$assetPath/wood_tile.png');
  } 
  
  create()
  {
    //Hide input element as it is no longer needed since text file has already
    //been given at this point.
    InputElement ie = querySelector('#test');
    ie.style.display = 'none';
    final int mapOffsetX = 96, mapOffsetY = 32;
    Sprite temp;
    
    for (int i = 0; i < map.height; i++) {
      for (int j = 0; j < map.width; j++) {
        switch(map.whatTile(i, j)) {
          //TODO Make Tile dimension variables so as not to hardcode 32
          case TileType.DIRT: temp = game.add.sprite(j * 32 + mapOffsetX, i * 32 + mapOffsetY, 'dirt');
          break;
          case TileType.DRY_LAND: temp = game.add.sprite(j * 32 + mapOffsetX , i * 32 + mapOffsetY, 'dryland');
          break;
          case TileType.GRASS: temp = game.add.sprite(j * 32 + mapOffsetX, i * 32 + mapOffsetY, 'grass');
          break;
          case TileType.LAVA: temp = game.add.sprite(j * 32 + mapOffsetX, i * 32 + mapOffsetY, 'lava');
          break;
          case TileType.VOID: temp = game.add.sprite(j * 32 + mapOffsetX, i * 32 + mapOffsetY, 'void');
          break;
          case TileType.WATER: temp = game.add.sprite(j * 32 + mapOffsetX, i * 32 + mapOffsetY, 'water');
          break;
          case TileType.WOOD_TILE: temp = game.add.sprite(j * 32 + mapOffsetX, i * 32 + mapOffsetY, 'wood');
          break;
        }
        temp.inputEnabled = true;
        temp.events.onInputDown.add(listenerTiles);
        map.setSpriteAt(temp, j, i);
      }
    }
    //Map rendering is done, need to setup and render characters now.
    Character player = new Character("Testguy", CharType.PLAYER, new Point(0, 0));
    map.setUnitAt(player.name, 0, 0);
    player.initSprite(game);
    //playerChar = game.add.sprite(10, 0, 'roshan');
    //game.add.tween(player)
    //  .to({ 'x': player.sprite.position.x + 32}, 2000, Easing.Quadratic.InOut, true, 0, 0, false);
    player.sprite.inputEnabled = true;
    player.sprite.events.onInputDown.add(listener);
    playerTeam.add(player);
  }
  
  listener(Sprite sprite, Pointer p)
  {
    //TODO Need to take into account possibility of it being player OR enemy
    //once turn system exists.
    selected = playerTeam.firstWhere((Character c) {
      return c.sprite == sprite;
    });
    //map.testFindPath(null);
    window.alert("Clicked! Unit ${selected.name} is now selected!");
  }
  
  listenerTiles(Sprite sprite, Pointer p)
  {
    //bool to avoid some needless iterations, i.e. once the right tile is found
    bool shouldEnd = false;
    for (int i = 0; i < map.width; i++) {
      for (int j = 0; j < map.height; j++) {
        if (sprite == map.getSpriteAt(i, j)) {
          print("Clicked on ($i,$j)");
          selected.moveTo(i, j, map, game, finder);
          break;
        }
      }
      if (shouldEnd) {
        break;
      }
    }
  }
}

class FileWaitState extends State
{
  GameMap map;
  InputElement ie;
  
  FileWaitState(GameMap map)
  {
    this.map = map;
  }
  
  create()
  {
    TextStyle style = new TextStyle(font: "45px Arial", fill: "#ffffff", align: "center");
    game.add.text(game.world.centerX, game.world.centerY, 'Waiting for text file...', style);
  }
  
  update()
  {
    if (ie.files.isNotEmpty) {
      map.generateMap(ie.files[0])
      .then((_) {
        //TODO Review: Is map.width a good max serach distance? 
        finder = new AStarPathFinder(map, map.width);
        game.state.start('maprender');
      });
    }
  }
  
  init([args])
  {
    ie  = querySelector('#test');
  }
}
