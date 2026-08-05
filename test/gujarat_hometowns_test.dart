import 'package:amora_ai/core/data/gujarat_hometowns.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gujaratDistricts = <String>{
    'Ahmedabad',
    'Amreli',
    'Anand',
    'Aravalli',
    'Banaskantha',
    'Bharuch',
    'Bhavnagar',
    'Botad',
    'Chhota Udaipur',
    'Dahod',
    'Dang',
    'Devbhoomi Dwarka',
    'Gandhinagar',
    'Gir Somnath',
    'Jamnagar',
    'Junagadh',
    'Kachchh',
    'Kheda',
    'Mahisagar',
    'Mehsana',
    'Morbi',
    'Narmada',
    'Navsari',
    'Panchmahal',
    'Patan',
    'Porbandar',
    'Rajkot',
    'Sabarkantha',
    'Surat',
    'Surendranagar',
    'Tapi',
    'Vadodara',
    'Valsad',
    'Vav-Tharad',
  };

  test('source is Gujarat-only, unique, stable, and alphabetical', () {
    final locations = GujaratHometowns.all;
    final ids = locations.map((location) => location.id).toList();
    final values = locations.map((location) => location.storageValue).toList();
    final sorted = [...locations]
      ..sort((a, b) {
        final cityComparison = a.city.compareTo(b.city);
        return cityComparison != 0
            ? cityComparison
            : a.district.compareTo(b.district);
      });

    expect(locations, hasLength(177));
    expect(ids.toSet(), hasLength(ids.length));
    expect(values.toSet(), hasLength(values.length));
    expect(locations, orderedEquals(sorted));
    expect(
      locations.map((location) => location.district).toSet(),
      gujaratDistricts,
    );
    expect(
      values,
      isNot(
        containsAll(<String>[
          'New Delhi',
          'Mumbai',
          'Pune',
          'Bengaluru',
          'Gurugram',
          'Noida',
          'Chennai',
        ]),
      ),
    );
  });

  test(
    'major Gujarat hometowns and every requested district hub are present',
    () {
      const requiredCities = <String>{
        'Ahmedabad',
        'Gandhinagar',
        'Surat',
        'Vadodara',
        'Rajkot',
        'Bhavnagar',
        'Jamnagar',
        'Junagadh',
        'Anand',
        'Nadiad',
        'Bharuch',
        'Ankleshwar',
        'Navsari',
        'Valsad',
        'Vapi',
        'Mehsana',
        'Patan',
        'Palanpur',
        'Himatnagar',
        'Godhra',
        'Dahod',
        'Morbi',
        'Surendranagar',
        'Porbandar',
        'Veraval',
        'Amreli',
        'Botad',
        'Bhuj',
        'Gandhidham',
        'Mundra',
        'Dwarka',
        'Somnath',
        'Modasa',
        'Lunawada',
        'Chhota Udaipur',
        'Rajpipla',
        'Vyara',
        'Ahwa',
      };

      expect(
        GujaratHometowns.all.map((location) => location.city).toSet(),
        containsAll(requiredCities),
      );
    },
  );

  test('search supports city, district, and known alternate spellings', () {
    expect(
      GujaratHometowns.search('Ahmedabad').map((location) => location.city),
      contains('Ahmedabad'),
    );
    expect(
      GujaratHometowns.search('Gir Somnath').map((location) => location.city),
      containsAll(<String>['Somnath', 'Veraval']),
    );
    expect(
      GujaratHometowns.search('Baroda').map((location) => location.city),
      contains('Vadodara'),
    );
    expect(
      GujaratHometowns.search('Kutch').map((location) => location.city),
      containsAll(<String>['Bhuj', 'Gandhidham', 'Mundra']),
    );
  });

  test('legacy values normalize and public labels never expose IDs', () {
    expect(ProfileFormOptions.normalizeHometown('Ahemdabad'), 'Ahmedabad');
    expect(
      ProfileFormOptions.displayHometown('Ahmedabad'),
      'Ahmedabad, Gujarat',
    );
    expect(
      ProfileFormOptions.displayHometown('Kalol, Panchmahal'),
      'Kalol, Panchmahal, Gujarat',
    );
    expect(ProfileFormOptions.displayHometown('Mumbai'), isEmpty);
    expect(
      ProfileFormOptions.displayHometown('ahmedabad-ahmedabad'),
      'Ahmedabad, Gujarat',
    );
  });
}
