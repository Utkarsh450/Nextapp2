import Link from 'next/link'

export default function PrivacyPage() {
  return (
    <main className="mx-auto max-w-2xl px-5 py-12 text-[15px] leading-relaxed">
      <p className="text-[0.7rem] font-medium uppercase tracking-[0.18em] text-[var(--muted)]">Notes</p>
      <h1 className="mt-3 text-3xl font-semibold tracking-tight">Privacy policy</h1>
      <p className="mt-4 text-[var(--muted)]">Last updated 2 September 2026</p>
      <p className="mt-6">
        Notes is a personal notebook. Notes, notebooks, templates, and attachments stay on your device
        in IndexedDB, isolated to the email you sign in with.
      </p>
      <p className="mt-4">
        We use your email only to send a one-time sign-in code. We do not operate a public feed,
        do not sell data, and do not require contacts, location, or advertising identifiers.
      </p>
      <p className="mt-4">
        Optional cloud sync is not enabled. Local notifications, if you allow them, fire only for
        reminders you set on your own notes.
      </p>
      <p className="mt-4">
        You can export or delete your notes from the You tab. Signing out does not upload your notes.
      </p>
      <Link href="/" className="mt-8 inline-flex min-h-11 items-center text-sm font-medium">
        Back to Notes
      </Link>
    </main>
  )
}
