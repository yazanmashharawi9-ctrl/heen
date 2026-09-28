// Minimal JWT signing with WebCrypto — enough for APNs (ES256) and Google's
// OAuth service-account flow for FCM (RS256). Runs unchanged on Deno
// (Supabase Edge Runtime) and Node 24, so it is unit-tested under Node.

const encoder = new TextEncoder();

export function base64url(input: ArrayBuffer | Uint8Array | string): string {
  const bytes = typeof input === "string" ? encoder.encode(input) : new Uint8Array(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** DER bytes of a PKCS#8 "-----BEGIN PRIVATE KEY-----" PEM (what .p8 files and service accounts contain). */
export function pemToPkcs8(pem: string): Uint8Array<ArrayBuffer> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\\n/g, "") // service-account JSON sometimes arrives with literal "\n"
    .replace(/\s+/g, "");
  if (!body) throw new Error("empty private key");
  const binary = atob(body);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out;
}

export type JwtAlg = "ES256" | "RS256";

export function importSigningKey(pem: string, alg: JwtAlg): Promise<CryptoKey> {
  const algorithm = alg === "ES256"
    ? { name: "ECDSA", namedCurve: "P-256" }
    : { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" };
  return crypto.subtle.importKey("pkcs8", pemToPkcs8(pem), algorithm, false, ["sign"]);
}

export async function signJwt(
  header: Record<string, unknown>,
  claims: Record<string, unknown>,
  key: CryptoKey,
  alg: JwtAlg,
): Promise<string> {
  const signingInput = `${base64url(JSON.stringify({ ...header, alg, typ: "JWT" }))}.${base64url(JSON.stringify(claims))}`;
  // WebCrypto's ECDSA output is already the raw r||s form JOSE expects.
  const signature = await crypto.subtle.sign(
    alg === "ES256" ? { name: "ECDSA", hash: "SHA-256" } : { name: "RSASSA-PKCS1-v1_5" },
    key,
    encoder.encode(signingInput),
  );
  return `${signingInput}.${base64url(signature)}`;
}
