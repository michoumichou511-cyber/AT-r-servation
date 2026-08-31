import { useRef, useState } from 'react';
import { UploadCloud, File as FileIcon, X } from 'lucide-react';

function formatBytes(bytes) {
  if (!bytes && bytes !== 0) return '';
  if (bytes < 1024) return `${bytes} o`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} Ko`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} Mo`;
}

/**
 * Zone de dépôt de fichier : drag & drop + clic pour parcourir.
 * Remplace visuellement <input type="file"> (l'input reste présent, caché, pour l'accessibilité).
 */
export default function FileDropZone({
  file,
  onSelect,
  accept,
  disabled = false,
  maxBytes,
  label = 'Glissez un fichier ici ou cliquez pour parcourir',
}) {
  const inputRef = useRef(null);
  const [dragOver, setDragOver] = useState(false);

  const pick = (f) => {
    if (!f) return;
    if (maxBytes && f.size > maxBytes) {
      onSelect(null, `Fichier trop volumineux (max ${formatBytes(maxBytes)})`);
      return;
    }
    onSelect(f, null);
  };

  const onDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    if (disabled) return;
    pick(e.dataTransfer.files?.[0] ?? null);
  };

  return (
    <div>
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        disabled={disabled}
        onChange={(e) => { pick(e.target.files?.[0] ?? null); e.target.value = ''; }}
        className="sr-only"
        aria-hidden
        tabIndex={-1}
      />

      {!file ? (
        <button
          type="button"
          disabled={disabled}
          onClick={() => inputRef.current?.click()}
          onDragOver={(e) => { e.preventDefault(); if (!disabled) setDragOver(true); }}
          onDragLeave={() => setDragOver(false)}
          onDrop={onDrop}
          className={[
            'w-full flex flex-col items-center justify-center gap-3 px-5 py-8',
            'rounded-[18px] border-2 border-dashed cursor-pointer select-none',
            'transition-all duration-300 will-change-transform',
            dragOver
              ? 'border-[#00A650] bg-[#00A650]/5 scale-[1.02] shadow-at-glow-green'
              : 'border-[#EAECF0] dark:border-[#2A2D3E] hover:border-[#00A650]/50 hover:bg-[#00A650]/[0.03]',
            disabled ? 'opacity-50 cursor-not-allowed' : '',
          ].join(' ')}
        >
          <div className={`p-3 rounded-xl transition-all duration-300 ${dragOver ? 'bg-[#00A650]/10' : 'bg-[#F4F6FA] dark:bg-[#252840]'}`}>
            <UploadCloud
              size={24}
              className={`transition-colors duration-200 ${dragOver ? 'text-[#00A650]' : 'text-[#9AA0AE]'}`}
            />
          </div>
          <span className="text-xs text-[#5A6070] dark:text-[#9AA0AE] text-center leading-relaxed font-medium">
            {label}
          </span>
        </button>
      ) : (
        <div className="flex items-center gap-3 px-4 py-3.5 rounded-[18px] border border-[#00A650]/20 bg-[#00A650]/5 dark:bg-[#00A650]/10">
          <div className="shrink-0 p-2 rounded-xl bg-[#00A650]/10">
            <FileIcon size={18} className="text-[#00A650]" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-sm font-semibold text-[#1A1D26] dark:text-white truncate">{file.name}</div>
            <div className="text-xs text-[#5A6070] dark:text-[#9AA0AE] at-number">{formatBytes(file.size)}</div>
          </div>
          <button
            type="button"
            onClick={() => { onSelect(null, null); }}
            disabled={disabled}
            className="shrink-0 p-2 rounded-xl text-[#9AA0AE] hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 transition-all duration-200"
            aria-label="Retirer le fichier"
          >
            <X size={16} />
          </button>
        </div>
      )}
    </div>
  );
}
