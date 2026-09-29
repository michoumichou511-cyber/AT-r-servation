import { useEffect, useState, useMemo } from 'react'
import { MapContainer, TileLayer, CircleMarker, Popup, useMap } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import api from '../../services/api'

const VILLES_COORDS = {
  'Alger': [36.7538, 3.0588],
  'Oran': [35.6969, -0.6331],
  'Constantine': [36.3650, 6.6147],
  'Annaba': [36.9000, 7.7667],
  'Sétif': [36.1898, 5.4108],
  'Béjaïa': [36.7508, 5.0567],
  'Blida': [36.4722, 2.8278],
  'Tizi Ouzou': [36.7169, 3.9708],
  'Batna': [35.5567, 6.1742],
  'Biskra': [34.8449, 5.7248],
  'Tlemcen': [34.8828, -1.3167],
  'Ouargla': [31.9497, 5.3253],
  'Ghardaïa': [32.4912, 3.6733],
  'Djelfa': [34.6704, 3.2503],
  'Tamanrasset': [22.7903, 5.5228],
  'Béchar': [31.6167, -2.2167],
  'El Oued': [33.3683, 6.8673],
  'Tipaza': [36.5897, 2.4483],
  'Boumerdès': [36.7603, 3.4753],
  'Jijel': [36.8208, 5.7667],
  'Skikda': [36.8764, 6.9092],
  'Mostaganem': [35.9311, 0.0892],
  'M\'Sila': [35.7056, 4.5450],
  'Médéa': [36.2675, 2.7503],
  'Chlef': [36.1647, 1.3317],
  'Tiaret': [35.3711, 1.3178],
  'Hassi Messaoud': [31.6800, 6.0700],
  'Paris': [48.8566, 2.3522],
  'Tunis': [36.8065, 10.1815],
  'Istanbul': [41.0082, 28.9784],
  'Dubaï': [25.2048, 55.2708],
}

function findCoords(ville) {
  if (!ville) return null
  const normalized = ville.trim()
  if (VILLES_COORDS[normalized]) return VILLES_COORDS[normalized]
  const key = Object.keys(VILLES_COORDS).find(k =>
    normalized.toLowerCase().includes(k.toLowerCase()) ||
    k.toLowerCase().includes(normalized.toLowerCase())
  )
  return key ? VILLES_COORDS[key] : null
}

function FitBounds({ positions }) {
  const map = useMap()
  useEffect(() => {
    if (positions.length > 0) {
      map.fitBounds(positions, { padding: [30, 30], maxZoom: 8 })
    }
  }, [map, positions])
  return null
}

export default function CarteMissions() {
  const [missions, setMissions] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/missions')
      .then(res => {
        const data = res.data?.data?.data || res.data?.data || res.data || []
        setMissions(Array.isArray(data) ? data : [])
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const markers = useMemo(() => {
    const grouped = {}
    missions.forEach(m => {
      const ville = m.destination_ville
      if (!ville) return
      const coords = findCoords(ville)
      if (!coords) return
      if (!grouped[ville]) grouped[ville] = { coords, missions: [], count: 0 }
      grouped[ville].missions.push(m)
      grouped[ville].count++
    })
    return Object.entries(grouped).map(([ville, data]) => ({
      ville,
      coords: data.coords,
      count: data.count,
      missions: data.missions.slice(0, 5),
    }))
  }, [missions])

  const positions = markers.map(m => m.coords)

  if (loading) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
        <div className="animate-pulse h-[400px] bg-gray-200 dark:bg-gray-700 rounded-xl" />
      </div>
    )
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-sm border border-gray-100 dark:border-gray-700">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white">
          Carte des déplacements
        </h3>
        <span className="text-xs text-gray-500 bg-gray-100 dark:bg-gray-700 dark:text-gray-400 px-3 py-1 rounded-full">
          {markers.length} destination{markers.length > 1 ? 's' : ''}
        </span>
      </div>
      <div className="rounded-xl overflow-hidden border border-gray-200 dark:border-gray-600" style={{ height: 400 }}>
        <MapContainer
          center={[28.0339, 1.6596]}
          zoom={5}
          style={{ height: '100%', width: '100%' }}
          scrollWheelZoom={false}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {positions.length > 0 && <FitBounds positions={positions} />}
          {markers.map(m => (
            <CircleMarker
              key={m.ville}
              center={m.coords}
              radius={Math.min(8 + m.count * 3, 25)}
              pathOptions={{
                fillColor: '#003DA5',
                fillOpacity: 0.7,
                color: '#00A650',
                weight: 2,
              }}
            >
              <Popup>
                <div className="min-w-[180px]">
                  <p className="font-bold text-[#003DA5] text-sm mb-1">{m.ville}</p>
                  <p className="text-xs text-gray-500 mb-2">{m.count} mission{m.count > 1 ? 's' : ''}</p>
                  {m.missions.map((mi, i) => (
                    <div key={i} className="text-xs border-t border-gray-100 pt-1 mt-1">
                      <span className="font-medium">{mi.titre || mi.objet_mission}</span>
                      {mi.date_depart && <span className="text-gray-400 ml-1">({mi.date_depart?.slice(0, 10)})</span>}
                    </div>
                  ))}
                  {m.count > 5 && <p className="text-xs text-gray-400 mt-1">+ {m.count - 5} autres</p>}
                </div>
              </Popup>
            </CircleMarker>
          ))}
        </MapContainer>
      </div>
    </div>
  )
}
