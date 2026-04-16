# Copyright 2026 Jiacheng Ni
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""短信发送服务（阿里云）"""

import json

from fastapi import HTTPException, status
from aliyunsdkcore.client import AcsClient
from aliyunsdkdysmsapi.request.v20170525.SendSmsRequest import SendSmsRequest

from app.config import settings


class SmsService:
    @staticmethod
    def send_reset_code(phone: str, code: str) -> None:
        if settings.SMS_PROVIDER != "aliyun":
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="短信服务未启用")

        if not (
            settings.SMS_ALIYUN_ACCESS_KEY_ID
            and settings.SMS_ALIYUN_ACCESS_KEY_SECRET
            and settings.SMS_ALIYUN_SIGN_NAME
            and settings.SMS_ALIYUN_TEMPLATE_CODE
        ):
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="短信服务配置不完整")

        client = AcsClient(
            settings.SMS_ALIYUN_ACCESS_KEY_ID,
            settings.SMS_ALIYUN_ACCESS_KEY_SECRET,
            "cn-hangzhou",
        )
        request = SendSmsRequest()
        request.set_accept_format("json")
        request.set_PhoneNumbers(phone)
        request.set_SignName(settings.SMS_ALIYUN_SIGN_NAME)
        request.set_TemplateCode(settings.SMS_ALIYUN_TEMPLATE_CODE)
        request.set_TemplateParam(json.dumps({"code": code}))

        response = client.do_action_with_exception(request)
        resp_json = json.loads(response.decode("utf-8"))
        if resp_json.get("Code") != "OK":
            message = resp_json.get("Message", "短信发送失败")
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"短信发送失败: {message}")
