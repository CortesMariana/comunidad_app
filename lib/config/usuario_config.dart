class UsuarioConfig {
  // Usuario actual — se reemplaza con el de Firebase Auth al implementar auth
  static String usuarioId        = '8f6dc055-873b-4683-b2be-790f2df627d1';
  static String nombreUsuario    = 'Miguel Angel Rodriguez Gonzalez';
  static String avatarUsuario    = 'https://enersishr.blob.core.windows.net/employee-profile-pictures/8dcfe851-4b7b-4f5d-b156-bdbb168712eb-perfil.jpg';
  static String puestoUsuario    = 'Gerente TI';
  static String departamento     = 'Tecnología';
  static String rol              = 'admin'; // 'empleado' | 'admin' | 'moderador'

  static bool get esAdmin        => rol == 'admin';
  static bool get esModerador    => rol == 'moderador' || rol == 'admin';
}