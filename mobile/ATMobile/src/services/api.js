import axios from 'axios';
import { API_BASE_URL } from '../constants/theme';
import * as SecureStore from 'expo-secure-store';

// ── Instance Axios ───────────────────────────────────────────────────────────
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    // Identifie le client mobile → le backend bloque l'accès admin
    'X-Client-Type': 'mobile',
  },
});

// ── Intercepteur : injecte le token Sanctum ──────────────────────────────────
api.interceptors.request.use(async (config) => {
  const token = await SecureStore.getItemAsync('sanctum_token');
  if (token) {
    config.headers.Authorization = 'Bearer ' + token;
  }
  return config;
});

// ── Auth ─────────────────────────────────────────────────────────────────────
export const authAPI = {
  login:  (email, password) => api.post('/auth/login', { email, password }),
  logout: ()               => api.post('/auth/logout'),
  me:     ()               => api.get('/auth/me'),
};

// ── Missions ─────────────────────────────────────────────────────────────────
export const missionAPI = {
  myMissions: (params) => api.get('/missions', { params }),
  detail:     (id)     => api.get('/missions/' + id),
  // Validation (directeur)
  pending:    ()       => api.get('/validations'),
  approuver:  (id, commentaire) =>
    api.post('/validations/' + id + '/approuver', { commentaire }),
  rejeter:    (id, motif) =>
    api.post('/validations/' + id + '/rejeter', { commentaire: motif }),
  demanderModif: (id, commentaire) =>
    api.post('/validations/' + id + '/demander-modification', { commentaire }),
};

// ── DML ──────────────────────────────────────────────────────────────────────
export const dmlAPI = {
  missionsValidees:  (params) => api.get('/dml/missions-validees', { params }),
  logistiqueOk:      (id)     => api.post('/dml/missions/' + id + '/logistique-ok'),
  assignerHotel:     (id, data) => api.post('/dml/missions/' + id + '/assigner-hotel', data),
  assignerVehicule:  (id, data) => api.post('/dml/missions/' + id + '/assigner-vehicule', data),
  hotels:            ()       => api.get('/dml/hotels-conventions'),
  vehicules:         ()       => api.get('/dml/vehicules-disponibles'),
};

// ── Notifications ─────────────────────────────────────────────────────────────
export const notificationsAPI = {
  list:       () => api.get('/notifications'),
  markRead:   (id) => api.patch('/notifications/' + id + '/read'),
  markAll:    () => api.patch('/notifications/read-all'),
  count:      () => api.get('/notifications/unread-count'),
};

export default api;
