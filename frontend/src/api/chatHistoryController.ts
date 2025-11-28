import request from '@/request'

export async function listAppChatHistory(params: API.listAppChatHistoryParams) {
  const { appId, ...queryParams } = params
  return request<API.BaseResponsePageChatHistory>(`/chatHistory/app/${appId}`, {
    method: 'GET',
    params: queryParams,
  })
}

export async function listAllChatHistoryByPageForAdmin(body: API.ChatHistoryQueryRequest) {
  return request<API.BaseResponsePageChatHistory>('/chatHistory/admin/list/page/vo', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    data: body,
  })
}

