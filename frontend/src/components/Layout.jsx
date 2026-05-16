import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { logout } from '../services/api';

function Layout({ user, onLogout }) {
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      await logout();
    } catch (err) {
      console.error('Logout error:', err);
    }
    onLogout();
    navigate('/login');
  };

  const roleColors = {
    admin: { bg: '#dbeafe', text: '#1e40af' },
    analyst: { bg: '#e0e7ff', text: '#3730a3' },
    technician: { bg: '#d1fae5', text: '#065f46' },
  };

  const rc = roleColors[user.role] || { bg: '#f1f5f9', text: '#475569' };

  return (
    <div style={styles.wrapper}>
      {/* Sidebar */}
      <aside style={styles.sidebar}>
        <div style={styles.logoSection}>
          <div style={styles.logoIcon}>LT</div>
          <span style={styles.logoText}>LabTrack</span>
        </div>

        <div style={styles.navLabel}>MAIN MENU</div>

        <nav style={styles.nav}>
          <NavLink
            to="/" end
            style={({ isActive }) => ({
              ...styles.navLink,
              backgroundColor: isActive ? '#eff6ff' : 'transparent',
              color: isActive ? '#1e40af' : '#475569',
              fontWeight: isActive ? '600' : '500',
              borderLeft: isActive ? '3px solid #1e40af' : '3px solid transparent',
            })}
          >
            Dashboard
          </NavLink>
          <NavLink
            to="/samples"
            style={({ isActive }) => ({
              ...styles.navLink,
              backgroundColor: isActive ? '#eff6ff' : 'transparent',
              color: isActive ? '#1e40af' : '#475569',
              fontWeight: isActive ? '600' : '500',
              borderLeft: isActive ? '3px solid #1e40af' : '3px solid transparent',
            })}
          >
            Samples
          </NavLink>
          <NavLink
            to="/tests"
            style={({ isActive }) => ({
              ...styles.navLink,
              backgroundColor: isActive ? '#eff6ff' : 'transparent',
              color: isActive ? '#1e40af' : '#475569',
              fontWeight: isActive ? '600' : '500',
              borderLeft: isActive ? '3px solid #1e40af' : '3px solid transparent',
            })}
          >
            Test Definitions
          </NavLink>
        </nav>

        <div style={styles.userSection}>
          <div style={styles.userAvatar}>
            {user.username.charAt(0).toUpperCase()}
          </div>
          <div style={styles.userInfo}>
            <div style={styles.userName}>{user.username}</div>
            <span style={{
              ...styles.roleBadge,
              backgroundColor: rc.bg,
              color: rc.text,
            }}>
              {user.role}
            </span>
          </div>
          <button onClick={handleLogout} style={styles.logoutBtn}>
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main style={styles.main}>
        <Outlet />
      </main>
    </div>
  );
}

const styles = {
  wrapper: {
    display: 'flex',
    minHeight: '100vh',
  },
  sidebar: {
    width: '230px',
    backgroundColor: '#fff',
    borderRight: '1px solid #e2e8f0',
    display: 'flex',
    flexDirection: 'column',
    padding: '16px 0',
  },
  logoSection: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '4px 20px 20px',
    borderBottom: '1px solid #f1f5f9',
    marginBottom: '16px',
  },
  logoIcon: {
    width: '32px',
    height: '32px',
    backgroundColor: '#1e40af',
    borderRadius: '6px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    color: '#fff',
    fontWeight: '700',
    fontSize: '13px',
  },
  logoText: {
    fontSize: '16px',
    fontWeight: '700',
    color: '#0f172a',
  },
  navLabel: {
    padding: '0 20px 8px',
    fontSize: '11px',
    fontWeight: '600',
    color: '#94a3b8',
    letterSpacing: '0.5px',
  },
  nav: {
    display: 'flex',
    flexDirection: 'column',
    flex: 1,
  },
  navLink: {
    display: 'block',
    padding: '9px 20px',
    textDecoration: 'none',
    fontSize: '14px',
  },
  userSection: {
    borderTop: '1px solid #f1f5f9',
    padding: '16px 20px 4px',
    display: 'flex',
    flexDirection: 'column',
    gap: '10px',
  },
  userAvatar: {
    width: '32px',
    height: '32px',
    backgroundColor: '#e2e8f0',
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '14px',
    fontWeight: '600',
    color: '#475569',
  },
  userInfo: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  userName: {
    fontSize: '14px',
    fontWeight: '500',
    color: '#334155',
  },
  roleBadge: {
    fontSize: '11px',
    fontWeight: '600',
    padding: '2px 8px',
    borderRadius: '4px',
    textTransform: 'capitalize',
  },
  logoutBtn: {
    padding: '6px 0',
    border: 'none',
    backgroundColor: 'transparent',
    color: '#94a3b8',
    fontSize: '13px',
    cursor: 'pointer',
    textAlign: 'left',
    fontFamily: 'inherit',
  },
  main: {
    flex: 1,
    padding: '28px 32px',
    backgroundColor: '#f1f5f9',
    overflowY: 'auto',
    maxHeight: '100vh',
  },
};

export default Layout;