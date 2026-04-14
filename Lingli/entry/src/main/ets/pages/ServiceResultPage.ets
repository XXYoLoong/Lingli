@Component
export struct ServiceResultPage {
  @State result: string = ''
  @State hasAbnormal: boolean = false
  @State abnormalReason: string = ''
  @State isSubmitting: boolean = false
  @State photoCount: number = 0
  private abnormalTags: string[] = [
    '客户不在家', '设备损坏', '无法进入', '客户取消',
    '缺少配件', '需要二次上门', '安全隐患'
  ]

  build() {
    Column() {
      Text('服务结果')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 20, bottom: 8 })
      Text('工单 NL202604140002')
        .fontSize(14)
        .fontColor('#999')
        .margin({ bottom: 24 })

      Column() {
        Text('现场图片')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')
          .margin({ bottom: 12 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.getPhotoList(), (item: number) => {
            Column() {
              Text('图片' + (item + 1))
                .fontSize(12)
                .fontColor('#999')
            }
            .width(80)
            .height(80)
            .backgroundColor('#f0f0f0')
            .borderRadius(8)
            .margin({ right: 10, bottom: 10 })
            .justifyContent(FlexAlign.Center)
          }, (item: number) => 'photo-' + item)

          if (this.photoCount < 3) {
            Column() {
              Text('+')
                .fontSize(28)
                .fontColor('#ccc')
            }
            .width(80)
            .height(80)
            .backgroundColor('#f9f9f9')
            .borderRadius(8)
            .borderWidth(1)
            .borderStyle(BorderStyle.Dashed)
            .borderColor('#ddd')
            .margin({ right: 10, bottom: 10 })
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (this.photoCount < 3) {
                this.photoCount++
              }
            })
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding({ bottom: 24 })

      Column() {
        Text('服务描述')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')
          .margin({ bottom: 8 })
        TextArea({ text: this.result, placeholder: '请描述本次服务的具体内容和结果' })
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .height(120)
          .onChange((value: string) => {
            this.result = value
          })
      }
      .width('100%')
      .padding({ bottom: 24 })

      if (this.hasAbnormal) {
        Column() {
          Text('异常标签')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 12 })
          Text('异常上报功能已启用')
            .fontSize(14)
            .fontColor('#ff4d4f')
        }
        .width('100%')
        .padding({ bottom: 20 })
      }

      Blank()

      Button(this.isSubmitting ? '提交中...' : '完成提交')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.result.length > 0 ? '#52c41a' : '#ccc')
        .borderRadius(8)
        .enabled(this.result.length > 0 && !this.isSubmitting)
        .margin({ bottom: 30 })
        .onClick(() => {
          this.isSubmitting = true
          this.isSubmitting = false
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
    .padding({ left: 20, right: 20 })
  }

  private getPhotoList(): number[] {
    const list: number[] = []
    let i = 0
    while (i < this.photoCount) {
      list.push(i)
      i++
    }
    return list
  }
}
