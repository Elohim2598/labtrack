import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getSample, getSampleTests } from '../services/api';

function SampleDetail() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [sample, setSample] = useState(null);
    const [tests, setTests] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([getSample(id), getSampleTests(id)])
            .then(([sampleRes, testsRes]) => {
                setSample(sampleRes.data.data);
                setTests(testsRes.data.data);
            })
            .catch((err) => console.error('Failed to load sample:', err))
            .finally(() => setLoading(false));
    }, [id]);

    if (loading) return <p style={{ color: '#64748b' }}>Loading sample...</p>;
    if (!sample) return <p style={{ color: '#dc2626' }}>Sample not found</p>;

    return (
        <div>
            <button onClick={() => navigate('/samples')} style={styles.backBtn}>
                ← Back to Samples
            </button>

            {/* Sample header */}
            <div style={styles.header}>
                <div>
                    <h1 style={styles.title}>{sample.sample_code}</h1>
                    <p style={styles.client}>{sample.client_name}</p>
                </div>
                <StatusPill status={sample.status} />
            </div>

            {/* Info cards */}
            <div style={styles.infoGrid}>
                <InfoCard label="Product Type" value={sample.sample_type.replace('_', ' ')} />
                <InfoCard label="Received By" value={sample.received_by_name || 'N/A'} />
                <InfoCard label="Received" value={new Date(sample.received_at).toLocaleDateString()} />
                <InfoCard label="Notes" value={sample.notes || 'No notes'} />
            </div>

            {/* Tests */}
            <div style={styles.testsSection}>
                <div style={styles.testsHeader}>
                    <h2 style={styles.testsTitle}>Assigned Tests</h2>
                    <span style={styles.testsCount}>{tests.length} tests</span>
                </div>

                {tests.length === 0 ? (
                    <p style={{ padding: '20px', color: '#94a3b8' }}>No tests assigned yet.</p>
                ) : (
                    <table style={styles.table}>
                        <thead>
                            <tr>
                                <th style={styles.th}>Test Name</th>
                                <th style={styles.th}>Category</th>
                                <th style={styles.th}>Status</th>
                                <th style={styles.th}>Result</th>
                                <th style={styles.th}>Pass/Fail</th>
                                <th style={styles.th}>Technician</th>
                                <th style={styles.th}>Approved By</th>
                            </tr>
                        </thead>
                        <tbody>
                            {tests.map((test) => (
                                <tr key={test.id}>
                                    <td style={styles.td}>
                                        <div style={{ fontWeight: '500', color: '#1e293b' }}>{test.test_name}</div>
                                        <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '2px' }}>{test.method}</div>
                                    </td>
                                    <td style={styles.td}>
                                        <span style={{ textTransform: 'capitalize', color: '#64748b' }}>{test.category}</span>
                                    </td>
                                    <td style={styles.td}>
                                        <TestStatusPill status={test.status} />
                                    </td>
                                    <td style={styles.td}>
                                        {test.result_value !== null ? (
                                            <span style={{ fontWeight: '500' }}>{test.result_value} <span style={{ color: '#94a3b8' }}>{test.unit}</span></span>
                                        ) : (
                                            <span style={{ color: '#cbd5e1' }}>—</span>
                                        )}
                                    </td>
                                    <td style={styles.td}>
                                        {test.pass_fail ? (
                                            <span style={{
                                                fontSize: '12px',
                                                fontWeight: '600',
                                                padding: '2px 8px',
                                                borderRadius: '4px',
                                                backgroundColor: test.pass_fail === 'pass' ? '#dcfce7' : '#fee2e2',
                                                color: test.pass_fail === 'pass' ? '#166534' : '#991b1b',
                                                textTransform: 'uppercase',
                                            }}>
                                                {test.pass_fail}
                                            </span>
                                        ) : (
                                            <span style={{ color: '#cbd5e1' }}>—</span>
                                        )}
                                    </td>
                                    <td style={styles.td}>
                                        <span style={{ color: '#64748b' }}>{test.assigned_to_name || '—'}</span>
                                    </td>
                                    <td style={styles.td}>
                                        {test.approved_by_name ? (
                                            <span style={{ color: '#047857' }}>{test.approved_by_name}</span>
                                        ) : (
                                            <span style={{ color: '#cbd5e1' }}>—</span>
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
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
            fontSize: '13px', fontWeight: '500', padding: '4px 12px',
            borderRadius: '4px', backgroundColor: c.bg, color: c.text,
            textTransform: 'capitalize',
        }}>
            {status.replace('_', ' ')}
        </span>
    );
}

function TestStatusPill({ status }) {
    const colors = {
        pending: { bg: '#f1f5f9', text: '#64748b' },
        in_progress: { bg: '#fef3c7', text: '#92400e' },
        completed: { bg: '#d1fae5', text: '#065f46' },
        failed: { bg: '#fee2e2', text: '#991b1b' },
    };
    const c = colors[status] || { bg: '#f1f5f9', text: '#64748b' };
    return (
        <span style={{
            fontSize: '11px', fontWeight: '500', padding: '2px 8px',
            borderRadius: '4px', backgroundColor: c.bg, color: c.text,
            textTransform: 'capitalize',
        }}>
            {status.replace('_', ' ')}
        </span>
    );
}

function InfoCard({ label, value }) {
    return (
        <div style={styles.infoCard}>
            <div style={{ fontSize: '12px', color: '#94a3b8', marginBottom: '4px' }}>{label}</div>
            <div style={{ fontSize: '14px', color: '#1e293b', fontWeight: '500', textTransform: 'capitalize' }}>{value}</div>
        </div>
    );
}

const styles = {
    backBtn: {
        background: 'none',
        border: 'none',
        color: '#1e40af',
        fontSize: '14px',
        cursor: 'pointer',
        padding: 0,
        marginBottom: '16px',
        fontFamily: 'inherit',
    },
    header: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        marginBottom: '20px',
    },
    title: {
        fontSize: '24px',
        fontWeight: '700',
        color: '#0f172a',
        margin: 0,
        fontFamily: "'SF Mono', 'Fira Code', monospace",
    },
    client: {
        fontSize: '15px',
        color: '#64748b',
        marginTop: '4px',
    },
    infoGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '12px',
        marginBottom: '24px',
    },
    infoCard: {
        backgroundColor: '#fff',
        border: '1px solid #e2e8f0',
        borderRadius: '8px',
        padding: '14px 16px',
    },
    testsSection: {
        backgroundColor: '#fff',
        border: '1px solid #e2e8f0',
        borderRadius: '8px',
        overflow: 'hidden',
    },
    testsHeader: {
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '14px 16px',
        borderBottom: '1px solid #e2e8f0',
    },
    testsTitle: {
        fontSize: '16px',
        fontWeight: '600',
        color: '#0f172a',
        margin: 0,
    },
    testsCount: {
        fontSize: '13px',
        color: '#94a3b8',
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
    },
    th: {
        textAlign: 'left',
        padding: '10px 16px',
        fontSize: '11px',
        fontWeight: '600',
        color: '#64748b',
        textTransform: 'uppercase',
        letterSpacing: '0.3px',
        borderBottom: '1px solid #e2e8f0',
        backgroundColor: '#f8fafc',
    },
    td: {
        padding: '10px 16px',
        fontSize: '14px',
        color: '#334155',
        borderBottom: '1px solid #f1f5f9',
    },
};

export default SampleDetail;