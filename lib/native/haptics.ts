export const tickHaptic = () => {
  try {
    navigator.vibrate?.(16)
  } catch {
    // Browsers without vibration, and most desktops, simply no-op.
  }
}
