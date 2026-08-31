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
          <div className={`absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none z-10 transition-colors duration-200 ${focused ? 'text-[#00A650]' : 'text-[#9AA0AE]'}`} aria-hidden>
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
          /* data-empty : neutralise le `.dark select { color: !important }` global
             qui rendait le placeholder visible sous le label flottant en mode sombre */
          data-empty={!hasValue && !focused ? 'true' : 'false'}
          className={[
            'w-full px-3 pt-5 pb-2 rounded-xl border-2 text-sm bg-white appearance-none cursor-pointer',
            'transition-all duration-200 outline-none',
            'focus-visible:ring-2 focus-visible:ring-at-green/30 focus-visible:ring-offset-2 dark:focus-visible:ring-offset-[#141727]',
            'dark:bg-[#1E2235]',
            hasValue
              ? 'text-[#1A1D26] dark:text-white'
              : focused
              ? 'text-[#9AA0AE]'
              : 'text-transparent',
            Icon ? 'pl-9' : '',
            error
              ? 'border-red-400 focus:border-red-500'
              : 'border-[#EAECF0] dark:border-[#2A2D3E] focus:border-[#00A650]',
            disabled ? 'bg-[#F8FAFB] dark:bg-[#252840] cursor-not-allowed opacity-70' : '',
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
                ? 'top-1.5 text-[10px] font-semibold tracking-wide'
                : 'top-1/2 -translate-y-1/2 text-sm text-[#9AA0AE]',
              error
                ? (floatLabel ? 'text-red-500' : 'text-[#9AA0AE]')
                : (floatLabel ? 'text-[#00A650]' : 'text-[#9AA0AE]'),
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
