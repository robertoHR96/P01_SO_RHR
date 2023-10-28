cargar_nuevo_freq() {
    while true; do
        read -p "Ingrese el nombre del archivo: " nombre_archivo
        if [ -f "$nombre_archivo" ]; then
            # Verifica si el archivo existe
            if [[ $nombre_archivo == *.freq ]]; then
                # Verifica si el archivo tiene la extensión .freq
                echo -e "El archivo $nombre_archivo existe y tiene la extensión .freq\n"
                cargar_fichero_freq $nombre_archivo
                return 1
            else
                echo -e "${R}El archivo $nombre_archivo existe, pero no tiene la extensión .freq${NORMAL}"
                echo -e "Introduca:\n - 1 para volver a intentar\n - 2 Volver atras\n"
                read opcion
                case $opcion in
                1)
                    clear
                    ;;
                2)
                    return 0
                    ;;
                *)
                    echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
                    echo -e "Introduca:\n 1 para volver a intentar o 2 para ir atras: \n"
                    read -p "Pulse enter para continuar" opcion
                    case $opcion in
                    1)
                        clear
                        ;;
                    2)
                        return 0
                        ;;
                    *)
                        echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
                        read -p "Presiona Enter para continuar..."
                        ;;
                    esac
                    ;;
                esac
            fi
        else
            echo -e "${R}El archivo $nombre_archivo no existe.${NORMAL}\n"
            echo -e "Introduca:\n - 1 para volver a intentar\n - 2 volver atras: \n"
            read -p "Pulse enter para continuar" opcion
            case $opcion in
            1)
                clear
                ;;
            2)
                return 0
                ;;
            *)
                echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
                read -p "Presiona Enter para continuar..."
                ;;
            esac
        fi
    done
}