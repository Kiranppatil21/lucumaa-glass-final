// Centralized API base that is safe in production.
// If the build accidentally embeds a localhost backend URL, we fall back to same-origin.

export const getApiOrigin = () => {
  const env = String(process.env.REACT_APP_BACKEND_URL || '').trim().replace(/\/$/, '');

  if (typeof window === 'undefined') {
    return env;
  }

  const host = window.location.hostname;
  const isProdHost = host && host !== 'localhost' && host !== '127.0.0.1';
  const isEnvLocal = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(env);

  // If we're running on a real domain but env points to localhost, ignore env.
  if (isProdHost && isEnvLocal) {
    return '';
  }

  return env;
};

export const API_ORIGIN = getApiOrigin();
export const API_ROOT = API_ORIGIN ? `${API_ORIGIN}/api` : '/api';
