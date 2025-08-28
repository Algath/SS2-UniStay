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
  'HES-SO Valais-Wallis (Sion)': 'Rue de l’Industrie 23, 1950 Sion',
  'EPFL (Lausanne)': 'Route Cantonale, 1015 Lausanne',
  'ETH Zürich': 'Rämistrasse 101, 8092 Zürich',
  'Université de Genève': 'Rue du Général-Dufour 24, 1211 Genève',
  'Université de Lausanne': 'CH-1015 Lausanne',
  'Université de Fribourg': 'Avenue de l’Europe 20, 1700 Fribourg',
  'Université de Neuchâtel': 'Avenue du 1er-Mars 26, 2000 Neuchâtel',
};
