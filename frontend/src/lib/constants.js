export const MISSION_STATUTS = {
  brouillon: { label: 'Brouillon', color: 'gray', icon: '📝' },
  soumis: { label: 'Soumis', color: 'blue', icon: '📤' },
  en_validation: { label: 'En validation', color: 'orange', icon: '⏳' },
  approuve: { label: 'Approuvé', color: 'green', icon: '✅' },
  rejete: { label: 'Rejeté', color: 'red', icon: '❌' },
  annule: { label: 'Annulé', color: 'gray', icon: '🚫' },
}

export const ROLES = {
  admin: { label: 'Administrateur', level: 4 },
  validateur: { label: 'Validateur', level: 3 },
  utilisateur: { label: 'Utilisateur', level: 2 },
  demandeur: { label: 'Demandeur', level: 1 },
}

export const TYPES_MISSION = [
  'formation',
  'reunion',
  'audit',
  'conference',
  'inspection',
  'autre',
]

export const PAGINATION = {
  DEFAULT_PER_PAGE: 15,
  OPTIONS: [10, 15, 25, 50],
}

export const API_ENDPOINTS = {
  MISSIONS: '/api/missions',
  RESERVATIONS: '/api/reservations',
  NOTIFICATIONS: '/api/notifications',
  MESSAGES: '/api/messages',
  USERS: '/api/admin/users',
  HEALTH: '/api/health',
}
