import 'lib/tfc_dart.dart';
import 'package:play_phaser/phaser.dart';
import 'dart:html';

void main()
{

  new Tfc();
  //Now, map is set up. Need to render
  //TODO Title screen and/or startup sequence?
}

class Tfc
{
  GameMap map;
  
  Tfc()
  {
    map = new GameMap(32, 32);
    
    for (int i = 0; i < 32; i++) {
      for (int j = 0; j < 32; j++) {
        _addTile(i, j);
      }
    }
    Game game = new Game(800, 600, AUTO, 'canvasDiv');
    State state, state2; 
    state = new FileWaitState();
    game.state.add('wait', state);
    game.state.start('wait');
    
    //InputElement ie = querySelector('#test');
    //while(ie.files.isEmpty); //loop until file is submitted
    
    state2 = new MapRenderState();
    game.state.add('maprender', state2);
    //game.state.start('maprender');
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
  preload()
  {
    game.load.image('wood', 'wood_ph.png');
    game.load.image('void', 'void_ph.png');
  }
  
  create()
  {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (j % 2 == 0) {
          game.add.sprite(j * 32, i * 32, 'wood');
        } else {
          game.add.sprite(j * 32, i * 32, 'void');
        }
      }
    }
  }
}

class FileWaitState extends State
{
  GameMap map;
  InputElement ie;
  
  create()
  {
    TextStyle style = new TextStyle(font: "65px Arial", fill: "#ffffff", align: "center");
    game.add.text(game.world.centerX, game.world.centerY, 'Waiting for text file...', style);
  }
  
  update()
  {
    if (ie.files.isNotEmpty) {
      map.fileProcessor.analyseTxtFile(ie.files[0])
      .then((_) {
        game.state.start('maprender');
      });
    }
  }
  
  init([GameMap theMap])
  {
    map = theMap;
    ie  = querySelector('#test');
  }
}
