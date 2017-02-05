#!/bin/sh
mkdir -p ~/.mybrowser
touch ~/.mybrowser/bookmark
touch ~/.mybrowser/error
test -f ~/.mybrowser/usertern || echo "Terms By accessing this browser" > ~/.mybrowser/userterm
test -f ~/.mybrowser/help || echo "URL ==> go to the URL\n/S  ==> show me the source code\n/L  ==> select a link to go\n/D  ==> select a link to download\n/<  ==> Go to last page\n/>  ==> Go to next page\n/H  ==> help page\n/E  ==> Show error log\n!\${cmd} ==> execute the shell cmd" > ~/.mybrowser/help

url="((http|https|ftp)://)?.+"
home="https://nasa.cs.nctu.edu.tw"
now=$home
log="$home"
log_num=1
page_num=1
input=""
flag=0

delete_tail(){
	if echo $now | rev | grep -Eq ^'/'; then
		now=$(echo $now | rev | cut -c2- | rev)
	fi	  
}

call_page(){
	now=$input
	if [ $log_num -ne $page_num ];then

		log=$(echo "$log" | sed ''$((log_num+1))',$d')
	fi
	log="$log\n$input"
	log_num=$((log_num+1))
	page_num=$log_num
	dialog --msgbox "$(w3m -dump $now)" 200 100
}

call_link(){
	link=$(curl -s -L "$now" | grep -Eoi '<a href=".*">' | cut -c 10- | rev | cut -c 3- | rev)
	mylist=''
	count=0
	for i in $link; do
		count=$((count+1))
		if echo "$i" | grep -qEo '(http|https)://' ; then
			mylist="$mylist $count $i"
		elif echo "$i" | grep -q ^'../'; then
			back=$(echo "$now" | rev | sed -r 's/[^/]+\///' | rev )
			mylist="$mylist $count $back"
		elif echo "$i" | grep -q ^'/'; then
			mylist="$mylist $count $now$i"
		else
			mylist="$mylist $count $now/$i"
		fi
	done
		opt=$(dialog --title "Mango browser" --menu "Links:" 200 100 100 $mylist  3>&1 1>&2 2>&3)
		if [ $? = 0 ]; then
			now=$(echo "$mylist" | awk '{print $(2*'$opt')}')
		fi
        
    if [ $log_num -ne $page_num ];then

		log=$(echo "$log" | sed ''$((log_num+1))',$d')
	fi
	log="$log\n$now"
	log_num=$((log_num+1))
	page_num=$log_num
	dialog --msgbox "$(w3m -dump $now)" 200 100

}

call_download(){
	link=$(curl -s -L "$now" | grep -Eoi '<a href=".*">' | cut -c 10- | rev | cut -c 3- | rev)
	mylist=''
	count=0
	for i in $link; do
		count=$((count+1))
		if echo "$i" | grep -qEo '(http|https)://' ; then
			mylist="$mylist $count $i"	
		elif echo "$i" | grep -q ^'../'; then
			back=$(echo "$now" | rev | sed -r 's/[^/]+\///' | rev )
			mylist="$mylist $count $back"
		elif echo "$i" | grep -q ^'/'; then
			mylist="$mylist $count $now$i"
		else
			mylist="$mylist $count $now/$i"
		fi
	done
	opt=$(dialog --title "Mango browser" --menu "Downloads:" 200 100 100 $mylist  3>&1 1>&2 2>&3)
	if [ $? = 0 ]; then
		wget $(echo "$mylist" | awk '{print $(2*'$opt')}') -P ~/Downloads/
	fi	
	
}

call_bookmark(){
	booklist=''
	bookmark=$(cat ~/.mybrowser/bookmark)
	count=2
	for i in $bookmark; do
		count=$((count+1))
		booklist="$booklist $count $i"
	done
	opt=$(dialog --title "Mango browser" --menu "Bookmarks:" 200 100 100 "1" "Add_a_bookmark" "2" "Delete_a_bookmark" $booklist  3>&1 1>&2 2>&3)
		if [ $? = 0 ]; then
			if [ "$opt" -eq 1 ]; then
				echo "$now" >> ~/.mybrowser/bookmark
			elif [ "$opt" -eq 2 ];then
				d_opt=$(dialog --title "Mango browser" --menu "Delete_a_bookmark" 200 100 100 $booklist  3>&1 1>&2 2>&3)
				if [ "$count" -gt 2 ];then
				line=$((d_opt-2))
				sed -in ''$line','$line'd' ~/.mybrowser/bookmark
				fi
			else
				line=$((opt-2))
				now=$(echo "$bookmark" | sed -n ''$line','$line'p')
			fi	
		fi
}

call_next(){
	
	if [ $log_num -lt $page_num ]; then
		next=$(echo "$log" | awk '{if(NR=='$log_num'+1)print $1}')
		now=$next
		log_num=$((log_num+1))
	fi
}


call_last(){
	if [ $log_num -eq 1 ]; then
		now=$home
	else
		last=$(echo "$log" | awk '{if(NR=='$log_num'-1)print $1}')
		now=$last
		log_num=$((log_num-1))
    fi
}

call_error(){
	dialog --title "Mango browser" --msgbox "$(cat ~/.mybrowser/error)" 200 100
}

call_help(){
	dialog --title "Mango browser" --msgbox "$(cat ~/.mybrowser/help)" 200 100
}

call_exec(){
	cmd=$(echo "$input" | cut -c 2-)
	ans=$(eval $cmd 2>>~/.mybrowser/error )
	dialog --title "Mango browser" --msgbox "$ans" 200 100 

}

dialog --title  "Term and Conditions of Use" --yesno "$(cat ~/.mybrowser/userterm)" 200 100
sel=$?
case $sel in
	0)  dialog --msgbox "$(w3m -dump https://nasa.cs.nctu.edu.tw)" 200 100
		while [ $flag -eq 0 ]; do
			delete_tail
			dialog --title "Mango browser" --inputbox "$now" 200 100 2>~/.mybrowser/inputbox.tmp$$
			respose=$?
			input=`cat ~/.mybrowser/inputbox.tmp$$`
			case $respose in
				0)
					if echo "$input" | grep -q '^/'; then
						if [ $input = '/S' ] || [ $input = '/source' ]; then
							dialog --title "Mango browser" --msgbox "$(curl -s -L "$now")" 200 100 
						elif [ $input = '/L' ] || [ $input = '/link' ]; then
							call_link
						elif [ $input = '/D' ] || [ $input = '/download' ]; then
							call_download
						elif [ $input = '/B' ] || [ $input = '/bookmark' ]; then
							call_bookmark		
						elif [ $input = '/E' ] || [ $input = '/error' ]; then
							call_error
						elif [ $input = '/>' ]; then
							call_next
						elif [ $input = '/<' ]; then
							call_last
						elif [ $input = '/H' ] || [ $input = '/help' ]; then
							call_help
						else
							call_help
						fi
					elif echo "$input" | grep -q ^[!]; then
						call_exec			
					elif echo "$input" | grep -qE $url; then
						call_page
					else
						dialog --title "Mango browser" --msgbox "Invaild Input\nTry /H for help messages." 200 100
					fi ;;
				1)
					dialog --title  "TMango browser" --yesno "Do you want to leave the browser?" 200 100
						check=$?
						case $check in
							0) flag=1 
								dialog --title "Mango browser" --msgbox "                                        GOOGLE BYE          " 200 100
								;;
							1) flag=0 ;;
						esac	
					;;
			esac
		done ;;
	1)  dialog --title "Apology" --msgbox "Sorry, you can't use it! GOOGEL BYE" 200 100 ;;
esac
