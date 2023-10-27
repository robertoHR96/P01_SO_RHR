#!/bin/bash

# Variable globales para los colores
R='\033[0;31m'       # Rojo
G='\033[0;32m'       # Verde
GL='\033[1;32m'      # Verde claro
Y='\033[1;33m'       # Amarillo
B='\033[0;34m'       # Azul
CY='\033[0;36m'      # Cyan
GL='\033[0;37m'      # Gris Claro
GD='\033[1;30m'      # Gris Oscuro
NEGRITA='\033[1m'    # Negritak
NORMAL='\033[0m'     # Normal
NOCOLOR='\033[1;37m' # Sin color
# Definir colores de fondo
FONDO_GRIS_CLARO='\033[47m'
FONDO_GRIS_OSCURO='\033[100m'
declare -A matrizDatos
# Función para mostrar la barra de progreso
mostrar_barra_progreso() {
    local progreso=$1                                # La variable 'progreso' almacena la cantidad de progreso completado, que se pasa como el primer argumento a la función.
    local total=$2                                   # La variable 'total' almacena el valor total que se debe alcanzar, que se pasa como el segundo argumento a la función.
    local anchura=39                                 # La variable 'anchura' representa el ancho de la barra de progreso, que se ha fijado en 39 caracteres para la estética.
    local completado=$((progreso * anchura / total)) # 'completado' calcula el número de caracteres que se deben mostrar como progreso en la barra.
    ((completado++))                                 # Incrementa 'completado' en uno para asegurarse de que se muestre al menos un carácter de progreso.
    local porcentaje=$((progreso * 100 / total))     # 'porcentaje' calcula el porcentaje de progreso en función de 'progreso' y 'total'.
    ((porcentaje++))                                 # Incrementa 'porcentaje' en uno para asegurarse de que se muestre el 100% cuando se alcanza por completo.

    # Imprimir mensaje de progreso
    echo -ne "📊 Analizando correo $3 de $4"
    echo -ne "${Y}["

    for ((i = 0; i < anchura; i++)); do
        if [ $i -lt $completado ]; then
            echo -ne "${GL}#" # Barra de progreso
        else
            echo -ne "${Y}-" # Espacio vacío en la barra
        fi
    done

    echo -ne "${Y}] "

    if [ $porcentaje -eq 100 ]; then
        echo -ne " ${GL}$porcentaje% \r" # Porcentaje completado
    else
        echo -ne " ${Y}$porcentaje% \r" # Porcentaje no completado
    fi

    echo -ne "${NO_COLOR}${RESET}" # Restaurar color
}
matriz_vacia() {

    # Itera sobre los elementos de la matriz
    for elemento in "${matriz[@]}"; do
        if [[ -n $elemento ]]; then
            # Si se encuentra un elemento no vacío, la matriz no está vacía
            return 1
        fi
    done

    # Si no se encontraron elementos no vacíos, la matriz está vacía
    return 0
}

analizar_datos() {
    # Se limpia la consola
    clear

    # Pedir al usuario los nombres de los archivos
    read -p "Nombre del archivo de palabras a buscar (Fraud_word.txt): " palabras_file
    read -p "Nombre del archivo de correos electrónicos (Emails.txt): " emails_file
    read -p "Nombre del archivo de resultado del análisis (.freq): " resultado_file

    # Comprobar si los archivos existen
    if [[ ! -f $palabras_file || ! -f $emails_file ]]; then
        echo -e " ${R}Error: Uno o ambos archivos no existen.${NOCOLOR}"
        return
    fi

    # Comprobar si el archivo de resultado ya existe
    if [[ -f $resultado_file ]]; then
        echo -e "${R}Error: El archivo de resultado ya existe. Por favor, elige un nombre diferente.${NOCOLOR}"
        return
    fi

    # Se limpia la consola
    clear

    # Crear un archivo temporal para las palabras limpias
    palabras_limpias="palabras_limpias.txt"

    # Declarar un array para almacenar las líneas procesadas
    lista_terminos=()

    # Leer el archivo línea por línea
    while IFS= read -r linea; do
        # Convertir a minúsculas
        linea=$(echo "$linea" | awk '{print tolower($0)}')

        # Reemplazar caracteres no alfanuméricos con espacios
        linea="${linea//[^[:alnum:]]/ }"

        # Agregar la línea procesada al array
        lista_terminos+=("$linea")
    done <"$palabras_file"
    # total de palabras en fraude_words
    total_progreso=${#lista_terminos[*]}
    # contador de mails para la matriz
    contadorMails=1
    # Calcular el total de correos para la barra de progreso
    total_correos=$(wc -l <"$emails_file" | tr -d '[:space:]')
    while IFS= read -r correo; do
        id=${contadorMails}
        SH=0
        # valor de concatenacion a escribir en el fichero
        lineaEscribir=""
        # id del mail lo guardamos en la matriz y lo concatenamos
        id=$(echo "$correo" | cut -d "|" -f 1)
        if [ -z "$HS" ]; then
            id=${contadorMails}
        fi
        matriz[$contadorMails, 1]=$id
        lineaEscribir="$id:"
        # spam/nospam del mail lo guardamos en la matriz y lo concatenamos
        HS=$(echo "$correo" | cut -d "|" -f 3)
        if [ -z "$HS" ]; then
            HS=0
        fi
        matriz[$contadorMails, 2]=$HS
        lineaEscribir="$lineaEscribir$HS"

        # texto del mail lo formateamos y vamos a buscar sus conincidencias
        data=$(echo "$correo" | cut -d "|" -f 2)
        data=$(echo "$data" | awk '{print tolower($0)}')
        data="${data//[^[:alnum:]]/ }"
        numero_de_palabras=$(echo "$data" | wc -w)
        numero_de_palabras=$(echo "$numero_de_palabras" | tr -d '[:space:]')
        # se añade el numero de palabras dentro del mail para calcular el tfidf
        matriz[$contadorMails, 3]=$numero_de_palabras
        lineaEscribir="$lineaEscribir:$numero_de_palabras"

        # data del mail limpia
        #correo_limpio=$(echo "$data" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]')
        correo_limpio=${data}
        # posicionador matriz para el mail
        contador=4
        # mostramos un salto de linea para mejorar la "interfaz"
        echo -e "\n"
        # recorremos la lista de frade_word
        for termino in "${lista_terminos[@]}"; do
            # buscamos el numero de coincidencias del termino de frade_word en el teto del mail
            ocurrencias=$(grep -o "$termino" <<<"$data" | wc -l)
            ocurrencias=$(echo "$ocurrencias" | tr -d '[:space:]')
            # mostramos al barra de progreso
            progreso=$((contador - 4))
            mostrar_barra_progreso $progreso $total_progreso $contadorMails $total_correos
            #lo guradamos en la matriz
            matriz[$contadorMails, $contador]=$ocurrencias
            valorMatriz=${matriz[$contadorMails, $contador]}
            # guradamos el valor en la linea
            lineaEscribir="${lineaEscribir}:${ocurrencias}"
            #aumentamos el contador de posiciones
            ((contador++))
        done
        # le damos un salto de linea a la linea a escribir en el fichero
        lineaEscribir="$lineaEscribir"
        echo -ne "\n-- 💾 Guardando datos..."

        # guardamos la linea en el fichero
        # Escribir resultados en el archivo de resultado
        echo -e "$lineaEscribir" >>"$resultado_file.freq"
        echo -ne "${G}\n-- 💾 Datos del mail: $contadorMails, guardados en el fichero de frequencias: $resultado_file.freq correctamente${NOCOLOR} \n"

        #aumentador el contador de mail para la matriz
        ((contadorMails++))
    done <"$emails_file"
}
cargar_fichero_freq() {
    echo -e "Cargando fichero $1\n"
    contador_lineas=1
    while IFS= read -r linea; do
        numero_de_columnas=$(echo "$linea" | tr ':' ' ' | wc -w)
        for ((i = 1; i <= $numero_de_columnas; i++)); do
            data=$(echo "$linea" | cut -d ":" -f $i)
            matriz[$contador_lineas,$i]=$data
        done
        ((contador_lineas++))
    done <"$1"
}
cargar_nuevo_freq() {
    while true; do
        read -p "Ingrese el nombre del archivo: " nombre_archivo
        if [ -f "$nombre_archivo" ]; then
            # Verifica si el archivo existe
            if [[ $nombre_archivo == *.freq ]]; then
                # Verifica si el archivo tiene la extensión .freq
                echo -e "El archivo $nombre_archivo existe y tiene la extensión .freq\n"
                cargar_fichero_freq $nombre_archivo
                echo -e "Matriz cargada correctamente\n"
                echo -e "Calculo TF-IDF echo correctamente"
                read oo
                return 0
            else
                echo -e "${R}El archivo $nombre_archivo existe, pero no tiene la extensión .freq${NOCOLOR}"
                echo -e "Introduca 1 para volver a intentar o 2 para ir atras: \n"
                read -p "Pulse enter para continuar" opcion
                case $opcion in
                1)
                    clear
                    ;;
                2)
                    return
                    ;;
                *)
                    echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
                    read -p "Presiona Enter para continuar..."
                    ;;
                esac
            fi
        else
            echo -e "${R}El archivo $nombre_archivo no existe.${NOCOLOR}\n"

            echo -e "Introduca 1 para volver a intentar o 2 para ir atras: \n"
            read -p "Pulse enter para continuar" opcion
            case $opcion in
            1)
                clear
                ;;
            2)
                return
                ;;
            *)
                echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
                read -p "Presiona Enter para continuar..."
                ;;
            esac
        fi
    done
}
prediccion_datos() {
    clear
    if matriz_vacia matriz; then
        while true; do
            echo -e "No hay analisis recin echo\n"
            echo -e "Se va a realizar una predcción con los datos cargados de un fichero externo\n"
            echo -e "Introducca:\n - 1 Para cargar un fichero nuevo\n - 2 Para volver atras\n"
            read opcion1
            case $opcion1 in
            1)
                cargar_nuevo_freq
                echo -e "Pulsa enter para volver al menu"
                read -p cosa
                return 0
                ;;
            2)
                return 0
                ;;
            *)
                echo $opcion1
                echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
                read -p "Presiona Enter para continuar..."
                clear
                ;;
            esac
        done
    else
        while true; do
            clear
            echo -e "Acaba de realizar un analisis\n - 1 Deseas usar los datos de este analisis \n - 2 Cargar un fichero con un nuevo analisis \n - 3 Atras \nSelecione una opcion: "
            read opcion
            case $opcion in
            1)
                echo -e "Se va a realizar una predcción con los datos del analisis recien echo"
                realizar_prediccion
                echo -e "Pulsa enter para volver al menu"
                read -p cosa
                return 0
                ;;
            2)
                echo -e "Se va a realizar una predcción con los datos cargados de un fichero externo"
                cargar_nuevo_freq
                realizar_prediccion
                echo -e "Pulsa enter para volver al menu"
                read -p cosa
                return 0
                ;;
            3)
                return
                ;;
            *)

                echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
                read -p "Presiona Enter para continuar..."
                clear
                ;;
            esac
        done
    fi
}
main() {
    while true; do
        clear
        echo -e "${NEGRITA}${CY}${FONDO_GRIS_OSCURO}======================================"
        echo -e "           Menú Principal             "
        echo -e "======================================"
        echo -e "${NORMAL}${NEGRITA}${Y}1️⃣  Análisis de datos"
        echo -e "2️⃣  Predicción"
        echo -e "3️⃣  Informes de resultados"
        echo -e "4️⃣  Ayuda 🛟"
        echo -e "5️⃣  Salir ❌"
        echo -e "======================================${NOCOLOR}${NORMAL}"
        read -p "Selecciona una opción: " opcion

        case $opcion in
        1)
            echo -e "${Y}Has seleccionado Análisis de datos${NORMAL}"
            analizar_datos
            ;;
        2)
            echo -e "${Y}Has seleccionado Predicción${NORMAL}"
            prediccion_datos
            ;;
        3)
            echo -e "${Y}Has seleccionado Informes de resultados${NORMAL}"
            # Aquí puedes poner el código para la opción 3
            read -p "Presiona Enter para continuar..."
            ;;
        4)
            echo -e "${Y}Has seleccionado Ayuda${NORMAL}"
            # Aquí puedes poner el código para la opción 4
            read -p "Presiona Enter para continuar..."
            ;;
        5)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
            read -p "Presiona Enter para continuar..."
            ;;
        esac
    done
}
main
