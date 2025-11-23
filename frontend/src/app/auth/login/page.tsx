'use client';

import React, { useState, useEffect } from 'react';
import { startTokenMonitoring, getApiBaseUrl } from '../../../shared/utils';

const LoginPage = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setUsername('');
    setPassword('');
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const apiUrl = `${getApiBaseUrl()}/api/auth/login`;
      const res = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });
      if (!res.ok) {
        throw new Error('Invalid credentials');
      }
      const data = await res.json();
      localStorage.setItem('token', data.token);
      localStorage.setItem('user', JSON.stringify(data.user));
      
      // Start token monitoring after successful login
      startTokenMonitoring();
      
      window.location.href = '/';
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || 'Login failed');
      } else {
        setError('Login failed');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #f0f4f8 0%, #e0e7ef 100%)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}>
      <div style={{
        background: '#fff',
        borderRadius: 16,
        boxShadow: '0 8px 32px rgba(60, 72, 100, 0.12)',
        padding: '40px 32px',
        maxWidth: 380,
        width: '100%',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
      }}>
        {/* Logo Placeholder */}
        <div style={{ marginBottom: 24 }}>
          <div style={{
            width: 56,
            height: 56,
            borderRadius: '50%',
            background: 'linear-gradient(135deg, #2563eb 0%, #60a5fa 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 32,
            color: '#fff',
            fontWeight: 700,
            boxShadow: '0 2px 8px rgba(37,99,235,0.12)'
          }}>
            {/* You can replace this with your logo */}
            <span>🔒</span>
          </div>
        </div>
        <h2 style={{ fontWeight: 700, fontSize: 28, marginBottom: 8, color: '#1e293b', letterSpacing: -1 }}>Sign in to Janssen CRM</h2>
        <p style={{ color: '#64748b', marginBottom: 28, fontSize: 15 }}>Enter your credentials to access your account</p>
        <form onSubmit={handleSubmit} style={{ width: '100%' }} autoComplete="off">
          <div style={{ marginBottom: 18 }}>
            <label style={{ fontWeight: 500, color: '#334155', fontSize: 15 }}>Username</label>
            <input
              type="text"
              value={username}
              onChange={e => setUsername(e.target.value)}
              required
              style={{
                width: '100%',
                padding: '10px 12px',
                marginTop: 6,
                borderRadius: 8,
                border: '1px solid #cbd5e1',
                fontSize: 16,
                outline: 'none',
                background: '#f8fafc',
                transition: 'border 0.2s',
              }}
              autoFocus
              autoComplete="off"
            />
          </div>
          <div style={{ marginBottom: 18 }}>
            <label style={{ fontWeight: 500, color: '#334155', fontSize: 15 }}>Password</label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              style={{
                width: '100%',
                padding: '10px 12px',
                marginTop: 6,
                borderRadius: 8,
                border: '1px solid #cbd5e1',
                fontSize: 16,
                outline: 'none',
                background: '#f8fafc',
                transition: 'border 0.2s',
              }}
              autoComplete="off"
            />
          </div>
          {error && <div style={{ color: '#ef4444', marginBottom: 16, fontWeight: 500, textAlign: 'center' }}>{error}</div>}
          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: '12px 0',
              borderRadius: 8,
              background: 'linear-gradient(90deg, #2563eb 0%, #60a5fa 100%)',
              color: '#fff',
              fontWeight: 700,
              fontSize: 17,
              border: 'none',
              boxShadow: '0 2px 8px rgba(37,99,235,0.10)',
              cursor: loading ? 'not-allowed' : 'pointer',
              transition: 'background 0.2s',
              marginTop: 6,
            }}
          >
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default LoginPage;