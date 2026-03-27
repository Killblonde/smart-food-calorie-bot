# Архитектура Smart Food Calorie Bot

## Общая схема (32 ноды)

```
Telegram Webhook (POST /webhook/your-path)
  │
  ├── Has Message ──(false)──▶ [стоп, игнорируем служебные update]
  │       │
  │      (true)
  │       │
  ├── Check Owner (chat.id == YOUR_ID)
  │       │
  │      (true)                    (false)
  │       │                          │
  │  Typing Action             Not Authorized
  │       │                    ("Бот приватный")
  │       │
  │  Message Type (Switch, 5 выходов)
  │       │
  │       ├── [0] /start
  │       │     └── Upsert Profile → Send Start Message
  │       │
  │       ├── [1] /stats
  │       │     └── Get Profile → Get Today Logs → Format Stats → Send Stats
  │       │
  │       ├── [2] Photo
  │       │     └── Get Image → Fix MIME → To Base64 → Claude Vision
  │       │           → Parse Photo → Has Food? → Save Food → Send Result
  │       │
  │       ├── [3] Voice
  │       │     └── Get Voice File → Whisper Transcribe → Voice to Text ──┐
  │       │                                                                │
  │       └── [4] Text (fallback)                                          │
  │             └── Message Text ──────────────────────────────────────────┘
  │                   │
  │              Get Profile Text → Get Week Logs (7 дней)
  │                   │
  │              Build Context (system prompt + история)
  │                   │
  │              Claude Text API (HTTP → Anthropic)
  │                   │
  │              Parse Text Response → Has Food? → Save Food → Send Result
  │
  └── [конец]
```

## Детали по веткам

### /start
1. **Upsert Profile** — POST в Supabase user_profiles (создаёт или обновляет)
2. **Send Start Message** — приветствие с инструкцией

### /stats
1. **Get Profile Stats** — GET user_profiles по chat_id
2. **Get Today Logs Stats** — GET food_log за сегодня (UTC-фильтр по Novosibirsk timezone)
3. **Format Stats** — Code нода, суммирует КБЖУ, форматирует сообщение
4. **Send Stats** — отправляет в Telegram

### Photo
1. **Get Image** — скачивает файл фото через Telegram API
2. **Fix MIME** — устанавливает mimeType = image/jpeg
3. **To Base64** — конвертирует бинарные данные в base64
4. **Claude Vision** — POST в Anthropic API с image + промпт для анализа КБЖУ
5. **Parse Photo Response** — извлекает текст ответа и JSON из `|||FOOD_LOG|||`
6. **Has Food?** — если JSON найден → сохранить, иначе → просто отправить ответ
7. **Save Food** — POST в Supabase food_log
8. **Send Photo Result** — отправляет КБЖУ пользователю

### Voice
1. **Get Voice File** — скачивает .ogg через Telegram API
2. **Whisper Transcribe** — POST в OpenAI API (form-data, model: whisper-1, language: ru)
3. **Voice to Text** — Set node, сохраняет транскрипцию в message_text
4. Далее → та же текстовая ветка

### Text
1. **Message Text** — Set node, извлекает текст сообщения
2. **Get Profile Text** — GET профиль из Supabase
3. **Get Week Logs** — GET food_log за 7 дней
4. **Build Context** — Code нода: формирует system prompt с профилем + историей по дням
5. **Claude Text API** — POST в Anthropic API (system + user message)
6. **Parse Text Response** — извлекает ответ и JSON еды
7. Далее → сохранение + отправка

---

## Паттерны n8n (уроки из разработки)

### 1. Webhook path нельзя менять
Telegram настроен на конкретный URL. Если изменить path при пересборке workflow — бот перестаёт получать сообщения.

### 2. HTTP Request: `authentication: "none"` + ключи в headers
Credential-based auth (`genericCredentialType`) теряется при пересборке через API. Надёжнее передавать ключи напрямую в headerParameters.

### 3. Switch: `looseTypeValidation: true`
При strict validation, если поле отсутствует (text при фото, photo при тексте), нода падает с TypeError. Всегда использовать loose.

### 4. Supabase массивы → `.all()`, не `.first()`
n8n разбивает массив Supabase `[{row1}, {row2}]` на отдельные items. `.first().json` вернёт только первую запись. Используйте `$('NodeName').all()` для всех записей.

### 5. Telegram Typing Action
Параметр: `operation: "sendChatAction"` (не `action`). Добавить `onError: "continueRegularOutput"`.

### 6. Timestamps в URL: конвертировать в UTC
`$now.setZone('Asia/Novosibirsk').toISO()` генерирует `+07:00` — символ `+` теряется в URL. Используйте `.toUTC().toISO()`.

### 7. Фильтр Has Message
Telegram шлёт edited_message, my_chat_member и т.д. без поля `message`. Нужна нода-фильтр в начале цепочки.

### 8. AI Agent node ненадёжен
Credential-based sub-nodes (Anthropic Chat Model) выдают "Could not get parameter". Используйте прямой HTTP Request к Anthropic API.

### 9. Python-эскейпинг ломает JS
При генерации JS-кода через Python, `\n` внутри обычных строк превращается в реальные newlines → SyntaxError. Используйте конкатенацию строк или скачайте workflow → модифицируйте → загрузите.

### 10. Формат FOOD_LOG
AI возвращает данные для записи в формате:
```
|||FOOD_LOG|||
{"meal_description": "...", "calories": N, "protein": N, "fat": N, "carbs": N}
|||END_LOG|||
```
Parse-ноды извлекают JSON регуляркой и отделяют от текста ответа.
