/**
 * 注册页面 - 居民注册
 */

import { registerApi, loginApi, type RegisterRequest, type LoginRequest } from '../common/ApiClient';

@Component
export struct RegisterPage {
  @State phone: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State realName: string = ''
  @State isLoading: boolean = false
  @State errorMsg: string = ''

  build() {
    Column() {
      Column() {
        Text('居民注册')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1677ff')
          .margin({ top: 56 })
        Text('创建邻里社区服务账号')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column() {
        this.formField('姓名（可选）', this.realName, '请输入姓名', InputType.Normal, (value: string) => {
          this.realName = value
        })
        this.formField('手机号', this.phone, '请输入手机号', InputType.PhoneNumber, (value: string) => {
          this.phone = value
        })
        this.formField('密码', this.password, '请输入密码（至少8位）', InputType.Password, (value: string) => {
          this.password = value
        })
        this.formField('确认密码', this.confirmPassword, '请再次输入密码', InputType.Password, (value: string) => {
          this.confirmPassword = value
        })

        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(13)
            .fontColor('#ff4d4f')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 6, bottom: 12 })
        }

        Button(this.isLoading ? '注册中...' : '注 册')
          .width('100%')
          .height(46)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#1677ff')
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleRegister()
          })

        Row() {
          Text('已有账号？')
            .fontSize(13)
            .fontColor('#999')
          Text('去登录')
            .fontSize(13)
            .fontColor('#1677ff')
            .fontWeight(FontWeight.Medium)
            .margin({ left: 4 })
            .onClick(() => {
              AppStorage.setOrCreate<string>('authMode', 'login')
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 14 })
      }
      .width('86%')
      .margin({ top: 30 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff')
  }

  @Builder
  private formField(
    label: string,
    value: string,
    placeholder: string,
    type: InputType,
    onChange: (value: string) => void
  ) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 8 })
      TextInput({ text: value, placeholder: placeholder })
        .type(type)
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .height(46)
        .maxLength(label === '手机号' ? 11 : 40)
        .onChange(onChange)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  private handleRegister(): void {
    if (this.phone.length !== 11) {
      this.errorMsg = '请输入正确手机号'
      return
    }
    if (this.password.length < 8) {
      this.errorMsg = '密码长度至少8位'
      return
    }
    if (this.password !== this.confirmPassword) {
      this.errorMsg = '两次密码不一致'
      return
    }

    this.errorMsg = ''
    this.isLoading = true
    const req: RegisterRequest = {
      username: `u${this.phone}`,
      phone: this.phone,
      password: this.password,
      role: 'resident',
      real_name: this.realName
    }
    registerApi(req)
      .then(() => {
        const loginReq: LoginRequest = {
          phone: this.phone,
          password: this.password
        }
        loginApi(loginReq)
          .then(() => {
            this.isLoading = false
            this.errorMsg = ''
            AppStorage.setOrCreate<boolean>('isLoggedIn', true)
            AppStorage.setOrCreate<string>('authMode', 'login')
          })
          .catch(() => {
            this.isLoading = false
            this.errorMsg = '注册成功，但自动登录失败，请手动登录'
            AppStorage.setOrCreate<string>('authMode', 'login')
          })
      })
      .catch((err: Error) => {
        this.isLoading = false
        if (err.message.indexOf('400') >= 0) {
          this.errorMsg = '该手机号已注册，请直接登录'
        } else {
          this.errorMsg = err.message || '注册失败，请稍后重试'
        }
      })
  }
}
