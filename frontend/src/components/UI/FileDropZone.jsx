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
            'w-full flex flex-col items-center justify-center gap-2 px-4 py-6',
            'rounded-xl border-2 border-dashed cursor-pointer select-none',
            'transition-all duration-200 will-change-transform',
            dragOver
              ? 'border-at-green bg-at-green/5 scale-[1.01]'
              : 'border-gray-200 dark:border-gray-700 hover:border-at-green/50 hover:bg-at-green/[0.03]',
            disabled ? 'opacity-50 cursor-not-allowed' : '',
          ].join(' ')}
        >
          <UploadCloud
            size={22}
            className={`transition-colors duration-200 ${dragOver ? 'text-at-green' : 'text-gray-400'}`}
          />
          <span className="text-xs text-gray-500 dark:text-gray-400 text-center leading-relaxed">
            {label}
          </span>
        </button>
      ) : (
        <div className="flex items-center gap-3 px-4 py-3 rounded-xl border border-at-green/30 bg-at-green/5">
          <FileIcon size={18} className="text-at-green shrink-0" />
          <div className="min-w-0 flex-1">
            <div className="text-sm font-semibold text-gray-800 dark:text-gray-100 truncate">{file.name}</div>
            <div className="text-xs text-gray-500 dark:text-gray-400">{formatBytes(file.size)}</div>
          </div>
          <button
            type="button"
            onClick={() => { onSelect(null, null); }}
            disabled={disabled}
            className="shrink-0 p-1.5 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors"
            aria-label="Retirer le fichier"
          >
            <X size={16} />
          </button>
        </div>
      )}
    </div>
  );
}
