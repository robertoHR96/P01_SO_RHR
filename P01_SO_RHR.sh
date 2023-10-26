#!/bin/bash

# Variable globales para los colores
R='\033[0;31m'    # Rojo
G='\033[0;32m'    # Verde
GL='\033[1;32m'  # Verde claro
Y='\033[1;33m'    # Amarillo
B='\033[0;34m'    # Azul
CY='\033[0;36m'    # Cyan 
GL='\033[0;37m'    # Gris Claro
GD='\033[1;30m'    # Gris Oscuro
NEGRITA='\033[1m'  # Negritak
NORMAL='\033[0m'   # Normal
NOCOLOR='\033[1;37m' # Sin color 
# Definir colores de fondo
FONDO_GRIS_CLARO='\033[47m'
FONDO_GRIS_OSCURO='\033[100m'
declare -A matrizDatos
# Función para mostrar la barra de progreso
mostrar_barra_progreso() {
local progreso=$1  # La variable 'progreso' almacena la cantidad de progreso completado, que se pasa como el primer argumento a la función.
local total=$2     # La variable 'total' almacena el valor total que se debe alcanzar, que se pasa como el segundo argumento a la función.
local anchura=39   # La variable 'anchura' representa el ancho de la barra de progreso, que se ha fijado en 39 caracteres para la estética.
local completado=$((progreso * anchura / total))  # 'completado' calcula el número de caracteres que se deben mostrar como progreso en la barra.
((completado++))   # Incrementa 'completado' en uno para asegurarse de que se muestre al menos un carácter de progreso.
local porcentaje=$((progreso * 100 / total))  # 'porcentaje' calcula el porcentaje de progreso en función de 'progreso' y 'total'.
((porcentaje++))   # Incrementa 'porcentaje' en uno para asegurarse de que se muestre el 100% cuando se alcanza por completo.


    # Imprimir mensaje de progreso
    echo -ne "📊 Analizando correo $3 de $4"
    echo -ne "${Y}["
    
    for ((i = 0; i < anchura; i++)); do
        if [ $i -lt $completado ]; then
            echo -ne "${GL}#"  # Barra de progreso
        else
            echo -ne "${Y}-"   # Espacio vacío en la barra
        fi
    done

    echo -ne "${Y}] "
    
    if [ $porcentaje -eq 100 ]; then
        echo -ne " ${GL}$porcentaje% \r"  # Porcentaje completado
    else
        echo -ne " ${Y}$porcentaje% \r"   # Porcentaje no completado
    fi

    echo -ne "${NO_COLOR}${RESET}"  # Restaurar color
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
        echo -e "Error: El archivo de resultado ya existe. Por favor, elige un nombre diferente."
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
    done < "$palabras_file"
    # total de palabras en fraude_words
    total_progreso=${#lista_terminos[*]}
    # contador de mails para la matriz
    contadorMails=1
    # Calcular el total de correos para la barra de progreso
    total_correos=$(wc -l < "$emails_file" | tr -d '[:space:]')
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
        matriz[$contadorMails,1]=$id
        lineaEscribir="$id:"
        # spam/nospam del mail lo guardamos en la matriz y lo concatenamos
        HS=$(echo "$correo" | cut -d "|" -f 3)
        if [ -z "$HS" ]; then
            HS=0
        fi
        matriz[$contadorMails,2]=$HS
        lineaEscribir="$lineaEscribir$HS"

        # texto del mail lo formateamos y vamos a buscar sus conincidencias
        data=$(echo "$correo" | cut -d "|" -f 2)
        data=$(echo "$data" | awk '{print tolower($0)}')
        data="${data//[^[:alnum:]]/ }"
        
        # data del mail limpia
        #correo_limpio=$(echo "$data" | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]')
        correo_limpio=${data}
        # posicionador matriz para el mail
        contador=3
        # mostramos un salto de linea para mejorar la "interfaz"
        echo -e "\n"
        # recorremos la lista de frade_word
        for termino in "${lista_terminos[@]}"; do
            # buscamos el numero de coincidencias del termino de frade_word en el teto del mail
            ocurrencias=$(grep -o "$termino" <<< "$data" | wc -l)
            ocurrencias=$(echo "$ocurrencias" | tr -d '[:space:]')
            # mostramos al barra de progreso
            progreso=$((contador - 3))
            mostrar_barra_progreso $progreso $total_progreso $contadorMails $total_correos
            #lo guradamos en la matriz
            matriz[$contadorMails,$contador]=$ocurrencias
            valorMatriz=${matriz[$contadorMails,$contador]}
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
        echo -e "$lineaEscribir" >> "$resultado_file.freq"
        echo -ne "${G}\n-- 💾 Datos del mail: $contadorMails, guardados en el fichero de frequencias: $resultado_file.freq correctamente${NOCOLOR} \n"

        #aumentador el contador de mail para la matriz
        ((contadorMails++))
    done < "$emails_file"
}
            
main(){
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
            # Aquí puedes poner el código para la opción 1
                read -p "Presiona Enter para continuar..."
                ;;
            2)
                echo -e "${Y}Has seleccionado Predicción${NORMAL}"
            # Aquí puedes poner el código para la opción 2
                read -p "Presiona Enter para continuar..."
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
