# lib.sh — shared helpers

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'

info() { echo -e "${C}==>${N} $1"; }
ok()   { echo -e "${G}[OK]${N} $1"; }
warn() { echo -e "${Y}[!!]${N} $1"; }
die()  { echo -e "${R}[ERR]${N} $1"; exit 1; }
