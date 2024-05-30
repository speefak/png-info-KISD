#!/bin/bash
# name          : png-info-KISD
# desciption    : shown png info, added ( Caption ) or created by stable diffusion ( parameter )
# autor         : speefak (itoss@gmx.de)
# licence       : (CC) BY-NC-SA
# version	: 1.0
#------------------------------------------------------------------------------------------------------------
############################################################################################################
#####################################   define backup website list   #######################################
############################################################################################################
#------------------------------------------------------------------------------------------------------------

 RequiredPackets="zenity imagemagick wmctrl"

 ScriptFile=$(readlink -f $(which $0))
 ScriptName=$(basename $ScriptFile)
 Version=$(cat $ScriptFile | grep "# version" | head -n1 | awk -F ":" '{print $2}' | sed 's/ //g')

 PNGFile=$(echo $@ | tr " " "\n" | grep ".png$")
 PNGInfo=$(identify -verbose $PNGFile 2>&1 )

 CaptionSection=$(echo "$PNGInfo" | sed -n '/Caption/,/Negative prompt:/p' ) 
 ParameterSection=$(echo "$PNGInfo" | sed -n '/parameters/,/Negative prompt:/p' ) 
 PositivePrompt=$(echo "$CaptionSection$ParameterSection" | sed -n '/parameters\|Caption/,/Steps:\|Negative prompt:/p' | grep -av "Steps:\|Negative prompt:" | sed 's/^.*:/Positive Prompt: \n/' | sed -e 's/ //' )
 NegativePrompt=$(echo "$PNGInfo" | sed -n '/Negative prompt:/,/png:IHDR/ {/Negative prompt:/,/Properties:/p}' | \
			grep -av "png:IHDR\|Properties:\|Steps:" | \
			sed s'/Negative prompt: /Negative prompt:\n/')

 StepsSection=$(echo "$PNGInfo" | grep "Steps:" | sed 's/^Steps: /Config:\n/')

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
	if [[ -n $OutputGUI ]] || [[ -n $(pgrep nemo) ]]; then		#use GUI if nemo runs
		ZenityStringParsed=$(tr -cd '[:alnum:][:cntrl:][:space:][:punct:]' <<< "$PositivePrompt \n\n$NegativePrompt \n\n$StepsSection\n\n" )
		zenity --info --text "$ZenityStringParsed" --title "$PNGFile" &
		# focus on zenity window
		sleep 0.2
		wmctrl -a "$PNGFile" #$(wmctrl -lp | grep "$PNGFile" | cut -d " " -f1)
	else
		printf "\n\n$PositivePrompt \n\n$NegativePrompt \n\n$StepsSection\n\n"
	fi

#------------------------------------------------------------------------------------------------------------

exit

#------------------------------------------------------------------------------------------------------------
