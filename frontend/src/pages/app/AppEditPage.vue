<template>
  <div class="app-edit-page">
    <a-card title="Edit App">
      <a-form :model="formData" @finish="handleUpdate" layout="vertical">
        <a-form-item
          label="App Name"
          name="appName"
          :rules="[{ required: true, message: 'Please enter app name' }]"
        >
          <a-input v-model:value="formData.appName" placeholder="Please enter app name" />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" html-type="submit" :loading="loading">Save</a-button>
          <a-button style="margin-left: 12px" @click="$router.back()">Cancel</a-button>
        </a-form-item>
      </a-form>

      <a-divider />

      <a-descriptions title="App Information" bordered>
        <a-descriptions-item label="App ID">{{ appInfo?.id }}</a-descriptions-item>
        <a-descriptions-item label="Code Type">{{ formatCodeGenType(appInfo?.codeGenType) }}</a-descriptions-item>
        <a-descriptions-item label="Create Time">{{ formatTime(appInfo?.createTime) }}</a-descriptions-item>
        <a-descriptions-item label="Update Time">{{ formatTime(appInfo?.updateTime) }}</a-descriptions-item>
        <a-descriptions-item label="Initial Description" :span="3">{{ appInfo?.initPrompt }}</a-descriptions-item>
      </a-descriptions>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { getAppVoById, updateApp } from '@/api/appController'

const route = useRoute()
const router = useRouter()

const appId = route.params.id as string
const appInfo = ref<API.AppVO | null>(null)
const loading = ref(false)

const formData = ref({
  appName: '',
})

const formatCodeGenType = (type?: string) => {
  if (!type) return '-'
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

const formatTime = (time?: string) => {
  if (!time) return '-'
  return new Date(time).toLocaleString('en-US')
}

const loadAppInfo = async () => {
  try {
    const res = await getAppVoById({ id: appId })
    if (res.data.code === 0 && res.data.data) {
      appInfo.value = res.data.data
      formData.value.appName = res.data.data.appName || ''
    }
  } catch (error) {
    console.error('加载应用信息失败：', error)
    message.error('Failed to load app information')
  }
}

const handleUpdate = async () => {
  loading.value = true
  try {
    const res = await updateApp({
      id: appId,
      appName: formData.value.appName,
    })

    if (res.data.code === 0) {
      message.success('Update successful')
      await loadAppInfo()
    } else {
      message.error('Update failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('更新失败：', error)
    message.error('Update failed, please try again')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadAppInfo()
})
</script>

<style scoped>
.app-edit-page {
  max-width: 1000px;
  margin: 0 auto;
}
</style>

