#!/bin/bash
set -e

# ====================== Настройки ======================
ZIP_DIR=$(realpath "./commits")
EDITOR="nano"                    # ← Измени на vim / code --wait / gedit при необходимости

if [ ! -d "$ZIP_DIR" ]; then
    echo "Ошибка: Папка './commits' не найдена!"
    exit 1
fi

unzip_commit() {
    local rev=$1
    local zip_path="$ZIP_DIR/$rev.zip"
    
    if [ ! -f "$zip_path" ]; then
        echo "Ошибка: Файл $zip_path не найден!"
        exit 1
    fi

    echo "→ Распаковываем $rev.zip"
    rm -rf ./* .[^.]* ..?* 2>/dev/null || true
    unzip -qo "$zip_path" -d .
    git add -A
}

# ====================== Функция разрешения конфликта ======================
resolve_conflict() {
    echo "⚠️  Обнаружен КОНФЛИКТ!"

    # Показываем файлы с конфликтами
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    if [ -n "$CONFLICT_FILES" ]; then
        echo "Конфликтные файлы:"
        echo "$CONFLICT_FILES"
        echo "Открываю редактор..."
        $EDITOR $CONFLICT_FILES
    else
        echo "Git сообщает о конфликте, но conflicted файлов не найдено (возможно modify/delete)."
    fi

    echo ""
    echo "Разреши все конфликты в редакторе."
    echo "После сохранения файлов нажми Enter, чтобы скрипт продолжил..."
    read -r   # ← исправлено: без лишних аргументов

    # Завершаем merge
    git add -A
    if git commit --no-edit 2>/dev/null; then
        echo "✅ Конфликт успешно разрешён и закоммичен"
    else
        echo "⚠️  Не удалось автоматически закоммитить. Возможно, нужно вручную выполнить git commit"
        read -r -p "Нажми Enter после того, как сам сделаешь git commit..."
    fi
}

# ====================== Основная часть ======================
rm -rf OPI_Lab2
mkdir OPI_Lab2
cd OPI_Lab2

git init

echo "=== Построение схемы начато ==="

# r0, r1 — Egor
unzip_commit "commit0"
git commit -m "r0" --author="Egor Shubin <>"

unzip_commit "commit1"
git commit -m "r1" --author="Egor Shubin <>"

git switch -c dev/branch_blue

unzip_commit "commit2"
git commit -m "r2" --author="Vlad Larionov <>"

unzip_commit "commit3"
git commit -m "r3" --author="Vlad Larionov <>"

unzip_commit "commit4"
git commit -m "r4" --author="Egor Shubin <>"

git switch -c dev/branch_red

unzip_commit "commit5"
git commit -m "r5" --author="Egor Shubin <>"

git switch dev/branch_blue
unzip_commit "commit6"
git commit -m "r6" --author="Vlad Larionov <>"

git switch dev/branch_red
unzip_commit "commit7"
git commit -m "r7" --author="Egor Shubin <>"

git switch dev/branch_blue
unzip_commit "commit8"
git commit -m "r8" --author="Vlad Larionov <>"

echo "=== Merge red-branch → blue-branch (r7 → r8) ==="
if ! git merge dev/branch_red --no-ff -m "merge with red-branch"; then
    resolve_conflict
fi

# r9–r13
for i in {9..13}; do
    unzip_commit "commit$i"
    git commit -m "r$i" --author="Vlad Larionov <>"
done

# Финальный merge
git switch main
unzip_commit "commit14"
git commit -m "r14" --author="Egor Shubin <>"

echo "=== Финальный merge blue-branch → main ==="
if ! git merge dev/branch_blue --no-ff -m "merge with blue branch"; then
    resolve_conflict
fi

echo ""
echo "=== Схема успешно построена! ==="
git log --graph --oneline --decorate --all -25