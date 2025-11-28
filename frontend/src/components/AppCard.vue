<template>
  <a-card :hoverable="true" class="app-card" @click="handleClick">
    <template #cover>
      <div class="app-cover" v-if="app.cover">
        <img :src="app.cover" :alt="app.appName" />
      </div>
      <div class="app-cover-placeholder" v-else>
        <span>{{ app.appName || 'Unnamed App' }}</span>
      </div>
    </template>
    <a-card-meta>
      <template #title>
        <div class="app-title">
          {{ app.appName || 'Unnamed App' }}
          <a-tag v-if="app.codeGenType" color="blue" class="code-gen-tag">
            {{ formatCodeGenType(app.codeGenType) }}
          </a-tag>
        </div>
      </template>
      <template #description>
        <div class="app-desc">{{ app.initPrompt || 'No description' }}</div>
        <div class="app-meta">
          <span>Created: {{ formatTime(app.createTime) }}</span>
        </div>
      </template>
    </a-card-meta>
  </a-card>
</template>

<script setup lang="ts">
interface Props {
  app: API.AppVO
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'click'): void
}>()

const handleClick = () => {
  emit('click')
}

const formatCodeGenType = (type: string) => {
  const map: Record<string, string> = {
    HTML: 'HTML',
    html: 'HTML',
    MULTI_FILE: 'Multi-file',
    multi_file: 'Multi-file',
    VUE_PROJECT: 'Vue Project',
    vue_project: 'Vue Project',
    html_sample_commerce: 'E-commerce Template',
    html_sample_enterprise: 'Enterprise Website',
    html_sample_portfolio: 'Portfolio',
  }
  return map[type] || type
}

const formatTime = (time: string) => {
  if (!time) return '-'
  const date = new Date(time)
  return date.toLocaleDateString('en-US')
}
</script>

<style scoped>
.app-card {
  cursor: pointer;
  transition: all 0.3s;
}

.app-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.app-cover {
  height: 200px;
  overflow: hidden;
}

.app-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.app-cover-placeholder {
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  font-size: 18px;
  font-weight: bold;
}

.app-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.code-gen-tag {
  margin: 0;
}

.app-desc {
  color: #666;
  margin-bottom: 8px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.app-meta {
  font-size: 12px;
  color: #999;
}
</style>

