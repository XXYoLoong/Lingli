/**
 * 数据模型定义
 */

// 用户角色
export enum UserRole {
  RESIDENT = 'resident',
  WORKER = 'worker',
  STATION_MANAGER = 'station_manager',
  DISPATCHER = 'dispatcher',
  OPERATOR = 'operator',
  ADMIN = 'admin'
}

// 工单状态
export enum OrderStatus {
  CREATED = 'created',
  PENDING_DISPATCH = 'pending_dispatch',
  PENDING_ACCEPT = 'pending_accept',
  PENDING_ARRIVE = 'pending_arrive',
  IN_SERVICE = 'in_service',
  PENDING_CONFIRM = 'pending_confirm',
  COMPLETED = 'completed',
  AFTER_SALE = 'after_sale',
  CLOSED = 'closed'
}

// 紧急程度
export enum UrgencyLevel {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
  URGENT = 'urgent'
}

// 服务类型
export enum ServiceType {
  REPAIR = '维修',
  CLEANING = '保洁',
  MEAL = '助餐',
  ACCOMPANY = '陪诊',
  ERRAND = '代办',
  CARE = '照护'
}

// 用户账户
export interface UserAccount {
  id: string;
  username: string;
  phone: string;
  role: UserRole;
  real_name: string | null;
  avatar_url: string | null;
  station_id: string | null;
  is_active: boolean;
}

// 工单
export interface ServiceOrder {
  id: string;
  order_no: string;
  service_type: string;
  title: string;
  description: string | null;
  contact_name: string | null;
  contact_phone: string | null;
  service_address: string | null;
  appointment_time: string | null;
  status: OrderStatus;
  urgency_level: string;
  ai_summary: string | null;
  service_result: string | null;
  abnormal_flag: boolean;
  created_at: string;
}

// 消息
export interface Message {
  id: string;
  message_type: 'system' | 'business' | 'alert';
  title: string;
  content: string | null;
  is_read: boolean;
  priority: string;
  created_at: string;
}

// 登录响应
export interface LoginResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
}
