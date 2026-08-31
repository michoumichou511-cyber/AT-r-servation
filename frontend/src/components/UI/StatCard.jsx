import { TrendingUp, TrendingDown } from 'lucide-react';

export default function StatCard({
  icon: Icon,
  label,
  value,
  delta,
  deltaLabel,
  color = 'green',
  className = '',
}) {
  const colors = {
    green: {
      bg:   'bg-at-green-light',
      icon: 'text-at-green',
      ring: 'ring-at-green/20',
      hover: 'group-hover:shadow-at-glow-green',
    },
    blue: {
      bg:   'bg-at-blue-light',
      icon: 'text-at-blue',
      ring: 'ring-at-blue/20',
      hover: 'group-hover:shadow-at-glow-blue',
    },
    orange: {
      bg:   'bg-orange-50',
      icon: 'text-orange-500',
      ring: 'ring-orange-200',
      hover: '',
    },
    red: {
      bg:   'bg-red-50',
      icon: 'text-red-500',
      ring: 'ring-red-200',
      hover: '',
    },
  };

  const c = colors[color] ?? colors.green;
  const isPositive = delta > 0;

  return (
    <div
      className={[
        'group bg-white dark:bg-[#1A1D2E] rounded-[18px] p-5 shadow-at-soft',
        'border border-[#EAECF0] dark:border-[#2A2D3E]',
        'transition-all duration-300 ease-at-smooth',
        'hover:-translate-y-1 hover:shadow-at-card cursor-default',
        c.hover,
        className,
      ].join(' ')}
    >
      <div className="flex items-start justify-between gap-3">
        <div className={`p-2.5 rounded-xl ${c.bg} ring-1 ${c.ring} transition-transform duration-300 group-hover:scale-110`}>
          {Icon && <Icon size={20} className={c.icon} />}
        </div>
        {delta !== undefined && (
          <span className={`flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${
            isPositive
              ? 'text-at-green bg-at-green-light'
              : 'text-red-500 bg-red-50 dark:bg-red-500/10'
          }`}>
            {isPositive
              ? <TrendingUp size={12} />
              : <TrendingDown size={12} />
            }
            {Math.abs(delta)}%
          </span>
        )}
      </div>
      <div className="mt-4">
        <p className="at-number text-[28px] leading-tight text-[#1A1D26] dark:text-white">
          {value ?? '—'}
        </p>
        <p className="text-[13px] text-[#5A6070] dark:text-[#9AA0AE] mt-1 font-medium">{label}</p>
        {deltaLabel && (
          <p className="text-xs text-[#9AA0AE] mt-1.5">{deltaLabel}</p>
        )}
      </div>
    </div>
  );
}
