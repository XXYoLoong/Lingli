/**
 * 服务结果提交页面 - 调用后端完成工单接口
 */

import { completeOrder } from '../common/ApiClient';

@Component
export struct ServiceResultPage {
  @State result: string = ''
  @State hasAbnormal: boolean = false
  @State abnormalReason: string = ''
  @State isSubmitting: boolean = false
  @State photoCount: number = 0
  @State statusMsg: string = ''
  @State selectedTags: string[] = []
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

      Column() {
        Text('异常上报')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')
          .margin({ bottom: 12 })

        Toggle({ type: ToggleType.Switch, isOn: this.hasAbnormal })
          .width(50)
          .height(28)
          .onChange((isOn: boolean) => {
            this.hasAbnormal = isOn
          })

        if (this.hasAbnormal) {
          Column() {
            Text('选择异常标签')
              .fontSize(14)
              .fontColor('#666')
              .width('100%')
              .margin({ bottom: 8, top: 12 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.abnormalTags, (tag: string) => {
                Text(tag)
                  .fontSize(13)
                  .fontColor(this.isTagSelected(tag) ? '#fff' : '#666')
                  .backgroundColor(this.isTagSelected(tag) ? '#ff4d4f' : '#f0f0f0')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(16)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => {
                    this.toggleTag(tag)
                  })
              }, (tag: string) => tag)
            }
            .width('100%')

            TextArea({ text: this.abnormalReason, placeholder: '补充说明异常情况' })
              .backgroundColor('#fff5f5')
              .borderRadius(8)
              .height(80)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.abnormalReason = value
              })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ bottom: 20 })

      if (this.statusMsg.length > 0) {
        Text(this.statusMsg)
          .fontSize(14)
          .fontColor(this.statusMsg.includes('成功') ? '#52c41a' : '#ff4d4f')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })
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
          this.submitResult()
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

  private isTagSelected(tag: string): boolean {
    return this.selectedTags.indexOf(tag) >= 0
  }

  private toggleTag(tag: string): void {
    const idx = this.selectedTags.indexOf(tag)
    if (idx >= 0) {
      const newList: string[] = []
      let j = 0
      while (j < this.selectedTags.length) {
        if (j !== idx) {
          newList.push(this.selectedTags[j])
        }
        j++
      }
      this.selectedTags = newList
    } else {
      const newList: string[] = []
      let k = 0
      while (k < this.selectedTags.length) {
        newList.push(this.selectedTags[k])
        k++
      }
      newList.push(tag)
      this.selectedTags = newList
    }
  }

  private submitResult(): void {
    this.isSubmitting = true
    this.statusMsg = ''

    let body = `{"service_result":"${this.result}","abnormal_flag":${this.hasAbnormal}`
    if (this.hasAbnormal && this.abnormalReason.length > 0) {
      body += `,"abnormal_reason":"${this.abnormalReason}"`
    }
    body += '}'

    completeOrder('placeholder-id', body)
      .then(() => {
        this.isSubmitting = false
        this.statusMsg = '工单完成提交成功！'
      })
      .catch((err: Error) => {
        this.isSubmitting = false
        this.statusMsg = '提交失败: ' + err.message
      })
  }
}
