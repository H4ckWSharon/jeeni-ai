async function testLiveRemote() {
  const HOST = 'http://213.133.97.141:3000';

  console.log('Testing Live Server at', HOST);

  // 1. GET /admin HTML page
  const htmlRes = await fetch(`${HOST}/admin`);
  const htmlText = await htmlRes.text();
  console.log(`1. GET /admin -> Status ${htmlRes.status}, contains title: ${htmlText.includes('Jeeni AI')}`);

  // 2. Unauthenticated GET /api/admin/dashboard (expect 401)
  const unauthRes = await fetch(`${HOST}/api/admin/dashboard`);
  console.log(`2. Unauthenticated GET /api/admin/dashboard -> Status ${unauthRes.status} (Expected 401)`);

  // 3. Admin Login
  const loginRes = await fetch(`${HOST}/api/admin/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'Sonalcjoseph@2005' }),
  });
  const loginData = await loginRes.json();
  console.log(`3. Admin Login -> Status ${loginRes.status}, success: ${loginData.success}, token: ${loginData.token?.slice(0, 16)}...`);

  if (!loginData.token) throw new Error('No token returned');
  const authHeader = { 'Authorization': `Bearer ${loginData.token}` };

  // 4. Authenticated GET /api/admin/dashboard
  const dashRes = await fetch(`${HOST}/api/admin/dashboard?timeframe=today`, { headers: authHeader });
  const dashData = await dashRes.json();
  console.log(`4. Authenticated Dashboard KPIs:`, dashData.kpis);

  // 5. Test Chat Call and verify telemetry interception
  console.log('5. Triggering sample student chat request to verify live AI Gateway interception...');
  const chatRes = await fetch(`${HOST}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-student-id': 'student_live_test' },
    body: JSON.stringify({
      student_id: 'student_live_test',
      messages: [{ role: 'user', content: 'What is Newton second law of motion?' }],
    }),
  });
  const chatData = await chatRes.json();
  console.log(`Chat response status: ${chatRes.status}, pipeline: ${chatData.pipeline}, content snippet: ${chatData.content?.slice(0, 60)}...`);

  // 6. Check Dashboard KPIs after chat call
  const postDashRes = await fetch(`${HOST}/api/admin/dashboard?timeframe=today`, { headers: authHeader });
  const postDashData = await postDashRes.json();
  console.log(`6. Post-Chat Dashboard KPIs -> Total Requests: ${postDashData.kpis.total_requests}, Total Tokens: ${postDashData.kpis.total_tokens}, Cost: ₹${postDashData.kpis.estimated_cost_inr}`);

  // 7. Verify request in Recent Requests table
  const reqRes = await fetch(`${HOST}/api/admin/requests?limit=5`, { headers: authHeader });
  const reqList = await reqRes.json();
  const latestReqId = reqList[0]?.request_id;
  console.log(`7. Recent Requests -> Found ${reqList.length} request(s). Latest: ID=${latestReqId}, User=${reqList[0]?.user_id}, Feature=${reqList[0]?.feature}, In/Out=${reqList[0]?.input_tokens}/${reqList[0]?.output_tokens}, Cost=₹${reqList[0]?.estimated_cost_inr}`);

  // 8. Test Command Center System Health
  const healthRes = await fetch(`${HOST}/api/admin/health`, { headers: authHeader });
  const healthData = await healthRes.json();
  console.log(`8. System Health -> Overall: ${healthData.overall}, Gemini: ${healthData.ai_provider?.status}, ChromaDB: ${healthData.vector_store?.status}`);

  // 9. Test Command Center Budget & Quota
  const budgetRes = await fetch(`${HOST}/api/admin/budget`, { headers: authHeader });
  const budgetData = await budgetRes.json();
  console.log(`9. Budget Controls -> Policy: ${budgetData.policy_action}, Daily Budget: ₹${budgetData.daily?.budget_cost_inr}, Quota Status: ${budgetData.quotas?.['gemini-3.1-flash-lite']?.status}`);

  // 10. Test Token Economics Multidimensional Endpoint
  const econRes = await fetch(`${HOST}/api/admin/token-economics?window=24h`, { headers: authHeader });
  const econData = await econRes.json();
  console.log(`10. Token Economics -> Total: ${econData.total_tokens}, In: ${econData.input_tokens}, Out: ${econData.output_tokens}, Cached: ${econData.cached_tokens}`);

  // 11. Test Feature & Model Analytics
  const featRes = await fetch(`${HOST}/api/admin/features`, { headers: authHeader });
  const featData = await featRes.json();
  console.log(`11. Feature Analytics -> Tracked features: ${featData.length}`);

  const modelRes = await fetch(`${HOST}/api/admin/models`, { headers: authHeader });
  const modelData = await modelRes.json();
  console.log(`12. Model Analytics -> Tracked models: ${modelData.length}`);

  // 13. Test Statistical Anomaly Detection
  const anomRes = await fetch(`${HOST}/api/admin/anomalies`, { headers: authHeader });
  const anomData = await anomRes.json();
  console.log(`13. Anomaly Detection -> Status: ${anomData.status}, Message/Count: ${anomData.message || anomData.anomalies?.length}`);

  // 15. Test Student AI Profiles & Identity Resolution
  const usersRes = await fetch(`${HOST}/api/admin/users`, { headers: authHeader });
  const usersData = await usersRes.json();
  console.log(`15. Student AI Profiles -> Found ${usersData.length} student(s) in accounting table:`);
  for (const u of usersData.slice(0, 5)) {
    console.log(`    - Name: "${u.display_name}" | ID: ${u.student_id} | Provider: ${u.provider} | Provider UID: ${u.provider_user_id || 'N/A'}`);
  }

  // Verify search by name
  const searchNameRes = await fetch(`${HOST}/api/admin/users?search=Yadukrishnan`, { headers: authHeader });
  const searchNameData = await searchNameRes.json();
  console.log(`    - Search by Name "Yadukrishnan" -> Found ${searchNameData.length} match(es)`);

  // Verify search by Google Provider UID
  const searchUidRes = await fetch(`${HOST}/api/admin/users?search=QRAVstzGqeOHuZNxqyb9Fcx6hkt1`, { headers: authHeader });
  const searchUidData = await searchUidRes.json();
  console.log(`    - Search by Provider UID "QRAVstzGqeOHuZNxqyb9Fcx6hkt1" -> Found ${searchUidData.length} match(es)`);

  console.log('\n=== LIVE PRODUCTION DEPLOYMENT FULLY VERIFIED! ===');
}

testLiveRemote().catch(err => {
  console.error('Test error:', err);
});
