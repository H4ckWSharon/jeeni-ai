const http = require('http');

async function runApiIntegrationTests() {
  console.log('--- TEST SUITE 3: Full-Stack Admin API Security & Live Interception ---');

  // Require express app without listen
  // We can start server on ephemeral port
  process.env.PORT = '3899';
  const serverModule = require('./server.js');

  // Give server 1.5 seconds to bind
  await new Promise(r => setTimeout(r, 1500));

  const BASE_URL = 'http://localhost:3899';

  // Helper fetch
  async function request(path, opts = {}) {
    const res = await fetch(`${BASE_URL}${path}`, opts);
    let body;
    try {
      body = await res.json();
    } catch (_) {
      body = null;
    }
    return { status: res.status, headers: res.headers, body };
  }

  // 1. Student / Unauthenticated access to /api/admin/dashboard
  const unauthRes = await request('/api/admin/dashboard');
  console.log('Unauthenticated access status:', unauthRes.status);
  if (unauthRes.status !== 401) throw new Error('Expected 401 for unauthenticated admin access');
  console.log('✓ Security check passed: Unauthenticated access rejected with 401');

  // 2. Student / Invalid token
  const fakeTokenRes = await request('/api/admin/dashboard', {
    headers: { 'Authorization': 'Bearer student_token_xyz' }
  });
  if (fakeTokenRes.status !== 401) throw new Error('Expected 401 for invalid admin token');
  console.log('✓ Security check passed: Invalid token rejected with 401');

  // 3. Admin Login with bad credentials
  const badLogin = await request('/api/admin/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'wrongpassword' })
  });
  if (badLogin.status !== 401) throw new Error('Expected 401 for bad admin credentials');
  console.log('✓ Security check passed: Bad admin login rejected with 401');

  // 4. Admin Login with valid credentials
  const goodLogin = await request('/api/admin/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'Sonalcjoseph@2005' })
  });
  if (goodLogin.status !== 200 || !goodLogin.body.token) throw new Error('Admin login failed');
  const token = goodLogin.body.token;
  console.log('✓ Admin authenticated successfully. Issued token:', token.slice(0, 16) + '...');

  const authHeaders = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  // 5. Admin Me Endpoint
  const meRes = await request('/api/admin/me', { headers: authHeaders });
  if (meRes.status !== 200 || meRes.body.user !== 'admin') throw new Error('Failed to get admin user info');
  console.log('✓ Admin identity verified via /api/admin/me');

  // 6. Admin Dashboard KPIs
  const dashRes = await request('/api/admin/dashboard?timeframe=today', { headers: authHeaders });
  if (dashRes.status !== 200 || !dashRes.body.kpis) throw new Error('Failed to load dashboard KPIs');
  console.log('✓ Dashboard KPIs loaded:', {
    requests: dashRes.body.kpis.total_requests,
    tokens: dashRes.body.kpis.total_tokens,
    cost_inr: dashRes.body.kpis.estimated_cost_inr
  });

  // 7. Admin Users Usage
  const usersRes = await request('/api/admin/users', { headers: authHeaders });
  if (usersRes.status !== 200 || !Array.isArray(usersRes.body)) throw new Error('Failed to get users usage');
  console.log('✓ Users AI Usage endpoint returned', usersRes.body.length, 'students');

  // 8. Admin Waste Monitor
  const wasteRes = await request('/api/admin/waste', { headers: authHeaders });
  if (wasteRes.status !== 200 || wasteRes.body.potential_waste_tokens === undefined) throw new Error('Failed to get waste data');
  console.log('✓ Waste Monitor endpoint returned valid data:', wasteRes.body.potential_waste_tokens, 'waste tokens');

  // 9. Admin Cache Performance
  const cacheRes = await request('/api/admin/cache', { headers: authHeaders });
  if (cacheRes.status !== 200 || cacheRes.body.cache_hit_rate_pct === undefined) throw new Error('Failed to get cache data');
  console.log('✓ Cache Performance endpoint returned hit rate:', cacheRes.body.cache_hit_rate_pct + '%');

  // 10. Admin Pricing Config GET and POST
  const pricingRes = await request('/api/admin/pricing', { headers: authHeaders });
  if (pricingRes.status !== 200) throw new Error('Failed to get pricing');
  console.log('✓ Pricing Config endpoint returned USD to INR rate:', pricingRes.body.currency_rate_usd_to_inr);

  // 11. Admin Audit Log
  const auditRes = await request('/api/admin/audit-log', { headers: authHeaders });
  if (auditRes.status !== 200 || !Array.isArray(auditRes.body)) throw new Error('Failed to get audit log');
  console.log('✓ Admin Audit Log returned', auditRes.body.length, 'audit entries');

  // 12. Admin Export
  const exportRes = await fetch(`${BASE_URL}/api/admin/export?type=events&format=csv`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (exportRes.status !== 200) throw new Error('Failed to export CSV');
  const csvText = await exportRes.text();
  if (!csvText.includes('request_id')) throw new Error('Export CSV missing expected headers');
  console.log('✓ Admin Export endpoint returned valid CSV format');

  console.log('\n--- ALL API INTEGRATION & SECURITY TESTS PASSED! ---');
  if (serverModule && serverModule.server) {
    serverModule.server.close(() => {
      process.exit(0);
    });
  } else {
    process.exit(0);
  }
}

runApiIntegrationTests().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
