import request from '@/request'

export async function userLogin(body: API.UserLoginRequest) {
  return request<API.BaseResponseLoginUserVO>('/user/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function userRegister(body: API.UserRegisterRequest) {
  return request<API.BaseResponseLong>('/user/register', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function getLoginUser() {
  return request<API.BaseResponseLoginUserVO>('/user/get/login', {
    method: 'GET',
  })
}

export async function userLogout() {
  return request<API.BaseResponseBoolean>('/user/logout', {
    method: 'POST',
  })
}

export async function listUserVoByPage(body: API.UserQueryRequest) {
  return request<API.BaseResponsePageUserVO>('/user/list/page/vo', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function addUser(body: API.UserAddRequest) {
  return request<API.BaseResponseLong>('/user/add', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function updateUser(body: API.UserUpdateRequest) {
  return request<API.BaseResponseBoolean>('/user/update', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function deleteUser(body: API.DeleteRequest) {
  return request<API.BaseResponseBoolean>('/user/delete', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

