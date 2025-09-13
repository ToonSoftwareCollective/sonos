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
	property url trayUrl : "MediaTray.qml"
	property url menuScreenUrl : "MenuScreen.qml"
	property url messageScreenUrl : "MessageScreen.qml"
	property url mediaSelectZoneUrl : "MediaSelectZone.qml"
	property url spotifySelectUserUrl : "SpotifySelectUser.qml"
	property url tileUrl : "SonosTile.qml"
	property url tileUrlControl : "SonosMiniControlTile.qml"
	property url thumbnailIcon: "qrc:/tsc/SonosThumb.png"
	property url spotifyEditUsersScreenUrl : "SpotifyEditUsersScreen.qml"
	property url spotifyCredentialsScreenUrl : "SpotifyCredentialsScreen.qml"
	property SpotifyEditUsersScreen spotifyEditUsersScreen 
	property SpotifyCredentialsScreen spotifyCredentialsScreen 
	property MenuScreen menuScreen
	property MediaScreen mediaScreen
	property MessageScreen messageScreen
	property MediaSelectZone mediaSelectZone
	property FavoritesScreen favoritesScreen
	property SpotifySelectUser spotifySelectUser


	//next property's are used for the visibility of the systray icon.
	property SystrayIcon mediaTray
	property bool showSonosIcon : true
	property bool playFootballScores : true
	property string playbackState
	property string timeStr
	property string dateStr
	property variant playlists : []
	property variant playlistsURI : []
	property variant favourites : []
	property variant queue : []
	property variant sonoslist : []
	property variant spotifyUserNames : []
	property variant spotifyUserIDs : []
	property string spotifyStatus : "toBeConfigured"
	property bool showSpotifyConfigMessage  : true

	property int selectedPlaylistUser : 0  // (0 = Sonos, >0 is a Spotify user account)

	property string playlistSource : ""
	property string sonosName
	property string sonosNameVoetbalApp
	property string zoneToSelect
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
			"sonosNameVoetbalApp" : "",
			"path" : "",
			"messageText" : "",
			"messageVolume" : "",
			"messageSonosName" : "",
			"voetbalTussenstanden" : "",
			"selectedPlaylistUser" : 0,
			"spotifyUserNames" : [],
			"spotifyUserIDs" : [],
			"spotifyStatus" : "",
			"spotifyClientId" : "",
			"spotifyClientSecret" : ""
		}

	property variant spotifyToken : {
			"spotifyClientId" : "",
			"spotifyClientSecret" : "",
			"access_token" : ""
		}
	property string musicSource : "Sonos"   // either "Sonos"or "Spotify"

		// variables for playing the selected text
	property variant messageTextArray : ["Hallo","Hallo daar, het eten staat klaar"]
	property string messageSonosName : "Alle"
	property int messageVolume : 20
	property string messageText
	property int trackDuration
	property int trackElapsedTime 
	property bool showSlider : false
	property bool showSliderTime : false


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
		registry.registerWidget("screen", messageScreenUrl, this, "messageScreen");
		registry.registerWidget("screen", spotifySelectUserUrl, this, "spotifySelectUser");
		registry.registerWidget("screen", mediaSelectZoneUrl, this, "mediaSelectZone");
		registry.registerWidget("screen", spotifyEditUsersScreenUrl, this, "spotifyEditUsersScreen");
		registry.registerWidget("screen", spotifyCredentialsScreenUrl, this, "spotifyCredentialsScreen");
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

	//this is the save of the voetbal toggle which could be found in the menuscreen.
	function saveplayScores(text) {
		playFootballScores = (text == "Yes");
   		saveSettings();
	}
	
	function saveSettings() {

		var tmpTrayIcon = "";
		if (showSonosIcon == true) {
			tmpTrayIcon = "true";
		} else {
			tmpTrayIcon = "false";
		}
		var tmpVoetbal = "";
		if (playFootballScores == true) {
			tmpVoetbal = "true";
		} else {
			tmpVoetbal = "false";
		}

		settings["showSonosIcon"] = tmpTrayIcon;
		settings["sonosName"] = sonosName;
		settings["sonosNameVoetbalApp"] = sonosNameVoetbalApp;
		settings["path"] = connectionPath;
		settings["messageText"] = messageTextArray;
		settings["messageSonosName"] = messageSonosName;
		settings["messageVolume"] = messageVolume;
		settings["voetbalTussenstanden"] = tmpVoetbal;
		settings["selectedPlaylistUser"] = selectedPlaylistUser;
		settings["spotifyUserNames"] = spotifyUserNames;
		settings["spotifyUserIDs"] = spotifyUserIDs;
		settings["spotifyStatus"] = spotifyStatus;
		settings["spotifyClientId"] = spotifyToken["spotifyClientId"]
		settings["spotifyClientSecret"] = spotifyToken["spotifyClientSecret"]

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
		if (settings['sonosNameVoetbalApp']) sonosNameVoetbalApp = (settings['sonosNameVoetbalApp']);
		if (settings['messageVolume']) messageVolume = (settings['messageVolume']);
		if (settings['messageSonosName']) messageSonosName = (settings['messageSonosName']);
		if (settings['messageText']) messageTextArray = (settings['messageText']);
		if (settings['voetbalTussenstanden']) playFootballScores = (settings['voetbalTussenstanden'] == "true");
		if (settings['selectedPlaylistUser']) selectedPlaylistUser = settings['selectedPlaylistUser'];
		if (selectedPlaylistUser == 0) {
			musicSource = "Sonos"
		} else {
			musicSource = "Spotify"
		}
		if (settings['spotifyUserNames']) spotifyUserNames= settings['spotifyUserNames'];
		if (settings['spotifyUserIDs']) spotifyUserIDs= settings['spotifyUserIDs'];
		if (settings['spotifyStatus']) spotifyStatus= settings['spotifyStatus'];
		if (settings['spotifyClientId']) spotifyToken["spotifyClientId"] = settings['spotifyClientId'];
		if (settings['spotifyClientSecret']) spotifyToken["spotifyClientSecret"] = settings['spotifyClientSecret'];

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
		if (spotifyStatus == "configured") getSpotifyBearerToken();
	}


		//This part is to create the now playing image and to start all the functions which are required for using the sonos app correctly.
		//When you are playing radio (no playlist) it have to check the station name and not the "track" name thats why you'll find this check.

	function getSpotifyBearerToken() {

		var xmlhttpSpot = new XMLHttpRequest();
		xmlhttpSpot.onreadystatechange=function() {
			if (xmlhttpSpot.readyState == 4) {
				if (xmlhttpSpot.status == 200) {
					var response = JSON.parse(xmlhttpSpot.responseText);
					spotifyToken["access_token"] = response["access_token"];
				}
			}
		}
		xmlhttpSpot.open("POST", "https://accounts.spotify.com/api/token");
                xmlhttpSpot.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                xmlhttpSpot.setRequestHeader("Authorization", 'Basic ' + customBtoa(spotifyToken["spotifyClientId"] + ":" + spotifyToken["spotifyClientSecret"]));
		xmlhttpSpot.send('grant_type=client_credentials');
		tokenRefreshTimer.stop()
		tokenRefreshTimer.interval = 3599000;
		tokenRefreshTimer.start()
	}
 

	function customBtoa(str) {
  		const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  		let encoded = '';
  		let i = 0;

  		while (i < str.length) {
  			const c1 = str.charCodeAt(i++);
    			const c2 = str.charCodeAt(i++);
    			const c3 = str.charCodeAt(i++);

    			const e1 = c1 >> 2;
    			const e2 = ((c1 & 3) << 4) | (c2 >> 4);
    			const e3 = ((c2 & 15) << 2) | (c3 >> 6);
    			const e4 = c3 & 63;

    			if (isNaN(c2)) {
      				encoded += chars.charAt(e1) + chars.charAt(e2) + '==';
    			} else if (isNaN(c3)) {
      				encoded += chars.charAt(e1) + chars.charAt(e2) + chars.charAt(e3) + '=';
    			} else {
      				encoded += chars.charAt(e1) + chars.charAt(e2) + chars.charAt(e3) + chars.charAt(e4);
    			}
  		}

  		return encoded;
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
						showSlider = true;
						showSliderTime = true;
						actualArtist = "";
						actualTitle = "";
						if (response['currentTrack']['title']) actualTitle = response['currentTrack']['title'];
						if (response['currentTrack']['artist']) actualArtist = response['currentTrack']['artist'];
						if (response['currentTrack']['duration']) trackDuration = response['currentTrack']['duration'];
						if (response['elapsedTime']) {
							if (!mediaScreen.positionIndicatorDragActive) { //do not update elapsedTime when positionIndicator is being dragged
								trackElapsedTime = response['elapsedTime'];
								mediaScreen.positionIndicatorX = Math.floor((trackElapsedTime / trackDuration) * mediaScreen.positionIndicatorWidth);
							}
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
					if (response['currentTrack']['type'] == "radio"){
						showSlider = false;
						showSliderTime = false;
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
					if (pauseButtonVisible) {
						sonosTrackTimer.start()
					} else {
						sonosTrackTimer.stop()
					} 
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
	
	function deleteSpotifyAccount(itemIndex) {


		// delete the item at index itemIndex from both arrays		
		var tmpNames = [];
		var tmpIDs = [];

		for (var i = 0; i < spotifyUserNames.length; i++) {
		if (i !== itemIndex) {		// skip the item to be deleted
				tmpNames.push(spotifyUserNames[i]);
				tmpIDs.push(spotifyUserIDs[i]);
			}
		}
		spotifyUserNames= tmpNames;
		spotifyUserIDs = tmpIDs;
		selectedPlaylistUser = 0; //default back to Sonos playlist
		saveSettings()
	}

	function addTrackTimer() {
		trackElapsedTime = trackElapsedTime + 1;
		if (trackElapsedTime > trackDuration) trackElapsedTime = trackDuration;
		mediaScreen.positionIndicatorX = Math.floor((trackElapsedTime / trackDuration) * mediaScreen.positionIndicatorWidth);

	}

	
	Timer {
		id: tokenRefreshTimer // Tokens valid only for 1 hour
		triggeredOnStart: false
		running: true
		repeat: true
		onTriggered: getSpotifyBearerToken()
	}

	Timer {
		id: sonosPlayInfoTimer
		interval: 5000
		triggeredOnStart: true
		running: true
		repeat: true
		onTriggered: readSonosState()
	}
	
	Timer {
		id: sonosTrackTimer
		interval: 1000
		triggeredOnStart: false
		running: false 
		repeat: true
		onTriggered: addTrackTimer()
	}
}
//created by Harmen Bartelink, further enhanced by Toonz
