import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getSamples } from '../services/api';

function Samples() {
    const [samples, setSamples] = useState([]);
    const [loading, setLoading] = useState(true);
    const navigate = useNavigate();

    useEffect(() => {
        getSamples()
            .then((res) => setSamples(res.data.data))
            .catch((err) => console.error('Failed to load samples:', err))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <p style={{ color: '#64748b' }}>Loading samples...</p>;

    return (
        <div>
            <div style={styles.pageHeader}>
                <div>
                    <h1 style={styles.title}>Samples</h1>
                    <p style={styles.subtitle}>{samples.length} registered samples</p>
                </div>
            </div>

            <div style={styles.tableWrap}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Sample Code</th>
                            <th style={styles.th}>Client</th>
                            <th style={styles.th}>Product Type</th>
                            <th style={styles.th}>Status</th>
                            <th style={styles.th}>Received By</th>
                            <th style={styles.th}>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        {samples.map((sample) => (
                            <tr
                                key={sample.id}
                                style={styles.tr}
                                onClick={() => navigate(`/samples/${sample.id}`)}
                                onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f8fafc'}
                                onMouseLeave={(e) => e.currentTarget.style.backgroundColor = '#fff'}
                            >
                                <td style={styles.td}>
                                    <span style={styles.code}>{sample.sample_code}</span>
                                </td>
                                <td style={styles.td}>{sample.client_name}</td>
                                <td style={styles.td}>
                                    <span style={styles.type}>{sample.sample_type.replace('_', ' ')}</span>
                                </td>
                                <td style={styles.td}>
                                    <StatusPill status={sample.status} />
                                </td>
                                <td style={styles.td}>
                                    <span style={{ color: '#64748b' }}>{sample.received_by_name}</span>
                                </td>
                                <td style={styles.td}>
                                    <span style={{ color: '#64748b' }}>
                                        {new Date(sample.received_at).toLocaleDateString()}
                                    </span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

function StatusPill({ status }) {
    const colors = {
        received: { bg: '#dbeafe', text: '#1e40af' },
        in_testing: { bg: '#fef3c7', text: '#92400e' },
        completed: { bg: '#d1fae5', text: '#065f46' },
        rejected: { bg: '#fee2e2', text: '#991b1b' },
    };
    const c = colors[status] || { bg: '#f1f5f9', text: '#475569' };
    return (
        <span style={{
            fontSize: '12px',
            fontWeight: '500',
            padding: '3px 10px',
            borderRadius: '4px',
            backgroundColor: c.bg,
            color: c.text,
            textTransform: 'capitalize',
        }}>
            {status.replace('_', ' ')}
        </span>
    );
}

const styles = {
    pageHeader: {
        marginBottom: '20px',
    },
    title: {
        fontSize: '22px',
        fontWeight: '700',
        color: '#0f172a',
        margin: 0,
    },
    subtitle: {
        fontSize: '14px',
        color: '#64748b',
        marginTop: '4px',
    },
    tableWrap: {
        backgroundColor: '#fff',
        borderRadius: '8px',
        border: '1px solid #e2e8f0',
        overflow: 'hidden',
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
    },
    th: {
        textAlign: 'left',
        padding: '12px 16px',
        fontSize: '12px',
        fontWeight: '600',
        color: '#64748b',
        textTransform: 'uppercase',
        letterSpacing: '0.3px',
        borderBottom: '1px solid #e2e8f0',
        backgroundColor: '#f8fafc',
    },
    tr: {
        cursor: 'pointer',
        backgroundColor: '#fff',
        transition: 'background-color 0.1s',
    },
    td: {
        padding: '12px 16px',
        fontSize: '14px',
        color: '#334155',
        borderBottom: '1px solid #f1f5f9',
    },
    code: {
        fontWeight: '600',
        color: '#1e40af',
        fontFamily: "'SF Mono', 'Fira Code', monospace",
        fontSize: '13px',
    },
    type: {
        textTransform: 'capitalize',
        color: '#475569',
    },
};

export default Samples;