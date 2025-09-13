import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;

Screen {
	id: spotifyCredentialsScreen
	screenTitle: "Configureren Spotify link"

	onShown: {
		spotifyClientIdLabel.inputText = app.spotifyToken["spotifyClientId"];
		spotifyClientSecretLabel.inputText = app.spotifyToken["spotifyClientSecret"];
	}

	function saveSpotifyClientIdLabel(text) {

		if (text) {
			app.spotifyToken["spotifyClientId"] = text;
			spotifyClientIdLabel.inputText = text;
		}
	}

	function saveSpotifyClientSecretLabel(text) {

		if (text) {
			app.spotifyToken["spotifyClientSecret"] = text;
			spotifyClientSecretLabel.inputText = text;
		}
	}

	function validateCredentials() {


		var xmlhttpSpot = new XMLHttpRequest();
		xmlhttpSpot.onreadystatechange=function() {
			if (xmlhttpSpot.readyState == 4) {
				if (xmlhttpSpot.status == 200) {
					var response = JSON.parse(xmlhttpSpot.responseText);
					if (response["access_token"]) {
						app.spotifyToken["access_token"] = response["access_token"];
						app.spotifyStatus = "configured";
						app.saveSettings();
						qdialog.showDialog(qdialog.SizeLarge, "Spotify configuratie", "De connectie met Spotify is succesvol getest. U kunt nu via het Sonos menu item meerdere spotify accounts toevoegen." , "Sluiten");
						app.getSpotifyBearerToken();
						hide();
					}
				}
				if (xmlhttpSpot.status == 400) {
					var response = JSON.parse(xmlhttpSpot.responseText);
					if (response["error"]) {
						qdialog.showDialog(qdialog.SizeLarge, "Spotify configuratie", "De connectie met Spotify is niet gelukt. Controleer het ClientId en de ClientSecret." , "Sluiten");
					}
				}
			}
		}
		xmlhttpSpot.open("POST", "https://accounts.spotify.com/api/token");
                xmlhttpSpot.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                xmlhttpSpot.setRequestHeader("Authorization", 'Basic ' + app.customBtoa(app.spotifyToken["spotifyClientId"] + ":" + app.spotifyToken["spotifyClientSecret"]));
		xmlhttpSpot.send('grant_type=client_credentials');
	}

	Text {
		id: headerText
		text: "Invoer Spotify app credentials:"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		anchors {
			top: parent.top
			left: parent.left
			leftMargin: isNxt ? 38 : 30
		}
	}

	EditTextLabel4421 {
		id: spotifyClientIdLabel
		width: isNxt ? 625 : 500
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 200 : 160
		leftText: "Client Id:"
		x: isNxt ? 38 : 30
		y: 10

		anchors {
			left: headerText.left
			top: parent.top
			topMargin: isNxt ? 30 : 24
		}

		onClicked: {
			qkeyboard.open("Voer de client Id in", spotifyClientIdLabel.inputText, saveSpotifyClientIdLabel)
		}
	}

	IconButton {
		id: spotifyClientIdLabelButton;
		width: isNxt ? 50 : 40
		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: spotifyClientIdLabel.right
			leftMargin: 6
			top: spotifyClientIdLabel.top
		}

		bottomClickMargin: 3
		onClicked: {
			qkeyboard.open("Voer de client Id in", spotifyClientIdLabel.inputText, saveSpotifyClientIdLabel)
		}
	}


	EditTextLabel4421 {
		id: spotifyClientSecretLabel
		width: spotifyClientIdLabel.width
		height: isNxt ? 44 : 35
		leftTextAvailableWidth: isNxt ? 200 : 160
		leftText: "Client Secret:"

		anchors {
			left: spotifyClientIdLabel.left
			top: spotifyClientIdLabel.bottom
			topMargin: 6
		}

		onClicked: {
			qkeyboard.open("Voer de client Id in", spotifyClientSecretLabel.inputText, saveSpotifyClientSecretLabel)
		}
	}


	IconButton {
		id: spotifyClientSecretLabelButton;
		width: isNxt ? 50 : 40
		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: spotifyClientSecretLabel.right
			leftMargin: 6
			top: spotifyClientSecretLabel.top
		}

		topClickMargin: 3
		onClicked: {
			qkeyboard.open("Voer de client Id in", spotifyClientSecretLabel.inputText, saveSpotifyClientSecretLabel)
		}
	}

	StandardButton {
		id: editSpotifyCredentialsButton
		width: isNxt ? 375 : 300
		radius: 5
		text: "Valideer gegevens"
		fontPixelSize: isNxt ? 25 : 20
		color: colors.background
		anchors {
			top: spotifyClientSecretLabel.bottom
			topMargin: 20
			left: spotifyClientSecretLabel.left
		}
		visible: (app.spotifyStatus !== "configured")
		onClicked: {
			validateCredentials()
		}
	}

	Text {
		id: explainerText
		text: 	"1: Ga met een browser naar https://developer.spotify.com/\n" +
			"2: Log in met je eigen Spotify account\n" + 
			"3: Klik op je inlognaam rechtsboven en ga naar het Dashboard\n" + 
			"4: Klik op de knop 'Create App'\n" + 
			"5: Vul in : App name, bijvoorbeeld 'Toon Sonos client' en een 'App description'\n" + 
			"6: Vul een 'Redirect URL'in , maakt niet uit wat, bijvoorbeeld: https://localhost:8080\n" +
			"7: Selekteer de checkbox Web API\n" +
			"8: Ga akkoord met de 'terms of service'\n" +
			"9: Druk op 'Save'\n" +
			"10: Je krijgt nu een scherm met basic information waaronder het Client Id.\n" +
			"11: Click op de link 'View client secret' om de Client Secret te tonen\n" +
			"12: Vul beide velden in hier op de Toon en druk op 'Valideer gegevens'"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 15 : 12
		anchors {
			top: editSpotifyCredentialsButton.bottom
			left: editSpotifyCredentialsButton.left
			topMargin: isNxt ? 38 : 30
		}
	}


}
