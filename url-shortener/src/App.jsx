import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from './assets/vite.svg'
import heroImg from './assets/hero.png'
import './App.css'

function App() {
  const [urlInput, setUrlInput] = useState('')
  const [result, setResult] = useState('')
  const [error, setError] = useState('')

  const handleShorten = async (e) => {
    e.preventDefault()
    setError('')
    try {
      const response = await fetch('/api/shorten', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ long_url: urlInput })
      })
      if (!response.ok) throw new Error('Failed to shorten URL')
      const data = await response.json()
      setResult(`${window.location.origin}/api/${data.short_code}`)
    } catch (err) {
      setResult('')
      setError(err.message)
    }
    setUrlInput('')
  }

  const handleGetLongUrl = async (e) => {
    e.preventDefault()
    setError('')
    try {
      const shortCode = urlInput.split('/').pop()
      const response = await fetch(`/api/lengthen?short_code=${shortCode}`)
      if (!response.ok) throw new Error('Short URL not found')
      const data = await response.json()
      setResult(data.long_url)
    } catch (err) {
      setResult('')
      setError(err.message)
    }
    setUrlInput('')
  }

  return (
    <>
      <section id="center">
        <div>
          <h1>Ben's URL Shortener</h1>
        </div>
        <div>
          <form style={{ display: 'flex', flexDirection: 'column', gap: '1rem', alignItems: 'center' }}>
            <input
              type="url"
              placeholder="Enter a URL"
              value={urlInput}
              onChange={(e) => setUrlInput(e.target.value)}
              required
            />
            <div style={{ display: 'flex', gap: '1rem' }}>
              <button type="submit" onClick={handleShorten}>Get Short URL</button>
              <button type="button" onClick={handleGetLongUrl}>Get Long URL</button>
            </div>
          </form>
        </div>
        {result && (
          <div className="result-box" style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <span>{result}</span>
            <button onClick={() => navigator.clipboard.writeText(result)}>📋</button>
          </div>
        )}
        {error && <p style={{ color: 'red' }}>{error}</p>}
      </section>
    </>
  )
}

export default App
