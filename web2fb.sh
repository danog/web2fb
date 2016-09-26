#!/bin/bash -e
# web2fb video reuploader script

# By Daniil Gentili (https://daniil.it)
# Licensed under GPLv3
# Copyright 2016 Daniil Gentili

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


echo "web2fb video reuploader script   Copyright (C) 2016  Daniil Gentili.
This program comes with ABSOLUTELY NO WARRANTY; for details see 
https://github.com/danog/web2fb-reuploader/blob/master/LICENSE.
This is free software, and you are welcome to redistribute it
under certain conditions: see https://github.com/danog/web2fb-reuploader/blob/master/LICENSE.
"


access_token=""
page_id=0

for f in $*;do
	echo "Reuploading $f..."

	echo "Downloading video..."
	yres=$(youtube-dl -o "%(title)s.%(ext)s" --prefer-ffmpeg --exec "echo disizdastartofdafilename {} disizdaendofdafilename" "$f")
	if [ "$?" != 0 ]; then echo "Failed downloading video $f"; exit 1;fi
	fname=$(echo "$yres" | sed '/^disizdastartofdafilename\s.*\sdisizdaendofdafilename$/!d;s/^disizdastartofdafilename\s//g;s/\sdisizdaendofdafilename$//g')

	echo "Getting metadata..."
	description=$(youtube-dl --get-description "$f")
	title=$(youtube-dl --get-filename -o "%(title)s" "$f")
	source="@$fname"
	file_size=$(wc -c "$fname" | sed 's/\s.*//g')

	echo "Getting thumbnail..."
	thumburl=$(youtube-dl --get-thumbnail "$f")
	thumbfname=$(basename "$thumburl")
	wget "$thumburl" -O "$thumbfname"
	thumb="@$thumbfname"

	embeddable=true

	echo "Uploading video..."
	res=$(curl "https://graph-video.facebook.com/v2.7/$page_id/videos" -F "access_token=$access_token" -F "description=$description" -F "title=$title" -F "embeddable=$embeddable" -F "file_size=$file_size" -F "source=$source" -F "thumb=$thumb")
	if ! echo "$res" | -q grep '{"id":'; then echo "Upload of $f failed"; exit 1;fi
	echo "Removing temporary files..."
	rm "$fname" "$thumbfname"
	echo "$f was reuploaded successfully!"
done
