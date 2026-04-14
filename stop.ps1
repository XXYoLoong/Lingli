# ============================================================
# 邻里 - 停止脚本 (Windows PowerShell)
# ============================================================

Write-Host "`n停止邻里系统服务..." -ForegroundColor Yellow

# 关闭后端和前端进程
Get-Process | Where-Object { $_.MainWindowTitle -like "*uvicorn*" -or $_.MainWindowTitle -like "*vite*" } | Stop-Process -Force 2>$null

# 关闭数据库容器
docker compose down 2>$null

Write-Host "服务已停止。`n" -ForegroundColor Green
