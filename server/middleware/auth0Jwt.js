import * as jose from "jose";

let remoteJwks;

function issuerBaseUrl() {
  const raw = process.env.AUTH0_ISSUER_BASE_URL?.trim();
  if (!raw) return "";
  return raw.endsWith("/") ? raw : `${raw}/`;
}

/** JWKS URL derived from issuer (matches Auth0 standard discovery layout). */
function jwksUri(base) {
  return new URL("jwks.json", `${base}.well-known/`).toString();
}

export function authConfigured() {
  return Boolean(issuerBaseUrl() && process.env.AUTH0_AUDIENCE?.trim());
}

function audienceList() {
  const aud = process.env.AUTH0_AUDIENCE?.trim();
  if (!aud) return [];
  return aud.split(",").map((a) => a.trim()).filter(Boolean);
}

function emailNamespace() {
  return (
    process.env.AUTH0_EMAIL_CLAIM_NAMESPACE?.trim() || "https://reliefnet.app/"
  );
}

function adminEmails() {
  return new Set(
    (process.env.ADMIN_EMAILS || "")
      .split(",")
      .map((s) => s.trim().toLowerCase())
      .filter(Boolean),
  );
}

export function extractUser(payload) {
  if (!payload || typeof payload !== "object") return null;
  const sub = typeof payload.sub === "string" ? payload.sub : "";
  if (!sub) return null;

  const ns = emailNamespace();
  const email =
    (typeof payload.email === "string" && payload.email.trim()) ||
    (typeof payload[`${ns}email`] === "string" &&
      String(payload[`${ns}email`]).trim()) ||
    "";

  const roleNs = process.env.AUTH0_ROLE_CLAIM_NAMESPACE?.trim() || ns;
  const rawRoles = payload[`${roleNs}roles`];
  let roles = [];
  if (Array.isArray(rawRoles)) roles = rawRoles.map(String);
  else if (typeof rawRoles === "string" && rawRoles)
    roles = rawRoles.split(",").map((s) => s.trim());

  const admins = adminEmails();
  const isAdmin =
    (email && admins.has(email.toLowerCase())) ||
    roles.some((r) => {
      const x = String(r).toLowerCase();
      return x === "admin" || x === "responder";
    });

  return { sub, email, isAdmin, roles };
}

function getJwks() {
  const issuer = issuerBaseUrl();
  if (!issuer) throw new Error("AUTH0_ISSUER_BASE_URL missing");
  if (!remoteJwks) {
    remoteJwks = jose.createRemoteJWKSet(new URL(jwksUri(issuer)));
  }
  return remoteJwks;
}

/**
 * If Authorization Bearer present and Auth0 configured, verify JWT and set req.authUser.
 * Invalid/expired token → 401. No header → req.authUser = null.
 */
export async function optionalBearerJwt(req, res, next) {
  req.authUser = null;

  if (!authConfigured()) return next();

  const hdr = req.headers.authorization;
  if (!hdr?.startsWith("Bearer ")) return next();

  const token = hdr.slice(7).trim();
  if (!token) return next();

  const base = issuerBaseUrl();
  const issuerSlash = base.endsWith("/") ? base : `${base}/`;
  const issuerNoSlash = issuerSlash.replace(/\/$/, "");
  const issuerCandidates = Array.from(
    new Set([issuerSlash, issuerNoSlash, `${issuerNoSlash}/`]),
  );
  const audiences = audienceList();

  try {
    const { payload } = await jose.jwtVerify(token, getJwks(), {
      issuer: issuerCandidates,
      audience: audiences.length === 1 ? audiences[0] : audiences,
    });
    req.authUser = extractUser(payload);
    if (!req.authUser?.sub) {
      return res.status(401).json({ error: "Access token missing subject." });
    }
    next();
  } catch (e) {
    console.warn("JWT verify failed:", e?.message || e);
    return res.status(401).json({ error: "Invalid or expired access token." });
  }
}

export function requireUser(req, res, next) {
  if (!authConfigured()) return next();
  if (!req.authUser?.sub) {
    return res.status(401).json({ error: "Sign in required." });
  }
  next();
}

export function requireAdmin(req, res, next) {
  if (!authConfigured()) return next();
  if (!req.authUser?.sub) {
    return res.status(401).json({ error: "Sign in required." });
  }
  if (!req.authUser.isAdmin) {
    return res.status(403).json({ error: "Responder or admin role required." });
  }
  next();
}
