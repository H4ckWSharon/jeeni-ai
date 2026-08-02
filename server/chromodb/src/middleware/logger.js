/**
 * ChromoDB — Request Logger Middleware
 * Logs: METHOD /path STATUS DURATIONms
 */
function requestLogger(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const ms     = Date.now() - start;
    const status = res.statusCode;
    const color  = status >= 500 ? '31' : status >= 400 ? '33' : status >= 200 ? '32' : '36';
    console.log(
      `\x1b[${color}m${req.method}\x1b[0m ${req.path} \x1b[${color}m${status}\x1b[0m ${ms}ms`
    );
  });
  next();
}

module.exports = { requestLogger };
