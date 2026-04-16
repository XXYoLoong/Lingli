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
