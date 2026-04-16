<!--
  Copyright 2026 Jiacheng Ni
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
      http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

<template>
  <div class="user-management">
    <el-alert
      v-if="!isSuperAdmin"
      title="仅小小游龙账号可管理用户"
      type="warning"
      :closable="false"
      show-icon
      class="mb-16"
    />
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" size="small" :disabled="!isSuperAdmin" @click="openCreateDialog">添加用户</el-button>
        </div>
      </template>

      <el-form :inline="true" :model="queryParams">
        <el-form-item label="角色">
          <el-select v-model="queryParams.role" placeholder="全部" clearable style="width: 160px">
            <el-option label="居民" value="resident" />
            <el-option label="服务人员" value="worker" />
            <el-option label="站长" value="station_manager" />
            <el-option label="调度员" value="dispatcher" />
            <el-option label="运营人员" value="operator" />
            <el-option label="管理员" value="admin" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadUsers">查询</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="users" v-loading="loading" stripe>
        <el-table-column prop="username" label="用户名" width="120" />
        <el-table-column prop="phone" label="手机号" width="140" />
        <el-table-column prop="email" label="邮箱" width="220" show-overflow-tooltip />
        <el-table-column prop="real_name" label="姓名" width="100" />
        <el-table-column prop="role" label="角色" width="120">
          <template #default="{ row }">
            <el-tag :type="roleType(row.role)" size="small">{{ roleLabel(row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="is_active" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'danger'" size="small">
              {{ row.is_active ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" link @click="editUser(row)">编辑</el-button>
            <el-button size="small" type="primary" link :disabled="!isSuperAdmin" @click="openEmailDialog(row)">维护邮箱</el-button>
            <el-button size="small" type="warning" link :disabled="!isSuperAdmin" @click="openResetPwdDialog(row)">重置密码</el-button>
            <el-button size="small" :type="row.is_active ? 'danger' : 'success'" link @click="toggleUserStatus(row)">
              {{ row.is_active ? '停用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 添加/编辑用户对话框 -->
    <el-dialog v-model="showAddDialog" :title="editingUser ? '编辑用户' : '添加用户'" width="500px">
      <el-form :model="userForm" label-width="80px">
        <el-form-item label="用户名">
          <el-input v-model="userForm.username" :disabled="!!editingUser" />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="userForm.phone" :disabled="!!editingUser" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="userForm.email" />
        </el-form-item>
        <el-form-item label="密码" v-if="!editingUser">
          <el-input v-model="userForm.password" type="password" show-password />
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="userForm.real_name" />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="userForm.role" style="width: 100%">
            <el-option label="居民" value="resident" />
            <el-option label="服务人员" value="worker" />
            <el-option label="站长" value="station_manager" />
            <el-option label="调度员" value="dispatcher" />
            <el-option label="运营人员" value="operator" />
            <el-option label="管理员" value="admin" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAddDialog = false">取消</el-button>
        <el-button type="primary" @click="saveUser">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showResetPwdDialog" title="重置用户密码" width="420px">
      <el-form label-width="90px">
        <el-form-item label="用户">
          <el-input :value="resetPwdTarget?.username || ''" disabled />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="resetPwdForm.new_password" type="password" show-password />
        </el-form-item>
        <el-form-item label="确认密码">
          <el-input v-model="resetPwdForm.confirm_password" type="password" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showResetPwdDialog = false">取消</el-button>
        <el-button type="primary" :loading="resetPwdSaving" @click="submitResetPwd">确认重置</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showEmailDialog" title="维护用户邮箱" width="420px">
      <el-form label-width="90px">
        <el-form-item label="用户">
          <el-input :value="emailTarget?.username || ''" disabled />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="emailForm.email" placeholder="请输入邮箱地址" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEmailDialog = false">取消</el-button>
        <el-button type="primary" :loading="emailSaving" @click="submitEmailUpdate">保存邮箱</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, reactive, onMounted } from 'vue'
import type { UserAccount } from '@/types'
import { ElMessage, ElMessageBox } from 'element-plus'
import { userApi } from '@/services/api'
import { useUserStore } from '@/stores/user'

const loading = ref(false)
const users = ref<UserAccount[]>([])
const showAddDialog = ref(false)
const showResetPwdDialog = ref(false)
const showEmailDialog = ref(false)
const resetPwdSaving = ref(false)
const emailSaving = ref(false)
const editingUser = ref<UserAccount | null>(null)
const resetPwdTarget = ref<UserAccount | null>(null)
const emailTarget = ref<UserAccount | null>(null)
const userStore = useUserStore()
const isSuperAdmin = computed(() => userStore.isSuperAdmin())
const userForm = reactive({
  username: '',
  phone: '',
  email: '',
  password: '',
  real_name: '',
  role: 'resident' as UserAccount['role'],
})
const resetPwdForm = reactive({
  new_password: '',
  confirm_password: '',
})
const emailForm = reactive({
  email: '',
})

const queryParams = reactive({ role: '' })

function openCreateDialog() {
  editingUser.value = null
  userForm.username = ''
  userForm.phone = ''
  userForm.email = ''
  userForm.password = ''
  userForm.real_name = ''
  userForm.role = 'resident'
  showAddDialog.value = true
}

function roleType(role: string) {
  const map: Record<string, string> = {
    resident: '', worker: 'success', station_manager: 'warning',
    dispatcher: 'primary', operator: 'info', admin: 'danger',
  }
  return map[role] || ''
}

function roleLabel(role: string) {
  const map: Record<string, string> = {
    resident: '居民', worker: '服务人员', station_manager: '站长',
    dispatcher: '调度员', operator: '运营人员', admin: '管理员',
  }
  return map[role] || role
}

async function loadUsers() {
  if (!isSuperAdmin.value) {
    users.value = []
    return
  }
  loading.value = true
  try {
    const params: Record<string, string> = {}
    if (queryParams.role) params.role = queryParams.role
    users.value = await userApi.list(params)
  } catch {
    ElMessage.error('用户数据加载失败')
  } finally {
    loading.value = false
  }
}

function editUser(user: UserAccount) {
  editingUser.value = user
  userForm.username = user.username
  userForm.phone = user.phone
  userForm.email = user.email || ''
  userForm.real_name = user.real_name || ''
  userForm.role = user.role
  showAddDialog.value = true
}

function openResetPwdDialog(user: UserAccount) {
  if (!isSuperAdmin.value) return
  resetPwdTarget.value = user
  resetPwdForm.new_password = ''
  resetPwdForm.confirm_password = ''
  showResetPwdDialog.value = true
}

function openEmailDialog(user: UserAccount) {
  if (!isSuperAdmin.value) return
  emailTarget.value = user
  emailForm.email = user.email || ''
  showEmailDialog.value = true
}

function toggleUserStatus(user: UserAccount) {
  if (!isSuperAdmin.value) return
  ElMessageBox.confirm(`确定要${user.is_active ? '停用' : '启用'}用户 ${user.username} 吗？`, '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning',
  }).then(async () => {
    await userApi.updateStatus(user.id, !user.is_active)
    ElMessage.success('操作成功')
    loadUsers()
  }).catch(() => {})
}

async function saveUser() {
  if (!isSuperAdmin.value) return
  if (editingUser.value) {
    await userApi.update(editingUser.value.id, {
      real_name: userForm.real_name || undefined,
      role: userForm.role,
      email: userForm.email || undefined,
    })
    ElMessage.success('用户信息已更新')
    showAddDialog.value = false
    editingUser.value = null
    await loadUsers()
    return
  }
  if (!userForm.username || !userForm.phone || !userForm.password) {
    ElMessage.warning('请填写完整信息')
    return
  }
  await userApi.create({
    username: userForm.username,
    phone: userForm.phone,
    email: userForm.email || undefined,
    password: userForm.password,
    real_name: userForm.real_name || undefined,
    role: userForm.role,
  })
  ElMessage.success('用户已创建')
  showAddDialog.value = false
  editingUser.value = null
  userForm.username = ''
  userForm.phone = ''
  userForm.email = ''
  userForm.password = ''
  userForm.real_name = ''
  userForm.role = 'resident'
  loadUsers()
}

async function submitEmailUpdate() {
  if (!emailTarget.value) return
  if (!emailForm.email) {
    ElMessage.warning('请输入邮箱')
    return
  }
  emailSaving.value = true
  try {
    await userApi.updateEmail(emailTarget.value.id, emailForm.email)
    ElMessage.success('邮箱已更新')
    showEmailDialog.value = false
    await loadUsers()
  } finally {
    emailSaving.value = false
  }
}

async function submitResetPwd() {
  if (!resetPwdTarget.value) return
  if (!resetPwdForm.new_password || !resetPwdForm.confirm_password) {
    ElMessage.warning('请填写完整密码信息')
    return
  }
  if (resetPwdForm.new_password.length < 8) {
    ElMessage.warning('新密码至少8位')
    return
  }
  if (resetPwdForm.new_password !== resetPwdForm.confirm_password) {
    ElMessage.warning('两次输入的新密码不一致')
    return
  }
  resetPwdSaving.value = true
  try {
    await userApi.resetPassword(resetPwdTarget.value.id, resetPwdForm.new_password)
    ElMessage.success('用户密码已重置')
    showResetPwdDialog.value = false
  } finally {
    resetPwdSaving.value = false
  }
}

onMounted(() => loadUsers())
</script>

<style scoped lang="scss">
.user-management {
  .mb-16 {
    margin-bottom: 16px;
  }
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
}
</style>
