/**
 * Notes OTP auth — Google Apps Script
 *
 * Setup:
 * 1. script.google.com → New project → paste this file
 * 2. Project Settings → Script properties:
 *    OTP_SECRET = a long random string (same as APPS_SCRIPT_SECRET in .env.local)
 * 3. Deploy → New deployment → Type: Web app
 *    Execute as: Me
 *    Who has access: Anyone
 * 4. Copy the web app URL into my-app/.env.local as APPS_SCRIPT_URL
 * 5. Redeploy after every code change
 *
 * The Next.js API routes call this script. OTP is emailed with Gmail
 * and stored hashed in CacheService for 10 minutes. The code is never
 * returned to the browser.
 */

function doGet() {
  return json_({ ok: true, service: 'notes-otp' })
}

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents)
    const secret = PropertiesService.getScriptProperties().getProperty('OTP_SECRET')
    if (!secret || data.secret !== secret) {
      return json_({ ok: false, error: 'Unauthorized' })
    }

    const email = String(data.email || '').trim().toLowerCase()
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return json_({ ok: false, error: 'Enter a valid email address' })
    }

    if (data.action === 'send') return sendOtp_(email)
    if (data.action === 'verify') return verifyOtp_(email, String(data.otp || '').replace(/\s/g, ''))
    return json_({ ok: false, error: 'Unknown action' })
  } catch (error) {
    return json_({ ok: false, error: String(error) })
  }
}

function sendOtp_(email) {
  const lock = LockService.getScriptLock()
  lock.waitLock(5000)

  try {
    const cache = CacheService.getScriptCache()
    const throttleKey = 'otp_wait_' + email
    if (cache.get(throttleKey)) {
      return json_({ ok: false, error: 'Wait a minute before requesting another code' })
    }

    const otp = String(100000 + Math.floor(Math.random() * 900000))
    cache.put(otpKey_(email), JSON.stringify({
      hash: hash_(email + ':' + otp),
      tries: 0,
    }), 600)
    cache.put(throttleKey, '1', 60)

    MailApp.sendEmail({
      to: email,
      subject: 'Your Notes login code',
      htmlBody:
        '<div style="font-family:sans-serif;max-width:420px;padding:24px">' +
        '<p style="font-size:13px;color:#71717a;letter-spacing:.16em;text-transform:uppercase">Notes</p>' +
        '<h1 style="font-size:28px;letter-spacing:.2em;margin:12px 0">' + otp + '</h1>' +
        '<p style="color:#52525b">This code expires in 10 minutes. If you did not request it, ignore this email.</p>' +
        '</div>',
    })

    return json_({ ok: true })
  } finally {
    lock.releaseLock()
  }
}

function verifyOtp_(email, otp) {
  if (!/^\d{6}$/.test(otp)) {
    return json_({ ok: false, error: 'Enter the 6-digit code' })
  }

  const cache = CacheService.getScriptCache()
  const raw = cache.get(otpKey_(email))
  if (!raw) return json_({ ok: false, error: 'Code expired. Request a new one.' })

  const record = JSON.parse(raw)
  record.tries = Number(record.tries || 0) + 1
  if (record.tries > 5) {
    cache.remove(otpKey_(email))
    return json_({ ok: false, error: 'Too many attempts. Request a new code.' })
  }

  if (record.hash !== hash_(email + ':' + otp)) {
    cache.put(otpKey_(email), JSON.stringify(record), 600)
    return json_({ ok: false, error: 'That code is incorrect' })
  }

  cache.remove(otpKey_(email))
  cache.remove('otp_wait_' + email)
  return json_({ ok: true })
}

function otpKey_(email) {
  return 'otp_' + email
}

function hash_(value) {
  const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, value)
  return bytes.map(function (byte) {
    const unsigned = byte < 0 ? byte + 256 : byte
    return ('0' + unsigned.toString(16)).slice(-2)
  }).join('')
}

function json_(payload) {
  return ContentService
    .createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON)
}
