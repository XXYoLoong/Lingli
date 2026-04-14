import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useUserStore } from '@/stores/user'

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
        meta: { title: '驾驶舱', roles: ['station_manager', 'operator', 'admin', 'dispatcher'] },
      },
      {
        path: 'orders',
        name: 'Orders',
        component: () => import('@/pages/OrderCenter.vue'),
        meta: { title: '工单中心', roles: ['station_manager', 'operator', 'admin', 'dispatcher'] },
      },
      {
        path: 'dispatch',
        name: 'Dispatch',
        component: () => import('@/pages/DispatchCenter.vue'),
        meta: { title: '调度中心', roles: ['station_manager', 'admin', 'dispatcher'] },
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
        meta: { title: '用户管理', roles: ['station_manager', 'admin'] },
      },
      {
        path: 'settings',
        name: 'Settings',
        component: () => import('@/pages/SystemSettings.vue'),
        meta: { title: '系统设置', roles: ['admin'] },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, _from, next) => {
  if (to.meta.public) {
    next()
    return
  }

  const userStore = useUserStore()
  if (!userStore.token) {
    next({ name: 'Login', query: { redirect: to.fullPath } })
    return
  }

  // 角色权限检查
  const roles = to.meta.roles as string[] | undefined
  if (roles && userStore.user?.role && !roles.includes(userStore.user.role)) {
    next({ name: 'Dashboard' })
    return
  }

  next()
})

export default router
