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
  <div class="dashboard">
    <!-- KPI 卡片 -->
    <el-row :gutter="16" class="kpi-row">
      <el-col :span="6" v-for="kpi in kpis" :key="kpi.label">
        <el-card shadow="hover" class="kpi-card">
          <div class="kpi-content">
            <div class="kpi-value">{{ kpi.value }}</div>
            <div class="kpi-label">{{ kpi.label }}</div>
          </div>
          <el-icon class="kpi-icon" :color="kpi.color">
            <component :is="kpi.icon" />
          </el-icon>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" class="chart-row">
      <!-- 工单趋势图 -->
      <el-col :span="16">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>工单趋势</span>
              <el-radio-group v-model="trendDays" size="small" @change="loadTrend">
                <el-radio-button :value="7">近7天</el-radio-button>
                <el-radio-button :value="14">近14天</el-radio-button>
                <el-radio-button :value="30">近30天</el-radio-button>
              </el-radio-group>
            </div>
          </template>
          <div ref="trendChartRef" class="chart-container" />
        </el-card>
      </el-col>

      <!-- 工单分布饼图 -->
      <el-col :span="8">
        <el-card>
          <template #header>工单分类分布</template>
          <div ref="pieChartRef" class="chart-container" />
        </el-card>
      </el-col>
    </el-row>

    <!-- 待办列表 -->
    <el-row :gutter="16" class="todo-row">
      <el-col :span="12">
        <el-card>
          <template #header>待处理工单</template>
          <el-table :data="pendingOrders" stripe size="small">
            <el-table-column prop="order_no" label="工单号" width="160" />
            <el-table-column prop="title" label="标题" show-overflow-tooltip />
            <el-table-column prop="service_type" label="类型" width="100" />
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="statusType(row.status)" size="small">{{ statusLabel(row.status) }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>异常告警</template>
          <el-empty v-if="alerts.length === 0" description="暂无异常告警" />
          <el-timeline v-else>
            <el-timeline-item
              v-for="alert in alerts"
              :key="alert.id"
              type="danger"
              :timestamp="alert.created_at"
            >
              {{ alert.title }}
            </el-timeline-item>
          </el-timeline>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { orderApi, statsApi } from '@/services/api'
import type { ServiceOrder } from '@/types'
import { Tickets, User, Warning, TrendCharts } from '@element-plus/icons-vue'

const trendDays = ref(7)
const trendChartRef = ref<HTMLDivElement>()
const pieChartRef = ref<HTMLDivElement>()

const kpis = ref([
  { label: '今日工单', value: 0, icon: Tickets, color: '#1677ff' },
  { label: '进行中', value: 0, icon: TrendCharts, color: '#faad14' },
  { label: '服务人员', value: 0, icon: User, color: '#52c41a' },
  { label: '异常告警', value: 0, icon: Warning, color: '#ff4d4f' },
])

const pendingOrders = ref<ServiceOrder[]>([])
const alerts = ref<Array<{ id: string; title: string; created_at: string }>>([])

const statusMap: Record<string, { label: string; type: string }> = {
  created: { label: '已创建', type: '' },
  pending_dispatch: { label: '待派单', type: 'warning' },
  pending_accept: { label: '待接单', type: 'info' },
  pending_arrive: { label: '待到场', type: 'primary' },
  in_service: { label: '服务中', type: '' },
  pending_confirm: { label: '待确认', type: 'success' },
  completed: { label: '已完成', type: 'success' },
  closed: { label: '已关闭', type: 'info' },
}

function statusType(status: string) {
  return statusMap[status]?.type || ''
}

function statusLabel(status: string) {
  return statusMap[status]?.label || status
}

async function loadDashboard() {
  try {
    const orders = await orderApi.list({ page_size: '10' })
    const today = new Date().toDateString()
    let todayCount = 0
    let inProgress = 0

    orders.forEach((o) => {
      if (new Date(o.created_at).toDateString() === today) todayCount++
      if (['pending_dispatch', 'pending_accept', 'pending_arrive', 'in_service'].includes(o.status)) inProgress++
    })

    kpis.value[0].value = todayCount
    kpis.value[1].value = inProgress
    pendingOrders.value = orders.filter(
      (o) => ['created', 'pending_dispatch', 'pending_accept'].includes(o.status)
    ).slice(0, 8)
  } catch {
    // 使用 mock 数据
    kpis.value[0].value = 23
    kpis.value[1].value = 12
  }

  loadTrend()
}

async function loadTrend() {
  await nextTick()
  const trendChart = echarts.init(trendChartRef.value)
  const pieChart = echarts.init(pieChartRef.value)

  // Mock trend data
  const days = Array.from({ length: trendDays.value }, (_, i) => {
    const d = new Date()
    d.setDate(d.getDate() - (trendDays.value - 1 - i))
    return d.toISOString().slice(0, 10)
  })

  trendChart.setOption({
    tooltip: { trigger: 'axis' },
    legend: { data: ['新建工单', '已完成'] },
    xAxis: { type: 'category', data: days },
    yAxis: { type: 'value' },
    series: [
      { name: '新建工单', type: 'line', smooth: true, data: days.map(() => Math.floor(Math.random() * 20) + 5) },
      { name: '已完成', type: 'line', smooth: true, data: days.map(() => Math.floor(Math.random() * 15) + 3) },
    ],
    grid: { left: 40, right: 20, bottom: 30 },
  })

  pieChart.setOption({
    tooltip: { trigger: 'item' },
    series: [{
      type: 'pie',
      radius: ['40%', '70%'],
      data: [
        { value: 35, name: '维修' },
        { value: 25, name: '保洁' },
        { value: 15, name: '助餐' },
        { value: 12, name: '陪诊' },
        { value: 13, name: '其他' },
      ],
    }],
  })
}

onMounted(() => {
  loadDashboard()
  window.addEventListener('resize', () => {
    echarts.getInstanceByDom(trendChartRef.value!)?.resize()
    echarts.getInstanceByDom(pieChartRef.value!)?.resize()
  })
})
</script>

<style scoped lang="scss">
.dashboard {
  .kpi-row {
    margin-bottom: 16px;
  }
  .chart-row {
    margin-bottom: 16px;
  }
  .kpi-card {
    :deep(.el-card__body) {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px;
    }
    .kpi-content {
      .kpi-value {
        font-size: 28px;
        font-weight: 700;
        color: #333;
      }
      .kpi-label {
        font-size: 14px;
        color: #999;
        margin-top: 4px;
      }
    }
    .kpi-icon {
      font-size: 48px;
    }
  }
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .chart-container {
    width: 100%;
    height: 300px;
  }
}
</style>
