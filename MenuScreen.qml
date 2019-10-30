import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: root
	screenTitle: qsTr("Sonos Instellingen")
	
	onHidden: {
		screenStateController.screenColorDimmedIsReachable = true;
	}
	
	onShown: {
		showSonosIconToggle.isSwitchedOn = app.showSonosIcon;
		addCustomTopRightButton("Check Connection");
		if (poortnummerLabel.inputText.length < 1) poortnummerLabel.inputText = "5005";
	}

	onCustomButtonClicked: {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					var response = JSON.parse(xmlhttp.responseText);
					if (response.length > 0) {
						app.sonosName = response[0]["coordinator"]["roomName"];
						hide();
						if (response.length > 1) {
							app.mediaSelectZone.show();
						}
					} 
				}
			}
		}
		xmlhttp.open("GET", "http://"+app.connectionPath+"/zones");
		xmlhttp.send();
	}

	//Next part is to have the possibility to use the keyboard for the Hostname/IP Address field and also for the portnumber!
	QtObject {
		id: p
		property int _IP_KEYBOARD: 1
		property int _PORTNUMBER_KEYBOARD: 2
	}

	function openKeyboard(location) {
		if (location === p._PORTNUMBER_KEYBOARD) {
			qkeyboard.open(qsTr("voer hier de poort in"), poortnummerLabel.inputText, savePoortnummer);
		} else {
			if (ipadresLabel.inputText)
				qkeyboard.open(qsTr("Voer hier uw hostname of ip-adres in"), ipadresLabel.inputText, saveIpadres);
			else
				qkeyboard.open(qsTr("Voer hier uw hostname of ip-adres in"), "", saveIpadres);
		}
	}
	
	function saveIpadres(text) {
		if (text) {
			ipadresLabel.inputText = text;
			savepath();
		}
	}

	function savePoortnummer(text) {
		if (text) {
			poortnummerLabel.inputText = text;
			savepath();
		}
	}

	function savepath(){
		var str = ipadresLabel.inputText + ":" + poortnummerLabel.inputText;
		app.connectionPath = str;
		var doc2 = new XMLHttpRequest();
			doc2.onreadystatechange = function() {
				if (doc2.readyState == XMLHttpRequest.DONE) {
				}
			}
		doc2.open("PUT", "file:///HCBv2/qml/apps/sonos/pathstring.txt");
		doc2.send(str);
	}
	
	Column {
		id: labelContainer
		anchors {
			top: parent.top
			topMargin: 20
			left: parent.left
			leftMargin: 44
			right: parent.right
			rightMargin: 27
		}
		spacing: 6


		Item {
			width: parent.width
			height: childrenRect.height

			Text {
				id: titleText
				anchors {
					left: parent.left
					right: infoButton.left
					rightMargin: 6
				}
				font {
					pixelSize: qfont.bodyText
					family: qfont.regular.name
				}
				wrapMode: Text.WordWrap
				text: "Configureer hier de instellingen voor Sonos"
			}
		}

		Item {
			id: spacer
			width: parent.width
			height: 18
		}

		Item {
			width: parent.width
			height: childrenRect.height
			
			EditTextLabel4421 {
				id: ipadresLabel
				height: editipAdresButton.height
				width: isNxt ? 800 : 600
				leftText: qsTr("Hostname of ip-adres")
				leftTextAvailableWidth:isNxt ? 500 : 400

				anchors {
					left: parent.left
					leftMargin: 10
					top: titleText.bottom
					topMargin: 6
				}

				onClicked: {
					openKeyboard(p._IP_KEYBOARD);
				}
			}
			
			IconButton {
				id: editipAdresButton
				width: 40
				anchors {
					bottom: ipadresLabel.bottom
					right: parent.right
				}
				iconSource: "qrc:/tsc/edit.png"

				onClicked: {
					openKeyboard(p._IP_KEYBOARD);
				}
			}
		}

		Item {
			width: parent.width
			height: childrenRect.height

			EditTextLabel4421 {
				id: poortnummerLabel
				height: editportNumberButton.height
				width: isNxt ? 800 : 600
				leftText: qsTr("Poortnummer (default is 5005)")
				leftTextAvailableWidth:isNxt ? 500 : 400

				anchors {
					left: parent.left
					leftMargin: 10
					top: ipadresLabel.bottom
					topMargin: 6
				}
				onClicked: {
					openKeyboard(p._PORTNUMBER_KEYBOARD);
				}
			}
			
			IconButton {
				id: editportNumberButton
				width: 40
				anchors {
					bottom: poortnummerLabel.bottom
					right: parent.right
				}
				iconSource: "qrc:/tsc/edit.png"

				onClicked: {
					openKeyboard(p._PORTNUMBER_KEYBOARD);
				}
			}
		}

	}
	//here stops the first function of the keyboards!
	
		
	//Next part is to give someone the option for having a systray icon (in the right upper corner)
	Text {
		id: systrayText
		anchors {
			left: parent.left
			leftMargin: 44
			top: labelContainer.bottom
			topMargin: 30
		}
		font {
			pixelSize: qfont.bodyText
			family: qfont.regular.name
		}
		wrapMode: Text.WordWrap
		text: "Sonos icoon zichtbaar op systray?"
	}
	
		OnOffToggle {
		id: showSonosIconToggle
		height: 36
		anchors {
			left: systrayText.left
			top: systrayText.bottom
			topMargin: 15
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.saveshowSonosIcon("Yes")
			} else {
				app.saveshowSonosIcon("No")
			}
		}
	}
	
	StandardButton {
		id: btninfo
		text: "?"
		anchors {
			left: showSonosIconToggle.right
			leftMargin: 15
			top: systrayText.bottom
			topMargin: 10
		}
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, qsTr("Informatie"), qsTr("De vraag betreft het icoon wat helemaal boven in op het hoofdscherm wordt getoond, indien u dit icoon wenst te zien zorg dat hij aan staat, zo niet uiteraard uit. <br><br> Bij het aan of uit zetten van deze knop, bevestigd u de keuze voor het laten zien van het icoon.") , qsTr("Sluiten"));
		}
	}

	
}

//in this section is no timer required!
//created by Harmen Bartelink