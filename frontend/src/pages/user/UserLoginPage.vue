<template>
  <div class="login-page">
    <div class="login-container">
      <h2 class="title">AI App Generation - User Login</h2>
      <a-form :model="loginForm" @finish="handleLogin" layout="vertical">
        <a-form-item
          label="Account"
          name="userAccount"
          :rules="[{ required: true, message: 'Please enter account' }]"
        >
          <a-input 
            v-model:value="loginForm.userAccount" 
            placeholder="Please enter account"
            autocomplete="username"
            data-lpignore="false"
          />
        </a-form-item>
        <a-form-item
          label="Password"
          name="userPassword"
          :rules="[{ required: true, message: 'Please enter password' }]"
        >
          <a-input-password 
            v-model:value="loginForm.userPassword" 
            placeholder="Please enter password"
            autocomplete="current-password"
            data-lpignore="false"
          />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" html-type="submit" :loading="loading" block>
            Login
          </a-button>
        </a-form-item>
        <a-form-item>
          <a-button type="link" @click="$router.push('/user/register')" block>
            Don't have an account? Register
          </a-button>
        </a-form-item>
      </a-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { userLogin } from '@/api/userController'
import { useLoginUserStore } from '@/stores/loginUser'

const router = useRouter()
const loginUserStore = useLoginUserStore()

const loginForm = ref({
  userAccount: '',
  userPassword: '',
})

const loading = ref(false)

const handleLogin = async () => {
  loading.value = true
  try {
    const res = await userLogin(loginForm.value)
    if (res.data.code === 0 && res.data.data) {
      loginUserStore.setLoginUser(res.data.data)
      message.success('Login successful')
      const redirect = router.currentRoute.value.query.redirect as string
      await router.push(redirect || '/')
    } else {
      message.error('Login failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('登录失败：', error)
    message.error('Login failed, please try again')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: calc(100vh - 64px - 70px);
}

.login-container {
  width: 400px;
  padding: 40px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.title {
  text-align: center;
  margin-bottom: 32px;
  font-size: 24px;
  color: #1890ff;
}
</style>

