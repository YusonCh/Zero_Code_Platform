<template>
  <div class="register-page">
    <div class="register-container">
      <h2 class="title">AI App Generation - User Registration</h2>
      <a-form :model="registerForm" @finish="handleRegister" layout="vertical">
        <a-form-item
          label="User Name"
          name="userName"
        >
          <a-input v-model:value="registerForm.userName" placeholder="Please enter user name (optional)" />
        </a-form-item>
        <a-form-item
          label="Account"
          name="userAccount"
          :rules="[{ required: true, message: 'Please enter account' }]"
        >
          <a-input 
            v-model:value="registerForm.userAccount" 
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
            v-model:value="registerForm.userPassword" 
            placeholder="Please enter password"
            autocomplete="new-password"
            data-lpignore="false"
          />
        </a-form-item>
        <a-form-item
          label="Confirm Password"
          name="checkPassword"
          :rules="[
            { required: true, message: 'Please enter password again' },
            {
              validator: validatePassword,
            },
          ]"
        >
          <a-input-password 
            v-model:value="registerForm.checkPassword" 
            placeholder="Please enter password again"
            autocomplete="new-password"
            data-lpignore="false"
          />
        </a-form-item>
        <a-form-item>
          <a-button type="primary" html-type="submit" :loading="loading" block>
            Register
          </a-button>
        </a-form-item>
        <a-form-item>
          <a-button type="link" @click="$router.push('/user/login')" block>
            Already have an account? Login
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
import { userRegister } from '@/api/userController'

const router = useRouter()

const registerForm = ref({
  userAccount: '',
  userPassword: '',
  checkPassword: '',
  userName: '',
})

const loading = ref(false)

const validatePassword = (_rule: any, value: string) => {
  if (!value) {
    return Promise.reject('Please enter password again')
  }
  if (value !== registerForm.value.userPassword) {
    return Promise.reject('Passwords do not match')
  }
  return Promise.resolve()
}

const handleRegister = async () => {
  loading.value = true
  try {
    const res = await userRegister(registerForm.value)
    if (res.data.code === 0) {
      message.success('Registration successful, please login')
      await router.push('/user/login')
    } else {
      message.error('Registration failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('注册失败：', error)
    message.error('Registration failed, please try again')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.register-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: calc(100vh - 64px - 70px);
}

.register-container {
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

