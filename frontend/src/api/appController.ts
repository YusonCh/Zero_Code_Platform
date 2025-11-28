import request from '@/request'

export async function addApp(body: API.AppAddRequest) {
  return request<API.BaseResponseLong>('/app/add', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function getAppVoById(params: API.getAppVOByIdParams) {
  return request<API.BaseResponseAppVO>('/app/get/vo', {
    method: 'GET',
    params,
  })
}

export async function getPreviewPath(params: { appId: string | number }) {
  return request<API.BaseResponseString>(`/app/get/preview-path/${params.appId}`, {
    method: 'GET',
  })
}

export async function listMyAppVoByPage(body: API.AppQueryRequest) {
  return request<API.BaseResponsePageAppVO>('/app/my/list/page/vo', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function listGoodAppVoByPage(body: API.AppQueryRequest) {
  return request<API.BaseResponsePageAppVO>('/app/good/list/page/vo', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function updateApp(body: API.AppUpdateRequest) {
  return request<API.BaseResponseBoolean>('/app/update', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function deleteApp(body: API.DeleteRequest) {
  return request<API.BaseResponseBoolean>('/app/delete', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function updateAppCode(body: { id: number | string; codeContent: string }) {
  return request<API.BaseResponseBoolean>('/app/update/code', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function downloadAppCode(params: API.downloadAppCodeParams) {
  const { appId, ...queryParams } = params
  return request<any>(`/app/download/${appId}`, {
    method: 'GET',
    params: queryParams,
    responseType: 'blob',
  })
}

export async function chatToGenCode(params: API.chatToGenCodeParams): Promise<EventSource> {
  const eventSource = new EventSource(
    `/api/app/chat/gen/code?appId=${params.appId}&message=${encodeURIComponent(params.message)}`
  )
  return eventSource
}

export async function listAppVoByPageByAdmin(body: API.AppQueryRequest) {
  return request<API.BaseResponsePageAppVO>('/app/admin/list/page/vo', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function updateAppByAdmin(body: API.AppAdminUpdateRequest) {
  return request<API.BaseResponseBoolean>('/app/admin/update', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

export async function deleteAppByAdmin(body: API.DeleteRequest) {
  return request<API.BaseResponseBoolean>('/app/admin/delete', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

