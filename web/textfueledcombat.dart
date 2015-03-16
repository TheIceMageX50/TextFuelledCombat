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
  List<Character> playerTeam, enemyTeam;
  Map<AttackType, Sprite> attackButtons;
  Character selected;
  Text playerText, enemyText;
  AttackType selectedPlayerAtk;
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
    attackButtons = new Map<AttackType, Sprite>();
  }
  
  preload()
  {
    game.load.image('button', '$assetPath/button_blue.png');
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
    Sprite temp, waitButton;
    
    for (int i = 0; i < map.height; i++) {
      for (int j = 0; j < map.width; j++) {
        switch(map.whatTile(i, j)) {
          case TileType.DIRT: temp = game.add.sprite(j * TILE_DIM + MAP_OFFSETX, i * TILE_DIM + mapOffsetY, 'dirt');
          break;
          case TileType.DRY_LAND: temp = game.add.sprite(j * TILE_DIM + MAP_OFFSETX , i * TILE_DIM + mapOffsetY, 'dryland');
          break;
          case TileType.GRASS: temp = game.add.sprite(j * TILE_DIM + MAP_OFFSETX, i * TILE_DIM + mapOffsetY, 'grass');
          break;
          case TileType.LAVA: temp = game.add.sprite(j * TILE_DIM + MAP_OFFSETX, i * TILE_DIM + mapOffsetY, 'lava');
          break;
          case TileType.VOID: temp = game.add.sprite(j * TILE_DIM + MAP_OFFSETX, i * TILE_DIM + mapOffsetY, 'void');
          break;
          case TileType.WATER: temp = game.add.sprite(j * TILE_DIM + MAP_OFFSETX, i * TILE_DIM + mapOffsetY, 'water');
          break;
          case TileType.WOOD_TILE: temp = game.add.sprite(j * TILE_DIM + MAP_OFFSETX, i * TILE_DIM + mapOffsetY, 'wood');
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
    //Adding player and enemy characters to the teams
    playerTeam.add(player);
    enemyTeam.add(enemy);
    //For all characters, assign some attack charges.
    [playerTeam, enemyTeam].forEach((List<Character> team) {
      team.forEach((Character char) {
        int tempVal;
        for (int i = 0; i < ATTACK_CHARGE_COUNT; i++) {
          tempVal = map.fileProcessor.takeRandAtkType(char);
          char.addCharge(tempVal);
        }
      });
    });
    
    //Setup displays for enemy and player HP.
    TextStyle style = new TextStyle(fill:'#fffff' , font:'10px Arial' , align:'left');
    playerText = game.add.text(10, 20, placeholderText, style);
    enemyText = game.add.text(10, 60, placeholderText, style);
    
    //Add buttons to the world
    waitButton = addGameButton(game, world.centerX, world.height - 100, 'button', 'Wait', onWaitClicked);
    //waitButton..inputEnabled = true;
    attackButtons[AttackType.SWORD] = addGameButton(
        game,
        0,
        100,
        'button',
        'Sword Attack',
        onSwordButtonClicked);
    attackButtons[AttackType.WATER] = addGameButton(
        game,
        0,
        150,
        'button',
        'Water Magic',
        onWaterButtonClicked);
  }
  
  void onPlayerClicked(Sprite sprite, Pointer p)
  {
    selected = playerTeam.firstWhere((Character c) {
      return c.sprite == sprite;
    }, orElse: () { /*Do nothing */ });
    playerText.setText("${selected.name}\n${selected.hpCurrent}/${selected.hpMax}");
    window.alert("Clicked! Unit ${selected.name} is now selected! pos (${sprite.position.x},${sprite.position.y})");
    //Enable all attack buttons for those attacks which the character has charges.
    attackButtons.forEach((AttackType type, Sprite sprite) {
      if (selected.hasCharge(type))  {sprite.inputEnabled = true;
      } else {
       print(selected.attackCharges);
       print("No charges of type ${type.value} remaining..");
      };
    });
  }
  
  void onEnemyClicked(Sprite sprite, Pointer p)
  {
    Character target = enemyTeam.firstWhere((Character c) {
      return sprite == c.sprite;
    });
    enemyText.setText("${target.name}\n${target.hpCurrent}/${target.hpMax}");
    
    if (selected != null) {
      try {
        if (selectedPlayerAtk != null) {
          selected..attack(selectedPlayerAtk, target)
            ..tired = true
            ..sprite.inputEnabled = false;
          selectedPlayerAtk = null;
          selected = null;
          enemyText.setText("${target.name}\n${target.hpCurrent}/${target.hpMax}");
        
          if (target.hpCurrent <= 0) {
            enemyTeam.remove(target);
            enemyText.setText(placeholderText);
          }
        } else {
          //TODO Error feedback to UI e.g. "You must select an attack type."
          //Temporary impl; alert message
          window.alert('You must select an attack type first.');
        }
      } on AttackRangeException catch (e) {
        //Enemy is out of range so attack could not be performed.
        print('Player failed attack! Out of range.');
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
  
  void onWaitClicked(Sprite sprite, Pointer p)
  {
    //TODO Add code to have some kind of confirmation dialogue
    if (selected != null) {
      selected.tired = true;
      bool allTired = playerTeam.every((Character player) {
        return player.tired;
      });
      if (allTired) turn = 1;
    }
  }
  
  void onSwordButtonClicked(Sprite sprite, Pointer p)
  {
    if (selected != null && selected.hasCharge(AttackType.SWORD)) {
      print('Player mode - Sword attack!');
      selectedPlayerAtk = AttackType.SWORD;
    }
  }
  
  void onWaterButtonClicked(Sprite sprite, Pointer p)
  {
    if (selected != null && selected.hasCharge(AttackType.WATER)) {
      print('Player mode - Water attack!');
      selectedPlayerAtk = AttackType.WATER;
    }
  }

  void playEnemyTurn()
  {
    enemyTeam.forEach((Character enemy) {
      //TODO First and foremost need to check if a player char is already adjacent.
      //First, figure out what player char is closest.
      //Simple approach of assuming first is closest then testing the rest
      AttackType chosenType;
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
        if (path != null) path.removeLast();
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
        chosenType = _pickEnemyAttackType(enemy, targetPlayer);
        enemy.attack(chosenType, targetPlayer);
        //update after dealing damage
        playerText.setText("${targetPlayer.name}\n${targetPlayer.hpCurrent}/${targetPlayer.hpMax}");
      } on AttackRangeException catch (e) {
        print("Enemy attack failed! range issue");
        //Enemy is too far away from player to attack, that's ok.
      } finally {
        enemy.tired = true;
      }
    });
    //All enemies will have moved and/or attacked now, end their turn!
    turn = 0;
  }
  
  AttackType _pickEnemyAttackType(Character enemy, Character target)
  {
    int rand = RNG.nextInt(5);
    if (rand < 3) {
      Map<AttackType, int> weaknessCharges = new Map<AttackType, int>(); 
      enemy.attackCharges.forEach((AttackType t, int charges) {
        if (target.isWeakTo(t)) weaknessCharges[t] = charges;
      });
      //Of all AttackTypes the target is weak to, that the attacking enemy has
      //charges for, select the one which has the most charges remaining.
      return weaknessCharges.keys
        .reduce((AttackType t1, AttackType t2) {
        return weaknessCharges[t1] >= weaknessCharges[t2] ? weaknessCharges[t1] : weaknessCharges[t2];
      });
    } else {
      //Unlucky (for the enemy!) roll...select the most charged type the target is
      //not weak to.
      Map<AttackType, int> nonweakCharges = new Map<AttackType, int>();
      enemy.attackCharges.forEach((AttackType t, int charges) {
        if (target.isWeakTo(t) == false) nonweakCharges[t] = charges;
      });
      return nonweakCharges.keys
        .reduce((AttackType t1, AttackType t2) {
        return nonweakCharges[t1] >= nonweakCharges[t2] ? t1 : t2;
      });
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
