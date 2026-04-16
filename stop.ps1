# Copyright 2026 Jiacheng Ni
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ============================================================
# 邻里 - 停止脚本 (Windows PowerShell)
# ============================================================

Write-Host "`n停止邻里系统服务..." -ForegroundColor Yellow

# 关闭后端和前端进程
Get-Process | Where-Object { $_.MainWindowTitle -like "*uvicorn*" -or $_.MainWindowTitle -like "*vite*" } | Stop-Process -Force 2>$null

# 关闭数据库容器
docker compose down 2>$null

Write-Host "服务已停止。`n" -ForegroundColor Green
