import { useCallback, useEffect, useMemo, useState } from 'react'
import { motion } from 'framer-motion'
import { Download, FileText, Upload, RotateCcw, Trash2 } from 'lucide-react'
import toast from 'react-hot-toast'

import { documentsAPI } from '../../../services/api'
import { Badge, Button, EmptyState, Modal } from '../../../components/UI'

function dlFromBlob(data, nom) {
  const blob = data instanceof Blob ? data : new Blob([data])
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = nom
  a.click()
  URL.revokeObjectURL(url)
}

const TYPE_DOCUMENT_OPTIONS = [
  { value: '', label: 'Sélectionner…' },
  { value: 'ordre_mission', label: 'Ordre de mission' },
  { value: 'autorisation', label: 'Autorisation' },
  { value: 'facture', label: 'Facture' },
  { value: 'rapport', label: 'Rapport' },
  { value: 'justificatif', label: 'Justificatif' },
  { value: 'contrat', label: 'Contrat' },
  { value: 'autre', label: 'Autre' },
]

export default function Step3Documents({ missionId, onNext, onPrev }) {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [documents, setDocuments] = useState([])

  const [typeDoc, setTypeDoc] = useState('ordre_mission')
  const [description, setDescription] = useState('')
  const [file, setFile] = useState(null)
  const [uploading, setUploading] = useState(false)

  const [confirmDeleteOpen, setConfirmDeleteOpen] = useState(false)
  const [pendingDeleteId, setPendingDeleteId] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const resetForm = () => {
    setTypeDoc('ordre_mission')
    setDescription('')
    setFile(null)
  }

  const loadDocuments = useCallback(async () => {
    if (!missionId) return
    setLoading(true)
    setError('')
    try {
      const res = await documentsAPI.list(missionId)
      const list = Array.isArray(res.data) ? res.data : []
      setDocuments(list)
    } catch (err) {
      setDocuments([])
      setError(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur lors du chargement des documents'
      )
    } finally {
      setLoading(false)
    }
  }, [missionId])

  useEffect(() => {
    loadDocuments()
  }, [loadDocuments])

  const canUpload = useMemo(() => !!file && !!typeDoc && !uploading, [file, typeDoc, uploading])

  const handleUpload = async (e) => {
    e.preventDefault()
    if (!missionId || !file || !typeDoc) return
    setUploading(true)
    setError('')
    try {
      const fd = new FormData()
      fd.append('fichier', file)
      fd.append('type_document', typeDoc)
      if (String(description ?? '').trim()) fd.append('description', description.trim())

      const res = await documentsAPI.upload(missionId, fd)
      const created = res?.data ?? null
      if (!created?.id) throw new Error("Réponse invalide lors de l'upload du document")

      setDocuments((prev) => [created, ...prev])
      toast.success('Document uploadé ✅')
      resetForm()
    } catch (err) {
      toast.error(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          "Erreur lors de l'upload du document"
      )
    } finally {
      setUploading(false)
    }
  }

  const handleDownload = async (id, nomFichier) => {
    try {
      const res = await documentsAPI.telecharger(id)
      dlFromBlob(res.data, nomFichier)
      toast.success('Téléchargement lancé ✅')
    } catch (err) {
      toast.error(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur téléchargement'
      )
    }
  }

  const askDelete = (id) => {
    setPendingDeleteId(id)
    setConfirmDeleteOpen(true)
  }

  const confirmDelete = async () => {
    if (!pendingDeleteId) return
    setDeleting(true)
    try {
      await documentsAPI.delete(pendingDeleteId)
      setDocuments((prev) => prev.filter((d) => d?.id !== pendingDeleteId))
      toast.success('Document supprimé ✅')
      setConfirmDeleteOpen(false)
      setPendingDeleteId(null)
    } catch (err) {
      toast.error(
        err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          'Erreur suppression'
      )
    } finally {
      setDeleting(false)
    }
  }

  if (!missionId) {
    return (
      <div className="at-card-surface p-6">
        <div className="text-sm font-semibold text-red-700 mb-2">Mission introuvable</div>
        <div className="text-sm text-gray-600 mb-4">Revenez à l’étape 1 pour créer la mission.</div>
        <Button variant="outline" onClick={onPrev}>
          ← Précédent
        </Button>
      </div>
    )
  }

  return (
    <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.2 }}>
      <div className="flex items-start justify-between gap-4 flex-wrap mb-5">
        <div>
          <h3 className="text-base font-semibold text-gray-700 mb-2">Documents</h3>
          <p className="text-sm text-gray-400">Ajoutez vos pièces jointes (optionnel pour soumission).</p>
        </div>
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-at-blue/10 border border-at-blue/20 text-at-blue text-xs font-semibold">
          <FileText size={14} /> Étape 3/4
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-2xl p-4 mb-4">
          <div className="text-sm font-semibold text-red-800 mb-1">Erreur</div>
          <div className="text-sm text-red-700">{error}</div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <div className="lg:col-span-2 at-card-surface p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="text-sm font-semibold text-gray-800">Upload</div>
            <Button variant="ghost" size="sm" onClick={resetForm} disabled={uploading} className="px-2">
              <RotateCcw size={16} />
            </Button>
          </div>

          <form onSubmit={handleUpload} className="space-y-3">
            <label className="block text-xs font-semibold text-gray-500 mb-2">Type de document</label>
            <select
              value={typeDoc}
              onChange={(e) => setTypeDoc(e.target.value)}
              className="w-full px-3 py-3 rounded-xl border border-gray-200 bg-white text-sm text-gray-800
                         focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green"
            >
              {TYPE_DOCUMENT_OPTIONS.map((o) => (
                <option key={o.value || 'x'} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>

            <label className="block text-xs font-semibold text-gray-500 mb-2">Fichier</label>
            <input
              type="file"
              accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png"
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              disabled={uploading}
              className="w-full text-sm text-gray-700"
            />

            <div>
              <label className="block text-xs font-semibold text-gray-500 mb-2">Description (optionnel)</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Ex: justifications pour l’ordre"
                rows={3}
                className="w-full px-3 py-2 rounded-xl border border-gray-200 bg-white text-sm text-gray-800
                           focus:outline-none focus:ring-1 focus:ring-at-green/30 focus:border-at-green resize-none"
              />
            </div>

            <Button type="submit" loading={uploading} disabled={!canUpload} className="w-full">
              <Upload size={16} /> Envoyer
            </Button>

            <div className="text-xs text-gray-500">
              Formats acceptés : PDF/DOC/DOCX/XLS/XLSX/JPG/PNG.
            </div>
          </form>
        </div>

        <div className="lg:col-span-3">
          {loading ? (
            <div className="space-y-3">
              {[0, 1, 2].map((i) => (
                <div key={i} className="at-card-surface p-4">
                  <div className="h-4 bg-gray-100 rounded animate-pulse w-1/2 mb-3" />
                  <div className="h-4 bg-gray-100 rounded animate-pulse w-3/4 mb-2" />
                  <div className="h-4 bg-gray-100 rounded animate-pulse w-2/3" />
                </div>
              ))}
            </div>
          ) : documents.length === 0 ? (
            <EmptyState
              icon={FileText}
              title="Aucun document"
              subtitle="Ajoutez une pièce pour enrichir votre ordre de mission."
            />
          ) : (
            <div className="space-y-3">
              {documents.map((d, idx) => (
                <motion.div
                  key={d.id ?? `${d.nom_fichier}_${idx}`}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2, delay: idx * 0.02 }}
                  className="at-card-surface p-4"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 mb-2">
                        <Badge status="actif" label={d.type_document ?? 'document'} />
                      </div>
                      <div className="font-semibold text-gray-800 truncate">{d.nom_fichier ?? '—'}</div>
                      <div className="text-sm text-gray-600">
                        Taille: <span className="font-semibold">{d.taille ?? '—'}</span>
                      </div>
                      <div className="text-sm text-gray-600">
                        Ajouté: <span className="font-semibold">{d.created_at ?? '—'}</span>
                      </div>
                    </div>
                    <div className="flex flex-col items-end gap-2">
                      <Button size="sm" variant="outline" onClick={() => handleDownload(d.id, d.nom_fichier)}>
                        <Download size={14} /> Télécharger
                      </Button>
                      <Button
                        size="sm"
                        variant="danger"
                        onClick={() => askDelete(d.id)}
                      >
                        <Trash2 size={14} /> Supprimer
                      </Button>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="flex justify-between gap-3 mt-6 flex-wrap">
        <Button variant="outline" onClick={onPrev} disabled={uploading}>
          ← Précédent
        </Button>
        <Button onClick={onNext} disabled={uploading} className="min-w-[220px]">
          Suivant → Récapitulatif
        </Button>
      </div>

      <Modal
        isOpen={confirmDeleteOpen}
        onClose={() => {
          if (deleting) return
          setConfirmDeleteOpen(false)
          setPendingDeleteId(null)
        }}
        title="Supprimer le document ?"
      >
        <div className="text-sm text-gray-700 mb-4">
          Cette action supprime la pièce jointe de la mission.
        </div>
        <div className="flex items-center justify-end gap-3">
          <Button variant="outline" onClick={() => setConfirmDeleteOpen(false)} disabled={deleting}>
            Annuler
          </Button>
          <Button onClick={confirmDelete} loading={deleting} disabled={deleting}>
            <Trash2 size={16} /> Supprimer
          </Button>
        </div>
      </Modal>
    </motion.div>
  )
}
