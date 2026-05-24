# Task Tracker (mywebapp)

Веб-сервіс для відстеження задач. Лабораторна робота №1 — розгортання Web-сервісу з автоматизацією.

## Варіант індивідуального завдання

**N = 13**

| Формула          | Розрахунок       | Результат |
| ---------------- | ---------------- | --------- |
| V2 = (N % 2) + 1 | (13 % 2) + 1 = 2 | **2**     |
| V3 = (N % 3) + 1 | (13 % 3) + 1 = 2 | **2**     |
| V5 = (N % 5) + 1 | (13 % 5) + 1 = 4 | **4**     |

Відповідно до розрахунків:

| Параметр                   | Значення                                         |
| -------------------------- | ------------------------------------------------ |
| Застосунок (V3=2)          | Task Tracker — сервіс для відстеження задач      |
| Спосіб конфігурації (V2=2) | Конфігураційний файл `/etc/mywebapp/config.json` |
| Порт застосунку (V5=4)     | 8000                                             |
| СУБД (V2=2)                | PostgreSQL                                       |

## Опис застосунку

Task Tracker — простий сервіс для відстеження задач. Кожна задача має поля:

- `id` — унікальний ідентифікатор (генерується автоматично)
- `title` — назва задачі
- `status` — статус (`pending` або `done`)
- `created_at` — дата і час створення

Стек технологій: Node.js, Express, PostgreSQL.

## Структура проєкту

```
mywebapp/
├── src/
│   ├── app.js              # Основний веб-застосунок (Express-сервер)
│   └── migrate.js          # Скрипт міграції бази даних
├── scripts/
│   ├── deploy.sh           # Скрипт автоматичного розгортання (точка входу)
│   ├── mywebapp.service    # Systemd unit для запуску сервісу
│   ├── mywebapp.socket     # Systemd socket для socket activation
│   └── operator-sudoers    # Правила sudo для користувача operator
├── nginx/
│   └── mywebapp.conf       # Конфігурація Nginx reverse proxy
├── config.json             # Шаблон конфігурації застосунку
├── package.json            # Залежності Node.js проєкту
├── .gitignore
└── README.md
```

## Архітектура системи

```
client → nginx (0.0.0.0:80) → web app (127.0.0.1:8000) → PostgreSQL (127.0.0.1:5432)
```

- Nginx слухає на порту 80 і проксує запити до застосунку
- Застосунок слухає тільки на localhost:8000 (не доступний ззовні напряму)
- PostgreSQL слухає тільки на localhost:5432 (не доступний ззовні)

## API документація

### Бізнес-логіка

| Метод | Шлях               | Опис                                   | Тіло запиту        |
| ----- | ------------------ | -------------------------------------- | ------------------ |
| GET   | `/`                | Головна сторінка зі списком ендпоінтів | —                  |
| GET   | `/tasks`           | Отримати список усіх задач             | —                  |
| POST  | `/tasks`           | Створити нову задачу                   | `{"title": "..."}` |
| POST  | `/tasks/<id>/done` | Позначити задачу як виконану           | —                  |

### Health-check ендпоінти

| Метод | Шлях            | Опис                                        |
| ----- | --------------- | ------------------------------------------- |
| GET   | `/health/alive` | Завжди повертає HTTP 200 з текстом `OK`     |
| GET   | `/health/ready` | HTTP 200 якщо БД доступна, HTTP 500 якщо ні |

Health-ендпоінти доступні тільки напряму (localhost:8000), через Nginx вони заблоковані (повертають 404).

### Content Negotiation

Бізнес-ендпоінти повертають різний формат залежно від заголовку `Accept`:

- `Accept: application/json` → відповідь у форматі JSON
- `Accept: text/html` (або будь-який інший) → проста HTML-сторінка (без JS, без CSS; списки відображаються у таблицях)

## Конфігурація застосунку

Застосунок читає конфігурацію з JSON-файлу. За замовчуванням шлях: `/etc/mywebapp/config.json`. Можна змінити через змінну середовища `CONFIG_PATH`.

```json
{
  "app": {
    "host": "127.0.0.1",
    "port": 8000
  },
  "db": {
    "host": "127.0.0.1",
    "port": 5432,
    "user": "mywebapp",
    "password": "mywebapp_secret",
    "name": "mywebapp"
  }
}
```

## Розгортання

### Базовий образ віртуальної машини

- **ОС:** Ubuntu 22.04 LTS (Server або Desktop)
- **Образ:** [Ubuntu Server ISO](https://ubuntu.com/download/server) або [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- **Мінімальні ресурси:** 1 CPU, 1 GB RAM, 10 GB диск
- Спеціальних налаштувань розбивки диску не потрібно — підходить стандартна

### Підготовка VM

1. Створити віртуальну машину у VirtualBox (або іншому гіпервізорі)
2. Встановити Ubuntu 22.04, при встановленні обрати "Install OpenSSH server" (для Server) або встановити потім (`sudo apt install openssh-server`)
3. Налаштувати мережу: Bridged Adapter або NAT з прокиданням портів (host 2222 → guest 22 для SSH, host 8080 → guest 80 для HTTP)

### Вхід на VM

Після встановлення ОС увійти через консоль VirtualBox або по SSH:

```bash
ssh <username>@<ip-адреса-VM>
# або через NAT з прокиданням портів:
ssh -p 2222 <username>@127.0.0.1
```

Використовувати credentials, задані при встановленні Ubuntu.

### Запуск автоматичного розгортання

```bash
# Встановити git (якщо ще не встановлений)
sudo apt update && sudo apt install -y git

# Клонувати репозиторій
git clone https://github.com/edw4rdkk/mywebapp.git ~/mywebapp
cd ~/mywebapp

# Запустити скрипт розгортання (від root)
sudo bash scripts/deploy.sh
```

### Що робить скрипт розгортання

1. Встановлює необхідні пакети (Nginx, PostgreSQL, Node.js 20)
2. Створює системних користувачів (student, teacher, operator, mywebapp)
3. Створює базу даних PostgreSQL
4. Копіює файли застосунку до `/opt/mywebapp` та конфігурацію до `/etc/mywebapp/`
5. Встановлює та запускає systemd-сервіс
6. Налаштовує Nginx як reverse proxy
7. Створює файл `/home/student/gradebook` з числом N=13
8. Блокує дефолтного користувача системи

### Після розгортання

Система працює, вхід можливий під одним із створених користувачів:

| Користувач | Пароль   | Права                | Примітка                       |
| ---------- | -------- | -------------------- | ------------------------------ |
| student    | 12345678 | sudo (повний доступ) | Робочий користувач             |
| teacher    | 12345678 | sudo (повний доступ) | Зміна пароля при першому вході |
| operator   | 12345678 | Обмежений sudo       | Зміна пароля при першому вході |

## Користувачі системи

| Користувач | Призначення         | Права                                               |
| ---------- | ------------------- | --------------------------------------------------- |
| student    | Робота з проєктом   | Повні адміністративні права (sudo)                  |
| teacher    | Перевірка роботи    | Повні адміністративні права (sudo)                  |
| operator   | Керування сервісами | Обмежений sudo (тільки керування mywebapp та nginx) |
| mywebapp   | Запуск застосунку   | Системний користувач без можливості логіну          |

### Доступні команди для operator

```bash
sudo systemctl start mywebapp.service
sudo systemctl stop mywebapp.service
sudo systemctl restart mywebapp.service
sudo systemctl status mywebapp.service
sudo systemctl reload nginx.service
```

## Налаштування середовища для розробки

1. Встановити Node.js 20+ та PostgreSQL
2. Створити базу даних:
   ```bash
   sudo -u postgres createuser mywebapp -P
   sudo -u postgres createdb mywebapp -O mywebapp
   ```
3. Встановити залежності:
   ```bash
   npm install
   ```
4. Створити конфігурацію:
   ```bash
   sudo mkdir -p /etc/mywebapp
   sudo cp config.json /etc/mywebapp/config.json
   ```
   Або вказати локальний конфіг:
   ```bash
   export CONFIG_PATH=./config.json
   ```
5. Запустити міграцію:
   ```bash
   npm run migrate
   ```
6. Запустити застосунок:
   ```bash
   npm start
   ```

## Тестування розгорнутої системи

### Перевірка статусу сервісів

```bash
# Статус застосунку
systemctl status mywebapp.service
# Має бути: active (running)

# Статус nginx
systemctl status nginx.service
# Має бути: active (running)
```

### Перевірка health-ендпоінтів

```bash
# Alive (напряму до застосунку)
curl http://localhost:8000/health/alive
# Очікуємо: OK

# Ready (напряму до застосунку)
curl http://localhost:8000/health/ready
# Очікуємо: OK

# Health через nginx має бути заблокований
curl http://localhost/health/alive
# Очікуємо: 404 Not Found
```

### Перевірка бізнес-логіки

```bash
# Головна сторінка (через nginx)
curl http://localhost/
# Очікуємо: HTML зі списком ендпоінтів

# Створити задачу (JSON)
curl -X POST http://localhost/tasks \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title": "Buy groceries"}'
# Очікуємо: {"id":1,"title":"Buy groceries","status":"pending","created_at":"..."}

# Створити ще одну задачу
curl -X POST http://localhost/tasks \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"title": "Do homework"}'

# Отримати список задач (JSON)
curl -H "Accept: application/json" http://localhost/tasks
# Очікуємо: масив з двома задачами

# Отримати список задач (HTML)
curl -H "Accept: text/html" http://localhost/tasks
# Очікуємо: HTML-таблиця з задачами

# Позначити задачу виконаною
curl -X POST http://localhost/tasks/1/done \
  -H "Accept: application/json"
# Очікуємо: {"id":1,...,"status":"done",...}
```

### Перевірка користувачів

```bash
# Перевірити існування користувачів
id student
id teacher
id operator
id mywebapp

# Перевірити gradebook
cat /home/student/gradebook
# Очікуємо: 13

# Перевірити sudo для operator
su - operator
sudo systemctl status mywebapp.service   # має працювати
```

### Перевірка логів

```bash
# Логи застосунку
journalctl -u mywebapp.service --no-pager -n 20

# Логи nginx
tail -20 /var/log/nginx/mywebapp_access.log
tail -20 /var/log/nginx/mywebapp_error.log
```
