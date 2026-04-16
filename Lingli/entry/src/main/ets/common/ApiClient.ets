/**
 * 统一网络请求客户端 - ArkTS 兼容版本
 * 所有 API 请求通过此模块发起，自动注入访问令牌
 */

import { http } from '@kit.NetworkKit';

// 后端地址 - 云端环境（使用 HTTPS，避免重定向导致的 URL 异常）
const BASE_URL = 'https://harmonycare.cn/api/v1';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  requestId: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
}

export interface LoginRequest {
  phone: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  phone: string;
  password: string;
  role: string;
  real_name: string;
}

export interface UserInfo {
  id: string;
  username: string;
  phone: string;
  role: string;
  real_name: string | null;
  avatar_url: string | null;
  station_id: string | null;
  is_active: boolean;
}

export interface OrderItem {
  id: string;
  order_no: string;
  station_id: string;
  service_type: string;
  title: string;
  description: string | null;
  contact_name: string | null;
  contact_phone: string | null;
  service_address: string | null;
  appointment_time: string | null;
  status: string;
  urgency_level: string;
  ai_category: string | null;
  ai_risk_tags: string | null;
  ai_summary: string | null;
  assigned_worker_id: string | null;
  service_result: string | null;
  abnormal_flag: boolean;
  created_at: string;
  updated_at: string;
  completed_at: string | null;
}

export interface MessageItem {
  id: string;
  message_type: string;
  title: string;
  content: string | null;
  is_read: boolean;
  priority: string;
  created_at: string;
}

export interface KVPair {
  key: string;
  value: string;
}

export interface TrendItem {
  date: string;
  total: number;
  completed: number;
  in_progress: number;
}

export class ApiClient {
  private static instance: ApiClient;
  private token: string = '';

  static getInstance(): ApiClient {
    if (!ApiClient.instance) {
      ApiClient.instance = new ApiClient();
    }
    return ApiClient.instance;
  }

  setToken(token: string): void {
    this.token = token;
    try {
      AppStorage.setOrCreate<string>('token', token);
    } catch (e) {
      // ignore
    }
  }

  getToken(): string {
    return this.token;
  }

  clearToken(): void {
    this.token = '';
    try {
      AppStorage.setOrCreate<string>('token', '');
    } catch (e) {
      // ignore
    }
  }

  async get<T>(path: string, params?: KVPair[]): Promise<ApiResponse<T>> {
    let url = `${BASE_URL}${path}`;
    if (params && params.length > 0) {
      let query = '?';
      for (let i = 0; i < params.length; i++) {
        const p = params[i];
        if (p.value.length > 0) {
          if (query.length > 1) query += '&';
          query += `${p.key}=${encodeURIComponent(p.value)}`;
        }
      }
      url += query;
    }
    return this.doRequest<T>('GET', url);
  }

  async post<T>(path: string, data?: string): Promise<ApiResponse<T>> {
    const url = `${BASE_URL}${path}`;
    const body = data ? data : '';
    return this.doRequest<T>('POST', url, body);
  }

  async patch<T>(path: string, data?: string): Promise<ApiResponse<T>> {
    const url = `${BASE_URL}${path}`;
    const body = data ? data : '';
    return this.doRequest<T>('PATCH', url, body);
  }

  async delete<T>(path: string): Promise<ApiResponse<T>> {
    const url = `${BASE_URL}${path}`;
    return this.doRequest<T>('DELETE', url);
  }

  private async doRequest<T>(method: string, url: string, data?: string): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const requestUrl = url.trim();
      if (requestUrl.length === 0) {
        throw new Error('接口地址为空');
      }
      const header: Record<string, string> = {
        'Content-Type': 'application/json'
      };
      if (this.token.length > 0) {
        header['Authorization'] = `Bearer ${this.token}`;
      }

      const response = await httpRequest.request(requestUrl, {
        method: method as http.RequestMethod,
        header: header,
        extraData: data,
        connectTimeout: 10000,
        readTimeout: 30000,
      });

      if (response.responseCode === 200 || response.responseCode === 201) {
        return this.normalizeResponse<T>(response.result as string | Object);
      }
      if (response.responseCode === 401) {
        this.clearToken();
      }
      const serverMsg = this.extractServerMessage(response.result as string | Object);
      if (serverMsg.length > 0) {
        throw new Error(serverMsg);
      }
      throw new Error(`HTTP ${response.responseCode}`);
    } catch (err) {
      const e = err as Error;
      if (e && e.message && e.message.length > 0) {
        if (e.message.indexOf('Invalid URL') >= 0 || e.message.indexOf('missing URL') >= 0) {
          throw new Error('接口地址异常，请更新应用后重试');
        }
        throw e;
      }
      throw new Error('服务器无响应，请检查网络连接');
    } finally {
      httpRequest.destroy();
    }
  }

  private normalizeResponse<T>(rawResult: string | Object): ApiResponse<T> {
    let payload: Object = rawResult as Object;
    if (typeof rawResult === 'string') {
      if (rawResult.length === 0) {
        return { code: 200, message: 'ok', data: '' as T, requestId: '' };
      }
      payload = JSON.parse(rawResult) as Object;
    }

    const wrapped = payload as ApiResponse<T>;
    if (wrapped && wrapped.data !== undefined) {
      return wrapped;
    }
    return {
      code: 200,
      message: 'ok',
      data: payload as T,
      requestId: ''
    };
  }

  private extractServerMessage(rawResult: string | Object): string {
    let payload: Object = rawResult as Object;
    if (typeof rawResult === 'string') {
      if (rawResult.length === 0) {
        return '';
      }
      payload = JSON.parse(rawResult) as Object;
    }
    const msgObj = payload as Record<string, string>;
    if (msgObj['detail']) {
      return msgObj['detail'];
    }
    if (msgObj['message']) {
      return msgObj['message'];
    }
    return '';
  }
}

// ===== 业务 API 封装 =====

export async function loginApi(data: LoginRequest): Promise<LoginResponse> {
  const client = ApiClient.getInstance();
  const body = `{"phone":"${data.phone}","password":"${data.password}"}`;
  const resp = await client.post<LoginResponse>('/auth/login', body);
  const result = resp.data;
  if (result && result.access_token.length > 0) {
    client.setToken(result.access_token);
    return result;
  }
  throw new Error(resp.message || '登录失败');
}

export async function registerApi(data: RegisterRequest): Promise<UserInfo> {
  const client = ApiClient.getInstance();
  const safeName = data.real_name.replace(/"/g, '');
  const body =
    `{"username":"${data.username}","phone":"${data.phone}","password":"${data.password}",` +
    `"role":"${data.role}","real_name":"${safeName}"}`;
  const resp = await client.post<UserInfo>('/auth/register', body);
  return resp.data;
}

export async function getUserInfo(): Promise<UserInfo> {
  const client = ApiClient.getInstance();
  const resp = await client.get<UserInfo>('/auth/me');
  return resp.data;
}

export async function fetchOrders(params?: KVPair[]): Promise<OrderItem[]> {
  const client = ApiClient.getInstance();
  const resp = await client.get<OrderItem[]>('/orders', params);
  if (resp.data) {
    return resp.data;
  }
  return [];
}

export async function createOrder(body: string): Promise<OrderItem> {
  const client = ApiClient.getInstance();
  const resp = await client.post<OrderItem>('/orders', body);
  return resp.data;
}

export async function completeOrder(orderId: string, body: string): Promise<OrderItem> {
  const client = ApiClient.getInstance();
  const resp = await client.post<OrderItem>(`/orders/${orderId}/complete`, body);
  return resp.data;
}

export async function checkInOrder(orderId: string, body: string): Promise<OrderItem> {
  const client = ApiClient.getInstance();
  const resp = await client.post<OrderItem>(`/orders/${orderId}/check-in`, body);
  return resp.data;
}

export async function fetchMessages(params?: KVPair[]): Promise<MessageItem[]> {
  const client = ApiClient.getInstance();
  const resp = await client.get<MessageItem[]>('/messages', params);
  if (resp.data) {
    return resp.data;
  }
  return [];
}

export interface CountResponse {
  count: number;
}

export async function fetchUnreadCount(): Promise<number> {
  const client = ApiClient.getInstance();
  const resp = await client.get<CountResponse>('/messages/unread-count');
  if (resp.data) {
    return resp.data.count;
  }
  return 0;
}

export async function markMessageRead(msgId: string): Promise<void> {
  const client = ApiClient.getInstance();
  await client.post<void>(`/messages/${msgId}/read`);
}

export async function markAllRead(): Promise<void> {
  const client = ApiClient.getInstance();
  await client.post<void>('/messages/read-all');
}

export async function fetchStationTrend(): Promise<TrendItem[]> {
  const client = ApiClient.getInstance();
  const resp = await client.get<TrendItem[]>('/stats/orders/trend');
  if (resp.data) {
    return resp.data;
  }
  return [];
}
