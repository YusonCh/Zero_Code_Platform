# Zero-Code Application Generation Platform

An AI-powered platform that generates complete frontend applications through natural language conversations.

## Features

- **Three Generation Types**:
  - Single-page HTML (all-in-one file)
  - Multi-file projects (separate HTML, CSS, JS files)
  - Vue.js projects (complete Vue 3 applications with routing)

- **Conversational Interface**: Multi-turn conversations with context awareness
- **Visual Editor**: Drag-and-drop interface for modifying generated pages
- **Code Download**: Export generated projects as ZIP files
- **User Management**: Authentication, authorization, and project management

## Technology Stack

### Frontend
- Vue 3.3.4
- TypeScript
- Ant Design Vue
- Vite 4.4.5
- Vue Router 4.2.4

### Backend
- Spring Boot 3.2.11
- Java 21
- MyBatis
- MySQL
- Redis
- LangChain4j

### AI/ML
- OpenAI GPT Models (via LangChain4j)
- DeepSeek API
- Alibaba Cloud DashScope

## Setup Instructions

### Prerequisites

- Java 21+
- Node.js 18+
- MySQL 8.0+
- Redis 6.0+

### Backend Setup

1. Clone the repository:
```bash
git clone https://github.com/YusonCh/Zero_Code_Platform.git
cd Zero_Code_Platform
```

2. Create MySQL database:
```bash
mysql -u root -p < sql/create_table.sql
```

3. Configure application:
```bash
cp src/main/resources/application.yml.example src/main/resources/application.yml
```

4. Set environment variables or update `application.yml`:
   - Database connection: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`
   - Redis connection: `REDIS_HOST`, `REDIS_PORT`, `REDIS_DATABASE`, `REDIS_PASSWORD`
   - AI API keys: `AI_API_KEY`, `ROUTING_AI_API_KEY`, `DASHSCOPE_API_KEY`, `PEXELS_API_KEY`

5. Build and run:
```bash
mvn clean install
mvn spring-boot:run
```

### Frontend Setup

1. Navigate to frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment (optional):
Create `.env` file:
```
VITE_API_BASE_URL=http://localhost:8123/api
```

4. Run development server:
```bash
npm run dev
```

## Configuration

### Required Environment Variables

**Database:**
- `DB_HOST`: MySQL host (default: localhost)
- `DB_PORT`: MySQL port (default: 3306)
- `DB_NAME`: Database name (default: zero_code_platform)
- `DB_USERNAME`: MySQL username (default: root)
- `DB_PASSWORD`: MySQL password

**Redis:**
- `REDIS_HOST`: Redis host (default: localhost)
- `REDIS_PORT`: Redis port (default: 6379)
- `REDIS_DATABASE`: Redis database number (default: 0)
- `REDIS_PASSWORD`: Redis password (optional)

**AI Services:**
- `AI_API_KEY`: API key for main AI service (DeepSeek)
- `ROUTING_AI_API_KEY`: API key for routing AI service (DashScope)
- `DASHSCOPE_API_KEY`: Alibaba Cloud DashScope API key
- `PEXELS_API_KEY`: Pexels API key (optional, for image search)

### Application Configuration

Copy `src/main/resources/application.yml.example` to `src/main/resources/application.yml` and update with your configuration.

**Note:** Never commit `application.yml` with real credentials. Use environment variables or local configuration files.

## Project Structure

```
zero_code_platform/
├── frontend/              # Vue 3 frontend application
│   ├── src/
│   │   ├── pages/        # Page components
│   │   ├── components/   # Reusable components
│   │   ├── api/          # API client
│   │   └── ...
│   └── package.json
├── src/main/java/com/    # Backend Java source
│   ├── ai/               # AI service layer
│   ├── core/             # Code generation core
│   ├── service/          # Business logic
│   ├── controller/       # REST API endpoints
│   └── ...
├── src/main/resources/
│   ├── application.yml.example  # Configuration template
│   └── prompt/           # LLM system prompts
├── sql/                  # Database scripts
└── docs/                 # Documentation
```

## Usage

1. **Create an Application**: 
   - Go to homepage
   - Enter a description of the website you want to create
   - Select generation type (HTML, Multi-file, or Vue Project)
   - Click "Create App"

2. **Chat with AI**:
   - The system will automatically generate initial code
   - You can chat with AI to modify the application
   - Changes are reflected in real-time preview

3. **Visual Editor**:
   - Click "Visual Editor" button
   - Select elements to edit properties
   - Drag and drop to reposition elements
   - Save changes

4. **Download Code**:
   - Click "Download Code" to get ZIP file
   - Extract and use the generated project

## Development

### Running Tests

```bash
# Backend tests
mvn test

# Frontend tests (if configured)
cd frontend
npm test
```

### Building for Production

```bash
# Backend
mvn clean package

# Frontend
cd frontend
npm run build
```

## Security Notes

- **Never commit sensitive information** (API keys, passwords, etc.)
- Use environment variables for configuration
- Keep `application.yml` in `.gitignore` (use `application.yml.example` as template)
- Generated code in `tmp/code_output/` is excluded from git

## License

[Your License Here]

## Contributing

[Contributing Guidelines]

## Contact

[Your Contact Information]

