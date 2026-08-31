import { useState } from 'react';

export default function Tooltip({ text, children }) {
  const [visible, setVisible] = useState(false);

  return (
    <div
      className="relative inline-flex"
      onMouseEnter={() => setVisible(true)}
      onMouseLeave={() => setVisible(false)}
    >
      {children}
      {visible && (
        <div
          className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2.5 px-3 py-1.5
                     bg-[#1A1D26] dark:bg-[#252840] text-white text-xs font-medium rounded-xl whitespace-nowrap z-50
                     shadow-xl pointer-events-none animate-at-fade-up"
        >
          {text}
          <div className="absolute top-full left-1/2 -translate-x-1/2 border-4 border-transparent border-t-[#1A1D26] dark:border-t-[#252840]" />
        </div>
      )}
    </div>
  );
}
