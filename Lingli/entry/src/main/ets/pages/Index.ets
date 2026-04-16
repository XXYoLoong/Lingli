/**
 * 邻里 - 主入口页面
 * 悬浮导航模式 + 角色切换视图
 */

import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { LoginPage } from './LoginPage';
import { RegisterPage } from './RegisterPage';
import { ResidentHomePage } from './ResidentHomePage';
import { WorkerHomePage } from './WorkerHomePage';
import { ServiceRequestPage } from './ServiceRequestPage';
import { CheckInPage } from './CheckInPage';
import { ServiceResultPage } from './ServiceResultPage';
import {
  ApiClient,
  fetchMessages,
  fetchUnreadCount,
  getUserInfo,
  markAllRead,
  markMessageRead,
  type MessageItem
} from '../common/ApiClient';
import { DeviceInteractionFeatures } from '../common/DeviceInteractionFeatures';

@Entry
@Component
struct Index {
  @StorageLink('activeTab') currentIndex: number = 0
  @StorageLink('workerActionMode') workerActionMode: string = 'checkIn'
  @State currentRole: string = 'resident'
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false
  @StorageLink('authMode') authMode: string = 'login'
  @StorageLink('isAIButtonRight') isNavRight: boolean = true
  @State userName: string = ''
  @State graspFeatureEnabled: boolean = false
  @State isPhoneDevice: boolean = false
  @State messages: MessageItem[] = []
  @State messageLoading: boolean = false
  @State unreadCount: number = 0

  aboutToAppear(): void {
    this.ensureGlobalState()
    AppStorage.setOrCreate('isAIButtonRight', true)
    this.isPhoneDevice = DeviceInteractionFeatures.isPhoneDevice()
    const ctx = this.getAbilityContext()
    DeviceInteractionFeatures.registerShareListeners(ctx)

    AppStorage.setOrCreate<string>('authMode', 'login')
    const token: string | undefined = AppStorage.get<string>('token')
    this.isLoggedIn = token !== undefined && token.length > 0
    if (this.isLoggedIn) {
      const client = ApiClient.getInstance()
      client.setToken(token || '')
      this.loadUserInfo()
      this.loadUnreadCount()
      if (this.currentIndex === 2) {
        this.loadMessages()
      }
    }
  }

  aboutToDisappear(): void {
    DeviceInteractionFeatures.unregisterShareListeners()
    DeviceInteractionFeatures.disableGraspFeature()
  }

  build() {
    Stack() {
      if (!this.isLoggedIn) {
        if (this.authMode === 'register') {
          RegisterPage()
        } else {
          LoginPage()
        }
      } else {
        Stack({ alignContent: this.isNavRight ? Alignment.BottomEnd : Alignment.BottomStart }) {
          Column() {
            this.MainContent()
          }
          .width('100%')
          .height('100%')
          .align(Alignment.TopStart)
          this.FloatingNavBar()
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MainContent() {
    if (this.currentIndex === 0) {
      if (this.currentRole === 'resident') {
        ResidentHomePage()
      } else {
        WorkerHomePage()
      }
    } else if (this.currentIndex === 1) {
      if (this.currentRole === 'resident') {
        ServiceRequestPage()
      } else if (this.workerActionMode === 'result') {
        ServiceResultPage()
      } else {
        CheckInPage()
      }
    } else if (this.currentIndex === 2) {
      this.MessagesPage()
    } else {
      this.MyPage()
    }
  }

  @Builder
  FloatingNavBar() {
    Row() {
      this.NavItem('\uD83C\uDFE0', '首页', 0, 0)
      this.NavItem('\uD83D\uDCDD', this.getSecondTabTitle(), 1, 0)
      this.NavItem('\uD83D\uDCAC', '消息', 2, this.unreadCount)
      this.NavItem('\uD83D\uDC64', '我的', 3, 0)
    }
    .backgroundColor('#FDFDFD')
    .borderRadius(28)
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .shadow({ radius: 12, color: '#33000000', offsetX: 0, offsetY: 4 })
    .margin({ left: 12, right: 12, bottom: 18 })
  }

  @Builder
  NavItem(icon: string, title: string, tabIndex: number, badge: number) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Text(icon)
          .fontSize(20)
          .fontColor(this.currentIndex === tabIndex ? '#1677ff' : '#999')

        if (badge > 0) {
          Text(badge > 99 ? '99+' : badge.toString())
            .fontSize(9)
            .fontColor('#fff')
            .backgroundColor('#ff4d4f')
            .borderRadius(8)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ top: -4, right: -14 })
        }
      }
      .width(24)
      .height(24)

      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === tabIndex ? '#1677ff' : '#999')
        .margin({ top: 4 })
    }
    .width(66)
    .padding({ top: 4, bottom: 4 })
    .borderRadius(18)
    .backgroundColor(this.currentIndex === tabIndex ? '#EAF3FF' : '#FFFFFF')
    .onClick(() => {
      this.switchTab(tabIndex)
    })
  }

  @Builder
  MessagesPage() {
    Column() {
      Row() {
        Text('消息中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        if (this.messages.length > 0) {
          Text('全部已读')
            .fontSize(13)
            .fontColor('#1677ff')
            .onClick(() => {
              this.readAllMessages()
            })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 10 })

      if (this.messageLoading) {
        Text('消息加载中...')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      } else if (this.messages.length === 0) {
        Text('暂无新消息')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      } else {
        List({ space: 10 }) {
          ForEach(this.messages, (msg: MessageItem) => {
            ListItem() {
              this.MessageCard(msg)
            }
          }, (msg: MessageItem) => msg.id)
          ListItem() {
            Column()
              .width('100%')
              .height(110)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  @Builder
  MessageCard(msg: MessageItem) {
    Row() {
      Column() {
        Row() {
          Text(msg.title || '系统消息')
            .fontSize(15)
            .fontWeight(msg.is_read ? FontWeight.Normal : FontWeight.Medium)
            .fontColor('#333')
            .layoutWeight(1)
          if (!msg.is_read) {
            Text('未读')
              .fontSize(11)
              .fontColor('#ff4d4f')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#fff1f0')
              .borderRadius(4)
          }
        }
        .width('100%')

        Text(msg.content || '')
          .fontSize(13)
          .fontColor('#666')
          .maxLines(2)
          .margin({ top: 6 })

        Text(msg.created_at || '')
          .fontSize(11)
          .fontColor('#999')
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#fff')
    .borderRadius(10)
    .onClick(() => {
      this.readOneMessage(msg)
    })
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
              this.currentIndex = 0
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
              this.currentIndex = 0
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

      if (this.isPhoneDevice) {
        Row() {
          Column() {
            Text('智感握姿')
              .fontSize(15)
              .fontColor('#333')
            Text('根据左右手握持，自动调整悬浮导航栏停靠位置')
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.graspFeatureEnabled })
            .selectedColor('#1677ff')
            .onChange((isOn: boolean) => {
              this.graspFeatureEnabled = isOn
              const ctx = this.getAbilityContext()
              if (isOn) {
                DeviceInteractionFeatures.enableGraspFeature(ctx).then((ok: boolean) => {
                  if (!ok) {
                    this.graspFeatureEnabled = false
                    const graspError = DeviceInteractionFeatures.getLastGraspError()
                    if (graspError === 'context_unavailable') {
                      this.safeToast('智感握姿权限申请失败：应用上下文不可用，请重试')
                    } else if (graspError === 'permission_denied') {
                      this.safeToast('未授予智感握姿权限，请在系统权限中允许“检测手势”')
                    } else if (graspError === 'unsupported') {
                      this.safeToast('当前设备暂不支持智感握姿')
                    } else {
                      this.safeToast('智感握姿开启失败，请稍后重试')
                    }
                  }
                })
              } else {
                DeviceInteractionFeatures.disableGraspFeature()
              }
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#fff')
        .margin({ top: 12 })
      }

      Button('退出登录')
        .width('90%')
        .height(44)
        .fontSize(15)
        .fontColor('#ff4d4f')
        .backgroundColor('#fff')
        .borderWidth(1)
        .borderColor('#ffccc7')
        .borderRadius(8)
        .margin({ top: 24, bottom: 90 })
        .onClick(() => {
          DeviceInteractionFeatures.disableGraspFeature()
          this.graspFeatureEnabled = false
          this.isLoggedIn = false
          this.authMode = 'login'
          this.messages = []
          this.unreadCount = 0
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
      this.handleSettingAction(label)
    })
  }

  private switchTab(index: number): void {
    this.currentIndex = index
    if (index === 2) {
      this.loadMessages()
    }
  }

  private ensureGlobalState(): void {
    AppStorage.setOrCreate('activeTab', 0)
    AppStorage.setOrCreate('workerActionMode', 'checkIn')
    AppStorage.setOrCreate('selectedServiceType', '')
    AppStorage.setOrCreate('currentOrderId', '')
    AppStorage.setOrCreate('currentOrderNo', '')
    AppStorage.setOrCreate('currentOrderTitle', '')
    AppStorage.setOrCreate('currentOrderAddress', '')
    AppStorage.setOrCreate('currentOrderContactName', '')
    AppStorage.setOrCreate('currentOrderContactPhone', '')
  }

  private loadUserInfo(): void {
    getUserInfo()
      .then((info) => {
        this.userName = info.real_name || info.username
        this.currentRole = info.role === 'worker' ? 'worker' : 'resident'
      })
      .catch(() => {
        this.userName = ''
      })
  }

  private loadMessages(): void {
    if (!this.isLoggedIn) {
      return
    }
    this.messageLoading = true
    fetchMessages()
      .then((list: MessageItem[]) => {
        this.messages = list
        this.messageLoading = false
        this.loadUnreadCount()
      })
      .catch(() => {
        this.messageLoading = false
      })
  }

  private loadUnreadCount(): void {
    if (!this.isLoggedIn) {
      this.unreadCount = 0
      return
    }
    fetchUnreadCount()
      .then((count: number) => {
        this.unreadCount = count
      })
      .catch(() => {
        this.unreadCount = 0
      })
  }

  private readOneMessage(msg: MessageItem): void {
    if (msg.is_read) {
      return
    }
    markMessageRead(msg.id)
      .then(() => {
        const next: MessageItem[] = []
        let i = 0
        while (i < this.messages.length) {
          const current = this.messages[i]
          if (current.id === msg.id) {
            next.push({
              id: current.id,
              message_type: current.message_type,
              title: current.title,
              content: current.content,
              is_read: true,
              priority: current.priority,
              created_at: current.created_at
            })
          } else {
            next.push(current)
          }
          i++
        }
        this.messages = next
        this.loadUnreadCount()
      })
      .catch(() => {
        this.safeToast('消息已读更新失败，请稍后重试')
      })
  }

  private readAllMessages(): void {
    markAllRead()
      .then(() => {
        const next: MessageItem[] = []
        let i = 0
        while (i < this.messages.length) {
          const current = this.messages[i]
          next.push({
            id: current.id,
            message_type: current.message_type,
            title: current.title,
            content: current.content,
            is_read: true,
            priority: current.priority,
            created_at: current.created_at
          })
          i++
        }
        this.messages = next
        this.unreadCount = 0
        this.safeToast('已全部标记为已读')
      })
      .catch(() => {
        this.safeToast('操作失败，请稍后重试')
      })
  }

  private handleSettingAction(label: string): void {
    if (label === '个人资料') {
      const displayName = this.userName.length > 0 ? this.userName : '未获取'
      this.safeToast(`当前用户：${displayName}`)
      return
    }
    if (label === '服务地址管理') {
      this.currentIndex = 1
      if (this.currentRole === 'resident') {
        AppStorage.setOrCreate('selectedServiceType', '代办')
      }
      return
    }
    if (label === '消息通知设置') {
      this.currentIndex = 2
      this.loadMessages()
      return
    }
    if (label === '帮助与反馈') {
      this.safeToast('可通过碰一碰或抓一抓分享应用给家人/邻居')
      return
    }
    if (label === '关于邻里') {
      this.safeToast('邻里社区便民服务 · HarmonyOS 版')
    }
  }

  private getSecondTabTitle(): string {
    if (this.currentRole === 'resident') {
      return '申请'
    }
    return this.workerActionMode === 'result' ? '结果' : '签到'
  }

  private getAbilityContext(): common.UIAbilityContext | undefined {
    try {
      const hostContext = this.getUIContext().getHostContext()
      if (hostContext) {
        return hostContext as common.UIAbilityContext
      }
    } catch {
    }
    try {
      return getContext(this) as common.UIAbilityContext
    } catch {
      return undefined
    }
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message: message })
    } catch {
    }
  }
}
