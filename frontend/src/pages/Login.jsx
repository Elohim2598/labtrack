import { useState } from 'react';
import { login } from '../services/api';

function Login({ onLogin }) {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const response = await login(username, password);
            onLogin(response.data.data);
        } catch (err) {
            setError(
                err.response?.data?.error || 'Connection failed. Is the server running?'
            );
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            <div style={styles.card}>
                <div style={styles.logoBar}>
                    <div style={styles.logoIcon}>LT</div>
                    <div>
                        <div style={styles.logoTitle}>LabTrack</div>
                        <div style={styles.logoSub}>Laboratory Information Management System</div>
                    </div>
                </div>

                <form onSubmit={handleSubmit} style={styles.form}>
                    {error && <div style={styles.error}>{error}</div>}

                    <div style={styles.field}>
                        <label style={styles.label}>Username</label>
                        <input
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            style={styles.input}
                            placeholder="Enter username"
                            required
                        />
                    </div>

                    <div style={styles.field}>
                        <label style={styles.label}>Password</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            style={styles.input}
                            placeholder="Enter password"
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            ...styles.button,
                            opacity: loading ? 0.7 : 1,
                        }}
                    >
                        {loading ? 'Signing in...' : 'Sign In'}
                    </button>
                </form>

                <div style={styles.hint}>
                    <div style={styles.hintTitle}>Demo Accounts</div>
                    <div style={styles.hintRow}><span>admin</span><span style={styles.hintRole}>Admin</span></div>
                    <div style={styles.hintRow}><span>jsmith</span><span style={styles.hintRole}>Analyst</span></div>
                    <div style={styles.hintRow}><span>mgarcia</span><span style={styles.hintRole}>Technician</span></div>
                    <div style={styles.hintPw}>Password: password123</div>
                </div>
            </div>
        </div>
    );
}

const styles = {
    container: {
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f1f5f9',
    },
    card: {
        backgroundColor: '#fff',
        borderRadius: '8px',
        padding: '40px',
        width: '100%',
        maxWidth: '400px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06)',
        border: '1px solid #e2e8f0',
    },
    logoBar: {
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        marginBottom: '32px',
    },
    logoIcon: {
        width: '40px',
        height: '40px',
        backgroundColor: '#1e40af',
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#fff',
        fontWeight: '700',
        fontSize: '16px',
    },
    logoTitle: {
        fontSize: '20px',
        fontWeight: '700',
        color: '#0f172a',
    },
    logoSub: {
        fontSize: '12px',
        color: '#64748b',
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '16px',
    },
    field: {
        display: 'flex',
        flexDirection: 'column',
        gap: '4px',
    },
    label: {
        fontSize: '13px',
        fontWeight: '500',
        color: '#334155',
    },
    input: {
        padding: '10px 12px',
        borderRadius: '6px',
        border: '1px solid #d1d5db',
        fontSize: '14px',
        color: '#1e293b',
        outline: 'none',
        transition: 'border-color 0.15s',
    },
    button: {
        padding: '10px',
        borderRadius: '6px',
        border: 'none',
        backgroundColor: '#1e40af',
        color: '#fff',
        fontSize: '14px',
        fontWeight: '600',
        cursor: 'pointer',
        marginTop: '4px',
    },
    error: {
        backgroundColor: '#fef2f2',
        border: '1px solid #fecaca',
        color: '#991b1b',
        padding: '10px 12px',
        borderRadius: '6px',
        fontSize: '13px',
    },
    hint: {
        marginTop: '24px',
        padding: '14px',
        backgroundColor: '#f8fafc',
        borderRadius: '6px',
        border: '1px solid #e2e8f0',
    },
    hintTitle: {
        fontSize: '12px',
        fontWeight: '600',
        color: '#475569',
        marginBottom: '8px',
    },
    hintRow: {
        display: 'flex',
        justifyContent: 'space-between',
        fontSize: '13px',
        color: '#64748b',
        padding: '2px 0',
    },
    hintRole: {
        fontSize: '11px',
        color: '#94a3b8',
    },
    hintPw: {
        fontSize: '11px',
        color: '#94a3b8',
        marginTop: '6px',
        paddingTop: '6px',
        borderTop: '1px solid #e2e8f0',
    },
};

export default Login;