/**
 * 登录页面 - 连接后端真实登录接口
 */

import { loginApi, type LoginRequest } from '../common/ApiClient';

@Component
export struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State isLoading: boolean = false
  @State errorMsg: string = ''

  build() {
    Column() {
      Column() {
        Text('邻里')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1677ff')
          .margin({ top: 80 })
        Text('社区服务')
          .fontSize(16)
          .fontColor('#999')
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column() {
        Column() {
          Text('手机号')
            .fontSize(14)
            .fontColor('#666')
            .width('100%')
            .margin({ bottom: 8 })
          TextInput({ text: this.phone, placeholder: '请输入手机号' })
            .type(InputType.PhoneNumber)
            .maxLength(11)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .height(48)
            .onChange((value: string) => {
              this.phone = value
            })
        }
        .width('100%')
        .margin({ bottom: 20 })

        Column() {
          Text('密码')
            .fontSize(14)
            .fontColor('#666')
            .width('100%')
            .margin({ bottom: 8 })
          TextInput({ text: this.password, placeholder: '请输入密码' })
            .type(InputType.Password)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)
            .height(48)
            .onChange((value: string) => {
              this.password = value
            })
        }
        .width('100%')
        .margin({ bottom: 32 })

        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(14)
            .fontColor('#ff4d4f')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 16 })
        }

        Button(this.isLoading ? '登录中...' : '登 录')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#1677ff')
          .borderRadius(8)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin()
          })
      }
      .width('85%')
      .padding({ top: 40 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff')
  }

  private handleLogin(): void {
    if (this.phone.length !== 11) {
      this.errorMsg = '请输入正确的手机号'
      return
    }
    if (this.password.length < 6) {
      this.errorMsg = '密码长度不足'
      return
    }

    this.isLoading = true
    this.errorMsg = ''

    const req: LoginRequest = {
      phone: this.phone,
      password: this.password
    }

    loginApi(req)
      .then(() => {
        this.isLoading = false
        AppStorage.setOrCreate<boolean>('isLoggedIn', true)
      })
      .catch((err: Error) => {
        this.isLoading = false
        this.errorMsg = err.message || '登录失败，请检查网络'
      })
  }
}
