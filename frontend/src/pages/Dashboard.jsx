import { useState, useEffect } from 'react';
import { getDashboardStats } from '../services/api';

function Dashboard() {
    const [stats, setStats] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        getDashboardStats()
            .then((res) => setStats(res.data.data))
            .catch((err) => console.error('Failed to load stats:', err))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <p style={{ color: '#64748b' }}>Loading dashboard...</p>;
    if (!stats) return <p style={{ color: '#dc2626' }}>Failed to load dashboard</p>;

    return (
        <div>
            <h1 style={styles.title}>Dashboard</h1>
            <p style={styles.subtitle}>Overview of laboratory operations</p>

            {/* Stat cards */}
            <div style={styles.cardGrid}>
                <StatCard label="Total Samples" value={stats.total_samples} color="#1e40af" bg="#eff6ff" />
                <StatCard label="Awaiting Approval" value={stats.awaiting_approval} color="#b45309" bg="#fffbeb" />
                <StatCard label="Received (7 days)" value={stats.received_last_7d} color="#047857" bg="#ecfdf5" />
                <StatCard
                    label="Tests Completed"
                    value={stats.tests_by_status?.find((t) => t.status === 'completed')?.count || 0}
                    color="#6d28d9"
                    bg="#f5f3ff"
                />
            </div>

            <div style={styles.sectionGrid}>
                {/* Samples by status */}
                <div style={styles.section}>
                    <div style={styles.sectionHeader}>Samples by Status</div>
                    <div style={styles.sectionBody}>
                        {stats.samples_by_status?.map((s) => (
                            <div key={s.status} style={styles.row}>
                                <StatusPill status={s.status} />
                                <span style={styles.rowCount}>{s.count}</span>
                                <div style={styles.barTrack}>
                                    <div style={{
                                        ...styles.barFill,
                                        width: `${(s.count / stats.total_samples) * 100}%`,
                                        backgroundColor: statusColors[s.status] || '#94a3b8',
                                    }} />
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Samples by type */}
                <div style={styles.section}>
                    <div style={styles.sectionHeader}>Samples by Product Type</div>
                    <div style={styles.sectionBody}>
                        {stats.samples_by_type?.map((s) => (
                            <div key={s.sample_type} style={styles.row}>
                                <span style={styles.rowLabel}>
                                    {s.sample_type.replace('_', ' ')}
                                </span>
                                <span style={styles.rowCount}>{s.count}</span>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Tests by status */}
                <div style={styles.section}>
                    <div style={styles.sectionHeader}>Test Status Overview</div>
                    <div style={styles.sectionBody}>
                        {stats.tests_by_result?.map((t) => (
                            <div key={t.pass_fail} style={styles.row}>
                                <span style={{
                                    ...styles.resultPill,
                                    backgroundColor: t.pass_fail === 'pass' ? '#dcfce7' : '#fee2e2',
                                    color: t.pass_fail === 'pass' ? '#166534' : '#991b1b',
                                }}>
                                    {t.pass_fail}
                                </span>
                                <span style={styles.rowCount}>{t.count}</span>
                            </div>
                        ))}
                        {stats.tests_by_status?.map((t) => (
                            <div key={t.status} style={styles.row}>
                                <span style={styles.rowLabel}>
                                    {t.status.replace('_', ' ')}
                                </span>
                                <span style={styles.rowCount}>{t.count}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}

const statusColors = {
    received: '#3b82f6',
    in_testing: '#f59e0b',
    completed: '#10b981',
    rejected: '#ef4444',
};

function StatCard({ label, value, color, bg }) {
    return (
        <div style={{ ...styles.card, backgroundColor: '#fff' }}>
            <div style={{ ...styles.cardValue, color }}>{value}</div>
            <div style={styles.cardLabel}>{label}</div>
            <div style={{ ...styles.cardAccent, backgroundColor: color }} />
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
            ...styles.pill,
            backgroundColor: c.bg,
            color: c.text,
        }}>
            {status.replace('_', ' ')}
        </span>
    );
}

const styles = {
    title: {
        fontSize: '22px',
        fontWeight: '700',
        color: '#0f172a',
        margin: '0',
    },
    subtitle: {
        fontSize: '14px',
        color: '#64748b',
        marginTop: '4px',
        marginBottom: '24px',
    },
    cardGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '16px',
        marginBottom: '24px',
    },
    card: {
        borderRadius: '8px',
        padding: '20px',
        border: '1px solid #e2e8f0',
        position: 'relative',
        overflow: 'hidden',
    },
    cardValue: {
        fontSize: '32px',
        fontWeight: '700',
    },
    cardLabel: {
        fontSize: '13px',
        color: '#64748b',
        marginTop: '4px',
    },
    cardAccent: {
        position: 'absolute',
        top: 0,
        left: 0,
        width: '4px',
        height: '100%',
        borderRadius: '8px 0 0 8px',
    },
    sectionGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: '16px',
    },
    section: {
        backgroundColor: '#fff',
        borderRadius: '8px',
        border: '1px solid #e2e8f0',
        overflow: 'hidden',
    },
    sectionHeader: {
        padding: '14px 16px',
        fontSize: '14px',
        fontWeight: '600',
        color: '#334155',
        borderBottom: '1px solid #f1f5f9',
    },
    sectionBody: {
        padding: '12px 16px',
    },
    row: {
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        padding: '8px 0',
        borderBottom: '1px solid #f8fafc',
    },
    rowLabel: {
        flex: 1,
        fontSize: '13px',
        color: '#475569',
        textTransform: 'capitalize',
    },
    rowCount: {
        fontSize: '14px',
        fontWeight: '600',
        color: '#0f172a',
        minWidth: '28px',
        textAlign: 'right',
    },
    pill: {
        flex: 1,
        fontSize: '12px',
        fontWeight: '500',
        padding: '3px 10px',
        borderRadius: '4px',
        textTransform: 'capitalize',
        display: 'inline-block',
    },
    resultPill: {
        flex: 1,
        fontSize: '12px',
        fontWeight: '600',
        padding: '3px 10px',
        borderRadius: '4px',
        textTransform: 'uppercase',
        display: 'inline-block',
    },
    barTrack: {
        flex: 1,
        height: '6px',
        backgroundColor: '#f1f5f9',
        borderRadius: '3px',
        overflow: 'hidden',
    },
    barFill: {
        height: '100%',
        borderRadius: '3px',
        transition: 'width 0.3s ease',
    },
};

export default Dashboard;