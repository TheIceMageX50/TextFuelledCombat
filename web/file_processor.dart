import 'dart:html';
import 'dart:async';

class FileProcessor
{
  FileProcessor()
  {
    //constructor
  }
  
  analyseTxtFile(File txtFile)
  {
    FileReader reader = new FileReader();
    String fileText = "";
    Map<String, int> charCounts = new Map<String, int>();
    Completer fileIsRead = new Completer();
    
    reader.onLoadEnd.listen((e) {
      //do something
      fileText = e.target.result;
      fileIsRead.complete(true);
    });
    reader.readAsText(txtFile);
    
    charCounts = _setupCharCountMap(charCounts);
    for (int i = 0; i < fileText.length; i++) {
      if (charCounts.containsKey(fileText[i])) {
        charCounts[fileText[i]]++;
      } else {
        //handle case where current char does not exist as a Map key.
      }
    }
  }
  
  Map<String, int> _setupCharCountMap(Map<String, int> counts)
  {
    int startCode = "!".codeUnitAt(0);
    int endCode = "z".codeUnitAt(0);
    
    //For each character we are interested in, add a key with value 0 to the map.
    for (int i = startCode; i < endCode; i++) {
      counts[new String.fromCharCode(i)] = 0;
    }
    return counts;
  }
}
