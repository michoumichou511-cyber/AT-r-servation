import { motion } from 'framer-motion'
import { Loader2 } from 'lucide-react'

const variants = {
  gradient:
    'bg-gradient-to-br from-[#003DA5] to-[#00A650] text-white shadow-sm hover:shadow-at-glow-green hover:-translate-y-0.5',
  primary:   'bg-at-green hover:bg-at-green-dark text-white shadow-sm hover:shadow-at-glow-green',
  secondary: 'bg-at-blue hover:bg-at-blue-dark text-white shadow-sm hover:shadow-at-glow-blue',
  danger:    'bg-red-500 hover:bg-red-600 text-white shadow-sm hover:shadow-[0_4px_16px_rgba(239,68,68,0.3)]',
  outline:   'border-2 border-[#00A650] text-[#00A650] bg-transparent hover:bg-[#E6F7EE] dark:hover:bg-[#00A650]/15',
  ghost:     'text-[#5A6070] hover:bg-[#F4F6FA] dark:text-[#9AA0AE] dark:hover:bg-[#252840]',
  loading:   'bg-at-green/70 text-white cursor-not-allowed',
};

const sizes = {
  sm: 'text-xs px-3.5 py-1.5 gap-1.5',
  md: 'text-sm px-5 py-2.5 gap-2',
  lg: 'text-base px-6 py-3 gap-2.5',
};

export default function Button({
  children,
  variant = 'primary',
  size = 'md',
  fullWidth = false,
  disabled = false,
  loading = false,
  onClick,
  type = 'button',
  className = '',
  ...props
}) {
  const isDisabled = disabled || loading;

  const Btn = motion.button

  return (
    <Btn
      type={type}
      onClick={onClick}
      disabled={isDisabled}
      whileTap={isDisabled ? undefined : { scale: 0.95 }}
      whileHover={isDisabled ? undefined : { scale: 1.02 }}
      transition={{ duration: 0.2 }}
      className={[
        'inline-flex items-center justify-center font-medium rounded-xl',
        'transition-all duration-150 select-none',
        'focus:outline-none focus-visible:ring-2 focus-visible:ring-[#003DA5] focus-visible:ring-offset-2',
        'dark:focus-visible:ring-offset-gray-900',
        variants[loading ? 'loading' : variant],
        sizes[size],
        fullWidth ? 'w-full' : '',
        isDisabled ? 'opacity-60 cursor-not-allowed' : '',
        className,
      ].join(' ')}
      {...props}
    >
      {loading && <Loader2 size={size === 'sm' ? 14 : 16} className="animate-spin" />}
      {children}
    </Btn>
  )
}
