import { useEffect, useRef } from 'react';

export function usePolling(callback, interval = 30000, enabled = true) {
  const savedCallback = useRef(callback);
  const pausedUntilRef = useRef(0);
  const timeoutRef = useRef(null);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    if (!enabled) return;

    const tick = async () => {
      const now = Date.now();
      if (pausedUntilRef.current > now) return;

      try {
        await savedCallback.current();
      } catch (error) {
        const status = error?.response?.status;
        if (status === 500) {
          const backoffMs = 5 * 60 * 1000;
          pausedUntilRef.current = Date.now() + backoffMs;
          if (timeoutRef.current) clearTimeout(timeoutRef.current);
          timeoutRef.current = setTimeout(() => {
            pausedUntilRef.current = 0;
          }, backoffMs);
        }
      }
    };

    void tick();
    const id = setInterval(tick, interval);
    return () => {
      clearInterval(id);
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, [interval, enabled]);
}
