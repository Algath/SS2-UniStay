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

/// Toutes les HES, universités et antennes en Valais
/// Coordonnées WGS84 des institutions
const Map<String, (double, double)> institutionCoords = {
  'HES-SO Valais-Wallis (Sion - HEI, ingénierie)': (46.226395, 7.359848),
  'HES-SO Valais-Wallis (Sion - HEdS, santé)': (46.22518, 7.37132),
  'HES-SO Valais-Wallis (Sierre - HEG, gestion)': (46.29305, 7.53645),
  'EDHEA - École de design & Haute école d\'art': (46.291386, 7.520819),
  'HEdS - Filière Physiothérapie (Loèche-les-Bains)': (46.37806, 7.62722),
  'EPFL Valais Wallis (Sion - Energypolis)': (46.22747, 7.36299),
  'UNIL Valais (Tourisme - IUKB)': (46.23022, 7.39843),
  'UNIGE Valais (CIDE - IUKB)': (46.23022, 7.39843),
  'UniDistance Suisse (siège, Brig)': (46.318611, 7.992222),
  'HEP-VS (site francophone - St-Maurice)': (46.21374, 7.00257),
  'HEP-VS (site germanophone - Brig)': (46.31590, 7.98782),
  'EPAC - École professionnelle des arts contemporains (Saxon)': (46.1381, 7.1747),
  'César Ritz Colleges (Brig)': (46.31900, 7.98950),
  'FFHS / Swiss Distance University (Brig)': (46.31719, 7.98789),
};