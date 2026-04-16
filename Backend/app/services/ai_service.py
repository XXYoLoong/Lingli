"""AI 代理服务 - Qwen API 封装"""

import json
import httpx
import logging
from typing import Optional

from app.config import settings
from app.models.order import ServiceOrder

logger = logging.getLogger(__name__)


class AIService:
    """Qwen API 封装服务"""

    def __init__(self):
        self.api_key = settings.DASHSCOPE_API_KEY
        self.base_url = settings.QWEN_BASE_URL
        self.timeout = settings.QWEN_TIMEOUT

    def build_review_prompt(self, order: ServiceOrder) -> str:
        """构建工单审核提示词"""
        prompt = f"""你是一个社区服务工单审核助手。请分析以下工单信息并返回结构化JSON结果。

工单信息：
- 标题：{order.title}
- 服务类型：{order.service_type}
- 描述：{order.description or "无"}
- 语音转写：{order.voice_transcript or "无"}
- 预约时间：{order.appointment_time}
- 地址：{order.service_address or "无"}

请返回以下JSON格式的结果（只返回JSON，不要其他内容）：
{{
  "category": "建议的服务分类（从以下选择：维修、保洁、助餐、陪诊、代办、照护、其他）",
  "urgency": "紧急程度建议（从以下选择：low、normal、high、urgent）",
  "risk_tags": ["可能的风险标签列表，如：老人独居、行动不便、高空作业、紧急需求等，如无则空数组"],
  "summary": "工单处理摘要（50字以内）",
  "confidence": 置信度（0-1之间的小数）
}}

注意：只返回JSON对象，不要markdown代码块或其他说明文字。"""
        return prompt

    def build_summary_prompt(self, order: ServiceOrder) -> str:
        """构建工单摘要提示词"""
        prompt = f"""请为以下社区服务工单生成一个简短摘要（30字以内）。

工单信息：
- 标题：{order.title}
- 描述：{order.description or "无"}
- 服务结果：{order.service_result or "未完成"}

只返回摘要文字。"""
        return prompt

    def call_qwen_api(self, prompt: str, task_type: str, extra_messages: list | None = None) -> dict:
        """调用 Qwen API"""
        if not self.api_key:
            raise RuntimeError("DASHSCOPE_API_KEY 未配置")

        model = settings.QWEN_MODEL_DEFAULT
        if task_type == "review":
            model = settings.QWEN_MODEL_REVIEW
        elif task_type == "summary":
            model = settings.QWEN_MODEL_SUMMARY
        elif task_type == "classify":
            model = settings.QWEN_MODEL_REVIEW

        messages = [
            {"role": "system", "content": "你是一个专业的社区服务系统AI助手，请提供准确、实用的分析和建议。"},
            {"role": "user", "content": prompt},
        ]
        if extra_messages:
            messages.extend(extra_messages)

        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": model,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 2048,
        }

        for attempt in range(settings.QWEN_MAX_RETRIES):
            try:
                with httpx.Client(timeout=self.timeout) as client:
                    response = client.post(url, json=payload, headers=headers)
                    response.raise_for_status()
                    data = response.json()

                    content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                    tokens_used = data.get("usage", {}).get("total_tokens")

                    # 尝试解析JSON响应
                    result = self._parse_response(content, task_type)
                    result["tokens_used"] = tokens_used
                    return result

            except (httpx.TimeoutException, httpx.ConnectionError) as e:
                logger.warning(f"Qwen API 调用失败 (第{attempt+1}次): {e}")
                if attempt == settings.QWEN_MAX_RETRIES - 1:
                    raise
            except Exception as e:
                logger.error(f"Qwen API 调用异常: {e}")
                raise

        raise RuntimeError("Qwen API 调用失败：超过最大重试次数")

    def _parse_response(self, content: str, task_type: str) -> dict:
        """解析模型返回结果"""
        # 清理可能的markdown代码块标记
        content = content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()

        try:
            result = json.loads(content)
            return result
        except json.JSONDecodeError:
            logger.warning(f"JSON解析失败，返回默认结构: {content[:200]}")
            if task_type == "review":
                return {
                    "category": "",
                    "urgency": "normal",
                    "risk_tags": [],
                    "summary": content[:200],
                    "confidence": 0.5,
                }
            return {"content": content, "confidence": 0.5}
