import { Capacitor } from '@capacitor/core'

const CHANNEL_ID = 'note-reminders'
const nativeId = (id: number) => {
  const value = Math.abs(id % 2147483647)
  return value === 0 ? 1 : value
}

type ReminderInput = {
  id: number
  title: string
  body: string
  at: Date
}

let channelReady = false

const isNative = () => {
  try {
    return Capacitor.isNativePlatform()
  } catch {
    return false
  }
}

export const calendarAlertsAvailable = () => isNative()

const loadPlugin = async () => {
  const { LocalNotifications } = await import('@capacitor/local-notifications')
  return LocalNotifications
}

const ensureChannel = async () => {
  if (channelReady) return
  const LocalNotifications = await loadPlugin()
  try {
    await LocalNotifications.createChannel({
      id: CHANNEL_ID,
      name: 'Reminders',
      description: 'Calendar-style alerts for notes with a date and time',
      importance: 5,
      visibility: 1,
      vibration: true,
      lights: true,
    })
  } catch {
    // Channel already exists from a previous launch.
  }
  channelReady = true
}

export const enableCalendarAlerts = async () => {
  if (!isNative()) return { ok: false as const, reason: 'web' as const }
  const LocalNotifications = await loadPlugin()
  const permission = await LocalNotifications.requestPermissions()
  const exact = await LocalNotifications.checkExactNotificationSetting()
  if (exact.exact_alarm !== 'granted') {
    await LocalNotifications.changeExactNotificationSetting()
  }
  await ensureChannel()
  const ok = permission.display === 'granted'
  return { ok, reason: ok ? ('ok' as const) : ('denied' as const) }
}

export const scheduleNoteReminder = async (input: ReminderInput) => {
  if (!isNative() || input.at.getTime() <= Date.now()) return
  const LocalNotifications = await loadPlugin()
  await LocalNotifications.requestPermissions()
  await ensureChannel()
  await LocalNotifications.schedule({
    notifications: [
      {
        id: nativeId(input.id),
        title: input.title || 'Note reminder',
        body: input.body || 'You have a note due.',
        largeBody: input.body || 'You have a note due.',
        extra: { noteId: input.id },
        channelId: CHANNEL_ID,
        autoCancel: true,
        foreground: true,
        isExactNotification: true,
        schedule: { at: input.at, allowWhileIdle: true },
      },
    ],
  })
}

export const cancelNoteReminder = async (id: number) => {
  if (!isNative()) return
  const LocalNotifications = await loadPlugin()
  await LocalNotifications.cancel({ notifications: [{ id: nativeId(id) }] })
}

export const watchReminderOpens = (onOpen: (noteId: number) => void) => {
  if (!isNative()) return () => undefined
  let cancelled = false
  let handle: { remove: () => Promise<void> } | undefined
  void loadPlugin().then(async (LocalNotifications) => {
    if (cancelled) return
    handle = await LocalNotifications.addListener('localNotificationActionPerformed', (event) => {
      const extra = event.notification.extra as { noteId?: number | string } | undefined
      const id = Number(extra?.noteId ?? event.notification.id)
      if (Number.isFinite(id)) onOpen(id)
    })
  })
  return () => {
    cancelled = true
    void handle?.remove()
  }
}
