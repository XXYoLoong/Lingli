<template>
  <div class="ai-review-center">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>AI 审核中心</span>
          <el-alert
            v-if="aiStatus === 'disabled'"
            title="AI 服务当前不可用"
            type="warning"
            :closable="false"
            show-icon
          />
        </div>
      </template>

      <el-form :inline="true" :model="queryParams">
        <el-form-item label="任务类型">
          <el-select v-model="queryParams.task_type" placeholder="全部" clearable>
            <el-option label="工单审核" value="review" />
            <el-option label="工单摘要" value="summary" />
            <el-option label="工单分类" value="classify" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="全部" clearable>
            <el-option label="待处理" value="pending" />
            <el-option label="处理中" value="processing" />
            <el-option label="已完成" value="completed" />
            <el-option label="失败" value="failed" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadAiTasks">查询</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="aiTasks" v-loading="loading" stripe>
        <el-table-column prop="task_id" label="任务ID" width="280" show-overflow-tooltip />
        <el-table-column prop="task_type" label="类型" width="100">
          <template #default="{ row }">
            <el-tag size="small">{{ taskTypeLabel(row.task_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="aiStatusType(row.status)" size="small">{{ aiStatusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="model_name" label="模型" width="120" />
        <el-table-column prop="confidence" label="置信度" width="100">
          <template #default="{ row }">
            <span v-if="row.confidence !== null">{{ (row.confidence * 100).toFixed(0) }}%</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" link @click="viewResult(row)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 审核结果对话框 -->
    <el-dialog v-model="showResultDialog" title="AI 审核结果" width="600px">
      <template v-if="selectedResult">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="任务状态">
            <el-tag :type="aiStatusType(selectedResult.status)">{{ aiStatusLabel(selectedResult.status) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="分类建议">{{ selectedResult.category_suggestion || '-' }}</el-descriptions-item>
          <el-descriptions-item label="紧急度建议">{{ selectedResult.urgency_suggestion || '-' }}</el-descriptions-item>
          <el-descriptions-item label="风险标签">
            <el-tag v-for="tag in selectedResult.risk_tags" :key="tag" class="risk-tag" size="small" type="danger">
              {{ tag }}
            </el-tag>
            <span v-if="selectedResult.risk_tags.length === 0">无</span>
          </el-descriptions-item>
          <el-descriptions-item label="置信度">
            <el-progress :percentage="selectedResult.confidence ? Math.round(selectedResult.confidence * 100) : 0" />
          </el-descriptions-item>
          <el-descriptions-item label="处理摘要">{{ selectedResult.summary || '-' }}</el-descriptions-item>
        </el-descriptions>

        <div class="dialog-footer">
          <el-button type="success" @click="approveReview">通过</el-button>
          <el-button type="danger" @click="rejectReview">驳回</el-button>
          <el-button @click="showResultDialog = false">关闭</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import type { AiReviewResult } from '@/types'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const aiTasks = ref<Partial<AiReviewResult & { task_type: string; model_name: string; created_at: string }>[]>([])
const showResultDialog = ref(false)
const selectedResult = ref<AiReviewResult | null>(null)
const aiStatus = ref<'active' | 'disabled'>('active')

const queryParams = reactive({
  task_type: '',
  status: '',
})

function taskTypeLabel(type: string) {
  const map: Record<string, string> = { review: '工单审核', summary: '工单摘要', classify: '工单分类', analysis: '经营分析' }
  return map[type] || type
}

function aiStatusType(status: string) {
  const map: Record<string, string> = {
    pending: 'info',
    processing: 'warning',
    completed: 'success',
    failed: 'danger',
    cancelled: 'info',
  }
  return map[status] || ''
}

function aiStatusLabel(status: string) {
  const map: Record<string, string> = {
    pending: '待处理',
    processing: '处理中',
    completed: '已完成',
    failed: '失败',
    cancelled: '已取消',
  }
  return map[status] || status
}

async function loadAiTasks() {
  loading.value = true
  try {
    aiTasks.value = generateMockAiTasks()
  } finally {
    loading.value = false
  }
}

function viewResult(row: Partial<AiReviewResult>) {
  selectedResult.value = row as AiReviewResult
  showResultDialog.value = true
}

function approveReview() {
  ElMessage.success('审核已通过')
  showResultDialog.value = false
}

function rejectReview() {
  ElMessage.warning('审核已驳回')
  showResultDialog.value = false
}

function generateMockAiTasks() {
  const types = ['review', 'summary', 'classify']
  const statuses = ['completed', 'processing', 'pending', 'failed']
  const models = ['qwen-plus', 'qwen-flash']
  return Array.from({ length: 12 }, (_, i) => ({
    task_id: `ai-task-${String(i).padStart(6, '0')}`,
    task_type: types[i % types.length],
    status: statuses[i % statuses.length],
    model_name: models[i % models.length],
    category_suggestion: i % 2 === 0 ? '维修' : '保洁',
    urgency_suggestion: i % 3 === 0 ? 'high' : 'normal',
    risk_tags: i % 4 === 0 ? ['老人独居', '行动不便'] : [],
    summary: `工单${i + 1}的AI分析摘要：该工单属于常规社区服务需求，建议优先安排处理。`,
    confidence: 0.7 + Math.random() * 0.25,
    created_at: new Date(Date.now() - i * 3600000).toISOString().replace('T', ' ').slice(0, 19),
  }))
}

onMounted(() => loadAiTasks())
</script>

<style scoped lang="scss">
.ai-review-center {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .risk_tag {
    margin-right: 4px;
  }
  .dialog-footer {
    margin-top: 16px;
    display: flex;
    justify-content: flex-end;
    gap: 8px;
  }
}
</style>
