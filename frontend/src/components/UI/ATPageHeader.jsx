import { motion } from 'framer-motion'

/**
 * En-tête de page aligné sur le Dashboard : titre dégradé AT + sous-titre + slot droit.
 */
export default function ATPageHeader({
  title,
  subtitle,
  emoji = null,
  right = null,
  className = '',
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: -12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, ease: [0.25, 0.1, 0.25, 1] }}
      className={`mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between ${className}`}
    >
      <div>
        <h1 className="at-gradient-title m-0 text-2xl font-bold tracking-tight sm:text-[28px] leading-tight">
          {title}
          {emoji ? (
            <span className="ml-1.5 inline-block" aria-hidden>
              {emoji}
            </span>
          ) : null}
        </h1>
        {subtitle ? (
          <p className="mt-1.5 text-[13px] text-[#5A6070] dark:text-[#9AA0AE] font-medium">
            {subtitle}
          </p>
        ) : null}
      </div>
      {right ? <div className="flex shrink-0 flex-wrap items-center gap-2">{right}</div> : null}
    </motion.div>
  )
}
