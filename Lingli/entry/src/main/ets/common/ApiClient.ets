/**
 * 统一网络请求客户端
 * 所有 API 请求通过此模块发起，自动注入访问令牌
 */

import { http } from '@kit.NetworkKit';
import { Preferences } from '@kit.ArkData';

const BASE_URL = 'http://192.168.1.100:8000/api/v1';

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
  requestId: string;
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
  }

  getToken(): string {
    return this.token;
  }

  async get<T>(path: string, params?: Record<string, string>): Promise<ApiResponse<T>> {
    const url = params ? `${BASE_URL}${path}?${this.buildQuery(params)}` : `${BASE_URL}${path}`;
    return this.request<T>('GET', url);
  }

  async post<T>(path: string, data?: Record<string, ESObject>): Promise<ApiResponse<T>> {
    const url = `${BASE_URL}${path}`;
    return this.request<T>('POST', url, data ? JSON.stringify(data) : '');
  }

  async patch<T>(path: string, data?: Record<string, ESObject>): Promise<ApiResponse<T>> {
    const url = `${BASE_URL}${path}`;
    return this.request<T>('PATCH', url, data ? JSON.stringify(data) : '');
  }

  async delete<T>(path: string): Promise<ApiResponse<T>> {
    const url = `${BASE_URL}${path}`;
    return this.request<T>('DELETE', url);
  }

  private async request<T>(method: string, url: string, data?: string): Promise<ApiResponse<T>> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: method as http.RequestMethod,
        header: {
          'Content-Type': 'application/json',
          'Authorization': this.token ? `Bearer ${this.token}` : '',
        },
        extraData: data,
        connectTimeout: 10000,
        readTimeout: 30000,
      });
      if (response.responseCode === 200) {
        return response.result as ApiResponse<T>;
      }
      throw new Error(`HTTP ${response.responseCode}`);
    } finally {
      httpRequest.destroy();
    }
  }

  private buildQuery(params: Record<string, string>): string {
    return Object.entries(params)
      .filter(([_, v]) => v !== undefined && v !== '')
      .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
      .join('&');
  }
}
