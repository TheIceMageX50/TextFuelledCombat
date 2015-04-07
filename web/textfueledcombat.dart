import 'lib/tfc_dart.dart';
import 'package:play_phaser/phaser.dart';
import 'dart:async' hide Timer;
import 'dart:html' hide Text, Node;

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
    map = new GameMap(12, 14);
    Game game = new Game(800, 600, AUTO, 'canvasDiv');
    game.stage.setBackgroundColor(0xADD8E6);
    State state, state2, state3; 
    state3 = new TitleState('assets');
    state = new FileWaitState(map);
    game.state.add('wait', state);
    game.state.add('titlestate', state3);
    //game.state.start('wait');
    game.state.start('titlestate');
    
    state2 = new MapRenderState(map, 'assets');
    game.state.add('maprender', state2);
  }
}

class MapRenderState extends State
{
  GameMap map;
  String assetPath;
  Map<AttackType, Sprite> attackButtons;
  Map<AttackType, Text> chargeDisplays;
  Character selected;
  AttackType selectedPlayerAtk;
  final String placeholderText = '----\n--/--';
  BitmapData selectorTexture;
  Sprite hpBar, tileSelector;
  int turnVal = -1; //0 is player's turn, 1 is enemy's turn.
  int selectedTileX = -1, selectedTileY = -1;
  //Incremented and displayed each turn
  int turnCount = 0;
 
  set turn(int val)
  {
    if (val > 1) {
      //TODO error, throw?
    } else if (val != turnVal) {
      turnVal = val;
      BitmapData bmp = game.make.bitmapData(world.width, world.height);
      bmp.fill(0, 0, 0, 0.5);
      Timer timer = game.time.create();
      Sprite temp;
      Text text;
      TextStyle style = new TextStyle(fill:'#ffffff' , font:'25px Arial' , align:'left');
     
      if (val == 0) {
        map.playerTeam.forEach((Character player) {
          player.tired = false;
          player.hasMoved = false;
          player.sprite.inputEnabled = true;
        });
        turnCount++;
        temp = game.add.sprite(0, 0, bmp);
        text = game.add.text(150, 200, 'Turn $turnCount: Player\'s Move', style);
        timer.add(2000, () {
          text.destroy();
          temp.destroy();
        });
        timer.start();
      } else {
        map.enemyTeam.forEach((Character enemy) {
          //TODO Remove this since it's effectively obsolete? Since as it stands
          //enemies can't "cheat" by moving more than they should.
          enemy.tired = false;
        });
        turnCount++;
        temp = game.add.sprite(0, 0, bmp);
        text = game.add.text(150, 200, 'Turn $turnCount: Enemy\'s Move', style);
        timer.add(2000, () {
          text.destroy();
          temp.destroy();
          playEnemyTurn();
        });
        timer.start();
      }
    }
  }
 
  MapRenderState(GameMap map, String assetPath)
  {
    this.map = map;
    this.assetPath = assetPath;
    attackButtons = new Map<AttackType, Sprite>();
    chargeDisplays = new Map<AttackType, Text>();
  }
 
  preload()
  {
    game.load.image('button', '$assetPath/button_blue.png');
    game.load.image('hpBar', '$assetPath/hp_bar_base.png');
    //character sprites
    game.load.image('roshan', '$assetPath/roshan.png');
    game.load.image('devil', '$assetPath/devil.png');
    game.load.image('devilPortrait', '$assetPath/devil_portrait.png');
    game.load.image('playerPortrait', '$assetPath/roshan_portrait.png');
    //tile sprites
    game.load.image('dirt', '$assetPath/dirt.png');
    game.load.image('dryland', '$assetPath/dry_land.png');
    game.load.image('grass', '$assetPath/grass.png');
    game.load.image('lava', '$assetPath/lava.png');
    game.load.image('void', '$assetPath/void.png');
    game.load.image('water', '$assetPath/water.png');
    game.load.image('wood', '$assetPath/wood_tile.png');
    //create tileSelector texture
    selectorTexture = game.make.bitmapData(TILE_DIM, TILE_DIM);
    selectorTexture.fill(255, 0, 0,0.5);
    //sounds and music
    game.load.audio('sword', '$assetPath/sword.ogg', true);
    game.load.audio('waterSound', '$assetPath/waterEdit.ogg', true);
    game.load.audio('air', '$assetPath/air_attack.ogg', true);
    game.load.audio('fire', '$assetPath/fire_attack.ogg', true);
    game.load.audio('earth', '$assetPath/earth_attack.ogg', true);
    game.load.audio('mace', '$assetPath/mace.ogg');
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
    Character player, enemy;
    //TODO Replace upper limit of i (3) with TEAM_SIZE constant.
    for (int i = 0; i < 3; i++) {
      player = new Character("Testguy$i", CharType.PLAYER, new Point(0, 3 + i));
      enemy = new Character('Devil$i', CharType.ENEMY, new Point(map.height - 1, 3 + i));
      map.setUnitAt(player.name, 0, 3 + i);
      map.setUnitAt(enemy.name, map.height - 1, 3 + i);
      player.initSprite(game);
      enemy.initSprite(game);
      player.sprite.inputEnabled = true;
      player.sprite.events.onInputDown.add(onPlayerClicked);
      enemy.sprite.inputEnabled = true;
      enemy.sprite.events.onInputDown.add(onEnemyClicked);
      //Adding player and enemy characters to the teams
      map.playerTeam.add(player);
      map.enemyTeam.add(enemy);
    }
    //For all characters, assign some attack charges and create HP bars.
    for (int i = 0; i < map.playerTeam.length; i++) {
      _assignAttackCharges(map.playerTeam[i]);
      game.add.sprite(0, 20 + 68 * i, getPortraitKey(map.playerTeam[i].type));
      map.playerTeam[i].hpBar = createHpBar(game, 0, 64 + 68 * i);
    }
    for (int i = 0; i < map.enemyTeam.length; i++) {
      _assignAttackCharges(map.enemyTeam[i]);
      game.add.sprite(world.width - 104, 20 + 68 * i, getPortraitKey(map.enemyTeam[i].type));
      map.enemyTeam[i].hpBar = createHpBar(game, world.width - 104, 64 + 68 * i);
    }
   
    //Add buttons to the world
    waitButton = addGameButton(game, 0, 438, 'button', 'Wait', onWaitClicked);
    attackButtons[AttackType.SWORD] = addGameButton(
        game,
        0,
        500,
        'button',
        'Sword Attack',
        onSwordButtonClicked);
    attackButtons[AttackType.MACE] = addGameButton(
        game,
        110,
        500,
        'button',
        'Mace Attack',
        onMaceButtonClicked);
    attackButtons[AttackType.WATER] = addGameButton(
        game,
        220,
        500,
        'button',
        'Water Magic',
        onWaterButtonClicked);
    attackButtons[AttackType.FIRE] = addGameButton(
        game,
        330,
        500,
        'button',
        'Fire Magic',
        onFireButtonClicked);
    attackButtons[AttackType.AIR] = addGameButton(
        game,
        440,
        500,
        'button',
        'Air Magic',
        onAirButtonClicked);
    attackButtons[AttackType.EARTH] = addGameButton(
        game,
        550,
        500,
        'button',
        'Earth Magic',
        onEarthButtonClicked);
    TextStyle style2 = new TextStyle(fill:'#FFFFFF' , font:'20px Arial' , align:'left');
    chargeDisplays[AttackType.SWORD] = game.add.text(0, 545, '--', style2);
    chargeDisplays[AttackType.MACE] = game.add.text(110, 545, '--', style2);
    chargeDisplays[AttackType.WATER] = game.add.text(220, 545, '--', style2);
    chargeDisplays[AttackType.FIRE] = game.add.text(330, 545, '--', style2);
    chargeDisplays[AttackType.AIR] = game.add.text(440, 545, '--', style2);
    chargeDisplays[AttackType.EARTH] = game.add.text(550, 545, '--', style2);
   
    //use turn setter to display "Turn 1" overlay
    turn = 0;
  }
 
  void onPlayerClicked(Sprite sprite, Pointer p)
  {
    if (selected == null || selected.tired) {
      selected = map.playerTeam.firstWhere((Character c) {
        return c.sprite == sprite;
      }, orElse: () { /*Do nothing */ });
      window.alert("Clicked! Unit ${selected.name} is now selected! pos (${sprite.position.x},${sprite.position.y})");
      //Enable all attack buttons for those attacks which the character has charges.
      attackButtons.forEach((AttackType type, Sprite sprite) {
        if (selected.hasCharge(type)) {
          sprite.inputEnabled = true;
        } else {
          sprite.inputEnabled = false;
          print("No charges of type ${type.value} remaining..");
        };
      });
      chargeDisplays.forEach((AttackType att, Text text){
        text.setText(selected.attackCharges[att]);
      });
    } else if (selected.hasMoved && selected.tired == false && sprite != selected.sprite) {
      TextStyle style = new TextStyle(fill:'#000000' , font:'25px Arial' , align:'left');
      Text info = game.add
        .text(100,
              200,
              'The character must attack or \'wait\' before selecting another',
              style);
      //Remove the text from the screen after 2 seconds.
      Timer t = game.time.create();
      t.add(2000, () => info.destroy());
      t.start();
    }
  }
 
  void onEnemyClicked(Sprite sprite, Pointer p)
  {
    Character target = map.enemyTeam.firstWhere((Character c) {
      return sprite == c.sprite;
    });
   
    if (selected != null) {
      try {
        if (selectedPlayerAtk != null) {
          selected..attack(selectedPlayerAtk, target)
            ..tired = true
            ..sprite.inputEnabled = false;
          playAttackSound(selectedPlayerAtk);
          chargeDisplays[selectedPlayerAtk].setText(selected.attackCharges[selectedPlayerAtk]);
          selectedPlayerAtk = null;
          selected = null;
          redrawHpBar(game, target);
       
          if (target.hpCurrent <= 0) {
            map.enemyTeam.remove(target);
          }
        } else {
          TextStyle style = new TextStyle(fill:'#000000' , font:'25px Arial' , align:'left');
          Text info = game.add
            .text(100,
                  200,
                  'You must select an attack type first.',
                  style);
          Timer t = game.time.create();
          t.add(2000, () => info.destroy());
          t.start();
        }
      } on AttackRangeException catch (e) {
        //Enemy is out of range so attack could not be performed.
        print('Player failed attack! Out of range.');
      }
      bool allTired = map.playerTeam.every((Character player) {
        return player.tired;
      });
      if (allTired) turn = 1;
    }
  }
 
  void listenerTiles(Sprite sprite, Pointer p)
  {
    //Avoid crash, and needless computations, if no character selected
    if (selected != null && selected.hasMoved == false) {
      //bool to avoid some needless iterations, i.e. once the right tile is found
      bool shouldEnd = false;
      for (int i = 0; i < map.height; i++) {
        for (int j = 0; j < map.width; j++) {
          if (sprite == map.getSpriteAt(i, j)) {
            print("Clicked on ($i,$j)");
            if (selectedTileX == -1 && selectedTileY == -1) {
              //Visually "select" the tile
              tileSelector = game.add.sprite(sprite.position.x, sprite.position.y, selectorTexture);
              selectedTileX = i;
              selectedTileY = j;
            } else if (i == selectedTileX && j == selectedTileY) {
              tileSelector.destroy();
              //Make sure there isn't another player char there already..
              if (map.getUnitAt(selectedTileX, selectedTileY) == '') {
                selected.moveTo(i, j, map, game, finder: finder);
              }
              selectedTileX = -1;
              selectedTileY = -1;
            } else {
              //Visually "deselect" the last tile and "select" the new one
              tileSelector.destroy();
              tileSelector = game.add.sprite(sprite.position.x, sprite.position.y, selectorTexture);
              selectedTileX = i;
              selectedTileY = j;
            }
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
      selected = null;
      bool allTired = map.playerTeam.every((Character player) {
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
 
  void onMaceButtonClicked(Sprite sprite, Pointer p)
  {
    if (selected != null && selected.hasCharge(AttackType.MACE)) {
      print('Player mode - Mace attack!');
      selectedPlayerAtk = AttackType.MACE;
    }
  }
 
  void onWaterButtonClicked(Sprite sprite, Pointer p)
  {
    if (selected != null && selected.hasCharge(AttackType.WATER)) {
      print('Player mode - Water attack!');
      selectedPlayerAtk = AttackType.WATER;
    }
  }
 
  void onFireButtonClicked(Sprite sprite, Pointer p)
  {
    if (selected != null && selected.hasCharge(AttackType.FIRE)) {
      print('Player mode - Fire attack!');
      selectedPlayerAtk = AttackType.FIRE;
    }
  }
 
  void onEarthButtonClicked(Sprite sprite, Pointer p)
  {
    if (selected != null && selected.hasCharge(AttackType.EARTH)) {
      print('Player mode - Earth attack!');
      selectedPlayerAtk = AttackType.EARTH;
    }
  }
 
  void onAirButtonClicked(Sprite sprite, Pointer p)
  {
    if (selected != null && selected.hasCharge(AttackType.AIR)) {
      print('Player mode - Air attack!');
      selectedPlayerAtk = AttackType.AIR;
    }
  }
 
  void playEnemyTurn()
  {
    Future.forEach(map.enemyTeam,(Character enemy) {
      //TODO First and foremost need to check if a player char is already adjacent.
      //First, figure out what player char is closest.
      //Simple approach of assuming first is closest then testing the rest
      AttackType chosenType;
      Character targetPlayer = map.playerTeam[0];
      int manhattanDistance = manhattanDist(enemy.pos.x,
                                            enemy.pos.y,
                                            targetPlayer.pos.x,
                                            targetPlayer.pos.y);
      int manhattanDistanceCurr;
      for (int i = 1; i < map.playerTeam.length; i++) {
        manhattanDistanceCurr = manhattanDist(enemy.pos.x, enemy.pos.y, map.playerTeam[i].pos.x, map.playerTeam[i].pos.y);
        if (manhattanDistanceCurr < manhattanDistance) {
          manhattanDistance = manhattanDistanceCurr;
          targetPlayer = map.playerTeam[i];
        }
      }
      //At this point the closest target has been found, although they may be too far away
      //to hit this turn.
      Future fut;
      if (manhattanDistance != 1) {
        //Not adjacent to the target player, must find a path to get closer.
        Path path = finder.findPath(enemy, enemy.pos.x, enemy.pos.y, targetPlayer.pos.x, targetPlayer.pos.y);
        if (path != null) {
          path.removeLast();
          while (path.length > 0 && map.getUnitAt(path.getStep(path.length - 1).x, path.getStep(path.length - 1).y) != '') {
            print('Unit at dest: ${map.getUnitAt(path.getStep(path.length - 1).x, path.getStep(path.length - 1).y)}');
            path.removeLast();
          }
          if (path.length - 1 <= enemy.mobility) {
            Node n = path.getStep(path.length - 1);
            fut = enemy.moveTo(n.x, n.y, map, game, precomputed: path);
          } else {
            int iter;
            for (iter = 0; iter < path.length; iter++) {
              if (path.getStep(iter).cost.toInt() > enemy.mobility) break;
            }
            path.removeFrom(iter);
            Node n = path.getStep(path.length - 1);
            fut = enemy.moveTo(n.x, n.y, map, game, precomputed: path);
          }
        }
      } else {
        //A future must be assigned to fut to execute the .then() below. The value doesn't
        //matter.
        fut = new Future.value(0);
      }
     
      return fut.then((_) {
        try {
          print('Enemy is attacking!');
          chosenType = _pickEnemyAttackType(enemy, targetPlayer);
          enemy.attack(chosenType, targetPlayer);
          playAttackSound(chosenType);
          //update after dealing damage
          redrawHpBar(game, targetPlayer);
          if (targetPlayer.hpCurrent <= 0) map.playerTeam.remove(targetPlayer);
        } on AttackRangeException catch (e) {
          print("Enemy attack failed! range issue");
          //Enemy is too far away from player to attack, that's ok.
        } finally {
          enemy.tired = true;
        }
      });
    }).then((_) {
      //All enemies will have moved and/or attacked now, end their turn!
      turn = 0;
    });
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
 
  void _assignAttackCharges(Character c)
  {
    int tempVal;
    for (int i = 0; i < ATTACK_CHARGE_COUNT; i++) {
      tempVal = map.fileProcessor.takeRandAtkType(c);
      c.addCharge(tempVal);
    }
  }
 
  void playAttackSound(AttackType type)
  {
    switch (type) {
      case AttackType.SWORD: game.sound.play('sword');
      break;
      case AttackType.MACE: game.sound.play('mace');
      break;
      case AttackType.WATER: game.sound.play('waterSound');
      break;
      case AttackType.AIR: game.sound.play('air');
      break;
      case AttackType.FIRE:
        //TODO Sound looping doesn't seem to be working yet, why?
        int loopCount = 0;
        Sound s = game.add.sound('fire', 1.0, true);
        s.onLoop.add((Sound s) {
          loopCount++;
          if (loopCount == 3) s.stop();
        });
        s.play();
      break;
      case AttackType.EARTH: game.sound.play('earth');
      break;
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
    TextStyle style = new TextStyle(font: "45px Arial", fill: "#ffffff", align: "left");
    game.add.text(game.world.centerX - 200, game.world.centerY, 'Waiting for text file...', style);
  }
  
  update()
  {
    if (ie.files.isNotEmpty) {
      map.generateMap(ie.files[0])
      .then((_) {
        finder = new AStarPathFinder(map, 50);
        game.state.start('maprender');
      });
    }
  }
  
  init([args])
  {
    ie  = querySelector('#test');
  }
}

class TitleState extends State
{
  String assetPath;
  Key spaceBar;
  
  TitleState(String assetPath)
  {
    this.assetPath = assetPath;
  }
  
  preload()
  {
    game.load.image('title', '$assetPath/title.png');
    game.load.audio('mainTheme', '$assetPath/broken_reality.ogg');
  }
  
  create()
  {
    game.add.sprite(0, 0, 'title');
    game.add.audio('mainTheme', 1.0, true)
    .play('', 0, 1.0, true);
    spaceBar = game.input.keyboard.addKey(Keyboard.SPACEBAR);
  }
  
  update()
  {
    //Leave title screen once space is pressed.
    if (spaceBar.isDown) {
      game.state.start('wait');
    }
  }
}
