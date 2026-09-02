const MAX_EDGE = 1280
const QUALITY = 0.72

const loadImage = (src: string) =>
  new Promise<HTMLImageElement>((resolve, reject) => {
    const image = new Image()
    image.onload = () => resolve(image)
    image.onerror = () => reject(new Error('Could not read image'))
    image.src = src
  })

const drawScaled = (image: HTMLImageElement, maxEdge: number) => {
  const scale = Math.min(1, maxEdge / Math.max(image.width, image.height))
  const canvas = document.createElement('canvas')
  canvas.width = Math.max(1, Math.round(image.width * scale))
  canvas.height = Math.max(1, Math.round(image.height * scale))
  const ctx = canvas.getContext('2d')
  if (!ctx) return null
  ctx.drawImage(image, 0, 0, canvas.width, canvas.height)
  return canvas
}

export const compressImageFile = (file: File, maxEdge = MAX_EDGE, quality = QUALITY) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('Could not read image'))
    reader.onload = async () => {
      const src = String(reader.result)
      if (!src.startsWith('data:image/')) {
        resolve(src)
        return
      }
      try {
        const image = await loadImage(src)
        const canvas = drawScaled(image, maxEdge)
        resolve(canvas ? canvas.toDataURL('image/jpeg', quality) : src)
      } catch {
        resolve(src)
      }
    }
    reader.readAsDataURL(file)
  })

export const compressImageToBlob = (file: File, maxEdge = MAX_EDGE, quality = QUALITY) =>
  new Promise<Blob>((resolve, reject) => {
    if (!file.type.startsWith('image/')) {
      resolve(file)
      return
    }
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('Could not read image'))
    reader.onload = async () => {
      try {
        const image = await loadImage(String(reader.result))
        const canvas = drawScaled(image, maxEdge)
        if (!canvas) {
          resolve(file)
          return
        }
        canvas.toBlob(
          (blob) => resolve(blob || file),
          'image/jpeg',
          quality
        )
      } catch {
        resolve(file)
      }
    }
    reader.readAsDataURL(file)
  })
