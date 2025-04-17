#!/bin/bash

# Configuración
directorio_backup="/home/mmatush/backup"
carpeta_mega="/Root/homelab/backups"  # Puedes cambiar esto por la carpeta destino que prefieras en MEGA

# Subir cada .zip en el directorio de backup
for archivo in "$directorio_backup"/backup-*.zip; do
    if [ -f "$archivo" ]; then
        echo "📤 Subiendo: $archivo"
        megatools put "$archivo" --path "$carpeta_mega"
        
        if [ $? -eq 0 ]; then
            echo "✅ Subido correctamente: $(basename "$archivo")"
        else
            echo "❌ Error al subir: $(basename "$archivo")"
        fi
    fi
done
