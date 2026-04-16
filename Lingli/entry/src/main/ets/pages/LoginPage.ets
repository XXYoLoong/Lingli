/*
 * Copyright 2026 Jiacheng Ni
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * 登录页面 - 连接后端真实登录接口
 */

import { loginApi, type LoginRequest } from '../common/ApiClient';
import { common, Want } from '@kit.AbilityKit';

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

        Row() {
          Text('还没有账号？')
            .fontSize(13)
            .fontColor('#999')
          Text('去注册')
            .fontSize(13)
            .fontColor('#1677ff')
            .fontWeight(FontWeight.Medium)
            .margin({ left: 4 })
            .onClick(() => {
              this.openRegisterWeb()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 14 })
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

  private openRegisterWeb(): void {
    const ctx = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: 'https://harmonycare.cn/login?tab=register'
    };
    ctx.startAbility(want)
      .catch(() => {
        this.errorMsg = '无法打开网页，请稍后重试';
      });
  }
}
