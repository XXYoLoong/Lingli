/**
 * 居民首页 - 从后端加载真实工单数据
 */

import { fetchOrders, type OrderItem } from '../common/ApiClient';

@Component
export struct ResidentHomePage {
  @State orders: OrderItem[] = []
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadOrders()
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('邻里')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1677ff')
          Blank()
          Text('消息')
            .fontSize(16)
            .fontColor('#666')
            .onClick(() => {
              AppStorage.setOrCreate('activeTab', 2)
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 10 })

        Column() {
          Text('您好，欢迎使用邻里服务')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .margin({ top: 16, bottom: 4 })
          Text('请选择您需要的服务类型')
            .fontSize(14)
            .fontColor('#999')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20 })

        Row() {
          this.ServiceCardItem('\uD83D\uDD27', '维修')
          this.ServiceCardItem('\uD83E\uDDF9', '保洁')
          this.ServiceCardItem('\uD83C\uDF71', '助餐')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ top: 20 })

        Row() {
          this.ServiceCardItem('\uD83C\uDFE5', '陪诊')
          this.ServiceCardItem('\uD83D\uDCCB', '代办')
          this.ServiceCardItem('\uD83D\uDC9D', '照护')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ top: 10 })

        Column() {
          Text('我的订单')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .margin({ top: 24, bottom: 12 })

          if (this.isLoading) {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#ccc')
          } else if (this.orders.length > 0) {
            ForEach(this.orders, (order: OrderItem) => {
              this.OrderCard(order)
            }, (order: OrderItem) => order.id)
          } else {
            Text('暂无进行中的订单')
              .fontSize(14)
              .fontColor('#ccc')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20 })

        Column()
          .width('100%')
          .height(110)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  @Builder
  ServiceCardItem(icon: string, name: string) {
    Column() {
      Text(icon)
        .fontSize(28)
        .margin({ bottom: 6 })
      Text(name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
    }
    .width(90)
    .height(70)
    .backgroundColor('#fff')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
    .onClick(() => {
      AppStorage.setOrCreate('selectedServiceType', name)
      AppStorage.setOrCreate('activeTab', 1)
    })
  }

  @Builder
  OrderCard(order: OrderItem) {
    Row() {
      Column() {
        Text(order.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
        Text(order.order_no)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.getStatusLabel(order.status))
        .fontSize(12)
        .fontColor(this.getStatusColor(order.status))
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(this.getStatusBg(order.status))
        .borderRadius(4)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#fff')
    .borderRadius(10)
    .margin({ bottom: 10 })
    .shadow({ radius: 2, color: '#00000005', offsetY: 1 })
  }

  private loadOrders(): void {
    this.isLoading = true
    fetchOrders()
      .then((orders: OrderItem[]) => {
        this.orders = orders
        this.isLoading = false
      })
      .catch(() => {
        this.isLoading = false
      })
  }

  private getStatusLabel(status: string): string {
    const map: Record<string, string> = {
      'created': '已创建',
      'pending_dispatch': '待派单',
      'pending_accept': '待接单',
      'in_service': '服务中',
      'completed': '已完成',
      'pending_arrive': '待到场',
      'pending_confirm': '待确认',
      'closed': '已关闭'
    }
    return map[status] || status
  }

  private getStatusColor(status: string): string {
    if (status === 'completed' || status === 'pending_confirm') return '#52c41a'
    if (status === 'in_service') return '#1677ff'
    return '#faad14'
  }

  private getStatusBg(status: string): string {
    if (status === 'completed' || status === 'pending_confirm') return '#f6ffed'
    if (status === 'in_service') return '#e6f4ff'
    return '#fffbe6'
  }
}
