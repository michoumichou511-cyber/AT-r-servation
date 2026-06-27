import { useEffect, useMemo } from 'react'
import { motion } from 'framer-motion'
import { Info } from 'lucide-react'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { missionStep1Schema } from '../../../lib/validations'

import { Button, Input } from '../../../components/UI'

const TYPE_MISSION_OPTIONS = [
  { value: '', label: 'Sélectionner…' },
  { value: 'formation', label: 'Formation' },
  { value: 'conference', label: 'Conférence' },
  { value: 'reunion', label: 'Réunion' },
  { value: 'inspection', label: 'Inspection' },
  { value: 'audit', label: 'Audit' },
  { value: 'autre', label: 'Autre' },
]

const PRIORITE_OPTIONS = [
  { value: '', label: 'Priorité (optionnel)' },
  { value: 'normale', label: 'Normale' },
  { value: 'urgente', label: 'Urgente' },
  { value: 'tres_urgente', label: 'Très urgente' },
]

export default function Step1Informations({ onNext, data, missionId, loading, error }) {
  const initial = useMemo(
    () => ({
      titre: data?.titre ?? '',
      objet_mission: data?.objet_mission ?? '',
      destination_ville: data?.destination_ville ?? '',
      destination_pays: data?.destination_pays ?? '',
      date_depart: data?.date_depart ?? '',
      date_retour: data?.date_retour ?? '',
      type_mission: data?.type_mission ?? '',
      priorite: data?.priorite ?? '',
      budget_previsionnel: data?.budget_previsionnel ?? '',
      description: data?.description ?? '',
    }),
    [data]
  )

  const { control, handleSubmit, reset, formState: { errors: formErrors } } = useForm({
    resolver: zodResolver(missionStep1Schema),
    defaultValues: initial,
  })

  useEffect(() => {
    reset(initial)
  }, [initial, reset])

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
      ...(formData.priorite ? { priorite: formData.priorite } : {}),
      ...(String(formData.budget_previsionnel ?? '').trim()
        ? { budget_previsionnel: Number(formData.budget_previsionnel) }
        : {}),
      ...(String(formData.description ?? '').trim()
        ? { description: formData.description.trim() }
        : {}),
    }

    await onNext(payload)
  }

  const firstError = Object.values(formErrors)[0]?.message

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2 }}
    >
      <div className="flex items-start justify-between gap-4 mb-5 flex-wrap">
        <div>
          <h3 className="text-base font-semibold text-gray-700 dark:text-gray-100 mb-2">Informations générales</h3>
          <p className="text-sm text-gray-400 dark:text-gray-400">
            {missionId ? 'Mise à jour de la mission (brouillon)' : 'Créez votre mission (brouillon)'}.
          </p>
        </div>
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-at-green/10 border border-at-green/20 text-at-green text-xs font-semibold">
          <Info size={14} /> Étape 1/4
        </div>
      </div>

      {(error || firstError) && (
        <div className="bg-red-50 border border-red-200 dark:bg-red-950/30 dark:border-red-900/50 rounded-2xl p-4 mb-4">
          <div className="text-sm text-red-800 dark:text-red-200 font-semibold mb-1">Erreur</div>
          <div className="text-sm text-red-700 dark:text-red-200/90">{error || firstError}</div>
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)}>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="md:col-span-2">
            <Controller name="titre" control={control} render={({ field }) => (
              <Input label="Titre" value={field.value} onChange={field.onChange}
                     placeholder="Ex: OM-2026 — Formation Laravel"
                     error={!!formErrors.titre} errorMessage={formErrors.titre?.message} />
            )} />
          </div>

          <div className="md:col-span-2">
            <Controller name="objet_mission" control={control} render={({ field }) => (
              <Input label="Objet de la mission" value={field.value} onChange={field.onChange}
                     placeholder="Objectif / contenu"
                     error={!!formErrors.objet_mission} errorMessage={formErrors.objet_mission?.message} />
            )} />
          </div>

          <div>
            <Controller name="destination_ville" control={control} render={({ field }) => (
              <Input label="Ville de destination" value={field.value} onChange={field.onChange}
                     placeholder="Alger"
                     error={!!formErrors.destination_ville} errorMessage={formErrors.destination_ville?.message} />
            )} />
          </div>
          <div>
            <Controller name="destination_pays" control={control} render={({ field }) => (
              <Input label="Pays de destination" value={field.value} onChange={field.onChange}
                     placeholder="Algérie"
                     error={!!formErrors.destination_pays} errorMessage={formErrors.destination_pays?.message} />
            )} />
          </div>

          <div>
            <Controller name="date_depart" control={control} render={({ field }) => (
              <>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">Date de départ</label>
                <input
                  type="date"
                  value={field.value}
                  onChange={field.onChange}
                  className={`w-full px-3 py-3 rounded-lg border bg-white text-sm text-gray-800 dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green
                             ${formErrors.date_depart ? 'border-red-400' : 'border-gray-200'}`}
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
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">Date de retour</label>
                <input
                  type="date"
                  value={field.value}
                  onChange={field.onChange}
                  className={`w-full px-3 py-3 rounded-lg border bg-white text-sm text-gray-800 dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green
                             ${formErrors.date_retour ? 'border-red-400' : 'border-gray-200'}`}
                />
                {formErrors.date_retour && (
                  <p className="mt-1 text-xs text-red-500">{formErrors.date_retour.message}</p>
                )}
              </>
            )} />
          </div>

          <div>
            <Controller name="type_mission" control={control} render={({ field }) => (
              <>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">Type de mission</label>
                <select
                  value={field.value}
                  onChange={field.onChange}
                  className={`w-full px-3 py-3 rounded-lg border bg-white text-sm text-gray-800 dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green
                             ${formErrors.type_mission ? 'border-red-400' : 'border-gray-200'}`}
                >
                  {TYPE_MISSION_OPTIONS.map((o) => (
                    <option key={o.value || 'x'} value={o.value}>
                      {o.label}
                    </option>
                  ))}
                </select>
                {formErrors.type_mission && (
                  <p className="mt-1 text-xs text-red-500">{formErrors.type_mission.message}</p>
                )}
              </>
            )} />
          </div>

          <div>
            <Controller name="priorite" control={control} render={({ field }) => (
              <>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">Priorité (optionnel)</label>
                <select
                  value={field.value}
                  onChange={field.onChange}
                  className="w-full px-3 py-3 rounded-lg border border-gray-200 bg-white text-sm text-gray-800 dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green"
                >
                  {PRIORITE_OPTIONS.map((o) => (
                    <option key={o.value || 'y'} value={o.value}>
                      {o.label}
                    </option>
                  ))}
                </select>
              </>
            )} />
          </div>

          <div>
            <Controller name="budget_previsionnel" control={control} render={({ field }) => (
              <Input label="Budget prévisionnel (DA)" type="number" value={field.value} onChange={field.onChange}
                     placeholder="Ex: 250000"
                     error={!!formErrors.budget_previsionnel} errorMessage={formErrors.budget_previsionnel?.message} />
            )} />
          </div>

          <div className="md:col-span-2">
            <Controller name="description" control={control} render={({ field }) => (
              <>
                <label className="block text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">Description (optionnel)</label>
                <textarea
                  value={field.value}
                  onChange={field.onChange}
                  placeholder="Détails complémentaires"
                  rows={4}
                  className="w-full px-3 py-3 rounded-lg border border-gray-200 bg-white text-sm text-gray-800 dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green resize-none"
                />
              </>
            )} />
          </div>
        </div>

        <div className="flex justify-end gap-3 mt-6">
          <Button type="submit" loading={loading} disabled={loading} className="min-w-[180px]">
            {loading ? 'Enregistrement...' : 'Suivant →'}
          </Button>
        </div>
      </form>
    </motion.div>
  )
}
