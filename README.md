# Smart Food Calorie Bot

> Telegram-бот для подсчёта КБЖУ по фото еды, тексту и голосу.
> Построен на **n8n** + **Claude AI** + **Supabase**.

## Возможности

- **📸 Фото еды** — отправляете фото, Claude Vision определяет блюдо и считает КБЖУ на реальную порцию
- **✍️ Текст** — описываете что съели текстом, AI рассчитывает КБЖУ и записывает в дневник
- **🎤 Голосовое** — отправляете голосовое сообщение, Whisper транскрибирует, AI обрабатывает
- **💬 Диалог** — задавайте вопросы о питании, бот знает вашу историю за 7 дней
- **📊 /stats** — дневная сводка с калориями, БЖУ, списком приёмов пищи
- **🔒 Приватный режим** — бот отвечает только владельцу

## Архитектура

```
Telegram
  │
  ▼
n8n Webhook
  │
  ├─ Has Message? ──(нет)──▶ [стоп]
  │
  ├─ Check Owner ──(чужой)──▶ "Бот приватный"
  │
  ▼
Message Type (Switch)
  │
  ├─ /start ──▶ Upsert Profile ──▶ Приветствие
  │
  ├─ /stats ──▶ Supabase: профиль + логи за день ──▶ Статистика
  │
  ├─ 📸 Фото ──▶ Telegram File ──▶ Base64 ──▶ Claude Vision ──▶ КБЖУ ──▶ Supabase
  │
  ├─ 🎤 Голос ──▶ Telegram File ──▶ OpenAI Whisper ──▶ Текст ──▼
  │                                                            │
  └─ 💬 Текст ──▶ Профиль + 7 дней логов ──▶ Claude AI ──▶ КБЖУ/Ответ ──▶ Supabase
```

## Технологии

| Компонент | Технология |
|-----------|-----------|
| Автоматизация | [n8n](https://n8n.io) (self-hosted) |
| Анализ фото | [Anthropic Claude API](https://docs.anthropic.com) (Vision) |
| Текстовый AI | [Anthropic Claude API](https://docs.anthropic.com) (Messages) |
| Голос → текст | [OpenAI Whisper API](https://platform.openai.com/docs/guides/speech-to-text) |
| База данных | [Supabase](https://supabase.com) (PostgreSQL) |
| Мессенджер | [Telegram Bot API](https://core.telegram.org/bots/api) |

## Установка

### 1. Supabase
1. Создайте проект на [supabase.com](https://supabase.com)
2. Выполните SQL из `supabase/migrations/001_create_tables.sql`
3. Скопируйте **Service Role Key** (Settings → API)

### 2. Telegram
1. Создайте бота через [@BotFather](https://t.me/BotFather)
2. Получите токен бота
3. Узнайте свой Telegram ID (через [@userinfobot](https://t.me/userinfobot))

### 3. API ключи
- [Anthropic Console](https://console.anthropic.com) — получите API key
- [OpenAI Platform](https://platform.openai.com) — получите API key для Whisper

### 4. n8n
1. Импортируйте `workflow/smart-food-calorie-bot.json` в ваш n8n
2. Создайте credentials:
   - **Telegram API** — токен бота
   - **OpenAI API** — для Whisper
3. Замените плейсхолдеры в workflow (см. таблицу ниже)
4. Настройте Telegram Webhook:
   ```
   https://api.telegram.org/bot<TOKEN>/setWebhook?url=https://your-n8n.com/webhook/your-bot-webhook-path
   ```
5. Активируйте workflow

## Плейсхолдеры

В workflow JSON замените следующие значения:

| Плейсхолдер | Где взять |
|------------|----------|
| `YOUR_SUPABASE_SERVICE_KEY` | Supabase → Settings → API → service_role key |
| `YOUR_PROJECT_REF` | Supabase → Settings → General → Reference ID |
| `YOUR_ANTHROPIC_API_KEY` | [console.anthropic.com](https://console.anthropic.com) |
| `YOUR_TELEGRAM_CREDENTIAL_ID` | ID credential в n8n после создания |
| `YOUR_OPENAI_CREDENTIAL_ID` | ID credential в n8n после создания |
| `000000000` (chat ID) | Ваш Telegram ID (число) |
| `your-bot-webhook-path` | Любой уникальный путь для webhook |
| `YOUR_NAME` | Ваше имя |

## Персонализация

В ноде **Build Context** настройте:
- Рост, вес, возраст
- Норму калорий и белка
- Часовой пояс (по умолчанию Asia/Novosibirsk)
- Примечания (медикаменты, ограничения)

## Структура проекта

```
smart-food-calorie-bot/
├── README.md
├── workflow/
│   └── smart-food-calorie-bot.json   # n8n workflow (32 ноды)
├── supabase/
│   └── migrations/
│       └── 001_create_tables.sql     # Таблицы user_profiles + food_log
└── docs/
    └── architecture.md               # Архитектура + паттерны n8n
```

## Лицензия

MIT
