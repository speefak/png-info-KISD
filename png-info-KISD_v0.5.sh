#!/bin/bash
# name          : png-info-KISDo
# desciption    : shown png info, added ( Caption ) or created by stable diffusion ( parameter )
# autor         : speefak (itoss@gmx.de)
# licence       : (CC) BY-NC-SA
# version	: 0.5
#------------------------------------------------------------------------------------------------------------
############################################################################################################
#####################################   define backup website list   #######################################
############################################################################################################
#------------------------------------------------------------------------------------------------------------

 RequiredPackets="zenity imagemagick"

 ScriptFile=$(readlink -f $(which $0))
 ScriptName=$(basename $ScriptFile)
 Version=$(cat $ScriptFile | grep "# version" | head -n1 | awk -F ":" '{print $2}' | sed 's/ //g')
 
 PNGFile=$(echo $@ | tr " " "\n" | grep ".png$")
 PNGInfo=$(identify -verbose $PNGFile 2>&1 ) #2>/dev/null)
 CaptionSection=$(echo "$PNGInfo" | sed -n '/Caption/,/Negative prompt:/p' | grep -v "Negative prompt:" | sed 's/^.*: /Prompt: \n/')
 ParameterSection=$(echo "$PNGInfo" | sed -n '/parameter/,/Negative prompt:/p' | grep -v "Negative prompt:" | sed 's/^.*: /Prompt: \n/')
 StepsSection=$(echo "$PNGInfo" | grep "Steps:" | sed 's/^Steps: /Steps:\n/')

# NegativePromptSection=$(echo "$PNGInfo" | sed -n '/Negative prompt:/,/png:IHDR/p' | sed -n '/Negative prompt:/,/Properties:/p' | grep -v "png:IHDR\|Properties:\|Steps:")
 NegativePromptSection=$(echo "$PNGInfo" | sed -n '/Negative prompt:/,/png:IHDR/ {/Negative prompt:/,/Properties:/p}' | \
			grep -v "png:IHDR\|Properties:\|Steps:" | \
			sed s'/Negative prompt: /Negative prompt:\n/')

#------------------------------------------------------------------------------------------------------------
############################################################################################################
########################################   set vars from options  ##########################################
############################################################################################################
#------------------------------------------------------------------------------------------------------------

	OptionVarList="
		HelpDialog;-h
		ScriptInformation;-si
		CheckForRequiredPackages;-cfrp
		OutputGUI;-g
	"

	# set entered vars from optionvarlist
	OptionAllocator="="										# for option seperator "=" use cut -d "="
	SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
	for InputOption in $(echo " $@" | sed -e 's/-[a-z]/\n\0/g' ) ; do  				# | sed 's/ -/\n-/g'
		for VarNameVarValue in $OptionVarList ; do
			VarName=$(echo "$VarNameVarValue" | cut -d ";" -f1)
			VarValue=$(echo "$VarNameVarValue" | cut -d ";" -f2)
			if [[ -n $(echo " $InputOption" | grep -w " $VarValue" 2>/dev/null) ]]; then
#				InputOption=$(sed 's/[ 0]*$//'<<< $InputOption)
				InputOption=$(sed 's/ $//g'<<< $InputOption)
				InputOptionValue=$(awk -F "$OptionAllocator" '{print $2}' <<< "$InputOption" )
				if [[ -z $InputOptionValue ]]; then
					eval $(echo "$VarName"="true")
				else
					eval $(echo "$VarName"='$InputOptionValue')
				fi
			fi
		done
	done
	
	IFS=$SAVEIFS

#------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################
###########################################   define functions   ###########################################
############################################################################################################
#------------------------------------------------------------------------------------------------------------------------------------------------
usage() {
	clear
	printf " Usage: $(basename $0) <option> <option> <option> ..."
	printf "\n"
	printf " -h			=> help dialog \n"
	printf " -si			=> show script information \n"
	printf " -cfrp			=> check for required packets \n"
	printf " -g			=> (g) GUI info (zenity)\n"
	printf "\n"
	printf " e.g. $(basename $0) -g /path/to/png "
	printf "\n"
	if [[ -z $1 ]]; then exit ; fi
	printf "\n\e[0;31m\n $1 \e[0m\n"
	printf "\n"
	exit
}
#------------------------------------------------------------------------------------------------------------------------------------------------
script_information () {
	printf "\n"
	printf " Scriptname: $ScriptName\n"
	printf " Version:    $Version \n"
	printf " Scriptfile: $ScriptFile\n"
	printf " Filesize:   $(ls -lh $0 | cut -d " " -f5)\n"
	printf "\n"
	exit 0
}
#------------------------------------------------------------------------------------------------------------------------------------------------
check_for_required_packages () {

	InstalledPacketList=$(dpkg -l | grep ii | awk '{print $2}' | cut -d ":" -f1)

	for Packet in $RequiredPackets ; do
		if [[ -z $(grep -w "$Packet" <<< $InstalledPacketList) ]]; then
			MissingPackets=$(echo $MissingPackets $Packet)
		fi
	done

	# print status message / install dialog
	if [[ -n $MissingPackets ]]; then
		printf  "missing packets: \e[0;31m $MissingPackets\e[0m\n"$(tput sgr0)
		read -e -p "install required packets ? (Y/N) "			-i "Y" 		InstallMissingPackets
		if   [[ $InstallMissingPackets == [Yy] ]]; then

			# install software packets
			sudo apt update
			sudo apt install -y $MissingPackets
			if [[ ! $? == 0 ]]; then
				exit
			fi
		else
			printf  "programm error: $LRed missing packets : $MissingPackets $Reset\n\n"$(tput sgr0)
			exit 1
		fi

	else
		printf "$LGreen all required packets detected$Reset\n"
	fi
}
#------------------------------------------------------------------------------------------------------------------------------------------------
############################################################################################################
#############################################   start script   #############################################
############################################################################################################
#------------------------------------------------------------------------------------------------------------

	# check help dialog
	if [[ -n $HelpDialog ]] || [[ -z $1 ]]; then usage ; fi

#------------------------------------------------------------------------------------------------------------

	# check for script information
	if [[ -n $ScriptInformation ]]; then script_information ; fi

#------------------------------------------------------------------------------------------------------------------------------------------------

	# check for packet install
	if [[ -n $CheckForRequiredPackages ]]; then
		check_for_required_packages
	fi

#------------------------------------------------------------------------------------------------------------------------------------------------

	# check for png file
	if [[ -z $PNGInfo ]]; then
		usage "missing png file feed"
	elif [[ -n $(grep "unable to open image" <<< "$PNGInfo") ]]; then
		usage "png file not found: $PNGFile"
	fi

#------------------------------------------------------------------------------------------------------------------------------------------------

	# printf png info ( GUI or CLI )
	if [[ -n $OutputGUI ]]; then
		zenity --info --text "$CaptionSection$ParameterSection \n\n$NegativePromptSection \n\n$StepsSection" --title "$File"
	else
		printf "\n\n$CaptionSection$ParameterSection \n\n$NegativePromptSection \n\n$StepsSection\n\n"
	fi

#------------------------------------------------------------------------------------------------------------

exit
#------------------------------------------------------------------------------------------------------------


#1=00126-10000.png
#1=00132-2680829126.png






echo "$PNGInfo"
echo ffffffffffffffffffffffffffffffffffffffffffffffff
echo "C$CaptionSection"
echo ffffffffffffffffffffffffffffffffffffffffffffffff
echo "P$ParameterSection"
echo ffffffffffffffffffffffffffffffffffffffffffffffff
echo "$NegativePromptSection"
echo ffffffffffffffffffffffffffffffffffffffffffffffff
echo "$StepsSection"


#zenity --info --text "$CaptionSection$ParameterSection \n\n$NegativePromptSection \n\n$StepsSection" --title "$File"



#| sed -n '/ Properties:/,/Negative prompt:/p' | grep -v "Negative prompt:" | sed 's/^.*:/Prompt: /'
exit





echo $1
echo
File=1
PNGCommentSD=$(identify -verbose $1 | grep  "Caption\|parameters:" | sed 's/^:/fuck/')
PNGCommentSDNP=$(identify -verbose $1 | grep  "Negative prompt" | sed 's/^  //')


#if [[ -z $PNGCommentSD ]]; then
#	PNGCommentSD=$(identify -verbose $1 | sed -n '/ Properties:/,/Negative prompt:/p' | grep -v "Negative prompt:")
	#PNGCommentSDNP=$(identify -verbose $1 | grep  "Negative prompt" | sed 's/^  //')
	
#	echo
#fi

echo -en "$PNGCommentSD  \n\n$PNGCommentSDNP\n"


# if Caption is empty
# identify -verbose 00126-10000.png | sed -n '/ Properties:/,/ Properties:/p'




#zenity --info --text "$PNGCommentSD \n\n $PNGCommentSDNP" --title "$File"
