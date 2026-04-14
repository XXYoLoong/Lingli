# ============================================================
# 邻里 - 一键启动脚本 (Windows PowerShell)
# 用法: 右键 start.ps1 -> 使用 PowerShell 运行
# ============================================================

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  邻里 - 社区服务管理系统" -ForegroundColor Cyan
Write-Host "  一键启动脚本" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# --- 1. 检查依赖 ---
Write-Host "[1/4] 检查环境..." -ForegroundColor Yellow
$hasPython = Get-Command python -ErrorAction SilentlyContinue
$hasNode = Get-Command node -ErrorAction SilentlyContinue

if (-not $hasPython) { Write-Host "  [错误] 未找到 Python" -ForegroundColor Red; exit 1 }
if (-not $hasNode) { Write-Host "  [错误] 未找到 Node.js" -ForegroundColor Red; exit 1 }
Write-Host "  [OK] Python 和 Node.js 已就绪" -ForegroundColor Green

# --- 2. 后端 ---
Write-Host "`n[2/4] 启动后端..." -ForegroundColor Yellow
$BackendDir = Join-Path $ProjectRoot "Backend"

if (-not (Test-Path "$BackendDir\venv")) {
    Write-Host "  创建虚拟环境..." -ForegroundColor DarkYellow
    python -m venv "$BackendDir\venv"
}

# 修复 aiosqlite 冲突
$sqliteInit = "$BackendDir\venv\Lib\site-packages\sqlalchemy\dialects\sqlite\__init__.py"
if (Test-Path $sqliteInit) {
    $content = Get-Content $sqliteInit -Raw
    if ($content -match "^from \. import aiosqlite" -or $content -match "^# from \. import aiosqlite") {
        $content = $content -replace "from \. import aiosqlite  # noqa", "# from . import aiosqlite  # noqa - disabled"
        Set-Content $sqliteInit -Value $content -NoNewline
        Write-Host "  已修复 SQLAlchemy aiosqlite 冲突" -ForegroundColor DarkYellow
    }
}

& "$BackendDir\venv\Scripts\python.exe" -c "import fastapi" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  安装后端依赖..." -ForegroundColor DarkYellow
    & "$BackendDir\venv\Scripts\pip.exe" install fastapi uvicorn sqlalchemy pydantic pydantic-settings python-jose bcrypt python-multipart httpx python-dotenv email-validator --quiet
    Write-Host "  [OK] 后端依赖安装完成" -ForegroundColor Green
} else {
    Write-Host "  [OK] 后端依赖已安装" -ForegroundColor Green
}

# 初始化数据库
& "$BackendDir\venv\Scripts\python.exe" -c "
import sys, os
sys.path.insert(0, '$BackendDir')
os.environ['DATABASE_URL'] = 'sqlite+pysqlite:///./neighbor.db'
from app.database import engine, Base
from app.models import *
Base.metadata.create_all(bind=engine)
print('  [OK] 数据库就绪')
" 2>$null

# 插入测试数据
& "$BackendDir\venv\Scripts\python.exe" -c "
import sys, os
sys.path.insert(0, '$BackendDir')
os.environ['DATABASE_URL'] = 'sqlite+pysqlite:///./neighbor.db'
from app.database import SessionLocal
from app.models.user import UserAccount, RoleEnum, WorkerProfile
from app.models.station import ServiceStation
from app.services.auth_service import hash_password
db = SessionLocal()
if not db.query(ServiceStation).first():
    s = ServiceStation(name='测试社区服务站', code='TEST001', address='测试路1号', contact_phone='13800000000', status='active')
    db.add(s); db.commit(); db.refresh(s)
    users = [
        ('admin','13800000000','admin123456',RoleEnum.ADMIN,'系统管理员',None),
        ('manager','13800000001','manager123',RoleEnum.STATION_MANAGER,'张站长',s.id),
        ('worker','13800000002','worker123',RoleEnum.WORKER,'李师傅',s.id),
        ('resident','13800000003','resident123',RoleEnum.RESIDENT,'王居民',s.id),
    ]
    for u, p, pwd, r, n, sid in users:
        if not db.query(UserAccount).filter(UserAccount.phone == p).first():
            usr = UserAccount(username=u, phone=p, password_hash=hash_password(pwd), role=r, real_name=n, station_id=sid, is_active=True, is_verified=True)
            db.add(usr)
            if r == RoleEnum.WORKER:
                db.flush()
                db.add(WorkerProfile(user_id=usr.id, max_load=10, status='available'))
    db.commit()
    print('  [OK] 测试数据已创建')
    print('    Admin: 13800000000 / admin123456')
    print('    Manager: 13800000001 / manager123')
    print('    Worker: 13800000002 / worker123')
    print('    Resident: 13800000003 / resident123')
else:
    print('  [OK] 测试数据已存在')
db.close()
" 2>$null

# 启动后端
Write-Host "  后端服务: http://localhost:8000" -ForegroundColor Green
Write-Host "  API 文档: http://localhost:8000/docs" -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$BackendDir'; `$env:DASHSCOPE_API_KEY='sk-test'; .\venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000"

# --- 3. 前端 ---
Write-Host "`n[3/4] 启动 Web 前端..." -ForegroundColor Yellow
$FrontendDir = Join-Path $ProjectRoot "Frontend"

if (-not (Test-Path "$FrontendDir\node_modules")) {
    Write-Host "  安装前端依赖..." -ForegroundColor DarkYellow
    Set-Location $FrontendDir
    npm install
}

Write-Host "  Web 前端: http://localhost:5173" -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$FrontendDir'; npm run dev"

# --- 4. 鸿蒙端 ---
Write-Host "`n[4/4] 鸿蒙端..." -ForegroundColor Yellow
Write-Host "  鸿蒙端: 请在 DevEco Studio 中打开 f:\YL-Workspace\D-A\Lingli 并运行" -ForegroundColor DarkYellow
Write-Host "  接口地址已在 ApiClient.ets 中配置" -ForegroundColor DarkYellow

# --- 完成 ---
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  邻里系统启动完成！" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
Write-Host "  后端 API:   http://localhost:8000" -ForegroundColor White
Write-Host "  API 文档:   http://localhost:8000/docs" -ForegroundColor White
Write-Host "  Web 前端:   http://localhost:5173" -ForegroundColor White
Write-Host ""
Write-Host "  测试账号 (手机号/密码):" -ForegroundColor Yellow
Write-Host "    管理员:    13800000000 / admin123456" -ForegroundColor White
Write-Host "    站长:      13800000001 / manager123" -ForegroundColor White
Write-Host "    服务人员:  13800000002 / worker123" -ForegroundColor White
Write-Host "    居民:      13800000003 / resident123" -ForegroundColor White
Write-Host ""
Write-Host "  关闭窗口即可停止服务`n" -ForegroundColor DarkYellow

Read-Host "按 Enter 退出（服务会继续运行）"
