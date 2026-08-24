function pagination(query, options = {}) {
  const defaultSize = options.defaultSize || 25;
  const maxSize = options.maxSize || 100;
  const page = Number(query.page || 1);
  const pageSize = Number(query.pageSize || query.limit || defaultSize);
  if (!Number.isInteger(page) || page < 1 || !Number.isInteger(pageSize) || pageSize < 1 || pageSize > maxSize) {
    const error = new Error('Invalid pagination parameters.');
    error.status = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  return { page, pageSize, offset: (page - 1) * pageSize };
}

function sort(query, allowed, fallback) {
  const key = String(query.sortBy || fallback[0]);
  const direction = String(query.sortDirection || fallback[1]).toUpperCase();
  if (!allowed.includes(key) || !['ASC', 'DESC'].includes(direction)) {
    const error = new Error('Invalid sorting parameters.');
    error.status = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  return [key, direction];
}

module.exports = { pagination, sort };
