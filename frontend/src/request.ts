import axios from 'axios'
import { message } from 'ant-design-vue'
import { API_BASE_URL } from '@/config/env'

const myAxios = axios.create({
  baseURL: API_BASE_URL,
  timeout: 60000,
  withCredentials: true,
})

myAxios.interceptors.request.use(
  function (config) {
    // 记录请求日志（开发环境）
    if (import.meta.env.DEV) {
      console.log('API请求:', {
        method: config.method?.toUpperCase(),
        url: config.url,
        baseURL: config.baseURL,
        fullURL: `${config.baseURL}${config.url}`,
        data: config.data,
      })
    }
    return config
  },
  function (error) {
    console.error('请求拦截器错误:', error)
    return Promise.reject(error)
  }
)

myAxios.interceptors.response.use(
  function (response) {
    const { data } = response
    // 记录响应日志（开发环境）
    if (import.meta.env.DEV) {
      console.log('API响应:', {
        url: response.config.url,
        status: response.status,
        code: data.code,
        message: data.message,
        data: data.data,
      })
    }
    
    if (data.code === 40100) {
      if (
        !response.request.responseURL.includes('user/get/login') &&
        !window.location.pathname.includes('/user/login')
      ) {
        message.warning('请先登录')
        window.location.href = `/user/login?redirect=${window.location.href}`
      }
    }
    return response
  },
  function (error) {
    // 记录错误日志
    console.error('API请求错误:', {
      url: error.config?.url,
      method: error.config?.method,
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
      message: error.message,
    })
    return Promise.reject(error)
  }
)

export default myAxios

