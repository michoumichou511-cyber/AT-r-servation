import axios from 'axios';

/**
 * PROD (Railway) : URL API hardcodée pour éviter les problèmes Vercel env.
 * Note: on garde la clé de token existante du projet: at_token.
 */
const API_URL = 'https://backend-production-170c.up.railway.app/api';

const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('at_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default api;
