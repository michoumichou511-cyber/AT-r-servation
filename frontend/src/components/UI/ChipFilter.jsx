export default function ChipFilter({ options = [], value, onChange, className = '' }) {
  return (
    <div className={`flex flex-wrap gap-2 ${className}`}>
      {options.map(opt => {
        const val   = typeof opt === 'object' ? opt.value : opt;
        const label = typeof opt === 'object' ? opt.label : opt;
        const active = value === val;

        return (
          <button
            key={val}
            type="button"
            onClick={() => onChange(active ? '' : val)}
            className={[
              'px-3.5 py-1.5 rounded-xl text-xs font-semibold border transition-all duration-200',
              'focus:outline-none focus-visible:ring-2 focus-visible:ring-at-green/30',
              active
                ? 'bg-gradient-to-br from-[#003DA5] to-[#00A650] text-white border-transparent shadow-sm'
                : 'bg-white dark:bg-[#1E2235] text-[#5A6070] dark:text-[#9AA0AE] border-[#EAECF0] dark:border-[#2A2D3E] hover:border-at-green hover:text-at-green',
            ].join(' ')}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}
