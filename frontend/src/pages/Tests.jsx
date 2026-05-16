import { useState, useEffect } from 'react';
import { getTests } from '../services/api';

function Tests() {
    const [tests, setTests] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState(null);

    useEffect(() => {
        getTests()
            .then((res) => setTests(res.data.data))
            .catch((err) => console.error('Failed to load tests:', err))
            .finally(() => setLoading(false));
    }, []);

    const categories = [...new Set(tests.map((t) => t.category))];
    const filtered = filter ? tests.filter((t) => t.category === filter) : tests;

    if (loading) return <p style={{ color: '#64748b' }}>Loading tests...</p>;

    return (
        <div>
            <div style={styles.pageHeader}>
                <div>
                    <h1 style={styles.title}>Test Definitions</h1>
                    <p style={styles.subtitle}>
                        {filtered.length} of {tests.length} test methods
                    </p>
                </div>
            </div>

            {/* Category filters */}
            <div style={styles.filters}>
                <button
                    onClick={() => setFilter(null)}
                    style={{
                        ...styles.filterBtn,
                        backgroundColor: !filter ? '#1e40af' : '#fff',
                        color: !filter ? '#fff' : '#475569',
                        borderColor: !filter ? '#1e40af' : '#d1d5db',
                    }}
                >
                    All
                </button>
                {categories.map((cat) => (
                    <button
                        key={cat}
                        onClick={() => setFilter(cat)}
                        style={{
                            ...styles.filterBtn,
                            backgroundColor: filter === cat ? '#1e40af' : '#fff',
                            color: filter === cat ? '#fff' : '#475569',
                            borderColor: filter === cat ? '#1e40af' : '#d1d5db',
                        }}
                    >
                        {cat}
                    </button>
                ))}
            </div>

            <div style={styles.tableWrap}>
                <table style={styles.table}>
                    <thead>
                        <tr>
                            <th style={styles.th}>Test Name</th>
                            <th style={styles.th}>Category</th>
                            <th style={styles.th}>Unit</th>
                            <th style={styles.th}>Acceptable Range</th>
                            <th style={styles.th}>Method</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filtered.map((test) => (
                            <tr key={test.id}>
                                <td style={styles.td}>
                                    <span style={{ fontWeight: '500', color: '#1e293b' }}>{test.name}</span>
                                </td>
                                <td style={styles.td}>
                                    <span style={{
                                        fontSize: '12px', fontWeight: '500', padding: '2px 8px',
                                        borderRadius: '4px', backgroundColor: '#f1f5f9', color: '#475569',
                                        textTransform: 'capitalize',
                                    }}>
                                        {test.category}
                                    </span>
                                </td>
                                <td style={styles.td}>
                                    <span style={{ color: '#64748b' }}>{test.unit}</span>
                                </td>
                                <td style={styles.td}>
                                    <span style={{ color: '#475569' }}>
                                        {test.min_range} – {test.max_range} <span style={{ color: '#94a3b8' }}>{test.unit}</span>
                                    </span>
                                </td>
                                <td style={styles.td}>
                                    <span style={{
                                        color: '#64748b',
                                        fontFamily: "'SF Mono', 'Fira Code', monospace",
                                        fontSize: '13px',
                                    }}>
                                        {test.method}
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

const styles = {
    pageHeader: {
        marginBottom: '16px',
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
    filters: {
        display: 'flex',
        gap: '8px',
        marginBottom: '16px',
    },
    filterBtn: {
        padding: '6px 14px',
        borderRadius: '6px',
        border: '1px solid',
        fontSize: '13px',
        fontWeight: '500',
        cursor: 'pointer',
        textTransform: 'capitalize',
        fontFamily: 'inherit',
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
    td: {
        padding: '12px 16px',
        fontSize: '14px',
        color: '#334155',
        borderBottom: '1px solid #f1f5f9',
    },
};

export default Tests;