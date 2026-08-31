import { useCallback, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { Stepper } from '../../../components/UI'
import PageHeader from '../../../components/Common/PageHeader'
import Step1Informations, { clearMissionDraft } from './Step1Informations'
import Step2Reservations from './Step2Reservations'
import Step3Documents from './Step3Documents'
import Step4Recap from './Step4Recap'
import toast from 'react-hot-toast'
import { missionsAPI } from '../../../services/api'

const STEPS = ['Informations', 'Réservations', 'Documents', 'Récapitulatif'];

/** Transition fluide GPU-only (opacity + transform) pour 60 FPS. */
const stepTransition = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -8 },
  transition: { duration: 0.22, ease: [0.25, 0.1, 0.25, 1] },
}

export default function NewMissionWizard() {
  const [currentStep, setCurrentStep] = useState(0)
  const [missionId, setMissionId] = useState(null)
  const [missionDraft, setMissionDraft] = useState({})
  const [step1Loading, setStep1Loading] = useState(false)
  const [step1Error, setStep1Error] = useState('')
  const creatingRef = useRef(false)

  const next = useCallback(() => {
    setCurrentStep((s) => Math.min(s + 1, STEPS.length - 1))
  }, [])

  const prev = useCallback(() => {
    setCurrentStep((s) => Math.max(s - 1, 0))
  }, [])

  // Retour direct à une étape déjà complétée via le Stepper
  const goToStep = useCallback((index) => {
    setCurrentStep((s) => (index < s ? index : s))
  }, [])

  const onSubmitStep1 = useCallback(
    async (payload) => {
      setStep1Loading(true)
      setStep1Error('')
      try {
        const cleaned = { ...payload }
        if (cleaned.budget_previsionnel === '') delete cleaned.budget_previsionnel
        if (cleaned.priorite === '') delete cleaned.priorite

        if (!missionId) {
          if (creatingRef.current) return
          creatingRef.current = true
          const res = await missionsAPI.create(cleaned)
          const data = res?.data?.data ?? res?.data ?? null
          const id = data?.id ?? data?.mission?.id ?? null
          if (!id) throw new Error("ID mission introuvable après création")

          setMissionId(id)
          setMissionDraft((d) => ({ ...d, ...cleaned }))
          clearMissionDraft()
          next()
          return
        }

        const res = await missionsAPI.update(missionId, cleaned)
        const data = res?.data?.data ?? res?.data ?? null
        if (!data) throw new Error('Réponse invalide lors de la mise à jour de la mission')

        setMissionDraft((d) => ({ ...d, ...cleaned }))
        next()
      } catch (err) {
        const msg =
          err?.response?.data?.message ||
          err?.response?.data?.error ||
          err?.message ||
          "Impossible d'enregistrer les informations"
        setStep1Error(msg)
        toast.error(msg)
      } finally {
        setStep1Loading(false)
      }
    },
    [missionId, next]
  )

  return (
    <div>
      <PageHeader
        title="Nouvelle mission"
        subtitle="Créez un ordre de mission en 4 étapes"
        backTo="/missions"
      />

      <div className="at-card-surface mb-6 rounded-xl p-6">
        <Stepper steps={STEPS} currentStep={currentStep} onStepClick={goToStep} />
      </div>

      <div className="at-card-surface rounded-xl p-6">
        <AnimatePresence initial={false} mode="wait">
          <motion.div key={`step-${currentStep}`} {...stepTransition}>
            {currentStep === 0 && (
              <Step1Informations
                data={missionDraft}
                missionId={missionId}
                onNext={onSubmitStep1}
                loading={step1Loading}
                error={step1Error}
              />
            )}
            {currentStep === 1 && (
              <Step2Reservations missionId={missionId} transportType={missionDraft.transport_type} destinationVille={missionDraft.destination_ville} onNext={next} onPrev={prev} />
            )}
            {currentStep === 2 && (
              <Step3Documents missionId={missionId} onNext={next} onPrev={prev} />
            )}
            {currentStep === 3 && (
              <Step4Recap missionId={missionId} onPrev={prev} onEditStep={goToStep} />
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  )
}
