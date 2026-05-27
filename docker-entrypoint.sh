#!/bin/sh
set -e

echo "Running database migration..."
node src/migrate.js

echo "Starting application..."
exec node src/app.js