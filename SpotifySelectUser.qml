import QtQuick 2.1
import qb.components 1.0
import BxtClient 1.0

Screen {
	id: spotifySelectUserScreen

	isSaveCancelDialog: true

	screenTitle: "Selecteer een bron voor de afspeellijsten"
	
	onHidden: queueTimer.stop();

	onShown: {
			radioButtonList.clearModel();
			radioButtonList.addItem("Sonos playlist");
			for (var i = 0; i < app.spotifyUserNames.length; i++) {
				radioButtonList.addItem("Spotify van "+ app.spotifyUserNames[i]);
			}
			radioButtonList.forceLayout();
			radioButtonList.currentIndex = app.selectedPlaylistUser
	}


	onSaved: {
		app.selectedPlaylistUser = radioButtonList.currentIndex
		if (radioButtonList.currentIndex == 0) {
			app.playlistSource = "Sonos"
		} else {
			app.playlistSource = app.spotifyUserNames[radioButtonList.currentIndex - 1]
		}
		app.saveSettings()
	}

	Text {
		id: headerText
		text: "Ga naar de Sonos tegel in het Toon menu om Spotify accounts toe te voegen."
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		anchors {
			top: parent.top
			topMargin: isNxt ? 25 : 20
			left: parent.left
			leftMargin: isNxt ? 125 : 100
		}
	}

	RadioButtonList {
		id: radioButtonList
		radioLabelWidth: isNxt ? 400 : 300
		anchors {
			horizontalCenter: parent.horizontalCenter
			top:headerText.bottom
		}
		title: "                       "

	}
}
