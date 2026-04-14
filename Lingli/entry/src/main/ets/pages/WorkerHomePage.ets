@Component
export struct WorkerHomePage {
  @State selectedTab: number = 0
  private tabs: TabItem[] = [
    { key: 'todo', label: '待办' },
    { key: 'done', label: '已完成' },
    { key: 'all', label: '全部' }
  ]
  private tasks: WorkerTask[] = [
    {
      id: '1',
      order_no: 'NL202604140001',
      title: '水龙头维修',
      status: 'pending_arrive',
      address: '阳光花园3栋2单元501',
      contactName: '张阿姨',
      contactPhone: '138****1234',
      appointmentTime: '今天 10:00'
    },
    {
      id: '2',
      order_no: 'NL202604140002',
      title: '家庭保洁',
      status: 'in_service',
      address: '翠湖小区7栋1单元302',
      contactName: '李大爷',
      contactPhone: '139****5678',
      appointmentTime: '今天 14:00'
    }
  ]

  build() {
    Column() {
      Row() {
        Column() {
          Text('我的工作')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1677ff')
          Text('今天有 2 个待办任务')
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
        ForEach(this.tabs, (item: TabItem) => {
          Text(item.label)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#999')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#f0f0f0')
            .borderRadius(16)
            .margin({ right: 8 })
        }, (item: TabItem) => item.key)
      }
      .width('100%')
      .padding({ left: 20, top: 10, bottom: 10 })

      List({ space: 12 }) {
        ForEach(this.tasks, (task: WorkerTask) => {
          ListItem() {
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
                Text(task.status)
                  .fontSize(12)
                  .fontColor('#1677ff')
              }
              .width('100%')
              Row() {
                Text(task.address)
                  .fontSize(13)
                  .fontColor('#666')
                  .layoutWeight(1)
                  .maxLines(1)
              }
              .width('100%')
              .margin({ top: 10, bottom: 4 })
              Row() {
                Text(task.contactName + '  ' + task.contactPhone)
                  .fontSize(13)
                  .fontColor('#666')
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
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#fff')
            .borderRadius(12)
          }
        }, (task: WorkerTask) => task.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }
}

interface WorkerTask {
  id: string
  order_no: string
  title: string
  status: string
  address: string
  contactName: string
  contactPhone: string
  appointmentTime: string
}

interface TabItem {
  key: string
  label: string
}
