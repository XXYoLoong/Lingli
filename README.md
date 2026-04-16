<h1 align="center">邻里 Lingli</h1>

<p align="center">
  面向社区养老与便民服务场景的多端协同系统：HarmonyOS 移动端、Web 管理端、FastAPI 后端与 AI 辅助审核能力。
</p>

<p align="center">
  <a href="./README.md">简体中文</a> ｜ <a href="./README_EN.md">English</a>
</p>

<p align="center">
  <a href="https://github.com/XXYoLoong/Lingli"><img src="https://img.shields.io/badge/GitHub-Lingli-181717?logo=github" alt="GitHub"></a>
  <img src="https://img.shields.io/badge/License-Apache--2.0-blue" alt="License">
  <img src="https://img.shields.io/badge/HarmonyOS-ArkTS-red" alt="HarmonyOS ArkTS">
  <img src="https://img.shields.io/badge/Web-Vue%203%20%2B%20TypeScript-42b883" alt="Vue TypeScript">
  <img src="https://img.shields.io/badge/Backend-FastAPI-009688" alt="FastAPI">
  <img src="https://img.shields.io/badge/AI-Qwen%20Assistant-7c3aed" alt="Qwen">
</p>

<p align="center">
  <a href="https://harmonycare.cn">在线站点</a> ｜ <a href="https://www.bilibili.com/video/BV1PNdaBvE5y/">Web 演示</a> ｜ <a href="https://www.bilibili.com/video/BV194daBJE3z/">鸿蒙实机演示</a>
</p>

## 项目简介

邻里是一个围绕社区服务闭环构建的全栈项目。系统覆盖居民服务申请、服务人员签到到场、工单调度、AI 审核、消息通知、用户管理、统计看板与移动端设备交互等流程，目标是在社区养老、家庭服务、便民协作等场景中提供可落地的数字化服务基础设施。

项目由三个核心端组成：

| 模块 | 技术栈 | 说明 |
| --- | --- | --- |
| HarmonyOS 移动端 | ArkTS / ArkUI / HarmonyOS NEXT | 居民端申请服务、服务人员签到与结果回填、智感握姿、碰一碰与抓一抓分享 |
| Web 管理端 | Vue 3 / TypeScript / Element Plus / ECharts | 管理后台、工单中心、调度中心、AI 审核、用户与系统设置 |
| 后端服务 | FastAPI / SQLAlchemy / Alembic / SQLite | 认证、工单、调度、站点、消息、统计、AI 审核与用户管理接口 |

## 核心能力

1. 居民服务申请：维修、保洁、助餐、陪诊、代办、照护等服务类型。
2. 服务人员移动工作流：工单领取、到场签到、定位校验、扫码服务码、现场拍照、结果回填。
3. 管理端工单闭环：工单列表、状态流转、分派候选、服务站点、用户权限与统计看板。
4. AI 辅助审核：对工单内容、服务结果与异常情况提供辅助判断与记录。
5. HarmonyOS 场景能力：智感握姿调整悬浮导航位置，碰一碰与抓一抓触发分享。
6. 多角色权限：居民、服务人员、站点管理员、调度员、运营人员与超级管理员。
7. 可部署工程结构：前后端分离、移动端独立模块、部署脚本与数据库迁移文件齐备。

## 界面预览

### Web 管理端

| 仪表盘 | 工单中心 |
| --- | --- |
| ![Dashboard](./docs/images/web/dashboard.png) | ![Orders](./docs/images/web/orders.png) |

| 调度中心 | AI 审核中心 |
| --- | --- |
| ![Dispatch](./docs/images/web/dispatch.png) | ![AI Review](./docs/images/web/ai-review.png) |

| 用户管理 | 系统设置 |
| --- | --- |
| ![Users](./docs/images/web/users.png) | ![Settings](./docs/images/web/settings.png) |

### HarmonyOS 移动端

| 首页 | 服务申请 | 签到/结果 |
| --- | --- | --- |
| ![Mobile 1](./docs/images/mobile/mobile-1.jpg) | ![Mobile 2](./docs/images/mobile/mobile-2.jpg) | ![Mobile 3](./docs/images/mobile/mobile-3.jpg) |

| 消息与我的 | 交互能力 | 工作流 |
| --- | --- | --- |
| ![Mobile 4](./docs/images/mobile/mobile-4.jpg) | ![Mobile 5](./docs/images/mobile/mobile-5.jpg) | ![Mobile 6](./docs/images/mobile/mobile-6.jpg) |

| 服务详情 | 页面交互 | 结果反馈 |
| --- | --- | --- |
| ![Mobile 7](./docs/images/mobile/mobile-7.jpg) | ![Mobile 8](./docs/images/mobile/mobile-8.jpg) | ![Mobile 9](./docs/images/mobile/mobile-9.jpg) |

## 演示视频

| 标题 | 链接 |
| --- | --- |
| 邻里鸿蒙实机运行演示 | https://www.bilibili.com/video/BV194daBJE3z/ |
| ElderSmart+综合实机演示 | https://www.bilibili.com/video/BV1U6deBEEWy/ |
| 邻里软件演示 | https://www.bilibili.com/video/BV1AMdaBYEFL/ |
| 基于康复治疗学的智慧教育智能体系统 | https://www.bilibili.com/video/BV1FVdaBFESb/ |
| 邻里社区管理系统web端 | https://www.bilibili.com/video/BV1PNdaBvE5y/ |

## 目录结构

```text
Lingli/
├── Backend/                 # FastAPI backend service
│   ├── app/api/             # REST API routers
│   ├── app/models/          # SQLAlchemy models
│   ├── app/schemas/         # Pydantic schemas
│   ├── app/services/        # Business services
│   └── alembic/             # Database migrations
├── Frontend/                # Vue 3 management console
│   └── src/
├── Lingli/                  # HarmonyOS ArkTS application
│   └── entry/src/main/ets/
├── docs/images/             # README screenshots
├── tools/                   # Deployment and utility scripts
└── docker-compose.yml
```

## 快速开始

### 后端

```bash
cd Backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Web 管理端

```bash
cd Frontend
npm install
npm run dev
```

### HarmonyOS 移动端

使用 DevEco Studio 6 打开 `Lingli/` 目录，选择 `entry@default` 模块构建。命令行构建可参考：

```powershell
& "F:\DevEco Studio 6.0.0\tools\node\node.exe" "F:\DevEco Studio 6.0.0\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```

## API 模块

| 模块 | 路径 | 说明 |
| --- | --- | --- |
| 认证 | `/api/v1/auth` | 注册、登录、用户身份 |
| 工单 | `/api/v1/orders` | 服务申请、签到、完成、查询 |
| 调度 | `/api/v1/dispatch` | 候选服务人员计算与派单 |
| 消息 | `/api/v1/messages` | 消息列表、未读数、已读状态 |
| 统计 | `/api/v1/stats` | 看板指标与趋势数据 |
| 站点 | `/api/v1/stations` | 社区服务站点管理 |
| AI | `/api/v1/ai` | AI 审核任务与结果 |
| 用户 | `/api/v1/users` | 用户列表、角色与管理 |

## 技术栈

| 类型 | 技术 |
| --- | --- |
| 移动端 | HarmonyOS NEXT, ArkTS, ArkUI, ShareKit, MultimodalAwarenessKit |
| 前端 | Vue 3, TypeScript, Vite, Pinia, Vue Router, Element Plus, ECharts |
| 后端 | FastAPI, SQLAlchemy, Alembic, Pydantic, SQLite |
| AI | 阿里通义 / Qwen API |
| 部署 | Docker Compose, PowerShell, Shell scripts |

## License

This project is licensed under the Apache License 2.0. See [LICENSE](./LICENSE) for details.

## Maintainer

**Yoloong (倪家诚)** focuses on **HarmonyOS / ArkUI application development, AI capability integration, full-stack web engineering, and agent-oriented system building**. His work spans the full implementation path of a software project, including **product-facing UI development, backend services, API integration, deployment, and iterative delivery**. Current projects mainly center on **smart healthcare, intelligent interaction, productivity tools, and scenario-driven software systems**. More work and ongoing projects can be found at **[yoloong.com](https://yoloong.com)** and **[harmonycare.cn](https://harmonycare.cn)**.

**游龙（倪家诚）**，持续从事 **HarmonyOS / ArkUI 应用开发、AI 能力集成、Web 全栈工程实现与智能体系统构建**。项目实践覆盖软件落地的完整链路，包括 **面向产品的界面开发、后端服务实现、接口集成、部署上线与持续迭代**。当前工作主要围绕 **智慧健康、智能交互、效率工具与场景化软件系统** 展开。更多项目与持续更新内容见 **[yoloong.com](https://yoloong.com)** 与 **[harmonycare.cn](https://harmonycare.cn)**。
