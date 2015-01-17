import 'dart:html';
import 'dart:async';

class FileProcessor
{
  Map<String, int> _charCounts;
  
  FileProcessor()
  {
    //constructor
    _charCounts = new Map<String, int>();
  }
  
  analyseTxtFile(File txtFile)
  {
    FileReader reader = new FileReader();
    String fileText = "";
    Completer fileIsRead = new Completer();
    
    reader.onLoadEnd.listen((e) {
      //do something
      fileText = e.target.result;
      fileIsRead.complete(true);
    });
    reader.readAsText(txtFile);
    
    _setupCharCountMap();
    for (int i = 0; i < fileText.length; i++) {
      if (_charCounts.containsKey(fileText[i])) {
        _charCounts[fileText[i]]++;
      } else {
        //TODO handle case where current char does not exist as a Map key.
      }
    }
  }
  
  _setupCharCountMap()
  {
    int startCode = "!".codeUnitAt(0);
    int endCode = "z".codeUnitAt(0);
    
    //For each character we are interested in, add a key with value 0 to the map.
    for (int i = startCode; i < endCode; i++) {
      _charCounts[new String.fromCharCode(i)] = 0;
    }
  }
}
