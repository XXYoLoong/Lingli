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

/**
 * 用户状态管理
 */
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { RegisterRequest, UserAccount } from '@/types'
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

  async function register(data: RegisterRequest) {
    await authApi.register(data)
  }

  async function fetchMe() {
    try {
      user.value = await authApi.getMe()
      return user.value
    } catch {
      logout()
      throw new Error('获取用户信息失败')
    }
  }

  function logout() {
    user.value = null
    token.value = null
    localStorage.removeItem('token')
  }

  function isSuperAdmin() {
    const name = user.value?.real_name || ''
    const username = user.value?.username || ''
    return name === '小小游龙' || username === '小小游龙' || username === 'xiaoxiaoyoulong'
  }

  return { user, token, login, register, fetchMe, logout, isSuperAdmin }
})
