library TextFueledCombat;

import 'package:play_phaser/phaser.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
//Mirrors import currently not used. *maybe* in the future.
import 'dart:mirrors';

//Third party code
part '../array_2d.dart';
part '../enum.dart';

//Code adapted from Java written by Kevin Glass
part '../astar_heuristic.dart';
part '../astar_pathfinder.dart';
part '../closest_heuristic.dart';
part '../mover.dart';
part '../path.dart';
part '../pathfinder.dart';
part '../tile_based_map.dart';

//Original code
//---------------------------------------
part '../character.dart';
part '../file_processor.dart';
part '../game_map.dart';
part '../tile.dart';
part '../tile_type_enum.dart';
part 'utils.dart';

//exceptions
part '../tfc_exceptions.dart';
//---------------------------------------
//Global constants
const int TILE_DIM = 32;
const int MAP_OFFSETX = 96;
const int MAP_OFFSETY = 64;
const int CHAR_HEIGHT = 46;
const double WEAKNESS_DMG_MULTIPLIER = 1.1;
