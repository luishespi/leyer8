import { config } from '../config.js';

/**
 * Cliente para la API de NextDNS.
 *
 * Todas las llamadas usan fetch nativo (Node 20+). El API key nunca viaja
 * al cliente Flutter — este servicio solo lo usa el backend.
 *
 * Docs: https://nextdns.github.io/api/
 */

const BASE_URL = 'https://api.nextdns.io';
const REQUEST_TIMEOUT_MS = 15_000;

// IPs anycast estáticas de NextDNS — el router apunta a estas.
// La asociación perfil ↔ red se hace por Linked IP desde el dashboard
// o por DoH/DoT con el profile ID embebido.
const NEXTDNS_IPV4 = ['45.90.28.90', '45.90.30.90'] as const;

interface NextDnsProfileCreated {
  profileId: string;
  dnsIpv4: readonly string[];
  dnsIpv6: [string, string];
  dohUrl: string;
  dotHostname: string;
}

interface NextDnsApiError {
  code: string;
  detail: string;
}

class NextDnsError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public apiErrors?: NextDnsApiError[],
  ) {
    super(message);
    this.name = 'NextDnsError';
  }
}

/**
 * Deriva las direcciones IPv6 a partir del profile ID de NextDNS.
 *
 * Patrón observado: para profile ID "78a865" → 2a07:a8c0::78:a865
 * Se divide el ID en dos mitades y se insertan como los últimos
 * dos grupos del bloque IPv6 de NextDNS.
 */
function deriveIpv6(profileId: string): [string, string] {
  const mid = Math.ceil(profileId.length / 2);
  const first = profileId.slice(0, mid);
  const second = profileId.slice(mid);
  return [
    `2a07:a8c0::${first}:${second}`,
    `2a07:a8c1::${first}:${second}`,
  ];
}

async function apiRequest<T>(
  method: string,
  path: string,
  body?: unknown,
): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  try {
    const res = await fetch(`${BASE_URL}${path}`, {
      method,
      headers: {
        'X-Api-Key': config.NEXTDNS_API_KEY,
        'Content-Type': 'application/json',
      },
      body: body ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    });

    const json = (await res.json()) as
      | { data: T }
      | { errors: NextDnsApiError[] };

    if ('errors' in json) {
      throw new NextDnsError(
        json.errors[0]?.detail ?? 'Error en NextDNS API',
        res.status,
        json.errors,
      );
    }

    if (!res.ok) {
      throw new NextDnsError(
        `NextDNS respondió ${res.status}`,
        res.status,
      );
    }

    return (json as { data: T }).data;
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Crea un perfil nuevo en la master account de NextDNS.
 *
 * Configuración por defecto:
 *   - Seguridad: threat intelligence, malware, phishing, cryptojacking → ON
 *   - Parental control: todo OFF (se configura en Fase 2 desde el panel)
 *   - Logs: activados con retención de 1 hora (mínima, suficiente para alertas)
 *   - Block page: activada (para que el usuario vea que algo fue bloqueado)
 */
export async function createProfile(
  profileName: string,
): Promise<NextDnsProfileCreated> {
  const result = await apiRequest<{ id: string }>('POST', '/profiles', {
    name: profileName,
    security: {
      threatIntelligenceFeeds: true,
      aiThreatDetection: true,
      googleSafeBrowsing: true,
      cryptojacking: true,
      dnsRebinding: true,
      idnHomographs: true,
      typosquatting: true,
      dga: true,
      nrd: false,
      ddns: false,
      parking: false,
      csam: true,
    },
    privacy: {
      blocklists: [{ id: 'nextdns-recommended' }],
      disguisedTrackers: true,
    },
    parentalControl: {
      categories: [],
      services: [],
      safeSearch: false,
      youtubeRestrictedMode: false,
      blockBypass: false,
    },
    settings: {
      logs: { enabled: true, retention: 3600 },
      blockPage: { enabled: true },
      performance: {
        ecs: true,
        cacheBoost: true,
        cnameFlattening: true,
      },
    },
  });

  const profileId = result.id;
  const ipv6 = deriveIpv6(profileId);

  return {
    profileId,
    dnsIpv4: NEXTDNS_IPV4,
    dnsIpv6: ipv6,
    dohUrl: `https://dns.nextdns.io/${profileId}`,
    dotHostname: `${profileId}.dns.nextdns.io`,
  };
}

/**
 * Obtiene la configuración de un perfil existente.
 * Útil para verificar que el perfil sigue activo.
 */
export async function getProfile(
  profileId: string,
): Promise<{ name: string }> {
  return apiRequest<{ name: string }>('GET', `/profiles/${profileId}`);
}

/**
 * Elimina un perfil de NextDNS.
 * Expuesto para cleanup de pruebas / perfiles fallidos.
 */
export async function deleteProfile(profileId: string): Promise<void> {
  await apiRequest<unknown>('DELETE', `/profiles/${profileId}`);
}

export { NextDnsError };