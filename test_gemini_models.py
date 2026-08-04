import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('213.133.97.141', username='root', password='AfjbCUvqgdpST8', timeout=30)

cmd = """
cd /var/www/jeeni && node -e "
const { GoogleGenAI } = require('@google/genai');
require('dotenv').config();
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

async function testModel(m) {
  try {
    const res = await ai.models.generateContent({
      model: m,
      contents: [{ role: 'user', parts: [{ text: 'Hi' }] }]
    });
    console.log('MODEL SUCCESS:', m, res.text ? res.text.slice(0, 50) : 'NO TEXT');
  } catch (err) {
    console.log('MODEL FAILED:', m, err.message);
  }
}

(async () => {
  await testModel('gemini-2.5-flash');
  await testModel('gemini-2.0-flash');
  await testModel('gemini-1.5-flash');
  await testModel('gemini-2.5-pro');
  await testModel('gemini-1.5-pro');
})();
"
"""

stdin, stdout, stderr = ssh.exec_command(cmd)
print(stdout.read().decode('utf-8', errors='ignore'))
print(stderr.read().decode('utf-8', errors='ignore'))

ssh.close()
