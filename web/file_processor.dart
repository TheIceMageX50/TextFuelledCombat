part of TextFueledCombat;

class FileProcessor
{
  Map<String, int> _charCountsTile;
  Map<String, int> _charCountsAttack;
  Map<String, int> _charTileMappings;
  Map<String, int> _charAttackMappings;
  Map<String, int> _exhaustedChars;
  Random rng = new Random();
  
  FileProcessor()
  {
    _charCountsTile = new Map<String, int>();
    _charCountsAttack = new Map<String, int>();
    _charTileMappings = new Map<String, int>();
    _charAttackMappings = new Map<String, int>();
    _exhaustedChars = new Map<String, int>();
    _setupCharCountMap();
    _setupCharTileMapping();
    _setupCharAttackMapping();
  }
  
  Future<bool> analyseTxtFile(File txtFile)
  {
    FileReader reader = new FileReader();
    String fileText = "";
    Completer fileIsRead = new Completer();
    
    //When file text has been read in, get it and analyse it.
    reader.onLoadEnd.listen((e) {
      //do something
      fileText = e.target.result;
      for (int i = 0; i < fileText.length; i++) {
        if (_charCountsTile.containsKey(fileText[i])) {
          _charCountsTile[fileText[i]]++;
        } else {
          //TODO handle case where current char does not exist as a Map key.
        }
      }
      fileIsRead.complete(true);
    });
    reader.readAsText(txtFile);
    
    return fileIsRead.future;
  }
  
  int takeRandAtkType(Character chargee)
  {
    List<String> keys = _charAttackMappings.keys.where((String str) {
      return !chargee._weaknesses.contains(_charAttackMappings[str]);
    }).toList();
    int rand = rng.nextInt(keys.length);
    
    String randKey = keys[rand];
    int ret = _charAttackMappings[randKey];
    _charCountsAttack[randKey]--;
    if (_charCountsAttack[randKey] == 0) {
      _charTileMappings.remove(randKey);
      _charCountsTile.remove(randKey);  
    }
    return ret;
  }
  
  void _takeChar(String chosenChar)
  {
    _charCountsTile[chosenChar]--;
    if (_charCountsTile[chosenChar] == 0) {
      _exhaustedChars[chosenChar] = _charTileMappings.remove(chosenChar);
      _charCountsTile.remove(chosenChar);  
    }
  }
  
  void _setupCharCountMap()
  {
    int startCode = "!".codeUnitAt(0);
    int endCode = "z".codeUnitAt(0);
    
    //For each character we are interested in, add a key with value 0 to the map.
    for (int i = startCode; i <= endCode; i++) {
      _charCountsTile[new String.fromCharCode(i)] = 0;
    }
  }
  
  /**
   * Initial basic character-TileType mapping method; First char is mapped to first tile type (enum value 0), second to second,
   * etc. and when the last TileType value is reached, the code loops back to map the next char to the first TileType value.
   */
  void _setupCharTileMapping()
  {
    int startCode = "!".codeUnitAt(0);
    int endCode = "z".codeUnitAt(0);
    int x = 0;
    
    //For each character we are interested in, add a key with value 0 to the map,
    //just to add all the desired keys.
    for (int i = startCode; i <= endCode; i++) {
      _charTileMappings[new String.fromCharCode(i)] = 0;
    }
    _charTileMappings.keys
    .forEach((String key) {
      _charTileMappings[key] = x % TileType.TYPE_COUNT;
      x++;
    });
  }
  
  void _setupCharAttackMapping()
  {
    int startCode = "!".codeUnitAt(0);
    int endCode = "z".codeUnitAt(0);
    int x = 0;
    
    //For each character we are interested in, add a key with value 0 to the map,
    //just to add all the desired keys.
    for (int i = startCode; i <= endCode; i++) {
      _charAttackMappings[new String.fromCharCode(i)] = 0;
    }
    _charAttackMappings.keys
    .forEach((String key) {
      _charAttackMappings[key] = x % AttackType.TYPE_COUNT;
      x++;
    });
  }
}
