<template>
  <div class="system-settings">
    <el-alert
      v-if="!isSuperAdmin"
      title="仅小小游龙账号可进行系统配置管理"
      type="warning"
      :closable="false"
      show-icon
      class="mb-16"
    />
    <el-tabs v-model="activeTab" type="card">
      <el-tab-pane label="账户安全" name="security">
        <el-card>
          <template #header>账户安全</template>
          <el-form :model="emailForm" label-width="120px" style="max-width: 520px; margin-bottom: 12px">
            <el-form-item label="当前邮箱">
              <el-input :value="userStore.user?.email || '未绑定'" disabled />
            </el-form-item>
            <el-form-item label="绑定/新邮箱">
              <el-input v-model="emailForm.email" placeholder="请输入邮箱地址" />
            </el-form-item>
            <el-form-item label="验证码">
              <el-row style="width: 100%" :gutter="8">
                <el-col :span="14">
                  <el-input v-model="emailForm.code" maxlength="6" placeholder="请输入6位验证码" />
                </el-col>
                <el-col :span="10">
                  <el-button :disabled="emailCodeCooldown > 0 || !emailForm.email" @click="sendMyEmailCode">
                    {{ emailCodeCooldown > 0 ? `${emailCodeCooldown}s后重发` : '发送验证码' }}
                  </el-button>
                </el-col>
              </el-row>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="emailSaving" @click="changeMyEmail">验证并绑定邮箱</el-button>
            </el-form-item>
          </el-form>
          <el-divider />
          <el-form :model="passwordForm" label-width="120px" style="max-width: 520px">
            <el-form-item label="当前密码">
              <el-input v-model="passwordForm.old_password" type="password" show-password />
            </el-form-item>
            <el-form-item label="新密码">
              <el-input v-model="passwordForm.new_password" type="password" show-password />
            </el-form-item>
            <el-form-item label="确认新密码">
              <el-input v-model="passwordForm.confirm_password" type="password" show-password />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="passwordSaving" @click="changeMyPassword">更新密码</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-tab-pane>

      <el-tab-pane label="数据字典" name="dictionary">
        <el-card>
          <template #header>数据字典管理</template>
          <el-table :data="dictionaries" stripe>
            <el-table-column prop="category" label="分类" width="150" />
            <el-table-column prop="key" label="键" width="150" />
            <el-table-column prop="label" label="显示名称" />
            <el-table-column prop="value" label="值" width="100" />
            <el-table-column label="操作" width="100">
              <template #default>
                <el-button size="small" type="primary" link>编辑</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <el-tab-pane label="通知模板" name="templates">
        <el-card>
          <template #header>通知模板配置</template>
          <el-table :data="templates" stripe>
            <el-table-column prop="name" label="模板名称" />
            <el-table-column prop="type" label="类型" width="120" />
            <el-table-column prop="title" label="标题模板" />
            <el-table-column label="操作" width="100">
              <template #default>
                <el-button size="small" type="primary" link>编辑</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>

      <el-tab-pane label="模型配置" name="model">
        <el-card>
          <template #header>AI 模型配置</template>
          <el-form label-width="120px">
            <el-form-item label="审核模型">
              <el-select v-model="modelConfig.reviewModel" style="width: 200px">
                <el-option label="deepseek-chat" value="deepseek-chat" />
                <el-option label="deepseek-reasoner" value="deepseek-reasoner" />
              </el-select>
            </el-form-item>
            <el-form-item label="摘要模型">
              <el-select v-model="modelConfig.summaryModel" style="width: 200px">
                <el-option label="deepseek-chat" value="deepseek-chat" />
                <el-option label="deepseek-reasoner" value="deepseek-reasoner" />
              </el-select>
            </el-form-item>
            <el-form-item label="日调用限额">
              <el-input-number v-model="modelConfig.dailyLimit" :min="0" :max="10000" />
            </el-form-item>
            <el-form-item label="启用状态">
              <el-switch v-model="modelConfig.enabled" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :disabled="!isSuperAdmin" @click="saveModelConfig">保存配置</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-tab-pane>

      <el-tab-pane label="权限管理" name="permissions">
        <el-card>
          <template #header>角色权限矩阵</template>
          <el-table :data="permissionMatrix" stripe>
            <el-table-column prop="role" label="角色" width="150" />
            <el-table-column label="工单查看">
              <template #default="{ row }">
                <el-tag :type="row.order_view ? 'success' : 'info'" size="small">
                  {{ row.order_view ? '✓' : '✗' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="工单编辑">
              <template #default="{ row }">
                <el-tag :type="row.order_edit ? 'success' : 'info'" size="small">
                  {{ row.order_edit ? '✓' : '✗' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="派单管理">
              <template #default="{ row }">
                <el-tag :type="row.dispatch ? 'success' : 'info'" size="small">
                  {{ row.dispatch ? '✓' : '✗' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="AI 审核">
              <template #default="{ row }">
                <el-tag :type="row.ai_review ? 'success' : 'info'" size="small">
                  {{ row.ai_review ? '✓' : '✗' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="数据统计">
              <template #default="{ row }">
                <el-tag :type="row.stats ? 'success' : 'info'" size="small">
                  {{ row.stats ? '✓' : '✗' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="系统设置">
              <template #default="{ row }">
                <el-tag :type="row.settings ? 'success' : 'info'" size="small">
                  {{ row.settings ? '✓' : '✗' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, reactive, onBeforeUnmount, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { authApi, userApi } from '@/services/api'
import { useRoute } from 'vue-router'

const activeTab = ref('security')
const route = useRoute()
const userStore = useUserStore()
const isSuperAdmin = computed(() => userStore.isSuperAdmin())
const passwordSaving = ref(false)
const emailSaving = ref(false)
const emailCodeCooldown = ref(0)
let emailCodeTimer: number | null = null
const emailForm = reactive({
  email: '',
  code: '',
})
const passwordForm = reactive({
  old_password: '',
  new_password: '',
  confirm_password: '',
})

const dictionaries = ref([
  { category: '服务类型', key: 'service_type', label: '维修服务', value: '维修' },
  { category: '服务类型', key: 'service_type', label: '保洁服务', value: '保洁' },
  { category: '服务类型', key: 'service_type', label: '助餐服务', value: '助餐' },
  { category: '服务类型', key: 'service_type', label: '陪诊服务', value: '陪诊' },
  { category: '服务类型', key: 'service_type', label: '代办服务', value: '代办' },
  { category: '服务类型', key: 'service_type', label: '照护服务', value: '照护' },
  { category: '紧急程度', key: 'urgency', label: '低', value: 'low' },
  { category: '紧急程度', key: 'urgency', label: '普通', value: 'normal' },
  { category: '紧急程度', key: 'urgency', label: '高', value: 'high' },
  { category: '紧急程度', key: 'urgency', label: '紧急', value: 'urgent' },
])

const templates = ref([
  { name: '工单创建通知', type: '系统消息', title: '您的工单 {order_no} 已创建成功' },
  { name: '派单通知', type: '业务提醒', title: '您有新的工单 {order_no} 需要处理' },
  { name: '工单完成通知', type: '业务提醒', title: '工单 {order_no} 已完成，请及时确认' },
  { name: '上传失败告警', type: '异常告警', title: '工单附件上传失败，请检查网络后重试' },
])

const modelConfig = reactive({
  reviewModel: 'deepseek-chat',
  summaryModel: 'deepseek-reasoner',
  dailyLimit: 1000,
  enabled: true,
})

const permissionMatrix = ref([
  { role: '居民', order_view: true, order_edit: true, dispatch: false, ai_review: false, stats: false, settings: false },
  { role: '服务人员', order_view: true, order_edit: false, dispatch: false, ai_review: false, stats: false, settings: false },
  { role: '站长', order_view: true, order_edit: true, dispatch: true, ai_review: true, stats: true, settings: false },
  { role: '调度员', order_view: true, order_edit: false, dispatch: true, ai_review: false, stats: false, settings: false },
  { role: '运营人员', order_view: true, order_edit: false, dispatch: false, ai_review: true, stats: true, settings: false },
  { role: '管理员', order_view: true, order_edit: true, dispatch: true, ai_review: true, stats: true, settings: true },
])

function saveModelConfig() {
  if (!isSuperAdmin.value) {
    ElMessage.warning('仅小小游龙账号可保存系统配置')
    return
  }
  ElMessage.success('模型配置已保存')
}

async function changeMyPassword() {
  if (!passwordForm.old_password || !passwordForm.new_password || !passwordForm.confirm_password) {
    ElMessage.warning('请填写完整密码信息')
    return
  }
  if (passwordForm.new_password.length < 8) {
    ElMessage.warning('新密码至少8位')
    return
  }
  if (passwordForm.new_password !== passwordForm.confirm_password) {
    ElMessage.warning('两次输入的新密码不一致')
    return
  }
  passwordSaving.value = true
  try {
    await authApi.changePassword({
      old_password: passwordForm.old_password,
      new_password: passwordForm.new_password,
    })
    ElMessage.success('密码已修改，请牢记新密码')
    passwordForm.old_password = ''
    passwordForm.new_password = ''
    passwordForm.confirm_password = ''
  } finally {
    passwordSaving.value = false
  }
}

async function changeMyEmail() {
  if (!emailForm.email || !emailForm.code) {
    ElMessage.warning('请填写邮箱和验证码')
    return
  }
  emailSaving.value = true
  try {
    const user = await userApi.verifyMyEmail(emailForm.email, emailForm.code)
    userStore.user = user
    ElMessage.success('邮箱已更新')
    emailForm.code = ''
  } finally {
    emailSaving.value = false
  }
}

async function sendMyEmailCode() {
  if (!emailForm.email) {
    ElMessage.warning('请先输入邮箱')
    return
  }
  await userApi.sendMyEmailCode(emailForm.email)
  ElMessage.success('验证码已发送，请查收邮箱')
  emailCodeCooldown.value = 60
  if (emailCodeTimer) window.clearInterval(emailCodeTimer)
  emailCodeTimer = window.setInterval(() => {
    if (emailCodeCooldown.value > 0) {
      emailCodeCooldown.value -= 1
    } else if (emailCodeTimer) {
      window.clearInterval(emailCodeTimer)
      emailCodeTimer = null
    }
  }, 1000)
}

onMounted(() => {
  const tab = String(route.query.tab || '')
  if (tab === 'security' || tab === 'dictionary' || tab === 'templates' || tab === 'model' || tab === 'permissions') {
    activeTab.value = tab
  }
})

onBeforeUnmount(() => {
  if (emailCodeTimer) {
    window.clearInterval(emailCodeTimer)
    emailCodeTimer = null
  }
})
</script>

<style scoped lang="scss">
.system-settings {
  .mb-16 {
    margin-bottom: 16px;
  }
  :deep(.el-tabs__content) {
    padding-top: 16px;
  }
}
</style>
