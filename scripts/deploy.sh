#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Task Tracker — automated deployment
#  N=13  V2=2  V3=2  V5=4
#  App: Task Tracker | Port: 8000 | DB: PostgreSQL
#  Config: /etc/mywebapp/config.json
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

N=13
APP_USER="mywebapp"
APP_DIR="/opt/mywebapp"
CONFIG_DIR="/etc/mywebapp"
DB_NAME="mywebapp"
DB_USER="mywebapp"
DB_PASS="mywebapp_secret"

echo "=== [1/8] Installing required packages ==="
apt-get update -qq
apt-get install -y -qq nginx postgresql nodejs npm curl > /dev/null

echo "=== [2/8] Creating system users ==="

# Системний користувач для запуску застосунку (без логіну)
if ! id "$APP_USER" &>/dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "$APP_USER"
    echo "  Created system user: $APP_USER"
fi

# student — твій робочий користувач
if ! id "student" &>/dev/null; then
    useradd -m -s /bin/bash student
    echo "student:12345678" | chpasswd
    usermod -aG sudo student
    echo "  Created user: student"
fi

# teacher — для перевірки, зміна пароля при першому вході
if ! id "teacher" &>/dev/null; then
    useradd -m -s /bin/bash teacher
    echo "teacher:12345678" | chpasswd
    usermod -aG sudo teacher
    chage -d 0 teacher
    echo "  Created user: teacher"
fi

# operator — обмежений доступ
if ! id "operator" &>/dev/null; then
    useradd -m -s /bin/bash operator
    echo "operator:12345678" | chpasswd
    chage -d 0 operator
    echo "  Created user: operator"
fi

# Налаштування sudo для operator
cp "$PROJECT_DIR/scripts/operator-sudoers" /etc/sudoers.d/operator
chmod 440 /etc/sudoers.d/operator
visudo -c -f /etc/sudoers.d/operator
echo "  Configured sudo for operator"

echo "=== [3/8] Setting up PostgreSQL database ==="
systemctl enable --now postgresql

# Створити користувача БД якщо не існує
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" \
  | grep -q 1 || sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

# Створити базу даних якщо не існує
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" \
  | grep -q 1 || sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

echo "  Database '$DB_NAME' ready"

echo "=== [4/8] Deploying application files ==="
mkdir -p "$APP_DIR"
cp -r "$PROJECT_DIR/src" "$APP_DIR/"
cp "$PROJECT_DIR/package.json" "$APP_DIR/"
cp "$PROJECT_DIR/package-lock.json" "$APP_DIR/" 2>/dev/null || true

cd "$APP_DIR"
npm install --production --silent 2>/dev/null
cd - > /dev/null

chown -R "$APP_USER":"$APP_USER" "$APP_DIR"

# Конфігурація
mkdir -p "$CONFIG_DIR"
cp "$PROJECT_DIR/config.json" "$CONFIG_DIR/config.json"
chown root:"$APP_USER" "$CONFIG_DIR/config.json"
chmod 640 "$CONFIG_DIR/config.json"
echo "  App deployed to $APP_DIR"

echo "=== [5/8] Installing systemd service ==="
cp "$PROJECT_DIR/scripts/mywebapp.service" /etc/systemd/system/mywebapp.service
cp "$PROJECT_DIR/scripts/mywebapp.socket" /etc/systemd/system/mywebapp.socket
systemctl daemon-reload

echo "=== [6/8] Starting the service ==="
systemctl enable --now mywebapp.service
echo "  mywebapp.service started"

echo "=== [7/8] Configuring Nginx ==="
rm -f /etc/nginx/sites-enabled/default
cp "$PROJECT_DIR/nginx/mywebapp.conf" /etc/nginx/sites-available/mywebapp
ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/mywebapp
nginx -t
systemctl enable --now nginx
systemctl reload nginx
echo "  Nginx configured"

echo "=== [8/8] Finalizing ==="

# Файл з номером N (обов'язково за завданням)
echo "$N" > /home/student/gradebook
chown student:student /home/student/gradebook
echo "  Created /home/student/gradebook with N=$N"

# Блокуємо дефолтного користувача
for default_user in ubuntu vagrant debian cloud-user; do
    if id "$default_user" &>/dev/null; then
        usermod -L "$default_user"
        echo "  Locked default user: $default_user"
    fi
done

echo ""
echo "========================================"
echo "  Deployment complete!"
echo "  Test: curl http://localhost/tasks"
echo "========================================"