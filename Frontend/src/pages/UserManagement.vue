<template>
  <div class="user-management">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" size="small" @click="showAddDialog = true">添加用户</el-button>
        </div>
      </template>

      <el-form :inline="true" :model="queryParams">
        <el-form-item label="角色">
          <el-select v-model="queryParams.role" placeholder="全部" clearable>
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
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" link @click="editUser(row)">编辑</el-button>
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
        <el-form-item label="用户名" v-if="!editingUser">
          <el-input v-model="userForm.username" />
        </el-form-item>
        <el-form-item label="手机号" v-if="!editingUser">
          <el-input v-model="userForm.phone" />
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
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import type { UserAccount } from '@/types'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const users = ref<UserAccount[]>([])
const showAddDialog = ref(false)
const editingUser = ref<UserAccount | null>(null)
const userForm = reactive({
  username: '',
  phone: '',
  password: '',
  real_name: '',
  role: 'resident' as UserAccount['role'],
})

const queryParams = reactive({ role: '' })

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
  loading.value = true
  try {
    users.value = generateMockUsers()
  } finally {
    loading.value = false
  }
}

function editUser(user: UserAccount) {
  editingUser.value = user
  userForm.username = user.username
  userForm.phone = user.phone
  userForm.real_name = user.real_name || ''
  userForm.role = user.role
  showAddDialog.value = true
}

function toggleUserStatus(user: UserAccount) {
  ElMessageBox.confirm(`确定要${user.is_active ? '停用' : '启用'}用户 ${user.username} 吗？`, '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning',
  }).then(() => {
    user.is_active = !user.is_active
    ElMessage.success('操作成功')
  }).catch(() => {})
}

function saveUser() {
  ElMessage.success(editingUser.value ? '用户已更新' : '用户已创建')
  showAddDialog.value = false
  loadUsers()
}

function generateMockUsers(): UserAccount[] {
  const roles: UserAccount['role'][] = ['resident', 'worker', 'station_manager', 'dispatcher', 'operator', 'admin']
  const names = ['张三', '李四', '王五', '赵六', '孙七', '周八']
  return Array.from({ length: 20 }, (_, i) => ({
    id: `user-${i}`,
    username: `user${String(i + 1).padStart(3, '0')}`,
    phone: `138${String(10000000 + i * 1234567).slice(0, 8)}`,
    email: null,
    role: roles[i % roles.length],
    real_name: names[i % names.length],
    avatar_url: null,
    is_active: i % 10 !== 0,
    is_verified: true,
    station_id: null,
    created_at: new Date(Date.now() - i * 86400000).toISOString(),
  }))
}

onMounted(() => loadUsers())
</script>

<style scoped lang="scss">
.user-management {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
}
</style>
