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
                  'w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold',
                  'transition-all duration-300 will-change-transform',
                  clickable ? 'group-hover:scale-110 group-hover:shadow-lg group-hover:shadow-at-green/30' : '',
                  isDone
                    ? 'bg-at-green text-white'
                    : isActive
                    ? 'bg-at-blue text-white ring-4 ring-at-blue/20 animate-pulse'
                    : 'bg-gray-200 text-gray-500 dark:bg-gray-600',
                ].join(' ')}
              >
                {isDone ? <Check size={16} /> : <span>{index + 1}</span>}
              </div>
              <span
                className={`mt-1 text-[10px] font-medium whitespace-nowrap transition-colors duration-200 ${
                  isActive ? 'text-at-blue' : isDone ? 'text-at-green' : 'text-gray-400'
                } ${clickable ? 'group-hover:underline' : ''}`}
              >
                {step}
              </span>
            </button>

            {/* Ligne de connexion */}
            {index < steps.length - 1 && (
              <div className={`flex-1 h-0.5 mx-2 mb-4 transition-all duration-300 ${
                isDone ? 'bg-at-green' : 'bg-gray-200 dark:bg-gray-600'
              }`} />
            )}
          </div>
        );
      })}
    </div>
  );
}
