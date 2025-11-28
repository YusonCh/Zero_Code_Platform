<template>
  <div class="home-page">
    <div class="hero-section">
      <h1 class="hero-title">Zero-Code Application Generation Platform</h1>
      <p class="hero-desc">Generate complete frontend applications quickly through AI conversation</p>
      <div class="create-section">
        <a-textarea
          v-model:value="userPrompt"
          placeholder="Describe the website you want to generate, e.g., create a personal blog website"
          :rows="4"
          :maxlength="500"
          class="prompt-input"
          autocomplete="off"
          data-lpignore="true"
          data-form-type="other"
          data-ms-editor="false"
        />
        
        <div class="type-selector">
          <a-radio-group v-model:value="codeGenType" button-style="solid">
            <a-radio-button value="html">Single Page HTML</a-radio-button>
            <a-radio-button value="multi_file">Multi-file Web Page</a-radio-button>
            <a-radio-button value="vue_project">Vue Project</a-radio-button>
          </a-radio-group>
        </div>
        
        <a-button type="primary" size="large" @click="createApp" :loading="creating" class="create-btn">
          Create App
        </a-button>
      </div>
    </div>

    <a-tabs v-model:activeKey="activeTab" class="apps-tabs">
      <a-tab-pane key="my" tab="My Apps">
        <div class="apps-grid">
          <AppCard
            v-for="app in myApps"
            :key="app.id"
            :app="app"
            @click="goToApp(app.id)"
          />
        </div>
        <div class="pagination-container" v-if="myAppsPage.total > 0">
          <a-pagination
            v-model:current="myAppsPage.current"
            v-model:page-size="myAppsPage.pageSize"
            :total="myAppsPage.total"
            @change="loadMyApps"
          />
        </div>
      </a-tab-pane>
      <a-tab-pane key="featured" tab="Featured Apps">
        <div class="apps-grid">
          <AppCard
            v-for="app in featuredApps"
            :key="app.id"
            :app="app"
            @click="goToApp(app.id)"
          />
        </div>
        <div class="pagination-container" v-if="featuredAppsPage.total > 0">
          <a-pagination
            v-model:current="featuredAppsPage.current"
            v-model:page-size="featuredAppsPage.pageSize"
            :total="featuredAppsPage.total"
            @change="loadFeaturedApps"
          />
        </div>
      </a-tab-pane>
    </a-tabs>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { useLoginUserStore } from '@/stores/loginUser'
import { addApp, listMyAppVoByPage, listGoodAppVoByPage } from '@/api/appController'
import AppCard from '@/components/AppCard.vue'

const router = useRouter()
const loginUserStore = useLoginUserStore()

const userPrompt = ref('')
const creating = ref(false)
const codeGenType = ref('vue_project') // 默认选中 Vue 项目

const myApps = ref<API.AppVO[]>([])
const myAppsPage = reactive({
  current: 1,
  pageSize: 6,
  total: 0,
})

const featuredApps = ref<API.AppVO[]>([])
const featuredAppsPage = reactive({
  current: 1,
  pageSize: 6,
  total: 0,
})

const activeTab = ref('my')

const createApp = async () => {
  if (!userPrompt.value.trim()) {
    message.warning('Please enter app description')
    return
  }

  // 确保登录状态是最新的
  if (!loginUserStore.loginUser.id) {
    console.log('检测到未登录，尝试获取登录用户...')
    await loginUserStore.fetchLoginUser()
  }

  if (!loginUserStore.loginUser.id) {
    console.warn('用户未登录，跳转到登录页')
    message.warning('Please login first')
    await router.push('/user/login')
    return
  }

  console.log('开始创建应用，用户ID:', loginUserStore.loginUser.id, '提示词:', userPrompt.value.trim())
  creating.value = true
  try {
    const requestData = {
      initPrompt: userPrompt.value.trim(),
      codeGenType: codeGenType.value,
    }
    console.log('发送创建应用请求:', requestData)
    
    const res = await addApp(requestData)
    console.log('创建应用响应:', res)

    if (res.data.code === 0 && res.data.data) {
      message.success('App created successfully')
      const appId = String(res.data.data)
      console.log('应用创建成功，ID:', appId)
      userPrompt.value = '' // 清空输入框
      
      // 确保登录用户信息是最新的（创建应用后可能需要刷新）
      if (!loginUserStore.loginUser.id) {
        console.log('创建应用后，刷新登录用户信息')
        await loginUserStore.fetchLoginUser()
      }
      
      // 刷新应用列表
      await loadMyApps()
      
      // 等待一下确保状态更新
      await new Promise(resolve => setTimeout(resolve, 100))
      
      await router.push(`/app/chat/${appId}`)
    } else {
      const errorMsg = res.data?.message || '创建失败，请重试'
      console.error('创建应用失败，响应数据:', res.data)
      message.error('Creation failed: ' + errorMsg)
    }
  } catch (error: any) {
    console.error('创建应用异常:', error)
    console.error('错误详情:', {
      message: error?.message,
      response: error?.response,
      responseData: error?.response?.data,
      status: error?.response?.status,
      statusText: error?.response?.statusText,
    })
    
    let errorMsg = '创建失败，请重试'
    if (error?.response?.data?.message) {
      errorMsg = error.response.data.message
    } else if (error?.response?.data?.data?.message) {
      errorMsg = error.response.data.data.message
    } else if (error?.message) {
      errorMsg = error.message
    } else if (typeof error === 'string') {
      errorMsg = error
    }
    
    // 如果是401未登录错误，跳转到登录页
    if (error?.response?.status === 401 || error?.response?.data?.code === 40100) {
      message.warning('Login expired, please login again')
      await router.push('/user/login')
      return
    }
    
    message.error(errorMsg)
  } finally {
    creating.value = false
  }
}

const loadMyApps = async () => {
  if (!loginUserStore.loginUser.id) {
    myApps.value = []
    return
  }

  try {
    const res = await listMyAppVoByPage({
      pageNum: myAppsPage.current,
      pageSize: myAppsPage.pageSize,
    })

    if (res.data.code === 0 && res.data.data) {
      myApps.value = res.data.data.records || []
      myAppsPage.total = res.data.data.total || 0
    }
  } catch (error) {
    console.error('加载我的应用失败：', error)
  }
}

const loadFeaturedApps = async () => {
  try {
    const res = await listGoodAppVoByPage({
      pageNum: featuredAppsPage.current,
      pageSize: featuredAppsPage.pageSize,
    })

    if (res.data.code === 0 && res.data.data) {
      featuredApps.value = res.data.data.records || []
      featuredAppsPage.total = res.data.data.total || 0
    }
  } catch (error) {
    console.error('加载精选应用失败：', error)
  }
}

const goToApp = (appId: string | number) => {
  router.push(`/app/chat/${appId}`)
}

onMounted(() => {
  loadMyApps()
  loadFeaturedApps()
})
</script>

<style scoped>
.home-page {
  max-width: 1200px;
  margin: 0 auto;
}

.hero-section {
  text-align: center;
  padding: 40px 0;
}

.hero-title {
  font-size: 36px;
  color: #1890ff;
  margin-bottom: 16px;
}

.hero-desc {
  font-size: 18px;
  color: #666;
  margin-bottom: 32px;
}

.create-section {
  max-width: 600px;
  margin: 0 auto;
}

.prompt-input {
  margin-bottom: 16px;
}

.type-selector {
  margin-bottom: 16px;
  text-align: left;
}

.create-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
}

.apps-tabs {
  margin-top: 40px;
}

.apps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
  margin-top: 24px;
}

.pagination-container {
  margin-top: 24px;
  text-align: center;
}
</style>

