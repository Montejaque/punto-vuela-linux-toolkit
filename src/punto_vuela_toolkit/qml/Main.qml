import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings

ApplicationWindow {
    id: window
    width: 1240
    height: 780
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: "Punto Vuela Linux Toolkit"
    property string activePage: "Inicio"
    property color accent: "#F3D54E"
    property string themeMode: appSettings.savedThemeMode
    property bool darkTheme: themeMode === "dark" || (themeMode === "system" && systemPalette.window.hslLightness < 0.5)

    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }
    Settings {
        id: appSettings
        category: "appearance"
        property string savedThemeMode: "system"
    }

    readonly property color backgroundColor: darkTheme ? "#111214" : "#F5F6F8"
    readonly property color sidebarColor: darkTheme ? "#17191C" : "#FFFFFF"
    readonly property color panel: darkTheme ? "#1B1D20" : "#FFFFFF"
    readonly property color panelBorder: darkTheme ? "#303237" : "#E1E3E8"
    readonly property color primaryText: darkTheme ? "#FFFFFF" : "#202226"
    readonly property color secondaryText: darkTheme ? "#B9BBC0" : "#555B65"
    readonly property color muted: darkTheme ? "#9A9DA3" : "#737984"
    readonly property color searchColor: darkTheme ? "#202226" : "#FFFFFF"
    readonly property color selectedNavigation: darkTheme ? "#343126" : "#FFF6D2"
    readonly property color heroStart: darkTheme ? "#393321" : "#FFF1B8"
    readonly property color heroEnd: darkTheme ? "#24211A" : "#F8E7A0"

    property bool previewVisible: false
    property var appImageItems: []

    function refreshAppImages() {
        appImageItems = JSON.parse(appImageManager.listAppImages())
    }

    function setThemeMode(mode) {
        themeMode = mode
        appSettings.savedThemeMode = mode
    }
    color: backgroundColor

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 238
            Layout.fillHeight: true
            color: sidebarColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 18

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        width: 44; height: 44; radius: 14
                        color: accent
                        Image { anchors.fill: parent; anchors.margins: 7; source: Qt.resolvedUrl("../assets/logotipovuela.svg"); fillMode: Image.PreserveAspectFit; visible: status === Image.Ready }
                    }
                    Column {
                        spacing: 2
                        Text { text: "PUNTO VUELA"; color: primaryText; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1.2 }
                        Text { text: "LINUX TOOLKIT"; color: accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: panelBorder }

                Text { text: "ESPACIO DE TRABAJO"; color: muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                Repeater {
                    model: [
                        {name:"Inicio", glyph:"⌂"},
                        {name:"Punto Vuela", glyph:"V"},
                        {name:"Catálogo AppImage", glyph:"▦"},
                        {name:"Mis aplicaciones", glyph:"▣"},
                        {name:"Actualizaciones", glyph:"↻"},
                        {name:"Contacto e información", glyph:"✉"}
                    ]
                    delegate: Item {
                        Layout.fillWidth: true
                        height: 43
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: activePage === modelData.name ? "#343126" : "transparent"
                            Rectangle { width: 3; height: 22; radius: 2; color: accent; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; visible: activePage === modelData.name }
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            spacing: 13
                            Text { text: modelData.glyph; color: activePage === modelData.name ? accent : "#B9BBC0"; font.pixelSize: 18; width: 18; horizontalAlignment: Text.AlignHCenter }
                            Text { text: modelData.name; color: activePage === modelData.name ? "#FFFFFF" : "#B9BBC0"; font.pixelSize: 13; font.weight: activePage === modelData.name ? Font.DemiBold : Font.Normal }
                        }
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData.name; cursorShape: Qt.PointingHandCursor }
                    }
                }

                Item { Layout.fillHeight: true }
                Text { text: "SISTEMA"; color: muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                Repeater {
                    model: ["Diagnóstico", "Configuración", "Ayuda"]
                    delegate: Text {
                        Layout.fillWidth: true
                        text: "  ◦   " + modelData
                        color: activePage === modelData ? "#FFFFFF" : "#B9BBC0"
                        font.pixelSize: 13
                        padding: 10
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData; cursorShape: Qt.PointingHandCursor }
                    }
                }
                Text { text: "VERSIÓN 0.1.0 · PREVIEW"; color: muted; font.pixelSize: 9; Layout.bottomMargin: 4 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: backgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 34
                spacing: 24

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 5
                        Text { text: activePage; color: primaryText; font.pixelSize: 27; font.bold: true }
                        Text { text: "Tu espacio para descubrir y mantener aplicaciones Linux"; color: muted; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 10; color: searchColor; border.color: panelBorder
                        Layout.preferredWidth: 250; Layout.preferredHeight: 40
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            Text { text: "⌕"; color: muted; font.pixelSize: 20 }
                            Text { text: "Buscar aplicaciones..."; color: muted; font.pixelSize: 12 }
                        }
                    }
                    ToolButton {
                        id: themeButton
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 40
                        text: themeMode === "system" ? "◐" : (themeMode === "dark" ? "☾" : "☀")
                        font.pixelSize: 20
                        palette.buttonText: primaryText
                        ToolTip.visible: hovered
                        ToolTip.text: "Apariencia: " + (themeMode === "system" ? "Sistema" : (themeMode === "dark" ? "Oscuro" : "Claro"))
                        background: Rectangle { radius: 10; color: themeButton.hovered ? panelBorder : searchColor; border.color: panelBorder }
                        onClicked: themeMenu.open()
                        Menu {
                            id: themeMenu
                            y: themeButton.height
                            MenuItem { text: "◐  Según el sistema"; checkable: true; checked: themeMode === "system"; onTriggered: setThemeMode("system") }
                            MenuItem { text: "☀  Claro"; checkable: true; checked: themeMode === "light"; onTriggered: setThemeMode("light") }
                            MenuItem { text: "☾  Oscuro"; checkable: true; checked: themeMode === "dark"; onTriggered: setThemeMode("dark") }
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: activePage === "Contacto e información" ? contactPage.implicitHeight : (activePage === "Mis aplicaciones" ? appImagesPage.implicitHeight : (activePage === "Ayuda" ? helpPage.implicitHeight : contentColumn.implicitHeight))
                    clip: true
                    ColumnLayout {
                        id: contentColumn
                        width: parent.width
                        spacing: 22
                        visible: activePage !== "Contacto e información" && activePage !== "Mis aplicaciones" && activePage !== "Ayuda"

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 190
                            radius: 18
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: heroStart }
                                GradientStop { position: 1.0; color: heroEnd }
                            }
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 28; spacing: 20
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "Bienvenido a tu centro de software"; color: primaryText; font.pixelSize: 22; font.bold: true }
                                    Text { text: "Las herramientas de Punto Vuela y tus aplicaciones Linux,
en un solo lugar."; color: secondaryText; font.pixelSize: 13; lineHeight: 1.35 }
                                    Rectangle {
                                        radius: 9; color: accent; Layout.preferredWidth: 154; Layout.preferredHeight: 38
                                        Text { anchors.centerIn: parent; text: "Explorar catálogo  →"; color: "#171717"; font.pixelSize: 12; font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: activePage = "Catálogo AppImage"; cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                                Rectangle {
                                    width: 116; height: 116; radius: 28; color: "#F3D54E"
                                    Image { anchors.fill: parent; anchors.margins: 18; source: Qt.resolvedUrl("../assets/logotipovuela.svg"); fillMode: Image.PreserveAspectFit; visible: status === Image.Ready }
                                }
                            }
                        }

                        Text { text: "Accesos destacados"; color: primaryText; font.pixelSize: 17; font.bold: true }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: width > 850 ? 3 : 2
                            columnSpacing: 14; rowSpacing: 14
                            Repeater {
                                model: [
                                    {title:"Antigravity Installer", desc:"Instalación y mantenimiento de Antigravity", url:"https://github.com/Montejaque/antigravity-installer-linux", tag:"PUNTO VUELA"},
                                    {title:"Claude Desktop Linux", desc:"Instalador de Claude Desktop para Linux", url:"https://github.com/Montejaque/claude-desktop-linux", tag:"PUNTO VUELA"},
                                    {title:"ChatGPT Installer", desc:"ChatGPT Desktop y Codex CLI", url:"https://github.com/Montejaque/chatgpt-installer-linux", tag:"PUNTO VUELA"},
                                    {title:"VS Code Installer", desc:"Gestor de Visual Studio Code sin root", url:"https://github.com/Montejaque/vscode-installer-linux", tag:"PUNTO VUELA"},
                                    {title:"Brother MFC-J5740DW", desc:"Controlador y escáner sin root", url:"https://github.com/Montejaque/brother-mfc-j5740dw-sinroot", tag:"PUNTO VUELA"}
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 122
                                    radius: 13; color: panel; border.color: panelBorder
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 15; spacing: 7
                                        Text { text: modelData.tag; color: accent; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                                        Text { text: modelData.title; color: primaryText; font.pixelSize: 13; font.bold: true }
                                        Text { text: modelData.desc; color: muted; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                        Text { text: "Fuentes de aplicaciones"; color: primaryText; font.pixelSize: 17; font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 14
                            Repeater {
                                model: [
                                    {title:"AppImageHub", desc:"Catálogo de aplicaciones AppImage", url:"https://www.appimagehub.com/"},
                                    {title:"AppImage Community", desc:"Catálogo comunitario oficial", url:"https://appimage.github.io/"}
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 88
                                    radius: 12; color: panel; border.color: panelBorder
                                    Column {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 7
                                        Text { text: modelData.title; color: primaryText; font.pixelSize: 13; font.bold: true }
                                        Text { text: modelData.desc; color: muted; font.pixelSize: 11 }
                                    }
                                }
                            }
                        }

                    }


                    ColumnLayout {
                        id: appImagesPage
                        width: parent.width
                        spacing: 16
                        visible: activePage === "Mis aplicaciones"
                        Text { text: "Tus aplicaciones AppImage"; color: primaryText; font.pixelSize: 20; font.bold: true }
                        Text { Layout.fillWidth: true; text: "Descarga aplicaciones desde enlaces HTTPS. Se guardan en tu carpeta personal y reciben permisos de ejecución automáticamente."; color: secondaryText; font.pixelSize: 12; wrapMode: Text.WordWrap }
                        Rectangle {
                            Layout.fillWidth: true; radius: 14; color: panel; border.color: panelBorder
                            implicitHeight: downloadForm.implicitHeight + 30
                            ColumnLayout {
                                id: downloadForm
                                anchors.fill: parent; anchors.margins: 16; spacing: 10
                                Text { text: "Descargar AppImage"; color: primaryText; font.pixelSize: 14; font.bold: true }
                                TextField { id: appImageUrl; Layout.fillWidth: true; placeholderText: "Enlace HTTPS directo al archivo .AppImage" }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Button {
                                        text: "Descargar"
                                        onClicked: {
                                            const result = JSON.parse(appImageManager.downloadAppImage(appImageUrl.text.trim()))
                                            appImageStatus.text = result.message
                                            if (result.ok) { appImageUrl.text = ""; refreshAppImages() }
                                        }
                                    }
                                    Button { text: "Abrir carpeta"; onClicked: appImageManager.openAppImageFolder() }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Aplicaciones descargadas"; color: primaryText; font.pixelSize: 15; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Button { text: "Actualizar lista"; onClicked: refreshAppImages() }
                        }
                        Text { id: appImageStatus; Layout.fillWidth: true; color: secondaryText; wrapMode: Text.WordWrap; font.pixelSize: 11 }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(150, appImageItems.length * 92)
                            interactive: false
                            model: appImageItems
                            spacing: 8
                            delegate: Rectangle {
                                width: ListView.view.width; height: 84
                                radius: 12; color: panel; border.color: panelBorder
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 8
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { text: modelData.name; color: primaryText; font.pixelSize: 12; font.bold: true; elide: Text.ElideMiddle; Layout.fillWidth: true }
                                        Text { text: modelData.executable ? "Permisos de ejecución activos" : "Sin permisos de ejecución"; color: muted; font.pixelSize: 10 }
                                    }
                                    Button {
                                        text: "Comprobar"
                                        onClicked: {
                                            const result = JSON.parse(appImageManager.checkAppImageUpdate(modelData.path))
                                            appImageStatus.text = modelData.name + ": " + result.message
                                            if (result.available) appImageStatus.text += " · Hay una actualización. Pulsa Actualizar."
                                        }
                                    }
                                    Button {
                                        text: "Actualizar"
                                        onClicked: {
                                            const result = JSON.parse(appImageManager.updateAppImage(modelData.path))
                                            appImageStatus.text = modelData.name + ": " + result.message
                                            refreshAppImages()
                                        }
                                    }
                                }
                            }
                        }
                        Text { Layout.fillWidth: true; text: "La comprobación requiere información de actualización compatible dentro de la AppImage. Si no encuentra AppImageUpdate, el Toolkit descarga el actualizador oficial en tu perfil y verifica su SHA-256; no necesita root. Si no existe esa información, consulta la web del desarrollador y descarga la nueva versión manualmente."; color: muted; font.pixelSize: 11; wrapMode: Text.WordWrap }
                        Component.onCompleted: refreshAppImages()
                    }

                    ColumnLayout {
                        id: helpPage
                        width: parent.width
                        spacing: 16
                        visible: activePage === "Ayuda"
                        Text { text: "Guía de ayuda"; color: primaryText; font.pixelSize: 22; font.bold: true }
                        Text { text: "PUNTO VUELA LINUX TOOLKIT"; color: accent; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                        Rectangle {
                            Layout.fillWidth: true; radius: 14; color: heroStart; border.color: panelBorder
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 18; spacing: 8
                                Text { text: "Tus aplicaciones, organizadas en un solo lugar"; color: "#202226"; font.pixelSize: 17; font.bold: true }
                                Text { text: "Las AppImages se guardan en ~/.local/share/punto-vuela-linux-toolkit/AppImages. No necesitas permisos de administrador para descargarlas o gestionarlas."; color: "#343434"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                            }
                        }
                        Repeater {
                            model: [
                                {title:"1. Descargar", body:"En Mis aplicaciones, introduce el enlace HTTPS directo al archivo .AppImage. El Toolkit valida que el archivo sea ELF y lo guarda en tu carpeta personal."},
                                {title:"2. Ejecutar", body:"Al finalizar la descarga, el archivo recibe permisos de ejecución automáticamente. Pulsa Abrir carpeta para localizarlo."},
                                {title:"3. Actualizar", body:"Pulsa Comprobar. Si la AppImage incluye información compatible, AppImageUpdate consulta el origen del autor. Si existe una versión nueva, pulsa Actualizar."},
                                {title:"4. Sin actualizador", body:"No todas las AppImages de AppImageHub incluyen información de actualización. En ese caso no se puede confirmar automáticamente si hay una versión posterior: consulta la web del desarrollador."},
                                {title:"5. Seguridad", body:"Una AppImage es un programa ejecutable. Descarga software de fuentes fiables. La validación ELF no es un análisis antivirus ni verifica la identidad del autor. Las actualizaciones requieren una acción explícita."}
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true; radius: 12; color: panel; border.color: panelBorder
                                implicitHeight: helpText.implicitHeight + 30
                                ColumnLayout {
                                    id: helpText
                                    anchors.fill: parent; anchors.margins: 15; spacing: 6
                                    Text { text: modelData.title; color: primaryText; font.pixelSize: 13; font.bold: true }
                                    Text { text: modelData.body; color: secondaryText; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                }
                            }
                        }
                        Text { Layout.fillWidth: true; text: "Guía completa: docs/GUIA-DE-AYUDA.md en el repositorio."; color: muted; font.pixelSize: 10; wrapMode: Text.WordWrap }
                    }

                    ColumnLayout {
                        id: contactPage
                        width: parent.width
                        spacing: 18
                        visible: activePage === "Contacto e información"

                        Text {
                            Layout.fillWidth: true
                            text: "Solicita incorporar una aplicación"
                            color: primaryText
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Indica desde qué Punto Vuela se realiza la solicitud y los datos de contacto del/de la AIL. Antes de abrir WhatsApp podrás revisar y editar el mensaje completo."
                            color: secondaryText
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: panel
                            border.color: panelBorder
                            implicitHeight: requestForm.implicitHeight + 32
                            ColumnLayout {
                                id: requestForm
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 12

                                Text { text: "1. Datos del Punto Vuela y del/de la AIL"; color: primaryText; font.pixelSize: 14; font.bold: true }
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: width > 680 ? 2 : 1
                                    columnSpacing: 12
                                    rowSpacing: 9
                                    TextField { id: puntoVuelaField; Layout.fillWidth: true; placeholderText: "Nombre del Punto Vuela *" }
                                    TextField { id: municipioField; Layout.fillWidth: true; placeholderText: "Municipio *" }
                                    TextField { id: ailField; Layout.fillWidth: true; placeholderText: "Nombre y apellidos del/de la AIL *" }
                                    TextField { id: telefonoField; Layout.fillWidth: true; placeholderText: "Teléfono de contacto *"; inputMethodHints: Qt.ImhTelephoneNumber }
                                    TextField { id: correoField; Layout.fillWidth: true; placeholderText: "Correo electrónico de contacto *"; inputMethodHints: Qt.ImhEmailCharactersOnly }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: panelBorder }
                                Text { text: "2. Aplicación que se solicita"; color: primaryText; font.pixelSize: 14; font.bold: true }
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: width > 680 ? 2 : 1
                                    columnSpacing: 12
                                    rowSpacing: 9
                                    TextField { id: softwareField; Layout.fillWidth: true; placeholderText: "Nombre del programa o aplicación *" }
                                    TextField { id: enlaceField; Layout.fillWidth: true; placeholderText: "Web oficial o enlace de descarga" }
                                    ComboBox {
                                        id: distroField
                                        Layout.fillWidth: true
                                        model: ["Ubuntu", "Debian", "Linux Mint", "Fedora", "Otra distribución", "Cualquier distribución"]
                                    }
                                }
                                TextArea {
                                    id: motivoField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 86
                                    placeholderText: "¿Para qué se utilizaría? ¿Qué necesidad cubriría? *"
                                    wrapMode: TextEdit.Wrap
                                }
                                TextArea {
                                    id: observacionesField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 64
                                    placeholderText: "Observaciones adicionales (opcional)"
                                    wrapMode: TextEdit.Wrap
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Rectangle {
                                        radius: 9
                                        color: accent
                                        Layout.preferredHeight: 42
                                        Layout.preferredWidth: 190
                                        Text { anchors.centerIn: parent; text: "Generar vista previa"; color: "#171717"; font.pixelSize: 12; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!puntoVuelaField.text.trim() || !municipioField.text.trim() ||
                                                    !ailField.text.trim() || !telefonoField.text.trim() ||
                                                    !correoField.text.trim() || !softwareField.text.trim() ||
                                                    !motivoField.text.trim()) {
                                                    formError.text = "Completa los campos obligatorios marcados con * para generar el mensaje."
                                                    formError.visible = true
                                                    return
                                                }
                                                formError.visible = false
                                                previewText.text =
                                                    "SOLICITUD DE INCORPORACIÓN DE SOFTWARE — PUNTO VUELA\n\n" +
                                                    "PUNTO VUELA\n" +
                                                    "Centro: " + puntoVuelaField.text.trim() + "\n" +
                                                    "Municipio: " + municipioField.text.trim() + "\n\n" +
                                                    "DATOS DEL/DE LA AIL\n" +
                                                    "Nombre: " + ailField.text.trim() + "\n" +
                                                    "Teléfono: " + telefonoField.text.trim() + "\n" +
                                                    "Correo: " + correoField.text.trim() + "\n\n" +
                                                    "SOFTWARE SOLICITADO\n" +
                                                    "Aplicación: " + softwareField.text.trim() + "\n" +
                                                    "Enlace: " + (enlaceField.text.trim() || "No indicado") + "\n" +
                                                    "Distribución: " + distroField.currentText + "\n" +
                                                    "Necesidad / utilidad: " + motivoField.text.trim() + "\n" +
                                                    "Observaciones: " + (observacionesField.text.trim() || "Ninguna") + "\n"
                                                previewVisible = true
                                            }
                                        }
                                    }
                                    Text {
                                        id: formError
                                        Layout.fillWidth: true
                                        visible: false
                                        color: "#D65A5A"
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            radius: 14
                            color: panel
                            border.color: panelBorder
                            visible: previewVisible
                            implicitHeight: previewColumn.implicitHeight + 32
                            ColumnLayout {
                                id: previewColumn
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 10
                                Text { text: "3. Revisa y modifica el mensaje"; color: primaryText; font.pixelSize: 14; font.bold: true }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Este texto es editable. Los cambios que hagas aquí serán los que se preparen en WhatsApp."
                                    color: muted
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }
                                TextArea {
                                    id: previewText
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 300
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    color: primaryText
                                    background: Rectangle { color: searchColor; border.color: panelBorder; radius: 8 }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Rectangle {
                                        radius: 9
                                        color: accent
                                        Layout.preferredHeight: 42
                                        Layout.preferredWidth: 190
                                        Text { anchors.centerIn: parent; text: "Abrir WhatsApp"; color: "#171717"; font.pixelSize: 12; font.bold: true }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (previewText.text.trim().length > 0) {
                                                    Qt.openUrlExternally("https://wa.me/34633402959?text=" + encodeURIComponent(previewText.text))
                                                }
                                            }
                                        }
                                    }
                                    Text { text: "Destino: +34 633 402 959"; color: muted; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
