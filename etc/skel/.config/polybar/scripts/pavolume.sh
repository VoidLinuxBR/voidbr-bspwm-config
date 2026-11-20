#!/usr/bin/env bash
#
# pavolume.sh - módulo de volume do polybar (VoidBR BSPWM)
#
# Usa somente 'pactl', que funciona tanto com PulseAudio quanto com
# PipeWire (pipewire-pulse). O 'pacmd' antigo NÃO funciona com PipeWire
# e imprimia "Nenhum daemon do PulseAudio em execução..." na barra.
#

osd='no'
inc='2'
capvol='no'
maxvol='150'
autosync='yes'
sink='@DEFAULT_SINK@'

# saída do pactl sempre em inglês, para o parse não quebrar em pt_BR
export LC_ALL=C

curVol=0
curStatus='no'

paOk() {
	pactl info &>/dev/null
}

getCurVol() {
	curVol=$(pactl get-sink-volume "$sink" 2>/dev/null | grep -o -m1 '[0-9]\+%' | head -n1 | tr -d '%')
	[[ -z $curVol ]] && curVol=0
}

volMuteStatus() {
	curStatus=$(pactl get-sink-mute "$sink" 2>/dev/null | awk '{print $2}')
	[[ -z $curStatus ]] && curStatus='no'
}

osdShow() {
	[[ $osd == 'yes' ]] && qdbus org.kde.kded /modules/kosd showVolume "$curVol" "${1:-0}"
}

volSync() {
	local defsink idx
	defsink=$(pactl get-default-sink 2>/dev/null)
	idx=$(pactl list short sinks 2>/dev/null | awk -v n="$defsink" '$2 == n {print $1}')
	[[ -z $idx ]] && return
	getCurVol
	pactl list short sink-inputs 2>/dev/null | awk -v s="$idx" '$2 == s {print $1}' |
		while read -r input; do
			pactl set-sink-input-volume "$input" "${curVol}%"
		done
}

volUp() {
	local limit
	getCurVol
	if [[ $capvol == 'yes' ]]; then
		limit=100
	else
		limit=$maxvol
	fi
	if ((curVol + inc >= limit)); then
		pactl set-sink-volume "$sink" "${limit}%"
	else
		pactl set-sink-volume "$sink" "+${inc}%"
	fi
	getCurVol
	osdShow 0
	[[ $autosync == 'yes' ]] && volSync
}

volDown() {
	pactl set-sink-volume "$sink" "-${inc}%"
	getCurVol
	osdShow 0
	[[ $autosync == 'yes' ]] && volSync
}

volMute() {
	case "$1" in
	mute)
		pactl set-sink-mute "$sink" 1
		curVol=0
		osdShow 1
		;;
	unmute)
		pactl set-sink-mute "$sink" 0
		getCurVol
		osdShow 0
		;;
	esac
}

output() {
	getCurVol
	volMuteStatus
	if [[ $curStatus == 'yes' ]]; then
		echo " mute"
	else
		echo " ${curVol}%"
	fi
}

# Fica escutando eventos do servidor de áudio.
# Sem servidor rodando, deixa o módulo vazio e tenta de novo a cada 5s,
# em vez de sair (o polybar reiniciava o script em loop -> barra piscando).
listen() {
	while true; do
		if ! paOk; then
			echo ""
			sleep 5
			continue
		fi
		output
		pactl subscribe 2>/dev/null | while read -r event; do
			case "$event" in
			*"on sink"* | *"on server"* | *"on card"*) output ;;
			esac
		done
		# servidor caiu/reiniciou: espera um pouco e reconecta
		sleep 2
	done
}

case "$1" in
--up) volUp ;;
--down) volDown ;;
--togmute)
	volMuteStatus
	if [[ $curStatus == 'yes' ]]; then
		volMute unmute
	else
		volMute mute
	fi
	;;
--mute) volMute mute ;;
--unmute) volMute unmute ;;
--sync) volSync ;;
--listen) listen ;;
*) paOk && output ;;
esac
