@Component
export struct CheckInPage {
  @State orderId: string = ''
  @State checkInCode: string = ''
  @State locationInfo: string = '正在获取定位...'
  @State hasLocation: boolean = false
  @State isCheckingIn: boolean = false
  @State photoTaken: boolean = false

  build() {
    Column() {
      Text('到场签到')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 20, bottom: 24 })

      Column() {
        Text('NL202604140001')
          .fontSize(14)
          .fontColor('#999')
          .margin({ bottom: 4 })
        Text('水龙头维修')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 8 })
        Text('阳光花园3栋2单元501')
          .fontSize(14)
          .fontColor('#666')
        Row() {
          Text('张阿姨')
            .fontSize(14)
            .fontColor('#666')
          Text('138****1234')
            .fontSize(14)
            .fontColor('#666')
            .margin({ left: 16 })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#fff')
      .borderRadius(12)
      .margin({ bottom: 20 })

      Column() {
        Row() {
          Text('位置信息')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ bottom: 12 })

        Column() {
          Text(this.locationInfo)
            .fontSize(14)
            .fontColor(this.hasLocation ? '#52c41a' : '#999')
        }
        .width('100%')
        .height(40)
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 12 })
        .onClick(() => {
          this.hasLocation = true
          this.locationInfo = '已定位成功'
        })
      }
      .width('100%')
      .padding({ top: 10, bottom: 20 })

      Column() {
        Text('家庭服务码')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')
          .margin({ bottom: 12 })
        TextInput({ text: this.checkInCode, placeholder: '请输入或扫描家庭服务码' })
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .height(48)
          .maxLength(20)
          .onChange((value: string) => {
            this.checkInCode = value
          })
      }
      .width('100%')
      .padding({ bottom: 20 })

      Column() {
        Text('现场拍照')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')
          .margin({ bottom: 12 })

        if (this.photoTaken) {
          Column() {
            Text('已拍照')
              .fontSize(14)
              .fontColor('#52c41a')
              .margin({ top: 8 })
          }
          .width('100%')
          .height(120)
          .backgroundColor('#f6ffed')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
        } else {
          Column() {
            Text('点击拍照')
              .fontSize(14)
              .fontColor('#999')
              .margin({ top: 8 })
          }
          .width('100%')
          .height(120)
          .backgroundColor('#f9f9f9')
          .borderRadius(8)
          .borderWidth(1)
          .borderStyle(BorderStyle.Dashed)
          .borderColor('#ddd')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.photoTaken = true
          })
        }
      }
      .width('100%')
      .padding({ bottom: 40 })

      Blank()

      Button(this.isCheckingIn ? '签到中...' : '确认签到')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.canCheckIn() ? '#1677ff' : '#ccc')
        .borderRadius(8)
        .enabled(this.canCheckIn() && !this.isCheckingIn)
        .margin({ bottom: 30 })
        .onClick(() => {
          this.isCheckingIn = true
          this.isCheckingIn = false
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
    .padding({ left: 20, right: 20 })
  }

  private canCheckIn(): boolean {
    return this.hasLocation && this.checkInCode.length > 0
  }
}
