import { useMemo } from 'react'
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from 'lucide-react'

const PER_PAGE_OPTIONS = [10, 15, 25, 50]

function getVisiblePages(current, total) {
  const maxVisible = 5
  if (total <= maxVisible) {
    return Array.from({ length: total }, (_, i) => i + 1)
  }

  const pages = []
  let start = Math.max(1, current - 2)
  let end = Math.min(total, start + maxVisible - 1)

  if (end - start < maxVisible - 1) {
    start = Math.max(1, end - maxVisible + 1)
  }

  if (start > 1) {
    pages.push(1)
    if (start > 2) pages.push('...')
  }

  for (let i = start; i <= end; i++) {
    if (!pages.includes(i)) pages.push(i)
  }

  if (end < total) {
    if (end < total - 1) pages.push('...')
    pages.push(total)
  }

  return pages
}

export default function Pagination({
  currentPage = 1,
  totalPages = 1,
  totalItems = 0,
  perPage = 10,
  onPageChange,
  onPerPageChange,
  className = '',
}) {
  const visiblePages = useMemo(
    () => getVisiblePages(currentPage, totalPages),
    [currentPage, totalPages]
  )

  const startItem = totalItems === 0 ? 0 : (currentPage - 1) * perPage + 1
  const endItem = Math.min(currentPage * perPage, totalItems)

  if (totalItems <= 0) return null

  return (
    <div
      className={`at-card-surface p-3 flex flex-col sm:flex-row items-center justify-between gap-3 ${className}`}
    >
      <div className="flex items-center gap-3">
        <span className="text-[13px] font-medium text-[#5A6070] dark:text-[#9AA0AE]">
          <span className="at-number">{startItem}</span>-<span className="at-number">{endItem}</span> sur <span className="at-number">{totalItems}</span>
        </span>
        {onPerPageChange && (
          <select
            value={perPage}
            onChange={(e) => onPerPageChange(Number(e.target.value))}
            className="rounded-xl border border-[#EAECF0] dark:border-[#2A2D3E] bg-white dark:bg-[#1E2235] px-2.5 py-1.5 text-xs font-medium text-[#5A6070] dark:text-[#9AA0AE] focus:outline-none focus:ring-2 focus:ring-[#00A650]/20 transition-all"
          >
            {PER_PAGE_OPTIONS.map((n) => (
              <option key={n} value={n}>
                {n} / page
              </option>
            ))}
          </select>
        )}
      </div>

      <div className="flex items-center gap-1">
        <button
          type="button"
          onClick={() => onPageChange(1)}
          disabled={currentPage <= 1}
          className="hidden sm:inline-flex items-center justify-center w-9 h-9 rounded-xl text-[#5A6070] dark:text-[#9AA0AE] hover:bg-[#F4F6FA] dark:hover:bg-[#252840] disabled:opacity-30 disabled:cursor-not-allowed transition-all duration-200"
          aria-label="Premiere page"
        >
          <ChevronsLeft size={16} />
        </button>
        <button
          type="button"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
          className="inline-flex items-center justify-center w-9 h-9 rounded-xl text-[#5A6070] dark:text-[#9AA0AE] hover:bg-[#F4F6FA] dark:hover:bg-[#252840] disabled:opacity-30 disabled:cursor-not-allowed transition-all duration-200"
          aria-label="Page precedente"
        >
          <ChevronLeft size={16} />
        </button>

        <div className="hidden sm:flex items-center gap-1">
          {visiblePages.map((p, i) =>
            p === '...' ? (
              <span
                key={`ellipsis-${i}`}
                className="w-9 h-9 flex items-center justify-center text-xs text-[#9AA0AE]"
              >
                ...
              </span>
            ) : (
              <button
                key={p}
                type="button"
                onClick={() => onPageChange(p)}
                className={`w-9 h-9 rounded-xl text-xs font-semibold transition-all duration-200 ${
                  p === currentPage
                    ? 'bg-gradient-to-br from-[#003DA5] to-[#00A650] text-white shadow-sm'
                    : 'text-[#5A6070] dark:text-[#9AA0AE] hover:bg-[#F4F6FA] dark:hover:bg-[#252840]'
                }`}
              >
                {p}
              </button>
            )
          )}
        </div>

        <span className="sm:hidden text-xs font-medium text-[#5A6070] dark:text-[#9AA0AE] px-2">
          {currentPage} / {totalPages}
        </span>

        <button
          type="button"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
          className="inline-flex items-center justify-center w-9 h-9 rounded-xl text-[#5A6070] dark:text-[#9AA0AE] hover:bg-[#F4F6FA] dark:hover:bg-[#252840] disabled:opacity-30 disabled:cursor-not-allowed transition-all duration-200"
          aria-label="Page suivante"
        >
          <ChevronRight size={16} />
        </button>
        <button
          type="button"
          onClick={() => onPageChange(totalPages)}
          disabled={currentPage >= totalPages}
          className="hidden sm:inline-flex items-center justify-center w-9 h-9 rounded-xl text-[#5A6070] dark:text-[#9AA0AE] hover:bg-[#F4F6FA] dark:hover:bg-[#252840] disabled:opacity-30 disabled:cursor-not-allowed transition-all duration-200"
          aria-label="Derniere page"
        >
          <ChevronsRight size={16} />
        </button>
      </div>
    </div>
  )
}
