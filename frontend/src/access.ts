import router from './router'
import { useLoginUserStore } from './stores/loginUser'

router.beforeEach(async (to, from, next) => {
  const loginUserStore = useLoginUserStore()
  const loginUser = loginUserStore.loginUser

  // 自动获取当前登录用户
  if (!loginUser.id) {
    await loginUserStore.fetchLoginUser()
  }

  // 检查是否需要登录
  if (to.path.startsWith('/admin')) {
    const currentUser = loginUserStore.loginUser
    if (!currentUser.id || currentUser.userRole !== 'admin') {
      next('/user/login')
      return
    }
  }

  next()
})

