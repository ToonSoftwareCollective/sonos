import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;

Screen {
	id: mediaSelectZoneScreen
	screenTitle: "Audioberichten"

	onShown: {
		updateZones();
		fillEffectsList();
	}

	function fillEffectsList() {
		// fill favourites list
		favouritesScrollableSimpleList.removeAll();
		console.log("********** Sonos: array length:" + app.messageTextArray.length);
		for (var i = 0; i < app.messageTextArray.length; i++) {
			favouritesScrollableSimpleList.addDevice(app.messageTextArray[i]);
			console.log("********** Sonos: array adding:" + app.messageTextArray[i]);
		}
		favouritesScrollableSimpleList.refreshView();
	}

	function updateZones() {

		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					if (response.length > 0) {
						zoneNameModel.clear();
						zoneNameModel.append({zoneName: "Alle"});
						for (var i = 0; i < response.length; i++) {
							zoneNameModel.append({zoneName: response[i]["coordinator"]["roomName"]});
						}
					} 
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/zones");
		xmlhttp.send();
	}

	function removeText(item) {
		var i = app.messageTextArray.indexOf(item);
		if (i > -1) {
  			app.messageTextArray.splice(i, 1);
		}
		app.saveSettings();
		fillEffectsList();
	}

	function saveText(text) {
		if (text) {
			saveTextNameLabel.inputText = text;
			app.messageTextArray.push(text);
			app.saveSettings();
		}
	}


	Text {
		id: txtBox

		text: "Selekteer een zone:"
		height: isNxt ? 35 : 28
		font.pixelSize: isNxt ? 25 : 20
		font.family: qfont.regular.name
		font.bold: true
		color: colors.tileTextColor
		width: isNxt ? 250 : 200
		anchors.top: parent.top
		anchors.topMargin : 10
		anchors.left: parent.left
		anchors.leftMargin : isNxt ? 25 : 20
	}

	ControlGroup {
		id: zoneGroup
		exclusive: false
	}

	GridView {
		id: zoneGridView

		model: zoneNameModel
		delegate: MessageScreenDelegate {}

		interactive: false
		flow: GridView.TopToBottom
		cellWidth: isNxt ? 320 : 250
		cellHeight: isNxt ? 50 : 40

		anchors {
			fill: parent
			top: txtBox.bottom
			left: txtBox.left
			topMargin: isNxt ? 50 : 40
		}
	}

	EditTextLabel4421 {
		id: saveTextNameLabel
		width: favouritesScrollableSimpleList.width
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 200 : 160
		leftText: "Nieuwe Tekst:"
		anchors {
			left: txtBox.left
			leftMargin: isNxt ? 375 : 300
			top: txtBox.top
			topMargin: isNxt ? 40 : 32

		}

		onClicked: {
			qkeyboard.open("Naam favouriet:", saveTextNameLabel.inputText, saveText);
		}
	}

	ListModel {
		id: zoneNameModel
	}

	// favourites Message list

	//this is the delegate of the saved messages
	Component {
		id: favouritesDelegate
		//make it clickable
		Item {
			width: isNxt ? 500 : 400
			height: isNxt ? 50 : 40		
			
			//name and number showed in the playlist
			
			StandardButton {
				id: listItemText

				text: item
				width: isNxt ? parent.width - 50 : parent.width - 40
				anchors {
					top: parent.top
					left: parent.left
					topMargin: 10
				}
				onClicked: {
					var xmlhttp = new XMLHttpRequest();
					if (app.messageSonosName == "Alle") {
						xmlhttp.open("GET", "http://"+app.connectionPath+"/sayall/" + item + "/nl-nl/20");
					} else {
						xmlhttp.open("GET", "http://"+app.connectionPath+"/"+app.messageSonosName+"/say/" + item + "/nl-nl/20");
					}
					xmlhttp.onreadystatechange=function() {
						if (xmlhttp.readyState == 4) {
							if (xmlhttp.status == 200) {
								var messageResponse = "Fout in versturen bericht";
								var response = JSON.parse(xmlhttp.responseText);
								if (response['status']) {
									if (response['status'] == "success") {
										messageResponse = "Bericht succesvol afgespeeld";
									}
								}
								qdialog.showDialog(qdialog.SizeSmall, "Sonos mededeling", messageResponse, "Sluiten");
							}
						}
					}
					xmlhttp.send();
				}
			}

			IconButton {
				id: deleteIcon
				width: 40
				iconSource: "qrc:/tsc/icon_delete.png"

				anchors {
					left: listItemText.right
					leftMargin: 10
					top: listItemText.top
				}

				bottomClickMargin: 3
				onClicked: removeText(item)
			}
		}
	}
	
	//property's of the scrollable list
	ScrollableSimpleList {
		id: favouritesScrollableSimpleList
		width: isNxt ? 600 : 480
		height: isNxt ? 375 : 300
		itemsPerPage: 6
		delegate: favouritesDelegate
		anchors.top: saveTextNameLabel.bottom
		anchors.right: saveTextNameLabel.right
		anchors.topMargin: isNxt ? 25 : 20
	}
}