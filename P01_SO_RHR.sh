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
# varibles globales
declare -A matriz
declare -A matrizPredicciones
matrizFilas=1
matrizColum=1
fichero_freq=""
fichero_tfidf=""
palabras_file=""
emails_file=""
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
mostrar_barra_progreso_carga_fichero() {
	local progreso=$1                                # La variable 'progreso' almacena la cantidad de progreso completado, que se pasa como el primer argumento a la función.
	local total=$2                                   # La variable 'total' almacena el valor total que se debe alcanzar, que se pasa como el segundo argumento a la función.
	local anchura=39                                 # La variable 'anchura' representa el ancho de la barra de progreso, que se ha fijado en 39 caracteres para la estética.
	local completado=$((progreso * anchura / total)) # 'completado' calcula el número de caracteres que se deben mostrar como progreso en la barra.
	((completado++))                                 # Incrementa 'completado' en uno para asegurarse de que se muestre al menos un carácter de progreso.
	local porcentaje=$((progreso * 100 / total))     # 'porcentaje' calcula el porcentaje de progreso en función de 'progreso' y 'total'.

	# Imprimir mensaje de progreso
	echo -ne "Cargando fichero"
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

####################################################################################
#                             Analisisis
####################################################################################

analizar_datos() {
	# Se limpia la consola
	clear

	# Pedir al usuario los nombres de los archivos
	read -p "Nombre del archivo de palabras a buscar (Fraud_word.txt): " palabras_file
	read -p "Nombre del archivo de correos electrónicos (Emails.txt): " emails_file
	read -p "Nombre del archivo de resultado del análisis (.freq): " resultado_file

	# Comprobar si los archivos existen
	if [[ ! -f $palabras_file || ! -f $emails_file ]]; then
		echo -e "${NORMAL}${NEGRITA}${R}Error: Uno o ambos archivos no existen.${NOCOLOR}${NORMAL}"
		return
	fi

	# Comprobar si el archivo de resultado ya existe
	if [[ -f $resultado_file ]]; then
		echo -e "${NORMAL}${NEGRITA}${R}Error: El archivo: $resultado_file ya existe. Por favor, elige un nombre diferente.${NOCOLOR}${NORMAL}"
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
		#HS=$(echo "$correo" | rev | cut -d "|" | rev)
		#HS=$(echo "$correo" | awk -F '|' '{gsub(/[^0-9]+/,"",$NF); print $NF}')
		#HS=$(echo "$correo" | cut -d "|" -f 3)
		HS=$(echo "$correo" | awk -F '|' '{print $(NF-1)}')
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
			# guradamos el valor en la line
			lineaEscribir="${lineaEscribir}:${valorMatriz}"
			#aumentamos el contador de posiciones
			((contador++))
		done
		# le damos un salto de linea a la linea a escribir en el fichero
		lineaEscribir="$lineaEscribir"
		echo -ne "\n-- 💾 Guardando datos..."

		# guardamos la linea en el fichero
		# Escribir resultados en el archivo de resultado
		echo -e "$lineaEscribir" >>"$resultado_file.freq"
		echo -ne "${G}\n-- 💾 Datos del mail: $contadorMails, guardados en el fichero de frequencias: $resultado_file.freq correctamente${NORMAL} \n"

		#aumentador el contador de mail para la matriz
		((contadorMails++))
		# delcarmo el valor del tamaño de la matriz
		matrizFilas=$contadorMails
		# se le resta uno al contador por que en la ultima iteracion se le sumo 1
		((contador--))
		matrizColum=$contador
	done <"$emails_file"
	fichero_freq=$resultado_file
}

####################################################################################
#                              Prediciones
####################################################################################

cargar_fichero_freq() {
	# se guarda el nombre del fichero para crear el .tfidf
	fichero_freq=$1
	echo -e "Cargando fichero $fichero_freq\n"
	contador_lineas=1
	numero_de_lineas=$(wc -l <"$fichero_freq")
	while IFS= read -r linea; do
		numero_de_columnas=$(echo "$linea" | tr ':' ' ' | wc -w)
		# se le suma uno para que funcione
		((numero_de_columnas++))
		for ((i = 1; i < $numero_de_columnas; i++)); do
			data=$(echo "$linea" | cut -d ":" -f $i)
			matriz[$contador_lineas, $i]=$data
			matrizPredicciones[$contador_lineas, $i]=$data
		done
		matrizFilas=$contador_lineas
		((numero_de_columnas--))
		matrizColum=$numero_de_columnas
		((numero_de_columnas++))
		mostrar_barra_progreso_carga_fichero $contador_lineas $numero_de_lineas
		((contador_lineas++))
	done <"$fichero_freq"
}
escribir_en_fichero_tfidf() {
	#numero maximo columnas
	columMax=$((matrizColum + 1))
	#escribimos en el fichero de salida
	for ((i = 1; i <= matrizFilas; i++)); do
		lineaEscribir2=""
		for ((j = 1; j <= $columMax; j++)); do
			valor2=${matrizPredicciones[$i, $j]}
			if [ -z "$lineaEscribir2" ]; then
				lineaEscribir2="$valor2"
			else
				lineaEscribir2="$lineaEscribir2:$valor2"
			fi
		done
		fichero_tfidf="${fichero_freq%.freq}"
		echo -e "$lineaEscribir2" >>"$fichero_tfidf.tfidf"
	done
}
realizar_prediccion() {
	#clear
	echo -e "\nRealizando calculo TF-IDF\n"
	# lista con los idfs
	array_idf=()
	# se calculan los idfs
	#numero maximo columnas
	columMax=$((matrizColum + 1))
	columMin=$((matrizColum - 1))

	# numero de columnas que son terminos
	numeroComTerminos=$((matrizColum - 3))
	# se recorren todos los terminos de la matriz
	for ((i = 1; i <= numeroComTerminos; i++)); do
		contadorTerminos=0
		# se recorren por filas
		for ((j = 1; j <= matrizFilas; j++)); do
			valor=${matriz[$i, $j]}
			valor=$((valor))
			# si el valor es distito de cero se le suma uno
			if [ $valor -ne 0 ]; then
				((contadorTerminos++))
			fi
		done

		# se calcula el idf del termino
		if [ $contadorTerminos -ne 0 ]; then
			resultado=$((matrizFilas / contadorTerminos))
			resultado=$(awk "BEGIN { print log($resultado) / log(10) }")
			array_idf[$i]=$resultado
		else
			array_idf[$i]=0
		fi
	done

	# se recorren todas las filas
	for ((i = 1; i <= matrizFilas; i++)); do
		# media tf-idf
		mediaTFIDF=0
		# numero de palabras en el correo
		numPalabras=${matriz[$i, 3]}
		# contador temrinos ya que la lista son 3 menos devido al id hs y numpalabras
		contTerm=1
		# y luego todas los terminos de esta
		for ((j = 4; j <= columMin; j++)); do
			valor=${matriz[$i, $j]}
			valor=$((valor))
			if [ $valor -ne 0 ]; then
				valor=$((valor))
				valorAux=$(awk -v a="$valor" -v b="$numPalabras" 'BEGIN { print a / b }')
				idfTermino=${array_idf[$contTerm]}
				resultado=$(awk -v a="$valorAux" -v b="$idfTermino" 'BEGIN { print a * b }')
				mediaTFIDF=$(awk -v a="$mediaTFIDF" -v b="$resultado" 'BEGIN { print a + b }')
			fi
			((contTerm++))
		done
		# se resta uno para el calculo, da igual luego se pone a 1 otra vez
		((contTerm--))
		# ahora se hace la media para ver si es sapm o no
		mediaTFI=$(awk -v a="$mediaTFIDF" -v b="$contTerm" 'BEGIN { print a / b }')
		# calcula para ver si es spam o no
		if (($(awk 'BEGIN {print ("'$mediaTFI'" > 0.3)}'))); then
			# Si es mayor que 0.3, asignas 1 a matrizPredicciones
			matrizPredicciones[$i, $columMax]=1
		else
			# Si no es mayor que 0.3, asignas 0 a matrizPredicciones
			matrizPredicciones[$i, $columMax]=0
		fi
	done

	# se escriben los datos de la prediccion ->
	escribir_en_fichero_tfidf
}
cargar_nuevo_freq() {
	while true; do
		read -p "Ingrese el nombre del archivo: " nombre_archivo

		if [ -f "$nombre_archivo" ]; then
			if [[ $nombre_archivo == *.freq ]]; then
				echo -e "El archivo $nombre_archivo existe y tiene la extensión .freq\n"
				cargar_fichero_freq $nombre_archivo
				## se elimina la extension para no dar errores en su busqueda luego
				fichero_freq="${fichero_freq%.freq}"
				return 1
			else
				echo -e "${NORMAL}${NEGRITA}${R}El archivo $nombre_archivo existe, pero no tiene la extensión .freq${NOCOLOR}${NORMAL}"
				return 0
			fi
		else
			echo -e "${NORMAL}${NEGRITA}${R}El archivo $nombre_archivo no existe.${NOCOLOR}${NORMAL}\n"
			return 0
		fi
	done
}

prediccion_datos() {
	clear
	if matriz_vacia matriz; then
		while true; do
			clear
			echo -e "${NORMAL}${NEGRITA}${Y}No hay analisis recin echo\n"
			echo -e "Se va a realizar una predcción con los datos cargados de un fichero externo\n"
			echo -e "Introducca:\n1️⃣  Para cargar un fichero nuevo\n2️⃣  Para volver atras\n${NOCOLOR}${NORMAL}"
			read -p "Seleccione una opción: " opcion1
			case $opcion1 in
			1)
				echo -e "Se va a realizar una predcción con los datos cargados de un fichero externo"
				if cargar_nuevo_freq; then
					echo -e "Pulsa enter para volver al menu"
					read -p ""
				else
					echo -e "${NORMAL}${NEGRITA}${G}Carga exitosa. Ejecutando ${NOCOLOR}${NORMAL}"
					echo -e "Pulsa enter para realizar la predicción"
					read -p ""
					realizar_prediccion
					echo -e "${NORMAL}${NEGRITA}${G}Prediccion exitosa. Ejecutando ${NOCOLOR}${NORMAL}"
					echo -e "Pulsa enter para continuar"
					read -p ""
					return 0
				fi
				;;
			2)
				return 0
				;;
			*)
				echo $opcion1
				echo -e "${NORMAL}${NEGRITA}${R}Opción no válida. Por favor, selecciona una opción válida.${NOCOLOR}${NORMAL}"
				read -p "Presiona Enter para continuar..."
				clear
				;;
			esac
		done
	else
		while true; do
			clear
			echo -e "${NORMAL}${NEGRITA}${Y}Acaba de realizar un analisis\n1️⃣  Deseas usar los datos de este analisis \n2️⃣  Cargar un fichero con un nuevo analisis \n3️⃣  Atras ${NOCOLOR}${NORMAL} \nSelecione una opción: "
			read opcion
			case $opcion in
			1)
				echo -e "Se va a realizar una predcción con los datos del analisis recien echo"
				cargar_fichero_freq "$fichero_freq.freq"
				## se elimina la extension para no dar errores en su busqueda luego
				fichero_freq="${fichero_freq%.freq}"
				echo -e "\n${NORMAL}${NEGRITA}${G}Carga exitosa. Ejecutando ${NOCOLOR}${NORMAL}"
				echo -e "Pulsa enter para realizar la predicción"
				read -p ""
				realizar_prediccion
				echo -e "\n${NORMAL}${NEGRITA}${G}Prediccion exitosa. Ejecutando ${NOCOLOR}${NORMAL}"
				echo -e "Pulsa enter para volver al menu"
				read -p ""
				return 0
				;;
			2)
				echo -e "Se va a realizar una predcción con los datos cargados de un fichero externo"
				if cargar_nuevo_freq; then
					echo -e "Pulsa enter para volver al menu"
					read -p ""
				else
					echo -e "${NORMAL}${NEGRITA}${G}Carga exitosa. Ejecutando ${NOCOLOR}${NORMAL}"
					echo -e "Pulsa enter para realizar la predicción"
					read -p ""
					realizar_prediccion
					echo -e "${NORMAL}${NEGRITA}${G}Prediccion exitosa. Ejecutando ${NOCOLOR}${NORMAL}"
					echo -e "Pulsa enter para continuar"
					read -p ""
					return 0
				fi
				;;
			3)
				return
				;;
			*)

				echo -e "${NORMAL}${NEGRITA}${R}Opción no válida. Por favor, selecciona una opción válida.${NOCOLOR}${NORMAL}"
				read -p "Presiona Enter para continuar..."
				clear
				;;
			esac
		done
	fi
}

####################################################################################
#                               Informes
####################################################################################

cargar_fichero_tfidf() {
	# se guarda el nombre del fichero para crear el .tfidf
	fichero_tfidf=$1
	echo -e "Cargando fichero $fichero_tfidf\n"
	contador_lineas=1
	numero_de_lineas=$(wc -l <"$fichero_tfidf")
	while IFS= read -r linea; do
		numero_de_columnas=$(echo "$linea" | tr ':' ' ' | wc -w)
		# se le suma uno para que funcione
		((numero_de_columnas++))
		for ((i = 1; i < $numero_de_columnas; i++)); do
			data=$(echo "$linea" | cut -d ":" -f $i)
			matrizPredicciones[$contador_lineas, $i]=$data
		done
		matrizFilas=$contador_lineas
		((numero_de_columnas--))
		matrizColum=$numero_de_columnas
		((numero_de_columnas++))
		mostrar_barra_progreso_carga_fichero $contador_lineas $numero_de_lineas
		((contador_lineas++))
	done <"$fichero_tfidf"

	echo -e "\n${NORMAL}${NEGRITA}${G}Carga del fichero $fichero_tfidf exitosa.${NOCOLOR}${NORMAL}"
	read -p "Pulse enter para continuar" op

}
cargar_nuevo_tfidf() {
	while true; do
		read -p "Ingrese el nombre del archivo: " nombre_archivo

		if [ -f "$nombre_archivo" ]; then
			if [[ $nombre_archivo == *.tfidf ]]; then
				echo -e "El archivo $nombre_archivo existe y tiene la extensión .tfidf\n"
				cargar_fichero_tfidf $nombre_archivo
				## se elimina la extension para no dar errores en su busqueda luego
				fichero_tfidf="${fichero_tfidf%.tfidf}"
				return 1
			else
				echo -e "${NORMAL}${NEGRITA}${R}El archivo $nombre_archivo existe, pero no tiene la extensión .tfidf${NOCOLOR}${NORMAL}"
				return 0
			fi
		else
			echo -e "${NORMAL}${NEGRITA}${R}El archivo $nombre_archivo no existe.${NOCOLOR}${NORMAL}\n"
			return 0
		fi
	done
}
ejecutar_busqueda_informes_b() {
	palabras_file=$1
	emails_file=$2
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

	# Se le pide al usuario el termino que desea buscar
	read -p "Introducca el termino que desea buscar: " termino
	clear
	echo -e "🔎  Bucando el termino: $termino"

	# Convertir a minúsculas
	termino=$(echo "$termino" | awk '{print tolower($0)}')

	# Reemplazar caracteres no alfanuméricos con espacios
	termino="${termino//[^[:alnum:]]/ }"

	# lista de indices don esta el temrino
	lista_indices=()

	contador=0
	indice=0
	for term in "${lista_terminos[@]}"; do
		if [ "$term" == "$termino" ]; then
			indice=$contador
			break
		fi
		((contador++))
	done
	# pasamos la varible a tipo numer
	indice=$((indice))
	# si el indice no es 0
	# significa que hay coincidencia y se agrego un termino valido
	if [ $indice -ne 0 ]; then
		# se el suma 4 al indice para acceder bien a la matriz
		# ya que equivale allas columnas y estas con los temrino repitods empiezan en el 4
		((indice += 4))

		contador_filas_mostradas=1
		# Encabezado de la tabla
		echo "-----------------------------------------------------------------------------------"
		printf "| %-5s | %-54s | %-*s |\n" "ID" "Mail" 3 "Número de veces"
		echo "-----------------------------------------------------------------------------------"

		# Se reccorre toda la columna
		for ((j = 1; j <= matrizFilas; j++)); do
			valorMatriz=${matrizPredicciones[$j, $indice]}
			valorMatriz=$((valorMatriz))
			# y se ve si tiene coincidencias > 0
			# luego se muestra la tabla de coincidencias
			if [ $valorMatriz -ne 0 ]; then
				# se optine la linea dle mail
				mail=$(head -n "$j" "$emails_file" | tail -n 1)
				# se saca el texto del mail
				data=$(echo "$mail" | cut -d "|" -f 2)
				# Se formatea el mail
				#data=$(echo "$data" | awk '{print tolower($0)}')
				#data="${data//[^[:alnum:]]/ }"
				# Verificar si 'data' tiene más de 50 caracteres si es asi se le suma los (...)
				if [ "${#data}" -gt 50 ]; then
					# se le concatenan los 3 puntos supensivos
					data="${data:0:50}"
					data+="..."
				fi
				# Limitar 'data' a los primeros 50 caracteres
				# uan vez se optine la data se muestra los mail
				printf "| %-6s | %-54s | %-*s |\n" "$((j))" "$data" 15 "${valorMatriz}"
				# si contador_filas_mostradas es modulo 20 se pide pulse enter para seguir
				if [ $((contador_filas_mostradas % 10)) -eq 0 ]; then
					echo "-----------------------------------------------------------------------------------"
					read -p "Pulse enter para continuar" op
					clear
					echo "-----------------------------------------------------------------------------------"
					printf "| %-5s | %-54s | %-*s |\n" "ID" "Mail" 3 "Número de veces"
					echo "-----------------------------------------------------------------------------------"
				fi
				# se aumenta en uno el numeor de filas mostradas
				((contador_filas_mostradas++))
			fi
		done
		echo "-----------------------------------------------------------------------------------"
	else
		echo -e "No existe ningun mail con ese termino"
	fi
	#mail=$(head -n "$contador" "$emails_file" | tail -n 1)
	#echo "$mail"

}
opcion_informes_b() {
	clear
	# Pedir al usuario los nombres de los archivos
	read -p "Nombre del archivo de palabras a buscar (Fraud_word.txt): " palabras_file
	read -p "Nombre del archivo de mails (Emails.txt): " emails_file

	# Comprobar si los archivos existen
	if [[ ! -f $palabras_file ]]; then
		echo -e "${NORMAL}${NEGRITA}${R}Error: El archivo de $palabras_file no existe\n.${NOCOLOR}${NORMAL}"
		return
	fi
	if [[ ! -f $emails_file ]]; then
		echo -e "${NORMAL}${NEGRITA}${R}Error: El archivo de $emails_file no existe\n.${NOCOLOR}${NORMAL}"
		return
	fi

	clear
	# se ejcuta la busqued ay se pregunta si se quiere hacer otra
	ejecutar_busqueda_informes_b $palabras_file $emails_file
	while true; do
		clear
		echo -e "${NORMAL}${NEGRITA}${Y}¿ Que desea hacer ahora ?"
		echo -e "1️⃣  Realizar otra busqueda"
		echo -e "2️⃣  Volver atras${NOCOLOR}${NORMAL}"
		read -p "Seleccione una opcion: " opcion
		clear
		case $opcion in
		1)
			clear
			ejecutar_busqueda_informes_b $palabras_file $emails_file
			clear
			echo -e "${NORMAL}${NEGRITA}${Y}¿ Que desea hacer ahora ?"
			echo -e "1️⃣  Realizar otra busqueda"
			echo -e "2️⃣  Volver atras${NOCOLOR}${NORMAL}"
			read -p "Seleccione una opcion: " opcion
			clear
			;;
		2)
			return 0
			;;
		*)
			echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
			read -p "Presiona Enter para continuar..."
			clear
			;;
		esac
	done
}
opcion_informes_a() {
	# Pedir al usuario los nombres de los archivos
	read -p "Nombre del archivo de palabras a buscar (Fraud_word.txt): " palabras_file

	# Comprobar si los archivos existen
	if [[ ! -f $palabras_file ]]; then
		echo -e "${NORMAL}${NEGRITA}${R}Error: El archivo de $palabras_file no existe\n.${NOCOLOR}${NORMAL}"
		return
	fi
	#lsita de palabras y las veces que aparecen
	lista_palabras=()
	lista_numPalabras=()
	#contadores
	contador_columnas=4
	contador_para_listas=1
	i=4
	# para calcular lontitud maxima de las palabras
	max_longitud_palabra=0
	max_longitud_numero=0
	# Verificar si el archivo existe
	if [ -f "$palabras_file" ]; then
		# Leer el archivo línea por línea
		while IFS= read -r linea; do
			numero_palabras=0
			for ((j = 1; j <= matrizFilas; j++)); do
				valor=${matrizPredicciones[$j, $i]}
				valor=$((valor))
				numero_palabras=$((numero_palabras + valor))
			done
			lista_palabras[$contador_para_listas]=$linea
			lista_numPalabras[$contador_para_listas]=$numero_palabras
			# se calcula la logintud maxima -
			# Calcular la longitud máxima de palabras
			if [ ${#linea} -gt $max_longitud_palabra ]; then
				max_longitud_palabra=${#linea}
				((max_longitud_palabra += 3))
			fi
			((i++))
			((contador_para_listas++))
		done <"$palabras_file"
	else
		echo "El archivo $archivo no existe."
	fi

	# Sumar un margen a las longitudes máximas
	((max_longitud_palabra += 5))

	clear
	# Encabezado de la tabla
	echo "-----------------------------------------------------------------------------------"
	printf "| %-5s | %-*s | %-*s |\n" "Índice" $max_longitud_palabra "Palabra" 3 "Número de veces"
	echo "-----------------------------------------------------------------------------------"

	# Imprimir los datos con el ancho ajustado
	for ((i = 1; i < contador_para_listas; i++)); do
		printf "| %-6s | %-*s | %-*s |\n" "$((i))" $max_longitud_palabra "${lista_palabras[i]}" 15 "${lista_numPalabras[i]}"
		# si es modulo 20 se pide pulse enter para seguir
		if [ $((i % 10)) -eq 0 ]; then
			echo "-----------------------------------------------------------------------------------"
			read -p "Pulse enter para continuar" op
			clear
			echo "-----------------------------------------------------------------------------------"
			printf "| %-5s | %-*s | %-*s |\n" "Índice" $max_longitud_palabra "Palabra" 3 "Número de veces"
			echo "-----------------------------------------------------------------------------------"
		fi
	done

	echo "-----------------------------------------------------------------------------------"
	read op
}
opcion_informes_c() {
	while true; do
		clear
		read -p "Intrducca el ID del mail que desea examinar: " mail_id
		if [[ $mail_id -gt $matrizFilas ]] || [[ $mail_id -le 0 ]]; then
			salirWhile=true
			while $salirWhile; do
				clear
				echo -e "❌ ${NORMAL}${NEGRITA}${Y}ID mail invalido, debe de ser mayor que 0 y menor que $matrizFilas\n seleccione una opcion"
				echo -e "1️⃣  para intentar de nuevo"
				echo -e "2️⃣  para volver atras${NOCOLOR}${NORMAL}"
				read -p "Introudca una opcion: " opcion
				case $opcion in
				1)
					clear
					salirWhile=false
					;;
				2)
					return 0
					;;
				*)
					echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
					read -p "Presiona Enter para continuar..."
					clear
					;;
				esac
			done
		else
			contador_id=1

			echo "----------------------------------"
			printf "| %-5s | %-10s |\n" "ID" "Número de repeticiones"
			echo "----------------------------------"
			echo "----------------------------------"
			for ((i = 4; i < matrizColum; i++)); do
				valores_matriz=${matrizPredicciones[$mail_id, $i]}

				printf "| %-5s | %-22s |\n" "$((contador_id))" "$valores_matriz veces"
				echo "----------------------------------"
				# asi se limita el numero de mails a mostrar en 10
				if [ $((contador_id % 10)) -eq 0 ]; then
					read -p "Pulse enter para continuar"
					clear
					echo "----------------------------------"
					printf "| %-5s | %-10s |\n" "ID" "Número de repeticiones"
					echo "----------------------------------"
					echo "----------------------------------"
				fi
				((contador_id++))
			done
			read -p "Pulse enter para continuar..."
			clear
			salirWhile2=true
			while $salirWhile2; do
				echo -e "${NORMAL}${NEGRITA}${Y}Que desea hacer ahora:"
				echo -e "1️⃣  para examinar de nuevo"
				echo -e "2️⃣  para volver atras${NOCOLOR}${NORMAL}"
				read -p "Introudca una opcion: " opcion
				case $opcion in
				1)
					clear
					salirWhile2=false
					;;
				2)
					return 0
					;;
				*)
					echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
					read -p "Presiona Enter para continuar..."
					clear
					;;
				esac
			done
		fi
	done
}
abirir_opciones_informes() {
	while true; do
		clear
		echo -e "${NORMAL}${NEGRITA}${Y}Selecciones una opcion:"
		echo -e "1️⃣  Informe 1"
		echo -e "2️⃣  Informe 2"
		echo -e "3️⃣  Informe 3"
		echo -e "4️⃣  Atras${NOCOLOR}${NORMAL}"
		read -p "Seleccione una opción: " opcion3
		case $opcion3 in
		1)
			opcion_informes_a
			;;
		2)
			opcion_informes_b
			;;
		3)
			opcion_informes_c
			;;
		4)
			return 0
			;;
		*)
			echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
			read -p "Presiona Enter para continuar..."
			clear
			;;
		esac
	done
}

menu_informes() {
	clear
	if matriz_vacia matrizPredicciones; then
		clear
		while true; do
			clear
			echo -e "${NORMAL}${NEGRITA}${Y}No hay predicciones recien echas"
			echo -e "1️⃣  Cargar un <fichero.>"
			echo -e "2️⃣  Volver al menu de inicio ${NOCOLOR}${NORMAL}"
			read -p "Seleccione una opción: " opcion1
			case $opcion1 in
			1)

				if cargar_nuevo_tfidf; then
					echo -e "Pulsa enter para volver al menu"
					read -p ""
				else
					abirir_opciones_informes
				fi
				;;
			2)
				return 0
				;;
			*)
				echo -e "${R}Opción no válida. Por favor, selecciona una opción válida.${NORMAL}"
				read -p "Presiona Enter para continuar..."
				clear
				;;
			esac
		done
	else
		clear
		while true; do
			clear
			echo -e "${NORMAL}${NEGRITA}${Y}Hay predicciones recien echas"
			echo -e "1️⃣  Usar la ultima predicción"
			echo -e "2️⃣  Cargar un <fichero.>"
			echo -e "3️⃣  Volver al menu de inicio ${NOCOLOR}${NORMAL}"
			read -p "Seleccione una opción: " opcion1
			case $opcion1 in
			1)
				fichero="$fichero_tfidf.tfidf"
				echo "cargar tfidf actual $fichero_tfidf"
				cargar_fichero_tfidf $fichero
				# como cargar ficheor asigna mal el nombre se cambia este nombre par evitar errores
				fichero_tfidf="${fichero_tfidf%.tfidf}"
				abirir_opciones_informes
				;;
			2)
				if cargar_nuevo_tfidf; then

					echo -e "Pulsa enter para volver al menu"
					read -p ""
				else
					abirir_opciones_informes
				fi
				;;
			3)
				return 0
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
			read -p "Pulse enter para continuar" enter
			;;
		2)
			echo -e "${Y}Has seleccionado Predicción${NORMAL}"
			prediccion_datos
			;;
		3)
			echo -e "${Y}Has seleccionado Informes de resultados${NORMAL}"
			menu_informes
			# Aquí puedes poner el código para la opción 3
			;;
		4)
			echo -e "${Y}Has seleccionado Ayuda${NORMAL}"
			# Aquí puedes poner el código para la opción 4
			read -p "Presiona Enter para continuar..."
			;;
		5)
			echo "Saliendo..."
			clear
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
