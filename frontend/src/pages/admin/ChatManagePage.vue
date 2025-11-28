<template>
  <div class="chat-manage-page">
    <a-card title="Chat Management">
      <a-table
        :columns="columns"
        :data-source="chatList"
        :loading="loading"
        :pagination="pagination"
        @change="handleTableChange"
        row-key="id"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'messageType'">
            <a-tag :color="record.messageType === 'user' ? 'blue' : 'green'">
              {{ record.messageType === 'user' ? 'User' : 'AI' }}
            </a-tag>
          </template>
          <template v-else-if="column.key === 'message'">
            <div class="message-cell">
              {{ record.message?.substring(0, 100) }}{{ record.message?.length > 100 ? '...' : '' }}
            </div>
          </template>
        </template>
      </a-table>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listAllChatHistoryByPageForAdmin } from '@/api/chatHistoryController'

const columns = [
  {
    title: 'ID',
    dataIndex: 'id',
    key: 'id',
    width: 80,
  },
  {
    title: 'App ID',
    dataIndex: 'appId',
    key: 'appId',
    width: 100,
  },
  {
    title: 'User ID',
    dataIndex: 'userId',
    key: 'userId',
    width: 100,
  },
  {
    title: 'Message Type',
    key: 'messageType',
    width: 100,
  },
  {
    title: 'Message',
    key: 'message',
  },
  {
    title: 'Create Time',
    dataIndex: 'createTime',
    key: 'createTime',
  },
]

const chatList = ref<API.ChatHistory[]>([])
const loading = ref(false)

const pagination = reactive({
  current: 1,
  pageSize: 10,
  total: 0,
      showTotal: (total: number) => `Total ${total} items`,
})

const loadChats = async () => {
  loading.value = true
  try {
    const res = await listAllChatHistoryByPageForAdmin({
      pageNum: pagination.current,
      pageSize: pagination.pageSize,
    })

    if (res.data.code === 0 && res.data.data) {
      chatList.value = res.data.data.records || []
      pagination.total = res.data.data.total || 0
    }
  } catch (error) {
    console.error('加载对话列表失败：', error)
    message.error('Failed to load chat list')
  } finally {
    loading.value = false
  }
}

const handleTableChange = (pag: any) => {
  pagination.current = pag.current
  pagination.pageSize = pag.pageSize
  loadChats()
}

onMounted(() => {
  loadChats()
})
</script>

<style scoped>
.chat-manage-page {
  max-width: 1400px;
  margin: 0 auto;
}

.message-cell {
  max-width: 400px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>

