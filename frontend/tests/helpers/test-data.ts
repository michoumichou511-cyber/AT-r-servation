export function uniqueName(prefix: string): string {
  const ts = Date.now().toString(36);
  return `${prefix}-${ts}`;
}

export const TEST_MISSION = {
  titre: () => uniqueName('Mission-Test'),
  destination: 'Oran',
  objectifs: 'Réunion de travail avec la direction régionale pour le suivi du projet de migration.',
  date_depart: '2026-09-15',
  date_retour: '2026-09-17',
  transport_type: 'terrestre',
  budget_mode: 'remboursement',
};

export const TEST_PRESTATAIRE = {
  nom: () => uniqueName('Prestataire-Test'),
  type: 'hotel',
  telephone: '+213 555 999 888',
  email: 'test@prestataire.dz',
  adresse: '123 Rue Test, Alger',
};
