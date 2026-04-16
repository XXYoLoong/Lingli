/**
 * 服务结果提交页面 - 调用后端完成工单接口
 */

import { completeOrder } from '../common/ApiClient';
import { abilityAccessCtrl, common, Permissions, Want } from '@kit.AbilityKit';

@Component
export struct ServiceResultPage {
  @StorageLink('currentOrderId') orderId: string = ''
  @StorageLink('currentOrderNo') orderNo: string = ''
  @StorageLink('currentOrderTitle') orderTitle: string = ''

  @State result: string = ''
  @State hasAbnormal: boolean = false
  @State abnormalReason: string = ''
  @State isSubmitting: boolean = false
  @State photoUris: string[] = []
  @State statusMsg: string = ''
  @State selectedTags: string[] = []
  @State capturing: boolean = false
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
      Text(this.orderNo || '请选择工单')
        .fontSize(14)
        .fontColor('#999')
        .margin({ bottom: 6 })
      Text(this.orderTitle || '未选择工单')
        .fontSize(16)
        .fontColor('#666')
        .margin({ bottom: 24 })

      Column() {
        Text('现场图片')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')
          .margin({ bottom: 12 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.photoUris, (uri: string, index: number) => {
            Column() {
              Text('图片' + (index + 1))
                .fontSize(12)
                .fontColor('#666')
              Text(uri)
                .fontSize(9)
                .fontColor('#999')
                .maxLines(1)
                .margin({ top: 4, left: 4, right: 4 })
            }
            .width(80)
            .height(80)
            .backgroundColor('#f0f0f0')
            .borderRadius(8)
            .margin({ right: 10, bottom: 10 })
            .justifyContent(FlexAlign.Center)
          }, (uri: string) => uri)

          if (this.photoUris.length < 3) {
            Column() {
              Text(this.capturing ? '...' : '+')
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
              this.capturePhoto()
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
        .margin({ bottom: 98 })
        .onClick(() => {
          this.submitResult()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
    .padding({ left: 20, right: 20 })
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
      return
    }

    const appendList: string[] = []
    let k = 0
    while (k < this.selectedTags.length) {
      appendList.push(this.selectedTags[k])
      k++
    }
    appendList.push(tag)
    this.selectedTags = appendList
  }

  private submitResult(): void {
    if (this.orderId.length === 0) {
      this.statusMsg = '请先在待办列表选择工单'
      return
    }
    this.isSubmitting = true
    this.statusMsg = ''

    const mergedReason = this.buildAbnormalReason()
    let body = `{"service_result":"${this.escapeJson(this.result)}","abnormal_flag":${this.hasAbnormal}`
    if (this.hasAbnormal && mergedReason.length > 0) {
      body += `,"abnormal_reason":"${this.escapeJson(mergedReason)}"`
    }
    body += `,"attachment_keys":${this.buildAttachmentJson()}`
    body += '}'

    completeOrder(this.orderId, body)
      .then(() => {
        this.isSubmitting = false
        this.statusMsg = '工单完成提交成功！'
      })
      .catch((err: Error) => {
        this.isSubmitting = false
        this.statusMsg = '提交失败: ' + err.message
      })
  }

  private buildAbnormalReason(): string {
    let reason = this.abnormalReason
    if (this.selectedTags.length > 0) {
      let tags = ''
      let i = 0
      while (i < this.selectedTags.length) {
        if (i > 0) {
          tags += '、'
        }
        tags += this.selectedTags[i]
        i++
      }
      reason = reason.length > 0 ? `${tags}；${reason}` : tags
    }
    return reason
  }

  private buildAttachmentJson(): string {
    if (this.photoUris.length === 0) {
      return '[]'
    }
    let text = '['
    let i = 0
    while (i < this.photoUris.length) {
      if (i > 0) {
        text += ','
      }
      text += `"${this.escapeJson(this.photoUris[i])}"`
      i++
    }
    text += ']'
    return text
  }

  private async capturePhoto(): Promise<void> {
    if (this.capturing || this.photoUris.length >= 3) {
      return
    }

    const ctx = this.getAbilityContext()
    if (!ctx) {
      this.statusMsg = '当前页面上下文不可用，请稍后重试'
      return
    }
    const granted = await this.requestPermissions(ctx, [
      'ohos.permission.CAMERA' as Permissions
    ])
    if (!granted) {
      this.statusMsg = '未授予相机权限，无法拍照'
      return
    }

    this.capturing = true
    try {
      const want: Want = {
        action: 'ohos.want.action.imageCapture'
      }
      const result = await ctx.startAbilityForResult(want)
      const params = result.want?.parameters as Record<string, string> | undefined
      const uri = (params?.resourceUri || params?.uri || '').trim()
      if (uri.length > 0) {
        const next: string[] = []
        let i = 0
        while (i < this.photoUris.length) {
          next.push(this.photoUris[i])
          i++
        }
        next.push(uri)
        this.photoUris = next
        this.statusMsg = '拍照成功'
      } else {
        this.statusMsg = '拍照完成，但未读取到照片路径'
      }
    } catch (_err) {
      this.statusMsg = '拍照失败，请重试'
    } finally {
      this.capturing = false
    }
  }

  private async requestPermissions(ctx: common.UIAbilityContext | undefined, perms: Permissions[]): Promise<boolean> {
    if (!ctx) {
      return false
    }
    const atManager = abilityAccessCtrl.createAtManager()
    try {
      const result = await atManager.requestPermissionsFromUser(ctx, perms)
      if (!result.authResults || result.authResults.length === 0) {
        return false
      }
      let i = 0
      while (i < result.authResults.length) {
        if (result.authResults[i] !== 0) {
          return false
        }
        i++
      }
      return true
    } catch (_err) {
      return false
    }
  }

  private escapeJson(raw: string): string {
    return raw.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n')
  }

  private getAbilityContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    return hostContext as common.UIAbilityContext | undefined
  }
}
