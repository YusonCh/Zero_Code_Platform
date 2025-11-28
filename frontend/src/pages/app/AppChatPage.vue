<template>
  <div class="app-chat-page">
    <div class="header-bar">
      <div class="header-left">
        <h1 class="app-name">{{ appInfo?.appName || 'Website Generator' }}</h1>
        <a-tag v-if="appInfo?.codeGenType" color="blue" class="code-gen-type-tag">
          {{ formatCodeGenType(appInfo.codeGenType) }}
        </a-tag>
      </div>
      <div class="header-right">
        <a-button type="default" @click="showAppDetail">App Details</a-button>
        <a-button
          type="primary"
          ghost
          @click="downloadCode"
          :loading="downloading"
          :disabled="!isOwner"
        >
          Download Code
        </a-button>
      </div>
    </div>

    <div class="main-content">
      <div class="chat-section">
        <div class="messages-container" ref="messagesContainer">
          <div v-if="hasMoreHistory" class="load-more-container">
            <a-button type="link" @click="loadMoreHistory" :loading="loadingHistory" size="small">
              Load More History
            </a-button>
          </div>
          <div v-for="(message, index) in messages" :key="index" class="message-item">
            <div v-if="message.type === 'user'" class="user-message">
              <div class="message-content">{{ message.content }}</div>
              <div class="message-avatar">
                <a-avatar :src="loginUserStore.loginUser.userAvatar" />
              </div>
            </div>
            <div v-else class="ai-message">
              <div class="message-avatar">
                <a-avatar>A</a-avatar>
              </div>
              <div class="message-content">
                <MarkdownRenderer v-if="message.content" :content="message.content" />
                <div v-if="message.loading" class="loading-indicator">
                  <a-spin size="small" />
                  <span>AI is thinking...</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="input-container">
          <div class="input-wrapper">
            <a-textarea
              v-if="isOwner"
              v-model:value="userInput"
              :placeholder="'Describe your requirements, e.g., change the background color to blue'"
              :rows="4"
              :maxlength="1000"
              @keydown.enter.prevent="sendMessage"
              :disabled="isGenerating"
              autocomplete="off"
              data-lpignore="true"
              data-form-type="other"
              data-ms-editor="false"
            />
            <a-tooltip v-else title="You cannot chat on others' works~" placement="top">
              <a-textarea
                v-model:value="userInput"
                placeholder="You cannot chat on others' works~"
                :rows="4"
                :maxlength="1000"
                :disabled="true"
                autocomplete="off"
                data-lpignore="true"
                data-form-type="other"
                data-ms-editor="false"
              />
            </a-tooltip>
            <div class="input-actions">
              <a-button type="primary" @click="sendMessage" :loading="isGenerating" :disabled="!isOwner">
                Send
              </a-button>
            </div>
          </div>
        </div>
      </div>

      <div class="preview-section">
        <div class="preview-header">
          <h3>Generated Web Page Preview</h3>
          <div class="preview-actions">
            <a-tooltip v-if="previewUrl && isOwner" :title="!supportsVisualEdit ? 'Vue projects and multi-file projects do not support visual editing. Please download the source code and edit manually' : null">
              <a-button 
                :disabled="!supportsVisualEdit" 
                @click="openVisualEditor"
              >
                Visual Editor
              </a-button>
            </a-tooltip>
            <a-button v-if="previewUrl" type="link" @click="openInNewTab">Open in New Tab</a-button>
          </div>
        </div>
        <div class="preview-content">
          <div v-if="isGenerating" class="preview-generating">
            <a-spin size="large" />
            <p>Generating web page, please wait...</p>
          </div>
          <div v-else-if="previewUrl && !previewLoadError && hasGeneratedCode" class="preview-iframe-wrapper">
            <iframe 
              :src="previewUrl" 
              class="preview-iframe"
              @load="onPreviewLoad"
              @error="onPreviewError"
            ></iframe>
          </div>
          <div v-else class="preview-placeholder">
            <iframe
              :src="previewPlaceholderUrl"
              class="preview-iframe preview-placeholder-iframe"
              title="No code generated yet, please provide requirements"
            ></iframe>
          </div>
        </div>
      </div>
    </div>

    <a-modal v-model:open="appDetailVisible" title="App Details" @ok="appDetailVisible = false">
      <a-descriptions v-if="appInfo" bordered>
        <a-descriptions-item label="App Name">{{ appInfo.appName }}</a-descriptions-item>
        <a-descriptions-item label="Code Type">{{ formatCodeGenType(appInfo.codeGenType) }}</a-descriptions-item>
        <a-descriptions-item label="Create Time">{{ formatTime(appInfo.createTime) }}</a-descriptions-item>
        <a-descriptions-item label="Initial Description" :span="3">{{ appInfo.initPrompt }}</a-descriptions-item>
      </a-descriptions>
    </a-modal>

    <a-modal
      v-model:open="visualEditorVisible"
      title="Visual Editor"
      width="100%"
      wrap-class-name="full-modal"
      :footer="null"
      @cancel="closeVisualEditor"
    >
      <div class="visual-editor-container">
        <div class="editor-toolbar">
          <div class="toolbar-left">
            <span>Click an element to edit</span>
          </div>
          <div class="toolbar-right">
            <a-button @click="closeVisualEditor" style="margin-right: 8px">Cancel</a-button>
            <a-button type="primary" @click="saveVisualEdit" :loading="saving">Save Changes</a-button>
          </div>
        </div>
        <div class="editor-main">
          <div class="editor-preview">
            <iframe ref="editorIframe" :src="previewUrl" class="editor-iframe" @load="onEditorIframeLoad"></iframe>
          </div>
          <div class="editor-sidebar">
            <a-tabs v-model:activeKey="activeTab" centered>
              <a-tab-pane key="attributes" tab="Properties">
                <div class="sidebar-content" v-if="selectedElement">
                  <div class="sidebar-header">
                    <div class="breadcrumb-container">
                      <span 
                        v-for="(item, index) in breadcrumbs" 
                        :key="index"
                        class="breadcrumb-item"
                        :class="{ active: item.element === selectedElement }"
                        @click="selectBreadcrumb(item)"
                      >
                        {{ item.tagName }}
                        <span v-if="index < breadcrumbs.length - 1" class="separator">></span>
                      </span>
                    </div>
                    <div class="current-tag">
                      <span class="tag-name">{{ selectedElement.tagName }}</span>
                    </div>
                  </div>
                  <a-form layout="vertical">
                    <!-- 图片上传 -->
                    <a-form-item label="Image" v-if="isImageElement">
                      <a-upload
                        :show-upload-list="false"
                        :before-upload="handleImageUpload"
                        accept="image/*"
                        list-type="picture-card"
                      >
                        <div v-if="currentImageSrc" class="image-preview-container">
                          <img :src="currentImageSrc" alt="Preview" style="width: 100%; height: 100%; object-fit: cover;" />
                        </div>
                        <div v-else class="upload-placeholder">
                          <div style="font-size: 24px; margin-bottom: 8px;">📷</div>
                          <div>Click to Upload Image</div>
                        </div>
                      </a-upload>
                      <div style="margin-top: 8px; font-size: 12px; color: #999;">
                        Supports JPG, PNG, GIF formats, recommended size under 5MB
                      </div>
                    </a-form-item>
                    
                    <a-form-item label="Text Content" v-if="hasTextContent && !isImageElement">
                      <a-textarea
                        v-model:value="elementStyle.textContent"
                        @change="updateElementText"
                        :rows="4"
                      />
                    </a-form-item>
                    
                    <a-divider>Styles</a-divider>
                    
                    <a-form-item label="Text Color">
                      <input type="color" v-model="elementStyle.color" @input="updateElementStyle('color')" />
                      <span style="margin-left: 8px">{{ elementStyle.color }}</span>
                    </a-form-item>
                    
                    <a-form-item label="Background Color">
                      <input type="color" v-model="elementStyle.backgroundColor" @input="updateElementStyle('backgroundColor')" />
                      <span style="margin-left: 8px">{{ elementStyle.backgroundColor }}</span>
                    </a-form-item>
                    
                    <a-form-item label="Font Size">
                       <a-input v-model:value="elementStyle.fontSize" @change="updateElementStyle('fontSize')" />
                    </a-form-item>

                     <a-form-item label="Padding">
                       <a-input v-model:value="elementStyle.padding" @change="updateElementStyle('padding')" />
                    </a-form-item>

                     <a-form-item label="Margin">
                       <a-input v-model:value="elementStyle.margin" @change="updateElementStyle('margin')" />
                    </a-form-item>
                  </a-form>
                </div>
                <div class="editor-sidebar-empty" v-else>
                  <p>Please click an element on the left to edit</p>
                </div>
              </a-tab-pane>
              <a-tab-pane key="components" tab="Components">
                <div class="components-list">
                  <div class="component-item" @click="addComponent('text')">
                    <div class="icon">T</div>
                    <span>Text Paragraph</span>
                  </div>
                  <div class="component-item" @click="addComponent('button')">
                    <div class="icon">B</div>
                    <span>Button</span>
                  </div>
                  <div class="component-item" @click="addComponent('container')">
                    <div class="icon">⬜</div>
                    <span>Container</span>
                  </div>
                  <div class="component-item" @click="addComponent('input')">
                    <div class="icon">I</div>
                    <span>Input</span>
                  </div>
                  <div class="component-item" @click="addComponent('image')">
                    <div class="icon">🖼️</div>
                    <span>Image Placeholder</span>
                  </div>
                </div>
              </a-tab-pane>
            </a-tabs>
          </div>
        </div>
      </div>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, nextTick, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { message } from 'ant-design-vue'
import { useLoginUserStore } from '@/stores/loginUser'
import {
  getAppVoById,
  chatToGenCode,
  downloadAppCode,
  updateAppCode,
  getPreviewPath,
} from '@/api/appController'
import { listAppChatHistory } from '@/api/chatHistoryController'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'

const route = useRoute()
const loginUserStore = useLoginUserStore()

// 使用字符串类型的 appId，避免大整数精度丢失
const appId = route.params.id as string
const appInfo = ref<API.AppVO | null>(null)
const previewPlaceholderUrl = '/preview-placeholder.html'

const getAppOwnerId = () => appInfo.value?.userId ?? appInfo.value?.user?.id

const isOwner = computed(() => {
  const appUserId = getAppOwnerId()
  const loginUserId = loginUserStore.loginUser.id
  
  // 只要有一个ID不存在，就暂时认为不是owner（等待数据加载）
  if (appUserId == null || loginUserId == null) {
    console.log('权限检查等待中:', {
      appUserId,
      loginUserId,
      appUserIdType: typeof appUserId,
      loginUserIdType: typeof loginUserId
    })
    return false
  }
  
  // 后端Long类型序列化为字符串，前端可能解析为number或string
  // 统一转换为字符串进行比较，避免类型不一致和精度丢失问题
  const appUserIdStr = String(appUserId)
  const loginUserIdStr = String(loginUserId)
  const isMatch = appUserIdStr === loginUserIdStr
  
  // 调试日志
  if (!isMatch) {
    console.warn('权限检查失败详情:', {
      appUserId,
      loginUserId,
      appUserIdType: typeof appUserId,
      loginUserIdType: typeof loginUserId,
      appUserIdStr,
      loginUserIdStr,
      appInfo: appInfo.value,
      loginUser: loginUserStore.loginUser,
      // 检查是否是精度丢失问题
      appUserIdNum: typeof appUserId === 'number' ? appUserId : Number(appUserId),
      loginUserIdNum: typeof loginUserId === 'number' ? loginUserId : Number(loginUserId)
    })
  } else {
    console.log('权限检查通过:', {
      appUserId,
      loginUserId,
      appUserIdStr,
      loginUserIdStr
    })
  }
  
  return isMatch
})

const supportsVisualEdit = computed(() => {
  if (!appInfo.value) return false
  const type = appInfo.value.codeGenType || 'html'
  const lowerType = type.toLowerCase()
  // Vue项目和多文件项目不支持可视化编辑（因为是源码构建，无法通过反写HTML保存）
  return !lowerType.includes('vue') && !lowerType.includes('multi')
})

// 添加 watch 监听权限变化，用于调试
watch(
  [() => getAppOwnerId(), () => loginUserStore.loginUser.id, isOwner],
  ([appUserId, loginUserId, owner]) => {
    console.log('权限状态变化:', {
      appUserId,
      loginUserId,
      appUserIdType: typeof appUserId,
      loginUserIdType: typeof loginUserId,
      appUserIdStr: appUserId != null ? String(appUserId) : null,
      loginUserIdStr: loginUserId != null ? String(loginUserId) : null,
      isMatch: appUserId != null && loginUserId != null && String(appUserId) === String(loginUserId),
      isOwner: owner
    })
  },
  { immediate: true, deep: true }
)

const messages = ref<
  Array<{
    type: 'user' | 'ai'
    content: string
    loading?: boolean
  }>
>([])

const userInput = ref('')
const isGenerating = ref(false)
const downloading = ref(false)
const previewUrl = ref('')
const previewLoadError = ref(false)
const appDetailVisible = ref(false)
const messagesContainer = ref<HTMLElement>()

// 判断是否已经生成了代码
const hasGeneratedCode = computed(() => {
  // 如果有预览URL且没有加载错误，认为有代码
  if (previewUrl.value && !previewLoadError.value) {
    return true
  }
  
  // 如果是Vue项目，只要后端文件生成完毕（通过 SSE done 事件或轮询获取到了 previewUrl），就认为生成了
  // 此时前端可能通过 SSE done 事件设置了 previewUrl，但 previewUrl 可能还没加载出来 iframe
  // 但只要 previewUrl 有值，就不应该显示 loading
  if (appInfo.value?.codeGenType === 'vue_project' && previewUrl.value) {
    return true
  }

  // 如果有历史消息且包含用户消息和AI回复（不是只有初始欢迎消息）
  const userMessages = messages.value.filter(m => m.type === 'user')
  const aiMessages = messages.value.filter(m => m.type === 'ai' && m.content && !m.loading)
  // 至少有一条用户消息和一条AI回复，且AI回复不是初始欢迎消息
  if (userMessages.length > 0 && aiMessages.length > 0) {
    // 检查AI消息是否包含代码相关的内容（不是欢迎消息）
    const hasCodeContent = aiMessages.some(m => {
      const content = m.content.toLowerCase()
      // 排除初始欢迎消息的特征
      return !content.includes('我是你的') && 
             !content.includes('web前端开发助手') &&
             !content.includes('可以帮你构建') &&
             (content.includes('<!doctype') || 
              content.includes('<html') || 
              content.includes('代码') ||
              content.length > 200) // 如果内容很长，可能是代码
    })
    
    // 如果是HTML模式，直接通过消息内容判断
    if (appInfo.value?.codeGenType !== 'vue_project') {
    return hasCodeContent
  }
    
    // 修正：如果是Vue项目，仅仅有消息内容是不够的，必须要有 previewUrl 才算真正生成完毕并构建成功
    // 否则会一直显示“生成中”的 loading 状态
    if (hasCodeContent && previewUrl.value) {
    return true
  }
  }
  
  // 特殊情况：如果 Vue 项目构建失败（previewUrl 一直为空），但 SSE 已经结束（isGenerating=false），
  // 且有代码内容，此时应该显示 placeholder 或错误提示，而不是一直转圈。
  // 我们可以增加一个判断：如果 !isGenerating 且有代码内容，也认为生成结束（虽然可能没预览）
  if (!isGenerating.value && userMessages.length > 0 && aiMessages.length > 0) {
     return true
  }

  return false
})

const loadingHistory = ref(false)
const hasMoreHistory = ref(false)
const lastCreateTime = ref<string | null>(null)

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
  return new Date(time).toLocaleString('en-US')
}

const loadAppInfo = async () => {
  try {
    const res = await getAppVoById({ id: appId })
    if (res.data.code === 0 && res.data.data) {
      appInfo.value = res.data.data
      
      // 调试信息：检查应用和用户ID
      console.log('应用信息加载完成:', {
        appId: appInfo.value.id,
        appUserId: appInfo.value.userId,
        appUserIdType: typeof appInfo.value.userId,
        loginUserId: loginUserStore.loginUser.id,
        loginUserIdType: typeof loginUserStore.loginUser.id,
        isOwner: isOwner.value
      })
      
      // 如果应用有代码生成类型，尝试获取预览路径
      // 不依赖messages.value，因为历史消息可能还没加载
      if (appInfo.value.codeGenType) {
        // 通过API获取正确的预览路径
        try {
          console.log('开始获取预览路径，appId:', appId, 'codeGenType:', appInfo.value.codeGenType)
          const res = await getPreviewPath({ appId })
          console.log('预览路径API响应:', res.data)
          if (res.data.code === 0 && res.data.data) {
            previewUrl.value = res.data.data + `?t=${Date.now()}`
            previewLoadError.value = false
            console.log('设置预览URL:', previewUrl.value)
          } else {
            console.warn('预览路径API返回失败:', res.data)
            // 预览路径获取失败，但不设置错误状态，让历史消息加载后再判断
            previewUrl.value = ''
            previewLoadError.value = false
          }
        } catch (error) {
          console.error('获取预览路径失败：', error)
          // 预览路径获取失败，但不设置错误状态，让历史消息加载后再判断
          previewUrl.value = ''
          previewLoadError.value = false
        }
      } else {
        // 如果应用没有代码生成类型（新建项目），清空预览URL但不设置错误状态
        previewUrl.value = ''
        previewLoadError.value = false
      }
    }
  } catch (error) {
    console.error('加载应用信息失败：', error)
    message.error('Failed to load app information')
  }
}

const loadHistory = async () => {
  if (!appId) return

  loadingHistory.value = true
  try {
    const res = await listAppChatHistory({
      appId,
      pageSize: 10,
      lastCreateTime: lastCreateTime.value || undefined,
    })

    if (res.data.code === 0 && res.data.data) {
      const chatHistoryList = res.data.data.records || []
      const historyMessages = chatHistoryList.map((item: API.ChatHistory) => ({
        type: item.messageType as 'user' | 'ai',
        content: item.message,
      }))

      if (lastCreateTime.value) {
        messages.value = [...historyMessages, ...messages.value]
      } else {
        messages.value = historyMessages
      }

      hasMoreHistory.value = chatHistoryList.length >= 10
      if (chatHistoryList.length > 0) {
        lastCreateTime.value = chatHistoryList[chatHistoryList.length - 1].createTime
      }

      await nextTick()
      scrollToBottom()
      
      // 历史消息加载完成后，如果有代码生成类型，再次尝试获取预览路径
      // 这样可以确保即使历史消息中有代码，也能正确显示预览
      if (appInfo.value?.codeGenType && chatHistoryList.length > 0) {
        // 检查历史消息中是否有实际代码（不是欢迎消息）
        const hasActualCode = historyMessages.some(m => {
          if (m.type === 'ai' && m.content) {
            const content = m.content.toLowerCase()
            return !content.includes('我是你的') && 
                   !content.includes('web前端开发助手') &&
                   !content.includes('可以帮你构建') &&
                   (content.includes('<!doctype') || 
                    content.includes('<html') || 
                    content.includes('代码') ||
                    content.length > 200)
          }
          return false
        })
        
        if (hasActualCode && !previewUrl.value) {
          console.log('历史消息中有代码，尝试获取预览路径')
          try {
            const res = await getPreviewPath({ appId })
            if (res.data.code === 0 && res.data.data) {
              previewUrl.value = res.data.data + `?t=${Date.now()}`
              previewLoadError.value = false
              console.log('从历史消息设置预览URL:', previewUrl.value)
            }
          } catch (error) {
            console.error('从历史消息获取预览路径失败：', error)
          }
        }
      }
      
      // 如果没有历史消息且是应用所有者，自动使用 initPrompt 生成初始代码
      console.log('检查自动生成条件:', {
        chatHistoryLength: chatHistoryList.length,
        isOwner: isOwner.value,
        hasInitPrompt: !!appInfo.value?.initPrompt,
        appUserId: getAppOwnerId(),
        loginUserId: loginUserStore.loginUser.id,
        appInfo: appInfo.value,
        loginUser: loginUserStore.loginUser
      })
      
      // 检查是否是所有者（即使isOwner.value可能因为响应式延迟为false，也检查实际数据）
      // 后端Long类型序列化为字符串，统一转换为字符串比较
      const appUserId = getAppOwnerId()
      const loginUserId = loginUserStore.loginUser.id
      const isActuallyOwner = appUserId != null && loginUserId != null && String(appUserId) === String(loginUserId)
      
      if (chatHistoryList.length === 0 && isActuallyOwner && appInfo.value?.initPrompt) {
        console.log('满足自动生成条件，开始生成代码')
        // 如果isOwner.value还是false，再等待一下
        if (!isOwner.value) {
          console.log('isOwner.value为false，但数据匹配，等待响应式更新...')
          await nextTick()
          await new Promise(resolve => setTimeout(resolve, 200))
        }
        await autoGenerateInitialCode()
      } else {
        console.log('不满足自动生成条件，跳过', {
          noHistory: chatHistoryList.length === 0,
          isActuallyOwner,
          hasInitPrompt: !!appInfo.value?.initPrompt
        })
      }
    }
  } catch (error) {
    console.error('加载历史消息失败：', error)
  } finally {
    loadingHistory.value = false
  }
}

const loadMoreHistory = async () => {
  await loadHistory()
}

const autoGenerateInitialCode = async () => {
  if (!appInfo.value?.initPrompt || isGenerating.value) {
    console.log('autoGenerateInitialCode: 条件不满足', {
      hasInitPrompt: !!appInfo.value?.initPrompt,
      isGenerating: isGenerating.value
    })
    return
  }

  // 再次检查isOwner，如果还是false但数据匹配，强制设置
  // 后端Long类型序列化为字符串，统一转换为字符串比较
      const appUserId = getAppOwnerId()
  const loginUserId = loginUserStore.loginUser.id
  const isActuallyOwner = appUserId != null && loginUserId != null && String(appUserId) === String(loginUserId)
  
  if (!isActuallyOwner) {
    console.log('autoGenerateInitialCode: 不是所有者，取消生成')
    return
  }

  const initPrompt = appInfo.value.initPrompt
  userInput.value = initPrompt
  
  // 延迟一下，确保界面已渲染
  await nextTick()
  await new Promise(resolve => setTimeout(resolve, 500))
  
  // 再次检查isOwner，如果还是false，再等待
  if (!isOwner.value) {
    console.log('autoGenerateInitialCode: isOwner.value仍为false，等待响应式更新...')
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 300))
  }
  
  // 如果isOwner.value还是false，但数据匹配，我们仍然尝试发送（sendMessage内部会再次检查）
  console.log('autoGenerateInitialCode: 准备发送消息', {
    isOwner: isOwner.value,
    isActuallyOwner,
    initPrompt: initPrompt.substring(0, 50) + '...'
  })
  
  // 自动发送消息
  await sendMessage()
}

const sendMessage = async () => {
  if (!userInput.value.trim() || isGenerating.value) {
    return
  }
  
  // 检查是否是所有者：优先使用isOwner.value，如果为false但数据匹配，也允许发送
  // 后端Long类型序列化为字符串，统一转换为字符串比较
  const appUserId = getAppOwnerId()
  const loginUserId = loginUserStore.loginUser.id
  const isActuallyOwner = appUserId != null && loginUserId != null && String(appUserId) === String(loginUserId)
  
  if (!isActuallyOwner) {
    console.log('sendMessage: 不是所有者，拒绝发送', {
      appUserId,
      loginUserId,
      isOwner: isOwner.value
    })
    message.warning('You cannot chat on others\' works~')
    return
  }
  
  // 如果isOwner.value为false但数据匹配，记录警告但继续
  if (!isOwner.value) {
    console.warn('sendMessage: isOwner.value为false，但数据匹配，继续发送', {
      appUserId,
      loginUserId
    })
  }

  const userMessage = userInput.value.trim()
  userInput.value = ''

  messages.value.push({
    type: 'user',
    content: userMessage,
  })

  messages.value.push({
    type: 'ai',
    content: '',
    loading: true,
  })

  await nextTick()
  scrollToBottom()

  isGenerating.value = true

  try {
    const eventSource = await chatToGenCode({
      appId,
      message: userMessage,
    })

    let aiResponse = ''

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        if (data.d) {
          aiResponse += data.d
          const lastMessage = messages.value[messages.value.length - 1]
          if (lastMessage && lastMessage.type === 'ai') {
            lastMessage.content = aiResponse
            lastMessage.loading = false
          }
          scrollToBottom()
        }
      } catch (e) {
        console.error('解析SSE消息失败：', e)
      }
    }

    eventSource.addEventListener('done', () => {
      eventSource.close()
      const lastMessage = messages.value[messages.value.length - 1]
      if (lastMessage && lastMessage.type === 'ai') {
        lastMessage.loading = false
      }

      setTimeout(async () => {
        // 重新加载应用信息，获取最新的状态
        await loadAppInfo()
        // 代码生成完成后，重新获取预览URL
        // 等待一下确保后端文件已生成
        setTimeout(async () => {
          if (appInfo.value?.codeGenType) {
            try {
              console.log('代码生成完成，获取预览路径，appId:', appId, 'codeGenType:', appInfo.value.codeGenType)
              const res = await getPreviewPath({ appId })
              console.log('预览路径API响应:', res.data)
              if (res.data.code === 0 && res.data.data) {
                previewUrl.value = res.data.data + `?t=${Date.now()}`
                previewLoadError.value = false
                console.log('设置预览URL:', previewUrl.value)
              } else {
                console.warn('预览路径API返回失败:', res.data)
                previewUrl.value = ''
                previewLoadError.value = true
              }
            } catch (error) {
              console.error('获取预览路径失败：', error)
              previewUrl.value = ''
              previewLoadError.value = true
            }
          }
        }, 2000) // 等待2秒确保后端文件已生成
        isGenerating.value = false
      }, 1000)
    })

    eventSource.onerror = () => {
      eventSource.close()
      isGenerating.value = false
      const lastMessage = messages.value[messages.value.length - 1]
      if (lastMessage && lastMessage.type === 'ai') {
        lastMessage.loading = false
        if (!lastMessage.content) {
          lastMessage.content = '生成失败，请重试'
        }
      }
      message.error('Generation failed, please try again')
    }
  } catch (error) {
    console.error('发送消息失败：', error)
    isGenerating.value = false
    const lastMessage = messages.value[messages.value.length - 1]
    if (lastMessage && lastMessage.type === 'ai') {
      lastMessage.loading = false
      lastMessage.content = '生成失败，请重试'
    }
    message.error('Failed to send message')
  }
}

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

const downloadCode = async () => {
  if (!isOwner.value) {
    message.warning('You can only download apps you created')
    return
  }

  downloading.value = true
  try {
    const res = await downloadAppCode({ appId })
    const blob = new Blob([res.data], { type: 'application/zip' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${appId}.zip`
    link.click()
    window.URL.revokeObjectURL(url)
    message.success('Download successful')
  } catch (error) {
    console.error('下载失败：', error)
    message.error('Download failed')
  } finally {
    downloading.value = false
  }
}

const showAppDetail = () => {
  appDetailVisible.value = true
}

const openInNewTab = () => {
  if (previewUrl.value) {
    window.open(previewUrl.value, '_blank')
  }
}

const onPreviewLoad = () => {
  // 延迟检查 iframe 内容，因为跨域情况下可能无法立即访问
  setTimeout(() => {
    const iframe = document.querySelector('.preview-iframe') as HTMLIFrameElement
    if (iframe) {
      try {
        // 尝试访问 iframe 内容（可能因跨域失败）
        const iframeDoc = iframe.contentDocument || iframe.contentWindow?.document
        if (iframeDoc) {
          // 如果能访问，检查是否是错误页面
          const bodyText = iframeDoc.body?.innerText || ''
          if (bodyText.includes('404') || bodyText.includes('Not Found') || bodyText.includes('error')) {
            previewLoadError.value = true
          } else {
            previewLoadError.value = false
          }
        } else {
          // 跨域情况下，无法访问内容，假设加载成功
          // 但如果之前有错误标记，保持错误状态
          // 这里我们假设跨域加载是成功的（因为浏览器没有阻止）
        }
      } catch (e) {
        // 跨域访问被阻止，这是正常的，不设置错误
        // 但如果之前有错误标记，保持错误状态
      }
    }
  }, 1000)
}

const onPreviewError = () => {
  // iframe 加载失败，设置错误状态
  previewLoadError.value = true
}

// 可视化编辑器状态
const visualEditorVisible = ref(false)
const editorIframe = ref<HTMLIFrameElement>()
const selectedElement = ref<HTMLElement | null>(null)
const saving = ref(false)
const activeTab = ref('attributes')

const elementStyle = reactive({
  textContent: '',
  color: '#000000',
  backgroundColor: '#ffffff',
  fontSize: '',
  padding: '',
  margin: ''
})

const hasTextContent = computed(() => {
  return selectedElement.value && 
         selectedElement.value.childNodes.length > 0 && 
         Array.from(selectedElement.value.childNodes).some(node => node.nodeType === 3 && node.textContent?.trim())
})

// 判断是否是图片元素
const isImageElement = computed(() => {
  if (!selectedElement.value) return false
  const tagName = selectedElement.value.tagName?.toUpperCase()
  // 是 img 标签
  if (tagName === 'IMG') return true
  // 或者是包含"Image Placeholder"文本的 div
  if (tagName === 'DIV' && selectedElement.value.textContent?.trim() === 'Image Placeholder') {
    return true
  }
  return false
})

// 当前图片的 src
const currentImageSrc = computed(() => {
  if (!selectedElement.value) return ''
  if (selectedElement.value.tagName?.toUpperCase() === 'IMG') {
    return (selectedElement.value as HTMLImageElement).src
  }
  return ''
})

const openVisualEditor = () => {
  visualEditorVisible.value = true
}

const closeVisualEditor = () => {
  visualEditorVisible.value = false
  selectedElement.value = null
}

// Iframe 加载完成，注入交互脚本
const onEditorIframeLoad = () => {
  const iframe = editorIframe.value
  if (!iframe || !iframe.contentWindow) return

  const doc = iframe.contentDocument
  if (!doc) return

  // 注入样式，高亮 hover 元素和拖拽样式
  const style = doc.createElement('style')
  style.innerHTML = `
    .visual-editor-hover {
      outline: 2px dashed #1890ff !important;
      cursor: pointer !important;
    }
    .visual-editor-selected {
      outline: 2px solid #1890ff !important;
      position: relative !important;
    }
    .visual-editor-dragging {
      opacity: 0.5 !important;
      cursor: move !important;
    }
    .visual-editor-drag-handle {
      position: absolute;
      top: -8px;
      left: -8px;
      width: 20px;
      height: 20px;
      background: #1890ff;
      border-radius: 50%;
      cursor: move;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-size: 12px;
      z-index: 10000;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    .visual-editor-drag-handle::before {
      content: '⋮⋮';
      line-height: 1;
    }
  `
  doc.head.appendChild(style)

  // 绑定事件
  doc.body.addEventListener('mouseover', (e) => {
    e.stopPropagation()
    const target = e.target as HTMLElement
    if (target === doc.body) return
    target.classList.add('visual-editor-hover')
  })

  doc.body.addEventListener('mouseout', (e) => {
    e.stopPropagation()
    const target = e.target as HTMLElement
    target.classList.remove('visual-editor-hover')
  })

  // 绑定事件 - 在捕获阶段监听 click 事件，确保能拦截所有点击（包括链接跳转）
  doc.body.addEventListener('click', (e) => {
    // 如果点击的是拖拽手柄，不处理选中
    if ((e.target as HTMLElement).classList.contains('visual-editor-drag-handle')) {
      return
    }
    
    e.preventDefault()
    e.stopPropagation()
    
    // 移除旧的选中状态和拖拽手柄
    const oldSelected = doc.querySelector('.visual-editor-selected')
    if (oldSelected) {
      oldSelected.classList.remove('visual-editor-selected')
      const oldHandle = oldSelected.querySelector('.visual-editor-drag-handle')
      if (oldHandle) {
        oldHandle.remove()
      }
    }

    const target = e.target as HTMLElement
    if (target === doc.body || target.classList.contains('visual-editor-drag-handle')) {
      selectedElement.value = null
      return
    }

    target.classList.add('visual-editor-selected')
    selectedElement.value = target
    
    // 添加拖拽手柄
    addDragHandle(target, doc)
    
    // 同步属性到编辑器
    syncElementToEditor(target)
  }, true) // 使用 capture: true 拦截
  
  // 初始化所有元素的拖拽功能
  enableDragForAllElements(doc)
}

// 为元素添加拖拽手柄
const addDragHandle = (element: HTMLElement, doc: Document) => {
  // 移除旧的拖拽手柄
  const oldHandle = element.querySelector('.visual-editor-drag-handle')
  if (oldHandle) {
    oldHandle.remove()
  }
  
  // 确保元素有定位
  const computedStyle = doc.defaultView?.getComputedStyle(element)
  if (computedStyle && computedStyle.position === 'static') {
    element.style.position = 'relative'
  }
  
  // 创建拖拽手柄
  const handle = doc.createElement('div')
  handle.className = 'visual-editor-drag-handle'
  element.appendChild(handle)
}

// 为所有元素启用拖拽功能
const enableDragForAllElements = (doc: Document) => {
  let draggedElement: HTMLElement | null = null
  let startX = 0
  let startY = 0
  let startLeft = 0
  let startTop = 0
  let isDragging = false
  
  // 鼠标按下事件
  doc.body.addEventListener('mousedown', (e) => {
    const target = e.target as HTMLElement
    
    // 如果点击的是拖拽手柄
    if (target.classList.contains('visual-editor-drag-handle')) {
      e.preventDefault()
      e.stopPropagation()
      draggedElement = target.parentElement as HTMLElement
      if (!draggedElement) return
      
      // 初始化起始坐标，但不立即开始拖拽
      startX = e.clientX
      startY = e.clientY
      
      const computedStyle = doc.defaultView?.getComputedStyle(draggedElement)
      startLeft = parseFloat(computedStyle?.left || '0') || 0
      startTop = parseFloat(computedStyle?.top || '0') || 0
      
      // 确保 position 不是 static
      if (computedStyle && computedStyle.position === 'static') {
        draggedElement.style.position = 'relative'
        startLeft = 0
        startTop = 0
      }
      
      isDragging = true
      return
    }
    
    // 如果点击的是已选中的元素，也可以拖拽
    if (target.classList.contains('visual-editor-selected')) {
      // 不阻止默认行为，否则无法触发点击选中逻辑
      // e.preventDefault()
      // e.stopPropagation()
      
      draggedElement = target
      // 不立即添加样式，移动时再添加
      // draggedElement.classList.add('visual-editor-dragging')
      
      startX = e.clientX
      startY = e.clientY
      
      const computedStyle = doc.defaultView?.getComputedStyle(draggedElement)
      startLeft = parseFloat(computedStyle?.left || '0') || 0
      startTop = parseFloat(computedStyle?.top || '0') || 0
      
      // 确保 position 不是 static
      if (computedStyle && computedStyle.position === 'static') {
        draggedElement.style.position = 'relative'
        startLeft = 0
        startTop = 0
      }
      
      isDragging = true
    }
  })
  
  // 鼠标移动事件
  doc.body.addEventListener('mousemove', (e) => {
    if (!isDragging || !draggedElement) return
    
    const deltaX = e.clientX - startX
    const deltaY = e.clientY - startY
    
    // 增加拖拽阈值，只有移动距离超过 5px 才算拖拽
    if (Math.abs(deltaX) < 5 && Math.abs(deltaY) < 5) {
      return
    }
    
    e.preventDefault()
    
    // 真正开始拖拽时才添加样式
    if (!draggedElement.classList.contains('visual-editor-dragging')) {
      draggedElement.classList.add('visual-editor-dragging')
    }
    
    // 更新位置 (基于 Delta 计算)
    draggedElement.style.left = `${startLeft + deltaX}px`
    draggedElement.style.top = `${startTop + deltaY}px`
  })
  
  // 鼠标释放事件
  doc.body.addEventListener('mouseup', (e) => {
    if (draggedElement && draggedElement.classList.contains('visual-editor-dragging')) {
      draggedElement.classList.remove('visual-editor-dragging')
      
      // 1. 隐藏拖拽元素以进行点击测试
      const prevDisplay = draggedElement.style.display
      draggedElement.style.display = 'none'
      
      // 2. 获取鼠标位置下的元素
      let target = doc.elementFromPoint(e.clientX, e.clientY) as HTMLElement
      
      // 3. 恢复显示
      draggedElement.style.display = prevDisplay
      
      if (target && target !== draggedElement && !draggedElement.contains(target) && target !== doc.documentElement && target !== doc.body) {
        // 策略：
        // 1. 向上查找是否有与拖拽元素“类名相同”的祖先元素（视为同类组件）。如果有，则在该组件前后插入（排序）。
        // 2. 如果没有找到同类组件：
        //    - 如果目标是容器（DIV, SECTION 等），则追加到该容器内部。
        //    - 如果目标是内容（P, SPAN, H1 等），则在该内容前后插入。
        
        const draggedBaseClasses = getBaseClasses(draggedElement)
        let peerMatch: HTMLElement | null = null
        
        // 如果拖拽元素有特定类名，才尝试匹配同类
        if (draggedBaseClasses) {
          let curr: HTMLElement | null = target
          while (curr && curr !== doc.body && curr !== doc.documentElement) {
            if (getBaseClasses(curr) === draggedBaseClasses) {
              peerMatch = curr
              break
            }
            curr = curr.parentElement
          }
        }
        
        // 清除定位样式，回归文档流
        draggedElement.style.position = ''
        draggedElement.style.left = ''
        draggedElement.style.top = ''
        
        if (peerMatch && peerMatch.parentElement) {
          // 模式 A：同类排序
          moveElementRelativeTo(draggedElement, peerMatch, e.clientX, e.clientY)
          message.success('Component order adjusted')
        } else {
          // 模式 B：异类处理
          if (['DIV', 'SECTION', 'MAIN', 'ARTICLE', 'HEADER', 'FOOTER', 'ASIDE', 'NAV', 'FORM', 'UL', 'OL'].includes(target.tagName)) {
            // 容器 -> 追加到末尾
            target.appendChild(draggedElement)
            message.success('Moved to container')
          } else {
             // 内容 -> 插入到旁边
             if (target.parentElement) {
               moveElementRelativeTo(draggedElement, target, e.clientX, e.clientY)
               message.success('Position adjusted')
             }
          }
        }
      } else {
        // 如果没有有效的放置目标，保留 relative 定位（或者归位）
        // 这里选择保留 relative，让用户感觉到“移动了但没改变结构”
        const computedStyle = draggedElement.style
        if (!computedStyle.position || computedStyle.position === 'static') {
          draggedElement.style.position = 'relative'
        }
      }
      
      draggedElement = null
    }
    isDragging = false
  })
}

const getBaseClasses = (el: HTMLElement) => {
  if (!el.classList) return ''
  return Array.from(el.classList)
    .filter(c => !c.startsWith('visual-editor-'))
    .sort()
    .join(' ')
}

const moveElementRelativeTo = (element: HTMLElement, reference: HTMLElement, clientX: number, clientY: number) => {
  const rect = reference.getBoundingClientRect()
  const isVertical = rect.height > rect.width
  
  const centerX = rect.left + rect.width / 2
  const centerY = rect.top + rect.height / 2
  
  let insertBefore = false
  if (isVertical) {
    insertBefore = clientY < centerY
  } else {
    insertBefore = clientX < centerX
  }
  
  if (insertBefore) {
    reference.parentElement?.insertBefore(element, reference)
  } else {
    reference.parentElement?.insertBefore(element, reference.nextSibling)
  }
}

// 尝试重排元素 (Legacy: 已被 mouseup 逻辑取代，已删除未使用的函数)

const rgbToHex = (rgb: string) => {
  if (!rgb) return '#000000'
  if (rgb.startsWith('#')) return rgb
  const rgbMatch = rgb.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/)
  if (!rgbMatch) return '#000000'
  const hex = (x: string) => ("0" + parseInt(x).toString(16)).slice(-2);
  return "#" + hex(rgbMatch[1]) + hex(rgbMatch[2]) + hex(rgbMatch[3]);
}

const breadcrumbs = ref<Array<{ tagName: string; element: HTMLElement }>>([])

const selectBreadcrumb = (item: { tagName: string; element: HTMLElement }) => {
  if (!item.element) return
  
  const doc = editorIframe.value?.contentDocument
  if (!doc) return

  // 移除当前选中
  const oldSelected = doc.querySelector('.visual-editor-selected')
  if (oldSelected) {
    oldSelected.classList.remove('visual-editor-selected')
    const oldHandle = oldSelected.querySelector('.visual-editor-drag-handle')
    if (oldHandle) {
      oldHandle.remove()
    }
  }
  
  // 选中新元素
  const target = item.element
  target.classList.add('visual-editor-selected')
  selectedElement.value = target
  
  addDragHandle(target, doc)
  syncElementToEditor(target)
}

const syncElementToEditor = (el: HTMLElement) => {
  elementStyle.textContent = el.innerText 
  
  // 生成面包屑
  breadcrumbs.value = []
  let current: HTMLElement | null = el
  while (current && current.tagName !== 'BODY' && current.tagName !== 'HTML') {
    breadcrumbs.value.unshift({
      tagName: current.tagName.toLowerCase(),
      element: current
    })
    current = current.parentElement
  }
  
  const iframeWindow = editorIframe.value?.contentWindow
  if (!iframeWindow) return
  
  const style = iframeWindow.getComputedStyle(el)
  
  elementStyle.color = rgbToHex(style.color)
  elementStyle.backgroundColor = rgbToHex(style.backgroundColor)
  elementStyle.fontSize = style.fontSize
  elementStyle.padding = style.padding
  elementStyle.margin = style.margin
}

const updateElementText = () => {
  if (selectedElement.value) {
    selectedElement.value.innerText = elementStyle.textContent
  }
}

const updateElementStyle = (prop: string) => {
  if (selectedElement.value) {
    // @ts-ignore
    selectedElement.value.style[prop] = elementStyle[prop as keyof typeof elementStyle]
  }
}

// 处理图片上传
const handleImageUpload = (file: File): Promise<boolean> => {
  return new Promise((resolve, reject) => {
    // 检查文件大小（5MB）
    if (file.size > 5 * 1024 * 1024) {
      message.error('Image size cannot exceed 5MB')
      reject(new Error('File too large'))
      return
    }
    
    // 检查文件类型
    if (!file.type.startsWith('image/')) {
      message.error('Please upload an image file')
      reject(new Error('Invalid file type'))
      return
    }
    
    const reader = new FileReader()
    reader.onload = (e) => {
      const base64 = e.target?.result as string
      if (!base64 || !selectedElement.value) {
        reject(new Error('Failed to read file'))
        return
      }
      
      const doc = editorIframe.value?.contentDocument
      if (!doc) {
        reject(new Error('Cannot access editor document'))
        return
      }
      
      // 如果当前是 div（Image Placeholder），替换为 img 标签
      if (selectedElement.value.tagName?.toUpperCase() === 'DIV') {
        const img = doc.createElement('img')
        img.src = base64
        img.style.width = '100%'
        img.style.height = 'auto'
        img.style.display = 'block'
        img.style.position = 'relative'
        
        // 保留原有的样式
        const computedStyle = window.getComputedStyle(selectedElement.value)
        if (computedStyle.width && computedStyle.width !== 'auto') {
          img.style.width = computedStyle.width
        }
        if (computedStyle.height && computedStyle.height !== 'auto') {
          img.style.height = computedStyle.height
        }
        if (computedStyle.margin) {
          img.style.margin = computedStyle.margin
        }
        if (computedStyle.padding) {
          img.style.padding = computedStyle.padding
        }
        
        // 替换元素
        selectedElement.value.parentElement?.replaceChild(img, selectedElement.value)
        selectedElement.value = img
        
        // 更新选中状态
        const oldSelected = doc.querySelector('.visual-editor-selected')
        if (oldSelected) {
          oldSelected.classList.remove('visual-editor-selected')
        }
        img.classList.add('visual-editor-selected')
        addDragHandle(img, doc)
        syncElementToEditor(img)
      } else if (selectedElement.value.tagName?.toUpperCase() === 'IMG') {
        // 如果已经是 img 标签，直接更新 src
        (selectedElement.value as HTMLImageElement).src = base64
        syncElementToEditor(selectedElement.value)
      }
      
      message.success('Image uploaded successfully')
      resolve(false) // 阻止默认上传行为
    }
    
    reader.onerror = () => {
      message.error('Failed to read image')
      reject(new Error('Failed to read file'))
    }
    
    reader.readAsDataURL(file)
  })
}

const addComponent = (type: string) => {
  if (!editorIframe.value?.contentDocument) return
  
  const doc = editorIframe.value.contentDocument
  let newElement: HTMLElement | null = null
  
  switch (type) {
    case 'text':
      newElement = doc.createElement('p')
      newElement.textContent = 'This is a newly added text'
      newElement.style.padding = '10px'
      newElement.style.position = 'relative'
      break
    case 'button':
      newElement = doc.createElement('button')
      newElement.textContent = 'Click Me'
      newElement.style.padding = '8px 16px'
      newElement.style.backgroundColor = '#1890ff'
      newElement.style.color = '#fff'
      newElement.style.border = 'none'
      newElement.style.borderRadius = '4px'
      newElement.style.cursor = 'pointer'
      newElement.style.position = 'relative'
      break
    case 'container':
      newElement = doc.createElement('div')
      newElement.style.padding = '20px'
      newElement.style.backgroundColor = '#f0f0f0'
      newElement.style.border = '1px dashed #999'
      newElement.style.minHeight = '50px'
      newElement.textContent = 'Container Area'
      newElement.style.position = 'relative'
      break
    case 'input':
      newElement = doc.createElement('input')
      newElement.setAttribute('type', 'text')
      newElement.setAttribute('placeholder', 'Please enter content')
      newElement.style.padding = '8px'
      newElement.style.border = '1px solid #d9d9d9'
      newElement.style.borderRadius = '4px'
      newElement.style.position = 'relative'
      break
    case 'image':
      newElement = doc.createElement('div')
      newElement.style.width = '100%'
      newElement.style.height = '200px'
      newElement.style.backgroundColor = '#e6e6e6'
      newElement.style.display = 'flex'
      newElement.style.alignItems = 'center'
      newElement.style.justifyContent = 'center'
      newElement.style.color = '#999'
      newElement.textContent = 'Image Placeholder'
      newElement.style.position = 'relative'
      break
  }
  
  if (newElement) {
    // 如果有选中的元素，且它是容器（div, section, main, etc.），则添加到其内部
    // 否则添加到 body
    const targetContainer = (selectedElement.value && 
      ['DIV', 'SECTION', 'MAIN', 'ARTICLE', 'HEADER', 'FOOTER', 'ASIDE', 'NAV', 'FORM'].includes(selectedElement.value.tagName)) 
      ? selectedElement.value 
      : doc.body
      
    targetContainer.appendChild(newElement)
    
    // 自动选中新添加的元素
    const oldSelected = doc.querySelector('.visual-editor-selected')
    if (oldSelected) {
      oldSelected.classList.remove('visual-editor-selected')
      const oldHandle = oldSelected.querySelector('.visual-editor-drag-handle')
      if (oldHandle) {
        oldHandle.remove()
      }
    }
    
    newElement.classList.add('visual-editor-selected')
    selectedElement.value = newElement
    addDragHandle(newElement, doc)
    syncElementToEditor(newElement)
    
    // 滚动到新元素
    newElement.scrollIntoView({ behavior: 'smooth', block: 'center' })
    
    message.success('Component added successfully, you can drag to move')
  }
}

const saveVisualEdit = async () => {
  if (!editorIframe.value?.contentDocument) return
  
  saving.value = true
  try {
    // 清理注入的类名、样式和拖拽手柄
    const doc = editorIframe.value.contentDocument.cloneNode(true) as Document
    
    // 移除所有编辑器相关的类名和元素
    const hoverEls = doc.querySelectorAll('.visual-editor-hover')
    hoverEls.forEach(el => el.classList.remove('visual-editor-hover'))
    
    const selectedEls = doc.querySelectorAll('.visual-editor-selected')
    selectedEls.forEach(el => el.classList.remove('visual-editor-selected'))
    
    const draggingEls = doc.querySelectorAll('.visual-editor-dragging')
    draggingEls.forEach(el => el.classList.remove('visual-editor-dragging'))
    
    // 移除所有拖拽手柄
    const dragHandles = doc.querySelectorAll('.visual-editor-drag-handle')
    dragHandles.forEach(handle => handle.remove())
    
    // 确保所有有位置信息的元素都保留了位置样式
    const allElements = doc.querySelectorAll('*')
    allElements.forEach((el: Element) => {
      const htmlEl = el as HTMLElement
      if (htmlEl.style.left || htmlEl.style.top || htmlEl.style.position === 'relative' || htmlEl.style.position === 'absolute') {
        // 确保位置信息被保留
        if (htmlEl.style.position === 'static' && (htmlEl.style.left || htmlEl.style.top)) {
          htmlEl.style.position = 'relative'
        }
      }
    })
    
    // 获取 HTML
    const htmlContent = doc.documentElement.outerHTML
    
    const res = await updateAppCode({
      id: appId,
      codeContent: htmlContent
    })
    
    if (res.data.code === 0) {
      message.success('Saved successfully')
      // 刷新编辑器内的 iframe
      const iframe = editorIframe.value
      iframe.src = iframe.src // reload
      
      // 刷新右侧预览区域的 iframe
      if (previewUrl.value) {
        // 通过更新时间戳参数强制刷新预览
        previewUrl.value = previewUrl.value.split('?')[0] + `?t=${Date.now()}`
        previewLoadError.value = false
        console.log('刷新预览URL:', previewUrl.value)
        
        // 也可以直接重新加载预览 iframe
        await nextTick()
        const previewIframe = document.querySelector('.preview-iframe') as HTMLIFrameElement
        if (previewIframe) {
          previewIframe.src = previewIframe.src
          console.log('已刷新预览iframe')
        }
      }
      
      closeVisualEditor()
    } else {
      message.error('Save failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('保存代码失败：', error)
    message.error('Save failed')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  console.log('=== AppChatPage onMounted 开始 ===')
  console.log('初始状态:', {
    appId: appId,
    loginUserId: loginUserStore.loginUser.id,
    loginUser: loginUserStore.loginUser
  })
  
  // 强制刷新登录用户信息，确保是最新的
  console.log('开始获取登录用户信息...')
  await loginUserStore.fetchLoginUser()
  
  console.log('登录用户信息获取完成:', {
    id: loginUserStore.loginUser.id,
    idType: typeof loginUserStore.loginUser.id,
    userName: loginUserStore.loginUser.userName,
    userRole: loginUserStore.loginUser.userRole,
    fullUser: loginUserStore.loginUser
  })
  
  // 确保登录用户信息完全加载
  await nextTick()
  
  // 加载应用信息
  console.log('开始加载应用信息...')
  await loadAppInfo()
  
      console.log('应用信息加载完成:', {
        appId: appInfo.value?.id,
        appUserId: getAppOwnerId(),
        appUserIdType: typeof getAppOwnerId(),
        loginUserId: loginUserStore.loginUser.id,
        loginUserIdType: typeof loginUserStore.loginUser.id,
        isOwner: isOwner.value
      })
  
  // 等待响应式数据更新完成
  await nextTick()
  await new Promise(resolve => setTimeout(resolve, 500))
  
  // 再次检查权限
  const appUserId = getAppOwnerId()
  const loginUserId = loginUserStore.loginUser.id
  
  console.log('权限检查详情:', {
    appUserId,
    loginUserId,
    appUserIdType: typeof appUserId,
    loginUserIdType: typeof loginUserId,
    appUserIdStr: appUserId != null ? String(appUserId) : null,
    loginUserIdStr: loginUserId != null ? String(loginUserId) : null,
    isMatch: appUserId != null && loginUserId != null && String(appUserId) === String(loginUserId),
    isOwnerComputed: isOwner.value
  })
  
  // 如果ID匹配但isOwner还是false，可能是响应式更新问题
  if (appUserId != null && loginUserId != null) {
    const isMatch = String(appUserId) === String(loginUserId)
    if (isMatch && !isOwner.value) {
      console.warn('⚠️ ID匹配但isOwner为false，可能是响应式更新问题')
      console.warn('强制刷新登录用户信息...')
      await loginUserStore.fetchLoginUser()
      await nextTick()
      await new Promise(resolve => setTimeout(resolve, 300))
      console.log('刷新后isOwner:', isOwner.value)
    } else if (!isMatch) {
      console.error('❌ ID不匹配！', {
        appUserId,
        loginUserId,
        appUserIdStr: String(appUserId),
        loginUserIdStr: String(loginUserId)
      })
    }
  } else {
    console.warn('⚠️ 缺少必要的ID信息:', {
      appUserId,
      loginUserId
    })
  }
  
  console.log('=== 最终状态 ===', {
    appUserId: getAppOwnerId(),
    loginUserId: loginUserStore.loginUser.id,
    isOwner: isOwner.value
  })
  
  // 确保 appInfo 加载完成后再加载历史，以便自动生成功能可以访问 initPrompt
  await loadHistory()
  
  console.log('=== onMounted 完成 ===')
})
</script>

<style scoped>
.app-chat-page {
  max-width: 1400px;
  margin: 0 auto;
}

.header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 0;
  border-bottom: 1px solid #f0f0f0;
  margin-bottom: 24px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.app-name {
  margin: 0;
  font-size: 24px;
  color: #1890ff;
}

.code-gen-type-tag {
  margin: 0;
}

.header-right {
  display: flex;
  gap: 12px;
}

.main-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  height: calc(100vh - 200px);
}

.chat-section {
  display: flex;
  flex-direction: column;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  overflow: hidden;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
}

.load-more-container {
  text-align: center;
  padding: 8px 0;
}

.message-item {
  margin-bottom: 16px;
}

.user-message {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

.ai-message {
  display: flex;
  justify-content: flex-start;
  gap: 12px;
}

.message-content {
  max-width: 70%;
  padding: 12px 16px;
  border-radius: 8px;
  word-wrap: break-word;
}

.user-message .message-content {
  background: #1890ff;
  color: #fff;
}

.ai-message .message-content {
  background: #f5f5f5;
  color: #333;
}

.loading-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
}

.input-container {
  border-top: 1px solid #f0f0f0;
  padding: 16px;
}

.input-wrapper {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.input-actions {
  display: flex;
  justify-content: flex-end;
}

.preview-section {
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.preview-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  border-bottom: 1px solid #f0f0f0;
}

.preview-header h3 {
  margin: 0;
}

.preview-actions {
  display: flex;
  gap: 8px;
}

.preview-content {
  flex: 1;
  position: relative;
}

.preview-iframe {
  width: 100%;
  height: 100%;
  border: none;
}

.preview-generating {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  gap: 16px;
  color: #1890ff;
  background-color: #fff;
}

.preview-placeholder {
  width: 100%;
  height: 100%;
  background: #f6f8fb;
  border-radius: 0 0 8px 8px;
  overflow: hidden;
}

.preview-placeholder-iframe {
  width: 100%;
  height: 100%;
  border: none;
}

.preview-iframe-wrapper {
  width: 100%;
  height: 100%;
  position: relative;
}

/* 可视化编辑器样式 */
:deep(.full-modal) .ant-modal {
  max-width: 100%;
  top: 0;
  padding-bottom: 0;
  margin: 0;
}

:deep(.full-modal) .ant-modal-content {
  display: flex;
  flex-direction: column;
  height: calc(100vh);
  padding: 0;
  border-radius: 0;
}

:deep(.full-modal) .ant-modal-body {
  flex: 1;
  padding: 0;
  overflow: hidden;
}

.visual-editor-container {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.editor-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 24px;
  border-bottom: 1px solid #f0f0f0;
  background: #fff;
}

.editor-main {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.editor-preview {
  flex: 1;
  background: #f0f2f5;
  padding: 24px;
  overflow: auto;
}

.editor-iframe {
  width: 100%;
  height: 100%;
  min-height: 600px;
  background: #fff;
  border: none;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.editor-sidebar {
  width: 300px;
  border-left: 1px solid #f0f0f0;
  background: #fff;
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  padding: 16px;
  border-bottom: 1px solid #f0f0f0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.breadcrumb-container {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  font-size: 12px;
  color: #666;
}

.breadcrumb-item {
  cursor: pointer;
  padding: 2px 4px;
  border-radius: 2px;
  transition: all 0.3s;
}

.breadcrumb-item:hover {
  background: #f0f0f0;
  color: #1890ff;
}

.breadcrumb-item.active {
  color: #1890ff;
  font-weight: bold;
  background: #e6f7ff;
}

.separator {
  margin-left: 4px;
  color: #999;
}

.current-tag {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.sidebar-header h3 {
  margin: 0;
  font-size: 16px;
}

.tag-name {
  color: #1890ff;
  font-weight: bold;
  background: #e6f7ff;
  padding: 2px 8px;
  border-radius: 4px;
}

.sidebar-content {
  padding: 16px;
  flex: 1;
  overflow-y: auto;
}

.editor-sidebar-empty {
  display: flex;
  justify-content: center;
  align-items: center;
  color: #999;
  padding: 24px;
  text-align: center;
  height: 100%;
}

.components-list {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  padding: 16px;
}

.component-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 16px;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.component-item:hover {
  border-color: #1890ff;
  box-shadow: 0 2px 8px rgba(24, 144, 255, 0.15);
  color: #1890ff;
}

.component-item .icon {
  font-size: 24px;
  margin-bottom: 8px;
}

/* 图片上传组件样式 */
.image-preview-container {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  border-radius: 4px;
}

.upload-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #999;
  font-size: 14px;
  padding: 20px;
  text-align: center;
}

:deep(.ant-upload-select-picture-card) {
  width: 100%;
  height: 200px;
  margin: 0;
}
</style>

