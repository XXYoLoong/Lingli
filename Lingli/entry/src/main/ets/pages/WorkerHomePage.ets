/**
 * 服务人员首页 - 从后端加载真实任务数据
 */

import { fetchOrders, type OrderItem } from '../common/ApiClient';

@Component
export struct WorkerHomePage {
  @State selectedTab: number = 0
  @State tasks: OrderItem[] = []
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadTasks()
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('我的工作')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1677ff')
          Text(this.getTodayCount() + ' 个待办任务')
            .fontSize(13)
            .fontColor('#999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Text('消息')
          .fontSize(16)
          .fontColor('#666')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 10 })

      Row() {
        this.TabItem('待办', 0)
        this.TabItem('已完成', 1)
        this.TabItem('全部', 2)
      }
      .width('100%')
      .padding({ left: 20, top: 10, bottom: 10 })

      if (this.isLoading) {
        Text('加载中...')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      } else if (this.getFilteredTasks().length === 0) {
        Text('暂无任务')
          .fontSize(14)
          .fontColor('#ccc')
          .margin({ top: 40 })
      } else {
        List({ space: 12 }) {
          ForEach(this.getFilteredTasks(), (task: OrderItem) => {
            ListItem() {
              this.TaskCard(task)
            }
          }, (task: OrderItem) => task.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  @Builder
  TabItem(label: string, idx: number) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.selectedTab === idx ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.selectedTab === idx ? '#1677ff' : '#999')
      .padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .backgroundColor(this.selectedTab === idx ? '#e6f4ff' : '#f0f0f0')
      .borderRadius(16)
      .margin({ right: 8 })
      .onClick(() => {
        this.selectedTab = idx
      })
  }

  @Builder
  TaskCard(task: OrderItem) {
    Column() {
      Row() {
        Column() {
          Text(task.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
          Text(task.order_no)
            .fontSize(12)
            .fontColor('#999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.getStatusLabel(task.status))
          .fontSize(12)
          .fontColor(this.getStatusColor(task.status))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getStatusBg(task.status))
          .borderRadius(4)
      }
      .width('100%')

      Row() {
        Text(task.service_address || '暂无地址')
          .fontSize(13)
          .fontColor('#666')
          .layoutWeight(1)
          .maxLines(1)
      }
      .width('100%')
      .margin({ top: 10, bottom: 4 })

      Row() {
        Text(task.contact_name || '')
          .fontSize(13)
          .fontColor('#666')
        if (task.contact_phone) {
          Text('  ' + task.contact_phone)
            .fontSize(13)
            .fontColor('#666')
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (task.status === 'pending_arrive') {
        Button('签到到场')
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#1677ff')
          .borderRadius(8)
      } else if (task.status === 'in_service') {
        Button('填写结果')
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#52c41a')
          .borderRadius(8)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#fff')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }

  private loadTasks(): void {
    this.isLoading = true
    fetchOrders()
      .then((orders: OrderItem[]) => {
        this.tasks = orders
        this.isLoading = false
      })
      .catch(() => {
        this.isLoading = false
      })
  }

  private getTodayCount(): number {
    const todo = this.tasks.filter((t: OrderItem) =>
      t.status === 'pending_arrive' || t.status === 'in_service'
    )
    return todo.length
  }

  private getFilteredTasks(): OrderItem[] {
    if (this.selectedTab === 0) {
      return this.tasks.filter((t: OrderItem) =>
        t.status === 'pending_arrive' || t.status === 'in_service' ||
        t.status === 'pending_accept' || t.status === 'pending_dispatch'
      )
    } else if (this.selectedTab === 1) {
      return this.tasks.filter((t: OrderItem) =>
        t.status === 'completed' || t.status === 'closed'
      )
    }
    return this.tasks
  }

  private getStatusLabel(status: string): string {
    const map: Record<string, string> = {
      'pending_arrive': '待到场',
      'in_service': '服务中',
      'completed': '已完成',
      'pending_accept': '待接单',
      'pending_dispatch': '待派单',
      'pending_confirm': '待确认',
      'closed': '已关闭'
    }
    return map[status] || status
  }

  private getStatusColor(status: string): string {
    if (status === 'pending_arrive' || status === 'pending_accept') return '#faad14'
    if (status === 'in_service') return '#1677ff'
    if (status === 'completed') return '#52c41a'
    return '#999'
  }

  private getStatusBg(status: string): string {
    if (status === 'pending_arrive' || status === 'pending_accept') return '#fffbe6'
    if (status === 'in_service') return '#e6f4ff'
    if (status === 'completed') return '#f6ffed'
    return '#f5f5f5'
  }
}
