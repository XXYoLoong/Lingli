<!--
  Copyright 2026 Jiacheng Ni
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
      http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->

<template>
  <router-view />
</template>

<script setup lang="ts">
</script>

<style>
:root {
  --neighbor-primary: #1677ff;
  --neighbor-success: #52c41a;
  --neighbor-warning: #faad14;
  --neighbor-danger: #ff4d4f;
  --neighbor-info: #1677ff;
  --neighbor-bg: #f4f6fb;
  --neighbor-card-shadow: 0 8px 24px rgba(22, 119, 255, 0.08);
}

html, body {
  margin: 0;
  padding: 0;
  height: 100%;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

#app {
  height: 100%;
  background: var(--neighbor-bg);
}

.el-card {
  border: none !important;
  border-radius: 12px !important;
  box-shadow: var(--neighbor-card-shadow) !important;
}

.el-button--primary {
  border-radius: 8px !important;
}

/* 全局滚动条 */
::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}
::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}
::-webkit-scrollbar-track {
  background: transparent;
}
</style>
