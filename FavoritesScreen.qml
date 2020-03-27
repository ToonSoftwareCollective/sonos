import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: favoritesScreen
	screenTitleIconUrl: "qrc:/tsc/Sonos_Favorites.png";
	screenTitle: "Sonos Favorieten";
	hasHomeButton: false

	property int counterFav
	property int counterList
	property string tempId
	property string lineinUrl
	property string stationName
	
	onHidden: {
		screenStateController.screenColorDimmedIsReachable = true;
		sonosUpdateFavoriteList.running = false;
	}

	onCustomButtonClicked: {
		if (app.messageScreen) {
			 app.messageScreen.show();
		}
	}
	

	onShown: {
		addCustomTopRightButton("Audiobericht");	
		screenStateController.screenColorDimmedIsReachable = false;
		pageThrobber.visible = true;
		//One timer which is used for automaticly update the favorite list, which could be find below in the function description.
		sonosUpdateFavoriteList.running = true;
		updateFavoriteslist();
		updateLinein();
		stationNameCheck();
		updatePlaylists();
	}
	
	//Required to use the Sonos HTTP API and to start every request in the functions.
	function simpleSynchronous(request) {
		pageThrobber.visible = true;
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.open("GET", request, true);
		xmlhttp.timeout = 1500;
		xmlhttp.send();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					pageThrobber.visible = false;
					if (typeof(functie) !== 'undefined') {
						functie(parameter);
					}
				}
			}
		}
	}
	
	//if the connection is not available or is still loading a page throbber will be visible in the scrollable list.
	Throbber {
		id: pageThrobber
		visible: true
		z: isNxt ? 25 : 20
		anchors {
			horizontalCenter: parent.horizontalCenter
			verticalCenter: parent.verticalCenter
		}
	}
	
	//this text shows the counter above the scrollable list.
	Text {
		id: chooseText

		text: counterFav + " favorieten:"
		font.pixelSize: isNxt ? 20 : 16

		font.family: qfont.regular.name
		font.bold: true

		wrapMode: Text.WordWrap
		anchors {
			top: boilerScrollableSimpleList.top
			topMargin: isNxt ? -35 : -28
			left: boilerScrollableSimpleList.left
		}
		width: 450
	}
	Text {
		id: chooseText2

		text: counterList + " afspeellijsten:"	
		font.pixelSize: isNxt ? 20 : 16

		font.family: qfont.regular.name
		font.bold: true

		wrapMode: Text.WordWrap
		anchors {
			top: playlistScrollableSimpleList.top
			topMargin: isNxt ? -35 : -28
			left: playlistScrollableSimpleList.left
		}
		width: 450
	}
	
	//the function "updateLinein" is creating lineinURL which is needed to change the source to Line In (input device for sonos Playbar)
	IconButton {
		id: inputButton
		anchors.top: parent.top
		anchors.right: refreshButton.left
		anchors.rightMargin: 10
		anchors.topMargin: isNxt ? 20 : 16
		iconSource: "qrc:/tsc/input.png"
		onClicked: {
			simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/setavtransporturi/x-sonos-htastream:"+lineinUrl+":spdif")
		}
	}
	
	//just refreshing manual the scrollable list.
	IconButton {
		id: refreshButton
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.rightMargin: isNxt ? 80 : 64
		anchors.topMargin: isNxt ? 20 : 16
		iconSource: "qrc:/tsc/refresh.png"
		onClicked: {
			updateFavoriteslist();
			updatePlaylists();
		}
	}
	
	//This is the delegate of the scrollable list which have the input of the function "updateFavoriteslist"
	Component {
		id: brandListDelegate
		//to make the list clickable
		Item {
			width: isNxt ? 450 : 360
			height: isNxt ? 50 : 40	
			MouseArea {
				id: mouse_area1
				z: 1
				anchors.fill: parent
				anchors.topMargin: isNxt ? -12 : -10
				onClicked: {
					tempId = app.favourites[item]['name'];
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/clearqueue");
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/favorite/"+tempId);
					hide();
				}
			}
			
			Text {
				id: listItemText

				text: app.favourites[item]['name']
				font.family: qfont.regular.name
				font.pixelSize: isNxt ? 20 : 16
				font.bold: ((stationName == app.favourites[item]['name'])? true:false)
				
				wrapMode: Text.WrapAnywhere
				maximumLineCount: 1
				verticalAlignment: Text.AlignVCenter
				anchors {
					left: parent.left
					leftMargin: isNxt ? 20 : 16
					top: parent.top
					topMargin: isNxt ? 20 : 16
				}
				width: boilerScrollableSimpleList.width - 150
			}
			/*
			Timer {
						interval: 1000; running: true; repeat: true
						onTriggered: time.text = Date().toString()
			}
			*/
		}
	}
	//Property's for the scrollable list it self.
	ScrollableSimpleList {
		id: boilerScrollableSimpleList
		width: isNxt ? 450 : 360
		height: isNxt ? 420 : 336
		x: isNxt ? 30 : 25

		itemsPerPage: 7
		delegate: brandListDelegate
		anchors {
			top: refreshButton.bottom
			topMargin: isNxt ? 12 : 10
		}

		Throbber {
			id: throbber
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: isNxt ? -30 : -25
				verticalCenter: parent.verticalCenter
			}
		}

		Text {
			id: noConnectionText
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: isNxt ? -30 : -25

				verticalCenter: parent.verticalCenter
			}
			font.family: qfont.italic.name
			font.pixelSize: isNxt ? 20 : 16
			text: qsTr("no-connection")
		}
	}
	
	//both functions below are required for the scrollable list
	function pad(n, width) {
		n = n + '';
		return n.length >= width ? n : new Array(width - n.length + 1).join('0') + n;
	}

	function objToString (obj) {
			var str = '';
			for (var p in obj) {
				if (obj.hasOwnProperty(p)) {
					str += p + '::' + obj[p] + '\n';
				}
			}
			return str;
		}
	
	//This is the delegate of the scrollable list which have the input of the function "updateFavoriteslist"
	Component {
		id: playlistDelegate
		//to make the list clickable
		Item {
			width: isNxt ? 450 : 360
			height: isNxt ? 50 : 40	
			MouseArea {
				id: mouse_area1
				z: 1
				anchors.fill: parent
				anchors.topMargin: isNxt ? -12 : -10
				onClicked: {
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/clearqueue");
					simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/playlist/"+listItemText.text);
				}
			}
			
			Text {
				id: listItemText

				text: app.playlists[item]['name']
				font.family: qfont.regular.name
				font.pixelSize: isNxt ? 20 : 16
				
				wrapMode: Text.WrapAnywhere
				maximumLineCount: 1
				verticalAlignment: Text.AlignVCenter
				anchors {
					left: parent.left
					leftMargin: isNxt ? 20 : 16
					top: parent.top
					topMargin: isNxt ? 20 : 16
				}
				width: boilerScrollableSimpleList.width - 150
			}
		}
	}
	//Property's for the scrollable list it self.

	ScrollableSimpleList {
		id: playlistScrollableSimpleList
		width: isNxt ? 450 : 360
		height: isNxt ? 420 : 336
		x: isNxt ? 510 : 425
		itemsPerPage: 7
		delegate: playlistDelegate
		anchors {
			top: refreshButton.bottom
			topMargin: isNxt ? 12 : 10
		}
		Throbber {
			id: throbberPL
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: isNxt ? -30 : -25
				verticalCenter: parent.verticalCenter
			}
		}

		Text {
			id: noConnectionText2
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: isNxt ? -30 : -25
					verticalCenter: parent.verticalCenter
			}
			font.family: qfont.italic.name
			font.pixelSize: isNxt ? 20 : 16
			text: qsTr("no-connection")
		}
	}

	
	//Fill the file: FavoriteslistItemsJS with only the item "Name" and also manage a little bit the scrollable list (with refreshing it). This has also the counter function.
	function updateFavoriteslist() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
						boilerScrollableSimpleList.removeAll();
						stationNameCheck();
						if (response.length > 0) {
							var tmpfavourites = [];
							for (var i = 0; i < response.length; i++) {
								tmpfavourites.push({"name": response[i]}); 
								boilerScrollableSimpleList.addDevice(i);
							}
							app.favourites = tmpfavourites;
							boilerScrollableSimpleList.refreshView();
							if (boilerScrollableSimpleList.currentPage == -1) {
								boilerScrollableSimpleList.scrollToPage(0);
							}
						} 
						counterFav = response.length;
					}
				}
			}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/favorites");
		xmlhttp.send();
	}
	
	//Fill the file: FavoriteslistItemsJS with only the item "Name" and also manage a little bit the scrollable list (with refreshing it). This has also the counter function.
	function updatePlaylists() {

		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
						playlistScrollableSimpleList.removeAll();
						if (response.length > 0) {
							var tmpplaylists = [];
							for (var i = 0; i < response.length; i++) {
								tmpplaylists.push({"name": response[i]}); 
								playlistScrollableSimpleList.addDevice(i);
							}
							app.playlists = tmpplaylists;
							playlistScrollableSimpleList.refreshView();
							if (playlistScrollableSimpleList.currentPage == -1) {
								playlistScrollableSimpleList.scrollToPage(0);
							}
						} 
						pageThrobber.visible = false;
						counterList = response.length;

					}
				}
			}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/playlists");
		xmlhttp.send();
	}
	
	//if the station name is equal to the now playing it will be visible in the scrollable list.
	function stationNameCheck() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					stationName = response['currentTrack']['stationName'];
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/"+app.sonosName+"/state");
		xmlhttp.send();
	}
	
	//Linein URL is important to have the possibility for changing the source to line in (like your TV or something which is plugged in to your playbar)
	function updateLinein() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
						for (var i = 0; i < response.length; i++) {
							if (response[i]['coordinator']['roomName'] == app.sonosName) {
								lineinUrl = response[i]['coordinator']['coordinator'];
							}
						
					}
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/zones");
		xmlhttp.send();
	}
	
	//Timer as described in the "On Shown"
	Timer {
		id: sonosUpdateFavoriteList
		interval: 7000
		triggeredOnStart: true
		running: false
		repeat: true
		onTriggered: updateFavoriteslist()
	}
}

//created by Harmen Bartelink
