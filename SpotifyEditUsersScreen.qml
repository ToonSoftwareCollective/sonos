import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;

Screen {
	id: spotifyEditUsersScreen
	screenTitle: "Beheren Spotify account lijst"

	onShown: {
		initSourcesList();
	}

	function initSourcesList() {

		spotifyUserGroupModel.clear();
		for (var i = 0; i < app.spotifyUserIDs.length; i++) {
			spotifyUserGroupModel.append({name: app.spotifyUserNames[i], userid: app.spotifyUserIDs[i]});
		}
	}

	function saveSpotifyNameLabel(text) {

		if (text) {
			spotifyNameLabel.inputText = text;
		}
	}

	function saveSpotifyUserID(text) {

		if (text) {
			spotifyUserIDLabel.inputText = text;
		}
	}

	Text {
		id: headerText
		text: "Toevoegen nieuw Spotify account aan deze app:"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		anchors {
			top: parent.top
			left: parent.left
			leftMargin: isNxt ? 38 : 30
		}
	}

	EditTextLabel4421 {
		id: spotifyNameLabel
		width: isNxt ? 550 : 440
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 300 : 240
		leftText: "Naam Spotify account:"
		x: isNxt ? 38 : 30
		y: 10

		anchors {
			top: parent.top
			topMargin: isNxt ? 30 : 24
		}

		onClicked: {
			qkeyboard.open("Voer de displaynaam in van het nieuwe spoptify account", spotifyNameLabel.inputText, saveSpotifyNameLabel)
		}
	}

	IconButton {
		id: spotifyNameButton
		width: isNxt ? 50 : 40
		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: spotifyNameLabel.right
			leftMargin: 6
			top: spotifyNameLabel.top
		}

		bottomClickMargin: 3
		onClicked: {
			qkeyboard.open("Voer de displaynaam in van het nieuwe spotify account", spotifyNameLabel.inputText, saveSpotifyNameLabel)
		}
	}

	Text {
		id: infoText1
		text: "Naam van het account op de Toon"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		anchors {
			top: spotifyNameButton.top
			left: spotifyNameButton.right
			leftMargin: isNxt ? 38 : 30
		}
	}


	EditTextLabel4421 {
		id: spotifyUserIDLabel
		width: spotifyNameLabel.width
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 300 : 240
		leftText: "Spotify gebruikersnaam:"

		anchors {
			left: spotifyNameLabel.left
			top: spotifyNameLabel.bottom
			topMargin: 6
		}

		onClicked: {
			qkeyboard.open("Voer de Spotify gebruikersnaam in (34 karakters):", spotifyUserIDLabel.inputText, saveSpotifyUserID)
		}
	}


	IconButton {
		id: spotifyUserIDButton;
		width: isNxt ? 50 : 40
		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: spotifyUserIDLabel.right
			leftMargin: 6
			top: spotifyUserIDLabel.top
		}

		topClickMargin: 3
		onClicked: {
			qkeyboard.open("Voer de Spotify gebruikersnaam in (34 karakters):", spotifyUserIDLabel.inputText, saveSpotifyUserID)
		}
	}

	Text {
		id: infoText2
		text: "typisch 34 karakters lang"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		anchors {
			top: spotifyUserIDButton.top
			left: spotifyUserIDButton.right
			leftMargin: isNxt ? 38 : 30
		}
	}

	StandardButton {
		id: addNewSpotifyAccountButton
		width: isNxt ? 275 : 220
		height: isNxt ? 44 : 35
		radius: 5
		text: "Toevoegen Account"
		fontPixelSize: isNxt ? 25 : 20
		color: colors.background
		visible : ((spotifyUserIDLabel.inputText.length > 2) && (spotifyNameLabel.inputText.length > 2))

		anchors {
			top: spotifyUserIDButton.top
			left: spotifyUserIDButton.right
			leftMargin: isNxt ? 15 : 12
		}

		onClicked: {   //validate userid before adding

			var xmlhttpSpot = new XMLHttpRequest();	
			xmlhttpSpot.onreadystatechange=function() {
				if (xmlhttpSpot.readyState == 4) {
					if (xmlhttpSpot.status == 404) {
						qdialog.showDialog(qdialog.SizeLarge, "Foutmelding", "Spotify account niet gevonden, controleer de gebruikersnaam (string van 34 karakters)." , "Sluiten");
					}
					if (xmlhttpSpot.status == 200) {   //add user
						var tempNames = app.spotifyUserNames;
						var tempIDs = app.spotifyUserIDs;
						tempNames.push(spotifyNameLabel.inputText);
						tempIDs.push(spotifyUserIDLabel.inputText);
						app.spotifyUserNames= tempNames;
						app.spotifyUserIDs= tempIDs;
						app.saveSettings();
						initSourcesList();
					}
				}
			}
			xmlhttpSpot.open("GET", "https://api.spotify.com/v1/users/" + spotifyUserIDLabel.inputText + "/playlists");
                	xmlhttpSpot.setRequestHeader("Authorization", 'Bearer ' + app.spotifyToken["access_token"]);
			xmlhttpSpot.send();
		}
	}

	Text {
		id: gridText
		text: "Klik op een bestaand account om uit deze app te verwijderen:"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		anchors {
			top: spotifyUserIDLabel.bottom
			topMargin: isNxt ? 25 : 20
			left: spotifyUserIDLabel.left
		}
	}

	ControlGroup {
		id: spotifyUserGroup
		exclusive: false
	}

	GridView {
		id: spotifyUserGroupGridView

		model: spotifyUserGroupModel
		delegate: SpotifyEditUsersScreenDelegate {onRefreshUsersList: initSourcesList()}


		interactive: false
		flow: GridView.TopToBottom
		cellWidth: isNxt ? 320 : 250
		cellHeight: isNxt ? 44 : 36
		height: isNxt ? parent.height - 150 : parent.height - 120
		width: parent.width
		anchors {
			top: spotifyUserIDLabel.bottom
			topMargin: isNxt ? 50 : 40
			left: spotifyUserIDLabel.left

		}
	}

	ListModel {
		id: spotifyUserGroupModel
	}
}
