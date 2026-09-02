import { Capacitor } from '@capacitor/core'

type ReminderInput = {
  id: number
  title: string
  body: string
  at: Date
}

const isNative = () => {
  try {
    return Capacitor.isNativePlatform()
  } catch {
    return false
  }
}

export const scheduleNoteReminder = async (input: ReminderInput) => {
  if (!isNative() || input.at.getTime() <= Date.now()) return
  const { LocalNotifications } = await import('@capacitor/local-notifications')
  await LocalNotifications.requestPermissions()
  await LocalNotifications.schedule({
    notifications: [
      {
        id: input.id % 2147483647,
        title: input.title || 'Note reminder',
        body: input.body || 'You have a note due.',
        schedule: { at: input.at },
      },
    ],
  })
}

export const cancelNoteReminder = async (id: number) => {
  if (!isNative()) return
  const { LocalNotifications } = await import('@capacitor/local-notifications')
  await LocalNotifications.cancel({ notifications: [{ id: id % 2147483647 }] })
}
