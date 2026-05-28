class UserConfig {
  static const String currentUserId = 'temp_user_001';
  static const String currentUserName = 'Mariana Cortes';
  static const String currentUserEmail = 'mariana@enermax.com';
  static const String currentUserAvatar = 'https://randomuser.me/api/portraits/women/68.jpg';
  static const String currentUserRol = 'rh';

  static bool isAdmin() {
    return currentUserRol == 'admin' || currentUserRol == 'rh';
  }
}