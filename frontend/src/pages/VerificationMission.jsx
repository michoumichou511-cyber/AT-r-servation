import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL
  ?? (import.meta.env.DEV ? '/api' : 'https://at-r-servation.onrender.com/api')

const statusColors = {
  brouillon: 'bg-gray-100 text-gray-700',
  soumise: 'bg-blue-100 text-blue-700',
  en_validation: 'bg-yellow-100 text-yellow-700',
  approuvee: 'bg-green-100 text-green-700',
  rejetee: 'bg-red-100 text-red-700',
  en_traitement: 'bg-purple-100 text-purple-700',
  terminee: 'bg-emerald-100 text-emerald-700',
}

const statusLabels = {
  brouillon: 'Brouillon',
  soumise: 'Soumise',
  en_validation: 'En validation',
  approuvee: 'Approuvée',
  rejetee: 'Rejetée',
  en_traitement: 'En traitement',
  terminee: 'Terminée',
}

export default function VerificationMission() {
  const { numero } = useParams()
  const [mission, setMission] = useState(null)
  const [error, setError] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    axios.get(`${API_URL}/verification/${numero}`)
      .then(res => {
        if (res.data.success) setMission(res.data.data)
        else setError(true)
      })
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }, [numero])

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#003DA5]/5 via-[#F4F6FA] to-[#00A650]/5 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl max-w-md w-full overflow-hidden">
        <div className="bg-gradient-to-r from-[#003DA5] to-[#003DA5]/90 p-6 text-center">
          <h1 className="text-white text-xl font-bold tracking-wide">ALGERIE TELECOM</h1>
          <p className="text-white/70 text-xs mt-1">Vérification d'ordre de mission</p>
        </div>

        <div className="p-6">
          {loading && (
            <div className="flex flex-col items-center gap-3 py-8">
              <div className="w-10 h-10 border-4 border-[#00A650]/20 border-t-[#00A650] rounded-full animate-spin" />
              <p className="text-gray-500 text-sm">Vérification en cours...</p>
            </div>
          )}

          {error && (
            <div className="text-center py-8">
              <div className="text-5xl mb-3">❌</div>
              <h2 className="text-lg font-semibold text-red-600">Document non trouvé</h2>
              <p className="text-gray-500 text-sm mt-2">
                Ce numéro d'ordre de mission n'existe pas dans le système.
              </p>
            </div>
          )}

          {mission && (
            <div className="space-y-4">
              <div className="text-center mb-4">
                <div className="text-4xl mb-2">✅</div>
                <h2 className="text-lg font-semibold text-green-600">Document authentique</h2>
              </div>

              <div className="bg-gray-50 rounded-xl p-4 space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-medium text-gray-500 uppercase">Référence</span>
                  <span className="font-mono font-bold text-[#003DA5]">{mission.numero}</span>
                </div>
                <div className="border-t border-gray-200" />
                <div className="flex justify-between items-start">
                  <span className="text-xs font-medium text-gray-500 uppercase">Mission</span>
                  <span className="text-sm text-right max-w-[60%]">{mission.titre}</span>
                </div>
                <div className="border-t border-gray-200" />
                <div className="flex justify-between">
                  <span className="text-xs font-medium text-gray-500 uppercase">Demandeur</span>
                  <span className="text-sm">{mission.demandeur}</span>
                </div>
                <div className="border-t border-gray-200" />
                <div className="flex justify-between">
                  <span className="text-xs font-medium text-gray-500 uppercase">Destination</span>
                  <span className="text-sm">{mission.destination}</span>
                </div>
                <div className="border-t border-gray-200" />
                <div className="flex justify-between">
                  <span className="text-xs font-medium text-gray-500 uppercase">Période</span>
                  <span className="text-sm">{mission.date_depart} — {mission.date_retour}</span>
                </div>
                <div className="border-t border-gray-200" />
                <div className="flex justify-between items-center">
                  <span className="text-xs font-medium text-gray-500 uppercase">Statut</span>
                  <span className={`text-xs font-semibold px-3 py-1 rounded-full ${statusColors[mission.statut] || 'bg-gray-100 text-gray-700'}`}>
                    {statusLabels[mission.statut] || mission.statut}
                  </span>
                </div>
                <div className="border-t border-gray-200" />
                <div className="flex justify-between">
                  <span className="text-xs font-medium text-gray-500 uppercase">Créé le</span>
                  <span className="text-sm">{mission.cree_le}</span>
                </div>
              </div>

              <p className="text-center text-xs text-gray-400 mt-4">
                Vérifié le {new Date().toLocaleDateString('fr-FR')} — AT Réservations v2.0
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
