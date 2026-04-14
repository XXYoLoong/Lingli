/**
 * API 服务层 - 统一封装所有后端接口调用
 */
import type {
  LoginRequest,
  RegisterRequest,
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
  PaginatedResponse,
} from '@/types'
import { get, post, patch, del } from './http'

// 认证相关
export const authApi = {
  login: (data: LoginRequest) => post<TokenResponse>('/auth/login', data),
  register: (data: RegisterRequest) => post<UserAccount>('/auth/register', data),
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
}
