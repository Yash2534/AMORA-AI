function meta(request) {
  return { requestId: request.adminCorrelationId || null };
}

function success(request, response, message, data = {}, status = 200) {
  return response.status(status).json({ success: true, message, data, meta: meta(request) });
}

function failure(request, response, status, code, message, errors = []) {
  return response.status(status).json({
    success: false,
    message,
    code,
    errors,
    meta: meta(request),
  });
}

module.exports = { success, failure };
