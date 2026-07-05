import { useCallback, useEffect, useState } from 'react'

export default function useAsync(asyncFn, { immediate = true, deps = [] } = {}) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(immediate)
  const [error, setError] = useState(null)

  const execute = useCallback(async (...args) => {
    setLoading(true)
    setError(null)
    try {
      const result = await asyncFn(...args)
      setData(result)
      return result
    } catch (err) {
      const msg = err.response?.data?.message ?? err.message ?? 'Erreur inconnue'
      setError(msg)
      throw err
    } finally {
      setLoading(false)
    }
  }, deps)

  useEffect(() => {
    if (immediate) execute()
  }, [execute, immediate])

  return { data, loading, error, execute, setData }
}
