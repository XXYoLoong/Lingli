<template>
  <div class="order-center">
    <!-- 筛选区 -->
    <el-card class="filter-card" shadow="never">
      <el-form :inline="true" :model="queryParams">
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="全部" clearable style="width: 140px">
            <el-option label="已创建" value="created" />
            <el-option label="待派单" value="pending_dispatch" />
            <el-option label="待接单" value="pending_accept" />
            <el-option label="待到场" value="pending_arrive" />
            <el-option label="服务中" value="in_service" />
            <el-option label="待确认" value="pending_confirm" />
            <el-option label="已完成" value="completed" />
            <el-option label="已关闭" value="closed" />
          </el-select>
        </el-form-item>
        <el-form-item label="服务类型">
          <el-select v-model="queryParams.service_type" placeholder="全部" clearable style="width: 160px">
            <el-option label="维修" value="维修" />
            <el-option label="保洁" value="保洁" />
            <el-option label="助餐" value="助餐" />
            <el-option label="陪诊" value="陪诊" />
            <el-option label="代办" value="代办" />
            <el-option label="照护" value="照护" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadOrders">查询</el-button>
          <el-button @click="resetQuery">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工单列表 -->
    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="table-header">
          <span>工单列表</span>
          <el-button type="primary" size="small" @click="showExportDialog = true">导出</el-button>
        </div>
      </template>
      <el-table :data="orders" v-loading="loading" stripe>
        <el-table-column prop="order_no" label="工单号" min-width="240" show-overflow-tooltip>
          <template #default="{ row }">
            <span class="order-no-cell">{{ row.order_no }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="标题" show-overflow-tooltip />
        <el-table-column prop="service_type" label="类型" width="80" />
        <el-table-column prop="contact_name" label="联系人" width="80" />
        <el-table-column prop="urgency_level" label="紧急度" width="80">
          <template #default="{ row }">
            <el-tag :type="urgencyType(row.urgency_level)" size="small">
              {{ urgencyLabel(row.urgency_level) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" link @click="viewOrder(row)">详情</el-button>
            <el-button v-if="canAiReview(row)" size="small" type="warning" link @click="aiReview(row)">AI 审核</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="queryParams.page"
        v-model:page-size="queryParams.page_size"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next"
        class="pagination"
        @change="loadOrders"
      />
    </el-card>

    <!-- 工单详情抽屉 -->
    <el-drawer v-model="drawerVisible" title="工单详情" size="500px">
      <template v-if="selectedOrder">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="工单号">{{ selectedOrder.order_no }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="statusType(selectedOrder.status)">{{ statusLabel(selectedOrder.status) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="服务类型">{{ selectedOrder.service_type }}</el-descriptions-item>
          <el-descriptions-item label="紧急度">{{ urgencyLabel(selectedOrder.urgency_level) }}</el-descriptions-item>
          <el-descriptions-item label="联系人">{{ selectedOrder.contact_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ selectedOrder.contact_phone || '-' }}</el-descriptions-item>
          <el-descriptions-item label="地址" :span="2">{{ selectedOrder.service_address || '-' }}</el-descriptions-item>
          <el-descriptions-item label="预约时间" :span="2">{{ selectedOrder.appointment_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">{{ selectedOrder.description || '-' }}</el-descriptions-item>
        </el-descriptions>

        <el-divider>AI 分析结果</el-divider>
        <el-descriptions :column="1" border>
          <el-descriptions-item label="分类建议">{{ selectedOrder.ai_category || '-' }}</el-descriptions-item>
          <el-descriptions-item label="风险提示">{{ selectedOrder.ai_risk_tags || '-' }}</el-descriptions-item>
          <el-descriptions-item label="处理摘要">{{ selectedOrder.ai_summary || '-' }}</el-descriptions-item>
        </el-descriptions>
      </template>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { orderApi, aiApi } from '@/services/api'
import type { ServiceOrder } from '@/types'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const orders = ref<ServiceOrder[]>([])
const total = ref(0)
const drawerVisible = ref(false)
const selectedOrder = ref<ServiceOrder | null>(null)
const showExportDialog = ref(false)
const usingMockData = ref(false)

const queryParams = reactive({
  status: '',
  service_type: '',
  page: 1,
  page_size: 20,
})

const statusMap: Record<string, { label: string; type: string }> = {
  created: { label: '已创建', type: '' },
  pending_dispatch: { label: '待派单', type: 'warning' },
  pending_accept: { label: '待接单', type: 'info' },
  pending_arrive: { label: '待到场', type: 'primary' },
  in_service: { label: '服务中', type: '' },
  pending_confirm: { label: '待确认', type: 'success' },
  completed: { label: '已完成', type: 'success' },
  after_sale: { label: '售后中', type: 'danger' },
  closed: { label: '已关闭', type: 'info' },
}

function statusType(status: string) {
  return statusMap[status]?.type || ''
}
function statusLabel(status: string) {
  return statusMap[status]?.label || status
}

const urgencyMap: Record<string, { label: string; type: string }> = {
  low: { label: '低', type: 'info' },
  normal: { label: '普通', type: '' },
  high: { label: '高', type: 'warning' },
  urgent: { label: '紧急', type: 'danger' },
}

function urgencyType(level: string) {
  return urgencyMap[level]?.type || ''
}
function urgencyLabel(level: string) {
  return urgencyMap[level]?.label || level
}

function canAiReview(order: ServiceOrder) {
  if (usingMockData.value) return false
  return ['created', 'pending_dispatch', 'pending_accept'].includes(order.status)
}

async function loadOrders() {
  loading.value = true
  try {
    const params: Record<string, string> = {}
    if (queryParams.status) params.status = queryParams.status
    if (queryParams.service_type) params.service_type = queryParams.service_type
    orders.value = await orderApi.list(params)
    total.value = orders.value.length
    usingMockData.value = false
  } catch {
    // 使用 mock 数据
    orders.value = generateMockOrders()
    total.value = orders.value.length
    usingMockData.value = true
  } finally {
    loading.value = false
  }
}

function resetQuery() {
  queryParams.status = ''
  queryParams.service_type = ''
  queryParams.page = 1
  loadOrders()
}

function viewOrder(order: ServiceOrder) {
  selectedOrder.value = order
  drawerVisible.value = true
}

async function aiReview(order: ServiceOrder) {
  if (usingMockData.value || order.id.startsWith('order-')) {
    ElMessage.warning('当前为离线示例数据，无法创建AI任务')
    return
  }
  try {
    await aiApi.review({ order_id: order.id, task_type: 'review' })
    ElMessage.success('AI 审核任务已提交，请稍后查看结果')
  } catch {
    // 全局拦截器会提示后端返回原因，避免重复弹窗
  }
}

function generateMockOrders(): ServiceOrder[] {
  const types = ['维修', '保洁', '助餐', '陪诊', '代办', '照护']
  const statuses: ServiceOrder['status'][] = ['created', 'pending_dispatch', 'pending_accept', 'in_service', 'completed']
  const urgencies = ['low', 'normal', 'high', 'urgent']
  return Array.from({ length: 15 }, (_, i) => ({
    id: `order-${i}`,
    order_no: `NL20260414${String(i).padStart(4, '0')}`,
    station_id: '',
    service_type: types[i % types.length],
    title: `社区服务工单 ${i + 1}`,
    description: '工单描述内容',
    contact_name: `用户${i + 1}`,
    contact_phone: '13800000000',
    service_address: `XX街道XX小区${i + 1}栋`,
    appointment_time: '2026-04-15 10:00',
    status: statuses[i % statuses.length],
    urgency_level: urgencies[i % urgencies.length],
    ai_category: i % 3 === 0 ? '维修' : null,
    ai_risk_tags: i % 4 === 0 ? '["老人独居"]' : null,
    ai_summary: null,
    assigned_worker_id: null,
    service_result: null,
    abnormal_flag: false,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    completed_at: null,
    attachments: [],
  }))
}

onMounted(() => loadOrders())
</script>

<style scoped lang="scss">
.order-center {
  .order-no-cell {
    display: inline-block;
    max-width: 220px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    font-variant-numeric: tabular-nums;
  }

  .filter-card {
    margin-bottom: 16px;
  }
  .table-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .pagination {
    margin-top: 16px;
    justify-content: flex-end;
  }
}
</style>
