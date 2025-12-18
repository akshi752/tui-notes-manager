#!/bin/bash



NOTES_DIR="data/notes"
LOG_FILE="data/actions.log"
FAV_FILE="data/favourites.txt"

# Create favorite file if it doesn't exist
if [ ! -f "$FAV_FILE" ]; then
    touch "$FAV_FILE"
fi

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"


mkdir -p "$NOTES_DIR"


trap "echo -e '\n${RED}Program interrupted. Goodbye!${RESET}'; exit" SIGINT

#   UTILITY FUNCTIONS

show_banner() {
    echo -e "${BLUE}"
    echo "======================================"
    echo "         TUI NOTES MANAGER"
    echo "======================================"
    echo -e "${RESET}"
}


success_msg() {
    echo -e "${GREEN}✔ SUCCESS:${RESET} $1"
    sleep 1
}


error_msg() {
    echo -e "${RED}✘ ERROR:${RESET} $1"
    sleep 1
}


loading() {
    echo -ne "${YELLOW}Processing"
    for i in {1..3}; do
        sleep 0.3
        echo -ne "."
    done
    echo -e "${RESET}"
}


#  MAIN FUNCTIONS


create_note() {
    echo -e "${CYAN}===== CREATE NEW NOTE =====${RESET}"
    echo -n "Enter note title: "
    read title

    filename="$NOTES_DIR/${title}.txt"

    echo "Write your note. Press CTRL+D to save:"
    cat > "$filename"

    echo "$(date) - Created note: $title" >> "$LOG_FILE"

    success_msg "Note saved successfully!"
}

list_notes() {
    echo -e "${CYAN}===== LIST OF NOTES =====${RESET}"
    
    if [ ! "$(ls -A $NOTES_DIR)" ]; then
        error_msg "No notes found!"
        return
    fi

    ls "$NOTES_DIR"
}

view_note() {
    echo -e "${CYAN}===== VIEW NOTE =====${RESET}"
    echo -n "Enter note title to view: "
    read title
    file="$NOTES_DIR/${title}.txt"

    if [ ! -f "$file" ]; then
        error_msg "Note does not exist!"
        return
    fi

    echo -e "${YELLOW}------ $title ------${RESET}"
    cat "$file"
    echo -e "${YELLOW}---------------------${RESET}"
}

edit_note() {
    echo -e "${CYAN}===== EDIT NOTE =====${RESET}"
    echo -n "Enter note title to edit: "
    read title
    file="$NOTES_DIR/${title}.txt"

    if [ ! -f "$file" ]; then
        error_msg "Note does not exist!"
        return
    fi

    echo -e "${YELLOW}Opening note in VI editor...${RESET}"
    sleep 1
    vi "$file"

    echo "$(date) - Edited note: $title" >> "$LOG_FILE"
    success_msg "Note updated successfully!"
}

delete_note() {
    echo -e "${CYAN}===== DELETE NOTE =====${RESET}"
    echo -n "Enter note title to delete: "
    read title
    file="$NOTES_DIR/${title}.txt"

    if [ ! -f "$file" ]; then
        error_msg "Note does not exist!"
        return
    fi

    rm "$file"
    echo "$(date) - Deleted note: $title" >> "$LOG_FILE"
    success_msg "Note deleted successfully!"
}

search_note() {
    echo -e "${CYAN}===== SEARCH NOTES =====${RESET}"
    echo -n "Enter keyword to search: "
    read key

    echo -e "${BLUE}Searching for '$key'...${RESET}"
    grep -Rni "$key" "$NOTES_DIR" # search command
    # R recursive search
    # n for printing line along with line number
    # i for case insensitive

    if [ $? -ne 0 ]; then
        error_msg "No matching notes found!"
    else
        success_msg "Search complete."
    fi
}

backup_notes() {
    echo -e "${CYAN}===== BACKUP NOTES =====${RESET}"
    backup_file="backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    tar -czf "$backup_file" "$NOTES_DIR" # tar is a Linux command used to bundle multiple files/folders into a single archive file.
    echo "$(date) - Backup created: $backup_file" >> "$LOG_FILE"

    success_msg "Backup created: $backup_file"
}

view_logs() {
    echo -e "${CYAN}===== ACTIVITY LOG =====${RESET}"
    echo "--------------------------------------"

    if [ ! -f "$LOG_FILE" ]; then
        error_msg "No logs found yet!"
        return
    fi

    cat "$LOG_FILE"
}

show_stats() {
    echo -e "${CYAN}===== NOTES STATISTICS =====${RESET}"
    echo "--------------------------------------"

    total_notes=$(ls "$NOTES_DIR" | wc -l)
    echo "Total notes: $total_notes"

    echo ""
    for file in "$NOTES_DIR"/*.txt; do
        [ -e "$file" ] || continue
        lines=$(wc -l < "$file")
        words=$(wc -w < "$file")
        chars=$(wc -m < "$file")
        name=$(basename "$file")

        echo "$name → $lines lines, $words words, $chars characters"
    done
    echo "--------------------------------------"
}

rename_note() {
    echo -e "${CYAN}===== RENAME NOTE =====${RESET}"
    read -p "Enter old title: " old
    read -p "Enter new title: " new

    old_file="$NOTES_DIR/${old}.txt"
    new_file="$NOTES_DIR/${new}.txt"

    if [ ! -f "$old_file" ]; then
        error_msg "Note does not exist!"
        return
    fi

    mv "$old_file" "$new_file"
    echo "$(date) - Renamed note: $old -> $new" >> "$LOG_FILE"
    success_msg "Note renamed successfully!"
}
sort_notes() {
    echo -e "${CYAN}===== SORT NOTES =====${RESET}"
    echo "[1] Sort by Name"
    echo "[2] Sort by Date Modified"
    read -p "Enter choice: " ch

    if [ "$ch" == "1" ]; then
        ls "$NOTES_DIR" | sort
    else
        ls -lt "$NOTES_DIR"
    fi
}
mark_favourite() {
    echo -e "${CYAN}===== MARK NOTE AS FAVORITE =====${RESET}"
    echo -n "Enter note title to favorite: "
    read title
    file="$NOTES_DIR/${title}.txt"

    if [ ! -f "$file" ]; then
        error_msg "Note does not exist!"
        return
    fi

    # Check if already favorited
    if grep -Fxq "$title" "$FAV_FILE"; then
        error_msg "Already in favorites!"
        return
    fi

    echo "$title" >> "$FAV_FILE"
    echo "$(date) - Added to favorites: $title" >> "$LOG_FILE"
    success_msg "Added to Favorites!"
}
view_favourites() {
    echo -e "${CYAN}===== FAVORITE NOTES =====${RESET}"

    if [ ! -s "$FAV_FILE" ]; then
        error_msg "No favorites added yet!"
        return
    fi

    echo -e "${YELLOW}Your Favorite Notes:${RESET}"
    cat "$FAV_FILE"
}

remove_favourite() {
    echo -n "Enter note title to remove from favorites: "
    read title

    if ! grep -Fxq "$title" "$FAV_FILE"; then
        error_msg "This note is not in favorites!"
        return
    fi

    # Remove entry from favorites
    grep -Fvx "$title" "$FAV_FILE" > temp.txt && mv temp.txt "$FAV_FILE"

    echo "$(date) - Removed from favorites: $title" >> "$LOG_FILE"
    success_msg "Removed from Favorites!"
}


# MAIN MENU LOOP


while true
do
    show_banner
    echo -e "${CYAN}=====================================${RESET}"
    echo -e "${YELLOW}            ✨ MENU ✨                 ${RESET}"
    echo -e "${CYAN}=====================================${RESET}"
    echo -e "${GREEN}[1]${RESET} 📄  Create Note"
    echo -e "${GREEN}[2]${RESET} 📁  List Notes"
    echo -e "${GREEN}[3]${RESET} 👁️   View Note"
    echo -e "${GREEN}[4]${RESET} ✏️   Edit Note"
    echo -e "${GREEN}[5]${RESET} 🗑️   Delete Note"
    echo -e "${GREEN}[6]${RESET} 🔍  Search Notes"
    echo -e "${GREEN}[7]${RESET} 💾  Backup Notes"
    echo -e "${GREEN}[8]${RESET} 📜  View Logs"
    echo -e "${GREEN}[9]${RESET} 📊  Notes Statistics"
    echo -e "${GREEN}[10]${RESET}📊  Rename note"
    echo -e "${GREEN}[11]${RESET}🔽 Sort notes"
    echo -e "${GREEN}[12]${RESET}⭐ Add to Favourites"
    echo -e "${GREEN}[13]${RESET}📂 View Favourites"
    echo -e "${GREEN}[14]${RESET}❌ Remove Favourite"
    echo -e "${GREEN}[15]${RESET}🚪 Exit"
    echo -e "${CYAN}=====================================${RESET}"
    echo -n "👉 Enter your choice: "
    read choice

    case $choice in
        1) create_note ;;
        2) list_notes ;;
        3) view_note ;;
        4) edit_note ;;
        5) delete_note ;;
        6) search_note ;;
        7) backup_notes ;;
        8) view_logs ;;
        9) show_stats ;;
        10) rename_note ;;
        11) sort_notes ;;
        12) mark_favourite ;;
        13) view_favourites ;;
        14) remove_favourite ;;
        15) 
            echo -e "${GREEN}Exiting... Goodbye!${RESET}"
            exit ;;
        *)
            error_msg "Invalid choice! Try again." ;;
    esac

    echo -e "${YELLOW}Press Enter to continue...${RESET}"
    read
done
