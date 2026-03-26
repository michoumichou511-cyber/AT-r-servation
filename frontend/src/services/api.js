import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
    ?? 'https://backend-production-170c.up.railway.app/api',
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('at_token')
  if (token)
    config.headers.Authorization = `Bearer ${token}`
  return config
})

let unauthorizedHandler = () => {}
export const setUnauthorizedHandler = (fn) => {
  unauthorizedHandler = fn
}

api.interceptors.response.use(
  (r) => r,
  (error) => {
    if (error.response?.status === 401) {
      try { unauthorizedHandler() } catch { /* ignore */ }
    }
    return Promise.reject(error)
  }
)

// ── Auth ──────────────────────────────
export const authAPI = {
  login:   (data) => api.post('/auth/login', data),
  logout:  ()     => api.post('/auth/logout'),
  me:      ()     => api.get('/auth/me'),
  register:(data) => api.post('/auth/register', data),
}

// ── Missions ──────────────────────────
export const missionsAPI = {
  list:    (params) => api.get('/missions', { params }),
  get:     (id)     => api.get(`/missions/${id}`),
  create:  (data)   => api.post('/missions', data),
  update:  (id, data) => api.put(`/missions/${id}`, data),
  delete:  (id)     => api.delete(`/missions/${id}`),
  submit:  (id)     => api.post(`/missions/${id}/soumettre`),
  cancel:  (id)     => api.post(`/missions/${id}/annuler`),
  timeline:(id)     => api.get(`/missions/${id}/timeline`),
  documents:(id)    => api.get(`/missions/${id}/documents`),
  bonsCommande:(id) => api.get(`/missions/${id}/bons-commande`),
  uploadDocument:(id, data) =>
    api.post(`/missions/${id}/documents`, data, {
      headers: { 'Content-Type': 'multipart/form-data' }
    }),
  deleteDocument:(missionId, docId) =>
    api.delete(`/missions/${missionId}/documents/${docId}`),
}

// ── Réservations ─────────────────────
export const reservationsAPI = {
  list:    (params) => api.get('/reservations', { params }),
  get:     (id)     => api.get(`/reservations/${id}`),
  create:  (data)   => api.post('/reservations', data),
  update:  (id, data) => api.put(`/reservations/${id}`, data),
  delete:  (id)     => api.delete(`/reservations/${id}`),
  byMission:(missionId) =>
    api.get(`/missions/${missionId}/reservations`),
}

// ── Validations ───────────────────────
export const validationsAPI = {
  list:    (params) => api.get('/validations', { params }),
  approuver:(id, data) =>
    api.post(`/validations/${id}/approuver`, data),
  rejeter: (id, data) =>
    api.post(`/validations/${id}/rejeter`, data),
  demanderModification:(id, data) =>
    api.post(`/validations/${id}/demander-modification`, data),
}

// ── Notifications ─────────────────────
export const notificationsAPI = {
  list:    (params) => api.get('/notifications', { params }),
  countNonLues: () =>
    api.get('/notifications/non-lues/count'),
  marquerLu: (id) =>
    api.put(`/notifications/${id}/marquer-lu`),
  marquerToutLu: () =>
    api.put('/notifications/marquer-tout-lu'),
  supprimer: (id) =>
    api.delete(`/notifications/${id}`),
}

// ── Messages ──────────────────────────
export const messagesAPI = {
  conversations: () =>
    api.get('/messages/conversations'),
  messages: (convId) =>
    api.get(`/messages/conversations/${convId}`),
  envoyer: (data) =>
    api.post('/messages/envoyer', data),
  nonLusCount: () =>
    api.get('/messages/non-lus/count'),
  marquerLu: (convId) =>
    api.put(`/messages/conversations/${convId}/marquer-lu`),
}

// ── Dashboard ─────────────────────────
export const dashboardAPI = {
  stats:   () => api.get('/dashboard/stats'),
  alertes: () => api.get('/dashboard/alertes'),
  missionsDuMois: () =>
    api.get('/dashboard/missions-du-mois'),
  depensesParDirection: () =>
    api.get('/dashboard/depenses-par-direction'),
}

// ── Admin ─────────────────────────────
export const adminAPI = {
  users: {
    list:   (params) =>
      api.get('/admin/users', { params }),
    get:    (id) =>
      api.get(`/admin/users/${id}`),
    create: (data) =>
      api.post('/admin/users', data),
    update: (id, data) =>
      api.put(`/admin/users/${id}`, data),
    delete: (id) =>
      api.delete(`/admin/users/${id}`),
    toggleActive: (id) =>
      api.put(`/admin/users/${id}/toggle-active`),
  },
  prestataires: {
    list:   (params) =>
      api.get('/prestataires', { params }),
    get:    (id) =>
      api.get(`/prestataires/${id}`),
    create: (data) =>
      api.post('/prestataires', data),
    update: (id, data) =>
      api.put(`/prestataires/${id}`, data),
    delete: (id) =>
      api.delete(`/prestataires/${id}`),
    toggleFavori: (id) =>
      api.put(`/prestataires/${id}/toggle-favori`),
    evaluer: (id, data) =>
      api.post(`/prestataires/${id}/evaluer`, data),
  },
  budgets: {
    list:   (params) =>
      api.get('/admin/budgets', { params }),
    get:    (id) =>
      api.get(`/admin/budgets/${id}`),
    create: (data) =>
      api.post('/admin/budgets', data),
    update: (id, data) =>
      api.put(`/admin/budgets/${id}`, data),
    delete: (id) =>
      api.delete(`/admin/budgets/${id}`),
    stats:  () =>
      api.get('/admin/budgets/stats'),
  },
  auditLogs: {
    list:   (params) =>
      api.get('/admin/audit-logs', { params }),
  },
  statistiques: {
    general: (params) =>
      api.get('/admin/statistiques', { params }),
    missions: (params) =>
      api.get('/admin/statistiques/missions',
        { params }),
    prestataires: (params) =>
      api.get('/admin/statistiques/prestataires',
        { params }),
  },
}

// ── Rapports / Export ─────────────────
export const exportAPI = {
  missions: (params) =>
    api.get('/rapports/missions', {
      params, responseType: 'blob' }),
  budgets: (params) =>
    api.get('/rapports/budgets', {
      params, responseType: 'blob' }),
  prestataires: (params) =>
    api.get('/rapports/prestataires', {
      params, responseType: 'blob' }),
  auditLogs: (params) =>
    api.get('/rapports/audit-logs', {
      params, responseType: 'blob' }),
}

// ── Bons de commande ──────────────────
export const bonCommandeAPI = {
  list:    (params) =>
    api.get('/bons-commande', { params }),
  get:     (id) =>
    api.get(`/bons-commande/${id}`),
  generer: (missionId) =>
    api.post(`/missions/${missionId}/generer-bon`),
  telecharger: (id) =>
    api.get(`/bons-commande/${id}/telecharger`, {
      responseType: 'blob' }),
}

// ── Recherche ─────────────────────────
export const searchAPI = {
  global: (q) =>
    api.get('/search', { params: { q } }),
}

// ── Health ────────────────────────────
export const healthAPI = {
  check: () => api.get('/health'),
}

// ── Utilitaire téléchargement ─────────
export const telechargerBlob = (blob, nom) => {
  const url = URL.createObjectURL(blob)
  const a   = document.createElement('a')
  a.href    = url
  a.download = nom
  a.click()
  URL.revokeObjectURL(url)
}

export default api
