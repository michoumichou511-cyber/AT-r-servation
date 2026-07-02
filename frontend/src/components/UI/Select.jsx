import { useState, useId } from 'react';
import { ChevronDown } from 'lucide-react';

/**
 * Select stylé — même design que Input (label flottant, focus ring vert AT).
 * Utilise un <select> natif pour l'accessibilité et le clavier.
 */
export default function Select({
  label,
  value,
  onChange,
  options = [],
  error = false,
  errorMessage,
  icon: Icon,
  className = '',
  required,
  disabled,
  id: idProp,
  placeholder = 'Sélectionner…',
  onFocus: onFocusProp,
  onBlur: onBlurProp,
  ...props
}) {
  const generatedId = useId();
  const selectId = idProp ?? generatedId;
  const errorId = `${selectId}-error`;
  const [focused, setFocused] = useState(false);
  const hasValue = value !== '' && value !== undefined && value !== null;
  const floatLabel = focused || hasValue;

  return (
    <div className={`relative ${className}`}>
      <div className="relative">
        {Icon && (
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none z-10" aria-hidden>
            <Icon size={16} />
          </div>
        )}
        <select
          id={selectId}
          value={value}
          onChange={onChange}
          disabled={disabled}
          onFocus={(e) => { setFocused(true); onFocusProp?.(e); }}
          onBlur={(e) => { setFocused(false); onBlurProp?.(e); }}
          aria-invalid={error ? 'true' : undefined}
          aria-describedby={errorMessage ? errorId : undefined}
          className={[
            'w-full px-3 pt-5 pb-2 rounded-lg border text-sm bg-white appearance-none cursor-pointer',
            'transition-all duration-200 outline-none',
            'focus-visible:ring-2 focus-visible:ring-at-green/35 focus-visible:ring-offset-2 dark:focus-visible:ring-offset-gray-900',
            'dark:bg-gray-800',
            /* Sans valeur : le placeholder reste invisible tant que le label est posé dessus
               (sinon les deux textes se chevauchent) — il apparaît en gris au focus. */
            hasValue
              ? 'text-gray-800 dark:text-white'
              : focused
              ? 'text-gray-400'
              : 'text-transparent',
            Icon ? 'pl-9' : '',
            error
              ? 'border-red-400 focus:border-red-500 focus:ring-1 focus:ring-red-400'
              : 'border-gray-200 focus:border-at-green focus:ring-1 focus:ring-at-green/30',
            disabled ? 'bg-gray-50 cursor-not-allowed opacity-70' : '',
          ].join(' ')}
          {...props}
        >
          <option value="" disabled hidden>
            {placeholder}
          </option>
          {options.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>

        {label && (
          <label
            htmlFor={selectId}
            className={[
              'absolute transition-all duration-200 pointer-events-none',
              Icon ? 'left-9' : 'left-3',
              floatLabel
                ? 'top-1.5 text-[10px] font-semibold'
                : 'top-1/2 -translate-y-1/2 text-sm text-gray-400',
              error
                ? (floatLabel ? 'text-red-500' : 'text-gray-400')
                : (floatLabel ? 'text-at-green' : 'text-gray-400'),
            ].join(' ')}
          >
            {label}{required && ' *'}
          </label>
        )}

        <ChevronDown
          size={16}
          className={`absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none transition-transform duration-200 ${
            focused ? 'rotate-180 text-at-green' : 'text-gray-400'
          }`}
          aria-hidden
        />
      </div>

      {errorMessage && (
        <p id={errorId} role="status" aria-live="polite" className="mt-1 text-xs text-red-500">
          {errorMessage}
        </p>
      )}
    </div>
  );
}
