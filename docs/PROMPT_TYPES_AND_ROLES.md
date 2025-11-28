# Prompt 类型与 LLM 角色说明

## 概述

本文档详细说明了系统中所有类型的 prompt，以及 LLM 在不同场景下扮演的角色。LLM 在系统中确实扮演了**多个不同的角色**，每个角色都有其特定的职责和任务。

---

## 一、Prompt 类型总览

系统中共有 **7 种不同类型的 prompt**，对应 LLM 的 **7 种不同角色**：

| 序号 | Prompt 文件 | LLM 角色 | 使用状态 | 主要职责 |
|------|------------|---------|---------|---------|
| 1 | `codegen-html-system-prompt.txt` | **Web 前端开发专家** | ✅ 使用中 | 生成 HTML 单文件代码 |
| 2 | `codegen-multi-file-system-prompt.txt` | **Web 前端开发专家** | ✅ 使用中 | 生成多文件代码（HTML/CSS/JS） |
| 3 | `codegen-vue-project-system-prompt.txt` | **Vue3 前端架构师** | ✅ 使用中 | 生成 Vue 项目 |
| 4 | `codegen-routing-system-prompt.txt` | **代码生成方案路由器** | ✅ 使用中 | 智能选择代码生成类型 |
| 5 | `code-quality-check-system-prompt.txt` | **代码质量检查专家** | ⚠️ 未使用 | 检查代码质量问题 |
| 6 | `image-collection-system-prompt.txt` | **图片收集助手** | ⚠️ 未使用 | 收集网站图片资源 |
| 7 | `image-collection-plan-system-prompt.txt` | **图片收集规划师** | ⚠️ 未使用 | 制定图片收集计划 |

---

## 二、正在使用的 Prompt（4 种）

### 1. HTML 单文件生成 Prompt

**文件**：`prompt/codegen-html-system-prompt.txt`

**LLM 角色**：**资深的 Web 前端开发专家**

**角色定位**：
```
你是一位资深的 Web 前端开发专家，精通 HTML、CSS 和原生 JavaScript。
你擅长构建响应式、美观且代码整洁的单页面网站。
```

**主要职责**：
- 根据用户需求生成完整的单页面 HTML 代码
- 确保代码符合技术约束（无外部依赖、响应式设计等）
- 将 CSS 和 JavaScript 内联到 HTML 中
- 处理用户修改请求，精确修改指定元素

**使用场景**：
```java
@SystemMessage(fromResource = "prompt/codegen-html-system-prompt.txt")
HtmlCodeResult generateHtmlCode(String userMessage);

@SystemMessage(fromResource = "prompt/codegen-html-system-prompt.txt")
Flux<String> generateHtmlCodeStream(String userMessage);
```

**技术约束**：
- 只能使用 HTML、CSS 和原生 JavaScript
- 禁止外部依赖（CSS 框架、JS 库、字体库）
- 必须响应式设计
- 所有代码内联在一个 HTML 文件中

---

### 2. 多文件生成 Prompt

**文件**：`prompt/codegen-multi-file-system-prompt.txt`

**LLM 角色**：**资深的 Web 前端开发专家**（代码分离专家）

**角色定位**：
```
你是一位资深的 Web 前端开发专家，你精通编写结构化的 HTML、清晰的 CSS 
和高效的原生 JavaScript，遵循代码分离和模块化的最佳实践。
```

**主要职责**：
- 生成分离的 HTML、CSS、JavaScript 文件
- 确保文件之间的引用关系正确
- 遵循代码分离和模块化最佳实践
- 处理用户修改请求

**使用场景**：
```java
@SystemMessage(fromResource = "prompt/codegen-multi-file-system-prompt.txt")
MultiFileCodeResult generateMultiFileCode(String userMessage);

@SystemMessage(fromResource = "prompt/codegen-multi-file-system-prompt.txt")
Flux<String> generateMultiFileCodeStream(String userMessage);
```

**技术约束**：
- 文件分离：`index.html`、`style.css`、`script.js`
- HTML 中通过 `<link>` 和 `<script>` 引用外部文件
- 禁止外部依赖
- 必须响应式设计

---

### 3. Vue 项目生成 Prompt

**文件**：`prompt/codegen-vue-project-system-prompt.txt`

**LLM 角色**：**资深的 Vue3 前端架构师**

**角色定位**：
```
你是一位资深的 Vue3 前端架构师，精通现代前端工程化开发、组合式 API、
组件化设计和企业级应用架构。
```

**主要职责**：
- 规划完整的 Vue3 项目结构
- 设计组件架构和路由配置
- 使用工具调用创建项目文件
- 确保项目可运行、可构建、可部署
- 处理用户修改请求（通过工具读取和修改文件）

**使用场景**：
```java
@SystemMessage(fromResource = "prompt/codegen-vue-project-system-prompt.txt")
TokenStream generateVueProjectCodeStream(@MemoryId long appId, @UserMessage String userMessage);
```

**技术栈**：
- Vue 3.x（组合式 API）
- Vite
- Vue Router 4.x
- Node.js 18+ 兼容

**特殊能力**：
- **工具调用**：可以调用 `FileWriteTool`、`FileReadTool`、`FileModifyTool` 等工具
- **自主规划**：自主决定需要创建哪些文件
- **项目完整性**：确保所有文件标签正确闭合，项目可以构建成功

**项目结构要求**：
```
项目根目录/
├── index.html
├── package.json
├── vite.config.js
├── src/
│   ├── main.js
│   ├── App.vue
│   ├── router/index.js
│   ├── components/
│   ├── pages/
│   └── styles/
└── public/
```

---

### 4. 代码生成类型路由 Prompt

**文件**：`prompt/codegen-routing-system-prompt.txt`

**LLM 角色**：**专业的代码生成方案路由器**

**角色定位**：
```
你是一个专业的代码生成方案路由器，需要根据用户需求返回最合适的代码生成类型。
```

**主要职责**：
- 分析用户需求
- 智能选择最合适的代码生成类型（HTML、MULTI_FILE、VUE_PROJECT）
- 根据需求复杂度做出判断

**使用场景**：
```java
@SystemMessage(fromResource = "prompt/codegen-routing-system-prompt.txt")
CodeGenTypeEnum routeCodeGenType(String userPrompt);
```

**判断规则**：
- **HTML**：适合简单的静态页面，单个 HTML 文件
- **MULTI_FILE**：适合简单的多文件静态页面，分离 HTML、CSS、JS
- **VUE_PROJECT**：适合复杂的现代化前端项目，涉及多页面、复杂交互、数据管理

**决策逻辑**：
```
- 如果用户需求简单，只需要一个展示页面 → HTML
- 如果用户需要多个页面但不涉及复杂交互 → MULTI_FILE
- 如果用户需求复杂，涉及多页面、复杂交互、数据管理等 → VUE_PROJECT
```

**注意**：当前系统中，用户可以在前端直接选择生成类型，所以这个路由功能可能主要用于初始推荐或备用方案。

---

## 三、未使用的 Prompt（3 种）

### 5. 代码质量检查 Prompt

**文件**：`prompt/code-quality-check-system-prompt.txt`

**LLM 角色**：**专业的代码质量检查专家**

**角色定位**：
```
你是一个专业的代码质量检查专家。你的任务是分析用户提供的网站代码，
检查语法错误等方面的问题，确保项目可以正常运行和打包。
```

**主要职责**（设计用途）：
- 检查语法和结构错误（HTML 标签闭合、CSS 语法、JS 语法等）
- 检查代码质量（结构合理性、命名规范、代码重复性）
- 检查功能完整性（页面功能、交互逻辑、响应式设计）
- 提供修复建议

**输出格式**（JSON）：
```json
{
  "isValid": true/false,
  "errors": ["错误描述1", "错误描述2"],
  "suggestions": ["改进建议1", "改进建议2"]
}
```

**状态**：⚠️ 未在代码中使用，可能是预留功能

---

### 6. 图片收集 Prompt

**文件**：`prompt/image-collection-system-prompt.txt`

**LLM 角色**：**专业的图片收集助手**

**角色定位**：
```
你是一个专业的图片收集助手。根据用户的网站需求，智能选择并调用相应的工具
收集不同类型的图片资源。
```

**主要职责**（设计用途）：
- 分析用户网站需求
- 智能选择图片类型（内容图片、插画、架构图、Logo）
- 调用相应的工具收集图片：
  - `searchContentImages` - 搜索内容相关图片
  - `searchIllustrations` - 搜索插画图片
  - `generateArchitectureDiagram` - 生成架构图
  - `generateLogos` - 生成 Logo

**状态**：⚠️ 未在代码中使用，可能是预留功能

---

### 7. 图片收集规划 Prompt

**文件**：`prompt/image-collection-plan-system-prompt.txt`

**LLM 角色**：**专业的图片收集规划师**

**角色定位**：
```
你是一个专业的图片收集规划师。你的任务是分析用户的网站需求，制定合理的图片收集计划。
```

**主要职责**（设计用途）：
- 分析用户网站需求
- 规划需要收集的图片类型和数量
- 为每种图片类型提供关键词或描述
- 输出结构化的图片收集计划（JSON 格式）

**图片类型**：
- **内容图片** (contentImageTasks)：网站主要内容配图
- **插画图片** (illustrationTasks)：装饰性插画
- **架构图** (diagramTasks)：系统架构、流程图等技术图表
- **Logo 图片** (logoTasks)：品牌标识、图标

**输出格式**（JSON）：
```json
{
  "contentImageTasks": [{"query": "搜索关键词"}],
  "illustrationTasks": [{"query": "插画关键词"}],
  "diagramTasks": [{"mermaidCode": "mermaid代码", "description": "描述"}],
  "logoTasks": [{"description": "Logo设计描述"}]
}
```

**状态**：⚠️ 未在代码中使用，可能是预留功能

---

## 四、LLM 角色总结

### 角色分类

#### 1. **代码生成类角色**（3 个）
- **Web 前端开发专家**（HTML 模式）
- **Web 前端开发专家**（多文件模式）
- **Vue3 前端架构师**（Vue 项目模式）

#### 2. **决策类角色**（1 个）
- **代码生成方案路由器**

#### 3. **质量保证类角色**（1 个）
- **代码质量检查专家**（未使用）

#### 4. **资源收集类角色**（2 个）
- **图片收集助手**（未使用）
- **图片收集规划师**（未使用）

---

## 五、LLM 多角色工作流程

### 场景一：用户首次创建应用

```
用户输入需求
    ↓
【路由器角色】分析需求，推荐生成类型
    ↓
用户选择/确认生成类型
    ↓
【代码生成角色】根据类型生成代码
    ├─ HTML 专家 → 生成单文件
    ├─ 多文件专家 → 生成分离文件
    └─ Vue 架构师 → 生成完整项目
```

### 场景二：用户修改代码

```
用户提出修改需求
    ↓
【代码生成角色】理解修改需求
    ├─ HTML 专家 → 修改 HTML 代码
    ├─ 多文件专家 → 修改对应文件
    └─ Vue 架构师 → 使用工具修改文件
```

### 场景三：代码质量检查（预留功能）

```
代码生成完成
    ↓
【质量检查专家】检查代码质量
    ↓
返回检查结果和建议
    ↓
【代码生成角色】根据建议修复问题
```

---

## 六、角色特点对比

| 角色 | 复杂度 | 工具调用 | 输出格式 | 自主性 |
|------|--------|---------|---------|--------|
| **HTML 专家** | 低 | ❌ | 代码字符串 | 低 |
| **多文件专家** | 中 | ❌ | 代码字符串 | 中 |
| **Vue 架构师** | 高 | ✅ | 工具调用 | 高 |
| **路由器** | 低 | ❌ | 枚举类型 | 中 |
| **质量检查专家** | 中 | ❌ | JSON | 中 |
| **图片收集助手** | 中 | ✅ | JSON | 中 |
| **图片规划师** | 中 | ❌ | JSON | 中 |

---

## 七、关键技术点

### 1. 角色切换机制

LLM 通过不同的 `@SystemMessage` 注解切换角色：

```java
// 角色 1：HTML 专家
@SystemMessage(fromResource = "prompt/codegen-html-system-prompt.txt")
HtmlCodeResult generateHtmlCode(String userMessage);

// 角色 2：Vue 架构师
@SystemMessage(fromResource = "prompt/codegen-vue-project-system-prompt.txt")
TokenStream generateVueProjectCodeStream(@MemoryId long appId, @UserMessage String userMessage);

// 角色 3：路由器
@SystemMessage(fromResource = "prompt/codegen-routing-system-prompt.txt")
CodeGenTypeEnum routeCodeGenType(String userPrompt);
```

### 2. 角色隔离

- 每个角色有独立的系统提示词
- 每个角色有独立的职责和约束
- 不同角色不会相互干扰

### 3. 角色能力差异

- **基础角色**（HTML/多文件专家）：直接生成代码字符串
- **高级角色**（Vue 架构师）：可以使用工具调用，自主规划项目
- **决策角色**（路由器）：分析需求，做出决策
- **辅助角色**（质量检查、图片收集）：提供额外功能支持

---

## 八、未来扩展方向

### 1. 激活未使用的角色
- 代码质量检查：生成后自动检查代码质量
- 图片收集：自动为网站收集合适的图片资源

### 2. 新增角色
- **代码优化专家**：优化生成的代码性能
- **SEO 专家**：优化网站的 SEO 配置
- **无障碍访问专家**：确保网站符合无障碍访问标准
- **多语言支持专家**：生成多语言版本的网站

### 3. 角色协作
- 多个角色协作完成复杂任务
- 角色之间可以相互调用和协作

---

## 九、总结

### LLM 确实扮演了多个角色

系统中 LLM **确实扮演了多个不同的角色**，每个角色都有其特定的：

1. **角色定位**：明确的身份和职责
2. **技术约束**：不同的技术栈和规范
3. **输出格式**：不同的输出要求
4. **能力范围**：不同的工具和权限

### 角色设计原则

1. **职责单一**：每个角色专注于特定任务
2. **约束明确**：每个角色有明确的技术约束
3. **易于切换**：通过注解轻松切换角色
4. **可扩展性**：预留了未使用的角色，便于未来扩展

### 核心价值

通过多角色设计，系统能够：
- **灵活应对**：不同复杂度的需求
- **专业分工**：每个角色发挥专业优势
- **易于维护**：角色独立，便于优化和扩展
- **用户体验**：根据需求自动选择最合适的角色

---

## 附录：Prompt 文件位置

```
src/main/resources/prompt/
├── codegen-html-system-prompt.txt          ✅ 使用中
├── codegen-multi-file-system-prompt.txt    ✅ 使用中
├── codegen-vue-project-system-prompt.txt  ✅ 使用中
├── codegen-routing-system-prompt.txt      ✅ 使用中
├── code-quality-check-system-prompt.txt   ⚠️ 未使用
├── image-collection-system-prompt.txt     ⚠️ 未使用
└── image-collection-plan-system-prompt.txt ⚠️ 未使用
```


