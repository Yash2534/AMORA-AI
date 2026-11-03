const EARTH_RADIUS_KM = 6371.0088;
const KM_PER_LATITUDE_DEGREE = 111.32;

function coordinate(value, { minimum, maximum, name }) {
  if (value === null || value === undefined || value === '' || typeof value === 'boolean') {
    throw new TypeError(`${name} must be a finite number between ${minimum} and ${maximum}.`);
  }
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isFinite(parsed) || parsed < minimum || parsed > maximum) {
    throw new TypeError(`${name} must be a finite number between ${minimum} and ${maximum}.`);
  }
  return parsed;
}

function validCoordinates(latitude, longitude) {
  try {
    coordinate(latitude, { minimum: -90, maximum: 90, name: 'latitude' });
    coordinate(longitude, { minimum: -180, maximum: 180, name: 'longitude' });
    return true;
  } catch (_) {
    return false;
  }
}

function distanceKm(viewerLatitude, viewerLongitude, candidateLatitude, candidateLongitude) {
  const lat1 = coordinate(viewerLatitude, { minimum: -90, maximum: 90, name: 'viewerLatitude' });
  const lon1 = coordinate(viewerLongitude, { minimum: -180, maximum: 180, name: 'viewerLongitude' });
  const lat2 = coordinate(candidateLatitude, { minimum: -90, maximum: 90, name: 'candidateLatitude' });
  const lon2 = coordinate(candidateLongitude, { minimum: -180, maximum: 180, name: 'candidateLongitude' });
  const radians = (degrees) => degrees * Math.PI / 180;
  const deltaLatitude = radians(lat2 - lat1);
  const deltaLongitude = radians(lon2 - lon1);
  const a = Math.sin(deltaLatitude / 2) ** 2
    + Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(deltaLongitude / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(Math.max(0, 1 - a)));
}

function distanceBoundingBox(viewerLatitude, viewerLongitude, maximumDistanceKm) {
  const latitude = coordinate(viewerLatitude, { minimum: -90, maximum: 90, name: 'viewerLatitude' });
  const longitude = coordinate(viewerLongitude, { minimum: -180, maximum: 180, name: 'viewerLongitude' });
  const distance = Number(maximumDistanceKm);
  if (!Number.isFinite(distance) || distance <= 0) {
    throw new TypeError('maximumDistanceKm must be a positive finite number.');
  }

  const latitudeDelta = distance / KM_PER_LATITUDE_DEGREE;
  const minimumLatitude = Math.max(-90, latitude - latitudeDelta);
  const maximumLatitude = Math.min(90, latitude + latitudeDelta);
  const cosine = Math.cos(latitude * Math.PI / 180);
  const longitudeDelta = Math.abs(cosine) < 1e-12
    ? 180
    : Math.min(180, distance / (KM_PER_LATITUDE_DEGREE * Math.abs(cosine)));

  if (longitudeDelta >= 180) {
    return { minimumLatitude, maximumLatitude, longitudeRanges: [[-180, 180]] };
  }
  const minimumLongitude = longitude - longitudeDelta;
  const maximumLongitude = longitude + longitudeDelta;
  if (minimumLongitude < -180) {
    return {
      minimumLatitude,
      maximumLatitude,
      longitudeRanges: [[minimumLongitude + 360, 180], [-180, maximumLongitude]],
    };
  }
  if (maximumLongitude > 180) {
    return {
      minimumLatitude,
      maximumLatitude,
      longitudeRanges: [[minimumLongitude, 180], [-180, maximumLongitude - 360]],
    };
  }
  return { minimumLatitude, maximumLatitude, longitudeRanges: [[minimumLongitude, maximumLongitude]] };
}

function sqlDistanceExpression(sequelize, {
  viewerLatitude,
  viewerLongitude,
  profileAlias = 'OnboardingProfile',
} = {}) {
  if (!validCoordinates(viewerLatitude, viewerLongitude)) {
    throw new TypeError('Viewer coordinates are invalid.');
  }
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const latitude = `${quote(profileAlias)}.${quote('matchLatitude')}`;
  const longitude = `${quote(profileAlias)}.${quote('matchLongitude')}`;
  const safeLatitude = sequelize.escape(Number(viewerLatitude));
  const safeLongitude = sequelize.escape(Number(viewerLongitude));
  const cosine = `COS(RADIANS(${safeLatitude})) * COS(RADIANS(${latitude})) * COS(RADIANS(${longitude}) - RADIANS(${safeLongitude})) + SIN(RADIANS(${safeLatitude})) * SIN(RADIANS(${latitude}))`;
  return `${EARTH_RADIUS_KM} * ACOS(LEAST(1, GREATEST(-1, ${cosine})))`;
}

module.exports = {
  EARTH_RADIUS_KM,
  distanceBoundingBox,
  distanceKm,
  sqlDistanceExpression,
  validCoordinates,
};
