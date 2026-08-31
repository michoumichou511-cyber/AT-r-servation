import Button from './Button';

export default function EmptyState({
  icon: Icon,
  title = 'Aucun résultat',
  subtitle = 'Il n\'y a rien à afficher pour le moment.',
  actionLabel,
  onAction,
}) {
  return (
    <div className="flex flex-col items-center justify-center py-20 px-4 text-center">
      {Icon && (
        <div className="relative mb-6">
          <div className="absolute inset-0 rounded-[22px] bg-at-green/10 blur-xl scale-150" />
          <div
            className="relative w-[72px] h-[72px] rounded-[22px] bg-gradient-to-br from-at-green-light to-white dark:from-[#00A650]/15 dark:to-[#1A1D2E] flex items-center justify-center border border-at-green/10"
            style={{ animation: 'emptyFloat 4s ease-in-out infinite' }}
          >
            <Icon size={32} className="text-at-green" />
          </div>
        </div>
      )}
      <h3 className="text-lg font-bold text-[#1A1D26] dark:text-[#E8EAF0]">
        {title}
      </h3>
      <p className="text-sm text-[#5A6070] dark:text-[#9AA0AE] mt-2 max-w-sm leading-relaxed">{subtitle}</p>
      {actionLabel && onAction && (
        <div className="mt-6">
          <Button onClick={onAction} variant="gradient" size="md">{actionLabel}</Button>
        </div>
      )}
      <style>{`
        @keyframes emptyFloat {
          0%, 100% { transform: translateY(0px) rotate(0deg); }
          25%      { transform: translateY(-6px) rotate(-1deg); }
          75%      { transform: translateY(-3px) rotate(1deg); }
        }
      `}</style>
    </div>
  );
}
