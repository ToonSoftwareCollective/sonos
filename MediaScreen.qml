import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: mediaScreen
	screenTitle: qsTr("Sonos")
	
	//Property's are required to manage the correct Sonos Device

	property string export_ip
	
	property int tempId
	property string playState
	property string shuffleMode
	property string itemType
	property int volumeState
	property alias queueTimerControl : queueTimer
	
	onCustomButtonClicked: {
		if (app.favoritesScreen) {
			 app.favoritesScreen.show();
		}
	}
	
	onHidden: {
		queueTimer.stop();
	}

	onShown: {
		addCustomTopRightButton("Favorieten");
		if (app.sonosName.length > 0) updateQueue();		
		//in the menuscreen you'll need to fill in your hostname and portnumber, if there is no device found you will have an popup that you have to correct your configuration
		if (app.sonosName.length < 1) {
			if (app.menuScreen)	
				app.menuScreen.show();
		}
		queueTimer.start();
	}
	
	//this popup is giving you the message that you have to correct your configuration in the menu screen.
	function showPopup() {
		qdialog.showDialog(qdialog.SizeLarge, qsTr("Informatie"), qsTr("U bent nu doorgestuurd naar het menuscherm omdat er of nog geen hostname en of poortnummer is ingevuld, of de Sonos HTTP Api werkt niet. <br><br> Check deze gegevens op het menuscherm waar u nu op terecht bent gekomen. ") , qsTr("Sluiten"));
	}


	//this is the item for the now playing image
	StyledRectangle {
		id: nowPlaying
		width: nowPlayingImage.width+6
		height: nowPlayingImage.height+6
		radius: 3
		color: colors.background
		opacity: ((nowPlayingImage.height > 0)? 1.0:0.0)
		shadowPixelSize: 1
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.leftMargin: isNxt ? 25 : 20
		anchors.topMargin: isNxt ? 62 : 50
		
		Image {
			id: nowPlayingImage
			source: app.nowPlayingImage
			fillMode: Image.PreserveAspectFit
			height: isNxt ? 250 : 200
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.leftMargin: 3
			anchors.topMargin: 3			
		}
		visible: (app.nowPlayingImage.length > 5)

	}
	
	//This is the text which is showing you the now playing artist and number
	Text {
		id: itemArtist

		text: app.actualArtist
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor

		wrapMode: Text.WordWrap
		horizontalAlignment: Text.AlignHCenter
		anchors {
			top: parent.top
			topMargin: isNxt ? 350 : 280
			left: parent.left
			leftMargin: isNxt ? 40 : 32
		}
		width: isNxt ? 250 : 200
	}

	Text {
		id: itemText

		text: app.actualTitle
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor

		wrapMode: Text.WordWrap
		horizontalAlignment: Text.AlignHCenter
		anchors {
			top: itemArtist.bottom
			topMargin: isNxt ? 5 : 4
			left: parent.left
			leftMargin: isNxt ? 40 : 32
		}
		width: isNxt ? 250 : 200
	}
	
	//below you'll find the iconbuttons which are controlling your device (previous, play/pause, shuffle on and shuffle off and the next button)
	IconButton {
		id: prevButton
		anchors {
			left: parent.left
			leftMargin: isNxt ? 62 : 50
			bottom: boilerScrollableSimpleList.bottom
		}

		iconSource: "qrc:/tsc/left.png"
		onClicked: {
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/previous");
		}
	}

	IconButton {
		id: pauseButton
		color: colors.background
		anchors {
			left: prevButton.right
			leftMargin: isNxt ? 10 : 7
			top: prevButton.top
		}

		iconSource: "qrc:/tsc/pause.png"
		onClicked: {
			app.playButtonVisible = false;
			app.pauseButtonVisible = false;
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/pause");
		}
		visible :  app.pauseButtonVisible
	}
	
	IconButton {
		id: playButton
		color: colors.background
		anchors {
			left: prevButton.right
			leftMargin: isNxt ? 10 : 7
			top: prevButton.top
		}

		iconSource: "qrc:/tsc/play.png"
		onClicked: {
			app.playButtonVisible = false;
			app.pauseButtonVisible = false;
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/play");
		}
		visible :  app.playButtonVisible
	}
	
	IconButton {
		id: shuffleOnButton
		anchors {
			left: playButton.right
			leftMargin: isNxt ? 10 : 7
			top: prevButton.top
		}

		iconSource: "qrc:/tsc/shuffle_on.png"
		onClicked: {
			app.shuffleButtonVisible = false;
			app.shuffleOnButtonVisible = false;
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/shuffle/off");
		}
		visible :  app.shuffleButtonVisible

	}
	IconButton {
		id: shuffleButton
		anchors {
			left: playButton.right
			leftMargin: isNxt ? 10 : 7
			top: prevButton.top
		}

		iconSource: "qrc:/tsc/shuffle.png"
		onClicked: {
			app.shuffleButtonVisible = false;
			app.shuffleOnButtonVisible = false;
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/shuffle/on");
		}
		visible :  app.shuffleOnButtonVisible
	}
	
	IconButton {
		id: nextButton
		anchors {
			left: shuffleButton.right
			leftMargin: isNxt ? 10 : 7
			top: prevButton.top
		}

		iconSource: "qrc:/tsc/right.png"
		onClicked: {
			console.log("next");
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/next");
		}
	}
	
	//this is the delegate of the playlist which is showed.
	Component {
		id: brandListDelegate
		//make it clickable
		Item {
			width: isNxt ? 500 : 400
			height: isNxt ? 50 : 40			
			MouseArea {
				id: mouse_area1
				z: 1
				anchors.fill: parent
				anchors.topMargin: -10
				onClicked: {
					app.actualArtist = app.queue[item]['artist'];
					app.actualTitle = app.queue[item]['name'];
					app.nowPlayingImage = "";
					tempId = item + 1;
					app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/trackseek/"+tempId);
				}
			}
			
			//artist and number which is showed in the playlist
			Text {
				id: listItemText

				text: app.queue[item]['name'] + " - " + app.queue[item]['artist']
				font.pixelSize: isNxt ? 20 : 16
				font.family: qfont.regular.name
				font.bold: (itemText.text == app.queue[item]['title']) ? true:false
				color: (itemText.text == app.queue[item]['title']) ? colors.wifiActiveNetwork:colors.foreground

				wrapMode: Text.WrapAnywhere
				maximumLineCount: 1
				elide: Text.ElideRight
				verticalAlignment: Text.AlignVCenter
				anchors {
					left: parent.left
					leftMargin: 10
				}
				width: isNxt ? boilerScrollableSimpleList.width - 50 : boilerScrollableSimpleList.width - 80
			}
		}
	}
	
	//property's of the scrollable list
	ScrollableSimpleList {
		id: boilerScrollableSimpleList
		width: isNxt ? 600 : 480
		height: isNxt ? 500 : 400
		itemsPerPage: 8
		delegate: brandListDelegate
		anchors.top: parent.top
		anchors.right: parent.right
		anchors.rightMargin: isNxt ? 75 : 60
		anchors.topMargin: 10

		Throbber {
			id: throbber
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: -26
				verticalCenter: parent.verticalCenter
			}
		}

		Text {
			id: noConnectionText
			visible: false
			anchors {
				horizontalCenter: parent.horizontalCenter
				horizontalCenterOffset: -26
				verticalCenter: parent.verticalCenter
			}
//			color: colors.taNoInternet
			font.family: qfont.italic.name
			font.pixelSize: isNxt ? 20 : 16
			text: qsTr("no-connection")
		}
	}
	
	
	//Below is the volume control part, first you find the volume up button
	IconButton {
		id: volumeUp
		anchors {
			top: nextButton.top
			left: nextButton.right
			leftMargin: isNxt ? 10 : 7
		}

		iconSource: "qrc:/tsc/volume_up.png"
		onClicked: {
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/volume/+5");
		}
	}
	
	
	//last of the volume part is the volume down button.
	IconButton {
		id: volumeDown
		anchors {
			top: prevButton.top
			right: prevButton.left
			rightMargin: isNxt ? 10 : 7
		}

		iconSource: "qrc:/tsc/volume_down.png"
		onClicked: {
			app.simpleSynchronous("http://"+app.connectionPath+"/"+app.sonosName+"/volume/-5");
		}
	}

	StandardButton {
		id: btnZone
		text: (app.sonoslist.length > 1) ? app.sonosName + "   (>>)" : app.sonosName
		fontPixelSize: isNxt ? 25 : 20
		anchors {
			bottom: nowPlaying.top
			bottomMargin: isNxt ? 7 : 5
			left: volumeDown.left
			right: volumeUp.right
		}
		onClicked: {
			if (app.mediaSelectZone)	
				app.mediaSelectZone.show();
		}
	}
	
	
	function pad(n, width) {
		n = n + '';
		return n.length >= width ? n : new Array(width - n.length + 1).join('0') + n;
	}

	//This function is to setup the playlist, export the information to: PlaylistItemsJS and configure the scrollable list (refresh and everything).
	function updateQueue() {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					if (itemType != "radio") {
						boilerScrollableSimpleList.removeAll();
						if (response.length > 0) {
							var tmpqueue = [];
							for (var i = 0; i < response.length; i++) {
								tmpqueue.push({"name": response[i]['title'], "artist": response[i]['artist'], "thumb": app.sonosIP+":1400" + response[i]['albumArtUri'],"title": response[i]['title']});
								boilerScrollableSimpleList.addDevice(i);
							}
							app.queue = tmpqueue;
							boilerScrollableSimpleList.refreshView();
							if (boilerScrollableSimpleList.currentPage == -1) {
								boilerScrollableSimpleList.scrollToPage(0);
							}
						} else {
							boilerScrollableSimpleList.addDevice(itemText.text);
						}
					}
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/"+app.sonosName+"/queue");
		xmlhttp.send();
	}
	
	Timer {
		id: queueTimer
		interval: 5000
		triggeredOnStart: true
		running: false
		repeat: true
		onTriggered: updateQueue()
	}
	
}

//created by Harmen Bartelink, further developed by Toonz
