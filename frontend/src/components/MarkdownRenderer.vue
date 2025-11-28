<template>
  <div class="markdown-renderer" v-html="renderedContent"></div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js'
import 'highlight.js/styles/default.css'

const props = defineProps<{
  content: string
}>()

const md = new MarkdownIt({
  highlight: function (str, lang) {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return hljs.highlight(str, { language: lang }).value
      } catch (__) {}
    }
    return ''
  },
})

const renderedContent = computed(() => {
  return md.render(props.content || '')
})
</script>

<style scoped>
.markdown-renderer {
  line-height: 1.6;
}

.markdown-renderer :deep(pre) {
  background: #f5f5f5;
  padding: 16px;
  border-radius: 4px;
  overflow-x: auto;
}

.markdown-renderer :deep(code) {
  background: #f5f5f5;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: 'Courier New', monospace;
}

.markdown-renderer :deep(pre code) {
  background: transparent;
  padding: 0;
}

.markdown-renderer :deep(p) {
  margin: 8px 0;
}

.markdown-renderer :deep(h1),
.markdown-renderer :deep(h2),
.markdown-renderer :deep(h3) {
  margin: 16px 0 8px 0;
  font-weight: bold;
}

.markdown-renderer :deep(ul),
.markdown-renderer :deep(ol) {
  margin: 8px 0;
  padding-left: 24px;
}

.markdown-renderer :deep(blockquote) {
  border-left: 4px solid #ddd;
  padding-left: 16px;
  margin: 8px 0;
  color: #666;
}
</style>

