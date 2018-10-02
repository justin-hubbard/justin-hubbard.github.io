#1/bin/bash
NAME=$1
if [ -d "$NAME"]
then
	cd $NAME
else
	mkdir $NAME
	cd $NAME
fi


filename="index.html"
if [ -e $filename ]
then
	echo "File already exists"
else
	touch $filename
	echo "---" >> $filename
	echo "layout: tagpage" >> $filename
	echo "tag: $NAME" >> $filename
	echo "---" >> $filename
fi