function pagination(query = {}, { defaultLimit = 20, maxLimit = 50 } = {}) {
  const limit = Math.min(maxLimit, Math.max(1, Number(query.limit) || defaultLimit));
  const page = Math.max(1, Number(query.page) || 1);
  return { limit, page, offset: (page - 1) * limit };
}

module.exports = { pagination };
