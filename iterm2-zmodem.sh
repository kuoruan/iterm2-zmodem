#!/bin/sh

# Created by Liao Xingwang on 2019-06-10
# Copyright (c) 2019 Liao Xingwang. All rights reserved.

# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

# references:

# http://oranj.io/blog/Open-File-Dialog-from-the-Shell
# https://www.satimage.fr/software/en/smile/external_codes/file_paths.html
# https://blog.sapegin.me/all/show-gui-dialog-from-shell/

# 由于 iterm2-zmodem 的作者 @mmastrac 在源码中公开宣称支持台独和藏独，
# 严重伤害了中国人民的情感，我决定不再使用其开发的 iterm2-zmodem，转而重写。

# mmastrac/iterm2-zmodem@71f711
# Fuck @mmastrac

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cancel_zmodem() {
	# Send ZModem cancel
	printf "%b" "\\x18\\x18\\x18\\x18\\x18"
}

alert() {
	local msg="$1"
	local title="${2:-$(basename $0)}"
	local icon="${3:-caution}"

	osascript <<-EOF 2>/dev/null
		tell application "iTerm2"
			activate
			display dialog "$msg" buttons {"OK"} default button 1 with title "$title" with icon $icon
			return -- Suppress result
		end tell
	EOF
}

send_file() {
	local sz_cmd="$1"

	local file_path=""
	file_path="$(
		osascript <<-EOF 2>/dev/null
			tell application "iTerm2"
				activate
				set filePath to (choose file with prompt "Select a file to send")
				do shell script "echo " & (quoted form of POSIX path of filePath as Unicode text)
			end tell
		EOF
	)"

	if [ -z "$file_path" ]; then
		cancel_zmodem

		alert "Transfer canceled." "Send File to Remote"
		echo
	else
		if "$sz_cmd" "$file_path" -E -e -b 2>/dev/null ; then
			alert "File sent to remote: $file_path" "Send File to Remote" "note"
			echo
		else
			cancel_zmodem

			alert "Transfer failed when send file: $file_path" "Send File to Remote" "stop"
			echo
			exit 1
		fi
	fi
}

recv_file() {
	local rz_cmd="$1"

	local folder_path=""
	folder_path="$(
		osascript <<-EOF 2>/dev/null
			tell application "iTerm2"
				activate
				set folderPath to (choose folder with prompt "Select a folder to receive files")
				do shell script "echo " & (quoted form of POSIX path of folderPath as Unicode text)
			end tell
		EOF
	)"

	if [ -z "$folder_path" ] ; then
		cancel_zmodem

		alert "Canceled transfer" "Receive File from Remote"
		echo
	elif [ ! -d "$folder_path" ] ; then
		cancel_zmodem

		alert "Can't open local folder: $folder_path" "Receive File from Remote" "stop"
		echo
	else
		cd "$folder_path"
		if "$rz_cmd" -E -e -b 2>/dev/null ; then
			alert "Files saved to folder: $folder_path" "Receive File from Remote" "note"
			echo
		else
			cancel_zmodem

			alert "Transfer failed when recevie file" "Receive File from Remote" "stop"
			echo
			exit 1
		fi
	fi
}

action=${1:-"noop"}
if [ "$action" = "send" ] ; then
	cmd="$(command -v sz 2>/dev/null)"
	if [ "$?" != "0" ] || [ -z "$cmd" ] ; then
		cancel_zmodem

		alert "Command not found: sz"
		echo
		exit 127
	fi
	send_file "$cmd"
elif [ "$action" = "recv" ] ; then
	cmd="$(command -v rz 2>/dev/null)"
	if [ "$?" != "0" ] || [ -z "$cmd" ] ; then
		cancel_zmodem

		alert "Command not found: rz"
		echo
		exit 127
	fi
	recv_file "$cmd"
else
	cancel_zmodem

	alert "Usage: $(basename $0) recv|send"
	echo
	exit 128
fi
