//
// Sonos v3.2 by Harmen Bartelink
// Further enhanced by Toonz after Harmen stopped developing
//

import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0;
import ScreenStateController 1.0
import FileIO 1.0

App {
	id: root
	property url trayUrl : "MediaTray.qml";
	property url menuScreenUrl : "MenuScreen.qml"
	property url mediaSelectZoneUrl : "MediaSelectZone.qml"
	property url tileUrl : "SonosTile.qml"
	property url tileUrlControl : "SonosMiniControlTile.qml"
	property url thumbnailIcon: "qrc:/tsc/SonosThumb.png"
	property MenuScreen menuScreen
	property MediaScreen mediaScreen
	property MediaSelectZone mediaSelectZone
	property FavoritesScreen favoritesScreen
	
	//next property's are used for the visibility of the systray icon.
	property SystrayIcon mediaTray
	property bool showSonosIcon : true
	property string playbackState
	property string timeStr
	property string dateStr
	property variant playlists : []
	property variant favourites : []
	property variant queue : []
	property variant sonoslist : []
	property string sonosName
	property bool sonosNameIsGroup : false
	property string ipadresLabel
	property string poortnummer
	property string actualArtist
	property string actualTitle
	property string nowPlayingImage
	property bool playButtonVisible : true
	property bool pauseButtonVisible : false
	property bool shuffleButtonVisible : true
	property bool shuffleOnButtonVisible : false
	property variant settings : {
			"showSonosIcon" : "true",
			"sonosName" : "",
			"path" : ""
		}

	//this is the main property for the complete Sonos App!
	property string connectionPath

	FileIO {
		id: sonosSettingsFile
		source: "file:///mnt/data/tsc/sonos.userSettings.json"
 	}

	QtObject {
		id: p
		property url favoritesScreenUrl : "FavoritesScreen.qml"
		property url mediaScreenUrl : "MediaScreen.qml"
	}
	
	function init() {
		registry.registerWidget("systrayIcon", trayUrl, this, "mediaTray");
		registry.registerWidget("screen", p.mediaScreenUrl, this, "mediaScreen");
		registry.registerWidget("screen", p.favoritesScreenUrl, this, "favoritesScreen");
		registry.registerWidget("screen", menuScreenUrl, this, "menuScreen");
		registry.registerWidget("screen", mediaSelectZoneUrl, this, "mediaSelectZone");
		registry.registerWidget("menuItem", null, this, null, {objectName: "sonosMenuItem", label: qsTr("Sonos"), image: thumbnailIcon, screenUrl: menuScreenUrl, weight: 120});
		registry.registerWidget("tile", tileUrl, this, null, {thumbLabel: qsTr("Sonos"), thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, thumbIconVAlignment: "center"});
	}
	
	//this function needs to be started after the app is booted.
	Component.onCompleted: {
		readSettings();
	}

	Connections {
		target: screenStateController
		onScreenStateChanged: {
			if (screenStateController.screenState == ScreenStateController.ScreenColorDimmed || screenStateController.screenState == ScreenStateController.ScreenOff) {
				sonosPlayInfoTimer.stop();
				sonosPlayInfoTimer.interval = 20000;
				sonosPlayInfoTimer.start();
			} else {
				sonosPlayInfoTimer.stop();
				sonosPlayInfoTimer.interval = 5000;
				sonosPlayInfoTimer.start();
			}
		}
	}

	
	//this will update the found zones in your sonos HTTP API and write it to ZoneItemsJS, but also push it to the new Array which is used by the whole application.
	function updateAvailableZones() {
		var newArray = [];
		var xmlhttp = new XMLHttpRequest();
		var tmpSonosName = sonosName;
		sonosName = "";
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					sonosNameIsGroup = false;
					if (response.length > 0) {
						for (var i = 0; i < response.length; i++) {
								// determine group or single room
							var tmpGroupFlag = (response[i]["members"].length > 1);
								// update groupflag for zone from settingsfile
							if (tmpSonosName == response[i]["coordinator"]["roomName"]) {
								sonosName = tmpSonosName;
								sonosNameIsGroup = tmpGroupFlag;
							}
							newArray.push({name: response[i]["coordinator"]["roomName"], isGroup: tmpGroupFlag});
						}
						sonoslist = newArray;
					} 
					if (sonosName.length < 1) {
						sonosName = newArray[0]['name'];
						sonosNameIsGroup = newArray[0]['isGroup'];
					} 
				}
			}
		}
		xmlhttp.open("GET", "http://"+connectionPath+"/zones");
		xmlhttp.send();
	}

	//this is the save of the toggle which could be found in the menuscreen.
	function saveshowSonosIcon(text) {
		showSonosIcon = (text == "Yes");
   		saveSettings();
		if (showSonosIcon) {
			mediaTray.show();
		} else {
			mediaTray.hide();
		}
	}
	
	function saveSettings() {

		var tmpTrayIcon = "";
		if (showSonosIcon == true) {
			tmpTrayIcon = "true";
		} else {
			tmpTrayIcon = "false";
		}

		settings["showSonosIcon"] = tmpTrayIcon;
		settings["sonosName"] = sonosName;
		settings["path"] = connectionPath;

		var saveFile = new XMLHttpRequest();
		saveFile.open("PUT", "file:///mnt/data/tsc/sonos.userSettings.json");
		saveFile.send(JSON.stringify(settings));
	}
	
	//In this read function you'll find the execution of the visibility of the systray icon.
	function readSettings() {

		//read user settings

		var settingsString = sonosSettingsFile.read();
		settings = JSON.parse(settingsString);
		if (settings['showSonosIcon']) showSonosIcon = (settings['showSonosIcon'] == "true");
		if (settings['sonosName']) sonosName = (settings['sonosName']);
		if (settings['path']) {
			connectionPath = (settings['path']);
			if (connectionPath.length > 0) {
				var pathVar = connectionPath;
				var splitVar = pathVar.split(":")
				ipadresLabel = splitVar[0];
				poortnummer = splitVar[1];
			}
			updateAvailableZones();
		}
		console.log("********** Sonos - path:" + settings['path']);
	}
	

	//This part is to create the now playing image and to start all the functions which are required for using the sonos app correctly.
	//When you are playing radio (no playlist) it have to check the station name and not the "track" name thats why you'll find this check.
	function readSonosState() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					if (response['currentTrack']['type'] == "track"){
						actualTitle = response['currentTrack']['title'];
						actualArtist = response['currentTrack']['artist'];
						if ('absoluteAlbumArtUri' in response['currentTrack']) {
							var tmpNowPlayingImage = response['currentTrack']['absoluteAlbumArtUri'].replace("https://", "http://");
						} else {
							var tmpNowPlayingImage = "";
						}
						if (tmpNowPlayingImage !== nowPlayingImage) {
							nowPlayingImage = tmpNowPlayingImage;
						}
					}
					if (response['currentTrack']['type'] == "radio"){
						actualArtist = response['currentTrack']['stationName'];
						actualTitle = "";
						if (response['playbackState'] == "PLAYING") {
							actualTitle = response['currentTrack']['title'];
						} 
						if ('absoluteAlbumArtUri' in response['currentTrack']) {
							var tmpNowPlayingImage = response['currentTrack']['absoluteAlbumArtUri'].replace("https://", "http://");
						} else {
							var tmpNowPlayingImage = "";
						}
						if (tmpNowPlayingImage !== nowPlayingImage) {
							nowPlayingImage = tmpNowPlayingImage;
						}
					}
					if (actualTitle.substring(0,10) == "x-sonosapi") {
						actualTitle = "";
					}
					
					playbackState = response['playbackState'];
					shuffleButtonVisible = response['playMode']['shuffle'];
					shuffleOnButtonVisible = !shuffleButtonVisible;
					pauseButtonVisible = (playbackState == "PLAYING");
					playButtonVisible = !pauseButtonVisible;
				}
			}
		}
		xmlhttp.open("GET", "http://"+connectionPath+"/"+sonosName+"/state");
		xmlhttp.send();
	}

	//Required to use the Sonos HTTP API and to start every request in the functions.
	function simpleSynchronous(request) {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.open("GET", request, true);
		xmlhttp.timeout = 1500;
		xmlhttp.send();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					if (typeof(functie) !== 'undefined') {
						functie(parameter);
					}
				}
			}
		}
	}
	
	Timer {
		id: sonosPlayInfoTimer
		interval: 5000
		triggeredOnStart: true
		running: true
		repeat: true
		onTriggered: readSonosState()
	}
}
//created by Harmen Bartelink, further enhanced by Toonz