/**
 * 邻里 - 主入口页面
 * 根据角色切换显示居民端/服务人员端视图
 * 使用 Tabs 组件实现底部导航（移动端）或侧边导航（大屏设备）
 */

import { mediaquery } from '@kit.ArkUI';
import { LoginPage } from './LoginPage';
import { ResidentHomePage } from './ResidentHomePage';
import { WorkerHomePage } from './WorkerHomePage';
import { ServiceRequestPage } from './ServiceRequestPage';
import { CheckInPage } from './CheckInPage';
import { getUserInfo, ApiClient } from '../common/ApiClient';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State currentRole: string = 'resident'
  @State isSideNav: boolean = false
  @State isLoggedIn: boolean = false
  @State userName: string = ''

  aboutToAppear(): void {
    let listener = mediaquery.matchMediaSync('(width >= 1440vp)')
    this.isSideNav = listener.matches
    listener.on('change', (result: mediaquery.MediaQueryResult) => {
      this.isSideNav = result.matches
    })
    const token: string | undefined = AppStorage.get<string>('token')
    this.isLoggedIn = token !== undefined && token.length > 0
    if (this.isLoggedIn) {
      const client = ApiClient.getInstance()
      client.setToken(token || '')
      getUserInfo()
        .then((info) => {
          this.userName = info.real_name || info.username
          if (info.role === 'worker') {
            this.currentRole = 'worker'
          }
        })
        .catch(() => {
          // 获取用户信息失败
        })
    }
  }

  build() {
    if (!this.isLoggedIn) {
      LoginPage()
    } else {
      Tabs({
        barPosition: this.isSideNav ? BarPosition.Start : BarPosition.End,
        index: this.currentIndex
      }) {
        TabContent() {
          if (this.currentRole === 'resident') {
            ResidentHomePage()
          } else {
            WorkerHomePage()
          }
        }
        .tabBar(this.TabBuilder('首页', '\uD83C\uDFE0', 0))

        TabContent() {
          if (this.currentRole === 'resident') {
            ServiceRequestPage()
          } else {
            CheckInPage()
          }
        }
        .tabBar(this.TabBuilder(this.currentRole === 'resident' ? '申请' : '待办', '\uD83D\uDCDD', 1))

        TabContent() {
          Column() {
            Text('消息')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .margin({ top: 20 })
            Text('暂无新消息')
              .fontSize(14)
              .fontColor('#999')
              .margin({ top: 100 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#f5f7fa')
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar(this.TabBuilder('消息', '\uD83D\uDCAC', 2))

        TabContent() {
          this.MyPage()
        }
        .tabBar(this.TabBuilder('我的', '\uD83D\uDC64', 3))
      }
      .vertical(this.isSideNav)
      .barMode(this.isSideNav ? BarMode.Fixed : BarMode.Scrollable)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  TabBuilder(title: string, icon: string, index: number) {
    Column() {
      Text(icon)
        .fontSize(this.isSideNav ? 24 : 20)
      Text(title)
        .fontSize(this.isSideNav ? 14 : 11)
        .fontColor(this.currentIndex === index ? '#1677ff' : '#999')
        .margin({ top: this.isSideNav ? 8 : 2 })
    }
    .width(this.isSideNav ? '100%' : undefined)
    .height(this.isSideNav ? undefined : '100%')
    .padding(this.isSideNav ? { top: 12, bottom: 12 } : { top: 4 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  MyPage() {
    Column() {
      Row() {
        Text('\uD83D\uDC64')
          .fontSize(40)
          .margin({ right: 16 })
        Column() {
          Text(this.userName || '用户')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333')
          Text(this.currentRole === 'resident' ? '居民用户' : '服务人员')
            .fontSize(13)
            .fontColor('#999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#fff')
      .margin({ bottom: 12 })

      Column() {
        Text('切换角色视图')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333')
          .width('100%')
          .margin({ bottom: 12 })

        Row() {
          Text('居民端')
            .fontSize(14)
            .fontColor(this.currentRole === 'resident' ? '#fff' : '#666')
            .backgroundColor(this.currentRole === 'resident' ? '#1677ff' : '#f0f0f0')
            .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            .borderRadius(20)
            .onClick(() => {
              this.currentRole = 'resident'
            })

          Text('服务人员端')
            .fontSize(14)
            .fontColor(this.currentRole === 'worker' ? '#fff' : '#666')
            .backgroundColor(this.currentRole === 'worker' ? '#1677ff' : '#f0f0f0')
            .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            .borderRadius(20)
            .margin({ left: 12 })
            .onClick(() => {
              this.currentRole = 'worker'
            })
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#fff')
      .margin({ bottom: 12 })

      Column() {
        this.SettingItem('个人资料', '\uD83D\uDC64')
        this.SettingItem('服务地址管理', '\uD83D\uDCCD')
        this.SettingItem('消息通知设置', '\uD83D\uDD14')
        this.SettingItem('帮助与反馈', '\u2753')
        this.SettingItem('关于邻里', '\u2139')
      }
      .width('100%')
      .backgroundColor('#fff')

      Button('退出登录')
        .width('90%')
        .height(44)
        .fontSize(15)
        .fontColor('#ff4d4f')
        .backgroundColor('#fff')
        .borderWidth(1)
        .borderColor('#ffccc7')
        .borderRadius(8)
        .margin({ top: 24 })
        .onClick(() => {
          this.isLoggedIn = false
          ApiClient.getInstance().clearToken()
          AppStorage.setOrCreate<string>('token', '')
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  @Builder
  SettingItem(label: string, icon: string) {
    Row() {
      Text(icon)
        .fontSize(18)
        .margin({ right: 12 })
      Text(label)
        .fontSize(15)
        .fontColor('#333')
        .layoutWeight(1)
      Text('>')
        .fontSize(16)
        .fontColor('#ccc')
    }
    .width('100%')
    .height(50)
    .padding({ left: 20, right: 20 })
    .onClick(() => {
      // placeholder
    })
  }
}
