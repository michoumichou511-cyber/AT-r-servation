export function SkeletonLine({ width = 'w-full', height = 'h-4', className = '' }) {
  return (
    <div
      className={`${width} ${height} rounded-lg animate-shimmer ${className}`}
    />
  );
}

export function SkeletonCard({ className = '' }) {
  return (
    <div className={`at-card-surface p-5 space-y-3.5 ${className}`}>
      <div className="flex items-center gap-3.5">
        <div className="w-11 h-11 rounded-xl animate-shimmer" />
        <div className="flex-1 space-y-2.5">
          <SkeletonLine width="w-3/4" height="h-3.5" />
          <SkeletonLine width="w-1/2" height="h-3" />
        </div>
      </div>
      <SkeletonLine />
      <SkeletonLine width="w-4/5" />
      <SkeletonLine width="w-2/3" />
    </div>
  );
}

export default function Skeleton({ count = 3, card = false }) {
  return (
    <div className="space-y-3">
      {Array.from({ length: count }).map((_, i) =>
        card
          ? <SkeletonCard key={i} style={{ animationDelay: `${i * 0.1}s` }} />
          : <SkeletonLine key={i} />
      )}
      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
        .animate-shimmer {
          animation: shimmer 1.8s infinite ease-in-out;
          background: linear-gradient(90deg, #EAECF0 25%, #F4F6FA 50%, #EAECF0 75%);
          background-size: 200% 100%;
        }
        .dark .animate-shimmer {
          background: linear-gradient(90deg, #252840 25%, #2A2D3E 50%, #252840 75%);
          background-size: 200% 100%;
        }
      `}</style>
    </div>
  );
}
