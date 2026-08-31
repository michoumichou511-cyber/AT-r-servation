export default function Loader({ fullPage = false, size = 'md' }) {
  const sizeClasses = {
    sm: 'w-5 h-5 border-2',
    md: 'w-9 h-9 border-[3px]',
    lg: 'w-12 h-12 border-4',
  };

  const spinner = (
    <div
      className={`${sizeClasses[size]} border-[#00A650]/15 border-t-[#00A650] rounded-full animate-spin`}
    />
  );

  if (fullPage) {
    return (
      <div className="fixed inset-0 flex flex-col items-center justify-center
                      bg-white/85 dark:bg-[#0b1220]/85 backdrop-blur-md z-50 gap-4">
        {spinner}
        <span className="text-sm font-medium text-[#5A6070] dark:text-[#9AA0AE]">Chargement...</span>
      </div>
    );
  }

  return (
    <div className="flex items-center justify-center p-8">
      {spinner}
    </div>
  );
}
