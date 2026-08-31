import { z } from 'zod'

export const loginSchema = z.object({
  email: z
    .string()
    .min(1, 'Email requis')
    .email('Format email invalide'),
  password: z
    .string()
    .min(1, 'Mot de passe requis'),
})

export const registerSchema = z.object({
  prenom: z
    .string()
    .min(1, 'Prénom requis')
    .max(50, '50 caractères maximum'),
  nom: z
    .string()
    .min(1, 'Nom requis')
    .max(50, '50 caractères maximum'),
  email: z
    .string()
    .min(1, 'Email requis')
    .email('Format email invalide'),
  matricule: z
    .string()
    .optional(),
  password: z
    .string()
    .min(8, '8 caractères minimum')
    .regex(/[A-Z]/, 'Au moins une majuscule')
    .regex(/[0-9]/, 'Au moins un chiffre')
    .regex(/[^A-Za-z0-9]/, 'Au moins un caractère spécial'),
  password_confirmation: z
    .string()
    .min(1, 'Confirmation requise'),
}).refine(d => d.password === d.password_confirmation, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['password_confirmation'],
})

export const changePasswordSchema = z.object({
  current_password: z
    .string()
    .min(1, 'Ancien mot de passe requis'),
  new_password: z
    .string()
    .min(8, '8 caractères minimum')
    .regex(/[A-Z]/, 'Au moins une majuscule')
    .regex(/[0-9]/, 'Au moins un chiffre')
    .regex(/[^A-Za-z0-9]/, 'Au moins un caractère spécial'),
  new_password_confirmation: z
    .string()
    .min(1, 'Confirmation requise'),
}).refine(d => d.new_password === d.new_password_confirmation, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['new_password_confirmation'],
})

export const profileSchema = z.object({
  nom: z
    .string()
    .min(1, 'Nom requis')
    .max(50, '50 caractères maximum'),
  prenom: z
    .string()
    .min(1, 'Prénom requis')
    .max(50, '50 caractères maximum'),
  telephone: z
    .string()
    .optional(),
  direction: z
    .string()
    .optional(),
  service: z
    .string()
    .optional(),
  poste: z
    .string()
    .optional(),
})

export const missionStep1Schema = z.object({
  titre: z
    .string()
    .min(1, 'Titre requis')
    .max(200, '200 caractères maximum'),
  objet_mission: z
    .string()
    .min(1, 'Objet de la mission requis'),
  destination_ville: z
    .string()
    .min(1, 'Ville de destination requise'),
  destination_pays: z
    .string()
    .min(1, 'Pays de destination requis'),
  date_depart: z
    .string()
    .min(1, 'Date de départ requise'),
  date_retour: z
    .string()
    .min(1, 'Date de retour requise'),
  type_mission: z
    .string()
    .min(1, 'Type de mission requis'),
  transport_type: z.enum(['avion', 'terrestre', 'train', 'autre'], { required_error: 'Choisissez le type de transport' }),
  priorite: z
    .string()
    .optional(),
  budget_mode: z.enum(['avance', 'remboursement'], { required_error: 'Choisissez le mode de budget' }),
  description: z
    .string()
    .optional(),
}).refine(d => {
  if (!d.date_depart || !d.date_retour) return true
  return new Date(d.date_retour) > new Date(d.date_depart)
}, {
  message: 'La date de retour doit être après la date de départ',
  path: ['date_retour'],
})
