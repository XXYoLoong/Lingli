/**
 * 服务人员签到页面 - 调用后端签到接口
 */

import { checkInOrder } from '../common/ApiClient';
import { abilityAccessCtrl, common, Permissions, Want } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';

@Component
export struct CheckInPage {
  @StorageLink('currentOrderId') orderId: string = ''
  @StorageLink('currentOrderNo') orderNo: string = ''
  @StorageLink('currentOrderTitle') orderTitle: string = ''
  @StorageLink('currentOrderAddress') orderAddress: string = ''
  @StorageLink('currentOrderContactName') contactName: string = ''
  @StorageLink('currentOrderContactPhone') contactPhone: string = ''

  @State checkInCode: string = ''
  @State locationInfo: string = '点击获取定位'
  @State hasLocation: boolean = false
  @State isCheckingIn: boolean = false
  @State photoTaken: boolean = false
  @State photoUri: string = ''
  @State statusMsg: string = ''
  @State locating: boolean = false
  @State scanning: boolean = false
  @State capturing: boolean = false
  @State latitude: number = 0
  @State longitude: number = 0

  build() {
    Column() {
      Text('到场签到')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333')
        .margin({ top: 20, bottom: 24 })

      Column() {
        Text(this.orderNo || '请选择待办工单')
          .fontSize(14)
          .fontColor('#999')
          .margin({ bottom: 4 })
        Text(this.orderTitle || '未选择工单')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .margin({ bottom: 8 })
        Text(this.orderAddress || '暂无服务地址')
          .fontSize(14)
          .fontColor('#666')
        Row() {
          Text(this.contactName || '暂无联系人')
            .fontSize(14)
            .fontColor('#666')
          if (this.contactPhone.length > 0) {
            Text(this.contactPhone)
              .fontSize(14)
              .fontColor('#666')
              .margin({ left: 16 })
          }
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
          this.fetchCurrentLocation()
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
        Button(this.scanning ? '扫码中...' : '扫码填写服务码')
          .width('100%')
          .height(36)
          .fontSize(14)
          .backgroundColor('#f0f2f5')
          .fontColor('#1677ff')
          .enabled(!this.scanning)
          .margin({ top: 8 })
          .onClick(() => {
            this.scanCheckInCode()
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
            Text(this.photoUri.length > 0 ? this.photoUri : '未获取照片路径')
              .fontSize(10)
              .fontColor('#999')
              .maxLines(1)
              .margin({ top: 6, left: 12, right: 12 })
          }
          .width('100%')
          .height(120)
          .backgroundColor('#f6ffed')
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.capturePhoto()
          })
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
            this.capturePhoto()
          })
        }
      }
      .width('100%')
      .padding({ bottom: 40 })

      if (this.statusMsg.length > 0) {
        Text(this.statusMsg)
          .fontSize(14)
          .fontColor(this.statusMsg.includes('成功') ? '#52c41a' : '#ff4d4f')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })
      }

      Blank()

      Button(this.isCheckingIn ? '签到中...' : '确认签到')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.canCheckIn() ? '#1677ff' : '#ccc')
        .borderRadius(8)
        .enabled(this.canCheckIn() && !this.isCheckingIn)
        .margin({ bottom: 98 })
        .onClick(() => {
          this.doCheckIn()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
    .padding({ left: 20, right: 20 })
  }

  private canCheckIn(): boolean {
    return this.hasLocation && this.checkInCode.length > 0 && this.orderId.length > 0
  }

  private doCheckIn(): void {
    if (this.orderId.length === 0) {
      this.statusMsg = '请先在待办列表中选择工单'
      return
    }

    this.isCheckingIn = true
    this.statusMsg = ''

    let body = `{"check_in_code":"${this.escapeJson(this.checkInCode)}"`
    if (this.hasLocation) {
      body += `,"longitude":${Math.round(this.longitude * 1000000)}`
      body += `,"latitude":${Math.round(this.latitude * 1000000)}`
    }
    body += '}'

    checkInOrder(this.orderId, body)
      .then(() => {
        this.isCheckingIn = false
        this.statusMsg = '签到成功，已切换到结果回填'
        AppStorage.setOrCreate('workerActionMode', 'result')
        AppStorage.setOrCreate('activeTab', 1)
      })
      .catch((err: Error) => {
        this.isCheckingIn = false
        this.statusMsg = '签到失败: ' + err.message
      })
  }

  private async fetchCurrentLocation(): Promise<void> {
    if (this.locating) {
      return
    }
    const ctx = this.getAbilityContext()
    if (!ctx) {
      this.hasLocation = false
      this.locationInfo = '当前页面上下文不可用，请稍后重试'
      return
    }
    const granted = await this.requestPermissions(ctx, [
      'ohos.permission.LOCATION' as Permissions,
      'ohos.permission.APPROXIMATELY_LOCATION' as Permissions
    ])
    if (!granted) {
      this.hasLocation = false
      this.locationInfo = '未授予定位权限'
      return
    }

    this.locating = true
    this.locationInfo = '正在定位...'

    try {
      const location = await geoLocationManager.getCurrentLocation()
      this.latitude = location.latitude || 0
      this.longitude = location.longitude || 0
      const lat = this.latitude.toFixed(6)
      const lng = this.longitude.toFixed(6)
      this.hasLocation = true
      this.locationInfo = `已定位 ${lat}, ${lng}`
    } catch (_err) {
      this.hasLocation = false
      this.locationInfo = '定位失败，请检查系统定位开关'
    } finally {
      this.locating = false
    }
  }

  private async scanCheckInCode(): Promise<void> {
    if (this.scanning) {
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
      this.statusMsg = '未授予相机权限，无法扫码'
      return
    }

    this.scanning = true
    const want: Want = {
      action: 'ohos.want.action.scan'
    }
    try {
      const result = await ctx.startAbilityForResult(want)
      const params = result.want?.parameters as Record<string, string> | undefined
      const scanned = (params?.scanResult || params?.SCAN_RESULT || params?.barcode_string_value || '').trim()
      if (scanned.length > 0) {
        this.checkInCode = scanned
        this.statusMsg = '扫码成功'
      } else {
        this.statusMsg = '未识别到二维码内容，请重试'
      }
    } catch (_err) {
      this.statusMsg = '扫码失败，请稍后重试'
    } finally {
      this.scanning = false
    }
  }

  private async capturePhoto(): Promise<void> {
    if (this.capturing) {
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
      this.photoTaken = true
      this.photoUri = uri
      this.statusMsg = uri.length > 0 ? '拍照成功' : '拍照完成，但未读取到照片路径'
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
