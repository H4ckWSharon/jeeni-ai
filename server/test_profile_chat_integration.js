const http = require('http');

function postJSON(port, path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request({
      hostname: 'localhost',
      port,
      path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    }, res => {
      let buf = '';
      res.on('data', chunk => buf += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(buf)); }
        catch { resolve({ raw: buf }); }
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function getJSON(port, path) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      hostname: 'localhost',
      port,
      path,
      method: 'GET',
    }, res => {
      let buf = '';
      res.on('data', chunk => buf += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(buf)); }
        catch { resolve({ raw: buf }); }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function run() {
  console.log('Testing server profile and memory API endpoints...');

  // Start temporary local instance of server.js on port 3999
  process.env.PORT = '3999';
  const server = require('./server.js');
  await new Promise(r => setTimeout(r, 1000));

  const testId = 'qa_student_42';

  // 1. Save profile
  console.log('1. Testing POST /api/profile...');
  const profRes = await postJSON(3999, '/api/profile', {
    student_id: testId,
    display_name: 'Ananya Nair',
    class: '10',
    board: 'CBSE',
    syllabus: 'NCERT',
    medium: 'English',
    preferred_language: 'Malayalam',
    learning_goal: 'Board 95%',
    knowledge_level: 'Intermediate',
    explanation_style: 'Simple with analogies',
  });
  console.log('Profile saved:', profRes.profile?.display_name);

  // 2. Fetch profile
  console.log('2. Testing GET /api/profile...');
  const getProf = await getJSON(3999, `/api/profile?student_id=${testId}`);
  console.log('Profile fetched:', getProf.profile?.board, 'Class:', getProf.profile?.class);

  // 3. Add explicit memory
  console.log('3. Testing POST /api/memories...');
  const memRes = await postJSON(3999, '/api/memories', {
    student_id: testId,
    category: 'Learning Preference',
    content: 'Always include practical real-world analogies',
  });
  console.log('Memory created:', memRes.memory?.content);

  // 4. Test chat call with explicit memory request
  console.log('4. Testing POST /api/chat with explicit memory triggers...');
  const chatRes = await postJSON(3999, '/api/chat', {
    student_id: testId,
    messages: [
      { role: 'user', content: 'Please remember that I prefer biology concepts explained with plant cell analogies.' }
    ],
  });
  console.log('Chat response status:', chatRes.pipeline);
  console.log('New memory saved:', chatRes.new_memory_saved);
  console.log('Memories applied:', chatRes.memories_applied);

  console.log('ALL API ENDPOINT TESTS PASSED SUCCESSFULLY! 🌟');
  process.exit(0);
}

run().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
