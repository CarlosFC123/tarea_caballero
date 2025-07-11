class User {
  final String id;
  final String nombre;
  final String telefono;
  final String password;
  final int puntos;
  final DateTime createdAt;

  User({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.password,
    required this.puntos,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      password: map['password'],
      puntos: map['puntos'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}