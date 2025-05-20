#!/usr/bin/env python3
"""
Скрипт для переноса GIF файлов с клиента на сервер

Этот скрипт выполняет следующие действия:
1. Создает директорию на сервере для хранения GIF файлов
2. Копирует все GIF файлы из локальной директории assets/gifs на сервер
3. Создает предварительный просмотр PNG для каждого GIF (если не существует)
"""

import os
import sys
import argparse
import shutil
from pathlib import Path
import subprocess
import concurrent.futures

try:
    from PIL import Image
    import imageio
except ImportError:
    print("Установка необходимых зависимостей...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "imageio"])
    from PIL import Image
    import imageio

def parse_args():
    """Разбор аргументов командной строки"""
    parser = argparse.ArgumentParser(description='Утилита для переноса GIF файлов на сервер')
    parser.add_argument('--source', '-s', type=str, default='assets/gifs',
                        help='Локальная директория с GIF файлами (по умолчанию: assets/gifs)')
    parser.add_argument('--server', type=str, required=True,
                        help='SSH-адрес сервера (например, user@example.com)')
    parser.add_argument('--dest', '-d', type=str, default='/path/to/static/assets/gifs',
                        help='Путь на сервере для сохранения GIF файлов')
    parser.add_argument('--create-preview', action='store_true',
                        help='Создать статический PNG-превью для каждого GIF')
    parser.add_argument('--max-workers', type=int, default=4, 
                        help='Количество параллельных процессов (по умолчанию: 4)')
    return parser.parse_args()

def ensure_server_dir(server, path):
    """Создает директорию на сервере, если она не существует"""
    print(f"Создание директории {path} на сервере {server}...")
    cmd = f"ssh {server} 'mkdir -p {path}'"
    subprocess.check_call(cmd, shell=True)

def create_preview(gif_path, max_size=(400, 400)):
    """Создает PNG превью для GIF файла"""
    try:
        output_path = gif_path.replace('.gif', '.png')
        if os.path.exists(output_path):
            print(f"Превью уже существует: {output_path}")
            return
        
        reader = imageio.get_reader(gif_path)
        # Берем первый кадр
        first_frame = reader.get_data(0)
        img = Image.fromarray(first_frame)
        
        # Изменяем размер, сохраняя пропорции
        img.thumbnail(max_size)
        
        # Сохраняем в PNG
        img.save(output_path, 'PNG')
        print(f"Создан превью: {output_path}")
    except Exception as e:
        print(f"Ошибка создания превью для {gif_path}: {e}")

def copy_file_to_server(server, src_path, dest_path):
    """Копирует файл на сервер через scp"""
    cmd = f"scp {src_path} {server}:{dest_path}"
    try:
        subprocess.check_call(cmd, shell=True)
        print(f"Скопирован файл: {src_path} -> {server}:{dest_path}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Ошибка копирования {src_path}: {e}")
        return False

def process_gif(args, gif_file, source_dir):
    """Обрабатывает один GIF файл: создает превью и копирует на сервер"""
    gif_path = os.path.join(source_dir, gif_file)
    
    # Создаем превью если нужно
    if args.create_preview:
        create_preview(gif_path)
        
        # Также копируем PNG превью на сервер
        png_file = gif_file.replace('.gif', '.png')
        png_path = os.path.join(source_dir, png_file)
        if os.path.exists(png_path):
            dest_png = os.path.join(args.dest, png_file)
            copy_file_to_server(args.server, png_path, dest_png)
    
    # Копируем GIF на сервер
    dest_gif = os.path.join(args.dest, gif_file)
    return copy_file_to_server(args.server, gif_path, dest_gif)

def main():
    """Основная функция скрипта"""
    args = parse_args()
    
    # Проверяем существование исходной директории
    source_dir = os.path.abspath(args.source)
    if not os.path.isdir(source_dir):
        print(f"Ошибка: Директория {source_dir} не существует")
        sys.exit(1)
    
    # Создаем директорию на сервере
    ensure_server_dir(args.server, args.dest)
    
    # Получаем список GIF файлов
    gif_files = [f for f in os.listdir(source_dir) if f.lower().endswith('.gif')]
    if not gif_files:
        print(f"Предупреждение: Директория {source_dir} не содержит GIF файлов")
        sys.exit(0)
    
    print(f"Найдено {len(gif_files)} GIF файлов для обработки")
    
    # Параллельная обработка файлов
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.max_workers) as executor:
        futures = []
        for gif_file in gif_files:
            future = executor.submit(process_gif, args, gif_file, source_dir)
            futures.append(future)
        
        # Ждем завершения всех задач
        results = [future.result() for future in concurrent.futures.as_completed(futures)]
    
    success_count = sum(1 for r in results if r)
    print(f"\nОбработка завершена: успешно скопировано {success_count} из {len(gif_files)} файлов")
    
    # Проверка размера файлов на сервере
    print("\nПроверка размера файлов на сервере...")
    cmd = f"ssh {args.server} 'du -sh {args.dest}'"
    subprocess.check_call(cmd, shell=True)

if __name__ == "__main__":
    main() 