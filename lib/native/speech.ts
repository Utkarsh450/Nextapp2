type SpeechRecognitionLike = {
  lang: string
  interimResults: boolean
  continuous: boolean
  onresult: ((event: { results: ArrayLike<{ 0: { transcript: string } }> }) => void) | null
  onend: (() => void) | null
  onerror: (() => void) | null
  start: () => void
  stop: () => void
}

const recognitionCtor = () => {
  if (typeof window === 'undefined') return null
  const speech = window as Window & {
    SpeechRecognition?: new () => SpeechRecognitionLike
    webkitSpeechRecognition?: new () => SpeechRecognitionLike
  }
  return speech.SpeechRecognition || speech.webkitSpeechRecognition || null
}

export const speechAvailable = () => Boolean(recognitionCtor())

export const startDictation = (handlers: {
  onText: (text: string) => void
  onEnd: () => void
  onError?: () => void
}) => {
  const Ctor = recognitionCtor()
  if (!Ctor) {
    handlers.onError?.()
    handlers.onEnd()
    return { stop: () => undefined }
  }

  const rec = new Ctor()
  rec.lang = 'en-US'
  rec.interimResults = false
  rec.continuous = false
  rec.onresult = (event) => {
    const spoken = event.results[0]?.[0]?.transcript?.trim()
    if (spoken) handlers.onText(spoken)
  }
  rec.onerror = () => {
    handlers.onError?.()
    handlers.onEnd()
  }
  rec.onend = () => handlers.onEnd()
  rec.start()
  return { stop: () => rec.stop() }
}

export const appendSpoken = (current: string, spoken: string) => {
  const next = spoken.trim()
  if (!next) return current
  if (!current.trim()) return next
  const glue = /[\n.!?]$/.test(current.trim()) ? '\n' : ' '
  return `${current.replace(/\s+$/, '')}${glue}${next}`
}
