class LoginController {
  
  final Map<String, String> _users = {
    "admin": "123",
    "user084": "pass084",
    "mahasiswa": "praktek2026",
  };

  int _salahLog = 0;  

  bool login(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    if (_users.containsKey(username) && _users[username] == password) {
      _salahLog = 0; 
      return true;
    } else {
      _salahLog++;  
      return false;
    }
  }
  bool get isLocked => _salahLog >= 3;
  
  void resetSalahLog() => _salahLog = 0;
}