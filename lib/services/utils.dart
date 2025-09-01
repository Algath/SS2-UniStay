import 'dart:math' show sin, cos, sqrt, atan2;

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  double toRad(double d) => d * (3.141592653589793 / 180.0);
  final dLat = toRad(lat2 - lat1);
  final dLon = toRad(lon2 - lon1);
  final la1 = toRad(lat1);
  final la2 = toRad(lat2);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(la1) * cos(la2);
  final c = 2 * atan2(sqrt(h), sqrt(1 - h));
  return R * c;
}

int walkingMinsFromKm(double km) => (km / 4.5 * 60).round();

const double hesSoValaisLat = 46.2276;
const double hesSoValaisLng = 7.3589;

const swissUniversities = {
  'HES-SO Valais-Wallis (Sion)': 'Rue de l\'Industrie 21, 1950 Sion',
  'HES-SO Valais-Wallis (Sierre)': 'Route de la Plaine 2, 3960 Sierre',
  'HEP-VS (St-Maurice)': 'Avenue du Simplon 13, 1890 St-Maurice',
  'HEP-VS (Brig)': 'Alte Simplonstrasse 33, 3900 Brig-Glis',
  'FFHS / Swiss Distance University (Brig)': 'Überlandstrasse 12, 3900 Brig',
  'César Ritz Colleges (Brig)': 'English Gruss Strasse 43, 3902 Brig',
};


