class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.iconKey,
  });

  final String id;
  final String name;
  final String location;
  final String iconKey;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'iconKey': iconKey,
      };

  factory CompanyProfile.fromMap(Map<dynamic, dynamic> map) => CompanyProfile(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        location: map['location']?.toString() ?? '',
        iconKey: map['iconKey']?.toString() ?? 'business',
      );
}
