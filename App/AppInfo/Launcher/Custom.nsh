${SegmentFile}

${SegmentPre}
    ; Ruta base del home portable
    StrCpy $1 "$EXEDIR\Data\home"

    ; Leer el directorio inicial desde Settings.ini
    ReadINIStr $0 "$EXEDIR\Data\Settings.ini" "General" "working_dir"

    ${If} $0 == ""
    ${OrIf} $0 == "default"
        StrCpy $0 "$1"
    ${EndIf}

    ; Fijar la carpeta inicial donde abre la consola
    SetOutPath "$0"
!macroend
