import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Samples from './pages/Samples';
import SampleDetail from './pages/SampleDetail';
import Tests from './pages/Tests';

function App() {
  // user state — null means "not logged in"
  // We store the user object (id, username, role) after login
  const [user, setUser] = useState(null);

  // Check if there's a saved user in sessionStorage on page load
  // sessionStorage is like localStorage but clears when you close the tab
  // This prevents losing login state when you refresh the page
  useEffect(() => {
    const saved = sessionStorage.getItem('labtrack_user');
    if (saved) {
      setUser(JSON.parse(saved));
    }
  }, []);
  // The empty [] means this runs once on mount (like componentDidMount)

  // Called after successful login — saves user and stores in sessionStorage
  const handleLogin = (userData) => {
    setUser(userData);
    sessionStorage.setItem('labtrack_user', JSON.stringify(userData));
  };

  // Called on logout — clears everything
  const handleLogout = () => {
    setUser(null);
    sessionStorage.removeItem('labtrack_user');
  };

  return (
    <BrowserRouter>
      <Routes>
        {/* If not logged in, show Login page on every route */}
        {/* If logged in, show the app inside the Layout wrapper */}

        <Route
          path="/login"
          element={
            user
              ? <Navigate to="/" replace />  // Already logged in? Go to dashboard
              : <Login onLogin={handleLogin} />
          }
        />

        {/* All these routes are wrapped in Layout which provides the navbar/sidebar */}
        {/* If not logged in, redirect to /login */}
        <Route
          path="/"
          element={
            user
              ? <Layout user={user} onLogout={handleLogout} />
              : <Navigate to="/login" replace />
          }
        >
          {/* "index" means this is the default child route for "/" */}
          <Route index element={<Dashboard />} />
          <Route path="samples" element={<Samples />} />
          <Route path="samples/:id" element={<SampleDetail />} />
          <Route path="tests" element={<Tests />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;