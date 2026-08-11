$VpsHost = "213.133.97.141"
$VpsUser = "root"
$RemotePath = "/var/www/jeeni"
$LocalWebBuild = "flutter\build\web"

Write-Host "=== Jeeni Web Deploy ===" -ForegroundColor Cyan

# 1. Create archive
$archive = "web.tar.gz"
Write-Host "Compressing build/web into $archive..." -ForegroundColor Yellow
python -c "import tarfile, os; t=tarfile.open('web.tar.gz','w:gz'); t.add('flutter/build/web', arcname='.'); t.close(); print(f'Archive: {os.path.getsize(chr(39)+chr(119)+chr(101)+chr(98)+chr(46)+chr(116)+chr(97)+chr(114)+chr(46)+chr(103)+chr(122)+chr(39))} bytes')"
python -c "import tarfile, os; t=tarfile.open('web.tar.gz','w:gz'); t.add('flutter/build/web', arcname='.'); t.close(); sz=os.path.getsize('web.tar.gz'); print(f'Archive created ({sz} bytes)')"

# 2. Upload via SCP
Write-Host "Uploading $archive to VPS..." -ForegroundColor Yellow
$scpDest = "${VpsUser}@${VpsHost}:/tmp/${archive}"
scp -o StrictHostKeyChecking=no $archive $scpDest
if ($LASTEXITCODE -ne 0) { Write-Host "SCP failed!" -ForegroundColor Red; exit 1 }

# 3. Extract and restart on VPS
Write-Host "Extracting archive on VPS..." -ForegroundColor Yellow
$sshTarget = "${VpsUser}@${VpsHost}"
ssh -o StrictHostKeyChecking=no $sshTarget "mkdir -p ${RemotePath}/public/app && tar -xzf /tmp/${archive} -C ${RemotePath}/public/app && rm /tmp/${archive}"
if ($LASTEXITCODE -ne 0) { Write-Host "SSH extract failed!" -ForegroundColor Red; exit 1 }

Write-Host "Restarting PM2..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no $sshTarget "pm2 restart all"

# 4. Cleanup local archive
Remove-Item $archive -ErrorAction SilentlyContinue

Write-Host "*** FLUTTER WEB APP DEPLOYED TO http://${VpsHost}:3000/app ***" -ForegroundColor Green
