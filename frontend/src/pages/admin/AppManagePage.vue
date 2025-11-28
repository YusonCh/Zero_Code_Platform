<template>
  <div class="app-manage-page">
    <a-card title="App Management">
      <a-table
        :columns="columns"
        :data-source="appList"
        :loading="loading"
        :pagination="pagination"
        @change="handleTableChange"
        row-key="id"
      >
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'action'">
            <a-space>
              <a-button type="link" @click="handleEdit(record)">Edit</a-button>
              <a-popconfirm title="Are you sure to delete?" @confirm="handleDelete(record.id)">
                <a-button type="link" danger>Delete</a-button>
              </a-popconfirm>
            </a-space>
          </template>
          <template v-else-if="column.key === 'codeGenType'">
            <a-tag color="blue">{{ formatCodeGenType(record.codeGenType) }}</a-tag>
          </template>
        </template>
      </a-table>

      <a-modal v-model:open="editModalVisible" title="编辑应用" @ok="handleUpdate">
        <a-form :model="editForm" layout="vertical">
          <a-form-item label="App Name" name="appName">
            <a-input v-model:value="editForm.appName" />
          </a-form-item>
          <a-form-item label="Priority" name="priority">
            <a-input-number v-model:value="editForm.priority" :min="0" />
          </a-form-item>
        </a-form>
      </a-modal>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listAppVoByPageByAdmin, updateAppByAdmin, deleteAppByAdmin } from '@/api/appController'

const columns = [
  {
    title: 'ID',
    dataIndex: 'id',
    key: 'id',
    width: 80,
  },
  {
    title: 'App Name',
    dataIndex: 'appName',
    key: 'appName',
  },
  {
    title: 'Code Type',
    key: 'codeGenType',
  },
  {
    title: 'Creator',
    dataIndex: ['user', 'userName'],
    key: 'userName',
  },
  {
    title: 'Create Time',
    dataIndex: 'createTime',
    key: 'createTime',
  },
  {
    title: 'Actions',
    key: 'action',
    width: 150,
  },
]

const appList = ref<API.AppVO[]>([])
const loading = ref(false)
const editModalVisible = ref(false)
const editForm = ref({
  id: '' as string | number,
  appName: '',
  priority: 0,
})

const pagination = reactive({
  current: 1,
  pageSize: 10,
  total: 0,
      showTotal: (total: number) => `Total ${total} items`,
})

const formatCodeGenType = (type: string) => {
  const map: Record<string, string> = {
    HTML: 'HTML',
    html: 'HTML',
    MULTI_FILE: 'Multi-file',
    multi_file: 'Multi-file',
    VUE_PROJECT: 'Vue Project',
    vue_project: 'Vue Project',
    html_sample_commerce: 'E-commerce Template',
    html_sample_enterprise: 'Enterprise Website',
    html_sample_portfolio: 'Portfolio',
  }
  return map[type] || type
}

const loadApps = async () => {
  loading.value = true
  try {
    const res = await listAppVoByPageByAdmin({
      pageNum: pagination.current,
      pageSize: pagination.pageSize,
    })

    if (res.data.code === 0 && res.data.data) {
      appList.value = res.data.data.records || []
      pagination.total = res.data.data.total || 0
    }
  } catch (error) {
    console.error('加载应用列表失败：', error)
    message.error('Failed to load app list')
  } finally {
    loading.value = false
  }
}

const handleTableChange = (pag: any) => {
  pagination.current = pag.current
  pagination.pageSize = pag.pageSize
  loadApps()
}

const handleEdit = (record: API.AppVO) => {
  editForm.value = {
    id: record.id,
    appName: record.appName,
    priority: record.priority || 0,
  }
  editModalVisible.value = true
}

const handleUpdate = async () => {
  try {
    const res = await updateAppByAdmin(editForm.value)
    if (res.data.code === 0) {
      message.success('Update successful')
      editModalVisible.value = false
      await loadApps()
    } else {
      message.error('Update failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('更新失败：', error)
    message.error('Update failed, please try again')
  }
}

const handleDelete = async (id: string | number) => {
  try {
    const res = await deleteAppByAdmin({ id })
    if (res.data.code === 0) {
      message.success('Delete successful')
      await loadApps()
    } else {
      message.error('Delete failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('删除失败：', error)
    message.error('Delete failed, please try again')
  }
}

onMounted(() => {
  loadApps()
})
</script>

<style scoped>
.app-manage-page {
  max-width: 1400px;
  margin: 0 auto;
}
</style>

