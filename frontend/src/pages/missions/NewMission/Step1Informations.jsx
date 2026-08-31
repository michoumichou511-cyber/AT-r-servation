import { useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Info, CalendarDays, Save, RotateCcw, ClipboardList, X, Loader2 } from 'lucide-react'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { missionStep1Schema } from '../../../lib/validations'
import { WILAYAS, PAYS_FREQUENTS } from '../../../lib/wilayas'
import { missionsAPI } from '../../../services/api'

import { Button, Input, Select } from '../../../components/UI'

const TYPE_MISSION_OPTIONS = [
  { value: 'formation', label: 'Formation' },
  { value: 'conference', label: 'Conférence' },
  { value: 'reunion', label: 'Réunion' },
  { value: 'inspection', label: 'Inspection' },
  { value: 'audit', label: 'Audit' },
  { value: 'autre', label: 'Autre' },
]

const PRIORITE_OPTIONS = [
  { value: 'normale', label: 'Normale' },
  { value: 'urgente', label: 'Urgente' },
  { value: 'tres_urgente', label: 'Très urgente' },
]

const DRAFT_KEY = 'at_new_mission_draft_v1'
const REQUIRED_FIELDS = ['titre', 'objet_mission', 'destination_ville', 'destination_pays', 'date_depart', 'date_retour', 'type_mission', 'transport_type', 'budget_mode']
const DESCRIPTION_MAX = 1000

function loadDraft() {
  try {
    const raw = localStorage.getItem(DRAFT_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw)
    return parsed?.values ?? null
  } catch {
    return null
  }
}

function saveDraft(values) {
  try {
    localStorage.setItem(DRAFT_KEY, JSON.stringify({ values, savedAt: Date.now() }))
  } catch { /* stockage plein : on ignore silencieusement */ }
}

export function clearMissionDraft() {
  try { localStorage.removeItem(DRAFT_KEY) } catch { /* noop */ }
}

export default function Step1Informations({ onNext, data, missionId, loading, error }) {
  const [templateModalOpen, setTemplateModalOpen] = useState(false)
  const [templates, setTemplates] = useState([])
  const [templatesLoading, setTemplatesLoading] = useState(false)

  const openTemplateModal = async () => {
    setTemplateModalOpen(true)
    setTemplatesLoading(true)
    try {
      const res = await missionsAPI.templates()
      const list = res.data?.data?.data ?? res.data?.data ?? res.data ?? []
      setTemplates(Array.isArray(list) ? list : [])
    } catch {
      setTemplates([])
    } finally {
      setTemplatesLoading(false)
    }
  }

  const applyTemplate = (tpl) => {
    const d = tpl.mission_data ?? {}
    const dest = d.destination ?? ''
    const parts = dest.split(',').map(s => s.trim())
    setValue('titre', d.titre ?? '', { shouldValidate: true })
    setValue('objet_mission', d.objet_mission ?? '', { shouldValidate: true })
    setValue('destination_ville', d.destination_ville ?? parts[0] ?? '', { shouldValidate: true })
    setValue('destination_pays', d.destination_pays ?? parts[1] ?? '', { shouldValidate: true })
    setValue('type_mission', d.type_mission ?? '', { shouldValidate: true })
    setValue('transport_type', d.transport_type ?? '', { shouldValidate: true })
    setValue('budget_mode', d.budget_mode ?? '', { shouldValidate: true })
    setValue('priorite', d.priorite ?? '', { shouldValidate: true })
    setTemplateModalOpen(false)
  }

  // Date locale (pas toISOString qui est UTC : à 00h30 locale, le min serait "hier")
  const todayStr = useMemo(() => {
    const d = new Date()
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }, [])
  const [savedAt, setSavedAt] = useState(null)
  const [draftRestored, setDraftRestored] = useState(false)

  const initial = useMemo(() => {
    const base = {
      titre: data?.titre ?? '',
      objet_mission: data?.objet_mission ?? '',
      destination_ville: data?.destination_ville ?? '',
      destination_pays: data?.destination_pays ?? '',
      date_depart: data?.date_depart ?? '',
      date_retour: data?.date_retour ?? '',
      type_mission: data?.type_mission ?? '',
      transport_type: data?.transport_type ?? '',
      priorite: data?.priorite ?? '',
      budget_mode: data?.budget_mode ?? '',
      demande_avance: data?.demande_avance ?? false,
      montant_avance: data?.montant_avance ?? '',
      description: data?.description ?? '',
    }
    // Restaurer le brouillon local uniquement pour une nouvelle mission vierge
    if (!missionId && !data?.titre) {
      const draft = loadDraft()
      if (draft && Object.values(draft).some((v) => v !== '' && v != null)) {
        return { ...base, ...draft, __draftRestored: undefined } // merged
      }
    }
    return base
  }, [data, missionId])

  const {
    control,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors: formErrors, touchedFields },
  } = useForm({
    resolver: zodResolver(missionStep1Schema),
    defaultValues: initial,
    mode: 'onBlur',
    reValidateMode: 'onChange',
  })

  useEffect(() => {
    reset(initial)
    if (!missionId && !data?.titre) {
      const draft = loadDraft()
      if (draft && Object.values(draft).some((v) => v !== '' && v != null)) {
        setDraftRestored(true)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initial, reset])

  // Focus automatique sur le premier champ
  useEffect(() => {
    const el = document.querySelector('form input')
    if (el) el.focus()
  }, [])

  const values = watch()

  // Auto-sauvegarde du brouillon (debounce 800ms) — uniquement avant création serveur
  useEffect(() => {
    if (missionId) return
    const hasContent = REQUIRED_FIELDS.some((f) => values[f]) || values.description || values.budget_previsionnel
    if (!hasContent) return
    const t = setTimeout(() => {
      saveDraft(values)
      setSavedAt(new Date())
    }, 800)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [JSON.stringify(values), missionId])

  // Durée de mission calculée en direct
  const dureeJours = useMemo(() => {
    if (!values.date_depart || !values.date_retour) return null
    const d1 = new Date(values.date_depart)
    const d2 = new Date(values.date_retour)
    if (isNaN(d1) || isNaN(d2) || d2 <= d1) return null
    return Math.round((d2 - d1) / 86400000)
  }, [values.date_depart, values.date_retour])

  // Progression du formulaire
  const filledCount = REQUIRED_FIELDS.filter((f) => values[f]).length
  const progressPct = Math.round((filledCount / REQUIRED_FIELDS.length) * 100)

  const isValid = (name) => touchedFields[name] && !formErrors[name] && !!values[name]

  const resetDraft = () => {
    clearMissionDraft()
    setDraftRestored(false)
    setSavedAt(null)
    reset({
      titre: '', objet_mission: '', destination_ville: '', destination_pays: '',
      date_depart: '', date_retour: '', type_mission: '', transport_type: '',
      priorite: '', budget_mode: '', demande_avance: false, montant_avance: '', description: '',
    })
  }

  const onSubmit = async (formData) => {
    if (loading) return

    const payload = {
      titre: formData.titre.trim(),
      objet_mission: formData.objet_mission.trim(),
      destination_ville: formData.destination_ville.trim(),
      destination_pays: formData.destination_pays.trim(),
      date_depart: formData.date_depart,
      date_retour: formData.date_retour,
      type_mission: formData.type_mission,
      transport_type: formData.transport_type,
      ...(formData.priorite ? { priorite: formData.priorite } : {}),
      budget_mode: formData.budget_mode,
      demande_avance: !!formData.demande_avance,
      ...(formData.demande_avance && formData.montant_avance
        ? { montant_avance: Number(formData.montant_avance) }
        : {}),
      ...(String(formData.description ?? '').trim()
        ? { description: formData.description.trim() }
        : {}),
    }

    await onNext(payload)
    clearMissionDraft()
  }

  // Ctrl+Entrée pour valider l'étape
  const onKeyDown = (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault()
      handleSubmit(onSubmit)()
    }
  }

  const firstError = Object.values(formErrors)[0]?.message

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, ease: [0.25, 0.1, 0.25, 1] }}
    >
      <div className="flex items-start justify-between gap-4 mb-3 flex-wrap">
        <div>
          <h3 className="text-base font-semibold text-[#1A1D26] dark:text-[#E8EAF0] mb-2">Informations générales</h3>
          <p className="text-sm text-[#9AA0AE]">
            {missionId ? 'Mise à jour de la mission (brouillon)' : 'Créez votre mission (brouillon)'}.
          </p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          {savedAt && !missionId && (
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#F4F6FA] dark:bg-[#252840] text-[#5A6070] dark:text-[#9AA0AE] text-xs">
              <Save size={12} /> Brouillon sauvegardé à {savedAt.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
            </span>
          )}
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-at-green/10 border border-at-green/20 text-at-green text-xs font-semibold">
            <Info size={14} /> Étape 1/4
          </div>
        </div>
      </div>

      {/* Charger depuis un template */}
      {!missionId && (
        <button
          type="button"
          onClick={openTemplateModal}
          className="flex items-center gap-2 px-4 py-2.5 mb-4 rounded-xl border border-dashed border-at-green/40
                     text-sm font-medium text-at-green hover:bg-at-green/5 dark:hover:bg-at-green/10 transition-colors"
        >
          <ClipboardList size={16} />
          Charger depuis un template
        </button>
      )}

      {/* Barre de progression du formulaire */}
      <div className="mb-5">
        <div className="flex items-center justify-between mb-1.5">
          <span className="text-xs text-[#9AA0AE] dark:text-[#5A6070]">
            {filledCount}/{REQUIRED_FIELDS.length} champs requis remplis
          </span>
          <span className={`text-xs font-semibold ${progressPct === 100 ? 'text-at-green' : 'text-[#9AA0AE]'}`}>
            {progressPct}%
          </span>
        </div>
        <div className="h-1.5 rounded-full bg-[#F4F6FA] dark:bg-[#252840] overflow-hidden">
          <div
            className="h-full rounded-full bg-at-green transition-[width] duration-500 ease-out will-change-[width]"
            style={{ width: `${progressPct}%` }}
          />
        </div>
      </div>

      {draftRestored && !missionId && (
        <div className="flex items-center justify-between gap-3 bg-at-blue/5 border border-at-blue/20 rounded-xl px-4 py-3 mb-4">
          <div className="text-sm text-at-blue dark:text-blue-300">
            📄 Votre brouillon précédent a été restauré automatiquement.
          </div>
          <button
            type="button"
            onClick={resetDraft}
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#5A6070] hover:text-red-500 transition-colors"
          >
            <RotateCcw size={12} /> Recommencer à zéro
          </button>
        </div>
      )}

      {(error || firstError) && (
        <div className="bg-red-50 border border-red-200 dark:bg-red-950/30 dark:border-red-900/50 rounded-2xl p-4 mb-4">
          <div className="text-sm text-red-800 dark:text-red-200 font-semibold mb-1">Erreur</div>
          <div className="text-sm text-red-700 dark:text-red-200/90">{error || firstError}</div>
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} onKeyDown={onKeyDown}>
        {/* ── Section 1 : Identification de la mission ── */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-6 h-6 rounded-full bg-at-green/10 border border-at-green/20 flex items-center justify-center text-at-green text-xs font-bold">1</div>
            <span className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0]">Identification de la mission</span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="md:col-span-2">
              <Controller name="titre" control={control} render={({ field }) => (
                <Input label="Titre" value={field.value} onChange={field.onChange} onBlur={field.onBlur}
                       placeholder="Ex: Formation Laravel avancée — Oran"
                       error={!!formErrors.titre} errorMessage={formErrors.titre?.message}
                       success={isValid('titre')} />
              )} />
              <p className="mt-1 text-[11px] text-[#9AA0AE] dark:text-[#5A6070]">Donnez un titre clair et descriptif pour identifier facilement votre mission.</p>
            </div>

            <div className="md:col-span-2">
              <Controller name="objet_mission" control={control} render={({ field }) => (
                <Input label="Objet de la mission" value={field.value} onChange={field.onChange} onBlur={field.onBlur}
                       placeholder="Ex: Participer à la formation Laravel pour renforcer les compétences de l'équipe"
                       error={!!formErrors.objet_mission} errorMessage={formErrors.objet_mission?.message}
                       success={isValid('objet_mission')} />
              )} />
            </div>

            <div>
              <Controller name="type_mission" control={control} render={({ field }) => (
                <Select
                  label="Type de mission"
                  value={field.value}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  options={TYPE_MISSION_OPTIONS}
                  error={!!formErrors.type_mission}
                  errorMessage={formErrors.type_mission?.message}
                  required
                />
              )} />
            </div>

            <div>
              <Controller name="priorite" control={control} render={({ field }) => (
                <Select
                  label="Priorité (optionnel)"
                  value={field.value}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  options={PRIORITE_OPTIONS}
                  placeholder="Non définie"
                />
              )} />
            </div>
          </div>
        </div>

        {/* ── Section 2 : Destination & Dates ── */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-6 h-6 rounded-full bg-at-blue/10 border border-at-blue/20 flex items-center justify-center text-at-blue text-xs font-bold">2</div>
            <span className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0]">Destination & dates</span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

          <div>
            <Controller name="destination_ville" control={control} render={({ field }) => (
              <>
                <Input label="Ville de destination" value={field.value} onChange={field.onChange} onBlur={field.onBlur}
                       placeholder="Tapez pour rechercher une wilaya..."
                       list="at-wilayas"
                       error={!!formErrors.destination_ville} errorMessage={formErrors.destination_ville?.message}
                       success={isValid('destination_ville')} />
                <datalist id="at-wilayas">
                  {WILAYAS.map((w) => <option key={w} value={w} />)}
                </datalist>
              </>
            )} />
          </div>
          <div>
            <Controller name="destination_pays" control={control} render={({ field }) => (
              <>
                <Input label="Pays de destination" value={field.value} onChange={field.onChange} onBlur={field.onBlur}
                       placeholder="Tapez pour rechercher un pays..."
                       list="at-pays"
                       error={!!formErrors.destination_pays} errorMessage={formErrors.destination_pays?.message}
                       success={isValid('destination_pays')} />
                <datalist id="at-pays">
                  {PAYS_FREQUENTS.map((p) => <option key={p} value={p} />)}
                </datalist>
              </>
            )} />
          </div>

          <div>
            <Controller name="date_depart" control={control} render={({ field }) => (
              <>
                <label className="block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-2">Date de départ</label>
                <input
                  type="date"
                  value={field.value}
                  min={todayStr}
                  onChange={(e) => {
                    field.onChange(e)
                    // Si la date de retour devient invalide, on la vide
                    if (values.date_retour && e.target.value && values.date_retour <= e.target.value) {
                      setValue('date_retour', '', { shouldValidate: false })
                    }
                  }}
                  onBlur={field.onBlur}
                  className={`w-full px-3 py-3 rounded-lg border bg-white text-sm text-[#1A1D26] dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             transition-all duration-200
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green
                             ${formErrors.date_depart ? 'border-red-400' : isValid('date_depart') ? 'border-at-green/60' : 'border-[#EAECF0]'}`}
                />
                {formErrors.date_depart && (
                  <p className="mt-1 text-xs text-red-500">{formErrors.date_depart.message}</p>
                )}
              </>
            )} />
          </div>
          <div>
            <Controller name="date_retour" control={control} render={({ field }) => (
              <>
                <label className="block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-2">Date de retour</label>
                <input
                  type="date"
                  value={field.value}
                  min={values.date_depart || todayStr}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  className={`w-full px-3 py-3 rounded-lg border bg-white text-sm text-[#1A1D26] dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             transition-all duration-200
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green
                             ${formErrors.date_retour ? 'border-red-400' : isValid('date_retour') ? 'border-at-green/60' : 'border-[#EAECF0]'}`}
                />
                {formErrors.date_retour && (
                  <p className="mt-1 text-xs text-red-500">{formErrors.date_retour.message}</p>
                )}
              </>
            )} />
          </div>

          {dureeJours !== null && (
            <motion.div
              className="md:col-span-2"
              initial={{ opacity: 0, scale: 0.97 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.25, ease: 'easeOut' }}
            >
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-at-blue/5 border border-at-blue/15 text-at-blue dark:text-blue-300 text-sm font-medium">
                <CalendarDays size={16} />
                Durée de la mission : <strong>{dureeJours} jour{dureeJours > 1 ? 's' : ''}</strong>
              </div>
            </motion.div>
          )}
          </div>
        </div>

        {/* ── Section 3 : Transport & Budget ── */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-6 h-6 rounded-full bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-600 dark:text-amber-400 text-xs font-bold">3</div>
            <span className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0]">Transport & budget</span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <Controller name="transport_type" control={control} render={({ field }) => (
              <Select
                label="Type de transport"
                value={field.value}
                onChange={field.onChange}
                onBlur={field.onBlur}
                options={[
                  { value: 'terrestre', label: 'Véhicule de service' },
                  { value: 'train', label: 'Train (SNTF)' },
                  { value: 'avion', label: 'Par avion (convention AT / Air Algérie)' },
                  { value: 'autre', label: 'Autre (taxi, bus...)' },
                ]}
                error={!!formErrors.transport_type}
                errorMessage={formErrors.transport_type?.message}
                required
              />
            )} />
          </div>

          <div>
            <Controller name="budget_mode" control={control} render={({ field }) => (
              <Select
                label="Mode de budget"
                value={field.value}
                onChange={field.onChange}
                onBlur={field.onBlur}
                options={[
                  { value: 'avance', label: "Avance — montant avancé par l'entreprise" },
                  { value: 'remboursement', label: "Remboursement — frais remboursés sur justificatifs" },
                ]}
                error={!!formErrors.budget_mode}
                errorMessage={formErrors.budget_mode?.message}
                required
              />
            )} />
          </div>

          {values.budget_mode === 'avance' && (
            <div className="md:col-span-2 rounded-2xl border border-[#00A650]/20 bg-[#00A650]/5 dark:bg-[#00A650]/10 p-4 space-y-3">
              <Controller name="demande_avance" control={control} render={({ field }) => (
                <label className="flex items-center gap-3 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={!!field.value}
                    onChange={e => field.onChange(e.target.checked)}
                    className="w-5 h-5 rounded border-gray-300 text-[#00A650] focus:ring-[#00A650]/30 cursor-pointer"
                  />
                  <div>
                    <span className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0]">
                      Demande d'avance sur frais de mission
                    </span>
                    <p className="text-xs text-[#5A6070] dark:text-[#9AA0AE] mt-0.5">
                      Cochez si vous souhaitez recevoir une avance avant le départ
                    </p>
                  </div>
                </label>
              )} />

              {values.demande_avance && (
                <Controller name="montant_avance" control={control} render={({ field }) => (
                  <Input
                    label="Montant de l'avance demandée (DZD)"
                    type="number"
                    placeholder="Ex: 50000"
                    value={field.value}
                    onChange={field.onChange}
                    onBlur={field.onBlur}
                    min={0}
                  />
                )} />
              )}
            </div>
          )}

          <div className="md:col-span-2">
            <Controller name="description" control={control} render={({ field }) => (
              <>
                <div className="flex items-center justify-between mb-2">
                  <label className="block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE]">Description (optionnel)</label>
                  <span className={`text-[10px] tabular-nums ${
                    (field.value?.length ?? 0) > DESCRIPTION_MAX ? 'text-red-500 font-semibold' : 'text-[#9AA0AE]'
                  }`}>
                    {field.value?.length ?? 0}/{DESCRIPTION_MAX}
                  </span>
                </div>
                <textarea
                  value={field.value}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  maxLength={DESCRIPTION_MAX}
                  placeholder="Ajoutez des informations utiles pour le validateur (contexte, participants, etc.)"
                  rows={3}
                  className="w-full px-3 py-3 rounded-lg border border-[#EAECF0] bg-white text-sm text-[#1A1D26] dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             transition-all duration-200
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green resize-none"
                />
              </>
            )} />
          </div>
          </div>
        </div>

        <div className="flex items-center justify-between gap-3 mt-6 flex-wrap">
          <span className="text-[11px] text-[#9AA0AE] dark:text-[#5A6070] hidden sm:inline">
            Astuce : <kbd className="px-1.5 py-0.5 rounded bg-[#F4F6FA] dark:bg-[#252840] border border-[#EAECF0] dark:border-gray-700 text-[10px]">Ctrl</kbd> + <kbd className="px-1.5 py-0.5 rounded bg-[#F4F6FA] dark:bg-[#252840] border border-[#EAECF0] dark:border-gray-700 text-[10px]">Entrée</kbd> pour valider
          </span>
          <Button type="submit" loading={loading} disabled={loading} className="min-w-[180px]">
            {loading ? 'Enregistrement...' : 'Suivant →'}
          </Button>
        </div>
      </form>

      {/* Modale Templates */}
      <AnimatePresence>
        {templateModalOpen && (
          <>
            <div className="fixed inset-0 bg-black/40 z-50" onClick={() => setTemplateModalOpen(false)} />
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.15 }}
              className="fixed inset-0 z-50 flex items-center justify-center p-4"
              onClick={() => setTemplateModalOpen(false)}
            >
              <div
                className="bg-white dark:bg-[#1A1D2E] rounded-2xl shadow-2xl w-full max-w-lg max-h-[70vh] flex flex-col"
                onClick={e => e.stopPropagation()}
              >
                <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 dark:border-gray-700">
                  <h3 className="text-base font-semibold text-[#1A1D26] dark:text-[#E8EAF0]">Choisir un template</h3>
                  <button onClick={() => setTemplateModalOpen(false)} className="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
                    <X size={18} className="text-[#9AA0AE]" />
                  </button>
                </div>
                <div className="flex-1 overflow-y-auto p-4 space-y-2">
                  {templatesLoading && (
                    <div className="flex items-center justify-center py-10">
                      <Loader2 size={24} className="animate-spin text-at-green" />
                    </div>
                  )}
                  {!templatesLoading && templates.length === 0 && (
                    <div className="text-center py-10 text-sm text-[#9AA0AE] dark:text-[#5A6070]">
                      Aucun template disponible.
                    </div>
                  )}
                  {!templatesLoading && templates.map(tpl => (
                    <button
                      key={tpl.id}
                      type="button"
                      onClick={() => applyTemplate(tpl)}
                      className="w-full text-left p-4 rounded-xl border border-gray-100 dark:border-gray-700
                                 hover:border-at-green/40 hover:bg-at-green/5 dark:hover:bg-at-green/10
                                 transition-all"
                    >
                      <div className="font-semibold text-sm text-[#1A1D26] dark:text-[#E8EAF0]">{tpl.nom_template}</div>
                      <div className="flex items-center gap-3 mt-1.5 flex-wrap">
                        {tpl.mission_data?.destination_ville && (
                          <span className="text-xs text-[#5A6070] dark:text-[#9AA0AE]">
                            {tpl.mission_data.destination_ville}{tpl.mission_data.destination_pays ? `, ${tpl.mission_data.destination_pays}` : ''}
                          </span>
                        )}
                        {tpl.mission_data?.transport_type && (
                          <span className="inline-block px-2 py-0.5 rounded-full bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-300 text-[10px] font-semibold">
                            {{ avion: 'Avion', terrestre: 'Véhicule', train: 'Train', autre: 'Autre' }[tpl.mission_data.transport_type] || tpl.mission_data.transport_type}
                          </span>
                        )}
                        {tpl.mission_data?.budget_mode && (
                          <span className="inline-block px-2 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-300 text-[10px] font-semibold">
                            {tpl.mission_data.budget_mode === 'avance' ? 'Avance' : 'Remboursement'}
                          </span>
                        )}
                        {tpl.is_public && (
                          <span className="inline-block px-2 py-0.5 rounded-full bg-purple-50 dark:bg-purple-900/30 text-purple-600 dark:text-purple-300 text-[10px] font-semibold">
                            Public
                          </span>
                        )}
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </motion.div>
  )
}
