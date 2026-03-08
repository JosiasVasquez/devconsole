${SegmentFile}

${SegmentPre}
    ; Dejar la ruta base fija en la carpeta Data
    StrCpy $1 "$EXEDIR\Data\home"
    
    ; Fijar las rutas de entorno para perfil y redes en Data
    System::Call 'Kernel32::SetEnvironmentVariable(t "HOME", t "$1")'
    System::Call 'Kernel32::SetEnvironmentVariable(t "USERPROFILE", t "$1")'
    System::Call 'Kernel32::SetEnvironmentVariable(t "APPDATA", t "$1\AppData\Roaming")'
    System::Call 'Kernel32::SetEnvironmentVariable(t "LOCALAPPDATA", t "$1\AppData\Local")'

    ; Leer el directorio inicial desde Settings.ini
    ReadINIStr $0 "$EXEDIR\Data\Settings.ini" "General" "working_dir"

    ; Si no hay texto, usar la carpeta Data por defecto
    ${If} $0 == ""
    ${OrIf} $0 == "default"
        StrCpy $0 "$1"
    ${EndIf}

    ; Fijar la carpeta inicial donde abre la consola
    SetOutPath "$0"
!macroend