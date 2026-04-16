/**
 * API 服务层 - 统一封装所有后端接口调用
 */
import type {
  LoginRequest,
  RegisterRequest,
  SendResetCodeRequest,
  ResetPasswordRequest,
  ChangePasswordRequest,
  TokenResponse,
  UserAccount,
  ServiceOrder,
  ServiceStation,
  DispatchCandidate,
  DispatchTask,
  Message,
  StationStats,
  AiReviewResult,
  AiTaskRequest,
  AiTaskItem,
} from '@/types'
import { get, post, patch, del } from './http'

// 认证相关
export const authApi = {
  login: (data: LoginRequest) => post<TokenResponse>('/auth/login', data),
  register: (data: RegisterRequest) => post<UserAccount>('/auth/register', data),
  sendResetCode: (data: SendResetCodeRequest) => post<{ message: string }>('/auth/password/send-code', data),
  resetPassword: (data: ResetPasswordRequest) => post<{ message: string }>('/auth/password/reset', data),
  changePassword: (data: ChangePasswordRequest) => post<{ message: string }>('/auth/password/change', data),
  getMe: () => get<UserAccount>('/auth/me'),
}

// 工单相关
export const orderApi = {
  list: (params?: Record<string, string>) =>
    get<ServiceOrder[]>('/orders', { params }),
  get: (id: string) => get<ServiceOrder>(`/orders/${id}`),
  create: (data: Record<string, unknown>) => post<ServiceOrder>('/orders', data),
  update: (id: string, data: Record<string, unknown>) =>
    patch<ServiceOrder>(`/orders/${id}`, data),
  checkIn: (id: string, data: Record<string, unknown>) =>
    post<ServiceOrder>(`/orders/${id}/check-in`, data),
  complete: (id: string, data: Record<string, unknown>) =>
    post<ServiceOrder>(`/orders/${id}/complete`, data),
  cancel: (id: string) => del(`/orders/${id}`),
}

// 调度相关
export const dispatchApi = {
  calculate: (orderId: string) =>
    post<DispatchCandidate[]>(`/dispatch/calculate/${orderId}`),
  assign: (data: { order_id: string; worker_id: string; dispatch_reason?: string }) =>
    post<DispatchTask>('/dispatch', data),
  autoDispatch: (orderId: string) =>
    post<DispatchTask[]>(`/dispatch/auto/${orderId}`),
  accept: (taskId: string) => post(`/dispatch/accept/${taskId}`),
  reject: (taskId: string, data: { reason?: string }) =>
    post(`/dispatch/reject/${taskId}`, data),
  myTasks: () => get<DispatchTask[]>('/dispatch/my-tasks'),
}

// 消息相关
export const messageApi = {
  list: (params?: Record<string, string>) =>
    get<Message[]>('/messages', { params }),
  unreadCount: () => get<{ count: number }>('/messages/unread-count'),
  markRead: (id: string) => post(`/messages/${id}/read`),
  markAllRead: () => post('/messages/read-all'),
}

// 统计相关
export const statsApi = {
  station: (stationId: string, params?: Record<string, string>) =>
    get<StationStats>(`/stats/station/${stationId}`, { params }),
  trend: (params?: Record<string, string>) =>
    get<Record<string, unknown>>('/stats/orders/trend', { params }),
}

// 站点相关
export const stationApi = {
  list: (params?: Record<string, string>) =>
    get<ServiceStation[]>('/stations', { params }),
  get: (id: string) => get<ServiceStation>(`/stations/${id}`),
  create: (data: Record<string, unknown>) => post<ServiceStation>('/stations', data),
  update: (id: string, data: Record<string, unknown>) =>
    patch<ServiceStation>(`/stations/${id}`, data),
}

// AI 相关
export const aiApi = {
  review: (data: AiTaskRequest) => post<Record<string, string>>('/ai/review', data),
  getResult: (taskId: string) => get<AiReviewResult>(`/ai/review/${taskId}`),
  listTasks: (params?: Record<string, string>) => get<AiTaskItem[]>('/ai/tasks', { params }),
}

// 用户管理（仅超级管理员）
export const userApi = {
  list: (params?: Record<string, string>) => get<UserAccount[]>('/users', { params }),
  create: (data: RegisterRequest & { role: UserAccount['role'] }) => post<UserAccount>('/users', data),
  update: (id: string, data: { real_name?: string; role: UserAccount['role']; email?: string }) =>
    patch<UserAccount>(`/users/${id}`, data),
  updateStatus: (id: string, is_active: boolean) =>
    patch<UserAccount>(`/users/${id}/status`, { is_active }),
  resetPassword: (id: string, new_password: string) =>
    patch<{ message: string }>(`/users/${id}/password`, { new_password }),
  updateMyEmail: (email: string) =>
    patch<UserAccount>('/users/me/email', { email }),
  sendMyEmailCode: (email: string) =>
    post<{ message: string }>('/users/me/email/send-code', { email }),
  verifyMyEmail: (email: string, code: string) =>
    post<UserAccount>('/users/me/email/verify', { email, code }),
  updateEmail: (id: string, email: string) =>
    patch<UserAccount>(`/users/${id}/email`, { email }),
}
