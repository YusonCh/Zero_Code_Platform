<template>
  <div class="user-manage-page">
    <a-card title="User Management">
      <a-table
        :columns="columns"
        :data-source="userList"
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
          <template v-else-if="column.key === 'userRole'">
            <a-tag :color="record.userRole === 'admin' ? 'red' : 'blue'">
              {{ record.userRole === 'admin' ? 'Admin' : 'User' }}
            </a-tag>
          </template>
        </template>
      </a-table>

      <a-modal v-model:open="editModalVisible" title="编辑用户" @ok="handleUpdate">
        <a-form :model="editForm" layout="vertical">
          <a-form-item label="User Name" name="userName">
            <a-input v-model:value="editForm.userName" />
          </a-form-item>
          <a-form-item label="Role" name="userRole">
            <a-select v-model:value="editForm.userRole">
              <a-select-option value="user">User</a-select-option>
              <a-select-option value="admin">Admin</a-select-option>
            </a-select>
          </a-form-item>
        </a-form>
      </a-modal>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { listUserVoByPage, updateUser, deleteUser } from '@/api/userController'

const columns = [
  {
    title: 'ID',
    dataIndex: 'id',
    key: 'id',
    width: 80,
  },
  {
    title: 'User Name',
    dataIndex: 'userName',
    key: 'userName',
  },
  {
    title: 'Account',
    dataIndex: 'userAccount',
    key: 'userAccount',
  },
  {
    title: 'Role',
    key: 'userRole',
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

const userList = ref<API.UserVO[]>([])
const loading = ref(false)
const editModalVisible = ref(false)
const editForm = ref({
  id: 0,
  userName: '',
  userRole: '',
})

const pagination = reactive({
  current: 1,
  pageSize: 10,
  total: 0,
      showTotal: (total: number) => `Total ${total} items`,
})

const loadUsers = async () => {
  loading.value = true
  try {
    const res = await listUserVoByPage({
      pageNum: pagination.current,
      pageSize: pagination.pageSize,
    })

    if (res.data.code === 0 && res.data.data) {
      userList.value = res.data.data.records || []
      pagination.total = res.data.data.total || 0
    }
  } catch (error) {
    console.error('加载用户列表失败：', error)
    message.error('Failed to load user list')
  } finally {
    loading.value = false
  }
}

const handleTableChange = (pag: any) => {
  pagination.current = pag.current
  pagination.pageSize = pag.pageSize
  loadUsers()
}

const handleEdit = (record: API.UserVO) => {
  editForm.value = {
    id: record.id,
    userName: record.userName,
    userRole: record.userRole,
  }
  editModalVisible.value = true
}

const handleUpdate = async () => {
  try {
    const res = await updateUser(editForm.value)
    if (res.data.code === 0) {
      message.success('Update successful')
      editModalVisible.value = false
      await loadUsers()
    } else {
      message.error('Update failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('更新失败：', error)
    message.error('Update failed, please try again')
  }
}

const handleDelete = async (id: number) => {
  try {
    const res = await deleteUser({ id })
    if (res.data.code === 0) {
      message.success('Delete successful')
      await loadUsers()
    } else {
      message.error('Delete failed: ' + res.data.message)
    }
  } catch (error) {
    console.error('删除失败：', error)
    message.error('Delete failed, please try again')
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.user-manage-page {
  max-width: 1400px;
  margin: 0 auto;
}
</style>

