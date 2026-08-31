class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String roleName;
  final String? matricule;
  final String? direction;
  final String? service;
  final String? poste;
  final String? telephone;
  final String? authMethod;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.roleName,
    this.matricule,
    this.direction,
    this.service,
    this.poste,
    this.telephone,
    this.authMethod,
    this.avatarUrl,
  });

  String get nomComplet {
    final parts = [prenom, nom].where((s) => s.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : email;
  }

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return (p + n).isNotEmpty ? p + n : email.substring(0, 1).toUpperCase();
  }

  static String _extractRoleName(Map<String, dynamic> j) {
    // Shape 1 : role is a Map object  {name: 'admin', ...}
    final role = j['role'];
    if (role is Map<String, dynamic>) {
      return (role['name'] ?? role['slug'] ?? '').toString();
    }
    // Shape 2 : role is a plain string 'admin'
    if (role is String) return role;
    // Shape 3 : role_name field directly
    final roleName = j['role_name'];
    if (roleName is String) return roleName;
    // Shape 4 : roles[] array (many-to-many)
    final roles = j['roles'];
    if (roles is List && roles.isNotEmpty) {
      final first = roles.first;
      if (first is Map<String, dynamic>) {
        return (first['name'] ?? first['slug'] ?? '').toString();
      }
      if (first is String) return first;
    }
    return '';
  }

  factory UserModel.fromJson(Map<String, dynamic> j) {
    final roleName = _extractRoleName(j);
    return UserModel(
      id:         j['id'] as int,
      nom:        j['nom'] as String? ?? '',
      prenom:     j['prenom'] as String? ?? '',
      email:      j['email'] as String? ?? '',
      roleName:   roleName.toLowerCase(),
      matricule:  j['matricule'] as String?,
      direction:  j['direction'] as String?,
      service:    j['service'] as String?,
      poste:      j['poste'] as String?,
      telephone:  j['telephone'] as String?,
      authMethod: j['auth_method'] as String?,
      avatarUrl:  j['avatar_url'] as String?,
    );
  }
}
