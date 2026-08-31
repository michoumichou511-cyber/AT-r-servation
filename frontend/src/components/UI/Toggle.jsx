export default function Toggle({ checked, onChange, label, disabled = false }) {
  return (
    <label className={`inline-flex items-center gap-2.5 cursor-pointer select-none ${
      disabled ? 'opacity-50 cursor-not-allowed' : ''
    }`}>
      <div
        onClick={() => !disabled && onChange(!checked)}
        className={`relative rounded-full transition-all duration-300 ${
          checked ? 'bg-gradient-to-r from-[#00A650] to-[#00C060] shadow-sm shadow-[#00A650]/30' : 'bg-[#EAECF0] dark:bg-[#2A2D3E]'
        }`}
        style={{ height: '24px', width: '44px' }}
      >
        <span
          className={`absolute top-[3px] w-[18px] h-[18px] bg-white rounded-full shadow-sm transition-all duration-300 ${
            checked ? 'translate-x-[23px]' : 'translate-x-[3px]'
          }`}
        />
      </div>
      {label && (
        <span className="text-sm font-medium text-[#1A1D26] dark:text-[#E5E7EB]">{label}</span>
      )}
    </label>
  );
}
