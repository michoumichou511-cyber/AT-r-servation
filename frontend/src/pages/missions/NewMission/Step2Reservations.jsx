import { useCallback, useEffect, useMemo, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import Swal from 'sweetalert2'
import { BookOpen, Building2, Plane, Plus, RotateCcw, Save, Trash2 } from 'lucide-react'
import toast from 'react-hot-toast'

import { adminAPI, reservationsAPI } from '../../../services/api'
import { Badge, Button, EmptyState, Input, Modal, SkeletonCard } from '../../../components/UI'

function billetLabel(transportType) {
  if (transportType === 'train') return 'Billet de train'
  if (transportType === 'autre') return 'Billet de transport'
  return 'Billet d\'avion'
}

const ALL_TYPE_OPTIONS_BASE = [
  { value: 'hebergement', label: 'Hébergement', icon: Building2 },
  { value: 'restauration', label: 'Restauration', icon: BookOpen },
]

function getPayloadValue(v) {
  const s = String(v ?? '').trim()
  return s === '' ? undefined : s
}

const TYPE_TO_PREST_TYPES = {
  billet: ['compagnie_aerienne', 'agence_voyage'],
  hebergement: ['hotel'],
  restauration: ['catering'],
}

function prestataireLabel(p) {
  const loc = p.ville || p.adresse || ''
  return loc ? `${p.nom} — ${loc}` : p.nom
}

function extractPrestataireIdFromReservation(r) {
  return r?.prestataire?.id ?? ''
}

export default function Step2Reservations({ missionId, transportType, destinationVille, onNext, onPrev }) {
  const TYPE_OPTIONS = useMemo(() => {
    if (transportType === 'terrestre') {
      return ALL_TYPE_OPTIONS_BASE
    }
    return [
      { value: 'billet', label: billetLabel(transportType), icon: Plane },
      ...ALL_TYPE_OPTIONS_BASE,
    ]
  }, [transportType])

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [reservations, setReservations] = useState([])
  const [prestataires, setPrestataires] = useState([])
  const [prestLoading, setPrestLoading] = useState(false)
  const [prestError, setPrestError] = useState('')

  const [formType, setFormType] = useState(transportType === 'terrestre' ? 'hebergement' : 'billet')
  const [formPrestId, setFormPrestId] = useState('')
  const [formNotes, setFormNotes] = useState('')
  const [saving, setSaving] = useState(false)

  const [editOpen, setEditOpen] = useState(false)
  const [editId, setEditId] = useState(null)
  const [editType, setEditType] = useState('billet')
  const [editPrestId, setEditPrestId] = useState('')
  const [editNotes, setEditNotes] = useState('')
  const [editSaving, setEditSaving] = useState(false)

  const reservationsCount = reservations.length

  const filteredPrestataires = useMemo(() => {
    const allowedTypes = TYPE_TO_PREST_TYPES[formType] ?? []
    if (!allowedTypes.length) return prestataires
    let list = prestataires.filter((p) => allowedTypes.includes(p.type))
    if (formType === 'hebergement' && destinationVille) {
      const dest = destinationVille.toLowerCase()
      const byCity = list.filter((p) => (p.ville || p.adresse || '').toLowerCase().includes(dest))
      if (byCity.length) list = byCity
    }
    return list
  }, [prestataires, formType, destinationVille])

  const editFilteredPrestataires = useMemo(() => {
    const allowedTypes = TYPE_TO_PREST_TYPES[editType] ?? []
    if (!allowedTypes.length) return prestataires
    let list = prestataires.filter((p) => allowedTypes.includes(p.type))
    if (editType === 'hebergement' && destinationVille) {
      const dest = destinationVille.toLowerCase()
      const byCity = list.filter((p) => (p.ville || p.adresse || '').toLowerCase().includes(dest))
      if (byCity.length) list = byCity
    }
    return list
  }, [prestataires, editType, destinationVille])

  const loadPrestataires = useCallback(async () => {
    setPrestLoading(true)
    setPrestError('')
    try {
      const res = await adminAPI.prestataires({ page: 1, per_page: 50 })
      const data = res?.data?.data ?? []
      setPrestataires(Array.isArray(data) ? data : [])
    } catch (err) {
      setPrestataires([])
      setPrestError(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur chargement prestataires'
      )
    } finally {
      setPrestLoading(false)
    }
  }, [])

  const loadReservations = useCallback(async () => {
    if (!missionId) return
    setLoading(true)
    setError('')
    try {
      const res = await reservationsAPI.getByMission(missionId)
      const raw = res?.data?.data ?? res?.data?.reservations ?? res?.data
      const list = Array.isArray(raw) ? raw : []
      setReservations(list)
    } catch (err) {
      setReservations([])
      setError(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur lors du chargement des réservations'
      )
    } finally {
      setLoading(false)
    }
  }, [missionId])

  useEffect(() => {
    loadReservations()
  }, [loadReservations])

  useEffect(() => {
    if (!prestataires.length && !prestLoading) loadPrestataires()
  }, [prestataires.length, prestLoading, loadPrestataires])

  useEffect(() => {
    setFormPrestId('')
  }, [formType])

  const resetForm = () => {
    setFormType(transportType === 'terrestre' ? 'hebergement' : 'billet')
    setFormPrestId('')
    setFormNotes('')
  }

  const addReservation = async () => {
    if (!missionId) return
    setSaving(true)
    setError('')
    try {
      const payload = {
        type: formType,
        ...(formPrestId ? { prestataire_id: Number(formPrestId) } : {}),
        ...(getPayloadValue(formNotes) ? { notes: formNotes.trim() } : {}),
      }

      const res = await reservationsAPI.creer(missionId, payload)
      const created = res?.data?.data ?? res?.data ?? null
      if (!created) throw new Error('Réservation créée mais réponse invalide')

      setReservations((prev) => [created, ...prev])
      resetForm()
    } catch (err) {
      setError(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur lors de l\'ajout de la réservation'
      )
    } finally {
      setSaving(false)
    }
  }

  const openEdit = (r) => {
    setEditId(r?.id ?? null)
    setEditType(r?.type ?? 'billet')
    setEditPrestId(extractPrestataireIdFromReservation(r))
    setEditNotes(r?.notes ?? '')
    setEditOpen(true)
  }

  const saveEdit = async () => {
    if (!editId) return
    setEditSaving(true)
    try {
      const payload = {
        type: editType,
        ...(editPrestId ? { prestataire_id: Number(editPrestId) } : {}),
        ...(getPayloadValue(editNotes) ? { notes: editNotes.trim() } : {}),
      }

      const res = await reservationsAPI.update(editId, payload)
      const updated = res?.data?.data ?? res?.data ?? null
      if (!updated) throw new Error('Réponse invalide lors de la modification')

      setReservations((prev) => prev.map((x) => (x?.id === editId ? updated : x)))
      setEditOpen(false)
      setEditId(null)
    } catch (err) {
      Swal.fire({
        icon: 'error',
        title: 'Erreur',
        text:
          err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Impossible de modifier la réservation',
      })
    } finally {
      setEditSaving(false)
    }
  }

  const removeReservation = async (id) => {
    const ok = await Swal.fire({
      title: 'Supprimer cette réservation ?',
      text: 'Cette action est immédiate (mission doit être en brouillon).',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Oui, supprimer',
      cancelButtonText: 'Annuler',
      confirmButtonColor: '#00A650',
      cancelButtonColor: '#EF4444',
    })

    if (!ok.isConfirmed) return

    try {
      await reservationsAPI.delete(id)
      setReservations((prev) => prev.filter((x) => x?.id !== id))
      toast.success('Réservation supprimée ✅')
    } catch (err) {
      toast.error(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur lors de la suppression'
      )
    }
  }

  const canProceed = reservationsCount > 0

  const nextDisabledReason = useMemo(() => {
    if (canProceed) return ''
    return 'Ajoutez au moins une réservation avant de continuer.'
  }, [canProceed])

  if (!missionId) {
    return (
      <div className="at-card-surface p-6">
        <div className="text-sm font-semibold text-red-700 mb-2">Mission introuvable</div>
        <div className="text-sm text-[#5A6070] dark:text-[#9AA0AE] mb-4">
          Créez d'abord la mission à l'étape 1.
        </div>
        <Button variant="outline" onClick={onPrev}>
          ← Précédent
        </Button>
      </div>
    )
  }

  return (
    <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.2 }}>
      <div className="flex items-start justify-between gap-4 flex-wrap mb-4">
        <div>
          <h3 className="text-base font-semibold text-[#1A1D26] dark:text-[#E8EAF0] mb-2">Réservations</h3>
          <p className="text-sm text-[#9AA0AE]">Billets, hébergements et restauration pour la mission.</p>
        </div>
        <div className="flex items-center gap-2">
          <Badge status="actif" label={`${reservationsCount} réservation(s)`} />
        </div>
      </div>

      <div className="flex items-start gap-2 px-4 py-2.5 rounded-xl bg-at-blue/5 dark:bg-at-blue/10 border border-at-blue/15 text-sm text-at-blue dark:text-blue-300 mb-5">
        <span className="shrink-0 text-base mt-0.5">&#128161;</span>
        <span>
          Ajoutez au moins <strong>une réservation</strong> pour continuer.
          {transportType === 'avion' ? ' Pour un déplacement en avion, pensez au billet + hébergement.' : ' Pour un déplacement terrestre, pensez à l\'hébergement et/ou la restauration.'}
        </span>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 dark:bg-red-950/30 dark:border-red-900/50 rounded-2xl p-4 mb-4">
          <div className="text-sm font-semibold text-red-800 dark:text-red-200 mb-1">Erreur</div>
          <div className="text-sm text-red-700 dark:text-red-200/90">{error}</div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <div className="lg:col-span-2">
          <div className="at-card-surface p-4 mb-4">
            <div className="flex items-center justify-between mb-3">
              <div className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0]">Ajouter</div>
              <Button
                variant="ghost"
                size="sm"
                onClick={resetForm}
                disabled={saving}
                className="px-2"
              >
                <RotateCcw size={16} />
              </Button>
            </div>

            <div className="space-y-3">
              <label className="block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-2">Type</label>
              <select
                value={formType}
                onChange={(e) => setFormType(e.target.value)}
                className="w-full px-3 py-3 rounded-xl border border-[#EAECF0] bg-white text-sm text-[#1A1D26] dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                           focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green"
              >
                {TYPE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>

              <label className="block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-2">Prestataire (optionnel)</label>
              <select
                value={formPrestId}
                onChange={(e) => setFormPrestId(e.target.value)}
                disabled={prestLoading}
                className="w-full px-3 py-3 rounded-xl border border-[#EAECF0] bg-white text-sm text-[#1A1D26] dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                           focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green disabled:opacity-60"
              >
                <option value="">Aucun</option>
                {filteredPrestataires.map((p) => (
                  <option key={p.id} value={p.id}>
                    {prestataireLabel(p)}
                  </option>
                ))}
              </select>
              {filteredPrestataires.length === 0 && !prestLoading && (
                <div className="text-xs text-amber-500 dark:text-amber-400">Aucun prestataire pour ce type</div>
              )}

              {prestError && <div className="text-xs text-[#5A6070] dark:text-[#9AA0AE]">Prestataires: {prestError}</div>}

              <div>
                <label className="block text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-2">Notes (optionnel)</label>
                <textarea
                  value={formNotes}
                  onChange={(e) => setFormNotes(e.target.value)}
                  placeholder="Détails / justification"
                  rows={3}
                  className="w-full px-3 py-2 rounded-xl border border-[#EAECF0] bg-white text-sm text-[#1A1D26] dark:bg-[#1E2235] dark:text-[#E8EAF0] dark:border-[#2A2D3E]
                             focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green resize-none"
                />
              </div>

              <Button onClick={addReservation} loading={saving} disabled={saving} className="w-full">
                <Plus size={16} /> Ajouter
              </Button>
            </div>
          </div>
        </div>

        <div className="lg:col-span-3">
          {loading ? (
            <div className="space-y-3">
              {[0, 1, 2].map((i) => (
                <SkeletonCard key={i} />
              ))}
            </div>
          ) : reservationsCount === 0 ? (
            <EmptyState
              icon={Plus}
              title="Aucune réservation"
              subtitle="Utilisez le formulaire à gauche pour ajouter un billet, un hébergement ou une restauration."
            />
          ) : (
            <div className="space-y-3">
              <AnimatePresence initial={false}>
                {reservations.map((r, idx) => {
                  const Icon = TYPE_OPTIONS.find((x) => x.value === r.type)?.icon ?? Plus
                  return (
                    <motion.div
                      key={r.id ?? `${r.type}_${idx}`}
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -8 }}
                      transition={{ duration: 0.2, delay: idx * 0.02 }}
                      className="at-card-surface p-4"
                    >
                      <div className="flex items-start justify-between gap-3 mb-3">
                        <div className="min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <div className="w-9 h-9 rounded-xl bg-at-green/10 border border-at-green/20 flex items-center justify-center text-at-green">
                              <Icon size={16} />
                            </div>
                            <div className="font-semibold text-[#1A1D26] truncate">
                              {r.type_label ?? r.type}
                            </div>
                          </div>
                          <div className="text-sm text-[#5A6070]">
                            Prestataire: <span className="font-semibold">{r.prestataire?.nom ?? 'Aucun'}</span>
                          </div>
                          {r.notes && (
                            <div className="text-sm text-[#5A6070] mt-2">
                              Notes: <span className="text-[#1A1D26]">{r.notes}</span>
                            </div>
                          )}
                        </div>
                        <div className="flex flex-col items-end gap-2">
                          <Badge status={r.statut} label={r.statut_label ?? r.statut} />
                          <div className="flex gap-2">
                            <Button size="sm" variant="outline" onClick={() => openEdit(r)}>
                              Modifier
                            </Button>
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() => removeReservation(r.id)}
                            >
                              <Trash2 size={14} />
                            </Button>
                          </div>
                        </div>
                      </div>
                    </motion.div>
                  )
                })}
              </AnimatePresence>
            </div>
          )}

          {(!loading && !canProceed) && (
            <div className="mt-4 text-sm text-red-700 font-semibold">{nextDisabledReason}</div>
          )}

          <div className="flex items-center justify-between gap-3 mt-6 flex-wrap">
            <Button variant="outline" onClick={onPrev} disabled={saving}>
              ← Précédent
            </Button>
            <Button onClick={onNext} disabled={!canProceed || saving} loading={false} className="min-w-[200px]">
              Continuer → Documents
            </Button>
          </div>
        </div>
      </div>

      <Modal
        isOpen={editOpen}
        onClose={() => {
          if (editSaving) return
          setEditOpen(false)
        }}
        title="Modifier la réservation"
      >
        <div className="space-y-3">
          <label className="block text-xs font-semibold text-[#5A6070] mb-2">Type</label>
          <select
            value={editType}
            onChange={(e) => setEditType(e.target.value)}
            className="w-full px-3 py-3 rounded-xl border border-[#EAECF0] bg-white text-sm text-[#1A1D26]
                       focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green"
          >
            {TYPE_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>

          <label className="block text-xs font-semibold text-[#5A6070] mb-2">Prestataire</label>
          <select
            value={editPrestId}
            onChange={(e) => setEditPrestId(e.target.value)}
            disabled={prestLoading}
            className="w-full px-3 py-3 rounded-xl border border-[#EAECF0] bg-white text-sm text-[#1A1D26]
                       focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green disabled:opacity-60"
          >
            <option value="">Aucun</option>
            {editFilteredPrestataires.map((p) => (
              <option key={p.id} value={p.id}>
                {prestataireLabel(p)}
              </option>
            ))}
          </select>

          <div>
            <label className="block text-xs font-semibold text-[#5A6070] mb-2">Notes</label>
            <textarea
              value={editNotes}
              onChange={(e) => setEditNotes(e.target.value)}
              placeholder="Détails"
              rows={3}
              className="w-full px-3 py-2 rounded-xl border border-[#EAECF0] bg-white text-sm text-[#1A1D26]
                         focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green resize-none"
            />
          </div>

          <div className="flex items-center justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setEditOpen(false)} disabled={editSaving}>
              Annuler
            </Button>
            <Button onClick={saveEdit} loading={editSaving} disabled={editSaving}>
              <Save size={16} /> Enregistrer
            </Button>
          </div>
        </div>
      </Modal>
    </motion.div>
  )
}
