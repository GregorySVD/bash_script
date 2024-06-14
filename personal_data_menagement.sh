#!/bin/bash

DATABASE_FILE="baza_danych.txt"

#Wywołanie menu
function show_menu {
    display_current_db
    echo "-----------------------------------------"
    echo "|        PERSONAL DATA MANAGEMENT        |"
    echo "-----------------------------------------"
    echo "| 1. Dodaj osobe do bazy danych          |" #add_user
    echo "| 2. Wyświetl bazę danych                |" #read_data
    echo "| 3. Utwórz kopii aktualnej bazy danych  |" #backup_file
    echo "| 4. Znajdź osobę po PESEL               |" #search_by_pesel
    echo "| 5. Usuń osobę po PESEL                 |" #delete_by_pesel
    echo "| 6. Zmiana pliku bazy danych            |" #change_database_file
    echo "| 7. Utwórz użytkownika                  |" #create_user
    echo "| 8. Utwórz grupę                        |" #create_group
    echo "| 9. Przydziel użytkownika do grupy      |" #add_user_to_group
    echo "| 10. Kopiuj plik                        |" #copy_file
    echo "| 11. Przenieś plik                      |" #move_file
    echo "| 12. Usuń plik                          |" #delete_file
    echo "| 13. Wyjście                            |" #exit_program
    echo "-----------------------------------------"
    echo -n "Wybierz opcję [1-13]: "
}

#Wyświetlanie aktualnie używanej bazy danych
function display_current_db {
    echo -e "\e[32mAktualnie używana baza danych: $DATABASE_FILE\e[0m"
}

#1.Dodawanie osoby do bazy danych
function add_data {
read -p "Imię: " imie
read -p "Nazwisko: " nazwisko
read -p "Adres: " adres
read -p "Nr telefonu (np. 600500123)" telefon
read -p "PESEL: " pesel

#Sprawdzenie czy wszystkie parametry zostały podane (nie są puste)
      if [[ -z "$imie" || -z "$nazwisko" || -z "$adres" || -z "$telefon" || -z "$pesel" ]]; then
        echo "Błąd: Wszystkie pola muszą być wypełnione" >&2
        return 1
    fi

#Sprawdzenie czy dane osoba juz istenieje (unique key = pesel)

if grep -q "$pesel" "$DATABASE_FILE"; then
	echo "Błąd: Osoba o takim PESEL juz istnieje" >&2
	return 1
fi

#Dodanie osoby do pliku bazy danych
echo "$imie|$nazwisko|$adres|$telefon|$pesel" >> $DATABASE_FILE
echo "Dodano pomyślnie osobe o PESEL: $pesel"
}

#2.Funkcja do odczytu danych z pliku bazy danych

function read_data {
if [[ ! -f $DATABASE_FILE ]]; then
	echo "Baza danych nie istnieje" >&2
return 1
fi

cat "$DATABASE_FILE"
}

#3. Tworzenie kopii aktualnej bazy danych
function backup_file {
    #walidacja
    if [[ -f "$DATABASE_FILE" ]]; then
        BASE_NAME=$(basename "$DATABASE_FILE" .txt)
        BACKUP_FILE="${BASE_NAME}_$(date +'%Y_%m_%d_%Hh_%Mm_%Ss')"
        cp "$DATABASE_FILE" "$BACKUP_FILE"
        if [[ $? -eq 0 ]]; then
            echo "Backup pliku zakończony sukcesem: $BACKUP_FILE"
        else
            echo "Błąd podczas tworzenia kopii zapasowej." >&2
        fi
    else
        echo "Błąd: Plik bazy danych nie istnieje: $DATABASE_FILE" >&2
    fi
}

#4. Szukanie osoby w bazie danych po PESELu 

function search_by_pesel {
    echo -n "Podaj PESEL do wyszukania: "
    read -r pesel
    if [[ -f "$DATABASE_FILE" ]]; then
        result=$(grep -w "$pesel" "$DATABASE_FILE")
        if [[ $? -eq 0 ]]; then
            IFS="," read -r imie nazwisko adres telefon pesel <<< "$result"
            echo "Osoba znaleziona:$result"
        else
            echo "Osoba z podanym PESEL nie została znaleziona."
        fi
    else
        echo "Plik bazy danych nie istnieje: $DATABASE_FILE" >&2
    fi
}
#5. Usuwanie osoby z pliku bazy danych po PESELu
function delete_by_pesel {
    echo -n "Podaj PESEL do usunięcia: "
    read -r pesel
    if [[ -f "$DATABASE_FILE" ]]; then
	    if grep -qw "$pesel" "$DATABASE_FILE"; then
        grep -vw "$pesel" "$DATABASE_FILE" > temp_file && mv temp_file "$DATABASE_FILE"
        if [[ $? -eq 0 ]]; then
            echo "Osoba z PESEL $pesel została usunięta."
        else
            echo "Błąd podczas usuwania osoby z PESEL $pesel." >&2
        fi
else
	echo "Osoba o numerze PESEL: $pesel nie istnieje w bazie danych"
	    fi
    else
        echo "Plik bazy danych nie istnieje: $DATABASE_FILE" >&2
    fi
   }

#6. Zmiana pliku bazy danych
function change_database_file {
    echo -n "Podaj nową ścieżkę do pliku bazy danych: "
    read -r new_database_file
    if [[ -f "$new_database_file" ]]; then
        DATABASE_FILE="$new_database_file"
        echo "Plik bazy danych został zmieniony na: $DATABASE_FILE"
    else
        echo "Plik $new_database_file nie istnieje." >&2
    fi
}

#7. Tworzenie użytkownika
function create_user {
read -p "Nazwa użytkownika: " username
if id "$username" &>/dev/null; then
	echo "Błąd: Użytkownik $username już istnieje" >&2
	return 1
fi
    sudo useradd "$username"
    echo "Użytkownik $username został utworzony"
}

#8. Tworzenie grupy

function create_group {
    read -p "Nazwa grupy: " groupname
    if getent group "$groupname" &>/dev/null; then
        echo "Błąd: Grupa $groupname już istnieje" >&2
        return 1
    fi
    sudo groupadd "$groupname"
    echo "Grupa $groupname została utworzona"
}
#9. Dodanie użytkowanika do grupy 
function add_user_to_group {
read -p "Nazwa użytkowanika którego chcesz dodać do grupy: " username
read -p "Nazwa grupy: " groupname
#walidacja użytkownika
if ! id "$username" &>/dev/null; then
	echo "Błąd: Użytkownik $username nie istnieje" >&2
	return 1
fi
#walidacja grupy
if ! getent group "$groupname" &>/dev/null; then 
	echo "Błąd: Grupa $groupname nie istnieje" >&2
	return 1
fi
#dodanie użytkownika do danej grupy
sudo usermod -aG "$groupname" "$username"
    echo "Użytkownik $username został przypisany do grupy $groupname"
}
#10. Funkcja do kopiowania pliku
function copy_file {

    read -p "Ścieżka do pliku źródłowego: " source
    read -p "Ścieżka do folderu docelowego: " destination
    #walidacja
    if [[ ! -f "$source" ]]; then
        echo "Błąd: Plik źródłowy nie istnieje" >&2
        return 1
    fi
    if [[ ! -d "$destination" ]]; then
        echo "Błąd: Folder docelowy nie istnieje" >&2
        return 1
    fi
    if [[ ! -w "$destination" ]]; then
        echo "Błąd: Brak uprawnień do zapisu do folderu docelowego" >&2
        return 1
    fi
    #wykonanie
    cp "$source" "$destination"
    echo "Plik został skopiowany pomyślnie"
}

#11. Przenoszenia pliku
function move_file {
    read -p "Ścieżka do pliku źródłowego: " source
    read -p "Ścieżka do folderu docelowego: " destination

    #walidacja
    if [[ ! -f "$source" ]]; then
        echo "Błąd: Plik źródłowy nie istnieje" >&2
        return 1
    fi
    if [[ ! -d "$destination" ]]; then
        echo "Błąd: Folder docelowy nie istnieje" >&2
        return 1
    fi
    if [[ ! -w "$destination" ]]; then
        echo "Błąd: Brak uprawnień do zapisu do folderu docelowego" >&2
        return 1
    fi

    mv "$source" "$destination"
    echo "Plik został przeniesiony pomyślnie"
}

#12. Usuwania pliku
function delete_file {
    read -p "Ścieżka do pliku: " filepath
    #walidacja
    if [[ ! -f "$filepath" ]]; then
        echo "Błąd: Plik nie istnieje" >&2
        return 1
    fi

    rm "$filepath"
    echo "Plik został usunięty pomyślnie"

}



#13. Funkcja zamykająca program
function exit_program {
	echo "-----------------------------------------"
	echo "|                 WYJŚCIE                |"
    echo "|  Dziękuję za skorzystanie z programu   |"
    echo "|               POZDRAWIAM               |"
	echo "|             Grzegorz Terenda           |"
    echo "-----------------------------------------"
                        exit 0


}
#Główna pętla programu

while true; do 
        show_menu
        read -p "Podaj numer zadania do wykonania: " choice

        case $choice in
        1) add_data
            ;;
        2) read_data
            ;;
        3) backup_file
            ;;
		4) search_by_pesel
			;;
		5) delete_by_pesel
			;;
		6) change_database_file
			;;
		7) create_user
			;;
		8) create_group
			;;
        9) add_user_to_group
			;;
		10) copy_file
			;;
		11) move_file
			;;
        12) delete_file
            ;;
		13) exit_program
			;;
        *) echo "Nieprawidlowa opcja. Wybierz opcje 1-11 aby wykonać poniższe operacje lub wprowadź 12 zakończyć działanie programu."
        esac
done











