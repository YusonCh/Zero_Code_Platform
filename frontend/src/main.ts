import { createApp } from 'vue'
import { createPinia } from 'pinia'
import Antd from 'ant-design-vue'
import 'ant-design-vue/dist/reset.css'
import '@/styles/global.css'

import App from './App.vue'
import router from './router'
import '@/access'

// 抑制浏览器扩展产生的控制台错误（开发环境）
if ((import.meta as any).env.DEV) {
  const originalError = console.error
  const originalWarn = console.warn
  
  // 检查是否是扩展错误
  const isExtensionError = (args: any[]): boolean => {
    const errorStr = JSON.stringify(args).toLowerCase()
    return (
      errorStr.includes('content_script') ||
      errorStr.includes('cannot read properties of undefined') ||
      errorStr.includes('reading \'control\'') ||
      errorStr.includes('shouldoffercompletionlistforfield') ||
      errorStr.includes('elementwasfocused') ||
      errorStr.includes('focusineventhandler')
    )
  }
  
  console.error = (...args: any[]) => {
    if (isExtensionError(args)) {
      // 静默处理扩展错误
      return
    }
    originalError.apply(console, args)
  }
  
  console.warn = (...args: any[]) => {
    if (isExtensionError(args)) {
      // 静默处理扩展警告
      return
    }
    originalWarn.apply(console, args)
  }
  
  // 捕获未处理的 Promise 拒绝（扩展错误也可能在这里）
  window.addEventListener('unhandledrejection', (event) => {
    const errorStr = JSON.stringify(event.reason).toLowerCase()
    if (
      errorStr.includes('content_script') ||
      errorStr.includes('cannot read properties of undefined') ||
      errorStr.includes('reading \'control\'')
    ) {
      event.preventDefault() // 阻止错误显示
      return
    }
  })
}

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(Antd)

app.mount('#app')

