@Component
export struct ResidentHomePage {
  @State currentRole: string = 'resident'

  build() {
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
        this.ServiceCardItem('维修服务')
        this.ServiceCardItem('保洁服务')
        this.ServiceCardItem('助餐服务')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ top: 20 })

      Row() {
        this.ServiceCardItem('陪诊服务')
        this.ServiceCardItem('代办服务')
        this.ServiceCardItem('照护服务')
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
        Text('暂无进行中的订单')
          .fontSize(14)
          .fontColor('#ccc')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  @Builder
  ServiceCardItem(name: string) {
    Column() {
      Text(name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
    }
    .width(100)
    .height(60)
    .backgroundColor('#fff')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }
}
