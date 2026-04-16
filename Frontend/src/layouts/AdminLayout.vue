<template>
  <el-container class="layout-container">
    <el-aside :width="sidebarCollapsed ? '64px' : '220px'" class="layout-aside">
      <div class="logo">
        <span v-if="!sidebarCollapsed">邻里</span>
        <span v-else>邻</span>
      </div>
      <el-menu
        :default-active="route.path"
        :collapse="sidebarCollapsed"
        router
        class="side-menu"
      >
        <el-menu-item v-for="item in visibleMenus" :key="item.index" :index="item.index">
          <el-icon><component :is="item.icon" /></el-icon>
          <template #title>{{ item.title }}</template>
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="layout-header">
        <div class="header-left">
          <el-icon class="collapse-btn" @click="toggleSidebar">
            <Fold v-if="!sidebarCollapsed" />
            <Expand v-else />
          </el-icon>
        </div>
        <div class="header-right">
          <el-badge :value="unreadCount" :hidden="unreadCount === 0">
            <el-icon class="header-icon" @click="showMessages = true">
              <Bell />
            </el-icon>
          </el-badge>
          <el-dropdown @command="handleUserCommand">
            <span class="user-info">
              <el-avatar :size="32" :src="user?.avatar_url">
                {{ user?.real_name?.charAt(0) || user?.username?.charAt(0) || 'U' }}
              </el-avatar>
              <span class="user-name">{{ user?.real_name || user?.username }}</span>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人信息</el-dropdown-item>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      <el-main class="layout-main">
        <router-view />
      </el-main>
    </el-container>

    <!-- 消息抽屉 -->
    <el-drawer v-model="showMessages" title="消息通知" size="400px">
      <el-empty v-if="messages.length === 0" description="暂无消息" />
      <el-timeline v-else>
        <el-timeline-item
          v-for="msg in messages"
          :key="msg.id"
          :color="msg.priority === 'high' ? '#ff4d4f' : '#1677ff'"
          :timestamp="msg.created_at"
        >
          <div class="msg-item">
            <div class="msg-title">{{ msg.title }}</div>
            <div class="msg-content">{{ msg.content }}</div>
          </div>
        </el-timeline-item>
      </el-timeline>
    </el-drawer>
  </el-container>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import { useUserStore } from '@/stores/user'
import { useAppStore } from '@/stores/app'
import { messageApi } from '@/services/api'
import type { Message } from '@/types'
import {
  Odometer, Tickets, Share, MagicStick, UserFilled,
  Setting, Fold, Expand, Bell,
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()
const appStore = useAppStore()
const { user } = storeToRefs(userStore)
const { sidebarCollapsed } = storeToRefs(appStore)
const { toggleSidebar } = appStore

const showMessages = ref(false)
const unreadCount = ref(0)
const messages = ref<Message[]>([])

const menuItems = [
  {
    index: '/dashboard',
    title: '仪表盘',
    icon: Odometer,
    roles: ['resident', 'worker', 'station_manager', 'dispatcher', 'operator', 'admin'],
  },
  {
    index: '/orders',
    title: '工单中心',
    icon: Tickets,
    roles: ['resident', 'worker', 'station_manager', 'dispatcher', 'operator', 'admin'],
  },
  {
    index: '/dispatch',
    title: '调度中心',
    icon: Share,
    roles: ['worker', 'station_manager', 'dispatcher', 'admin'],
  },
  {
    index: '/ai-review',
    title: 'AI 审核',
    icon: MagicStick,
    roles: ['station_manager', 'operator', 'admin'],
  },
  {
    index: '/users',
    title: '用户管理',
    icon: UserFilled,
    roles: ['admin'],
    superOnly: true,
  },
  {
    index: '/settings',
    title: '系统设置',
    icon: Setting,
    roles: ['admin'],
    superOnly: true,
  },
] as const

const visibleMenus = computed(() => {
  const role = user.value?.role
  if (!role) return menuItems.filter((item) => !item.superOnly)
  return menuItems.filter((item) => {
    if (!item.roles.includes(role)) return false
    if (item.superOnly && !userStore.isSuperAdmin()) return false
    return true
  })
})

onMounted(async () => {
  if (userStore.token) {
    await userStore.fetchMe()
    try {
      const countRes = await messageApi.unreadCount()
      unreadCount.value = countRes.count
      const msgRes = await messageApi.list({ is_read: 'false' })
      messages.value = msgRes
    } catch {
      // ignore
    }
  }
})

function handleUserCommand(command: string) {
  if (command === 'profile') {
    router.push('/settings?tab=security')
    return
  }
  if (command === 'logout') {
    userStore.logout()
    router.replace('/login')
    window.setTimeout(() => {
      if (window.location.pathname !== '/login') {
        window.location.replace('/login')
      }
    }, 0)
  }
}
</script>

<style scoped lang="scss">
.layout-container {
  height: 100vh;
}

.layout-aside {
  background: linear-gradient(180deg, #0b1f3d 0%, #001529 100%);
  transition: width 0.3s;
  overflow: hidden;
}

.logo {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 20px;
  font-weight: bold;
  letter-spacing: 2px;
}

.side-menu {
  border-right: none;
  background-color: transparent;

  :deep(.el-menu-item) {
    color: rgba(255, 255, 255, 0.65);

    &.is-active {
      background-color: #1677ff;
      color: #fff;
    }

    &:hover {
      color: #fff;
      background-color: rgba(255, 255, 255, 0.08);
    }
  }
}

.layout-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(8px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.06);
  padding: 0 20px;
}

.header-left {
  display: flex;
  align-items: center;
}

.collapse-btn {
  font-size: 20px;
  cursor: pointer;
  color: #666;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 20px;
}

.header-icon {
  font-size: 20px;
  cursor: pointer;
  color: #666;

  &:hover {
    color: #1677ff;
  }
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.user-name {
  font-size: 14px;
  color: #333;
}

.layout-main {
  background: #f4f6fb;
  padding: 20px 24px;
  overflow-y: auto;
}

.msg-item {
  .msg-title {
    font-weight: 500;
    font-size: 14px;
    color: #333;
  }
  .msg-content {
    font-size: 12px;
    color: #999;
    margin-top: 4px;
  }
}
</style>
