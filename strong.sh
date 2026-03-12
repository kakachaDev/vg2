#!/bin/bash
# next_todo.sh - Генерирует контекст для ИИ и управляет задачами

echo "=== ПРОЕКТ: $(basename $(pwd)) ==="
echo "СТЕК: Node.js/TypeScript/Vite"
echo ""

echo "=== СТРУКТУРА ПРОЕКТА ==="
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.json" \) | grep -v "node_modules" | grep -v "dist" | head -30

echo ""
echo "=== TODO.md ==="
cat TODO.md 2>/dev/null || echo "TODO.md не найден"

echo ""
echo "=== README.md ==="
cat README.md 2>/dev/null || echo "README.md не найден"

echo ""
echo "=== PROGRESS.md ==="
cat PROGRESS.md 2>/dev/null || echo "PROGRESS.md не найден"

echo ""
echo "=== VISION.md ==="
cat VISION.md 2>/dev/null || echo "VISION.md не найден"

echo ""
echo "=== ПОСЛЕДНИЙ КОММИТ ==="
git log -1 --pretty=format:"%h - %s" 2>/dev/null || echo "git не инициализирован"

echo ""
echo "=== ИНСТРУКЦИЯ ДЛЯ ИИ ==="
cat << 'EOF'
Ты ассистент для разработки. Отвечай ТОЛЬКО shell скриптами.

ПРАВИЛА:
1. Проанализируй структуру проекта и TODO
2. Напиши, какие файлы тебе нужны для выполнения следующей задачи (список)
3. После получения файлов выполни задачу:
   - Пиши код без комментариев
   - Активно используй инструменты редактирования текста (sed, grep, awk)
   - Обнови PROGRESS.md (добавь выполненное)
   - Обнови TODO.md (отметь текущий пункт и перенеси его вниз)
   - Сделай git commit с сообщением о выполненной задаче
4. Выдай ТОЛЬКО shell скрипт с командами

ФОРМАТ ПЕРВОГО ОТВЕТА:
```bash
#!/bin/bash
echo "--- package.json ---"
cat package.json 2>/dev/null || echo "File not found"
echo ""

echo "--- tsconfig.json ---"
cat tsconfig.json 2>/dev/null || echo "File not found"
echo ""
# ... выполнение каких-то действий и запрос файлов
```

ФОРМАТ ОТВЕТА С ЗАДАЧЕЙ:
```bash
#!/bin/bash
# 1. Создание/изменение файлов
cat > src/file.ts << 'EOF'
// код без комментариев
export const fn = () => {}
\EOF

# 2. Обновление PROGRESS.md
cat >> PROGRESS.md << 'EOF'
- [x] Выполненная задача
\EOF

# 3. Обновление TODO.md
# (перенос выполненного пункта вниз)

# 4. Коммит
git add .
git commit -m "feat: выполнена задача Х"

# 5. Run tests. , coverage, pretty
...
```
=================
Сейчас есть подозрение в том, что проект не соответствует вижену, а тесты написаны "лишь бы были" и некоторые из них являются моковыми или написанными с огрехами. НУжно найти все эти огрехи и исправить их.
EOF

