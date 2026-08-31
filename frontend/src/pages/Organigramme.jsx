import { useEffect, useState, useMemo } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Search, ChevronDown, ChevronUp, ZoomIn, ZoomOut, X, Building2, Mail, Phone, Users } from "lucide-react"
import api from "../services/api"
import { SkeletonCard } from "../components/UI"

const orgData = {
  id: "pdg",
  title: "President Directeur General",
  name: "M. Karim Bensalem",
  email: "pdg@algerietelecom.dz",
  phone: "+213 21 XXX XXX",
  color: "#003DA5",
  children: [
    {
      id: "cellule",
      title: "Cellule Reporting & Analyse",
      name: "Mme. Nadia Khelifi",
      email: "reporting@algerietelecom.dz",
      phone: "+213 21 XXX XXX",
      color: "#555",
      children: [],
    },
    {
      id: "inspection",
      title: "Inspection Generale",
      name: "M. Mourad Tebbal",
      email: "inspection@algerietelecom.dz",
      phone: "+213 21 XXX XXX",
      color: "#555",
      children: [],
    },
    {
      id: "dsi",
      title: "Division Systemes d'Information",
      name: "M. Yacine Boudiaf",
      email: "dsi@algerietelecom.dz",
      phone: "+213 21 XXX XXX",
      color: "#00A650",
      children: [
        { id: "dir-secu", title: "Direction Securite des Systemes d'Information", name: "M. Amar Bouzidi", email: "securite.si@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#00A650", children: [] },
        { id: "dir-infra", title: "Direction Infrastructures Informatiques", name: "Mme. Samira Hadj-Ali", email: "infra.info@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#00A650", children: [] },
        { id: "dir-dev", title: "Direction Developpement Systemes d'Information", name: "M. Rachid Ferhat", email: "dev.si@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#00A650", children: [] },
        { id: "dir-billing", title: "Direction Systemes Billings", name: "Mme. Farida Amrane", email: "billing@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#00A650", children: [] },
      ],
    },
    {
      id: "drh",
      title: "Division Ressources Humaines et Formation",
      name: "Mme. Leila Mebarki",
      email: "drh@algerietelecom.dz",
      phone: "+213 21 XXX XXX",
      color: "#003DA5",
      children: [
        {
          id: "dir-carrieres",
          title: "Direction Gestion des Carrieres et des Competences",
          name: "M. Djamel Ouali",
          email: "carrieres@algerietelecom.dz",
          phone: "+213 21 XXX XXX",
          color: "#003DA5",
          children: [],
        },
        {
          id: "dir-formation",
          title: "Direction de la Formation",
          name: "Mme. Houria Belkacemi",
          email: "formation@algerietelecom.dz",
          phone: "+213 21 XXX XXX",
          color: "#003DA5",
          children: [
            {
              id: "dept-qualite",
              title: "Departement Developpement et Management de la Qualite",
              name: "M. Samir Bencherif",
              email: "qualite@algerietelecom.dz",
              phone: "+213 21 XXX XXX",
              color: "#003DA5",
              children: [
                { id: "s-qualite", title: "Service Management de la Qualite", name: "Mme. Assia Boudali", email: "s.qualite@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
                { id: "s-etude", title: "Service Etude & Developpement Formation", name: "M. Hocine Zeroual", email: "s.etude@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
                { id: "s-support", title: "Service Support, Suivi, Budget & Reporting", name: "Mme. Rania Tlemcani", email: "s.support@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
              ],
            },
            {
              id: "dept-competences",
              title: "Departement Developpement des Competences",
              name: "M. Kamel Ghribi",
              email: "competences@algerietelecom.dz",
              phone: "+213 21 XXX XXX",
              color: "#003DA5",
              children: [
                { id: "s-tech", title: "Service Formations Techniques", name: "M. Nabil Kara", email: "s.tech@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
                { id: "s-manag", title: "Service Formations Manageriales et Commerciales", name: "Mme. Wafa Benali", email: "s.manag@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
                { id: "s-cadres", title: "Service Formations Cadres Superieurs & Clients Partenaires", name: "M. Sofiane Laib", email: "s.cadres@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
              ],
            },
            {
              id: "dept-veille",
              title: "Departement Veille Formation & Partenariats",
              name: "Mme. Nabila Sediki",
              email: "veille@algerietelecom.dz",
              phone: "+213 21 XXX XXX",
              color: "#003DA5",
              children: [
                { id: "s-veille", title: "Service Veille Formation & Partenariats Nationaux & Internationaux", name: "M. Tarek Mahiout", email: "s.veille@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
                { id: "s-etude2", title: "Service Etude & Developpement Formation", name: "Mme. Imane Bensaid", email: "s.etude2@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
              ],
            },
          ],
        },
        { id: "dir-relations", title: "Direction des Relations Socioprofessionnelles", name: "M. Hamid Mekki", email: "relations.soc@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#003DA5", children: [] },
        { id: "dir-etudes", title: "Direction des Etudes", name: "Mme. Zohra Bendjama", email: "etudes@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#003DA5", children: [] },
      ],
    },
    { id: "dcm", title: "Division Commerciale, Communication et Marketing", name: "M. Bilal Hadidi", email: "commercial@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#00A650", children: [] },
    { id: "dfc", title: "Division Finances & Comptabilite", name: "Mme. Karima Bouziane", email: "finances@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#003DA5", children: [] },
    { id: "dir-interconnexion", title: "Division Interconnexion et Relations Internationales", name: "M. Adel Boukhobza", email: "interconnexion@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#00A650", children: [] },
    { id: "dir-surete", title: "Direction Surete Interne de l'Entreprise", name: "M. Lotfi Aoudjane", email: "surete@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
    { id: "dir-juridique", title: "Direction Affaires Juridiques", name: "Mme. Sara Benkhalil", email: "juridique@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
    { id: "dir-audit", title: "Direction Audit Interne", name: "M. Fares Toumi", email: "audit@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
    { id: "dir-achats", title: "Division Achats, Moyens & Patrimoine", name: "Mme. Djamila Rekik", email: "achats@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#00A650", children: [] },
    {
      id: "pole-infra",
      title: "Pole Infrastructures et Reseaux",
      name: "M. Abdelaziz Guerroudj",
      email: "infra@algerietelecom.dz",
      phone: "+213 21 XXX XXX",
      color: "#003DA5",
      children: [
        { id: "div-transport", title: "Division Reseaux Transport", name: "M. Hani Beddiaf", email: "reseaux.transport@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#003DA5", children: [] },
        { id: "div-core", title: "Division Reseau Core", name: "Mme. Lydia Chaker", email: "reseau.core@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#003DA5", children: [] },
        { id: "div-acces", title: "Division Reseaux Acces", name: "M. Mehdi Bouchenak", email: "reseaux.acces@algerietelecom.dz", phone: "+213 21 XXX XXX", color: "#003DA5", children: [] },
      ],
    },
    {
      id: "do",
      title: "Directions Operationnelles (60 DO)",
      name: "Directions Regionales",
      email: "do@algerietelecom.dz",
      phone: "+213 21 XXX XXX",
      color: "#555",
      children: [
        { id: "do-alger1", title: "DOT Alger Centre", name: "M. Chaabane Khelil", email: "alger1@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
        { id: "do-alger2", title: "DOT Alger Est", name: "Mme. Nassira Belmahi", email: "alger2@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
        { id: "do-alger3", title: "DOT Alger Ouest", name: "M. Omar Brahimi", email: "alger3@at.dz", phone: "+213 21 XXX XXX", color: "#555", children: [] },
      ],
    },
  ],
}

function getBgColor(node, depth) {
  if (depth === 0) return "#003DA5"
  if (node.color === "#00A650") return "#00A650"
  if (node.color === "#003DA5") return "#003DA5"
  return "#4b5563"
}

function OrgCard({ node, depth, onSelect, selected, usersByStructure }) {
  const isSelected = selected?.id === node.id
  const hasChildren = node.children && node.children.length > 0
  const isRoot = depth === 0
  const nodeUsers = usersByStructure?.[node.id] || []
  const bgColor = getBgColor(node, depth)
  const initials = node.name.split(" ").map(w => w[0]).join("").slice(0, 2).toUpperCase()

  return (
    <div
      onClick={(e) => { e.stopPropagation(); onSelect(node) }}
      className={`relative cursor-pointer text-center transition-all duration-200 ${
        isRoot ? 'min-w-[220px] max-w-[260px] rounded-xl p-4' : 'min-w-[160px] max-w-[200px] rounded-lg p-2.5'
      }`}
      style={{
        background: isSelected ? (document.documentElement.classList.contains('dark') ? '#1F2937' : '#fff') : `${bgColor}15`,
        border: `2px solid ${isSelected ? bgColor : bgColor + '60'}`,
        boxShadow: isSelected ? `0 4px 20px ${bgColor}40` : 'none',
      }}
    >
      <div
        className={`mx-auto mb-2 rounded-full flex items-center justify-center font-bold text-white ${
          isRoot ? 'w-10 h-10 text-sm' : 'w-[30px] h-[30px] text-[11px]'
        }`}
        style={{ background: bgColor }}
      >
        {initials}
      </div>
      <div
        className={`font-bold leading-tight mb-1 ${isRoot ? 'text-[13px]' : 'text-[10px]'}`}
        style={{ color: isSelected ? bgColor : undefined }}
      >
        <span className={isSelected ? '' : 'text-gray-800 dark:text-gray-100'}>{node.title}</span>
      </div>
      <div className={`italic text-[#5A6070] dark:text-[#9AA0AE] ${isRoot ? 'text-[11px]' : 'text-[9px]'}`}>
        {node.name}
      </div>
      <div
        className="absolute top-2.5 right-2.5 px-2 py-1 rounded-full text-[10px] font-bold text-white border border-white/35"
        style={{ background: nodeUsers.length > 0 ? '#16a34a' : '#9ca3af' }}
      >
        {nodeUsers.length > 0 ? `${nodeUsers.length} u.` : 'Vacant'}
      </div>
      {hasChildren && (
        <div
          className="absolute -bottom-2 left-1/2 -translate-x-1/2 rounded-full w-4 h-4 text-[10px] flex items-center justify-center font-bold text-white"
          style={{ background: bgColor }}
        >
          {node.children.length}
        </div>
      )}
    </div>
  )
}

function TreeNode({ node, depth, onSelect, selected, expandedIds, toggleExpand, usersByStructure }) {
  const isExpanded = expandedIds.includes(node.id)
  const hasChildren = node.children && node.children.length > 0

  return (
    <div className="flex flex-col items-center">
      <div className="relative">
        <OrgCard node={node} depth={depth} onSelect={onSelect} selected={selected} usersByStructure={usersByStructure} />
        {hasChildren && (
          <button
            onClick={(e) => { e.stopPropagation(); toggleExpand(node.id) }}
            className="absolute -bottom-5 left-1/2 -translate-x-1/2 rounded-full w-5 h-5 text-white cursor-pointer text-sm flex items-center justify-center z-10 border-none"
            style={{ background: isExpanded ? '#ef4444' : '#00A650' }}
          >
            {isExpanded ? '−' : '+'}
          </button>
        )}
      </div>

      {hasChildren && isExpanded && (
        <div className="mt-7 flex flex-col items-center">
          <div className="w-0.5 h-5 bg-gray-300 dark:bg-gray-600" />
          {node.children.length > 1 && (
            <div className="h-0.5 bg-gray-300 dark:bg-gray-600" style={{ width: `${node.children.length * 220}px`, maxWidth: '90vw' }} />
          )}
          <div className="flex gap-4 flex-wrap justify-center">
            {node.children.map((child) => (
              <div key={child.id} className="flex flex-col items-center">
                <div className="w-0.5 h-5 bg-gray-300 dark:bg-gray-600" />
                <TreeNode
                  node={child}
                  depth={depth + 1}
                  onSelect={onSelect}
                  selected={selected}
                  expandedIds={expandedIds}
                  toggleExpand={toggleExpand}
                  usersByStructure={usersByStructure}
                />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function DetailPanel({ node, onClose, usersByStructure }) {
  if (!node) return null
  const bgColor = getBgColor(node, node.id === 'pdg' ? 0 : 1)
  const nodeUsers = usersByStructure?.[node.id] || []
  const initials = (nodeUsers[0]?.name || node.name).split(" ").map(w => w[0]).join("").slice(0, 2).toUpperCase()

  const roleBadge = (role) => {
    const r = (role || "").toLowerCase()
    if (r === "admin") return "bg-blue-600 text-white"
    if (r === "validateur") return "bg-amber-500 text-gray-900"
    if (r === "demandeur") return "bg-green-600 text-white"
    return "bg-gray-400 text-white"
  }

  return (
    <motion.div
      initial={{ x: '100%' }}
      animate={{ x: 0 }}
      exit={{ x: '100%' }}
      transition={{ duration: 0.3 }}
      className="fixed right-0 top-0 bottom-0 w-80 bg-white dark:bg-gray-800 shadow-[-4px_0_30px_rgba(0,0,0,0.15)] z-[1000] flex flex-col"
    >
      <div className="px-5 py-6 text-white" style={{ background: bgColor }}>
        <button onClick={onClose} className="bg-white/20 border-none rounded-md text-white cursor-pointer px-2.5 py-1 text-xs mb-3">
          <X size={14} className="inline mr-1" />Fermer
        </button>
        <div className="w-[60px] h-[60px] rounded-full bg-white/25 flex items-center justify-center text-[22px] font-bold mb-3">
          {initials}
        </div>
        <div className="text-lg font-bold mb-1">
          {nodeUsers.length > 0 ? `${nodeUsers.length} utilisateur(s)` : "Poste vacant"}
        </div>
        <div className="text-[13px] opacity-85">{node.title}</div>
      </div>

      <div className="p-5 flex-1 overflow-y-auto">
        <div className="flex gap-3 py-3 border-b border-gray-100 dark:border-gray-700">
          <Mail size={18} className="text-[#9AA0AE] dark:text-[#5A6070] mt-0.5" />
          <div>
            <div className="text-[11px] text-[#9AA0AE] dark:text-[#5A6070] font-semibold mb-0.5">Email</div>
            <div className="text-[13px] text-gray-800 dark:text-gray-200">{node.email}</div>
          </div>
        </div>
        <div className="flex gap-3 py-3 border-b border-gray-100 dark:border-gray-700">
          <Phone size={18} className="text-[#9AA0AE] dark:text-[#5A6070] mt-0.5" />
          <div>
            <div className="text-[11px] text-[#9AA0AE] dark:text-[#5A6070] font-semibold mb-0.5">Telephone</div>
            <div className="text-[13px] text-gray-800 dark:text-gray-200">{node.phone}</div>
          </div>
        </div>
        {node.children && node.children.length > 0 && (
          <div className="flex gap-3 py-3 border-b border-gray-100 dark:border-gray-700">
            <Users size={18} className="text-[#9AA0AE] dark:text-[#5A6070] mt-0.5" />
            <div>
              <div className="text-[11px] text-[#9AA0AE] dark:text-[#5A6070] font-semibold mb-0.5">Sous-structures</div>
              <div className="text-[13px] text-gray-800 dark:text-gray-200">{node.children.length} unite(s)</div>
            </div>
          </div>
        )}

        <div className="mt-4">
          <div className="text-xs font-bold text-gray-900 dark:text-white mb-2.5">Utilisateurs affectes</div>
          {nodeUsers.length > 0 ? (
            <div className="flex flex-col gap-2.5">
              {nodeUsers.map((u) => (
                <div key={u.id} className="border border-gray-200 dark:border-gray-600 rounded-xl p-2.5 bg-white dark:bg-gray-700">
                  <div className="flex items-center justify-between gap-2">
                    <div className="text-[13px] font-bold text-gray-900 dark:text-white">{u.name}</div>
                    <span className={`text-[11px] font-extrabold px-2 py-0.5 rounded-full ${roleBadge(u.role)}`}>
                      {u.role || "—"}
                    </span>
                  </div>
                  <div className="mt-1 text-xs text-[#5A6070] dark:text-[#9AA0AE]">{u.email}</div>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-3 rounded-xl bg-gray-50 dark:bg-gray-700/50 border border-dashed border-gray-300 dark:border-gray-600">
              <div className="text-xs text-[#5A6070] dark:text-[#9AA0AE]">Aucun utilisateur affecte a cette structure.</div>
            </div>
          )}
        </div>

        <div className="mt-5 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600">
          <div className="text-[11px] text-[#5A6070] dark:text-[#9AA0AE] mb-1.5 font-semibold">NOTE</div>
          <div className="text-xs text-gray-600 dark:text-gray-300 leading-relaxed">
            Les informations de contact sont fictives conformement aux exigences de confidentialite d'Algerie Telecom. La structure hierarchique est officielle.
          </div>
        </div>
      </div>
    </motion.div>
  )
}

function LegendItem({ color, label }) {
  return (
    <div className="flex items-center gap-2">
      <div className="w-3.5 h-3.5 rounded-sm" style={{ background: color }} />
      <span className="text-xs text-gray-600 dark:text-gray-300">{label}</span>
    </div>
  )
}

export default function Organigramme() {
  const [selected, setSelected] = useState(null)
  const [expandedIds, setExpandedIds] = useState(["pdg"])
  const [search, setSearch] = useState("")
  const [usersByStructure, setUsersByStructure] = useState({})
  const [loading, setLoading] = useState(true)
  const [zoom, setZoom] = useState(1)

  useEffect(() => {
    let mounted = true
    setLoading(true)
    api.get("/users/by-structure")
      .then((res) => { if (mounted) setUsersByStructure(res.data || {}) })
      .catch(() => { if (mounted) setUsersByStructure({}) })
      .finally(() => { if (mounted) setLoading(false) })
    return () => { mounted = false }
  }, [])

  const toggleExpand = (id) => {
    setExpandedIds((prev) => prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id])
  }

  const collectIds = (node) => [node.id, ...(node.children || []).flatMap(collectIds)]
  const expandAll = () => setExpandedIds(collectIds(orgData))
  const collapseAll = () => setExpandedIds(["pdg"])

  const searchResults = useMemo(() => {
    if (!search.trim()) return []
    const results = []
    const q = search.toLowerCase()
    const walk = (node) => {
      if (node.name.toLowerCase().includes(q) || node.title.toLowerCase().includes(q)) results.push(node)
      ;(node.children || []).forEach(walk)
    }
    walk(orgData)
    return results
  }, [search])

  const zoomIn = () => setZoom(z => Math.min(z + 0.15, 2))
  const zoomOut = () => setZoom(z => Math.max(z - 0.15, 0.4))
  const zoomReset = () => setZoom(1)

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 font-sans">
      {/* Header AT */}
      <div className="bg-gradient-to-br from-[#003DA5] to-[#00A650] px-4 sm:px-6 py-5 text-white">
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div className="flex items-center gap-3.5">
            <div className="w-11 h-11 rounded-xl bg-white/20 flex items-center justify-center">
              <Building2 size={22} />
            </div>
            <div>
              <div className="text-xl font-extrabold tracking-tight">Algerie Telecom</div>
              <div className="text-[13px] opacity-85">Organigramme General Interactif</div>
            </div>
          </div>

          <div className="flex gap-2 flex-wrap">
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-white/60" />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Rechercher..."
                className="pl-8 pr-3 py-2 rounded-lg border-none text-[13px] bg-white/20 text-white outline-none backdrop-blur-sm w-44 placeholder:text-white/50"
              />
            </div>
            <button onClick={expandAll} className="px-3 py-2 rounded-lg border-none cursor-pointer text-xs font-semibold bg-[#00A650] text-white hover:bg-[#009040] transition-colors">
              <ChevronDown size={14} className="inline mr-1" />Deplier
            </button>
            <button onClick={collapseAll} className="px-3 py-2 rounded-lg border-none cursor-pointer text-xs font-semibold bg-white/20 text-white hover:bg-white/30 transition-colors">
              <ChevronUp size={14} className="inline mr-1" />Replier
            </button>
          </div>
        </div>
      </div>

      {/* Description + Legende */}
      <div className="px-4 sm:px-6 py-3 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <p className="text-xs text-[#5A6070] dark:text-[#9AA0AE] mb-2 leading-relaxed">
          Organigramme de la Direction Generale d'Algerie Telecom.
          Structure officielle extraite des documents internes (memoire ISIL E-014). Les noms du personnel sont fictifs.
        </p>
        <div className="flex gap-4 flex-wrap items-center">
          <LegendItem color="#003DA5" label="Direction / Division Centrale" />
          <LegendItem color="#00A650" label="Division Technique / Commerciale" />
          <LegendItem color="#4b5563" label="Direction Support / Operationnelle" />
          <div className="ml-auto text-[11px] text-[#9AA0AE] dark:text-[#5A6070]">* Noms fictifs</div>
        </div>
      </div>

      {/* Zoom controls */}
      <div className="fixed bottom-6 right-6 z-50 flex flex-col gap-2">
        <button onClick={zoomIn} className="w-10 h-10 rounded-xl bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 shadow-lg flex items-center justify-center cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors">
          <ZoomIn size={18} className="text-gray-700 dark:text-gray-200" />
        </button>
        <button onClick={zoomReset} className="w-10 h-10 rounded-xl bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 shadow-lg flex items-center justify-center cursor-pointer text-xs font-bold text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors">
          {Math.round(zoom * 100)}%
        </button>
        <button onClick={zoomOut} className="w-10 h-10 rounded-xl bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 shadow-lg flex items-center justify-center cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors">
          <ZoomOut size={18} className="text-gray-700 dark:text-gray-200" />
        </button>
      </div>

      {/* Resultats recherche */}
      <AnimatePresence>
        {search.trim() && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="overflow-hidden px-4 sm:px-6 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700"
          >
            <div className="py-3">
              <div className="text-[13px] font-semibold text-gray-700 dark:text-gray-200 mb-2">
                {searchResults.length} resultat(s) pour "{search}"
              </div>
              <div className="flex gap-2 flex-wrap">
                {searchResults.map((r) => (
                  <div
                    key={r.id}
                    onClick={() => { setSelected(r); setSearch("") }}
                    className="px-3 py-1.5 bg-gray-100 dark:bg-gray-700 rounded-md cursor-pointer text-xs border border-gray-200 dark:border-gray-600 hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
                  >
                    <span className="font-semibold text-gray-900 dark:text-white">{r.name}</span>
                    <span className="text-[#5A6070] dark:text-[#9AA0AE]"> &mdash; {r.title}</span>
                  </div>
                ))}
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Skeleton / Arbre */}
      {loading ? (
        <div className="p-6 space-y-3">
          {[0, 1, 2].map(i => <SkeletonCard key={i} />)}
        </div>
      ) : (
        <div
          className="p-6 sm:p-10 overflow-x-auto overflow-y-auto transition-[padding] duration-300"
          style={{ minHeight: 'calc(100vh - 160px)', paddingRight: selected ? 360 : undefined }}
        >
          <div className="inline-block min-w-full origin-top-left transition-transform duration-200" style={{ transform: `scale(${zoom})` }}>
            <TreeNode
              node={orgData}
              depth={0}
              onSelect={setSelected}
              selected={selected}
              expandedIds={expandedIds}
              toggleExpand={toggleExpand}
              usersByStructure={usersByStructure}
            />
          </div>
        </div>
      )}

      {/* Panneau detail */}
      <AnimatePresence>
        {selected && (
          <DetailPanel node={selected} onClose={() => setSelected(null)} usersByStructure={usersByStructure} />
        )}
      </AnimatePresence>
    </div>
  )
}
