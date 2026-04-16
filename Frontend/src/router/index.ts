/*
 * Copyright 2026 Jiacheng Ni
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'

const ALL_ROLES = ['resident', 'worker', 'station_manager', 'operator', 'admin', 'dispatcher']

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/pages/Login.vue'),
    meta: { public: true },
  },
  {
    path: '/',
    component: () => import('@/layouts/AdminLayout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/pages/Dashboard.vue'),
        meta: { title: '仪表盘', roles: ALL_ROLES },
      },
      {
        path: 'orders',
        name: 'Orders',
        component: () => import('@/pages/OrderCenter.vue'),
        meta: { title: '工单中心', roles: ALL_ROLES },
      },
      {
        path: 'dispatch',
        name: 'Dispatch',
        component: () => import('@/pages/DispatchCenter.vue'),
        meta: { title: '调度中心', roles: ['worker', 'station_manager', 'admin', 'dispatcher'] },
      },
      {
        path: 'ai-review',
        name: 'AIReview',
        component: () => import('@/pages/AIReviewCenter.vue'),
        meta: { title: 'AI 审核中心', roles: ['station_manager', 'operator', 'admin'] },
      },
      {
        path: 'users',
        name: 'Users',
        component: () => import('@/pages/UserManagement.vue'),
        meta: { title: '用户管理', roles: ['admin'], superOnly: true },
      },
      {
        path: 'settings',
        name: 'Settings',
        component: () => import('@/pages/SystemSettings.vue'),
        meta: { title: '系统设置', roles: ['admin'], superOnly: true },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

function getHomeRouteByRole(): string {
  return '/orders'
}

router.beforeEach(async (to) => {
  if (to.meta.public) {
    return true
  }

  const userStore = useUserStore()
  if (!userStore.token) {
    return { name: 'Login', query: { redirect: to.fullPath } }
  }

  if (!userStore.user) {
    try {
      await userStore.fetchMe()
    } catch {
      return { name: 'Login', query: { redirect: to.fullPath } }
    }
  }

  const roles = to.meta.roles as string[] | undefined
  const currentRole = userStore.user?.role
  if (roles && currentRole && !roles.includes(currentRole)) {
    return getHomeRouteByRole()
  }
  if (to.meta.superOnly && !userStore.isSuperAdmin()) {
    return '/orders'
  }
  return true
})

export default router
