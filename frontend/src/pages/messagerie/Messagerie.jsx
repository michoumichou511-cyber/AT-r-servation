import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { MessageCircle, UserRound } from 'lucide-react'

import PageHeader from '../../components/Common/PageHeader'
import Modal from '../../components/UI/Modal'
import { EmptyState, SkeletonCard, SkeletonLine, Button, Input } from '../../components/UI'
import toast from 'react-hot-toast'
import api, { messagesAPI } from '../../services/api'
import { usePolling } from '../../hooks/usePolling'

// ─── Couleurs AT ────────────────────────────────────────────
const AT_GREEN = '#00A650'
const AT_BLUE = '#003DA5'

// ─── Petit composant Avatar ──────────────────────────────────
function Avatar({ name = '', size = 40, online = false, color = 'green' }) {
  const initials = initialsFromName(name)
  const colors = {
    green: { bg: '#e8f8f0', text: AT_GREEN },
    blue: { bg: '#e8eef8', text: AT_BLUE },
    amber: { bg: '#fef3e2', text: '#c87000' },
    coral: { bg: '#fdecea', text: '#c0392b' },
  }
  const c = colors[color] || colors.green
  return (
    <div style={{ position: 'relative', flexShrink: 0 }}>
      <div
        style={{
          width: size,
          height: size,
          borderRadius: '50%',
          background: c.bg,
          color: c.text,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontWeight: 700,
          fontSize: size * 0.32,
        }}
      >
        {initials}
      </div>
      {online && (
        <div
          style={{
            position: 'absolute',
            bottom: 1,
            right: 1,
            width: 11,
            height: 11,
            borderRadius: '50%',
            background: AT_GREEN,
            border: '2px solid #fff',
          }}
        />
      )}
    </div>
  )
}

function RoleBadge({ role }) {
  return (
    <span
      style={{
        background: '#e8eef8',
        color: AT_BLUE,
        fontSize: 10,
        fontWeight: 700,
        padding: '3px 8px',
        borderRadius: 6,
        letterSpacing: 0.3,
        textTransform: 'uppercase',
      }}
    >
      {role}
    </span>
  )
}

function initialsFromName(name) {
  if (!name || typeof name !== 'string') return '?'
  const parts = name.split(' ').map(p => p.trim()).filter(Boolean)
  if (parts.length === 0) return '?'
  const a = parts[0]?.[0] ?? ''
  const b = parts.length > 1 ? parts[parts.length - 1]?.[0] ?? '' : ''
  return `${a}${b}`.toUpperCase()
}

function truncate40(s) {
  if (s == null) return ''
  const str = String(s)
  if (str.length <= 40) return str
  return `${str.slice(0, 40)}...`
}

function formatRelative(isoString) {
  if (!isoString) return '—'
  const t = new Date(isoString)
  if (Number.isNaN(t.getTime())) return '—'
  const diffMs = Date.now() - t.getTime()
  const diffMin = Math.floor(diffMs / (1000 * 60))
  if (diffMin < 1) return 'à l’instant'
  if (diffMin < 60) return `il y a ${diffMin} min`
  const diffH = Math.floor(diffMin / 60)
  return `il y a ${diffH} h`
}

function formatTime(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const now = new Date()
  if (d.toDateString() === now.toDateString()) {
    return d.toLocaleTimeString('fr-DZ', { hour: '2-digit', minute: '2-digit' })
  }
  return d.toLocaleDateString('fr-DZ', { day: '2-digit', month: '2-digit' })
}

function getAvatarColor(name = '') {
  const colors = ['green', 'blue', 'amber', 'coral']
  const code = (name && name.length > 0 ? name.charCodeAt(0) : 0) || 0
  return colors[code % colors.length]
}

function parseConversationsPayload(res) {
  const data = res?.data?.data ?? res?.data
  if (Array.isArray(data)) return data
  if (Array.isArray(data?.conversations)) return data.conversations
  if (Array.isArray(data?.data)) return data.data
  return []
}

export default function Messagerie() {
  const [loadingConversations, setLoadingConversations] = useState(true)
  const [errorConversations, setErrorConversations] = useState('')
  const [conversations, setConversations] = useState([])
  const [searchQuery, setSearchQuery] = useState('')
  const [activeTab, setActiveTab] = useState('all') // all | unread

  const [activeConvId, setActiveConvId] = useState(null)
  const activeConversation = useMemo(
    () => conversations.find(c => c.id === activeConvId) ?? null,
    [conversations, activeConvId]
  )

  const [loadingMessages, setLoadingMessages] = useState(false)
  const [errorMessages, setErrorMessages] = useState('')
  const [messages, setMessages] = useState([])

  const [contenu, setContenu] = useState('')

  const [newConvOpen, setNewConvOpen] = useState(false)
  const [userSearch, setUserSearch] = useState('')
  const [contactsResults, setContactsResults] = useState([])
  const [loadingContacts, setLoadingContacts] = useState(false)
  const [startingConv, setStartingConv] = useState(false)
  const searchDebounceRef = useRef(null)

  const messageEndRef = useRef(null)
  const textareaRef = useRef(null)

  const refreshConversationsAndSelect = useCallback(async (otherUserId) => {
    const convRes = await messagesAPI.conversations()
    const arr = parseConversationsPayload(convRes)
    setConversations(arr)
    const found = arr.find((c) => c.interlocuteur?.id === otherUserId)
    if (found) setActiveConvId(found.id)
  }, [])

  const fetchConversations = useCallback(async (options = {}) => {
    const silent = options?.silent === true
    if (!silent) {
      setLoadingConversations(true)
      setErrorConversations('')
    }
    try {
      const res = await messagesAPI.conversations()
      setConversations(parseConversationsPayload(res))
    } catch (err) {
      if (!silent) {
        setConversations([])
        setErrorConversations(
          err?.response?.data?.message || err?.message || 'Erreur chargement des conversations'
        )
      }
    } finally {
      if (!silent) {
        setLoadingConversations(false)
      }
    }
  }, [])

  const fetchMessages = useCallback(async (convId, options = {}) => {
    if (!convId) return
    const silent = options?.silent === true
    if (!silent) {
      setLoadingMessages(true)
      setErrorMessages('')
    }
    try {
      const res = await messagesAPI.messages(convId)
      const data = res.data?.data ?? res.data
      const list = data?.messages ?? []
      setMessages(Array.isArray(list) ? list : [])
    } catch (err) {
      if (!silent) {
        setMessages([])
      }
      setErrorMessages(
        err?.response?.data?.message || err?.message || 'Erreur chargement des messages'
      )
    } finally {
      if (!silent) {
        setLoadingMessages(false)
      }
    }
  }, [])

  useEffect(() => {
    fetchConversations()
  }, [fetchConversations])

  useEffect(() => {
    if (!newConvOpen) return
    if (searchDebounceRef.current) clearTimeout(searchDebounceRef.current)
    searchDebounceRef.current = setTimeout(async () => {
      setLoadingContacts(true)
      try {
        const res = await api.get('/utilisateurs/contacts', {
          params: { search: userSearch.trim() || undefined },
        })
        const raw = res.data?.data?.contacts ?? res.data?.contacts ?? []
        setContactsResults(Array.isArray(raw) ? raw : [])
      } catch {
        setContactsResults([])
        toast.error('Impossible de charger les contacts')
      } finally {
        setLoadingContacts(false)
      }
    }, 350)
    return () => {
      if (searchDebounceRef.current) clearTimeout(searchDebounceRef.current)
    }
  }, [userSearch, newConvOpen])

  const openNewConvModal = () => {
    setUserSearch('')
    setContactsResults([])
    setNewConvOpen(true)
  }

  const startConversationWith = async (userId) => {
    if (!userId || startingConv) return
    setStartingConv(true)
    try {
      await messagesAPI.envoyer({
        receiver_id: userId,
        contenu: 'Bonjour',
        mission_id: null,
      })
      toast.success('Conversation ouverte ✅')
      setNewConvOpen(false)
      setUserSearch('')
      await refreshConversationsAndSelect(userId)
    } catch (err) {
      toast.error(
        err?.response?.data?.message || err?.message || 'Impossible de démarrer la conversation'
      )
    } finally {
      setStartingConv(false)
    }
  }

  // Auto-sélection conversation (pour éviter écran vide côté chat).
  useEffect(() => {
    if (!activeConvId && conversations.length > 0) {
      setActiveConvId(conversations[0].id)
    }
  }, [activeConvId, conversations])

  useEffect(() => {
    if (activeConvId) fetchMessages(activeConvId)
  }, [activeConvId, fetchMessages])

  // Polling (conversations 30s, messages 60s)
  usePolling(async () => {
    await fetchConversations({ silent: true })
  }, 30_000, true)

  usePolling(async () => {
    if (!activeConvId) return
    await fetchMessages(activeConvId, { silent: true })
  }, 60_000, !!activeConvId)

  const sendMessage = async () => {
    const conv = activeConversation
    if (!conv) return
    const txt = contenu.trim()
    if (!txt) return

    // Optimiste : on affiche l’état "envoi" via disable bouton implicitement.
    try {
      await messagesAPI.envoyer({
        receiver_id: conv.interlocuteur?.id,
        contenu: txt,
        mission_id: conv.mission_id ?? null,
      })
      setContenu('')
      toast.success('Message envoyé ✅')
      await fetchMessages(conv.id)
      await fetchConversations()
    } catch (err) {
      toast.error(
        err?.response?.data?.message || err?.message || 'Erreur envoi message'
      )
    }
  }

  const createConversation = useCallback(() => {
    openNewConvModal()
  }, [])

  useEffect(() => {
    if (messageEndRef.current) {
      messageEndRef.current.scrollIntoView({ behavior: 'smooth', block: 'end' })
    }
  }, [messages.length, activeConvId, loadingMessages])

  const filteredConvs = useMemo(() => {
    const q = searchQuery.trim().toLowerCase()
    return conversations.filter((c) => {
      const name = (c.interlocuteur?.name || '').toLowerCase()
      const matchSearch = !q || name.includes(q)
      const nonLus = c.non_lus ?? 0
      const matchTab = activeTab === 'all' || (activeTab === 'unread' && nonLus > 0)
      return matchSearch && matchTab
    })
  }, [conversations, searchQuery, activeTab])

  const handleTextareaInput = (e) => {
    setContenu(e.target.value)
    const ta = textareaRef.current
    if (ta) {
      ta.style.height = 'auto'
      ta.style.height = `${Math.min(ta.scrollHeight, 100)}px`
    }
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }

  const isMyMessage = (msg) => {
    if (typeof msg?.est_moi === 'boolean') return msg.est_moi
    if (typeof msg?.is_mine === 'boolean') return msg.is_mine
    return false
  }

  return (
    <div>
      <PageHeader title="Messagerie" subtitle="Messagerie interne AT" backTo="/" />

      <div style={{ display: 'flex', height: 'calc(70vh)', minHeight: 520, background: '#f0f4f8', overflow: 'hidden', borderRadius: 18 }}>
        {/* PANEL GAUCHE */}
        <motion.div
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ duration: 0.35 }}
          style={{
            width: 320,
            display: 'flex',
            flexDirection: 'column',
            background: '#fff',
            borderRight: '1px solid #e2e8f2',
            flexShrink: 0,
            height: '100%',
            overflow: 'hidden',
          }}
        >
          <div style={{ padding: '20px 20px 16px', borderBottom: '1px solid #f0f4f8' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <span style={{ fontSize: 18, fontWeight: 700, color: AT_BLUE, letterSpacing: '-0.3px' }}>Messagerie</span>
              <motion.button
                whileHover={{ scale: 1.03, y: -1 }}
                whileTap={{ scale: 0.96 }}
                onClick={createConversation}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 6,
                  background: AT_GREEN,
                  color: '#fff',
                  border: 'none',
                  borderRadius: 10,
                  padding: '8px 14px',
                  fontSize: 12,
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                <span style={{ fontSize: 16 }}>+</span> Nouvelle
              </motion.button>
            </div>

            <div style={{ position: 'relative' }}>
              <input
                type="text"
                placeholder="Rechercher..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  width: '100%',
                  background: '#f5f7fa',
                  border: '1.5px solid transparent',
                  borderRadius: 10,
                  padding: '9px 12px',
                  fontSize: 13,
                  color: '#333',
                  outline: 'none',
                  transition: 'border-color 0.2s',
                }}
                onFocus={(e) => (e.target.style.borderColor = AT_GREEN)}
                onBlur={(e) => (e.target.style.borderColor = 'transparent')}
              />
            </div>
          </div>

          <div style={{ display: 'flex', padding: '10px 14px 0', gap: 4 }}>
            {[
              { id: 'all', label: 'Toutes' },
              { id: 'unread', label: 'Non lues' },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                style={{
                  flex: 1,
                  padding: '7px',
                  textAlign: 'center',
                  fontSize: 12,
                  fontWeight: 600,
                  border: 'none',
                  borderRadius: 8,
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                  background: activeTab === tab.id ? '#e8f8f0' : 'none',
                  color: activeTab === tab.id ? AT_GREEN : '#8a93a6',
                }}
              >
                {tab.label}
              </button>
            ))}
          </div>

          <div style={{ flex: 1, overflowY: 'auto', padding: '8px 10px' }}>
            {loadingConversations ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: '12px 8px' }}>
                {[0, 1, 2, 3].map((i) => (
                  <SkeletonCard key={i} />
                ))}
              </div>
            ) : errorConversations ? (
              <div style={{ padding: 14 }}>
                <EmptyState icon={UserRound} title="Erreur" subtitle={errorConversations} actionLabel="Réessayer" onAction={fetchConversations} />
              </div>
            ) : filteredConvs.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 20px', color: '#b0b8c8' }}>
                <div style={{ fontSize: 32, marginBottom: 8 }}>💬</div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#8a93a6' }}>Aucune conversation</div>
              </div>
            ) : (
              <AnimatePresence>
                {filteredConvs.map((conv, i) => {
                  const user = conv.interlocuteur || {}
                  const isActive = activeConversation?.id === conv.id
                  const unread = conv.non_lus ?? 0
                  return (
                    <motion.div
                      key={conv.id}
                      initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: i * 0.04 }}
                      onClick={() => setActiveConvId(conv.id)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 12,
                        padding: '11px 12px',
                        borderRadius: 12,
                        cursor: 'pointer',
                        marginBottom: 2,
                        transition: 'background 0.15s',
                        background: isActive ? '#e8f8f0' : 'transparent',
                        border: isActive ? '1px solid #c3edda' : '1px solid transparent',
                      }}
                    >
                      <Avatar name={user.name || 'UN'} size={42} online={!!user.is_online} color={getAvatarColor(user.name)} />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 600, color: '#1a2240', marginBottom: 2 }}>
                          {user.name || 'Utilisateur'}
                        </div>
                        <div style={{ fontSize: 12, color: isActive ? '#5a9e7a' : '#8a93a6', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                          {truncate40(conv.dernier_message || '—')}
                        </div>
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 5 }}>
                        <span style={{ fontSize: 10, color: '#b0b8c8', fontWeight: 500 }}>
                          {formatTime(conv.dernier_message_at)}
                        </span>
                        {unread > 0 && (
                          <motion.span
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            style={{ background: AT_GREEN, color: '#fff', borderRadius: 10, fontSize: 10, fontWeight: 700, padding: '2px 6px', minWidth: 18, textAlign: 'center' }}
                          >
                            {unread > 99 ? '99+' : unread}
                          </motion.span>
                        )}
                      </div>
                    </motion.div>
                  )
                })}
              </AnimatePresence>
            )}
          </div>
        </motion.div>

        {/* PANEL DROIT */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', height: '100%' }}>
          {!activeConvId ? (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14 }}>
              <div style={{ fontSize: 56, opacity: 0.35 }}>💬</div>
              <div style={{ fontSize: 18, fontWeight: 700, color: '#8a93a6' }}>Messagerie interne AT</div>
              <div style={{ fontSize: 13, color: '#b0b8c8', textAlign: 'center', maxWidth: 280, lineHeight: 1.6 }}>
                Sélectionnez une conversation ou créez-en une nouvelle pour commencer.
              </div>
              <motion.button
                whileHover={{ scale: 1.03 }}
                whileTap={{ scale: 0.97 }}
                onClick={createConversation}
                style={{ marginTop: 8, background: AT_GREEN, color: '#fff', border: 'none', borderRadius: 12, padding: '10px 24px', fontSize: 13, fontWeight: 600, cursor: 'pointer' }}
              >
                + Nouvelle conversation
              </motion.button>
            </motion.div>
          ) : (
            <>
              <motion.div
                initial={{ opacity: 0, y: -8 }}
                animate={{ opacity: 1, y: 0 }}
                style={{ background: '#fff', padding: '14px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid #e8edf4', flexShrink: 0 }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <Avatar name={activeConversation?.interlocuteur?.name || 'UN'} size={40} online={!!activeConversation?.interlocuteur?.is_online} color={getAvatarColor(activeConversation?.interlocuteur?.name)} />
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 15, fontWeight: 700, color: '#1a2240' }}>{activeConversation?.interlocuteur?.name || 'Interlocuteur'}</span>
                      {activeConversation?.interlocuteur?.role && <RoleBadge role={activeConversation.interlocuteur.role} />}
                    </div>
                    <div style={{ fontSize: 12, color: AT_GREEN, fontWeight: 500 }}>
                      {activeConversation?.interlocuteur?.is_online ? '● En ligne' : '○ Hors ligne'}
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 8 }}>
                  <motion.button whileHover={{ scale: 1.08 }} whileTap={{ scale: 0.95 }} onClick={() => setActiveConvId(null)} style={{ width: 36, height: 36, borderRadius: 10, background: '#f5f7fa', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, color: '#6b7894' }}>
                    ←
                  </motion.button>
                </div>
              </motion.div>

              <div style={{ flex: 1, overflowY: 'auto', padding: 24, display: 'flex', flexDirection: 'column', gap: 4 }}>
                {loadingMessages ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: '12px 8px' }}>
                    {[0, 1, 2, 3].map((i) => (
                      <SkeletonLine key={i} />
                    ))}
                  </div>
                ) : errorMessages ? (
                  <EmptyState icon={MessageCircle} title="Erreur messages" subtitle={errorMessages} actionLabel="Réessayer" onAction={() => fetchMessages(activeConvId)} />
                ) : messages.length === 0 ? (
                  <EmptyState icon={MessageCircle} title="Aucun message" subtitle="Commencez la conversation en envoyant un message." />
                ) : (
                  <AnimatePresence>
                    {messages.map((msg, i) => {
                      const mine = isMyMessage(msg)
                      return (
                        <motion.div
                          key={msg.id ?? i}
                          initial={{ opacity: 0, y: 10, scale: 0.97 }}
                          animate={{ opacity: 1, y: 0, scale: 1 }}
                          transition={{ duration: 0.2 }}
                          style={{ display: 'flex', flexDirection: mine ? 'row-reverse' : 'row', gap: 10, marginBottom: 2, alignItems: 'flex-end' }}
                        >
                          {!mine && <div style={{ width: 32, flexShrink: 0 }} />}
                          <div style={{ maxWidth: '68%', display: 'flex', flexDirection: 'column', alignItems: mine ? 'flex-end' : 'flex-start', gap: 2 }}>
                            <div
                              style={{
                                padding: '10px 14px',
                                borderRadius: 16,
                                borderTopRightRadius: mine ? 4 : 16,
                                borderTopLeftRadius: mine ? 16 : 4,
                                fontSize: 13,
                                lineHeight: 1.55,
                                background: mine ? AT_GREEN : '#fff',
                                color: mine ? '#fff' : '#1a2240',
                                border: mine ? 'none' : '1px solid #e8edf4',
                                wordBreak: 'break-word',
                                whiteSpace: 'pre-wrap',
                              }}
                            >
                              {msg.contenu}
                            </div>
                            <span style={{ fontSize: 10, color: '#b0b8c8', padding: '0 2px' }}>{formatTime(msg.created_at)}</span>
                          </div>
                        </motion.div>
                      )
                    })}
                  </AnimatePresence>
                )}
                <div ref={messageEndRef} />
              </div>

              <div style={{ background: '#fff', borderTop: '1px solid #e8edf4', padding: '14px 20px', flexShrink: 0 }}>
                <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10 }}>
                  <div style={{ flex: 1, background: '#f5f7fa', border: '1.5px solid transparent', borderRadius: 14, padding: '10px 14px', display: 'flex', alignItems: 'flex-end', gap: 8 }}>
                    <textarea
                      ref={textareaRef}
                      rows={1}
                      value={contenu}
                      onChange={handleTextareaInput}
                      onKeyDown={handleKeyDown}
                      placeholder="Écrire un message... (Entrée pour envoyer)"
                      style={{ flex: 1, background: 'none', border: 'none', outline: 'none', fontSize: 13, color: '#1a2240', resize: 'none', lineHeight: 1.5, maxHeight: 100, fontFamily: 'inherit' }}
                    />
                  </div>
                  <Button variant="gradient" onClick={sendMessage} disabled={!contenu.trim()} size="md">
                    Envoyer
                  </Button>
                </div>
              </div>
            </>
          )}
        </div>
      </div>

      <Modal
        isOpen={newConvOpen}
        onClose={() => !startingConv && setNewConvOpen(false)}
        title="Nouvelle conversation"
        size="md"
      >
        <div className="space-y-3">
          <Input
            label="Rechercher un collègue"
            value={userSearch}
            onChange={(e) => setUserSearch(e.target.value)}
            placeholder="Nom, prénom, e-mail…"
          />
          {loadingContacts && (
            <div className="text-xs text-[#9AA0AE]">Recherche…</div>
          )}
          {!loadingContacts && contactsResults.length === 0 && (
            <div className="text-sm text-[#9AA0AE] py-2">
              {userSearch.trim() ? 'Aucun résultat' : 'Saisissez un nom ou parcourez la liste.'}
            </div>
          )}
          {!loadingContacts && contactsResults.length > 0 && (
            <ul className="max-h-[280px] overflow-y-auto space-y-1 border border-[#EAECF0] rounded-xl p-2 dark:border-[#2A2D3E]">
              {contactsResults.map((u) => (
                <li key={u.id}>
                  <button
                    type="button"
                    disabled={startingConv}
                    onClick={() => startConversationWith(u.id)}
                    className="w-full text-left rounded-lg px-3 py-2.5 text-sm hover:bg-[#F0FDF4] dark:hover:bg-[#252840] disabled:opacity-50"
                  >
                    <div className="font-semibold text-[#1A1D26] dark:text-[#E8EAF0]">
                      {(u.nom_complet && String(u.nom_complet).trim())
                        || `${u.prenom ?? ''} ${u.nom ?? ''}`.trim()
                        || 'Utilisateur'}
                    </div>
                    {u.email && (
                      <div className="text-xs text-[#9AA0AE] truncate">{u.email}</div>
                    )}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Modal>
    </div>
  )
}
