import { useEffect, useRef } from 'react';

/**
 * Polling intelligent : s'arrête quand l'onglet est caché (visibilitychange)
 * et relance immédiatement au retour → économise CPU, réseau et batterie.
 */
export function usePolling(callback, interval = 30000, enabled = true) {
  const savedCallback = useRef(callback);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    if (!enabled) return;

    let id = null;
    const tick = () => savedCallback.current();

    const start = () => {
      if (id) return;
      id = setInterval(tick, interval);
    };

    const stop = () => {
      if (id) {
        clearInterval(id);
        id = null;
      }
    };

    const onVisibility = () => {
      if (document.hidden) stop();
      else start();
    };

    if (!document.hidden) start();
    document.addEventListener('visibilitychange', onVisibility);

    return () => {
      stop();
      document.removeEventListener('visibilitychange', onVisibility);
    };
  }, [interval, enabled]);
}
