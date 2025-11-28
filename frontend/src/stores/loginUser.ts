import { defineStore } from 'pinia'
import { ref } from 'vue'
import { getLoginUser } from '@/api/userController'

export const useLoginUserStore = defineStore('loginUser', () => {
  const loginUser = ref<API.LoginUserVO>({
    userName: '未登录',
  })

  async function fetchLoginUser() {
    try {
      const res = await getLoginUser()
      if (res.data.code === 0 && res.data.data) {
        loginUser.value = res.data.data
        console.log('登录用户信息已更新:', loginUser.value)
      } else {
        console.warn('获取登录用户信息失败:', res.data)
        // 如果获取失败，清空登录状态
        loginUser.value = {
          userName: '未登录',
        }
      }
    } catch (error) {
      console.error('获取登录用户信息异常:', error)
      // 如果获取失败，清空登录状态
      loginUser.value = {
        userName: '未登录',
      }
    }
  }

  function setLoginUser(newLoginUser: any) {
    loginUser.value = newLoginUser
  }

  return { loginUser, fetchLoginUser, setLoginUser }
})

