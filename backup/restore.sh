#!/bin/bash

# Configuración
carpeta_mega="/Root/homelab/backups"
destino_local="/home/mmatush/restore"

# Crear carpeta temporal para descarga
mkdir -p "$temp_dir"

# Obtener la lista de archivos, filtrar solo los ZIP, y ordenar por fecha descendente
ultimo_zip=$(megatools ls "$carpeta_mega" 2>/dev/null | \
    grep 'backup-.*\.zip' | \
    sort -k 6,7 | \
    tail -n 1 | \
    awk '{print $NF}')

if [ -z "$ultimo_zip" ]; then
    echo "❌ No se encontró ningún archivo backup-*.zip en $carpeta_mega"
    exit 1
fi

# Extraer solo el nombre del archivo
nombre_zip=$(basename "$ultimo_zip")
echo "📥 Último archivo encontrado: $nombre_zip"

# Crear el directorio de destino si no existe
mkdir -p "$destino_local"

# Ir al directorio temporal y descargar
megatools get --path "$destino_local/$nombre_zip" "$ultimo_zip"

# Verificar descarga
if [ $? -ne 0 ]; then
    echo "❌ Error al descargar el archivo desde MEGA"
    exit 1
fi

# Descomprimir
echo "🗂 Descomprimiendo en $destino_local"
sudo unzip -o "$destino_local/$nombre_zip" -d "$destino_local"

# Limpieza
if [ $? -eq 0 ]; then
    echo "✅ Backup restaurado correctamente en $destino_local"
    rm -f "$nombre_zip"
else
    echo "❌ Error al descomprimir el archivo"
    exit 1
fi