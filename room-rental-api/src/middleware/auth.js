const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ message: 'ກະລຸນາເຂົ້າສູ່ລະບົບກ່ອນ' });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    return next();
  } catch (_err) {
    return res.status(401).json({ message: 'ໂທເຄັນບໍ່ຖືກຕ້ອງ ຫຼື ໝົດອາຍຸ' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'ບໍ່ມີສິດເຂົ້າເຖິງສ່ວນນີ້' });
    }
    return next();
  };
}

function optionalAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next();
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
  } catch (_err) {
    req.user = null;
  }
  return next();
}

module.exports = { authenticateToken, requireRole, optionalAuth };
