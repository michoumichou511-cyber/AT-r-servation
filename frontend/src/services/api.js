import axios from 'axios';

/** Enregistré depuis l’app (Router) pour éviter window.location = flash blanc sur 401 */
let unauthorizedHandler = null;
export function setUnauthorizedHandler(fn) {
  unauthorizedHandler = typeof fn === 'function' ? fn : null;
}

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? 'http://127.0.0.1:8000/api',
  headers: { 'Content-Type': 'application/json' },
});

// Ajoute le token automatiquement
api.interceptors.request.use(config => {
  const token = localStorage.getItem('at_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Gère les erreurs globalement
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('at_token');
      localStorage.removeItem('at_user');
      if (unauthorizedHandler) {
        try {
          unauthorizedHandler();
        } catch {
          /* ignore */
        }
      } else {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// ─── Helper pour télécharger un blob ───────────────────
export const telechargerBlob = (data, nomFichier) => {
  const url  = window.URL.createObjectURL(new Blob([data]));
  const link = document.createElement('a');
  link.href  = url;
  link.setAttribute('download', nomFichier);
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.URL.revokeObjectURL(url);
};

// ─── AUTH ───────────────────────────────────────────────
export const authAPI = {
  login:          (data) => api.post('/auth/login', data),
  register:       (data) => api.post('/auth/register', data),
  logout:         ()     => api.post('/auth/logout'),
  me:             ()     => api.get('/auth/me'),
  updateProfile:  (data) => api.put('/auth/profile', data),
  changePassword: (data) => api.post('/auth/change-password', data),
  statistiques:   ()     => api.get('/profil/statistiques'),
  uploadAvatar:   (form) => api.post('/auth/avatar', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  }),
};

// ─── MISSIONS ──────────────────────────────────────────
export const missionsAPI = {
  list:         (params)   => api.get('/missions', { params }),
  create:       (data)     => api.post('/missions', data),
  get:          (id)       => api.get(`/missions/${id}`),
  update:       (id, data) => api.put(`/missions/${id}`, data),
  delete:       (id)       => api.delete(`/missions/${id}`),
  submit:       (id)       => api.post(`/missions/${id}/submit`),
  cancel:       (id)       => api.post(`/missions/${id}/cancel`),
  duplicate:    (id)       => api.post(`/missions/${id}/duplicate`),
  exportPdf:    (id)       => api.get(`/missions/${id}/export/pdf`,
                               { responseType: 'blob' }),
  historique:   (id)       => api.get(`/missions/${id}/historique`),
  bonsCommande: (id)       => api.get(`/missions/${id}/bons-commande`),
  calendrier:   (params)   => api.get('/calendrier', { params }),
};

// ─── RÉSERVATIONS ──────────────────────────────────────
export const reservationsAPI = {
  list:            (missionId)       => api.get(`/missions/${missionId}/reservations`),
  create:          (missionId, data) => api.post(`/missions/${missionId}/reservations`, data),
  update:          (id, data)        => api.put(`/reservations/${id}`, data),
  delete:          (id)              => api.delete(`/reservations/${id}`),
  addBillet:       (resId, data)     => api.post(`/reservations/${resId}/billet`, data),
  addHebergement:  (resId, data)     => api.post(`/reservations/${resId}/hebergement`, data),
  addRestauration: (resId, data)     => api.post(`/reservations/${resId}/restauration`, data),
  confirmerBillet: (id, data)        => api.post(`/billets/${id}/confirmer`, data),
  confirmerHeberg: (id, data)        => api.post(`/hebergements/${id}/confirmer`, data),
  confirmerRest:   (id)              => api.post(`/restaurations/${id}/confirmer`),
};

// ─── VALIDATIONS ───────────────────────────────────────
export const validationsAPI = {
  list:      ()         => api.get('/validations'),
  get:       (id)       => api.get(`/validations/${id}`),
  approuver: (id, data) => api.post(`/validations/${id}/approuver`, data),
  rejeter:   (id, data) => api.post(`/validations/${id}/rejeter`, data),
  modifier:  (id, data) => api.post(`/validations/${id}/modifier`, data),
};

// ─── NOTIFICATIONS ─────────────────────────────────────
export const notificationsAPI = {
  list:          ()   => api.get('/notifications'),
  count:         ()   => api.get('/notifications/non-lues/count'),
  marquerLu:     (id) => api.put(`/notifications/${id}/lire`),
  marquerToutLu: ()   => api.put('/notifications/tout-lire'),
  supprimer:     (id) => api.delete(`/notifications/${id}`),
};

// ─── MESSAGERIE ────────────────────────────────────────
export const messagesAPI = {
  conversations: ()       => api.get('/conversations'),
  messages:      (convId) => api.get(`/conversations/${convId}/messages`),
  envoyer:       (data)   => api.post('/messages', data),
  marquerLu:     (id)     => api.put(`/messages/${id}/lire`),
  nonLusCount:   ()       => api.get('/messages/non-lus/count'),
  contacts:      (q)      => api.get('/utilisateurs/contacts', { params: { search: q } }),
};

// ─── DOCUMENTS ─────────────────────────────────────────
export const documentsAPI = {
  list:        (missionId)       => api.get(`/missions/${missionId}/documents`),
  upload:      (missionId, form) => api.post(
                 `/missions/${missionId}/documents`, form,
                 { headers: { 'Content-Type': 'multipart/form-data' } }),
  delete:      (id)              => api.delete(`/documents/${id}`),
  telecharger: (id)              => api.get(
                 `/documents/${id}/telecharger`,
                 { responseType: 'blob' }),
};

// ─── DASHBOARD ─────────────────────────────────────────
export const dashboardAPI = {
  stats:                ()       => api.get('/dashboard/stats'),
  alertes:              ()       => api.get('/dashboard/alertes'),
  missionsDuMois:       ()       => api.get('/dashboard/missions-du-mois'),
  depensesParDirection: (params) => api.get('/dashboard/depenses-par-direction', { params }),
  validateur:           ()       => api.get('/dashboard/validateur'),
};

// ─── ADMIN ─────────────────────────────────────────────
export const adminAPI = {
  // Utilisateurs
  utilisateurs:         (params) => api.get('/admin/utilisateurs', { params }),
  toggleActif:          (id)     => api.put(`/admin/utilisateurs/${id}/toggle-active`),
  changerRole:          (id, d)  => api.put(`/admin/utilisateurs/${id}/role`, d),
  contacts:             (q)      => api.get('/utilisateurs/contacts', { params: { search: q } }),

  // Prestataires
  prestataires:         (params) => api.get('/prestataires', { params }),
  prestaDetail:         (id)     => api.get(`/prestataires/${id}`),
  prestaFavoris:        ()       => api.get('/prestataires/favoris'),
  toggleFavori:         (id)     => api.post(`/prestataires/${id}/favori`),
  evaluerPrestataire:   (id, d)  => api.post(`/prestataires/${id}/evaluer`, d),
  evaluationsPresta:    (id)     => api.get(`/prestataires/${id}/evaluations`),
  creerPrestataire:     (data)   => api.post('/admin/prestataires', data),
  modifierPrestataire:  (id, d)  => api.put(`/admin/prestataires/${id}`, d),
  supprimerPrestataire: (id)     => api.delete(`/admin/prestataires/${id}`),

  // Budgets
  budgets:              ()       => api.get('/admin/budgets'),
  creerBudget:          (data)   => api.post('/admin/budgets', data),
  modifierBudget:       (id, d)  => api.put(`/admin/budgets/${id}`, d),

  // Audit
  auditLogs:            (params) => api.get('/admin/audit-logs', { params }),
};

// ─── EXPORTS ───────────────────────────────────────────
export const exportAPI = {
  missionsExcel:     (params) => api.get('/export/missions/excel',
                                  { params, responseType: 'blob' }),
  missionsPdf:       (params) => api.get('/export/missions/pdf',
                                  { params, responseType: 'blob' }),
  depensesExcel:     (params) => api.get('/export/depenses/excel',
                                  { params, responseType: 'blob' }),
  prestatairesExcel: (params) => api.get('/export/prestataires/excel',
                                  { params, responseType: 'blob' }),
};

// ─── BONS DE COMMANDE ──────────────────────────────────
export const bonCommandeAPI = {
  parMission:    (missionId) => api.get(`/missions/${missionId}/bons-commande`),
  marquerEnvoye: (id)        => api.put(`/bons-commande/${id}/envoyer`),
};

// ─── RECHERCHE ─────────────────────────────────────────
export const searchAPI = {
  search: (q) => api.get('/search', { params: { q } }),
};

// ─── HEALTH ────────────────────────────────────────────
export const healthAPI = {
  check: () => api.get('/health'),
};

export default api;
