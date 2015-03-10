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
    map = new GameMap(10, 12);
    
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
  Text playerText, enemyText;
  final String placeholderText = '----\n--/--';
  int turnVal = 0; //0 is player's turn, 1 is enemy's turn.
  
  set turn(int val)
  {
    if (val > 1) {
      //TODO error, throw?
    } else if (val != turnVal) {
      turnVal = val; 
      if (val == 0) {
        //Reset playerText
        playerText.setText(placeholderText);
        playerTeam.forEach((Character player) {
          player.tired = false;
          player.sprite.inputEnabled = true;
        });
      } else {
        enemyTeam.forEach((Character enemy) {
          enemy.tired = false;
        });
        playEnemyTurn();
      }
    }
  }
  
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
    game.load.image('devil', '$assetPath/devil.png');
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
        map.setSpriteAt(temp, i, j);
      }
    }
    //Map rendering is done, need to setup and render characters now.
    Character player = new Character("Testguy", CharType.PLAYER, new Point(0, 0));
    Character enemy = new Character('Devil', CharType.ENEMY, new Point(5, 1));
    map.setUnitAt(player.name, 0, 0);
    map.setUnitAt(enemy.name, 5, 1);
    player.initSprite(game);
    enemy.initSprite(game);
    player.sprite.inputEnabled = true;
    player.sprite.events.onInputDown.add(onPlayerClicked);
    enemy.sprite.inputEnabled = true;
    enemy.sprite.events.onInputDown.add(onEnemyClicked);
    playerTeam.add(player);
    enemyTeam.add(enemy);
    
    //Setup displays for enemy and player HP.
    TextStyle style = new TextStyle(fill:'#fffff' , font:'10px Arial' , align:'left');
    playerText = game.add.text(10, 20, placeholderText, style);
    enemyText = game.add.text(10, 60, placeholderText, style);
  }
  
  update()
  {
    
  }
  
  void onPlayerClicked(Sprite sprite, Pointer p)
  {
    selected = playerTeam.firstWhere((Character c) {
      return c.sprite == sprite;
    }, orElse: () { /*Do nothing */ });
    playerText.setText("${selected.name}\n${selected.hpCurrent}/${selected.hpMax}");
    window.alert("Clicked! Unit ${selected.name} is now selected! pos (${sprite.position.x},${sprite.position.y})");
  }
  
  void onEnemyClicked(Sprite sprite, Pointer p)
  {
    Character target = enemyTeam.firstWhere((Character c) {
      return sprite == c.sprite;
    });
    enemyText.setText("${target.name}\n${target.hpCurrent}/${target.hpMax}");
    
    if (selected != null) {
      try {
        selected..attack(target)
          ..tired = true
          ..sprite.inputEnabled = false;
        selected = null;
        enemyText.setText("${target.name}\n${target.hpCurrent}/${target.hpMax}");
      
        if (target.hpCurrent <= 0) {
          enemyTeam.remove(target);
          enemyText.setText(placeholderText);
        }
      } catch (e) {
        //Enemy is out of range so attack could not be performed.
        selected.tired = true;
      }
      bool allTired = playerTeam.every((Character player) {
        return player.tired;
      });
      if (allTired) turn = 1;
    }
  }
  
  void listenerTiles(Sprite sprite, Pointer p)
  {
    if (selected != null) { //Avoid crash, and needless computations, if no character selected
      //bool to avoid some needless iterations, i.e. once the right tile is found
      bool shouldEnd = false;
      for (int i = 0; i < map.height; i++) {
        for (int j = 0; j < map.width; j++) {
          if (sprite == map.getSpriteAt(i, j)) {
            print("Clicked on ($i,$j)");
            selected.moveToFix(i, j, map, game, finder: finder);
            shouldEnd = true;
            break;
          }
        }
        if (shouldEnd) {
          break;
        }
      }
    }
  }
  
  void playEnemyTurn()
  {
    enemyTeam.forEach((Character enemy) {
      //TODO First and foremost need to check if a player char is already adjacent.
      //First, figure out what player char is closest.
      //Simple approach of assuming first is closest then testing the rest
      Character targetPlayer = playerTeam[0];
      int manhattanDistance = manhattanDist(enemy.pos.x,
                                            enemy.pos.y,
                                            targetPlayer.pos.x,
                                            targetPlayer.pos.y);
      int manhattanDistanceCurr;
      for (int i = 1; i < playerTeam.length; i++) {
        manhattanDistanceCurr = manhattanDist(enemy.pos.x, enemy.pos.y, playerTeam[i].pos.x, playerTeam[i].pos.y);
        if (manhattanDistanceCurr < manhattanDistance) {
          manhattanDistance = manhattanDistanceCurr;
          targetPlayer = playerTeam[i];
        }
      }
      enemyText.setText("${enemy.name}\n${enemy.hpCurrent}/${enemy.hpMax}");
      playerText.setText("${targetPlayer.name}\n${targetPlayer.hpCurrent}/${targetPlayer.hpMax}");
      //At this point the closest target has been found, although they may be too far away
      //to hit this turn.
      if (manhattanDistance != 1) {
        //Not adjacent to the target player, must find a path to get closer.
        Path path = finder.findPath(enemy, enemy.pos.x, enemy.pos.y, targetPlayer.pos.x, targetPlayer.pos.y);
        path.removeLast();
        if (path.length - 1 <= enemy.mobility) {
          Node n = path.getStep(path.length - 1);
          enemy.moveToFix(n.x, n.y, map, game, precomputed: path);
        } else {
          int iter;
          for (iter = 0; iter < path.length; iter++) {
            if (path.getStep(iter).cost.toInt() > enemy.mobility) break;
          }
          path.removeFrom(iter);
          Node n = path.getStep(path.length - 1);
          enemy.moveToFix(n.x, n.y, map, game, precomputed: path);
        }
      }
      
      try {
        print('Enemy is attacking!');
        enemy.attack(targetPlayer);
        //update after dealing damage
        playerText.setText("${targetPlayer.name}\n${targetPlayer.hpCurrent}/${targetPlayer.hpMax}");
      } catch (e) {
        print("Enemy attack failed! range issue");
        //Enemy is too far away from player to attack, that's ok.
      } finally {
        enemy.tired = true;
      }
    });
    //All enemies will have moved and/or attacked now, end their turn!
    turn = 0;
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
        //TODO Review: Is map.width a good max search distance? 
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
