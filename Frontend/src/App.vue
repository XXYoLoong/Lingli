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
}

html, body {
  margin: 0;
  padding: 0;
  height: 100%;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

#app {
  height: 100%;
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
