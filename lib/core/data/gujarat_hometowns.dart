import 'package:flutter/foundation.dart';

/// A Gujarat-only hometown that can be mapped onto the existing string field.
@immutable
class GujaratHometown {
  const GujaratHometown({
    required this.id,
    required this.city,
    required this.district,
    this.aliases = const <String>[],
    this.disambiguateWithDistrict = false,
  });

  /// Stable frontend identifier. This is never shown to the user.
  final String id;
  final String city;
  final String district;
  final List<String> aliases;
  final bool disambiguateWithDistrict;

  /// Keeps the existing backend city-name contract, adding the district only
  /// where two approved Gujarat locations share the same city name.
  String get storageValue =>
      disambiguateWithDistrict ? '$city, $district' : city;

  String get displayName =>
      disambiguateWithDistrict ? '$city, $district, Gujarat' : '$city, Gujarat';

  /// Selector rows always include the district for unambiguous accessibility.
  String get selectorLabel => '$city, $district, Gujarat';

  String? get alternateSpellings =>
      aliases.isEmpty ? null : 'Also known as ${aliases.join(', ')}';
}

/// Single approved source for every AMORAA hometown selector and display.
abstract final class GujaratHometowns {
  static final List<GujaratHometown> all = _buildLocations();

  static final List<String> storageValues = List<String>.unmodifiable(
    all.map((location) => location.storageValue),
  );

  static final Map<String, GujaratHometown> _byNormalizedValue = _buildLookup();

  static GujaratHometown? resolve(String? value) {
    final normalized = _normalize(value ?? '');
    if (normalized.isEmpty) return null;
    return _byNormalizedValue[normalized];
  }

  static String normalizeStorageValue(String? value) =>
      resolve(value)?.storageValue ?? '';

  static String displayNameFor(String? value) =>
      resolve(value)?.displayName ?? '';

  static List<GujaratHometown> search(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return all;
    return List<GujaratHometown>.unmodifiable(
      all.where((location) {
        final terms = <String>[
          location.city,
          location.district,
          location.storageValue,
          location.displayName,
          location.selectorLabel,
          ...location.aliases,
          if (location.district == 'Kachchh') 'Kutch',
          if (location.district == 'Dang') 'The Dangs',
        ];
        return terms.any((term) => _normalize(term).contains(normalized));
      }),
    );
  }

  static Map<String, GujaratHometown> _buildLookup() {
    final lookup = <String, GujaratHometown>{};
    for (final location in all) {
      for (final value in <String>[
        location.id,
        location.city,
        location.storageValue,
        location.displayName,
        location.selectorLabel,
        ...location.aliases,
      ]) {
        lookup.putIfAbsent(_normalize(value), () => location);
      }
    }
    return Map<String, GujaratHometown>.unmodifiable(lookup);
  }

  static List<GujaratHometown> _buildLocations() {
    final uniqueById = <String, GujaratHometown>{};
    for (final location in _approvedLocations) {
      uniqueById.putIfAbsent(location.id, () => location);
    }
    final locations = uniqueById.values.toList()
      ..sort((a, b) {
        final cityComparison = a.city.compareTo(b.city);
        return cityComparison != 0
            ? cityComparison
            : a.district.compareTo(b.district);
      });
    return List<GujaratHometown>.unmodifiable(locations);
  }

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const _approvedLocations = <GujaratHometown>[
  GujaratHometown(
    id: 'ahmedabad-ahmedabad',
    city: 'Ahmedabad',
    district: 'Ahmedabad',
    aliases: ['Ahemdabad'],
  ),
  GujaratHometown(id: 'ahwa-dang', city: 'Ahwa', district: 'Dang'),
  GujaratHometown(
    id: 'ambaji-banaskantha',
    city: 'Ambaji',
    district: 'Banaskantha',
  ),
  GujaratHometown(id: 'amod-bharuch', city: 'Amod', district: 'Bharuch'),
  GujaratHometown(id: 'amreli-amreli', city: 'Amreli', district: 'Amreli'),
  GujaratHometown(id: 'anand-anand', city: 'Anand', district: 'Anand'),
  GujaratHometown(id: 'anjar-kachchh', city: 'Anjar', district: 'Kachchh'),
  GujaratHometown(
    id: 'anklav-anand',
    city: 'Anklav',
    district: 'Anand',
    aliases: ['Ankalav'],
  ),
  GujaratHometown(
    id: 'ankleshwar-bharuch',
    city: 'Ankleshwar',
    district: 'Bharuch',
    aliases: ['Ankleswar', 'Anklesvar'],
  ),
  GujaratHometown(
    id: 'babra-amreli',
    city: 'Babra',
    district: 'Amreli',
    aliases: ['Babara'],
  ),
  GujaratHometown(
    id: 'bagasara-amreli',
    city: 'Bagasara',
    district: 'Amreli',
    aliases: ['Bagsara'],
  ),
  GujaratHometown(
    id: 'balasinor-mahisagar',
    city: 'Balasinor',
    district: 'Mahisagar',
  ),
  GujaratHometown(id: 'bantwa-junagadh', city: 'Bantwa', district: 'Junagadh'),
  GujaratHometown(id: 'bardoli-surat', city: 'Bardoli', district: 'Surat'),
  GujaratHometown(
    id: 'bareja-ahmedabad',
    city: 'Bareja',
    district: 'Ahmedabad',
  ),
  GujaratHometown(id: 'barwala-botad', city: 'Barwala', district: 'Botad'),
  GujaratHometown(id: 'bavla-ahmedabad', city: 'Bavla', district: 'Ahmedabad'),
  GujaratHometown(id: 'bayad-aravalli', city: 'Bayad', district: 'Aravalli'),
  GujaratHometown(
    id: 'becharaji-mehsana',
    city: 'Becharaji',
    district: 'Mehsana',
    aliases: ['Bahucharaji'],
  ),
  GujaratHometown(
    id: 'bhabhar-vav-tharad',
    city: 'Bhabhar',
    district: 'Vav-Tharad',
  ),
  GujaratHometown(id: 'bhachau-kachchh', city: 'Bhachau', district: 'Kachchh'),
  GujaratHometown(
    id: 'bhanvad-devbhoomi-dwarka',
    city: 'Bhanvad',
    district: 'Devbhoomi Dwarka',
  ),
  GujaratHometown(
    id: 'bharuch-bharuch',
    city: 'Bharuch',
    district: 'Bharuch',
    aliases: ['Broach'],
  ),
  GujaratHometown(
    id: 'bhavnagar-bhavnagar',
    city: 'Bhavnagar',
    district: 'Bhavnagar',
  ),
  GujaratHometown(
    id: 'bhayavadar-rajkot',
    city: 'Bhayavadar',
    district: 'Rajkot',
  ),
  GujaratHometown(id: 'bhuj-kachchh', city: 'Bhuj', district: 'Kachchh'),
  GujaratHometown(
    id: 'bilimora-navsari',
    city: 'Bilimora',
    district: 'Navsari',
  ),
  GujaratHometown(id: 'bopal-ahmedabad', city: 'Bopal', district: 'Ahmedabad'),
  GujaratHometown(id: 'boriavi-anand', city: 'Boriavi', district: 'Anand'),
  GujaratHometown(id: 'borsad-anand', city: 'Borsad', district: 'Anand'),
  GujaratHometown(id: 'botad-botad', city: 'Botad', district: 'Botad'),
  GujaratHometown(id: 'chaklasi-kheda', city: 'Chaklasi', district: 'Kheda'),
  GujaratHometown(id: 'chalala-amreli', city: 'Chalala', district: 'Amreli'),
  GujaratHometown(id: 'chanasma-patan', city: 'Chanasma', district: 'Patan'),
  GujaratHometown(
    id: 'chhaya-porbandar',
    city: 'Chhaya',
    district: 'Porbandar',
  ),
  GujaratHometown(
    id: 'chhota-udaipur-chhota-udaipur',
    city: 'Chhota Udaipur',
    district: 'Chhota Udaipur',
  ),
  GujaratHometown(
    id: 'chorwad-junagadh',
    city: 'Chorwad',
    district: 'Junagadh',
  ),
  GujaratHometown(
    id: 'chotila-surendranagar',
    city: 'Chotila',
    district: 'Surendranagar',
  ),
  GujaratHometown(
    id: 'dahegam-gandhinagar',
    city: 'Dahegam',
    district: 'Gandhinagar',
    aliases: ['Dehgam'],
  ),
  GujaratHometown(
    id: 'dahod-dahod',
    city: 'Dahod',
    district: 'Dahod',
    aliases: ['Dohad'],
  ),
  GujaratHometown(id: 'dakor-kheda', city: 'Dakor', district: 'Kheda'),
  GujaratHometown(id: 'damnagar-amreli', city: 'Damnagar', district: 'Amreli'),
  GujaratHometown(
    id: 'dantiwada-banaskantha',
    city: 'Dantiwada',
    district: 'Banaskantha',
  ),
  GujaratHometown(id: 'dabhoi-vadodara', city: 'Dabhoi', district: 'Vadodara'),
  GujaratHometown(
    id: 'deesa-banaskantha',
    city: 'Deesa',
    district: 'Banaskantha',
    aliases: ['Disa'],
  ),
  GujaratHometown(
    id: 'devgadh-baria-dahod',
    city: 'Devgadh Baria',
    district: 'Dahod',
    aliases: ['Devgad Baria', 'Devgadbaria'],
  ),
  GujaratHometown(
    id: 'dhandhuka-ahmedabad',
    city: 'Dhandhuka',
    district: 'Ahmedabad',
  ),
  GujaratHometown(
    id: 'dhanera-vav-tharad',
    city: 'Dhanera',
    district: 'Vav-Tharad',
  ),
  GujaratHometown(
    id: 'dharampur-valsad',
    city: 'Dharampur',
    district: 'Valsad',
  ),
  GujaratHometown(
    id: 'dholka-ahmedabad',
    city: 'Dholka',
    district: 'Ahmedabad',
  ),
  GujaratHometown(id: 'dhoraji-rajkot', city: 'Dhoraji', district: 'Rajkot'),
  GujaratHometown(
    id: 'dhrangadhra-surendranagar',
    city: 'Dhrangadhra',
    district: 'Surendranagar',
    aliases: ['Dhrangadhara'],
  ),
  GujaratHometown(id: 'dhrol-jamnagar', city: 'Dhrol', district: 'Jamnagar'),
  GujaratHometown(
    id: 'dwarka-devbhoomi-dwarka',
    city: 'Dwarka',
    district: 'Devbhoomi Dwarka',
  ),
  GujaratHometown(
    id: 'ekta-nagar-narmada',
    city: 'Ekta Nagar',
    district: 'Narmada',
    aliases: ['Kevadia', 'Kevadiya'],
  ),
  GujaratHometown(id: 'gadhada-botad', city: 'Gadhada', district: 'Botad'),
  GujaratHometown(id: 'gandevi-navsari', city: 'Gandevi', district: 'Navsari'),
  GujaratHometown(
    id: 'gandhidham-kachchh',
    city: 'Gandhidham',
    district: 'Kachchh',
  ),
  GujaratHometown(
    id: 'gandhinagar-gandhinagar',
    city: 'Gandhinagar',
    district: 'Gandhinagar',
    aliases: ['Gandhinager'],
  ),
  GujaratHometown(
    id: 'gariadhar-bhavnagar',
    city: 'Gariadhar',
    district: 'Bhavnagar',
    aliases: ['Gariyadhar'],
  ),
  GujaratHometown(
    id: 'godhra-panchmahal',
    city: 'Godhra',
    district: 'Panchmahal',
    aliases: ['Godhara'],
  ),
  GujaratHometown(id: 'gondal-rajkot', city: 'Gondal', district: 'Rajkot'),
  GujaratHometown(
    id: 'halol-panchmahal',
    city: 'Halol',
    district: 'Panchmahal',
  ),
  GujaratHometown(id: 'halvad-morbi', city: 'Halvad', district: 'Morbi'),
  GujaratHometown(id: 'harij-patan', city: 'Harij', district: 'Patan'),
  GujaratHometown(
    id: 'himmatnagar-sabarkantha',
    city: 'Himatnagar',
    district: 'Sabarkantha',
    aliases: ['Himmatnagar'],
  ),
  GujaratHometown(
    id: 'idar-sabarkantha',
    city: 'Idar',
    district: 'Sabarkantha',
  ),
  GujaratHometown(
    id: 'jafrabad-amreli',
    city: 'Jafrabad',
    district: 'Amreli',
    aliases: ['Jaffrabad'],
  ),
  GujaratHometown(
    id: 'jambusar-bharuch',
    city: 'Jambusar',
    district: 'Bharuch',
  ),
  GujaratHometown(
    id: 'jamjodhpur-jamnagar',
    city: 'Jamjodhpur',
    district: 'Jamnagar',
  ),
  GujaratHometown(
    id: 'jamnagar-jamnagar',
    city: 'Jamnagar',
    district: 'Jamnagar',
  ),
  GujaratHometown(
    id: 'jamraval-devbhoomi-dwarka',
    city: 'Jamraval',
    district: 'Devbhoomi Dwarka',
    aliases: ['Jam Raval'],
  ),
  GujaratHometown(id: 'jasdan-rajkot', city: 'Jasdan', district: 'Rajkot'),
  GujaratHometown(
    id: 'jetpur-rajkot',
    city: 'Jetpur',
    district: 'Rajkot',
    aliases: ['Jetpur Navagadh'],
  ),
  GujaratHometown(
    id: 'jhalod-dahod',
    city: 'Jhalod',
    district: 'Dahod',
    aliases: ['Zalod'],
  ),
  GujaratHometown(
    id: 'junagadh-junagadh',
    city: 'Junagadh',
    district: 'Junagadh',
  ),
  GujaratHometown(id: 'kadi-mehsana', city: 'Kadi', district: 'Mehsana'),
  GujaratHometown(id: 'kadodara-surat', city: 'Kadodara', district: 'Surat'),
  GujaratHometown(
    id: 'kalavad-jamnagar',
    city: 'Kalavad',
    district: 'Jamnagar',
  ),
  GujaratHometown(
    id: 'kalol-gandhinagar',
    city: 'Kalol',
    district: 'Gandhinagar',
    disambiguateWithDistrict: true,
  ),
  GujaratHometown(
    id: 'kalol-panchmahal',
    city: 'Kalol',
    district: 'Panchmahal',
    disambiguateWithDistrict: true,
  ),
  GujaratHometown(id: 'kanjari-kheda', city: 'Kanjari', district: 'Kheda'),
  GujaratHometown(id: 'kapadvanj-kheda', city: 'Kapadvanj', district: 'Kheda'),
  GujaratHometown(id: 'karamsad-anand', city: 'Karamsad', district: 'Anand'),
  GujaratHometown(id: 'karjan-vadodara', city: 'Karjan', district: 'Vadodara'),
  GujaratHometown(id: 'kathlal-kheda', city: 'Kathlal', district: 'Kheda'),
  GujaratHometown(id: 'keshod-junagadh', city: 'Keshod', district: 'Junagadh'),
  GujaratHometown(
    id: 'khambhalia-devbhoomi-dwarka',
    city: 'Khambhalia',
    district: 'Devbhoomi Dwarka',
    aliases: ['Khambhaliya', 'Khambalia'],
  ),
  GujaratHometown(
    id: 'khambhat-anand',
    city: 'Khambhat',
    district: 'Anand',
    aliases: ['Cambay'],
  ),
  GujaratHometown(id: 'kheda-kheda', city: 'Kheda', district: 'Kheda'),
  GujaratHometown(
    id: 'khedbrahma-sabarkantha',
    city: 'Khedbrahma',
    district: 'Sabarkantha',
    aliases: ['Khed Brahma'],
  ),
  GujaratHometown(id: 'kheralu-mehsana', city: 'Kheralu', district: 'Mehsana'),
  GujaratHometown(
    id: 'kodinar-gir-somnath',
    city: 'Kodinar',
    district: 'Gir Somnath',
  ),
  GujaratHometown(
    id: 'kutiyana-porbandar',
    city: 'Kutiyana',
    district: 'Porbandar',
  ),
  GujaratHometown(id: 'lathi-amreli', city: 'Lathi', district: 'Amreli'),
  GujaratHometown(
    id: 'limbdi-surendranagar',
    city: 'Limbdi',
    district: 'Surendranagar',
  ),
  GujaratHometown(
    id: 'lunawada-mahisagar',
    city: 'Lunawada',
    district: 'Mahisagar',
  ),
  GujaratHometown(id: 'mahudha-kheda', city: 'Mahudha', district: 'Kheda'),
  GujaratHometown(
    id: 'mahuva-bhavnagar',
    city: 'Mahuva',
    district: 'Bhavnagar',
  ),
  GujaratHometown(
    id: 'maliya-miyana-morbi',
    city: 'Maliya-Miyana',
    district: 'Morbi',
    aliases: ['Malia Miyana'],
  ),
  GujaratHometown(
    id: 'manavadar-junagadh',
    city: 'Manavadar',
    district: 'Junagadh',
  ),
  GujaratHometown(
    id: 'mandvi-kachchh',
    city: 'Mandvi',
    district: 'Kachchh',
    disambiguateWithDistrict: true,
  ),
  GujaratHometown(
    id: 'mandvi-surat',
    city: 'Mandvi',
    district: 'Surat',
    disambiguateWithDistrict: true,
  ),
  GujaratHometown(
    id: 'mangrol-junagadh',
    city: 'Mangrol',
    district: 'Junagadh',
  ),
  GujaratHometown(
    id: 'mansa-gandhinagar',
    city: 'Mansa',
    district: 'Gandhinagar',
  ),
  GujaratHometown(
    id: 'mehsana-mehsana',
    city: 'Mehsana',
    district: 'Mehsana',
    aliases: ['Mahesana'],
  ),
  GujaratHometown(
    id: 'mehmedabad-kheda',
    city: 'Mehmedabad',
    district: 'Kheda',
    aliases: ['Mahemdabad'],
  ),
  GujaratHometown(id: 'modasa-aravalli', city: 'Modasa', district: 'Aravalli'),
  GujaratHometown(
    id: 'morbi-morbi',
    city: 'Morbi',
    district: 'Morbi',
    aliases: ['Morvi'],
  ),
  GujaratHometown(
    id: 'mundra-kachchh',
    city: 'Mundra',
    district: 'Kachchh',
    aliases: ['Mundra-Baroi'],
  ),
  GujaratHometown(
    id: 'nadiad-kheda',
    city: 'Nadiad',
    district: 'Kheda',
    aliases: ['Nadiyad'],
  ),
  GujaratHometown(
    id: 'nakhatrana-kachchh',
    city: 'Nakhatrana',
    district: 'Kachchh',
    aliases: ['Nakhtrana'],
  ),
  GujaratHometown(id: 'navsari-navsari', city: 'Navsari', district: 'Navsari'),
  GujaratHometown(
    id: 'ode-anand',
    city: 'Ode',
    district: 'Anand',
    aliases: ['Oad'],
  ),
  GujaratHometown(
    id: 'okha-devbhoomi-dwarka',
    city: 'Okha',
    district: 'Devbhoomi Dwarka',
  ),
  GujaratHometown(id: 'padra-vadodara', city: 'Padra', district: 'Vadodara'),
  GujaratHometown(
    id: 'palanpur-banaskantha',
    city: 'Palanpur',
    district: 'Banaskantha',
  ),
  GujaratHometown(
    id: 'palitana-bhavnagar',
    city: 'Palitana',
    district: 'Bhavnagar',
  ),
  GujaratHometown(id: 'pardi-valsad', city: 'Pardi', district: 'Valsad'),
  GujaratHometown(
    id: 'patadi-surendranagar',
    city: 'Patadi',
    district: 'Surendranagar',
  ),
  GujaratHometown(id: 'patan-patan', city: 'Patan', district: 'Patan'),
  GujaratHometown(id: 'petlad-anand', city: 'Petlad', district: 'Anand'),
  GujaratHometown(
    id: 'porbandar-porbandar',
    city: 'Porbandar',
    district: 'Porbandar',
  ),
  GujaratHometown(
    id: 'prantij-sabarkantha',
    city: 'Prantij',
    district: 'Sabarkantha',
  ),
  GujaratHometown(id: 'radhanpur-patan', city: 'Radhanpur', district: 'Patan'),
  GujaratHometown(id: 'rajkot-rajkot', city: 'Rajkot', district: 'Rajkot'),
  GujaratHometown(
    id: 'rajpipla-narmada',
    city: 'Rajpipla',
    district: 'Narmada',
  ),
  GujaratHometown(id: 'rajula-amreli', city: 'Rajula', district: 'Amreli'),
  GujaratHometown(
    id: 'ranavav-porbandar',
    city: 'Ranavav',
    district: 'Porbandar',
  ),
  GujaratHometown(id: 'rapar-kachchh', city: 'Rapar', district: 'Kachchh'),
  GujaratHometown(
    id: 'salaya-devbhoomi-dwarka',
    city: 'Salaya',
    district: 'Devbhoomi Dwarka',
  ),
  GujaratHometown(
    id: 'sanand-ahmedabad',
    city: 'Sanand',
    district: 'Ahmedabad',
  ),
  GujaratHometown(
    id: 'santrampur-mahisagar',
    city: 'Santrampur',
    district: 'Mahisagar',
  ),
  GujaratHometown(id: 'saputara-dang', city: 'Saputara', district: 'Dang'),
  GujaratHometown(
    id: 'savarkundla-amreli',
    city: 'Savarkundla',
    district: 'Amreli',
    aliases: ['Savar Kundla'],
  ),
  GujaratHometown(id: 'savli-vadodara', city: 'Savli', district: 'Vadodara'),
  GujaratHometown(
    id: 'shehera-panchmahal',
    city: 'Shehera',
    district: 'Panchmahal',
    aliases: ['Shahera'],
  ),
  GujaratHometown(
    id: 'siddhpur-patan',
    city: 'Siddhpur',
    district: 'Patan',
    aliases: ['Sidhpur'],
  ),
  GujaratHometown(
    id: 'sihor-bhavnagar',
    city: 'Sihor',
    district: 'Bhavnagar',
    aliases: ['Shihor'],
  ),
  GujaratHometown(id: 'sikka-jamnagar', city: 'Sikka', district: 'Jamnagar'),
  GujaratHometown(id: 'sojitra-anand', city: 'Sojitra', district: 'Anand'),
  GujaratHometown(
    id: 'somnath-gir-somnath',
    city: 'Somnath',
    district: 'Gir Somnath',
    aliases: ['Prabhas Patan'],
  ),
  GujaratHometown(id: 'songadh-tapi', city: 'Songadh', district: 'Tapi'),
  GujaratHometown(id: 'surat-surat', city: 'Surat', district: 'Surat'),
  GujaratHometown(
    id: 'surendranagar-surendranagar',
    city: 'Surendranagar',
    district: 'Surendranagar',
  ),
  GujaratHometown(
    id: 'sutrapada-gir-somnath',
    city: 'Sutrapada',
    district: 'Gir Somnath',
  ),
  GujaratHometown(
    id: 'talaja-bhavnagar',
    city: 'Talaja',
    district: 'Bhavnagar',
  ),
  GujaratHometown(
    id: 'talala-gir-somnath',
    city: 'Talala',
    district: 'Gir Somnath',
  ),
  GujaratHometown(
    id: 'talod-sabarkantha',
    city: 'Talod',
    district: 'Sabarkantha',
  ),
  GujaratHometown(id: 'tankara-morbi', city: 'Tankara', district: 'Morbi'),
  GujaratHometown(id: 'tarsadi-surat', city: 'Tarsadi', district: 'Surat'),
  GujaratHometown(
    id: 'thangadh-surendranagar',
    city: 'Thangadh',
    district: 'Surendranagar',
  ),
  GujaratHometown(
    id: 'thara-vav-tharad',
    city: 'Thara',
    district: 'Vav-Tharad',
  ),
  GujaratHometown(
    id: 'tharad-vav-tharad',
    city: 'Tharad',
    district: 'Vav-Tharad',
  ),
  GujaratHometown(id: 'thasra-kheda', city: 'Thasra', district: 'Kheda'),
  GujaratHometown(
    id: 'umargam-valsad',
    city: 'Umargam',
    district: 'Valsad',
    aliases: ['Umbergaon', 'Umargaon'],
  ),
  GujaratHometown(id: 'umreth-anand', city: 'Umreth', district: 'Anand'),
  GujaratHometown(id: 'una-gir-somnath', city: 'Una', district: 'Gir Somnath'),
  GujaratHometown(id: 'unjha-mehsana', city: 'Unjha', district: 'Mehsana'),
  GujaratHometown(id: 'upleta-rajkot', city: 'Upleta', district: 'Rajkot'),
  GujaratHometown(
    id: 'vadali-sabarkantha',
    city: 'Vadali',
    district: 'Sabarkantha',
  ),
  GujaratHometown(
    id: 'vadnagar-mehsana',
    city: 'Vadnagar',
    district: 'Mehsana',
  ),
  GujaratHometown(
    id: 'vadodara-vadodara',
    city: 'Vadodara',
    district: 'Vadodara',
    aliases: ['Baroda', 'Vadodra'],
  ),
  GujaratHometown(
    id: 'vallabh-vidyanagar-anand',
    city: 'Vallabh Vidyanagar',
    district: 'Anand',
    aliases: ['Vallabh Vidhyanagar'],
  ),
  GujaratHometown(
    id: 'vallabhipur-bhavnagar',
    city: 'Vallabhipur',
    district: 'Bhavnagar',
  ),
  GujaratHometown(
    id: 'valsad-valsad',
    city: 'Valsad',
    district: 'Valsad',
    aliases: ['Bulsar'],
  ),
  GujaratHometown(
    id: 'vanthali-junagadh',
    city: 'Vanthali',
    district: 'Junagadh',
  ),
  GujaratHometown(id: 'vapi-valsad', city: 'Vapi', district: 'Valsad'),
  GujaratHometown(
    id: 'veraval-gir-somnath',
    city: 'Veraval',
    district: 'Gir Somnath',
    aliases: ['Veraval Patan'],
  ),
  GujaratHometown(id: 'vijapur-mehsana', city: 'Vijapur', district: 'Mehsana'),
  GujaratHometown(
    id: 'viramgam-ahmedabad',
    city: 'Viramgam',
    district: 'Ahmedabad',
  ),
  GujaratHometown(
    id: 'visavadar-junagadh',
    city: 'Visavadar',
    district: 'Junagadh',
  ),
  GujaratHometown(
    id: 'visnagar-mehsana',
    city: 'Visnagar',
    district: 'Mehsana',
  ),
  GujaratHometown(id: 'vyara-tapi', city: 'Vyara', district: 'Tapi'),
  GujaratHometown(
    id: 'waghodia-vadodara',
    city: 'Waghodia',
    district: 'Vadodara',
    aliases: ['Vaghodia'],
  ),
  GujaratHometown(
    id: 'wadhwan-surendranagar',
    city: 'Wadhwan',
    district: 'Surendranagar',
  ),
  GujaratHometown(
    id: 'wankaner-morbi',
    city: 'Wankaner',
    district: 'Morbi',
    aliases: ['Vankaner'],
  ),
];
