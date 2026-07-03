import { useEffect, useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Truck, Building2, Car, CheckCircle, Clock, AlertCircle,
  MapPin, Calendar, User, X, ChevronRight, RefreshCw,
} from 'lucide-react'
import toast from 'react-hot-toast'

import { dmlAPI } from '../../services/api'
import PageHeader from '../../components/Common/PageHeader'
import { Button, EmptyState, SkeletonCard } from '../../components/UI'
import Modal from '../../components/UI/Modal'

// ── Constantes ─────────────────────────────────────────────
const TABS = [
  { key: 'validees',      label: 'À traiter',      icon: Clock,        color: 'text-amber-600' },
  { key: 'en_traitement', label: 'En traitement',  icon: Truck,        color: 'text-blue-600'  },
  { key: 'terminees',     label: 'Logistique OK',  icon: CheckCircle,  color: 'text-[#00A650]' },
]

const TRANSPORT_OPTIONS = [
  { value: 'vehicule_service', label: '🚗 Véhicule de service' },
  { value: 'avion',            label: '✈️ Avion' },
  { value: 'train',            label: '🚂 Train' },
  { value: 'taxi',             label: '🚕 Taxi' },
  { value: 'autre',            label: '📦 Autre' },
]

const STATUT_BADGE = {
  en_attente:    { label: 'En attente',    cls: 'bg-amber-50 text-amber-700 ring-amber-200',  dot: 'bg-amber-400' },
  en_traitement: { label: 'En traitement', cls: 'bg-blue-50 text-blue-700 ring-blue-200',     dot: 'bg-blue-400' },
  logistique_ok: { label: 'Logistique OK', cls: 'bg-green-50 text-[#00A650] ring-green-200', dot: 'bg-[#00A650]' },
  approuve:      { label: 'Approuvée',     cls: 'bg-green-50 text-[#00A650] ring-green-200', dot: 'bg-[#00A650]' },
}

/** "2026-07-20" ou ISO → "20/07/2026" ; laisse les dates déjà en d/m/Y intactes. */
function formatDateFr(d) {
  if (!d) return '—'
  const s = String(d)
  if (/^\d{1,2}\/\d{1,2}\/\d{4}/.test(s)) return s.slice(0, 10)
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/)
  return m ? `${m[3]}/${m[2]}/${m[1]}` : s
}

function StatutBadge({ statut }) {
  const c = STATUT_BADGE[statut] ?? { label: statut, cls: 'bg-gray-100 text-gray-600 ring-gray-200', dot: 'bg-gray-400' }
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium ring-1 ${c.cls}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${c.dot}`} />
      {c.label}
    </span>
  )
}

function MissionCard({ mission, traitement, onTraiter, onRefresh }) {
  const user = mission.user ?? mission.demandeur ?? {}
  const nomComplet = [user.prenom, user.nom].filter(Boolean).join(' ') || '—'

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -8 }}
      transition={{ duration: 0.3 }}
      className="at-card-surface p-5 hover:shadow-md transition-shadow duration-200"
    >
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <span className="text-xs font-mono text-gray-400">{mission.numero_unique}</span>
            <StatutBadge statut={traitement?.statut ?? mission.statut} />
          </div>
          <h3 className="text-sm font-semibold text-gray-800 dark:text-white truncate">
            {mission.titre}
          </h3>
          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-gray-500">
            <span className="flex items-center gap-1">
              <User size={12} /> {nomComplet}
            </span>
            <span className="flex items-center gap-1">
              <MapPin size={12} /> {mission.destination_ville ?? mission.destination ?? '—'}
            </span>
            <span className="flex items-center gap-1">
              <Calendar size={12} />
              {formatDateFr(mission.dates?.depart ?? mission.date_depart)}
              {' → '}
              {formatDateFr(mission.dates?.retour ?? mission.date_retour)}
            </span>
          </div>
          {traitement?.hotel && (
            <div className="mt-2 text-xs text-blue-600 flex items-center gap-1">
              <Building2 size={11} /> {traitement.hotel.nom} — {traitement.hotel.ville}
            </div>
          )}
          {traitement?.vehicule && (
            <div className="mt-1 text-xs text-teal-600 flex items-center gap-1">
              <Car size={11} /> {traitement.vehicule.marque} {traitement.vehicule.modele} ({traitement.vehicule.immatriculation})
            </div>
          )}
        </div>
        {onTraiter && (
          <Button size="sm" onClick={() => onTraiter(mission, traitement)} className="flex-shrink-0">
            <ChevronRight size={14} /> Traiter
          </Button>
        )}
      </div>
    </motion.div>
  )
}

// ── Modal de traitement ─────────────────────────────────────
function TraiterModal({ mission, traitement, hotels, vehicules, onClose, onSuccess }) {
  const [form, setForm] = useState({
    hotel_convention_id: traitement?.hotel_convention_id ?? '',
    hotel_nom_libre:     traitement?.hotel_nom_libre ?? '',
    vehicule_id:         traitement?.vehicule_id ?? '',
    type_transport:      traitement?.type_transport ?? '',
    numero_bon:          traitement?.numero_bon ?? '',
    observations:        traitement?.observations ?? '',
  })
  const [saving, setSaving] = useState(false)
  const [markingOk, setMarkingOk] = useState(false)
  const missionId = mission.id

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  const handleSaveHotel = async () => {
    setSaving(true)
    try {
      // Bug fix : ne pas envoyer "__libre__" comme hotel_convention_id
      // (valeur sentinelle UI uniquement — backend rejette car invalide).
      const conventionId = form.hotel_convention_id
      const payload = {
        hotel_convention_id:
          conventionId && conventionId !== '__libre__' ? conventionId : null,
        hotel_nom_libre:     form.hotel_nom_libre || null,
        observations:        form.observations || null,
      }
      await dmlAPI.assignerHotel(missionId, payload)
      toast.success('Hébergement assigné')
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur lors de l\'assignation hôtel')
    } finally { setSaving(false) }
  }

  const handleSaveVehicule = async () => {
    setSaving(true)
    try {
      await dmlAPI.assignerVehicule(missionId, {
        vehicule_id:    form.vehicule_id || null,
        type_transport: form.type_transport || null,
        numero_bon:     form.numero_bon || null,
        observations:   form.observations || null,
      })
      toast.success('Transport assigné')
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur lors de l\'assignation véhicule')
    } finally { setSaving(false) }
  }

  const handleLogistiqueOk = async () => {
    setMarkingOk(true)
    try {
      await dmlAPI.marquerLogistiqueOk(missionId)
      // UX-07 fix : feedback explicite que le demandeur a ete averti
      toast.success(
        '✅ Mission clôturée avec succès !\n' +
        'Le demandeur a été notifié par email et notification in-app.',
        { duration: 5000, style: { whiteSpace: 'pre-line', maxWidth: '420px' } }
      )
      onSuccess()
      onClose()
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur')
    } finally { setMarkingOk(false) }
  }

  return (
    <Modal
      isOpen
      onClose={onClose}
      title={`Traiter — ${mission.numero_unique}`}
      size="lg"
    >
      <div className="space-y-5 p-1">
        {/* Info mission */}
        <div className="rounded-xl bg-[#F4F6FA] dark:bg-white/5 p-4 text-sm">
          <div className="font-semibold text-gray-800 dark:text-white mb-1">{mission.titre}</div>
          <div className="text-gray-500 text-xs flex flex-wrap gap-x-4 gap-y-1">
            <span><MapPin size={11} className="inline mr-0.5" />{mission.destination_ville ?? mission.destination}</span>
            <span><Calendar size={11} className="inline mr-0.5" />
              {formatDateFr(mission.dates?.depart ?? mission.date_depart)} → {formatDateFr(mission.dates?.retour ?? mission.date_retour)}
            </span>
          </div>
        </div>

        {/* ─ Hébergement ─ */}
        <div>
          <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-200 mb-2 flex items-center gap-1.5">
            <Building2 size={14} className="text-[#003DA5]" /> Hébergement
          </h4>
          <div className="space-y-2">
            <select
              value={form.hotel_convention_id}
              onChange={e => set('hotel_convention_id', e.target.value)}
              className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm text-gray-800 dark:text-white focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30"
            >
              <option value="">— Sélectionner un hôtel convention —</option>
              {hotels.map(h => (
                <option key={h.id} value={h.id}>
                  {h.nom} — {h.ville} ({h.tarif_chambre_simple} DA/nuit)
                </option>
              ))}
              <option value="__libre__">Autre hôtel (saisie libre)</option>
            </select>
            {(form.hotel_convention_id === '__libre__' || (!form.hotel_convention_id && form.hotel_nom_libre)) && (
              <input
                type="text"
                placeholder="Nom de l'hôtel..."
                value={form.hotel_nom_libre}
                onChange={e => set('hotel_nom_libre', e.target.value)}
                className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30"
              />
            )}
            <button
              type="button"
              onClick={handleSaveHotel}
              disabled={saving}
              className="text-xs text-[#003DA5] hover:underline"
            >
              {saving ? 'Enregistrement…' : '💾 Enregistrer hébergement'}
            </button>
          </div>
        </div>

        {/* ─ Transport ─ */}
        <div>
          <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-200 mb-2 flex items-center gap-1.5">
            <Car size={14} className="text-[#003DA5]" /> Transport
          </h4>
          <div className="space-y-2">
            <select
              value={form.type_transport}
              onChange={e => set('type_transport', e.target.value)}
              className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30"
            >
              <option value="">— Type de transport —</option>
              {TRANSPORT_OPTIONS.map(o => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>
            {form.type_transport === 'vehicule_service' && (
              <select
                value={form.vehicule_id}
                onChange={e => set('vehicule_id', e.target.value)}
                className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30"
              >
                <option value="">— Sélectionner un véhicule —</option>
                {vehicules.map(v => (
                  <option key={v.id} value={v.id}>
                    {v.marque} {v.modele} — {v.immatriculation} ({v.capacite} places)
                  </option>
                ))}
              </select>
            )}
            <input
              type="text"
              placeholder="N° bon de transport / billet..."
              value={form.numero_bon}
              onChange={e => set('numero_bon', e.target.value)}
              className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30"
            />
            <button
              type="button"
              onClick={handleSaveVehicule}
              disabled={saving}
              className="text-xs text-[#003DA5] hover:underline"
            >
              {saving ? 'Enregistrement…' : '💾 Enregistrer transport'}
            </button>
          </div>
        </div>

        {/* ─ Observations ─ */}
        <div>
          <label className="text-xs font-medium text-gray-500 mb-1 block">Observations</label>
          <textarea
            rows={3}
            placeholder="Notes logistiques..."
            value={form.observations}
            onChange={e => set('observations', e.target.value)}
            className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30"
          />
        </div>

        {/* ─ Bouton final ─ */}
        <button
          type="button"
          onClick={handleLogistiqueOk}
          disabled={markingOk}
          className="w-full py-3 rounded-xl font-semibold text-white text-sm transition-all duration-200 active:scale-95 disabled:opacity-60"
          style={{ background: markingOk ? '#94A3B8' : 'linear-gradient(135deg,#003DA5,#00A650)' }}
        >
          {markingOk ? '⏳ Traitement…' : '✅ Marquer logistique OK'}
        </button>
      </div>
    </Modal>
  )
}

// ── Composant principal ─────────────────────────────────────
export default function DmlDashboard() {
  const [activeTab,  setActiveTab]  = useState('validees')
  const [missions,   setMissions]   = useState([])
  const [traitements,setTraitements]= useState([])
  const [hotels,     setHotels]     = useState([])
  const [vehicules,  setVehicules]  = useState([])
  const [loading,    setLoading]    = useState(true)
  const [selected,   setSelected]   = useState(null) // { mission, traitement }

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const [mR, tR, hR, vR] = await Promise.allSettled([
        dmlAPI.getMissionsValidees(),
        dmlAPI.getMissionsEnTraitement(),
        dmlAPI.getHotelsConventions(),
        dmlAPI.getVehiculesDisponibles(),
      ])
      if (mR.status === 'fulfilled') {
        const body = mR.value.data
        setMissions(body?.data?.data ?? body?.data ?? [])
      }
      if (tR.status === 'fulfilled') {
        const body = tR.value.data
        setTraitements(body?.data?.data ?? body?.data ?? [])
      }
      if (hR.status === 'fulfilled') {
        setHotels(hR.value.data?.data ?? [])
      }
      if (vR.status === 'fulfilled') {
        setVehicules(vR.value.data?.data ?? [])
      }
    } catch {
      toast.error('Erreur lors du chargement')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadData() }, [loadData])

  // Missions terminées (logistique_ok) filtrées depuis traitements
  const terminees = traitements.filter(t => t.statut === 'logistique_ok')
  const enCours   = traitements.filter(t => t.statut !== 'logistique_ok')

  const handleTraiter = (mission, traitement) => setSelected({ mission, traitement })

  return (
    <div className="space-y-5">
      <PageHeader
        title="Module DML"
        subtitle="Traitement logistique des missions validées"
        backTo="/"
        actions={
          <Button size="sm" variant="outline" onClick={loadData} disabled={loading}>
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            Rafraîchir
          </Button>
        }
      />

      {/* Hero résumé */}
      <div className="grid grid-cols-3 gap-3">
        {[
          { label: 'À traiter', value: missions.length,   color: 'from-amber-400 to-orange-500',  icon: Clock       },
          { label: 'En cours',  value: enCours.length,    color: 'from-blue-500 to-[#003DA5]',    icon: Truck       },
          { label: 'Terminées', value: terminees.length,  color: 'from-green-400 to-[#00A650]',   icon: CheckCircle },
        ].map(({ label, value, color, icon: Icon }) => (
          <div key={label} className="at-card-surface p-4 flex items-center gap-3">
            <div className={`p-2.5 rounded-xl bg-gradient-to-br ${color} flex-shrink-0`}>
              <Icon size={16} className="text-white" />
            </div>
            <div>
              <div className="text-xl font-extrabold text-gray-900 dark:text-white">{value}</div>
              <div className="text-xs text-gray-500">{label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-[#F4F6FA] dark:bg-white/5 rounded-xl p-1">
        {TABS.map(tab => {
          const Icon = tab.icon
          const isActive = activeTab === tab.key
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={[
                'flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200',
                isActive
                  ? 'bg-white dark:bg-[#1A1D2E] shadow-sm text-gray-900 dark:text-white'
                  : 'text-gray-500 hover:text-gray-700',
              ].join(' ')}
            >
              <Icon size={14} className={isActive ? tab.color : ''} />
              {tab.label}
            </button>
          )
        })}
      </div>

      {/* Contenu */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(3)].map((_, i) => <SkeletonCard key={i} />)}
        </div>
      ) : (
        <AnimatePresence mode="wait">
          {activeTab === 'validees' && (
            <motion.div key="validees" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-3">
              {missions.length === 0
                ? <EmptyState icon={CheckCircle} title="Aucune mission à traiter" subtitle="Toutes les missions approuvées ont été traitées." />
                : missions.map(m => (
                  <MissionCard key={m.id} mission={m} onTraiter={handleTraiter} />
                ))}
            </motion.div>
          )}

          {activeTab === 'en_traitement' && (
            <motion.div key="en_traitement" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-3">
              {enCours.length === 0
                ? <EmptyState icon={Truck} title="Aucun traitement en cours" subtitle="Aucune mission en cours de traitement logistique." />
                : enCours.map(t => (
                  <MissionCard key={t.id} mission={t.mission ?? {}} traitement={t} onTraiter={handleTraiter} />
                ))}
            </motion.div>
          )}

          {activeTab === 'terminees' && (
            <motion.div key="terminees" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-3">
              {terminees.length === 0
                ? <EmptyState icon={CheckCircle} title="Aucune mission terminée" subtitle="Les missions avec logistique OK apparaîtront ici." />
                : terminees.map(t => (
                  <MissionCard key={t.id} mission={t.mission ?? {}} traitement={t} />
                ))}
            </motion.div>
          )}
        </AnimatePresence>
      )}

      {/* Modal traitement */}
      {selected && (
        <TraiterModal
          mission={selected.mission}
          traitement={selected.traitement}
          hotels={hotels}
          vehicules={vehicules}
          onClose={() => setSelected(null)}
          onSuccess={loadData}
        />
      )}
    </div>
  )
}
