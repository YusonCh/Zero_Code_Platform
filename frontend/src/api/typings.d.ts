declare namespace API {
  type BaseResponse<T> = {
    code: number
    data: T
    message: string
  }

  type BaseResponseLong = BaseResponse<number>
  type BaseResponseBoolean = BaseResponse<boolean>
  type BaseResponseString = BaseResponse<string>

  type Page<T> = {
    records: T[]
    total: number
    current: number
    size: number
  }

  type BaseResponsePage<T> = BaseResponse<Page<T>>

  type UserVO = {
    id: number
    userName: string
    userAvatar: string
    userProfile: string
    userRole: string
    createTime: string
  }

  type LoginUserVO = {
    id: string | number  // 后端Long类型序列化为字符串，但前端可能解析为number
    userName: string
    userAvatar: string
    userProfile: string
    userRole: string
  }

  type UserLoginRequest = {
    userAccount: string
    userPassword: string
  }

  type UserRegisterRequest = {
    userAccount: string
    userPassword: string
    checkPassword: string
    userName?: string
  }

  type UserAddRequest = {
    userName: string
    userAccount: string
    userRole: string
  }

  type UserUpdateRequest = {
    id: number
    userName?: string
    userRole?: string
  }

  type UserQueryRequest = {
    pageNum?: number
    pageSize?: number
    userName?: string
    userAccount?: string
    userRole?: string
  }

  type BaseResponseLoginUserVO = BaseResponse<LoginUserVO>
  type BaseResponseUserVO = BaseResponse<UserVO>
  type BaseResponsePageUserVO = BaseResponsePage<UserVO>
  type BaseResponseUser = BaseResponse<any>

  type getUserByIdParams = {
    id: number
  }

  type getUserVOByIdParams = {
    id: number
  }

  type AppVO = {
    id: string | number  // 后端Long类型序列化为字符串，但前端可能解析为number
    appName: string
    cover: string
    initPrompt: string
    codeGenType: string
    priority: number
    userId: string | number  // 后端Long类型序列化为字符串，但前端可能解析为number
    createTime: string
    updateTime: string
    user: UserVO
    appStatus: number
  }

  type AppAddRequest = {
    initPrompt: string
  }

  type AppUpdateRequest = {
    id: number | string
    appName: string
  }

  type AppAdminUpdateRequest = {
    id: number | string
    appName?: string
    priority?: number
  }

  type AppQueryRequest = {
    pageNum?: number
    pageSize?: number
    id?: number | string
    appName?: string
    codeGenType?: string
    userId?: number | string
    priority?: number
  }

  type AppCodeUpdateRequest = {
    id: number | string
    codeContent: string
  }

  type BaseResponseAppVO = BaseResponse<AppVO>
  type BaseResponsePageAppVO = BaseResponsePage<AppVO>

  type getAppVOByIdParams = {
    id: number | string
  }

  type chatToGenCodeParams = {
    appId: number | string
    message: string
  }

  type downloadAppCodeParams = {
    appId: number | string
  }

  type getAppVOByIdByAdminParams = {
    id: number | string
  }

  type DeleteRequest = {
    id: number | string
  }

  type ChatHistory = {
    id: number
    message: string
    messageType: string
    appId: number | string
    userId: number | string
    createTime: string
  }

  type ChatHistoryQueryRequest = {
    pageNum?: number
    pageSize?: number
    appId?: number | string
    userId?: number | string
    messageType?: string
  }

  type BaseResponsePageChatHistory = BaseResponsePage<ChatHistory>

  type listAppChatHistoryParams = {
    appId: number | string
    pageSize?: number
    lastCreateTime?: string
  }

  type ServerSentEvent<T> = T[]
}

