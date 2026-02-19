let translations = {}

function loadTranslations() {
  const meta = document.querySelector('meta[name="translations"]')
  if (meta) {
    try {
      translations = JSON.parse(meta.content)
    } catch (e) {
      console.error("Failed to parse translations:", e)
      translations = {}
    }
  }
}

// Load on first import
loadTranslations()

// Reload on Turbo navigation
document.addEventListener("turbo:load", loadTranslations)

export function t(key, replacements = {}) {
  let value = key.split(".").reduce((obj, k) => (obj && obj[k] !== undefined ? obj[k] : null), translations)

  if (value === null) {
    console.warn(`Missing translation: ${key}`)
    return key
  }

  if (typeof value === "string") {
    Object.entries(replacements).forEach(([k, v]) => {
      value = value.replace(`%{${k}}`, v)
    })
    return value
  }

  return String(value)
}
