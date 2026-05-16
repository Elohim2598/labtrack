import axios from 'axios';

// Create an axios instance pointed at your Perl backend
// withCredentials: true sends the session cookie with every request
// Without this, the backend would see you as "not logged in" on every call
const api = axios.create({
    baseURL: 'http://localhost:3000/api',
    withCredentials: true,
    headers: {
        'Content-Type': 'application/json',
    },
});

// ============ Auth ============
export const login = (username, password) =>
    api.post('/auth/login', { username, password });

export const register = (username, email, password, role) =>
    api.post('/auth/register', { username, email, password, role });

export const logout = () =>
    api.post('/auth/logout');

// ============ Samples ============
export const getSamples = (params = {}) =>
    api.get('/samples', { params });

export const getSample = (id) =>
    api.get(`/samples/${id}`);

export const createSample = (data) =>
    api.post('/samples', data);

export const updateSample = (id, data) =>
    api.put(`/samples/${id}`, data);

export const deleteSample = (id) =>
    api.delete(`/samples/${id}`);

// ============ Test Definitions ============
export const getTests = (params = {}) =>
    api.get('/tests', { params });

export const getTest = (id) =>
    api.get(`/tests/${id}`);

export const createTest = (data) =>
    api.post('/tests', data);

// ============ Sample Tests (Results) ============
export const getSampleTests = (sampleId) =>
    api.get(`/samples/${sampleId}/tests`);

export const assignTest = (sampleId, data) =>
    api.post(`/samples/${sampleId}/tests`, data);

export const updateResult = (sampleTestId, data) =>
    api.put(`/sample-tests/${sampleTestId}`, data);

export const approveResult = (sampleTestId) =>
    api.post(`/sample-tests/${sampleTestId}/approve`);

// ============ Dashboard ============
export const getDashboardStats = () =>
    api.get('/dashboard/stats');

export const getRecentActivity = (limit = 20) =>
    api.get('/dashboard/recent', { params: { limit } });

export default api;