/**
 * 类型定义 - 与后端 API Schema 对应
 */

// 通用响应类型
export interface ApiResponse<T = unknown> {
  code: number
  message: string
  data: T
  requestId: string
}

export interface PaginatedResponse<T = unknown> {
  list: T[]
  pageNo: number
  pageSize: number
  total: number
}

// 用户相关
export interface UserAccount {
  id: string
  username: string
  phone: string
  email: string | null
  role: 'resident' | 'worker' | 'station_manager' | 'dispatcher' | 'operator' | 'admin'
  real_name: string | null
  avatar_url: string | null
  is_active: boolean
  is_verified: boolean
  station_id: string | null
  created_at: string
}

export interface LoginRequest {
  phone: string
  password: string
}

export interface TokenResponse {
  access_token: string
  token_type: string
  expires_in: number
}

// 站点相关
export interface ServiceStation {
  id: string
  name: string
  code: string
  address: string
  contact_phone: string | null
  service_radius: number
  status: 'active' | 'inactive'
  description: string | null
  created_at: string
}

// 工单相关
export type OrderStatus =
  | 'created'
  | 'pending_dispatch'
  | 'pending_accept'
  | 'pending_arrive'
  | 'in_service'
  | 'pending_confirm'
  | 'completed'
  | 'after_sale'
  | 'closed'

export interface OrderAttachment {
  id: string
  file_key: string
  file_path: string
  file_name: string
  mime_type: string | null
  attachment_type: string
  created_at: string
}

export interface ServiceOrder {
  id: string
  order_no: string
  station_id: string
  service_type: string
  title: string
  description: string | null
  contact_name: string | null
  contact_phone: string | null
  service_address: string | null
  appointment_time: string | null
  status: OrderStatus
  urgency_level: string
  ai_category: string | null
  ai_risk_tags: string | null
  ai_summary: string | null
  assigned_worker_id: string | null
  service_result: string | null
  abnormal_flag: boolean
  created_at: string
  updated_at: string
  completed_at: string | null
  attachments: OrderAttachment[]
}

// 调度相关
export interface DispatchCandidate {
  worker_id: string
  worker_name: string | null
  distance_score: number
  type_match_score: number
  load_score: number
  urgency_score: number
  total_score: number
}

export interface DispatchTask {
  id: string
  order_id: string
  station_id: string
  candidate_worker_id: string
  score: number
  status: 'pending' | 'assigned' | 'accepted' | 'rejected' | 'reassigned'
  dispatch_reason: string | null
  created_at: string
  responded_at: string | null
}

// AI 相关
export interface AiReviewResult {
  task_id: string
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled'
  category_suggestion: string | null
  urgency_suggestion: string | null
  risk_tags: string[]
  summary: string | null
  confidence: number | null
}

export interface AiTaskRequest {
  order_id: string
  task_type: 'review' | 'summary' | 'classify' | 'analysis'
  force?: boolean
}

// 消息相关
export interface Message {
  id: string
  user_id: string
  message_type: 'system' | 'business' | 'alert'
  title: string
  content: string | null
  related_order_id: string | null
  is_read: boolean
  priority: string
  created_at: string
  read_at: string | null
}

// 统计相关
export interface StationStats {
  station_id: string
  station_name: string
  total_orders: number
  completed_orders: number
  completion_rate: number
  by_status: Record<string, number>
  by_type: Record<string, number>
}
