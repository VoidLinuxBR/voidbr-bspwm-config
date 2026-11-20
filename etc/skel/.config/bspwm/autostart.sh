#!/bin/bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

#Find out your monitor name with xrandr or arandr (save and you get this line)
#xrandr --output VGA-1 --primary --mode 1360x768 --pos 0x0 --rotate normal
#xrandr --output DP2 --primary --mode 1920x1080 --rate 60.00 --output LVDS1 --off &
#xrandr --output LVDS1 --mode 1366x768 --output DP3 --mode 1920x1080 --right-of LVDS1
#xrandr --output HDMI2 --mode 1920x1080 --pos 1920x0 --rotate normal --output HDMI1 --primary --mode 1920x1080 --pos 0x0 --rotate normal --output VIRTUAL1 --off
#autorandr horizontal

# audio: mesmo esquema do voidbr-enlightenment-config. O bspwm nao le o
# ~/.config/autostart (onde o voidbr-base-config poe o pipewire.desktop), entao
# o voidbr-bspwm-pipewire-start encerra as sobras da sessao anterior e sobe o
# pipewire, que chama o wireplumber e o pipewire-pulse pelos drop-ins de
# ~/.config/pipewire/pipewire.conf.d.
# Roda so na abertura da sessao: o "bspc wm -r" reexecuta o bspwmrc (e este
# script) com o mesmo PID do bspwm, e nao pode derrubar o audio.
wmpid=$(pgrep -nx -u "$USER" bspwm)
audiomark="${XDG_RUNTIME_DIR:-/tmp}/voidbr-bspwm-audio.${USER}.${wmpid}"
if [ ! -e "$audiomark" ]; then
  : >"$audiomark"
  voidbr-bspwm-pipewire-start &
fi

$HOME/.config/polybar/launch.sh &

#change your keyboard if you need it
#setxkbmap -layout be

keybLayout=$(setxkbmap -v | awk -F "+" '/symbols/ {print $2}')

if [ $keybLayout = "be" ]; then
  run sxhkd -c ~/.config/bspwm/sxhkd/sxhkdrc-azerty &
else
  run sxhkd -c ~/.config/bspwm/sxhkd/sxhkdrc &
fi

#Some ways to set your wallpaper besides variety or nitrogen
#feh --bg-scale ~/.config/bspwm/wall.png &
[ -x "$HOME/.fehbg" ] && "$HOME/.fehbg" &
#wallpaper for other Arch based systems
#feh --bg-fill /usr/share/archlinux-tweak-tool/data/wallpaper/wallpaper.png &
#feh --randomize --bg-fill ~/Dropbox/Apps/Desktoppr/*

xsetroot -cursor_name left_ptr &

conky -c $HOME/.config/bspwm/system-overview &
run nm-applet &
run xfce4-power-manager &
numlockx on &
picom --config $HOME/.config/bspwm/picom.conf &
# agente polkit: mate-polkit vem do voidbr-gui-common
for agent in /usr/libexec/polkit-mate-authentication-agent-1 \
             /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 \
             /usr/libexec/polkit-gnome-authentication-agent-1; do
  if [ -x "$agent" ]; then
    pgrep -f 'polkit-.*-authentication-agent-1' >/dev/null || "$agent" &
    break
  fi
done
# notificacoes: dunst (dependencia do voidbr-bspwm)
run dunst &
run volumeicon &
#nitrogen --restore &
#run caffeine &
#run vivaldi-stable &
#run firefox &
#run thunar &
#run dropbox &
#run insync start &
#run discord &
#run spotify &
#run atom &
