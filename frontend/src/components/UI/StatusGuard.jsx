import { AlertTriangle, RotateCcw } from 'lucide-react'
import { SkeletonCard } from './Skeleton'
import { Button } from './index'

export default function StatusGuard({ loading, error, onRetry, skeletonCount = 3, children }) {
  if (loading) {
    return (
      <div className="space-y-4">
        {Array.from({ length: skeletonCount }, (_, i) => (
          <SkeletonCard key={i} />
        ))}
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <AlertTriangle size={40} className="text-red-400" />
        <p className="text-red-600 dark:text-red-400 text-sm text-center max-w-md">{error}</p>
        {onRetry && (
          <Button variant="outline" onClick={onRetry} className="gap-2">
            <RotateCcw size={14} /> Réessayer
          </Button>
        )}
      </div>
    )
  }

  return children
}
