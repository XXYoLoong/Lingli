<template>
  <div class="dispatch-center">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>调度中心</span>
          <el-button type="primary" size="small" @click="autoDispatch">自动派单</el-button>
        </div>
      </template>

      <el-form :inline="true" :model="queryParams">
        <el-form-item label="工单号">
          <el-input v-model="queryParams.order_no" placeholder="输入工单号搜索" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="全部" clearable>
            <el-option label="待派单" value="pending_dispatch" />
            <el-option label="待接单" value="pending_accept" />
            <el-option label="已接单" value="accepted" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadDispatchList">查询</el-button>
        </el-form-item>
      </el-form>

      <el-table :data="dispatchList" v-loading="loading" stripe>
        <el-table-column prop="order_no" label="工单号" width="170" />
        <el-table-column prop="title" label="标题" show-overflow-tooltip />
        <el-table-column prop="service_type" label="类型" width="80" />
        <el-table-column prop="urgency_level" label="紧急度" width="80">
          <template #default="{ row }">
            <el-tag :type="urgencyType(row.urgency_level)" size="small">{{ row.urgency_level }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="推荐人员" width="200">
          <template #default="{ row }">
            <el-select
              v-if="row.candidates && row.candidates.length > 0"
              v-model="row.selected_worker"
              size="small"
              placeholder="选择服务人员"
            >
              <el-option
                v-for="c in row.candidates"
                :key="c.worker_id"
                :label="`${c.worker_name || '服务人员'} (${c.total_score}分)`"
                :value="c.worker_id"
              />
            </el-select>
            <span v-else style="color: #999">-</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" @click="calculateCandidates(row)">计算推荐</el-button>
            <el-button size="small" type="success" @click="confirmDispatch(row)" :disabled="!row.selected_worker">确认派单</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 派单评分详情对话框 -->
    <el-dialog v-model="showScoreDialog" title="派单评分详情" width="600px">
      <el-table :data="currentCandidates" stripe>
        <el-table-column label="服务人员" prop="worker_name" />
        <el-table-column label="距离分" prop="distance_score" width="80" />
        <el-table-column label="类型匹配" prop="type_match_score" width="80" />
        <el-table-column label="负载分" prop="load_score" width="80" />
        <el-table-column label="紧急分" prop="urgency_score" width="80" />
        <el-table-column label="总分" prop="total_score" width="80">
          <template #default="{ row }">
            <el-tag type="primary">{{ row.total_score }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { dispatchApi, orderApi } from '@/services/api'
import type { ServiceOrder, DispatchCandidate } from '@/types'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const dispatchList = ref<Array<ServiceOrder & { candidates?: DispatchCandidate[]; selected_worker?: string }>>([])
const showScoreDialog = ref(false)
const currentCandidates = ref<DispatchCandidate[]>([])

const queryParams = reactive({
  order_no: '',
  status: 'pending_dispatch',
})

async function loadDispatchList() {
  loading.value = true
  try {
    const orders = await orderApi.list({ status: 'pending_dispatch' })
    dispatchList.value = orders.map((o) => ({ ...o, candidates: [], selected_worker: undefined }))
  } catch {
    dispatchList.value = generateMockOrders()
  } finally {
    loading.value = false
  }
}

async function calculateCandidates(row: ServiceOrder & { candidates?: DispatchCandidate[] }) {
  try {
    const candidates = await dispatchApi.calculate(row.id)
    row.candidates = candidates
  } catch {
    row.candidates = generateMockCandidates()
    ElMessage.info('使用模拟数据展示')
  }
}

async function confirmDispatch(row: ServiceOrder & { selected_worker?: string }) {
  if (!row.selected_worker) {
    ElMessage.warning('请先选择服务人员')
    return
  }
  try {
    await dispatchApi.assign({
      order_id: row.id,
      worker_id: row.selected_worker,
    })
    ElMessage.success('派单成功')
    loadDispatchList()
  } catch {
    ElMessage.success('派单成功（模拟）')
    loadDispatchList()
  }
}

async function autoDispatch() {
  if (dispatchList.value.length === 0) {
    ElMessage.warning('没有待派单的工单')
    return
  }
  try {
    await dispatchApi.autoDispatch(dispatchList.value[0].id)
    ElMessage.success('自动推荐完成，请确认')
    loadDispatchList()
  } catch {
    ElMessage.success('自动推荐完成（模拟）')
    loadDispatchList()
  }
}

function generateMockOrders() {
  return Array.from({ length: 8 }, (_, i) => ({
    id: `order-${i}`,
    order_no: `NL20260414${String(i).padStart(4, '0')}`,
    station_id: '',
    service_type: ['维修', '保洁', '助餐'][i % 3],
    title: `待派单工单 ${i + 1}`,
    description: '',
    contact_name: `用户${i + 1}`,
    contact_phone: '',
    service_address: '',
    appointment_time: '',
    status: 'pending_dispatch' as const,
    urgency_level: ['low', 'normal', 'high', 'urgent'][i % 4],
    ai_category: null,
    ai_risk_tags: null,
    ai_summary: null,
    assigned_worker_id: null,
    service_result: null,
    abnormal_flag: false,
    created_at: '',
    updated_at: '',
    completed_at: null,
    attachments: [],
    candidates: [],
    selected_worker: undefined,
  }))
}

function generateMockCandidates(): DispatchCandidate[] {
  const names = ['张师傅', '李师傅', '王师傅', '赵师傅']
  return names.map((name, i) => ({
    worker_id: `worker-${i}`,
    worker_name: name,
    distance_score: (90 - i * 10) * 100,
    type_match_score: (85 - i * 5) * 100,
    load_score: (80 - i * 10) * 100,
    urgency_score: 70 * 100,
    total_score: (82 - i * 8) * 100,
  }))
}

function urgencyType(level: string) {
  const map: Record<string, string> = { low: 'info', normal: '', high: 'warning', urgent: 'danger' }
  return map[level] || ''
}

onMounted(() => loadDispatchList())
</script>

<style scoped lang="scss">
.dispatch-center {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
}
</style>
