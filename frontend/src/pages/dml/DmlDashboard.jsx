import { useEffect, useState, useCallback, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Truck, Building2, Car, CheckCircle, Clock, AlertCircle,
  MapPin, Calendar, User, X, ChevronRight, RefreshCw,
  AlertTriangle, Briefcase, BarChart3, History, ArrowRight,
} from 'lucide-react'
import {
  PieChart, Pie, Cell, ResponsiveContainer, Tooltip,
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
} from 'recharts'
import toast from 'react-hot-toast'

import { dmlAPI } from '../../services/api'
import { Button, EmptyState, SkeletonCard } from '../../components/UI'
import Modal from '../../components/UI/Modal'

// ── Constantes ─────────────────────────────────────────────
const TABS = [
  { key: 'validees',      label: 'À traiter',      icon: Clock,        color: 'text-amber-600' },
  { key: 'terminees',     label: 'Logistique OK',  icon: CheckCircle,  color: 'text-[#00A650]' },
]

const TRANSPORT_OPTIONS = [
  { value: 'vehicule_service', label: 'Véhicule de service' },
  { value: 'avion',            label: 'Avion' },
  { value: 'train',            label: 'Train' },
  { value: 'taxi',             label: 'Taxi' },
  { value: 'autre',            label: 'Autre' },
]

const TRANSPORT_LABELS = {
  vehicule_service: 'Véhicule',
  avion: 'Avion',
  train: 'Train',
  taxi: 'Taxi',
  autre: 'Autre',
}

const PIE_COLORS = ['#003DA5', '#00A650', '#F59E0B', '#EF4444', '#8B5CF6']

const STATUT_BADGE = {
  en_attente:    { label: 'En attente',    cls: 'bg-amber-50 text-amber-700 ring-amber-200 dark:bg-amber-900/30 dark:text-amber-300 dark:ring-amber-700',  dot: 'bg-amber-400' },
  en_traitement: { label: 'En traitement', cls: 'bg-blue-50 text-blue-700 ring-blue-200 dark:bg-blue-900/30 dark:text-blue-300 dark:ring-blue-700',     dot: 'bg-blue-400' },
  logistique_ok: { label: 'Logistique OK', cls: 'bg-green-50 text-[#00A650] ring-green-200 dark:bg-green-900/30 dark:text-green-300 dark:ring-green-700', dot: 'bg-[#00A650]' },
  approuve:      { label: 'Approuvée',     cls: 'bg-green-50 text-[#00A650] ring-green-200 dark:bg-green-900/30 dark:text-green-300 dark:ring-green-700', dot: 'bg-[#00A650]' },
}

function formatDateFr(d) {
  if (!d) return '—'
  const s = String(d)
  if (/^\d{1,2}\/\d{1,2}\/\d{4}/.test(s)) return s.slice(0, 10)
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})/)
  return m ? `${m[3]}/${m[2]}/${m[1]}` : s
}

function parseDate(d) {
  if (!d) return null
  const s = String(d)
  const iso = s.match(/^(\d{4})-(\d{2})-(\d{2})/)
  if (iso) return new Date(+iso[1], +iso[2] - 1, +iso[3])
  const fr = s.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})/)
  if (fr) return new Date(+fr[3], +fr[2] - 1, +fr[1])
  return null
}

function StatutBadge({ statut }) {
  const c = STATUT_BADGE[statut] ?? { label: statut, cls: 'bg-gray-100 text-gray-600 ring-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:ring-gray-600', dot: 'bg-gray-400' }
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium ring-1 ${c.cls}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${c.dot}`} />
      {c.label}
    </span>
  )
}

function MissionCard({ mission, traitement, onTraiter }) {
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
            <span className="text-xs font-mono text-[#9AA0AE] bg-[#F4F6FA] dark:bg-[#252840] px-2 py-0.5 rounded-md">{mission.numero_unique}</span>
            <StatutBadge statut={traitement?.statut ?? mission.statut} />
          </div>
          <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white truncate">
            {mission.titre}
          </h3>
          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-[#5A6070] dark:text-[#9AA0AE]">
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

  const user = mission.user ?? mission.demandeur ?? {}
  const nomComplet = [user.prenom, user.nom].filter(Boolean).join(' ') || '—'
  const destination = mission.destination_ville ?? mission.destination ?? '—'
  const pays = mission.destination_pays ?? 'Algerie'
  const transportDemande = mission.transport_type
  const budget = mission.budget_previsionnel ?? 0
  const reservations = mission.reservations ?? []
  const nbJours = (() => {
    const d1 = parseDate(mission.dates?.depart ?? mission.date_depart)
    const d2 = parseDate(mission.dates?.retour ?? mission.date_retour)
    if (d1 && d2) return Math.max(1, Math.ceil((d2 - d1) / (1000 * 60 * 60 * 24)))
    return null
  })()

  const filteredHotels = useMemo(() => {
    const ville = (mission.destination_ville ?? '').toLowerCase()
    if (!ville) return hotels
    return hotels.filter(h =>
      (h.ville ?? '').toLowerCase().includes(ville) ||
      (h.wilaya ?? '').toLowerCase().includes(ville)
    )
  }, [hotels, mission.destination_ville])

  const handleSaveHotel = async () => {
    setSaving(true)
    try {
      const conventionId = form.hotel_convention_id
      const payload = {
        hotel_convention_id:
          conventionId && conventionId !== '__libre__' ? conventionId : null,
        hotel_nom_libre:     form.hotel_nom_libre || null,
        observations:        form.observations || null,
      }
      await dmlAPI.assignerHotel(missionId, payload)
      toast.success('Hebergement assigne')
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur lors de l\'assignation hotel')
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
      toast.success('Transport assigne')
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur lors de l\'assignation vehicule')
    } finally { setSaving(false) }
  }

  const handleLogistiqueOk = async () => {
    setMarkingOk(true)
    try {
      await dmlAPI.marquerLogistiqueOk(missionId)
      toast.success(
        'Mission cloturee avec succes !\nLe demandeur a ete notifie par email et notification in-app.',
        { duration: 5000, style: { whiteSpace: 'pre-line', maxWidth: '420px' } }
      )
      onSuccess()
      onClose()
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur')
    } finally { setMarkingOk(false) }
  }

  return (
    <Modal isOpen onClose={onClose} title={`Traiter — ${mission.numero_unique}`} size="lg">
      <div className="space-y-5 p-1 max-h-[75vh] overflow-y-auto">

        {/* Fiche mission complete */}
        <div className="rounded-xl bg-[#F4F6FA] dark:bg-[#252840] p-4">
          <div className="font-semibold text-[#1A1D26] dark:text-white mb-2 text-base">{mission.titre}</div>

          {mission.objet_mission && (
            <p className="text-sm text-[#5A6070] dark:text-[#9AA0AE] mb-3 leading-relaxed">{mission.objet_mission}</p>
          )}
          {mission.description && !mission.objet_mission && (
            <p className="text-sm text-[#5A6070] dark:text-[#9AA0AE] mb-3 leading-relaxed">{mission.description}</p>
          )}

          <div className="grid grid-cols-2 gap-x-4 gap-y-2 text-xs">
            <div className="flex items-center gap-1.5">
              <User size={12} className="text-[#003DA5] flex-shrink-0" />
              <span className="text-[#5A6070] dark:text-[#9AA0AE]">Demandeur :</span>
              <span className="font-semibold text-[#1A1D26] dark:text-white">{nomComplet}</span>
            </div>
            {user.direction && (
              <div className="flex items-center gap-1.5">
                <Briefcase size={12} className="text-[#003DA5] flex-shrink-0" />
                <span className="text-[#5A6070] dark:text-[#9AA0AE]">Direction :</span>
                <span className="font-semibold text-[#1A1D26] dark:text-white">{user.direction}</span>
              </div>
            )}
            <div className="flex items-center gap-1.5">
              <MapPin size={12} className="text-[#00A650] flex-shrink-0" />
              <span className="text-[#5A6070] dark:text-[#9AA0AE]">Destination :</span>
              <span className="font-semibold text-[#1A1D26] dark:text-white">{destination}, {pays}</span>
            </div>
            <div className="flex items-center gap-1.5">
              <Calendar size={12} className="text-amber-500 flex-shrink-0" />
              <span className="text-[#5A6070] dark:text-[#9AA0AE]">Dates :</span>
              <span className="font-semibold text-[#1A1D26] dark:text-white">
                {formatDateFr(mission.dates?.depart ?? mission.date_depart)} → {formatDateFr(mission.dates?.retour ?? mission.date_retour)}
                {nbJours && <span className="text-[#9AA0AE] font-normal ml-1">({nbJours}j)</span>}
              </span>
            </div>
            {transportDemande && (
              <div className="flex items-center gap-1.5">
                <Truck size={12} className="text-[#003DA5] flex-shrink-0" />
                <span className="text-[#5A6070] dark:text-[#9AA0AE]">Transport demande :</span>
                <span className="font-semibold text-[#1A1D26] dark:text-white">
                  {transportDemande === 'aerien' ? 'Aerien (avion)' : transportDemande === 'terrestre' ? 'Terrestre' : transportDemande}
                </span>
              </div>
            )}
            {mission.type_mission && (
              <div className="flex items-center gap-1.5">
                <AlertCircle size={12} className="text-amber-500 flex-shrink-0" />
                <span className="text-[#5A6070] dark:text-[#9AA0AE]">Type :</span>
                <span className="font-semibold text-[#1A1D26] dark:text-white">{mission.type_mission}</span>
              </div>
            )}
            {budget > 0 && (
              <div className="flex items-center gap-1.5">
                <span className="text-[#00A650] flex-shrink-0 text-sm font-bold">DA</span>
                <span className="text-[#5A6070] dark:text-[#9AA0AE]">Budget :</span>
                <span className="font-semibold text-[#1A1D26] dark:text-white">{budget.toLocaleString('fr-DZ')} DA</span>
              </div>
            )}
            {mission.priorite && mission.priorite !== 'normale' && (
              <div className="flex items-center gap-1.5">
                <AlertTriangle size={12} className="text-red-500 flex-shrink-0" />
                <span className="text-[#5A6070] dark:text-[#9AA0AE]">Priorite :</span>
                <span className="font-semibold text-red-600 dark:text-red-400 uppercase">{mission.priorite}</span>
              </div>
            )}
          </div>

          {/* Reservations existantes */}
          {reservations.length > 0 && (
            <div className="mt-3 pt-3 border-t border-[#EAECF0] dark:border-[#2A2D3E]">
              <div className="text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-1.5">Reservations demandees :</div>
              <div className="space-y-1">
                {reservations.map((r, i) => (
                  <div key={r.id ?? i} className="flex items-center gap-2 text-xs">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#003DA5] flex-shrink-0" />
                    <span className="text-[#1A1D26] dark:text-white font-medium">
                      {r.type === 'billet' ? 'Billet' : r.type === 'hebergement' ? 'Hebergement' : r.type}
                    </span>
                    {r.prestataire?.nom && (
                      <span className="text-[#5A6070] dark:text-[#9AA0AE]">— {r.prestataire.nom}</span>
                    )}
                    {r.notes && (
                      <span className="text-[#9AA0AE] italic truncate">({r.notes})</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {user.telephone && (
            <div className="mt-2 pt-2 border-t border-[#EAECF0] dark:border-[#2A2D3E] text-xs text-[#5A6070] dark:text-[#9AA0AE]">
              Contact demandeur : <span className="font-semibold">{user.telephone}</span>
              {user.email && <span className="ml-3">{user.email}</span>}
            </div>
          )}
        </div>

        {/* Hebergement */}
        <div>
          <h4 className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0] mb-2 flex items-center gap-1.5">
            <Building2 size={14} className="text-[#003DA5]" /> Hebergement
            {filteredHotels.length < hotels.length && (
              <span className="text-[10px] font-normal text-[#9AA0AE] ml-1">
                (filtres pour {mission.destination_ville} — {filteredHotels.length} hotel{filteredHotels.length > 1 ? 's' : ''})
              </span>
            )}
          </h4>
          <div className="space-y-2">
            <select value={form.hotel_convention_id} onChange={e => set('hotel_convention_id', e.target.value)}
              className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm text-[#1A1D26] dark:text-white focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30">
              <option value="">— Selectionner un hotel convention —</option>
              {filteredHotels.map(h => (<option key={h.id} value={h.id}>{h.nom} — {h.ville} ({h.tarif_chambre_simple} DA/nuit)</option>))}
              <option value="__libre__">Autre hotel (saisie libre)</option>
            </select>
            {(form.hotel_convention_id === '__libre__' || (!form.hotel_convention_id && form.hotel_nom_libre)) && (
              <input type="text" placeholder="Nom de l'hotel..." value={form.hotel_nom_libre} onChange={e => set('hotel_nom_libre', e.target.value)}
                className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30" />
            )}
            <button type="button" onClick={handleSaveHotel} disabled={saving} className="text-xs text-[#003DA5] dark:text-blue-400 hover:underline">
              {saving ? 'Enregistrement...' : 'Enregistrer hebergement'}
            </button>
          </div>
        </div>

        {/* Transport */}
        <div>
          <h4 className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0] mb-2 flex items-center gap-1.5">
            <Car size={14} className="text-[#003DA5]" /> Transport
            {transportDemande && (
              <span className="text-[10px] font-normal text-amber-600 dark:text-amber-400 ml-1">
                (demande : {transportDemande === 'aerien' ? 'aerien' : transportDemande === 'terrestre' ? 'terrestre' : transportDemande})
              </span>
            )}
          </h4>
          <div className="space-y-2">
            <select value={form.type_transport} onChange={e => set('type_transport', e.target.value)}
              className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30">
              <option value="">— Type de transport —</option>
              {TRANSPORT_OPTIONS.map(o => (<option key={o.value} value={o.value}>{o.label}</option>))}
            </select>
            {form.type_transport === 'vehicule_service' && (
              <select value={form.vehicule_id} onChange={e => set('vehicule_id', e.target.value)}
                className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30">
                <option value="">— Selectionner un vehicule —</option>
                {vehicules.map(v => (<option key={v.id} value={v.id}>{v.marque} {v.modele} — {v.immatriculation} ({v.capacite} places)</option>))}
              </select>
            )}
            {form.type_transport && form.type_transport !== 'vehicule_service' && (
              <input type="text"
                placeholder={form.type_transport === 'avion' ? 'N° billet avion...' : form.type_transport === 'train' ? 'N° billet train...' : 'N° bon de transport...'}
                value={form.numero_bon} onChange={e => set('numero_bon', e.target.value)}
                className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30" />
            )}
            <button type="button" onClick={handleSaveVehicule} disabled={saving} className="text-xs text-[#003DA5] dark:text-blue-400 hover:underline">
              {saving ? 'Enregistrement...' : 'Enregistrer transport'}
            </button>
          </div>
        </div>

        {/* Observations */}
        <div>
          <label className="text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-1 block tracking-wide">Observations</label>
          <textarea rows={3} placeholder="Notes logistiques..." value={form.observations} onChange={e => set('observations', e.target.value)}
            className="w-full rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] px-3 py-2 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30" />
        </div>

        <button type="button" onClick={handleLogistiqueOk} disabled={markingOk}
          className="w-full py-3 rounded-xl font-semibold text-white text-sm transition-all duration-200 active:scale-95 disabled:opacity-60"
          style={{ background: markingOk ? '#94A3B8' : 'linear-gradient(135deg,#003DA5,#00A650)' }}>
          {markingOk ? 'Traitement...' : 'Marquer logistique OK'}
        </button>
      </div>
    </Modal>
  )
}

// ── Composant principal ─────────────────────────────────────
const MAX_PREVIEW = 5

export default function DmlDashboard() {
  const navigate = useNavigate()
  const [activeTab,  setActiveTab]  = useState('validees')
  const [missions,   setMissions]   = useState([])
  const [traitements,setTraitements]= useState([])
  const [hotels,     setHotels]     = useState([])
  const [vehicules,  setVehicules]  = useState([])
  const [loading,    setLoading]    = useState(true)
  const [selected,   setSelected]   = useState(null)

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

  const terminees = traitements.filter(t => t.statut === 'logistique_ok')
  const totalTraitees = terminees.length + missions.length

  const handleTraiter = (mission, traitement) => setSelected({ mission, traitement })

  // ── Missions urgentes (depart < 48h sans logistique) ────
  const missionsUrgentes = useMemo(() => {
    const now = new Date()
    const limit = new Date(now.getTime() + 48 * 60 * 60 * 1000)
    return missions.filter(m => {
      const dep = parseDate(m.dates?.depart ?? m.date_depart)
      return dep && dep <= limit && dep >= now
    })
  }, [missions])

  // ── Calendrier des departs (7 prochains jours) ────
  const departsProchains = useMemo(() => {
    const now = new Date()
    now.setHours(0, 0, 0, 0)
    const limit = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
    return missions
      .map(m => {
        const dep = parseDate(m.dates?.depart ?? m.date_depart)
        return dep && dep >= now && dep <= limit ? { ...m, _dep: dep } : null
      })
      .filter(Boolean)
      .sort((a, b) => a._dep - b._dep)
      .slice(0, 5)
  }, [missions])

  // ── Repartition transport (camembert) ────
  const transportData = useMemo(() => {
    const counts = {}
    for (const t of traitements) {
      const type = t.type_transport || 'autre'
      counts[type] = (counts[type] || 0) + 1
    }
    return Object.entries(counts).map(([key, value]) => ({
      name: TRANSPORT_LABELS[key] || key,
      value,
    }))
  }, [traitements])

  // ── Missions par direction (barres) ────
  const missionsParDirection = useMemo(() => {
    const counts = {}
    const allMissions = [
      ...missions,
      ...traitements.map(t => t.mission).filter(Boolean),
    ]
    for (const m of allMissions) {
      const dir = m.user?.direction ?? m.demandeur?.direction ?? m.direction ?? 'Non defini'
      counts[dir] = (counts[dir] || 0) + 1
    }
    return Object.entries(counts)
      .map(([direction, total]) => ({ direction, total }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 6)
  }, [missions, traitements])

  // ── Derniere activite ────
  const dernieresActions = useMemo(() => {
    return terminees
      .map(t => ({
        id: t.id,
        mission: t.mission?.numero_unique ?? t.mission?.titre ?? '—',
        hotel: t.hotel?.nom ?? t.hotel_nom_libre ?? null,
        transport: TRANSPORT_LABELS[t.type_transport] ?? null,
        date: t.updated_at ?? t.created_at,
      }))
      .sort((a, b) => {
        const da = a.date ? new Date(a.date) : new Date(0)
        const db = b.date ? new Date(b.date) : new Date(0)
        return db - da
      })
      .slice(0, 5)
  }, [terminees])

  // ── Top hotels ────
  const topHotels = useMemo(() => {
    const counts = {}
    for (const t of traitements) {
      const name = t.hotel?.nom ?? t.hotel_nom_libre
      if (name) counts[name] = (counts[name] || 0) + 1
    }
    return Object.entries(counts)
      .map(([nom, count]) => ({ nom, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 3)
  }, [traitements])

  return (
    <div className="space-y-6">
      {/* En-tete DML */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3, ease: 'easeOut' }}
        className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <div className="flex items-center gap-3 mb-1">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-[#003DA5] to-[#00A650]">
              <Truck size={20} className="text-white" />
            </div>
            <h1 className="at-gradient-title text-xl font-bold tracking-tight md:text-2xl">
              Espace Agent DML
            </h1>
          </div>
          <p className="text-sm text-[#9AA0AE] dark:text-[#8B92A8] ml-[52px]">
            Gestion logistique des missions validees — hebergement, transport, prestataires
          </p>
        </div>
        <Button size="sm" variant="outline" onClick={loadData} disabled={loading}>
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          Rafraichir
        </Button>
      </motion.div>

      {/* Alerte urgente */}
      {missionsUrgentes.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          className="rounded-2xl bg-red-50 dark:bg-red-900/20 p-4 flex items-start gap-3"
        >
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-red-500 flex-shrink-0 mt-0.5">
            <AlertTriangle size={16} className="text-white" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="text-sm font-semibold text-red-800 dark:text-red-200">
              {missionsUrgentes.length} mission(s) urgente(s) — depart dans moins de 48h
            </div>
            <div className="text-xs text-red-600 dark:text-red-300 mt-1">
              {missionsUrgentes.map(m => m.numero_unique ?? m.titre).join(', ')}
            </div>
          </div>
        </motion.div>
      )}

      {/* KPI cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {[
          { label: 'À traiter',      value: missions.length,  gradient: 'from-amber-400 to-orange-500', icon: Clock,       bg: 'bg-amber-50 dark:bg-amber-900/20'  },
          { label: 'Logistique OK',  value: terminees.length, gradient: 'from-green-400 to-[#00A650]',  icon: CheckCircle, bg: 'bg-green-50 dark:bg-green-900/20'  },
          { label: 'Total',          value: totalTraitees,    gradient: 'from-[#003DA5] to-[#00A650]',  icon: Briefcase,   bg: 'bg-[#F4F6FA] dark:bg-[#252840]/60' },
        ].map(({ label, value, gradient, icon: Icon, bg }, i) => (
          <motion.div
            key={label}
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ delay: i * 0.08, duration: 0.4, ease: [0.4, 0, 0.2, 1] }}
            className={`rounded-2xl p-4 ${bg} transition-shadow hover:shadow-md`}
          >
            <div className="flex items-center gap-3">
              <div className={`flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br ${gradient} flex-shrink-0`}>
                <Icon size={16} className="text-white" />
              </div>
              <div>
                <div className="text-2xl font-extrabold text-[#1A1D26] dark:text-white leading-none at-number">{value}</div>
                <div className="text-xs text-[#5A6070] dark:text-[#9AA0AE] mt-0.5">{label}</div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Grille dashboard : missions + stats */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Colonne gauche : apercu missions (2/3) */}
        <div className="lg:col-span-2">
          <div className="at-card-surface p-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-semibold text-[#1A1D26] dark:text-white flex items-center gap-2">
                <Clock size={16} className="text-amber-500" />
                Missions a traiter
                {missions.length > 0 && (
                  <span className="text-[11px] font-bold rounded-full px-2 py-0.5 bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">
                    {missions.length}
                  </span>
                )}
              </h2>
              <button
                onClick={() => navigate('/dml/missions')}
                className="flex items-center gap-1.5 text-xs font-semibold text-[#003DA5] dark:text-blue-400 hover:underline"
              >
                Voir toutes les missions <ArrowRight size={14} />
              </button>
            </div>

            {loading ? (
              <div className="space-y-3">
                {[...Array(3)].map((_, i) => <SkeletonCard key={i} />)}
              </div>
            ) : missions.length === 0 ? (
              <EmptyState icon={CheckCircle} title="Aucune mission a traiter" subtitle="Toutes les missions approuvees ont ete traitees." />
            ) : (
              <div className="space-y-3">
                {missions.slice(0, MAX_PREVIEW).map(m => (
                  <MissionCard key={m.id} mission={m} onTraiter={handleTraiter} />
                ))}
                {missions.length > MAX_PREVIEW && (
                  <button
                    onClick={() => navigate('/dml/missions')}
                    className="w-full py-3 rounded-xl text-sm font-semibold text-[#003DA5] dark:text-blue-400 bg-[#F4F6FA] dark:bg-[#252840] hover:bg-[#E8EAF0] dark:hover:bg-[#2A2D3E] transition-colors flex items-center justify-center gap-2"
                  >
                    +{missions.length - MAX_PREVIEW} autre(s) mission(s) <ArrowRight size={14} />
                  </button>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Colonne droite : panneau statistiques (1/3) */}
        <div className="space-y-5">

          {/* Ressources disponibles */}
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.2 }} className="at-card-surface p-5">
            <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white mb-4 flex items-center gap-2">
              <Building2 size={16} className="text-[#003DA5]" />
              Ressources disponibles
            </h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between rounded-xl bg-blue-50 dark:bg-blue-900/20 px-4 py-3">
                <div className="flex items-center gap-2.5">
                  <Building2 size={14} className="text-[#003DA5]" />
                  <span className="text-sm font-medium text-[#1A1D26] dark:text-[#E8EAF0]">Hotels convention</span>
                </div>
                <span className="text-lg font-bold text-[#003DA5] dark:text-blue-400">{hotels.length}</span>
              </div>
              <div className="flex items-center justify-between rounded-xl bg-green-50 dark:bg-green-900/20 px-4 py-3">
                <div className="flex items-center gap-2.5">
                  <Car size={14} className="text-[#00A650]" />
                  <span className="text-sm font-medium text-[#1A1D26] dark:text-[#E8EAF0]">Vehicules disponibles</span>
                </div>
                <span className="text-lg font-bold text-[#00A650] dark:text-green-400">{vehicules.length}</span>
              </div>
            </div>
          </motion.div>

          {/* Taux de traitement */}
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.3 }} className="at-card-surface p-5">
            <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white mb-4 flex items-center gap-2">
              <BarChart3 size={16} className="text-[#00A650]" />
              Taux de traitement
            </h3>
            {(() => {
              const total = missions.length + terminees.length
              const pct = total > 0 ? Math.round((terminees.length / total) * 100) : 0
              return (
                <div>
                  <div className="flex items-end justify-between mb-2">
                    <span className="text-3xl font-extrabold text-[#1A1D26] dark:text-white at-number">{pct}%</span>
                    <span className="text-xs text-[#5A6070] dark:text-[#9AA0AE] at-number">{terminees.length}/{total} missions</span>
                  </div>
                  <div className="h-2.5 w-full bg-[#EAECF0] dark:bg-[#2A2D3E] rounded-full overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${pct}%` }}
                      transition={{ duration: 1, delay: 0.5, ease: [0.22, 1, 0.36, 1] }}
                      className="h-full rounded-full"
                      style={{ background: 'linear-gradient(90deg, #003DA5, #00A650)' }}
                    />
                  </div>
                  <p className="text-xs text-[#9AA0AE] dark:text-[#5A6070] mt-2">
                    {pct === 100 ? 'Toutes les missions sont traitees' : pct === 0 ? 'Aucune mission traitee pour le moment' : `${missions.length} mission(s) en attente`}
                  </p>
                </div>
              )
            })()}
          </motion.div>

          {/* Calendrier des departs (7 jours) */}
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.35 }} className="at-card-surface p-5">
            <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white mb-3 flex items-center gap-2">
              <Calendar size={16} className="text-amber-500" />
              Departs prochains (7j)
            </h3>
            {departsProchains.length === 0 ? (
              <p className="text-xs text-[#9AA0AE] dark:text-[#5A6070]">Aucun depart prevu cette semaine</p>
            ) : (
              <div className="space-y-2">
                {departsProchains.map((m, i) => {
                  const dep = m._dep
                  const isUrgent = dep && (dep.getTime() - Date.now()) < 48 * 3600 * 1000
                  return (
                    <div key={m.id ?? i} className={`flex items-center gap-2.5 rounded-xl px-3 py-2.5 text-xs ${isUrgent ? 'bg-red-50 dark:bg-red-900/20' : 'bg-[#F4F6FA] dark:bg-[#252840]'}`}>
                      <span className={`font-bold tabular-nums ${isUrgent ? 'text-red-600 dark:text-red-400' : 'text-[#5A6070] dark:text-[#9AA0AE]'}`}>
                        {formatDateFr(m.dates?.depart ?? m.date_depart)}
                      </span>
                      <span className="text-[#5A6070] dark:text-[#9AA0AE] truncate flex-1">{m.titre ?? m.numero_unique}</span>
                      {isUrgent && <AlertTriangle size={12} className="text-red-500 flex-shrink-0" />}
                    </div>
                  )
                })}
              </div>
            )}
          </motion.div>

          {/* Repartition transport (camembert) */}
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.4 }} className="at-card-surface p-5">
            <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white mb-3 flex items-center gap-2">
              <Car size={16} className="text-[#003DA5]" />
              Repartition transport
            </h3>
            {transportData.length === 0 ? (
              <p className="text-xs text-[#9AA0AE] dark:text-[#5A6070]">Aucune donnee de transport</p>
            ) : (
              <div className="flex items-center gap-4">
                <div className="w-24 h-24 flex-shrink-0">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie data={transportData} dataKey="value" cx="50%" cy="50%" innerRadius={20} outerRadius={40} paddingAngle={3}>
                        {transportData.map((_, i) => (
                          <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="flex-1 space-y-1.5">
                  {transportData.map((d, i) => (
                    <div key={d.name} className="flex items-center gap-2 text-xs">
                      <span className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ background: PIE_COLORS[i % PIE_COLORS.length] }} />
                      <span className="text-[#5A6070] dark:text-[#9AA0AE] flex-1">{d.name}</span>
                      <span className="font-bold text-[#1A1D26] dark:text-white">{d.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </motion.div>

          {/* Missions par direction */}
          {missionsParDirection.length > 0 && (
            <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.45 }} className="at-card-surface p-5">
              <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white mb-3 flex items-center gap-2">
                <Briefcase size={16} className="text-[#003DA5]" />
                Missions par direction
              </h3>
              <div className="h-[140px]">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={missionsParDirection} layout="vertical" margin={{ left: 0, right: 8, top: 4, bottom: 4 }}>
                    <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="rgba(150,150,150,0.15)" />
                    <XAxis type="number" tick={{ fontSize: 10, fill: '#9AA0AE' }} allowDecimals={false} />
                    <YAxis type="category" dataKey="direction" tick={{ fontSize: 10, fill: '#9AA0AE' }} width={60} />
                    <Tooltip contentStyle={{ fontSize: 12, borderRadius: 8, border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,.1)' }} />
                    <Bar dataKey="total" fill="#003DA5" radius={[0, 4, 4, 0]} barSize={14} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </motion.div>
          )}

          {/* Derniere activite */}
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.5 }} className="at-card-surface p-5">
            <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white mb-3 flex items-center gap-2">
              <History size={16} className="text-[#00A650]" />
              Derniere activite
            </h3>
            {dernieresActions.length === 0 ? (
              <p className="text-xs text-[#9AA0AE] dark:text-[#5A6070]">Aucune activite recente</p>
            ) : (
              <div className="space-y-2.5">
                {dernieresActions.map((a, i) => (
                  <div key={a.id ?? i} className="flex items-start gap-2.5">
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/30 flex-shrink-0 mt-0.5">
                      <CheckCircle size={12} className="text-[#00A650]" />
                    </div>
                    <div className="text-xs min-w-0">
                      <div className="font-medium text-[#1A1D26] dark:text-[#E8EAF0] truncate">{a.mission}</div>
                      <div className="text-[#9AA0AE] dark:text-[#5A6070]">
                        {[a.hotel && `Hotel: ${a.hotel}`, a.transport && `Transport: ${a.transport}`].filter(Boolean).join(' | ') || 'Logistique OK'}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </motion.div>

          {/* Workflow logistique */}
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.6 }} className="at-card-surface p-5">
            <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white mb-3 flex items-center gap-2">
              <ChevronRight size={16} className="text-amber-500" />
              Workflow logistique
            </h3>
            <div className="space-y-2.5">
              {[
                { step: '1', text: 'Mission validee par le directeur', color: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300' },
                { step: '2', text: 'Assigner hotel + transport', color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300' },
                { step: '3', text: 'Marquer logistique OK', color: 'bg-green-100 text-[#00A650] dark:bg-green-900/30 dark:text-green-300' },
              ].map(({ step, text, color }) => (
                <div key={step} className="flex items-center gap-3">
                  <span className={`flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold ${color}`}>{step}</span>
                  <span className="text-xs text-[#5A6070] dark:text-[#9AA0AE]">{text}</span>
                </div>
              ))}
            </div>
          </motion.div>

        </div>
      </div>

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
