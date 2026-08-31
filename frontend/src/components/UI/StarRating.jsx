import { useState } from 'react';
import { Star } from 'lucide-react';

export default function StarRating({ value = 0, onChange, readonly = false, size = 20 }) {
  const [hovered, setHovered] = useState(0);
  const display = hovered || value;

  return (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map(star => (
        <button
          key={star}
          type="button"
          disabled={readonly}
          onClick={() => !readonly && onChange?.(star)}
          onMouseEnter={() => !readonly && setHovered(star)}
          onMouseLeave={() => !readonly && setHovered(0)}
          className={[
            'transition-all duration-200',
            !readonly ? 'hover:scale-125 active:scale-90 cursor-pointer' : 'cursor-default',
          ].join(' ')}
          style={{ filter: star <= display ? 'drop-shadow(0 1px 2px rgba(245, 158, 11, 0.4))' : 'none' }}
        >
          <Star
            size={size}
            className="transition-colors duration-200"
            fill={star <= display ? '#F59E0B' : 'transparent'}
            stroke={star <= display ? '#F59E0B' : '#EAECF0'}
            strokeWidth={star <= display ? 2 : 1.5}
          />
        </button>
      ))}
    </div>
  );
}
