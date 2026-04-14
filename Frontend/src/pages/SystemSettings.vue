<template>
  <div class="system-settings">
    <el-tabs v-model="activeTab" type="card">
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
                <el-option label="qwen-plus" value="qwen-plus" />
                <el-option label="qwen-max" value="qwen-max" />
                <el-option label="qwen-flash" value="qwen-flash" />
              </el-select>
            </el-form-item>
            <el-form-item label="摘要模型">
              <el-select v-model="modelConfig.summaryModel" style="width: 200px">
                <el-option label="qwen-flash" value="qwen-flash" />
                <el-option label="qwen-plus" value="qwen-plus" />
              </el-select>
            </el-form-item>
            <el-form-item label="日调用限额">
              <el-input-number v-model="modelConfig.dailyLimit" :min="0" :max="10000" />
            </el-form-item>
            <el-form-item label="启用状态">
              <el-switch v-model="modelConfig.enabled" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="saveModelConfig">保存配置</el-button>
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
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'

const activeTab = ref('dictionary')

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
  reviewModel: 'qwen-plus',
  summaryModel: 'qwen-flash',
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
  ElMessage.success('模型配置已保存')
}
</script>

<style scoped lang="scss">
.system-settings {
  :deep(.el-tabs__content) {
    padding-top: 16px;
  }
}
</style>
