const MAX_EDGE = 1280
const QUALITY = 0.72

export const compressImageFile = (file: File, maxEdge = MAX_EDGE, quality = QUALITY) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('Could not read image'))
    reader.onload = () => {
      const src = String(reader.result)
      if (!src.startsWith('data:image/')) {
        resolve(src)
        return
      }
      const image = new Image()
      image.onload = () => {
        const scale = Math.min(1, maxEdge / Math.max(image.width, image.height))
        const width = Math.max(1, Math.round(image.width * scale))
        const height = Math.max(1, Math.round(image.height * scale))
        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        const ctx = canvas.getContext('2d')
        if (!ctx) {
          resolve(src)
          return
        }
        ctx.drawImage(image, 0, 0, width, height)
        resolve(canvas.toDataURL('image/jpeg', quality))
      }
      image.onerror = () => resolve(src)
      image.src = src
    }
    reader.readAsDataURL(file)
  })
