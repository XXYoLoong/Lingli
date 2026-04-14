/**
 * 用户状态管理
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { UserAccount } from '@/types'
import { authApi } from '@/services/api'

export const useUserStore = defineStore('user', () => {
  const user = ref<UserAccount | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))

  async function login(phone: string, password: string) {
    const res = await authApi.login({ phone, password })
    token.value = res.access_token
    localStorage.setItem('token', res.access_token)
    await fetchMe()
  }

  async function fetchMe() {
    try {
      user.value = await authApi.getMe()
    } catch {
      logout()
    }
  }

  function logout() {
    user.value = null
    token.value = null
    localStorage.removeItem('token')
  }

  return { user, token, login, fetchMe, logout }
})
