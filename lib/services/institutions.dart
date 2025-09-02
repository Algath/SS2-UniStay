import 'package:unistay/services/utils.dart';

class Institution {
  final String nom;
  final String adresse;
  final double latitude;
  final double longitude;

  const Institution({
    required this.nom,
    required this.adresse,
    required this.latitude,
    required this.longitude,
  });
}

class InstitutionDistance {
  final String nom;
  final String adresse;
  final double distanceKm;

  InstitutionDistance({
    required this.nom,
    required this.adresse,
    required this.distanceKm,
  });
}

/// Trouve l’institution la plus proche d’un point (lat, lon)
InstitutionDistance? findNearestInstitutionFromList(double lat, double lon, List<Institution> institutions) {
  InstitutionDistance? nearest;
  double? minDist;

  for (final inst in institutions) {
    final dist = haversineKm(lat, lon, inst.latitude, inst.longitude);
    if (minDist == null || dist < minDist) {
      minDist = dist;
      nearest = InstitutionDistance(
        nom: inst.nom,
        adresse: inst.adresse,
        distanceKm: dist,
      );
    }
  }

  return nearest;
}

const List<Institution> institutions = [
  Institution(
    nom: 'HES-SO Valais-Wallis (Sion) – Ingénierie',
    adresse: 'Rue de l\'Industrie 21, 1950 Sion',
    latitude: 46.226395,
    longitude: 7.359848,
  ),
  Institution(
    nom: 'HES-SO Valais-Wallis (Sierre) – Gestion',
    adresse: 'Route de la Plaine 2, 3960 Sierre',
    latitude: 46.29305,
    longitude: 7.53645,
  ),
  Institution(
    nom: 'HEP-VS (St-Maurice) – Formation enseignement',
    adresse: 'Avenue du Simplon 13, 1890 St-Maurice',
    latitude: 46.21494,
    longitude: 7.00479,
  ),
  Institution(
    nom: 'HEP-VS (Brig) – Formation enseignement',
    adresse: 'Alte Simplonstrasse 33, 3900 Brig-Glis',
    latitude: 46.31590,
    longitude: 7.98782,
  ),
  Institution(
    nom: 'FFHS / Swiss Distance University (Brig) – Ingénierie & Informatique',
    adresse: 'Überlandstrasse 12, 3900 Brig',
    latitude: 46.31719,
    longitude: 7.98789,
  ),
  Institution(
    nom: 'César Ritz Colleges (Brig) – Hôtellerie & Management',
    adresse: 'English Gruss Strasse 43, 3902 Brig',
    latitude: 46.31900,
    longitude: 7.98950,
  ),
  Institution(
    nom: "EDHEA (Sierre) - Art & Design",
    adresse: "Route de la Bonne-Eau 16, 3960 Sierre",
    latitude: 46.291386,
    longitude: 7.520819,
  ),
  Institution(
    nom: 'HEdS (Sion) - Santé',
    adresse: "Chemin de l'Agasse 5, 1950 Sion",
    latitude: 46.22518,
    longitude: 7.37132
  ),
  Institution(
    nom: 'EPFL (Sion) - Antenne',
    adresse: "Route des Ronquos 86, 1951 Sion",
    latitude: 46.22747,
    longitude: 7.36299
  ),
  Institution(
      nom: 'EPFL (Sion) - Laboratoire',
      adresse: "Rue de l'Industrie 17, 1951 Sion",
      latitude: 46.22747,
      longitude: 7.36299
  ),
  Institution(
      nom: 'UNIL (Bramois) - Tourisme (antenne)',
      adresse: 'Chemin de l\'Industrie 18, 1967 Bramois',
      latitude: 46.23021788828319,
      longitude: 7.398433685302734
  ),
  Institution(
      nom: 'UNIGE (Bramois) - Droits de l\'enfant (antenne)',
      adresse: 'Chemin de l\'Institut 18, 1967 Bramois',
      latitude: 46.23021788828319,
      longitude: 7.398433685302734
  ),
  Institution(
      nom: 'UniDistance (Brig-Glis) - Université à distance',
      adresse: 'Schinerstrasse 18, 3900 Brig-Glis',
      latitude: 46.31719,
      longitude: 7.98789
  ),
  Institution(
      nom: 'HEdS (Loêche-les-Bains) - Physiothérapie',
      adresse: 'Thermenstrasse 41, 3954 Loèche-les-Bains',
      latitude: 46.383,
      longitude: 7.633
  ),
  Institution(
      nom: 'EPAC (Saxon) - Art Contemporain',
      adresse: 'Saxon, Valais',
      latitude: 46.14864,
      longitude: 7.17852
  )
];

