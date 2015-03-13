part of TextFueledCombat;

class UnknownTileException implements Exception
{
  String _message = "";
  
  UnknownTileException(String message)
  {
    _message = message;
  }
  
  String toString() => "UnknownTileException: message=${_message}";
}

class AttackRangeException implements Exception
{
  String _message = '';
  
  AttackRangeException(String message)
  {
    _message = message;
  }
  
  String toString() => "AttackRangeException: message=${_message}";
}
