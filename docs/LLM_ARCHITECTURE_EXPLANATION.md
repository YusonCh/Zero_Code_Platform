# LLM 调用架构说明

## 你的理解 vs 实际架构

### 你的理解
> "调用 LLM 只写了一个工厂类，子类调用这些工厂类来实现，同时根据角色的不同替换 prompt"

### 实际架构
**不是传统的工厂模式 + 子类继承，而是：接口定义 + 动态代理 + 方法级 Prompt 绑定**

---

## 一、实际架构设计

### 1. 核心组件

```
┌─────────────────────────────────────────────────────────┐
│  AiCodeGeneratorService (接口)                          │
│  - 定义所有 LLM 方法                                     │
│  - 每个方法用 @SystemMessage 注解绑定不同的 prompt      │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │ 通过 AiServices.builder() 创建代理
                       ↓
┌─────────────────────────────────────────────────────────┐
│  AiCodeGeneratorServiceFactory (工厂类)                 │
│  - 使用 LangChain4j 的 AiServices.builder()              │
│  - 动态创建接口的代理实现                                 │
│  - 管理服务实例缓存                                       │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │ 业务层调用
                       ↓
┌─────────────────────────────────────────────────────────┐
│  AiCodeGeneratorFacade (门面类)                         │
│  - 调用工厂获取服务实例                                   │
│  - 根据类型调用不同的方法                                 │
└─────────────────────────────────────────────────────────┘
```

### 2. 关键代码分析

#### 接口定义（AiCodeGeneratorService）

```java
public interface AiCodeGeneratorService {
    
    // 方法1：HTML 生成 - 绑定 HTML prompt
    @SystemMessage(fromResource = "prompt/codegen-html-system-prompt.txt")
    HtmlCodeResult generateHtmlCode(String userMessage);
    
    // 方法2：多文件生成 - 绑定多文件 prompt
    @SystemMessage(fromResource = "prompt/codegen-multi-file-system-prompt.txt")
    MultiFileCodeResult generateMultiFileCode(String userMessage);
    
    // 方法3：Vue 项目生成 - 绑定 Vue prompt
    @SystemMessage(fromResource = "prompt/codegen-vue-project-system-prompt.txt")
    TokenStream generateVueProjectCodeStream(@MemoryId long appId, @UserMessage String userMessage);
}
```

**关键点**：
- ✅ **接口定义方法**，不是子类实现
- ✅ **每个方法绑定不同的 prompt**（通过 `@SystemMessage` 注解）
- ✅ **没有子类**，所有方法都在同一个接口中

#### 工厂类（AiCodeGeneratorServiceFactory）

```java
@Configuration
public class AiCodeGeneratorServiceFactory {
    
    // 获取服务实例（带缓存）
    public AiCodeGeneratorService getAiCodeGeneratorService(long appId, CodeGenTypeEnum codeGenType) {
        String cacheKey = buildCacheKey(appId, codeGenType);
        return serviceCache.get(cacheKey, key -> createAiCodeGeneratorService(appId, codeGenType));
    }
    
    // 创建服务实例
    private AiCodeGeneratorService createAiCodeGeneratorService(long appId, CodeGenTypeEnum codeGenType) {
        // 创建对话记忆
        MessageWindowChatMemory chatMemory = ...;
        
        // 根据类型配置不同的模型和工具
        return switch (codeGenType) {
            case VUE_PROJECT -> {
                // Vue 项目：使用推理模型 + 工具调用
                yield AiServices.builder(AiCodeGeneratorService.class)  // 👈 关键：动态创建代理
                        .chatModel(chatModel)
                        .streamingChatModel(reasoningStreamingChatModel)
                        .tools((Object[]) toolManager.getAllTools())
                        .build();
            }
            case HTML, MULTI_FILE -> {
                // HTML/多文件：使用流式对话模型
                yield AiServices.builder(AiCodeGeneratorService.class)  // 👈 关键：动态创建代理
                        .chatModel(chatModel)
                        .streamingChatModel(openAiStreamingChatModel)
                        .build();
            }
        };
    }
}
```

**关键点**：
- ✅ **使用 `AiServices.builder()` 动态创建代理对象**
- ✅ **不是创建子类，而是创建接口的代理实现**
- ✅ **LangChain4j 会根据方法上的注解自动处理 prompt 加载**

#### 业务层调用（AiCodeGeneratorFacade）

```java
@Service
public class AiCodeGeneratorFacade {
    
    @Resource
    private AiCodeGeneratorServiceFactory aiCodeGeneratorServiceFactory;
    
    public Flux<String> generateAndSaveCodeStream(String userMessage, CodeGenTypeEnum codeGenType, Long appId) {
        // 1. 从工厂获取服务实例
        AiCodeGeneratorService service = aiCodeGeneratorServiceFactory.getAiCodeGeneratorService(appId, codeGenType);
        
        // 2. 根据类型调用不同的方法（每个方法有不同的 prompt）
        return switch (codeGenType) {
            case HTML -> {
                // 调用 generateHtmlCodeStream() → 自动使用 HTML prompt
                Flux<String> stream = service.generateHtmlCodeStream(userMessage);
                yield processCodeStream(stream, CodeGenTypeEnum.HTML, appId);
            }
            case MULTI_FILE -> {
                // 调用 generateMultiFileCodeStream() → 自动使用多文件 prompt
                Flux<String> stream = service.generateMultiFileCodeStream(userMessage);
                yield processCodeStream(stream, CodeGenTypeEnum.MULTI_FILE, appId);
            }
            case VUE_PROJECT -> {
                // 调用 generateVueProjectCodeStream() → 自动使用 Vue prompt
                TokenStream stream = service.generateVueProjectCodeStream(appId, userMessage);
                yield processTokenStream(stream, appId);
            }
        };
    }
}
```

**关键点**：
- ✅ **通过调用不同的方法切换角色**
- ✅ **不是替换 prompt，而是调用绑定了不同 prompt 的方法**

---

## 二、角色切换机制

### 传统理解（错误）
```
工厂类 → 创建子类 → 子类实现方法 → 根据角色替换 prompt
```

### 实际机制（正确）
```
接口定义方法（每个方法绑定不同的 prompt）
    ↓
工厂类使用 AiServices.builder() 创建代理对象
    ↓
业务层调用不同的方法
    ↓
LangChain4j 拦截方法调用，根据 @SystemMessage 注解加载对应的 prompt
    ↓
LLM 使用对应的 prompt 处理请求
```

### 示例流程

```java
// 1. 用户请求生成 HTML
codeGenType = HTML

// 2. 工厂创建服务实例（所有方法都在同一个代理对象中）
AiCodeGeneratorService service = factory.getAiCodeGeneratorService(appId, HTML);

// 3. 调用 HTML 方法
service.generateHtmlCodeStream(userMessage);
    ↓
// 4. LangChain4j 拦截调用
    - 读取方法上的 @SystemMessage 注解
    - 加载 "prompt/codegen-html-system-prompt.txt"
    - 将 prompt 作为系统消息发送给 LLM
    ↓
// 5. LLM 使用 HTML 专家的角色生成代码
```

---

## 三、架构特点

### 1. **接口定义，动态代理实现**

```java
// ❌ 不是这样（传统继承）
class HtmlCodeGenerator implements AiCodeGeneratorService { ... }
class VueCodeGenerator implements AiCodeGeneratorService { ... }

// ✅ 实际是这样（动态代理）
interface AiCodeGeneratorService {
    @SystemMessage(...) HtmlCodeResult generateHtmlCode(...);
    @SystemMessage(...) TokenStream generateVueProjectCodeStream(...);
}

// LangChain4j 动态创建代理实现
AiServices.builder(AiCodeGeneratorService.class).build();
```

### 2. **方法级 Prompt 绑定**

```java
// 每个方法有自己的 prompt，不是运行时替换
@SystemMessage(fromResource = "prompt/codegen-html-system-prompt.txt")
HtmlCodeResult generateHtmlCode(String userMessage);

@SystemMessage(fromResource = "prompt/codegen-vue-project-system-prompt.txt")
TokenStream generateVueProjectCodeStream(@MemoryId long appId, @UserMessage String userMessage);
```

### 3. **工厂类的作用**

工厂类的主要职责：
- ✅ **创建代理对象**：使用 `AiServices.builder()` 创建接口的代理实现
- ✅ **配置模型和工具**：根据类型配置不同的 ChatModel、StreamingChatModel、工具等
- ✅ **管理对话记忆**：为每个应用创建独立的对话记忆
- ✅ **实例缓存**：缓存服务实例，避免重复创建

**不是**：
- ❌ 创建子类
- ❌ 替换 prompt（prompt 是方法级别的，编译时绑定）

---

## 四、LangChain4j 的工作原理

### AiServices.builder() 做了什么？

```java
AiServices.builder(AiCodeGeneratorService.class)
    .chatModel(chatModel)
    .streamingChatModel(streamingChatModel)
    .build();
```

**内部流程**：

1. **扫描接口方法**
   - 读取 `AiCodeGeneratorService` 接口的所有方法
   - 检查每个方法上的注解（`@SystemMessage`、`@UserMessage` 等）

2. **创建动态代理**
   - 使用 Java 动态代理或 CGLIB 创建接口的代理实现
   - 代理对象实现了 `AiCodeGeneratorService` 接口

3. **方法拦截**
   - 当调用方法时，代理拦截调用
   - 读取方法上的 `@SystemMessage` 注解
   - 从资源文件加载 prompt 内容

4. **构建消息**
   - 系统消息：从 `@SystemMessage` 注解加载的 prompt
   - 用户消息：从方法参数中提取（标记了 `@UserMessage` 的参数）
   - 历史消息：从对话记忆中加载

5. **调用 LLM**
   - 将消息发送给 ChatModel
   - 处理响应并返回结果

---

## 五、对比总结

| 维度 | 你的理解 | 实际架构 |
|------|---------|---------|
| **实现方式** | 子类继承接口 | 动态代理实现接口 |
| **Prompt 绑定** | 运行时替换 | 编译时方法级绑定 |
| **角色切换** | 替换 prompt | 调用不同方法 |
| **工厂类作用** | 创建子类实例 | 创建代理对象并配置 |
| **代码组织** | 多个子类文件 | 单个接口文件 |

---

## 六、为什么这样设计？

### 优势

1. **代码简洁**
   - 所有方法在一个接口中，便于管理
   - 不需要为每个角色创建子类

2. **类型安全**
   - Prompt 在编译时绑定，避免运行时错误
   - 方法签名明确，IDE 可以检查

3. **易于扩展**
   - 添加新角色只需在接口中添加新方法
   - 不需要创建新的子类

4. **统一管理**
   - 所有 LLM 调用通过同一个接口
   - 工厂类统一配置和管理

### 与传统设计的对比

**传统设计（如果使用子类）**：
```java
// 需要创建多个子类
class HtmlCodeGenerator implements AiCodeGeneratorService {
    @Override
    public HtmlCodeResult generateHtmlCode(String userMessage) {
        // 手动加载 prompt
        String prompt = loadPrompt("prompt/codegen-html-system-prompt.txt");
        // 手动调用 LLM
        return chatModel.generate(prompt, userMessage);
    }
}

class VueCodeGenerator implements AiCodeGeneratorService {
    @Override
    public TokenStream generateVueProjectCodeStream(long appId, String userMessage) {
        // 手动加载 prompt
        String prompt = loadPrompt("prompt/codegen-vue-project-system-prompt.txt");
        // 手动调用 LLM
        return chatModel.generateStream(prompt, userMessage);
    }
}
```

**实际设计（使用 LangChain4j）**：
```java
// 只需定义接口，LangChain4j 自动处理
interface AiCodeGeneratorService {
    @SystemMessage(fromResource = "prompt/codegen-html-system-prompt.txt")
    HtmlCodeResult generateHtmlCode(String userMessage);
    
    @SystemMessage(fromResource = "prompt/codegen-vue-project-system-prompt.txt")
    TokenStream generateVueProjectCodeStream(@MemoryId long appId, @UserMessage String userMessage);
}

// 工厂类自动创建代理
AiServices.builder(AiCodeGeneratorService.class).build();
```

---

## 七、总结

### 你的理解需要调整的地方

1. **不是子类继承**，而是**动态代理实现接口**
2. **不是运行时替换 prompt**，而是**方法级编译时绑定 prompt**
3. **不是根据角色替换**，而是**根据方法调用自动使用对应的 prompt**

### 正确的理解

1. **接口定义所有方法**，每个方法用 `@SystemMessage` 注解绑定不同的 prompt
2. **工厂类使用 LangChain4j 的 `AiServices.builder()` 创建代理对象**
3. **业务层调用不同的方法**，LangChain4j 自动根据方法上的注解加载对应的 prompt
4. **LLM 根据不同的 prompt 扮演不同的角色**

### 核心机制

```
方法调用 → LangChain4j 拦截 → 读取 @SystemMessage 注解 → 加载对应的 prompt → 调用 LLM
```

这就是为什么你只需要：
- ✅ 定义一个接口（所有方法）
- ✅ 一个工厂类（创建代理）
- ✅ 每个方法绑定不同的 prompt（通过注解）

而不需要：
- ❌ 创建多个子类
- ❌ 手动加载和替换 prompt
- ❌ 为每个角色写不同的实现类


