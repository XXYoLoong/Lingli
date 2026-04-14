/**
 * 服务申请页面 - 提交工单到后端
 */

import { createOrder } from '../common/ApiClient';

@Component
export struct ServiceRequestPage {
  @State title: string = ''
  @State description: string = ''
  @State contactName: string = ''
  @State contactPhone: string = ''
  @State address: string = ''
  @State selectedType: string = ''
  @State isSubmitting: boolean = false
  @State submitResult: string = ''
  private serviceTypes: string[] = ['维修', '保洁', '助餐', '陪诊', '代办', '照护']

  build() {
    Scroll() {
      Column() {
        Column() {
          Text('服务类型')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 12 })
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.serviceTypes, (type: string) => {
              Text(type)
                .fontSize(14)
                .fontColor(this.selectedType === type ? '#fff' : '#333')
                .backgroundColor(this.selectedType === type ? '#1677ff' : '#f0f0f0')
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(20)
                .margin({ right: 10, bottom: 10 })
                .onClick(() => {
                  this.selectedType = type
                })
            }, (type: string) => type)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })

        Column() {
          Text('工单标题')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 8 })
          TextInput({ text: this.title, placeholder: '请简要描述您的需求' })
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .height(44)
            .onChange((value: string) => {
              this.title = value
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })

        Column() {
          Text('补充说明')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 8 })
          TextArea({ text: this.description, placeholder: '请补充详细说明' })
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .height(100)
            .onChange((value: string) => {
              this.description = value
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })

        Column() {
          Text('联系人')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 12 })
          TextInput({ text: this.contactName, placeholder: '联系人姓名' })
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .height(44)
            .margin({ bottom: 12 })
            .onChange((value: string) => {
              this.contactName = value
            })
          TextInput({ text: this.contactPhone, placeholder: '联系电话' })
            .type(InputType.PhoneNumber)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .height(44)
            .onChange((value: string) => {
              this.contactPhone = value
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })

        Column() {
          Text('服务地址')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 8 })
          TextInput({ text: this.address, placeholder: '请输入详细地址' })
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .height(44)
            .onChange((value: string) => {
              this.address = value
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 40 })

        if (this.submitResult.length > 0) {
          Text(this.submitResult)
            .fontSize(14)
            .fontColor('#52c41a')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })
        }

        Row() {
          Button('保存草稿')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .backgroundColor('#fff')
            .fontColor('#333')
            .borderWidth(1)
            .borderColor('#ddd')
            .borderRadius(8)
            .margin({ right: 10 })
          Button(this.isSubmitting ? '提交中...' : '提交工单')
            .layoutWeight(1)
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#1677ff')
            .borderRadius(8)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.submitOrder()
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 30 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  private submitOrder(): void {
    if (this.selectedType.length === 0) {
      this.submitResult = '请选择服务类型'
      return
    }
    if (this.title.length === 0) {
      this.submitResult = '请输入工单标题'
      return
    }

    this.isSubmitting = true
    this.submitResult = ''

    let body = `{"service_type":"${this.selectedType}","title":"${this.title}"`
    if (this.contactName.length > 0) {
      body += `,"contact_name":"${this.contactName}"`
    }
    if (this.contactPhone.length > 0) {
      body += `,"contact_phone":"${this.contactPhone}"`
    }
    if (this.address.length > 0) {
      body += `,"service_address":"${this.address}"`
    }
    if (this.description.length > 0) {
      body += `,"description":"${this.description}"`
    }
    body += '}'

    createOrder(body)
      .then(() => {
        this.isSubmitting = false
        this.submitResult = '工单提交成功！'
        this.title = ''
        this.description = ''
        this.contactName = ''
        this.contactPhone = ''
        this.address = ''
        this.selectedType = ''
      })
      .catch((err: Error) => {
        this.isSubmitting = false
        this.submitResult = '提交失败: ' + err.message
      })
  }
}
