#!/bin/sh

# Created by Liao Xingwang on 2019-06-10
# Copyright (c) 2019-present Liao Xingwang. All rights reserved.

# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

# references:

# http://oranj.io/blog/Open-File-Dialog-from-the-Shell
# https://www.satimage.fr/software/en/smile/external_codes/file_paths.html
# https://blog.sapegin.me/all/show-gui-dialog-from-shell/

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

SEND_DIALOG_TITLE="Send File - Zmodem"
RECEIVE_DIALOG_TITLE="Receive File - Zmodem"

cancel_zmodem() {
	# Send ZModem cancel
	printf "\x18\x18\x18\x18\x18"
}

alert() {
	msg="$1"
	title="${2:-$(basename "$0")}"
	icon="${3:-caution}" # stop | note | caution

	osascript <<-EOF 2>/dev/null
		tell application "iTerm2"
			activate
			display dialog "$msg" buttons {"OK"} default button 1 with title "$title" with icon $icon
			return -- Suppress result
		end tell
	EOF
}

send_file() {
	file_path="$(
		osascript <<-EOF 2>/dev/null
			tell application "iTerm2"
				activate
				set filePath to (choose file with prompt "Select a file to send")
				do shell script "echo " & (quoted form of POSIX path of filePath as Unicode text)
			end tell
		EOF
	)"

	if [ -z "$file_path" ] ; then
		cancel_zmodem

		sleep 1 # sleep to make next "echo" works

		echo
		exit 0
	fi

	if sz "$file_path" -b -B 4096 -e -E 2>/dev/null ; then
		alert "File sent to remote: $file_path" "$SEND_DIALOG_TITLE" "note"

		echo
	else
		cancel_zmodem

		alert "Transfer failed when send file: $file_path" "$SEND_DIALOG_TITLE" "stop"

		echo
		exit 1
	fi
}

recv_file() {
	folder_path="$(
		osascript <<-EOF 2>/dev/null
			tell application "iTerm2"
				activate
				set folderPath to (choose folder with prompt "Select a folder to receive file")
				do shell script "echo " & (quoted form of POSIX path of folderPath as Unicode text) & " | sed 's|:/$|/|'"
			end tell
		EOF
	)"

	if [ -z "$folder_path" ] ; then
		cancel_zmodem

		sleep 1

		echo
		exit 0
	fi

	if [ ! -d "$folder_path" ] ; then
		cancel_zmodem

		alert "Can't find local folder: $folder_path" "$RECEIVE_DIALOG_TITLE" "stop"

		echo
		exit 1
	else
		if ! cd "$folder_path" ; then
			cancel_zmodem

			alert "Can't open local folder: $folder_path" "$RECEIVE_DIALOG_TITLE" "stop"

			echo
			exit 1
		fi

		if rz -b -B 4096 -e -E 2>/dev/null ; then
			cd - || true

			alert "File saved to local folder: $folder_path" "$RECEIVE_DIALOG_TITLE" "note"

			echo
		else
			cancel_zmodem

			alert "Transfer failed when recevie file" "$RECEIVE_DIALOG_TITLE" "stop"

			echo
			exit 1
		fi
	fi
}

action=${1:-"noop"}
if [ "$action" = "send" ] ; then
	if ! command -v sz 2>/dev/null ; then
		cancel_zmodem

		alert "Command not found: sz"

		echo
		exit 127
	fi

	send_file
elif [ "$action" = "recv" ] ; then
	if ! command -v rz 2>/dev/null ; then
		cancel_zmodem

		alert "Command not found: rz"

		echo
		exit 127
	fi

	recv_file
else
	cancel_zmodem

	alert "Usage: $(basename "$0") recv|send"

	echo
	exit 128
fi
