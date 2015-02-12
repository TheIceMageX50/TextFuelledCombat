import 'lib/tfc_dart.dart';
import 'package:play_phaser/phaser.dart';
import 'dart:html';

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
    map = new GameMap(32, 32);
    
    /*for (int i = 0; i < 32; i++) {
      for (int j = 0; j < 32; j++) {
        _addTile(i, j);
      }
    }*/
    Game game = new Game(800, 600, AUTO, 'canvasDiv');
    game.stage.setBackgroundColor(0xADD8E6);
    State state, state2; 
    state = new FileWaitState(map);
    game.state.add('wait', state);
    game.state.start('wait');
    
    state2 = new MapRenderState(map);
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
  
  MapRenderState(GameMap map)
  {
    this.map = map;
  }
  
  preload()
  {
    game.load.image('dirt', 'dirt.png');
    game.load.image('dryland', 'wood_ph.png');
    game.load.image('grass', 'grass.png');
    game.load.image('lava', 'lava.png');
    game.load.image('void', 'void.png');
    game.load.image('water', 'water.png');
    game.load.image('wood', 'wood_tile.png');
  } 
  
  create()
  {
    //Hide input element as it is no longer needed since text file has already
    //been given at this point.
    InputElement ie = querySelector('#test');
    ie.style.display = 'none';
    
    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 20; j++) {
        switch(map.whatTile(i, j)) {
          case TileType.DIRT: game.add.sprite(j * 32, i * 32, 'dirt');
          break;
          case TileType.DRY_LAND: game.add.sprite(j * 32, i * 32, 'dryland');
          break;
          case TileType.GRASS: game.add.sprite(j * 32, i * 32, 'grass');
          break;
          case TileType.LAVA: game.add.sprite(j * 32, i * 32, 'lava');
          break;
          case TileType.VOID: game.add.sprite(j * 32, i * 32, 'void');
          break;
          case TileType.WATER: game.add.sprite(j * 32, i * 32, 'water');
          break;
          case TileType.WOOD_TILE: game.add.sprite(j * 32, i * 32, 'wood');
          break;
        }
      }
    }
    //Map rendering is done, need to setup and render characters now.
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
    TextStyle style = new TextStyle(font: "65px Arial", fill: "#ffffff", align: "center");
    game.add.text(game.world.centerX, game.world.centerY, 'Waiting for text file...', style);
  }
  
  update()
  {
    if (ie.files.isNotEmpty) {
      map.generateMap(ie.files[0])
      .then((_) {
        game.state.start('maprender');
      });
    }
  }
  
  init([args])
  {
    ie  = querySelector('#test');
  }
}
