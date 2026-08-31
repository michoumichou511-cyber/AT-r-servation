import { Check } from 'lucide-react';

/**
 * Stepper — les étapes déjà complétées sont cliquables (retour arrière)
 * si onStepClick est fourni.
 */
export default function Stepper({ steps, currentStep, onStepClick }) {
  return (
    <div className="flex items-center w-full">
      {steps.map((step, index) => {
        const isDone   = index < currentStep;
        const isActive = index === currentStep;
        const clickable = isDone && typeof onStepClick === 'function';

        return (
          <div key={index} className="flex items-center flex-1 last:flex-none">
            {/* Cercle */}
            <button
              type="button"
              onClick={clickable ? () => onStepClick(index) : undefined}
              disabled={!clickable}
              className={`flex flex-col items-center bg-transparent border-0 p-0 ${
                clickable ? 'cursor-pointer group' : 'cursor-default'
              }`}
              aria-label={clickable ? `Revenir à l'étape ${index + 1} : ${step}` : undefined}
            >
              <div
                className={[
                  'w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold',
                  'transition-all duration-300 will-change-transform',
                  clickable ? 'group-hover:scale-110 group-hover:shadow-at-glow-green' : '',
                  isDone
                    ? 'bg-gradient-to-br from-[#00A650] to-[#008040] text-white shadow-sm'
                    : isActive
                    ? 'bg-gradient-to-br from-[#003DA5] to-[#0055D4] text-white ring-4 ring-at-blue/20'
                    : 'bg-[#EAECF0] text-[#9AA0AE] dark:bg-[#2A2D3E] dark:text-[#5A6070]',
                ].join(' ')}
              >
                {isDone ? <Check size={16} strokeWidth={3} /> : <span>{index + 1}</span>}
              </div>
              <span
                className={`mt-1.5 text-[11px] font-semibold whitespace-nowrap transition-colors duration-200 ${
                  isActive ? 'text-at-blue' : isDone ? 'text-at-green' : 'text-[#9AA0AE]'
                } ${clickable ? 'group-hover:underline' : ''}`}
              >
                {step}
              </span>
            </button>

            {/* Ligne de connexion */}
            {index < steps.length - 1 && (
              <div className="flex-1 mx-3 mb-5 relative">
                <div className="h-[3px] rounded-full bg-[#EAECF0] dark:bg-[#2A2D3E]" />
                <div
                  className={`absolute inset-0 h-[3px] rounded-full transition-all duration-500 ease-at-smooth ${
                    isDone ? 'bg-gradient-to-r from-[#00A650] to-[#00C060]' : 'w-0'
                  }`}
                />
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
