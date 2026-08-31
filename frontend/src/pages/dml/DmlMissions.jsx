import { useEffect, useState, useCallback, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Truck, Building2, Car, CheckCircle, Clock, AlertCircle,
  MapPin, Calendar, User, ChevronRight, RefreshCw,
  AlertTriangle, Briefcase, Search, Filter,
} from 'lucide-react'
import toast from 'react-hot-toast'

import { dmlAPI } from '../../services/api'
import { Button, EmptyState, SkeletonCard, Input } from '../../components/UI'
import Modal from '../../components/UI/Modal'

const TABS = [
  { key: 'validees',      label: 'À traiter',      icon: Clock,       color: 'text-amber-600' },
  { key: 'terminees',     label: 'Logistique OK',  icon: CheckCircle, color: 'text-[#00A650]' },
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

function MissionRow({ mission, traitement, onTraiter, isUrgent }) {
  const user = mission.user ?? mission.demandeur ?? {}
  const nomComplet = [user.prenom, user.nom].filter(Boolean).join(' ') || '—'
  const dep = parseDate(mission.dates?.depart ?? mission.date_depart)
  const ret = parseDate(mission.dates?.retour ?? mission.date_retour)
  const nbJours = dep && ret ? Math.max(1, Math.ceil((ret - dep) / (1000 * 60 * 60 * 24))) : null

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -8 }}
      transition={{ duration: 0.25 }}
      className={`at-card-surface p-4 hover:shadow-md transition-shadow duration-200 ${isUrgent ? 'ring-2 ring-red-300 dark:ring-red-700' : ''}`}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap mb-1.5">
            <span className="text-xs font-mono text-[#9AA0AE] bg-[#F4F6FA] dark:bg-[#252840] px-2 py-0.5 rounded-md">
              {mission.numero_unique}
            </span>
            <StatutBadge statut={traitement?.statut ?? mission.statut} />
            {isUrgent && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300">
                <AlertTriangle size={10} /> URGENT
              </span>
            )}
          </div>
          <h3 className="text-sm font-semibold text-[#1A1D26] dark:text-white">
            {mission.titre}
          </h3>

          <div className="mt-2 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-x-4 gap-y-1.5 text-xs text-[#5A6070] dark:text-[#9AA0AE]">
            <span className="flex items-center gap-1.5">
              <User size={12} className="text-[#003DA5] flex-shrink-0" /> {nomComplet}
            </span>
            {user.direction && (
              <span className="flex items-center gap-1.5">
                <Briefcase size={12} className="text-[#003DA5] flex-shrink-0" /> {user.direction}
              </span>
            )}
            <span className="flex items-center gap-1.5">
              <MapPin size={12} className="text-[#00A650] flex-shrink-0" /> {mission.destination_ville ?? mission.destination ?? '—'}
            </span>
            <span className="flex items-center gap-1.5">
              <Calendar size={12} className="text-amber-500 flex-shrink-0" />
              {formatDateFr(mission.dates?.depart ?? mission.date_depart)} → {formatDateFr(mission.dates?.retour ?? mission.date_retour)}
              {nbJours && <span className="text-[#9AA0AE]">({nbJours}j)</span>}
            </span>
          </div>

          {traitement?.hotel && (
            <div className="mt-2 text-xs text-blue-600 dark:text-blue-400 flex items-center gap-1">
              <Building2 size={11} /> {traitement.hotel.nom} — {traitement.hotel.ville}
            </div>
          )}
          {traitement?.vehicule && (
            <div className="mt-1 text-xs text-teal-600 dark:text-teal-400 flex items-center gap-1">
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
      await dmlAPI.assignerHotel(missionId, {
        hotel_convention_id: conventionId && conventionId !== '__libre__' ? conventionId : null,
        hotel_nom_libre: form.hotel_nom_libre || null,
        observations: form.observations || null,
      })
      toast.success('Hebergement assigne')
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur lors de l\'assignation hotel')
    } finally { setSaving(false) }
  }

  const handleSaveVehicule = async () => {
    setSaving(true)
    try {
      await dmlAPI.assignerVehicule(missionId, {
        vehicule_id: form.vehicule_id || null,
        type_transport: form.type_transport || null,
        numero_bon: form.numero_bon || null,
        observations: form.observations || null,
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
      toast.success('Mission cloturee avec succes !\nLe demandeur a ete notifie.', { duration: 4000, style: { whiteSpace: 'pre-line' } })
      onSuccess()
      onClose()
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur')
    } finally { setMarkingOk(false) }
  }

  return (
    <Modal isOpen onClose={onClose} title={`Traiter — ${mission.numero_unique}`} size="lg">
      <div className="space-y-5 p-1 max-h-[75vh] overflow-y-auto">
        <div className="rounded-xl bg-[#F4F6FA] dark:bg-[#252840] p-4">
          <div className="font-semibold text-[#1A1D26] dark:text-white mb-2 text-base">{mission.titre}</div>
          {(mission.objet_mission || mission.description) && (
            <p className="text-sm text-[#5A6070] dark:text-[#9AA0AE] mb-3 leading-relaxed">{mission.objet_mission ?? mission.description}</p>
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
            {budget > 0 && (
              <div className="flex items-center gap-1.5">
                <span className="text-[#00A650] flex-shrink-0 text-sm font-bold">DA</span>
                <span className="text-[#5A6070] dark:text-[#9AA0AE]">Budget :</span>
                <span className="font-semibold text-[#1A1D26] dark:text-white">{budget.toLocaleString('fr-DZ')} DA</span>
              </div>
            )}
            {mission.demande_avance && (
              <div className="flex items-center gap-1.5">
                <span className="text-[#00A650] flex-shrink-0 text-xs font-bold">$</span>
                <span className="text-[#5A6070] dark:text-[#9AA0AE]">Avance demandee :</span>
                <span className="font-semibold text-[#00A650]">
                  {mission.montant_avance ? `${Number(mission.montant_avance).toLocaleString('fr-DZ')} DA` : 'Oui'}
                </span>
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
                    {r.prestataire?.nom && <span className="text-[#5A6070] dark:text-[#9AA0AE]">— {r.prestataire.nom}</span>}
                  </div>
                ))}
              </div>
            </div>
          )}
          {user.telephone && (
            <div className="mt-2 pt-2 border-t border-[#EAECF0] dark:border-[#2A2D3E] text-xs text-[#5A6070] dark:text-[#9AA0AE]">
              Contact : <span className="font-semibold">{user.telephone}</span>
              {user.email && <span className="ml-3">{user.email}</span>}
            </div>
          )}
        </div>

        <div>
          <h4 className="text-sm font-semibold text-[#1A1D26] dark:text-[#E8EAF0] mb-2 flex items-center gap-1.5">
            <Building2 size={14} className="text-[#003DA5]" /> Hebergement
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

        <div>
          <label className="text-xs font-semibold text-[#5A6070] dark:text-[#9AA0AE] mb-1 block">Observations</label>
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

export default function DmlMissions() {
  const [activeTab, setActiveTab] = useState('validees')
  const [missions, setMissions] = useState([])
  const [traitements, setTraitements] = useState([])
  const [hotels, setHotels] = useState([])
  const [vehicules, setVehicules] = useState([])
  const [loading, setLoading] = useState(true)
  const [selected, setSelected] = useState(null)
  const [search, setSearch] = useState('')

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
      if (hR.status === 'fulfilled') setHotels(hR.value.data?.data ?? [])
      if (vR.status === 'fulfilled') setVehicules(vR.value.data?.data ?? [])
    } catch {
      toast.error('Erreur lors du chargement')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadData() }, [loadData])

  const terminees = traitements.filter(t => t.statut === 'logistique_ok')

  const handleTraiter = (mission, traitement) => setSelected({ mission, traitement })

  const handleCloturer = async (traitement) => {
    const mission = traitement.mission ?? {}
    const confirm = window.confirm(`Clôturer la mission "${mission.titre ?? mission.numero_unique}" et libérer le véhicule ?`)
    if (!confirm) return
    try {
      await dmlAPI.cloturerMission(mission.id)
      toast.success('Mission clôturée — véhicule libéré')
      loadData()
    } catch (e) {
      toast.error(e?.response?.data?.message ?? 'Erreur lors de la clôture')
    }
  }

  const urgentIds = useMemo(() => {
    const now = new Date()
    const limit = new Date(now.getTime() + 48 * 60 * 60 * 1000)
    const ids = new Set()
    for (const m of missions) {
      const dep = parseDate(m.dates?.depart ?? m.date_depart)
      if (dep && dep <= limit && dep >= now) ids.add(m.id)
    }
    return ids
  }, [missions])

  const filterMission = useCallback((m) => {
    if (!search) return true
    const q = search.toLowerCase()
    const user = m.user ?? m.demandeur ?? {}
    const haystack = [
      m.numero_unique, m.titre, m.destination_ville, m.destination,
      user.prenom, user.nom, user.direction,
    ].filter(Boolean).join(' ').toLowerCase()
    return haystack.includes(q)
  }, [search])

  const filteredMissions = useMemo(() => missions.filter(filterMission), [missions, filterMission])
  const filteredTerminees = useMemo(() => terminees.filter(t => filterMission(t.mission ?? t)), [terminees, filterMission])

  const currentList = activeTab === 'validees' ? filteredMissions : filteredTerminees

  const totalCounts = {
    validees: missions.length,
    terminees: terminees.length,
  }

  return (
    <div className="space-y-5">
      {/* En-tete */}
      <motion.div
        initial={{ opacity: 0, y: -12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
      >
        <div>
          <h1 className="at-gradient-title text-xl font-bold tracking-tight md:text-2xl">
            Missions a traiter
          </h1>
          <p className="text-sm text-[#9AA0AE] dark:text-[#8B92A8] mt-0.5">
            {missions.length + terminees.length} mission(s) au total
          </p>
        </div>
        <Button size="sm" variant="outline" onClick={loadData} disabled={loading}>
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          Rafraichir
        </Button>
      </motion.div>

      {/* Barre de recherche + Tabs */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9AA0AE]" />
          <input
            type="text"
            placeholder="Rechercher par numero, titre, demandeur..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-2.5 rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1A1D2E] text-sm text-[#1A1D26] dark:text-white placeholder-[#9AA0AE] focus:outline-none focus:ring-2 focus:ring-[#003DA5]/30"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-[#F4F6FA] dark:bg-white/5 rounded-xl p-1">
        {TABS.map(tab => {
          const Icon = tab.icon
          const isActive = activeTab === tab.key
          const count = totalCounts[tab.key]
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={[
                'flex-1 flex items-center justify-center gap-1.5 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200',
                isActive
                  ? 'bg-white dark:bg-[#1A1D2E] shadow-sm text-[#1A1D26] dark:text-white'
                  : 'text-[#5A6070] hover:text-[#1A1D26] dark:text-[#9AA0AE] dark:hover:text-white',
              ].join(' ')}
            >
              <Icon size={14} className={isActive ? tab.color : ''} />
              {tab.label}
              {count > 0 && (
                <span className={`ml-1 text-[11px] font-bold rounded-full px-1.5 py-0.5 ${
                  isActive ? 'bg-[#003DA5]/10 text-[#003DA5] dark:bg-white/10 dark:text-white' : 'bg-gray-200/60 text-gray-500 dark:bg-white/5 dark:text-gray-400'
                }`}>
                  {count}
                </span>
              )}
            </button>
          )
        })}
      </div>

      {/* Liste des missions */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => <SkeletonCard key={i} />)}
        </div>
      ) : currentList.length === 0 ? (
        <EmptyState
          icon={activeTab === 'validees' ? CheckCircle : CheckCircle}
          title={search ? 'Aucun resultat' : activeTab === 'validees' ? 'Aucune mission a traiter' : 'Aucune mission terminee'}
          subtitle={search ? `Aucune mission ne correspond a "${search}"` : activeTab === 'validees' ? 'Toutes les missions approuvees ont ete traitees.' : 'Les missions avec logistique OK apparaitront ici.'}
        />
      ) : (
        <AnimatePresence mode="wait">
          <motion.div key={activeTab} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-3">
            {activeTab === 'validees' && filteredMissions.map(m => (
              <MissionRow key={m.id} mission={m} onTraiter={handleTraiter} isUrgent={urgentIds.has(m.id)} />
            ))}
            {activeTab === 'terminees' && filteredTerminees.map(t => {
              const m = t.mission ?? {}
              const isTerminee = m.statut === 'termine'
              return (
                <div key={t.id}>
                  <MissionRow mission={m} traitement={t} />
                  {!isTerminee && (
                    <div className="flex justify-end px-4 -mt-1 mb-2">
                      <Button size="sm" variant="outline" onClick={() => handleCloturer(t)}
                        className="text-xs text-amber-700 border-amber-300 hover:bg-amber-50 dark:text-amber-400 dark:border-amber-700 dark:hover:bg-amber-900/20">
                        <CheckCircle size={13} /> Clôturer (retour mission)
                      </Button>
                    </div>
                  )}
                </div>
              )
            })}
          </motion.div>
        </AnimatePresence>
      )}

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
