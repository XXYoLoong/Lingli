/**
 * 服务申请页面 - 提交工单到后端
 */

import { createOrder } from '../common/ApiClient';
import { abilityAccessCtrl, common, Permissions, Want } from '@kit.AbilityKit';

@Component
export struct ServiceRequestPage {
  @State title: string = ''
  @State description: string = ''
  @State contactName: string = ''
  @State contactPhone: string = ''
  @State address: string = ''
  @StorageLink('selectedServiceType') selectedType: string = ''
  @State familyServiceCode: string = ''
  @State isSubmitting: boolean = false
  @State submitResult: string = ''
  @State showFamilyCodeDialog: boolean = false
  @State familyCodeInput: string = ''
  @State scanningFamilyCode: boolean = false
  private serviceTypes: string[] = ['维修', '保洁', '助餐', '陪诊', '代办', '照护']

  aboutToAppear(): void {
    this.restoreDraft()
  }

  build() {
    Stack() {
      this.RequestForm()

      if (this.showFamilyCodeDialog) {
        this.FamilyCodeDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  @Builder
  RequestForm() {
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
        .padding({ left: 20, right: 20, bottom: 20 })

        Column() {
          Text('家庭服务码')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Text(this.familyServiceCode.length > 0 ? this.familyServiceCode : '未填写')
              .fontSize(14)
              .fontColor(this.familyServiceCode.length > 0 ? '#333' : '#999')
              .layoutWeight(1)
            Button('扫描/填写')
              .height(34)
              .fontSize(13)
              .fontColor('#1677ff')
              .backgroundColor('#EAF3FF')
              .borderRadius(17)
              .onClick(() => {
                this.openFamilyCodeDialog()
              })
          }
          .width('100%')
          .padding({ left: 12, right: 8 })
          .height(44)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 30 })

        if (this.submitResult.length > 0) {
          Text(this.submitResult)
            .fontSize(14)
            .fontColor(this.submitResult.indexOf('成功') >= 0 ? '#52c41a' : '#ff4d4f')
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
            .onClick(() => {
              this.saveDraft()
            })
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
        .padding({ left: 20, right: 20, bottom: 90 })

        Column()
          .width('100%')
          .height(24)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FamilyCodeDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          this.showFamilyCodeDialog = false
        })

      Column() {
        Text('输入家庭服务码')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 16 })

        Row({ space: 8 }) {
          ForEach(this.getCodeIndexList(), (idx: number) => {
            Text(this.getCodeChar(idx))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333')
              .width(30)
              .height(38)
              .textAlign(TextAlign.Center)
              .backgroundColor('#F5F7FA')
              .borderRadius(6)
          }, (idx: number) => idx.toString())
        }
        .margin({ bottom: 12 })

        TextInput({ text: this.familyCodeInput, placeholder: '可手动输入服务码' })
          .width('100%')
          .height(40)
          .maxLength(8)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.familyCodeInput = this.normalizeCode(value)
          })

        Button(this.scanningFamilyCode ? '扫描中...' : '点击扫描')
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor('#1677ff')
          .borderRadius(8)
          .enabled(!this.scanningFamilyCode)
          .margin({ top: 12 })
          .onClick(() => {
            this.scanFamilyCode()
          })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .fontColor('#666')
            .backgroundColor('#f0f0f0')
            .borderRadius(8)
            .margin({ right: 8 })
            .onClick(() => {
              this.showFamilyCodeDialog = false
            })
          Button('确定')
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor('#1677ff')
            .borderRadius(8)
            .onClick(() => {
              this.confirmFamilyCode()
            })
        }
        .width('100%')
        .margin({ top: 14 })
      }
      .width('86%')
      .padding({ left: 16, right: 16, top: 18, bottom: 16 })
      .backgroundColor('#fff')
      .borderRadius(14)
      .onClick(() => {
      })
    }
    .width('100%')
    .height('100%')
  }

  private openFamilyCodeDialog(): void {
    this.familyCodeInput = this.familyServiceCode
    this.showFamilyCodeDialog = true
  }

  private confirmFamilyCode(): void {
    this.familyServiceCode = this.familyCodeInput
    this.showFamilyCodeDialog = false
  }

  private getCodeIndexList(): number[] {
    return [0, 1, 2, 3, 4, 5, 6, 7]
  }

  private getCodeChar(idx: number): string {
    if (idx >= this.familyCodeInput.length) {
      return ''
    }
    return this.familyCodeInput.substring(idx, idx + 1)
  }

  private normalizeCode(raw: string): string {
    return raw.replace(/\s/g, '').toUpperCase().substring(0, 8)
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

    let body = `{"service_type":"${this.escapeJson(this.selectedType)}","title":"${this.escapeJson(this.title)}"`
    if (this.contactName.length > 0) {
      body += `,"contact_name":"${this.escapeJson(this.contactName)}"`
    }
    if (this.contactPhone.length > 0) {
      body += `,"contact_phone":"${this.escapeJson(this.contactPhone)}"`
    }
    if (this.address.length > 0) {
      body += `,"service_address":"${this.escapeJson(this.address)}"`
    }
    if (this.description.length > 0) {
      body += `,"description":"${this.escapeJson(this.description)}"`
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
        this.familyServiceCode = ''
        this.clearDraft()
      })
      .catch((err: Error) => {
        this.isSubmitting = false
        this.submitResult = '提交失败: ' + err.message
      })
  }

  private saveDraft(): void {
    AppStorage.setOrCreate('draft_request_title', this.title)
    AppStorage.setOrCreate('draft_request_description', this.description)
    AppStorage.setOrCreate('draft_request_contact_name', this.contactName)
    AppStorage.setOrCreate('draft_request_contact_phone', this.contactPhone)
    AppStorage.setOrCreate('draft_request_address', this.address)
    AppStorage.setOrCreate('draft_request_type', this.selectedType)
    AppStorage.setOrCreate('draft_request_family_code', this.familyServiceCode)
    this.submitResult = '草稿已保存'
  }

  private restoreDraft(): void {
    const title = AppStorage.get<string>('draft_request_title')
    const description = AppStorage.get<string>('draft_request_description')
    const contactName = AppStorage.get<string>('draft_request_contact_name')
    const contactPhone = AppStorage.get<string>('draft_request_contact_phone')
    const address = AppStorage.get<string>('draft_request_address')
    const draftType = AppStorage.get<string>('draft_request_type')
    const familyCode = AppStorage.get<string>('draft_request_family_code')

    if (this.title.length === 0 && title) {
      this.title = title
    }
    if (this.description.length === 0 && description) {
      this.description = description
    }
    if (this.contactName.length === 0 && contactName) {
      this.contactName = contactName
    }
    if (this.contactPhone.length === 0 && contactPhone) {
      this.contactPhone = contactPhone
    }
    if (this.address.length === 0 && address) {
      this.address = address
    }
    if (this.selectedType.length === 0 && draftType) {
      this.selectedType = draftType
    }
    if (this.familyServiceCode.length === 0 && familyCode) {
      this.familyServiceCode = familyCode
    }
  }

  private clearDraft(): void {
    AppStorage.setOrCreate('draft_request_title', '')
    AppStorage.setOrCreate('draft_request_description', '')
    AppStorage.setOrCreate('draft_request_contact_name', '')
    AppStorage.setOrCreate('draft_request_contact_phone', '')
    AppStorage.setOrCreate('draft_request_address', '')
    AppStorage.setOrCreate('draft_request_type', '')
    AppStorage.setOrCreate('draft_request_family_code', '')
  }

  private async scanFamilyCode(): Promise<void> {
    if (this.scanningFamilyCode) {
      return
    }
    const ctx = this.getAbilityContext()
    if (!ctx) {
      this.submitResult = '当前页面上下文不可用，请稍后重试'
      return
    }
    const granted = await this.requestPermissions(ctx, ['ohos.permission.CAMERA' as Permissions])
    if (!granted) {
      this.submitResult = '未授予相机权限，无法扫码'
      return
    }

    this.scanningFamilyCode = true
    const want: Want = {
      action: 'ohos.want.action.scan'
    }
    try {
      const result = await ctx.startAbilityForResult(want)
      const params = result.want?.parameters as Record<string, string> | undefined
      const scanned = (params?.scanResult || params?.SCAN_RESULT || params?.barcode_string_value || '').trim()
      if (scanned.length > 0) {
        this.familyCodeInput = this.normalizeCode(scanned)
      } else {
        this.submitResult = '未识别到服务码，请重试'
      }
    } catch (_err) {
      this.submitResult = '扫码失败，请稍后重试'
    } finally {
      this.scanningFamilyCode = false
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

  private getAbilityContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext()
    return hostContext as common.UIAbilityContext | undefined
  }

  private escapeJson(raw: string): string {
    return raw.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n')
  }
}
