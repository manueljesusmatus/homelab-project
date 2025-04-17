#!/bin/bash

# Fecha actual en formato YYYY-MM-DD
fecha=$(date +%F)

# Nombre del archivo ZIP con la fecha
archivo_zip="backup-$fecha.zip"

# Directorios base
directorio_base=/home/mmatush
directorio_origen=$directorio_base/docker
directorio_destino=$directorio_base/backup

# Crear el directorio de destino si no existe
mkdir -p "$directorio_destino"

# Eliminar archivos .zip con más de 7 días en la carpeta de backup
find "$directorio_destino" -name "backup-*.zip" -type f -mtime +7 -exec rm -f {} \;

# Ir al home para evitar guardar la ruta completa en el zip
cd "$directorio_origen" || exit 1

# Crear el archivo ZIP con las carpetas
zip -r "$directorio_destino/$archivo_zip" ./*

# Verificar si se creó correctamente
if [ $? -eq 0 ]; then
    echo "✅ Backup creado exitosamente en: $directorio_destino/$archivo_zip"
else
    echo "❌ Hubo un error al crear el archivo de backup."
fi
