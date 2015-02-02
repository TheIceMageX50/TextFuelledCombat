part of TextFueledCombat;

class FileProcessor
{
  Map<String, int> _charCounts;
  Map<String, int> _charTileMappings;
  
  FileProcessor()
  {
    _charCounts = new Map<String, int>();
    _charTileMappings = new Map<String, int>();
    _setupCharCountMap();
    _setupCharMapping();
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
        if (_charCounts.containsKey(fileText[i])) {
          _charCounts[fileText[i]]++;
        } else {
          //TODO handle case where current char does not exist as a Map key.
        }
      }
      fileIsRead.complete(true);
    });
    reader.readAsText(txtFile);
    
    return fileIsRead.future;
  }
  
  _setupCharCountMap()
  {
    int startCode = "!".codeUnitAt(0);
    int endCode = "z".codeUnitAt(0);
    
    //For each character we are interested in, add a key with value 0 to the map.
    for (int i = startCode; i <= endCode; i++) {
      _charCounts[new String.fromCharCode(i)] = 0;
    }
  }
  
  /**
   * Initial basic character-TileType mapping method; First char is mapped to first tile type (enum value 0), second to second,
   * etc. and when the last TileType value is reached, the code loops back to map the next char to the first TileType value.
   */
  _setupCharMapping()
  {
    int startCode = "!".codeUnitAt(0);
    int endCode = "z".codeUnitAt(0);
    int x = 0;
    
    //For each character we are interested in, add a key with value 0 to the map, just to add all the desired keys.
    for (int i = startCode; i <= endCode; i++) {
      _charTileMappings[new String.fromCharCode(i)] = 0;
    }
    _charTileMappings.keys
    .forEach((String key) {
      _charTileMappings[key] = x % TileType.TYPE_COUNT;
      x++;
    });
  }
}
