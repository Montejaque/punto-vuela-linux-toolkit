import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings

ApplicationWindow {
    id: window
    width: rem(77.5)
    height: rem(48.75)
    minimumWidth: rem(60)
    minimumHeight: rem(40)
    visible: true
    title: "Puntos Vuela Toolkit"
    property string activePage: "Inicio"
    // QML usa unidades lógicas; esta función centraliza todas las medidas en rem-equivalentes.
    readonly property real remBase: 16
    function rem(value) { return value * remBase }
    property bool sidebarExpanded: true
    property color accent: "#FAD100"
    property string themeMode: appSettings.savedThemeMode
    property bool darkTheme: themeMode === "dark" || (themeMode === "system" && systemPalette.window.hslLightness < 0.5)

    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }
    Settings {
        id: appSettings
        category: "appearance"
        property string savedThemeMode: "dark"
    }

    readonly property color backgroundColor: darkTheme ? "#252B31" : "#F3F4F6"
    readonly property color sidebarColor: "#FAD100"
    readonly property color panel: darkTheme ? "#303740" : "#FFFFFF"
    readonly property color panelBorder: darkTheme ? "#3A424C" : "#E1E3E8"
    readonly property color primaryText: darkTheme ? "#F7F8FA" : "#202226"
    readonly property color secondaryText: darkTheme ? "#C2C8D0" : "#555B65"
    readonly property color muted: darkTheme ? "#929BA6" : "#737984"
    readonly property color searchColor: darkTheme ? "#252B31" : "#FFFFFF"
    readonly property color selectedNavigation: darkTheme ? "#343126" : "#FFF6D2"
    readonly property color heroStart: darkTheme ? "#34303D" : "#FFF1B8"
    readonly property color heroEnd: darkTheme ? "#292F38" : "#F8E7A0"

    property bool previewVisible: false
    property bool emailSending: false
    property var puntoVuelaCentres: []
    property var filteredPuntoVuelaCentres: []
    property bool puntoVuelaCentresLoading: false
    property string selectedCentreSlug: ""
    property string selectedCentreSourceUrl: ""
    property bool centreDetailsLoading: false
    property bool dataProtectionRead: false
    property bool privacyPolicyRead: false
    property bool termsAccepted: false
    property var appImageItems: []
    property var catalogItems: []
    property bool catalogLoading: false
    property var selectedCatalogApp: null
    property string catalogCategory: "Todas"
    property var filteredCatalogItems: catalogItems.filter(item => catalogCategory === "Todas" || item.category === catalogCategory)
    property string selectedCategory: "Todas"
    property string selectedAppName: ""
    property var selectedHomeApp: null
    property var puntoVuelaTools: []
    property var toolkitRelease: ({})
    property bool puntoVuelaLoading: false
    property string puntoVuelaStatus: "Consultando repositorios públicos de GitHub…"
    property var featuredApps: puntoVuelaTools.map(item => ({
        title:item.name, category:item.category, kind:item.kind,
        desc:item.description, url:item.repositoryUrl, repository:item.repository, image:item.iconUrl||"", tag:"PUNTO VUELA",
        version:item.version, releaseUrl:item.releaseUrl, downloadUrl:item.downloadUrl
    }))
    property var allHomeApps: featuredApps.concat(catalogItems.map(item => ({title:item.name,category:item.category,kind:"AppImage oficial",desc:item.description||"Aplicación del catálogo oficial.",url:item.catalogUrl,image:item.iconUrl,tag:"CATÁLOGO OFICIAL",official:true})))
    property var visibleFeaturedApps: allHomeApps.filter(item => selectedCategory === "Todas" || item.category === selectedCategory)

    Component.onCompleted: {
        refreshCatalog()
        puntoVuelaLoading = true
        appImageManager.loadPuntoVuelaTools()
        appImageManager.loadToolkitRelease()
        puntoVuelaCentresLoading = true
        appImageManager.loadPuntoVuelaCentres()
    }

    function refreshCatalog() {
        catalogLoading = true
        appImageManager.loadCatalog(catalogSearch.text.trim())
    }

    Connections {
        target: appImageManager
        function onEmailSent(payload) {
            const result = JSON.parse(payload)
            emailSending = false
            emailStatus.text = result.message || (result.ok ? "Correo enviado correctamente." : "No se pudo enviar el correo.")
            emailStatus.color = result.ok ? "#62B47A" : "#E06A6A"
            if (result.ok) previewVisible = false
        }
        function onPuntoVuelaCentresLoaded(payload) {
            const result = JSON.parse(payload)
            puntoVuelaCentres = result.items || []
            filteredPuntoVuelaCentres = puntoVuelaCentres
            puntoVuelaCentresLoading = false
            if (!result.ok) {
                emailStatus.text = result.message || "No se pudo cargar el directorio de centros."
                emailStatus.color = "#D65A5A"
            }
        }
        function onPuntoVuelaCentreDetailsLoaded(payload) {
            const result = JSON.parse(payload)
            if (result.slug !== selectedCentreSlug) return
            centreDetailsLoading = false
            if (!result.ok) {
                centreDetailsStatus.text = (result.message || "No se pudieron consultar los datos públicos del centro.") + " Puedes completarlos manualmente."
                centreDetailsStatus.color = "#D65A5A"
                return
            }
            const details = result.details || {}
            selectedCentreSourceUrl = details.source_url || ""
            ailField.text = details.ail || ""
            telefonoField.text = details.phone || ""
            correoField.text = details.email || ""
            const missing = []
            if (!details.ail) missing.push("AIL")
            if (!details.phone) missing.push("teléfono")
            if (!details.email) missing.push("correo")
            centreDetailsStatus.text = missing.length
                ? "Datos cargados desde la ficha oficial. No publicados: " + missing.join(", ") + ". Puedes completar esos campos manualmente."
                : "Nombre del AIL y datos de contacto del centro cargados desde la ficha oficial."
            centreDetailsStatus.color = secondaryText
        }
        function onPuntoVuelaToolsLoaded(payload) {
            const result = JSON.parse(payload)
            if (result.ok) puntoVuelaTools = result.items || []
            puntoVuelaStatus = result.message || "Catálogo de GitHub actualizado."
            puntoVuelaLoading = false
        }
        function onToolkitReleaseLoaded(payload) { toolkitRelease = JSON.parse(payload) }
        function onCatalogLoaded(payload) {
            const result = JSON.parse(payload)
            catalogItems = result.items || []
            catalogStatus.text = result.message || ""
            catalogLoading = false
        }
        function onCatalogInstallFinished(payload) {
            const result = JSON.parse(payload)
            catalogStatus.text = result.message || "La operación ha terminado."
            if (result.ok) refreshAppImages()
        }
        function onAppImageDownloadFinished(payload) {
            const result = JSON.parse(payload)
            appImageStatus.text = result.message || ""
            if (result.ok) { appImageUrl.text = ""; refreshAppImages() }
        }
        function onAppImageUpdateCheckFinished(payload) {
            const result = JSON.parse(payload)
            appImageStatus.text = result.path.split("/").pop() + ": " + result.message
            if (result.available) appImageStatus.text += " · Hay una actualización. Pulsa Actualizar."
        }
        function onAppImageUpdated(payload) {
            const result = JSON.parse(payload)
            appImageStatus.text = result.message || ""
            refreshAppImages()
        }
    }

    Dialog {
        id: removeDialog
        property string targetPath: ""
        title: "Eliminar AppImage"
        modal: true
        standardButtons: Dialog.Yes | Dialog.Cancel
        Label { text: "¿Quieres eliminar este archivo de la carpeta de aplicaciones? No se puede deshacer."; wrapMode: Text.WordWrap }
        onAccepted: {
            const result = JSON.parse(appImageManager.removeAppImage(targetPath))
            appImageStatus.text = result.message
            refreshAppImages()
        }
    }

    Dialog {
        id: dataProtectionDialog
        modal: true
        title: "Información sobre protección de datos"
        width: Math.min(window.width - 48, 680)
        height: Math.min(window.height - 48, 620)
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton
        contentItem: ColumnLayout {
            spacing: rem(0.75)
            Label { Layout.fillWidth: true; text: "Responsable: Consorcio Puntos Vuela de Andalucía (CPV)."; font.bold: true; wrapMode: Text.WordWrap }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; color: secondaryText
                    text: "Finalidad: recibir, revisar y responder a propuestas profesionales de los AIL de los centros Puntos Vuela.\n\nDatos: centro, municipio, datos profesionales de contacto, aplicación propuesta, enlace, distribución, necesidad y observaciones.\n\nDestinatario: las propuestas se remiten a montejaque@puntosvuela.es. El correo indicado por el AIL recibe una copia.\n\nProveedores: Cloudflare Workers y Gmail API. La aplicación no mantiene una base de datos propia de propuestas ni crea expedientes; el contenido queda en los buzones de correo.\n\nMantenimiento técnico y gestión operativa del buzón: Francisco Javier Gallego Orellana, AIL del Punto Vuela de Montejaque.\n\nNo incluyas contraseñas, documentos de identidad ni datos personales innecesarios."
                }
            }
            Label { Layout.fillWidth: true; text: "La base jurídica aplicable es la que corresponda a las funciones del Consorcio y debe estar documentada por este."; color: muted; wrapMode: Text.WordWrap; font.pixelSize: rem(0.75) }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Cerrar"; onClicked: dataProtectionDialog.close() }
                Button { text: "He leído esta información"; highlighted: true; onClicked: { dataProtectionRead = true; dataProtectionDialog.close() } }
            }
        }
    }

    Dialog {
        id: privacyPolicyDialog
        modal: true
        title: "Política de privacidad"
        width: Math.min(window.width - 48, 680)
        height: Math.min(window.height - 48, 620)
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton
        contentItem: ColumnLayout {
            spacing: rem(0.75)
            Label { Layout.fillWidth: true; text: "Puntos Vuela Toolkit · Consorcio Puntos Vuela de Andalucía"; font.bold: true; wrapMode: Text.WordWrap }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; color: secondaryText
                    text: "La política completa explica los datos tratados, finalidades, proveedores tecnológicos, conservación, seguridad y ejercicio de derechos.\n\nDelegado de Protección de Datos: delegadoprotecciondatos.cfr@puntosvuela.es\n\nBuzón central de propuestas: montejaque@puntosvuela.es"
                }
            }
            Label {
                Layout.fillWidth: true
                text: '<a href="https://toolkit.javigallego.es/privacy">Abrir política de privacidad completa</a>'
                textFormat: Text.RichText; color: accent
                onLinkActivated: Qt.openUrlExternally(link)
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Cerrar"; onClicked: privacyPolicyDialog.close() }
                Button { text: "He leído la política"; highlighted: true; onClicked: { privacyPolicyRead = true; privacyPolicyDialog.close() } }
            }
        }
    }
    Dialog {
        id: termsDialog
        modal: true
        title: "Términos y condiciones de uso"
        width: Math.min(window.width - 48, 680)
        height: Math.min(window.height - 48, 620)
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton
        contentItem: ColumnLayout {
            spacing: rem(0.75)
            Label { Layout.fillWidth: true; text: "Condiciones de uso del formulario de propuestas"; font.bold: true; wrapMode: Text.WordWrap }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; color: secondaryText
                    text: "1. Finalidad. Este formulario está destinado exclusivamente a los Agentes de Innovación Local de la red Puntos Vuela para remitir propuestas profesionales de aplicaciones y necesidades de los centros.\n\n2. Uso adecuado. La información facilitada debe ser veraz, pertinente y relacionada con la finalidad del formulario. No se deben enviar contraseñas, documentos de identidad, datos especialmente protegidos ni datos personales de terceras personas que no sean necesarios.\n\n3. Envío y destinatarios. Al enviar, la propuesta se transmite mediante una conexión HTTPS al servicio de correo y se remite al buzón indicado en la información de protección de datos. La dirección profesional facilitada recibe una copia.\n\n4. Disponibilidad. El servicio depende de proveedores tecnológicos externos y puede no estar disponible temporalmente. El envío solo se considera realizado cuando la aplicación confirma su recepción.\n\n5. Uso responsable. No se permite utilizar el formulario para spam, publicidad no solicitada, contenido ilícito o comunicaciones ajenas a su finalidad.\n\n6. Protección de datos. El tratamiento se rige por la información y política de privacidad mostradas en el formulario. La aceptación de estas condiciones no sustituye la base jurídica que corresponda al responsable del tratamiento."
                }
            }
            Label {
                Layout.fillWidth: true
                text: '<a href="https://toolkit.javigallego.es/terms">Abrir términos y condiciones completos</a>'
                textFormat: Text.RichText; color: accent
                onLinkActivated: Qt.openUrlExternally(link)
            }
            Label {
                Layout.fillWidth: true
                text: "Consulta el documento completo de condiciones de uso. Debe mantenerse alineado con las instrucciones oficiales del Consorcio."
                color: muted; wrapMode: Text.WordWrap; font.pixelSize: rem(0.75)
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Cerrar"; onClicked: termsDialog.close() }
                Button { text: "He leído y acepto"; highlighted: true; onClicked: { termsAccepted = true; termsDialog.close() } }
            }
        }
    }

    function selectPuntoVuelaCentre(item) {
        if (!item) return
        selectedCentreSlug = item.slug || ""
        selectedCentreSourceUrl = ""
        municipioField.text = item.municipality || ""
        provinciaField.text = item.province || ""
        ailField.text = ""
        telefonoField.text = ""
        correoField.text = ""
        if (!selectedCentreSlug) {
            centreDetailsStatus.text = "La ficha del centro no está enlazada en el directorio. Completa los datos manualmente."
            centreDetailsStatus.color = "#D65A5A"
            return
        }
        centreDetailsLoading = true
        centreDetailsStatus.text = "Consultando la ficha pública de Puntos Vuela…"
        centreDetailsStatus.color = secondaryText
        appImageManager.loadPuntoVuelaCentreDetails(selectedCentreSlug)
    }
    function refreshAppImages() {
        appImageItems = JSON.parse(appImageManager.listAppImages())
    }

    function setThemeMode(mode) {
        themeMode = mode
        appSettings.savedThemeMode = mode
    }
    color: backgroundColor
    palette.window: backgroundColor
    palette.base: searchColor
    palette.alternateBase: panel
    palette.text: primaryText
    palette.windowText: primaryText
    palette.button: panel
    palette.buttonText: primaryText
    palette.highlight: accent
    palette.highlightedText: "#202226"

    RowLayout {
        anchors.fill: parent
        spacing: rem(0)

        Rectangle {
            Layout.preferredWidth: sidebarExpanded ? 238 : 76
            Layout.fillHeight: true
            color: sidebarColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: sidebarExpanded ? 20 : 8
                spacing: rem(1.125)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: sidebarExpanded ? 12 : 0
                    Rectangle {
                        width: sidebarExpanded ? 44 : 28; height: sidebarExpanded ? 44 : 34; radius: rem(0.75)
                        color: accent
                        Image { anchors.fill: parent; anchors.margins: rem(0.1875); source: Qt.resolvedUrl("../assets/logo_toolkit.svg"); fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true; asynchronous: true; sourceSize.width: rem(32); sourceSize.height: rem(32); visible: status === Image.Ready }
                    }
                    Column {
                        visible: sidebarExpanded
                        spacing: rem(0.125)
                        Text { text: "PUNTOS VUELA"; color: "#202226"; font.pixelSize: rem(0.8125); font.bold: true; font.letterSpacing: rem(0.075) }
                        Text { text: "TOOLKIT"; color: "#51430A"; font.pixelSize: rem(0.75); font.bold: true; font.letterSpacing: rem(0.06875) }
                    }
                    ToolButton {
                        Layout.preferredWidth: sidebarExpanded ? 28 : 24
                        Layout.preferredHeight: rem(2.125)
                        Layout.alignment: Qt.AlignRight
                        text: sidebarExpanded ? "‹" : "☰"
                        font.pixelSize: rem(1.25)
                        palette.buttonText: "#202226"
                        ToolTip.visible: hovered
                        ToolTip.text: sidebarExpanded ? "Contraer menú" : "Expandir menú"
                        onClicked: sidebarExpanded = !sidebarExpanded
                    }
                }

                Rectangle { Layout.fillWidth: true; height: rem(0.0625); color: "#E0AD00" }

                Text { visible: sidebarExpanded; text: "ESPACIO DE TRABAJO"; color: "#665400"; font.pixelSize: rem(0.75); font.bold: true; font.letterSpacing: rem(0.06875) }
                Repeater {
                    model: [
                        {name:"Inicio", glyph:"⌂"},
                        {name:"Catálogo AppImage", glyph:"▦"},
                        {name:"Mis aplicaciones", glyph:"▣"},
                        {name:"Contacto e información", glyph:"✉"}
                    ]
                    delegate: Item {
                        Layout.fillWidth: true
                        height: rem(2.6875)
                        Rectangle {
                            anchors.fill: parent
                            radius: rem(0.625)
                            color: activePage === modelData.name ? "#292F36" : "transparent"
                            Rectangle { width: rem(0.1875); height: rem(1.375); radius: rem(0.125); color: accent; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; visible: activePage === modelData.name }
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: sidebarExpanded ? 14 : (parent.width - width) / 2
                            spacing: sidebarExpanded ? 13 : 0
                            Text { text: modelData.glyph; color: activePage === modelData.name ? "#FFC400" : "#292F36"; font.pixelSize: rem(1.125); width: rem(1.5); horizontalAlignment: Text.AlignHCenter }
                            Text { visible: sidebarExpanded; text: modelData.name; color: activePage === modelData.name ? "#FFFFFF" : "#292F36"; font.pixelSize: rem(0.8125); font.weight: activePage === modelData.name ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; width: rem(8.875) }
                        }
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData.name; cursorShape: Qt.PointingHandCursor }
                    }
                }

                Item { Layout.fillHeight: true }
                Text { visible: sidebarExpanded; text: "SISTEMA"; color: "#665400"; font.pixelSize: rem(0.75); font.bold: true; font.letterSpacing: rem(0.06875) }
                Repeater {
                    model: ["Ayuda"]
                    delegate: Text {
                        Layout.fillWidth: true
                        text: sidebarExpanded ? "  ◦   " + modelData : "◦"
                        color: activePage === modelData ? "#292F36" : "#292F36"
                        font.pixelSize: rem(0.8125)
                        padding: rem(0.625)
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData; cursorShape: Qt.PointingHandCursor }
                    }
                }
                Text { visible: sidebarExpanded; text: "VERSIÓN 0.1.0 · PREVIEW"; color: "#665400"; font.pixelSize: rem(0.75); Layout.bottomMargin: rem(0.25) }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: backgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: rem(1.625)
                spacing: rem(1.5)

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: rem(0.3125)
                        Text { text: activePage; color: primaryText; font.pixelSize: rem(1.6875); font.bold: true }
                        Text { text: "Tu espacio para descubrir y mantener aplicaciones Linux"; color: muted; font.pixelSize: rem(0.8125) }
                    }
                    Item { Layout.fillWidth: true }
                    TextField {
                        id: globalSearch
                        Layout.preferredWidth: rem(16.875)
                        placeholderText: "Buscar aplicaciones..."
                        onAccepted: {
                            catalogSearch.text = text
                            activePage = "Catálogo AppImage"
                            refreshCatalog()
                        }
                    }
                    ToolButton {
                        id: themeButton
                        Layout.preferredWidth: rem(2.625)
                        Layout.preferredHeight: rem(2.5)
                        text: themeMode === "system" ? "◐" : (themeMode === "dark" ? "☾" : "☀")
                        font.pixelSize: rem(1.25)
                        palette.buttonText: primaryText
                        ToolTip.visible: hovered
                        ToolTip.text: "Apariencia: " + (themeMode === "system" ? "Sistema" : (themeMode === "dark" ? "Oscuro" : "Claro"))
                        background: Rectangle { radius: rem(0.625); color: themeButton.hovered ? panelBorder : searchColor; border.color: panelBorder }
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
                    contentHeight: activePage === "Contacto e información" ? contactPage.implicitHeight : (activePage === "Mis aplicaciones" ? appImagesPage.implicitHeight : (activePage === "Ayuda" ? helpPage.implicitHeight : (activePage === "Catálogo AppImage" ? catalogPage.implicitHeight : contentColumn.implicitHeight)))
                    clip: true
                    ColumnLayout {
                        id: contentColumn
                        width: parent.width
                        spacing: rem(1.375)
                        visible: activePage !== "Contacto e información" && activePage !== "Mis aplicaciones" && activePage !== "Ayuda" && activePage !== "Catálogo AppImage"

                        Rectangle {
                            Layout.fillWidth:true; Layout.preferredHeight:rem(15.5); radius:rem(1.375); clip:true
                            gradient:Gradient {
                                GradientStop { position:0; color:darkTheme?"#332D1B":"#FFF0AE" }
                                GradientStop { position:1; color:darkTheme?"#211F1A":"#F8E4A0" }
                            }
                            RowLayout {
                                anchors.fill:parent; anchors.margins:rem(1.75); spacing:rem(1.5)
                                ColumnLayout {
                                    Layout.fillWidth:true; spacing:rem(0.75)
                                    Text { text:"PUNTO VUELA · SOFTWARE HUB"; color:darkTheme?"#FAD100":"#76601B"; font.pixelSize: rem(0.75); font.bold:true; font.letterSpacing:rem(0.10625) }
                                    Text { text:"Todo tu software Linux.\nEn un solo lugar."; color:darkTheme?"#FFFFFF":"#202226"; font.pixelSize:rem(1.8125); font.bold:true }
                                    Text { text:"Descubre herramientas, aplicaciones y utilidades seleccionadas para tu entorno de trabajo."; color:darkTheme?"#D3D0C7":"#55504A"; font.pixelSize:rem(0.8125); wrapMode:Text.WordWrap; Layout.fillWidth:true }
                                    Button { text:"Explorar aplicaciones  →"; onClicked:activePage="Catálogo AppImage" }
                                }
                                Item {
                                    Layout.preferredWidth:rem(18.75); Layout.fillHeight:true
                                    Repeater {
                                        model:[
                                            {image:"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/openai.png",x:10,y:30,rotation:-9},
                                            {image:"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/vscode.png",x:105,y:8,rotation:7},
                                            {image:"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude.png",x:205,y:46,rotation:8}
                                        ]
                                        delegate:Rectangle {
                                            x:modelData.x;y:modelData.y;width:rem(5.125);height:rem(5.125);radius:rem(1.1875);rotation:modelData.rotation;color:"#FFFFFF";border.color:"#E6E2D5"
                                            Image { anchors.fill:parent;anchors.margins:rem(0.875);source:modelData.image;fillMode:Image.PreserveAspectFit;asynchronous:true }
                                            SequentialAnimation on y {
                                                loops: Animation.Infinite
                                                NumberAnimation { to: modelData.y - 8; duration: 1500 + index * 160; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: modelData.y; duration: 1500 + index * 160; easing.type: Easing.InOutSine }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth:true
                            Text { text:"Aplicaciones destacadas"; color:primaryText; font.pixelSize:rem(1.1875); font.bold:true }
                            Item { Layout.fillWidth:true }
                            Text { text:allHomeApps.length+" herramientas"; color:muted; font.pixelSize: rem(0.75) }
                        }
                        Flow {
                            Layout.fillWidth:true; spacing:rem(0.5)
                            Repeater {
                                model:["Todas","Herramientas Puntos Vuela","IA y desarrollo","Desarrollo","Sistema y periféricos"]
                                delegate:Button { text:modelData; highlighted:selectedCategory===modelData; onClicked:selectedCategory=modelData }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth:true
                            Text { text:puntoVuelaStatus; color:muted; font.pixelSize: rem(0.75); Layout.fillWidth:true; wrapMode:Text.WordWrap }
                            Button { text:"Actualizar repositorios"; enabled:!puntoVuelaLoading; onClicked:{puntoVuelaLoading=true;appImageManager.refreshPuntoVuelaTools()} }
                        }
                        Text { visible:!!toolkitRelease.version; text:"Puntos Vuela Toolkit · Última versión: "+(toolkitRelease.version||""); color:secondaryText; font.pixelSize: rem(0.75) }
                        GridLayout {
                            Layout.fillWidth:true; columns:width>850?3:2; columnSpacing:rem(0.875); rowSpacing:rem(0.875)
                            Repeater {
                                model:visibleFeaturedApps
                                delegate:Rectangle {
                                    id:homeAppCard
                                    Layout.fillWidth:true; Layout.preferredHeight:rem(15.375); radius:rem(1.1875); clip:true
                                    color:homeCardHover.containsMouse?(darkTheme?"#3A424D":"#FFFDF5"):panel
                                    border.color:homeCardHover.containsMouse?accent:panelBorder
                                    Behavior on color { ColorAnimation { duration:170 } }
                                    Behavior on border.color { ColorAnimation { duration:170 } }
                                    MouseArea { id:homeCardHover; anchors.fill:parent; hoverEnabled:true; z:-1; onClicked:{selectedHomeApp=modelData;appDetailDialog.open()} }
                                    Rectangle {
                                        anchors.top:parent.top; anchors.left:parent.left; anchors.right:parent.right
                                        height:rem(1.8125)
                                        color:modelData.official?(darkTheme?"#414A55":"#E9EDF2"):accent
                                        RowLayout {
                                            anchors.fill:parent; anchors.leftMargin:rem(0.75); anchors.rightMargin:rem(0.75); spacing:rem(0.4375)
                                            Rectangle { width:rem(0.4375);height:rem(0.4375);radius:rem(0.25);color:modelData.official?"#AEB8C4":"#202226" }
                                            Text {
                                                text:modelData.official?"CATÁLOGO APPIMAGE":"PUNTO VUELA MONTEJAQUE"
                                                color:modelData.official?"#FFFFFF":"#202226"
                                                font.pixelSize: rem(0.75);font.bold:true;font.letterSpacing:rem(0.0625)
                                                Layout.fillWidth:true
                                            }
                                            Text { text:modelData.official?"COMUNIDAD":"DESARROLLO LOCAL";color:modelData.official?"#D8DEE6":"#51430A";font.pixelSize: rem(0.75);font.bold:true }
                                        }
                                    }
                                    ColumnLayout {
                                        anchors.fill:parent; anchors.leftMargin:rem(0.9375); anchors.rightMargin:rem(0.9375); anchors.topMargin:rem(2.5625); anchors.bottomMargin:rem(0.8125); spacing:rem(0.5)
                                        RowLayout {
                                            Layout.fillWidth:true
                                            Rectangle {
                                                width:rem(3.375);height:rem(3.375);radius:rem(0.8125);color:"#FFFFFF";border.color:"#E8E8E8"
                                                Image { anchors.fill:parent;anchors.margins:rem(0.4375);source:modelData.image;asynchronous:true;fillMode:Image.PreserveAspectFit }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth:true;spacing:rem(0.1875)
                                                Text { text:modelData.title;color:primaryText;font.pixelSize:rem(0.875);font.bold:true;Layout.fillWidth:true;elide:Text.ElideRight }
                                                Text { text:modelData.category;color:muted;font.pixelSize: rem(0.75) }
                                            }
                                        }
                                        Text { text:modelData.desc;color:secondaryText;font.pixelSize: rem(0.75);wrapMode:Text.WordWrap;Layout.fillWidth:true;Layout.fillHeight:true }
                                        RowLayout {
                                            Layout.fillWidth:true
                                            Text { text:modelData.tag;color:accent;font.pixelSize: rem(0.75);font.bold:true }
                                            Item { Layout.fillWidth:true }
                                            Button { text:"Detalles";onClicked: { selectedHomeApp = modelData; appDetailDialog.open() }
                                                 background:Rectangle { radius:rem(0.5625);color:darkTheme?"#414A55":"#F0F1F3";border.color:panelBorder }
                                                 contentItem:Text { text:parent.text;color:primaryText;font.pixelSize: rem(0.75);font.bold:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                            Button { text:"Repositorio";onClicked: Qt.openUrlExternally(modelData.url)
                                                 background:Rectangle { radius:rem(0.5625);color:"transparent";border.color:panelBorder }
                                                 contentItem:Text { text:parent.text;color:primaryText;font.pixelSize: rem(0.75);font.bold:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                            Button { visible:!!modelData.downloadUrl;text:"Instalar";onClicked: appImageManager.installPuntoVuelaTool(modelData.repository)
                                                 background:Rectangle { radius:rem(0.5625);color:accent }
                                                 contentItem:Text { text:parent.text;color:"#202226";font.pixelSize: rem(0.75);font.bold:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                        }
                                    }
                                }
                            }
                        }
                        Dialog {
                            id:appDetailDialog
                            modal:true
                            anchors.centerIn:Overlay.overlay
                            width:Math.min(window.width-48,600)
                            padding:rem(0)
                            closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutside
                            background:Rectangle { radius:rem(1.375);color:panel;border.color:panelBorder;Rectangle { anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right;height:rem(0.3125);radius:rem(0.1875);color:accent } }
                            enter:Transition { ParallelAnimation { NumberAnimation { property:"opacity";from:0;to:1;duration:180 } NumberAnimation { property:"scale";from:0.94;to:1;duration:220;easing.type:Easing.OutCubic } } }
                            exit:Transition { ParallelAnimation { NumberAnimation { property:"opacity";from:1;to:0;duration:130 } NumberAnimation { property:"scale";from:1;to:0.97;duration:130 } } }
                            contentItem:ColumnLayout {
                                spacing:rem(1)
                                RowLayout {
                                    Layout.fillWidth:true
                                    Rectangle { width:rem(4.125);height:rem(4.125);radius:rem(1.0625);color:"#FFFFFF";border.color:"#E8E8E8";Image { anchors.fill:parent;anchors.margins:rem(0.5625);source:selectedHomeApp?selectedHomeApp.image:"";asynchronous:true;fillMode:Image.PreserveAspectFit } }
                                    ColumnLayout { Layout.fillWidth:true; spacing:rem(0.25)
                                         Text { text:selectedHomeApp ? selectedHomeApp.title : "Aplicación"; color:primaryText; font.pixelSize:rem(1.3125); font.bold:true; wrapMode:Text.WordWrap; Layout.fillWidth:true }
                                         Text { text:selectedHomeApp?(selectedHomeApp.category+" · "+selectedHomeApp.kind):"";color:muted;font.pixelSize: rem(0.75) } }
                                    Button { text:"✕";onClicked: appDetailDialog.close()
                                     background:Rectangle { radius:rem(0.625);color:darkTheme?"#414A55":"#F0F1F3" }
                                     contentItem:Text { text:parent.text;color:primaryText;font.pixelSize:rem(0.9375);horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                }
                                Rectangle { Layout.fillWidth:true;height:rem(0.0625);color:panelBorder }
                                Text { text:selectedHomeApp?selectedHomeApp.desc:"";color:secondaryText;font.pixelSize:rem(0.8125);wrapMode:Text.WordWrap;Layout.fillWidth:true }
                                GridLayout { Layout.fillWidth:true;columns:2;columnSpacing:rem(1.125);rowSpacing:rem(0.75)
                                    ColumnLayout { spacing:rem(0.1875)
                                         Text { text:"VERSIÓN"; color:muted; font.pixelSize: rem(0.75); font.bold:true }
                                         Text { text:selectedHomeApp?(selectedHomeApp.version||"Consultar repositorio"):"";color:primaryText;font.pixelSize:rem(0.75) } }
                                    ColumnLayout { spacing:rem(0.1875)
                                         Text { text:"ORIGEN"; color:muted; font.pixelSize: rem(0.75); font.bold:true }
                                         Text { text:selectedHomeApp?(selectedHomeApp.tag||"Puntos Vuela"):"";color:primaryText;font.pixelSize:rem(0.75) } }
                                }
                                RowLayout { Layout.fillWidth:true;spacing:rem(0.5625)
                                    Button { text:"Ver repositorio";Layout.fillWidth:true;onClicked: { if (selectedHomeApp) Qt.openUrlExternally(selectedHomeApp.url) }
                                     background:Rectangle { radius:rem(0.6875);color:"transparent";border.color:panelBorder }
                                     contentItem:Text { text:parent.text;color:primaryText;font.pixelSize: rem(0.75);font.bold:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                    Button { text:"Ver release";visible:!!(selectedHomeApp&&selectedHomeApp.releaseUrl);Layout.fillWidth:true;onClicked: { if (selectedHomeApp) Qt.openUrlExternally(selectedHomeApp.releaseUrl) }
                                     background:Rectangle { radius:rem(0.6875);color:darkTheme?"#414A55":"#F0F1F3" }
                                     contentItem:Text { text:parent.text;color:primaryText;font.pixelSize: rem(0.75);font.bold:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                    Button { text:"Descargar e instalar";visible:!!(selectedHomeApp&&selectedHomeApp.downloadUrl);Layout.fillWidth:true;onClicked: { if (selectedHomeApp) { appImageManager.installPuntoVuelaTool(selectedHomeApp.repository); appDetailDialog.close() } }
                                     background:Rectangle { radius:rem(0.6875);color:accent }
                                     contentItem:Text { text:parent.text;color:"#202226";font.pixelSize: rem(0.75);font.bold:true;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                }
                            }
                        }
                        Text { text: "Fuentes de aplicaciones"; color: primaryText; font.pixelSize: rem(1.0625); font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true; spacing: rem(0.875)
                            Repeater {
                                model: [
                                    {title:"Catálogo oficial AppImage", desc:"Catálogo de aplicaciones AppImage", url:"https://appimage.github.io/"},
                                    {title:"AppImage Community", desc:"Catálogo comunitario oficial", url:"https://appimage.github.io/"}
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: rem(5.5)
                                    radius: rem(0.75); color: panel; border.color: panelBorder
                                    Column {
                                        anchors.fill: parent; anchors.margins: rem(0.875); spacing: rem(0.4375)
                                        Text { text: modelData.title; color: primaryText; font.pixelSize: rem(0.8125); font.bold: true }
                                        Text { text: modelData.desc; color: muted; font.pixelSize: rem(0.75) }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally(modelData.url) }
                                }
                            }
                        }

                    }



                    ColumnLayout {
                        id: catalogPage
                        width: parent.width
                        spacing: rem(0.875)
                        visible: activePage === "Catálogo AppImage"

                        Text { text: "Catálogo de aplicaciones"; color: primaryText; font.pixelSize: rem(1.3125); font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: "Busca en el catálogo comunitario AppImage. Se muestran los requisitos de glibc cuando el editor los ha declarado; las aplicaciones que requieren una versión superior a Ubuntu 20.04 quedan bloqueadas para evitar instalaciones incompatibles."
                            color: secondaryText; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap
                        }
                        Rectangle {
                            Layout.fillWidth: true; radius: rem(0.75); color: panel; border.color: panelBorder
                            implicitHeight: rem(4.125)
                            RowLayout {
                                anchors.fill: parent; anchors.margins: rem(0.75); spacing: rem(0.5)
                                TextField {
                                    id: catalogSearch
                                    Layout.fillWidth: true
                                    placeholderText: "Buscar por nombre, descripción, categoría o autor"
                                    onAccepted: refreshCatalog()
                                }
                                Button { text: "Buscar"; onClicked: refreshCatalog() }
                                Button { text: "Actualizar catálogo"; enabled: !catalogLoading; onClicked: { catalogLoading = true; appImageManager.refreshCatalog() } }
                            }
                        }
                        Text {
                            id: catalogStatus
                            Layout.fillWidth: true
                            text: catalogLoading ? "Cargando catálogo…" : "El catálogo se cargará al abrir esta sección."
                            color: accent; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: rem(0.75)
                            Label { text: "Filtrar por categoría"; color: secondaryText; font.pixelSize: rem(0.75) }
                            ComboBox {
                                id: catalogCategoryFilter
                                Layout.fillWidth: true
                                Layout.maximumWidth: rem(24)
                                model: ["Todas"].concat(Array.from(new Set(catalogItems.map(item => item.category).filter(Boolean))).sort())
                                currentIndex: Math.max(0, model.indexOf(catalogCategory))
                                onActivated: catalogCategory = currentText
                                Accessible.name: "Filtrar aplicaciones por categoría"
                            }
                            Item { Layout.fillWidth: true }
                            Label { text: filteredCatalogItems.length + " resultados"; color: muted; font.pixelSize: rem(0.75) }
                        }
                        GridView {
                            id:officialCatalogGrid
                            Layout.fillWidth:true
                            Layout.preferredHeight:Math.max(rem(22.5),Math.ceil(filteredCatalogItems.length/3)*rem(14.75))
                            cellWidth:width/3
                            cellHeight:rem(14.75)
                            interactive:false
                            model:filteredCatalogItems
                            delegate:Rectangle {
                                width:officialCatalogGrid.cellWidth-12;height:rem(13.375)
                                radius:rem(1);color:panel;border.color:panelBorder
                                ColumnLayout {
                                    anchors.fill:parent;anchors.margins:rem(0.8125);spacing:rem(0.4375)
                                    RowLayout {
                                        Layout.fillWidth:true;spacing:rem(0.625)
                                        Rectangle {
                                            width:rem(3.625);height:rem(3.625);radius:rem(0.8125);color:"#FFFFFF";border.color:"#E8EAF0"
                                            Image { anchors.fill:parent;anchors.margins:rem(0.375);source:modelData.iconUrl||"";asynchronous:true;cache:true;fillMode:Image.PreserveAspectFit;visible:status===Image.Ready }
                                            Text { anchors.centerIn:parent;text:(modelData.name||"?").charAt(0).toUpperCase();color:"#303740";font.pixelSize:rem(1.3125);font.bold:true;visible:parent.children[0].status!==Image.Ready }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth:true;spacing:rem(0.1875)
                                            Text { text:modelData.name;color:primaryText;font.pixelSize:rem(0.75);font.bold:true;wrapMode:Text.WordWrap;maximumLineCount:2;Layout.fillWidth:true }
                                            Text { text:modelData.category;color:accent;font.pixelSize: rem(0.75) }
                                        }
                                    }
                                    Text { text:modelData.description||"Aplicación publicada en el catálogo oficial AppImage.";color:secondaryText;font.pixelSize: rem(0.75);wrapMode:Text.WordWrap;maximumLineCount:3;elide:Text.ElideRight;Layout.fillWidth:true;Layout.fillHeight:true }
                                    Text { text:modelData.compatibility;color:modelData.compatibleUbuntu20?"#62B47A":"#D65A5A";font.pixelSize: rem(0.75);wrapMode:Text.WordWrap;Layout.fillWidth:true }
                                    RowLayout {
                                        Layout.fillWidth:true
                                        Button { text:"Ficha";onClicked:{selectedCatalogApp=modelData;catalogDetailDialog.open()} }
                                        Item { Layout.fillWidth:true }
                                        Button { text:"Instalar";enabled:modelData.compatibleUbuntu20 && (modelData.repository!=="" || modelData.downloadUrl!=="");onClicked:{selectedCatalogApp=modelData;appImageManager.installCatalogApp(modelData.name);catalogStatus.text="Instalando "+modelData.name+"…"} }
                                    }
                                }
                            }
                        }
                        Dialog {
                            id:catalogDetailDialog
                            modal:true
                            anchors.centerIn:Overlay.overlay
                            width:Math.min(window.width-48,620)
                            padding:rem(0)
                            closePolicy:Popup.CloseOnEscape|Popup.CloseOnPressOutside
                            background:Rectangle { radius:rem(1.375);color:panel;border.color:panelBorder;Rectangle { anchors.top:parent.top;anchors.left:parent.left;anchors.right:parent.right;height:rem(0.3125);radius:rem(0.1875);color:accent } }
                            enter:Transition { ParallelAnimation { NumberAnimation { property:"opacity";from:0;to:1;duration:180 } NumberAnimation { property:"scale";from:0.94;to:1;duration:220;easing.type:Easing.OutCubic } } }
                            exit:Transition { ParallelAnimation { NumberAnimation { property:"opacity";from:1;to:0;duration:130 } NumberAnimation { property:"scale";from:1;to:0.97;duration:130 } } }
                            contentItem:ColumnLayout {
                                spacing:rem(0.875)
                                RowLayout {
                                    Layout.fillWidth:true
                                    Rectangle { width:rem(3.875);height:rem(3.875);radius:rem(1);color:"#FFFFFF";border.color:"#E8E8E8";Image { anchors.fill:parent;anchors.margins:rem(0.5);source:selectedCatalogApp?selectedCatalogApp.iconUrl:"";asynchronous:true;fillMode:Image.PreserveAspectFit } }
                                    ColumnLayout { Layout.fillWidth:true; spacing:rem(0.25)
                                         Text { text:selectedCatalogApp ? selectedCatalogApp.name : "Ficha de aplicación"; color:primaryText; font.pixelSize:rem(1.25); font.bold:true; wrapMode:Text.WordWrap; Layout.fillWidth:true }
                                         Text { text:selectedCatalogApp?selectedCatalogApp.category:"";color:muted;font.pixelSize: rem(0.75) } }
                                    Button { text:"✕";onClicked: catalogDetailDialog.close()
                                     background:Rectangle { radius:rem(0.625);color:darkTheme?"#414A55":"#F0F1F3" }
                                     contentItem:Text { text:parent.text;color:primaryText;font.pixelSize:rem(0.9375);horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter } }
                                }
                                Rectangle { Layout.fillWidth:true;height:rem(0.0625);color:panelBorder }
                                Text { text:selectedCatalogApp?(selectedCatalogApp.description||"El catálogo oficial no proporciona descripción para esta aplicación."):"";color:secondaryText;font.pixelSize:rem(0.8125);wrapMode:Text.WordWrap;Layout.fillWidth:true }
                                Text { text:selectedCatalogApp?"Categoría: "+selectedCatalogApp.category+"\nAutor: "+selectedCatalogApp.author+"\nLicencia: "+selectedCatalogApp.license+"\nCompatibilidad: "+selectedCatalogApp.compatibility+"\nRequisito glibc: "+selectedCatalogApp.glibc:"";color:secondaryText;wrapMode:Text.WordWrap;Layout.fillWidth:true }
                                RowLayout {
                                    Layout.fillWidth:true
                                    Button {
                                        text:"Instalar"
                                        enabled:selectedCatalogApp && selectedCatalogApp.compatibleUbuntu20 && (selectedCatalogApp.repository!=="" || selectedCatalogApp.downloadUrl!=="")
                                        onClicked:{catalogStatus.text="Descargando e integrando "+selectedCatalogApp.name+"…";appImageManager.installCatalogApp(selectedCatalogApp.name);catalogDetailDialog.close()}
                                    }
                                    Button { text:"Ver ficha oficial";onClicked:if(selectedCatalogApp)Qt.openUrlExternally(selectedCatalogApp.catalogUrl||"https://appimage.github.io/") }
                                }
                            }
                        }
                        Text { Layout.fillWidth:true;text:"Catálogo oficial: appimage.github.io/feed.json. Las aplicaciones se descargan desde los enlaces publicados por sus autores y se integran en el menú del usuario, sin permisos de administrador. Las actualizaciones dependen de que la AppImage incluya metadatos compatibles con AppImageUpdate.";color:muted;font.pixelSize: rem(0.75);wrapMode:Text.WordWrap }
                    }

                    ColumnLayout {
                        id: appImagesPage
                        width: parent.width
                        spacing: rem(1)
                        visible: activePage === "Mis aplicaciones"
                        Text { text: "Tus aplicaciones AppImage"; color: primaryText; font.pixelSize: rem(1.25); font.bold: true }
                        Text { Layout.fillWidth: true; text: "Descarga aplicaciones desde enlaces HTTPS. Se guardan en tu carpeta personal y reciben permisos de ejecución automáticamente."; color: secondaryText; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap }
                        Rectangle {
                            Layout.fillWidth: true; radius: rem(0.875); color: panel; border.color: panelBorder
                            implicitHeight: downloadForm.implicitHeight + 30
                            ColumnLayout {
                                id: downloadForm
                                anchors.fill: parent; anchors.margins: rem(1); spacing: rem(0.625)
                                Text { text: "Descargar AppImage"; color: primaryText; font.pixelSize: rem(0.875); font.bold: true }
                                TextField { id: appImageUrl; Layout.fillWidth: true; placeholderText: "Enlace HTTPS directo al archivo .AppImage" }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Button {
                                        text: "Descargar"
                                        onClicked: {
                                            if (!appImageUrl.text.trim()) {
                                                appImageStatus.text = "Introduce un enlace HTTPS directo a una AppImage."
                                                return
                                            }
                                            appImageStatus.text = "Descargando y comprobando la aplicación…"
                                            appImageManager.downloadAppImage(appImageUrl.text.trim())
                                        }
                                    }
                                    Button { text: "Catálogo oficial"; onClicked: { activePage = "Catálogo AppImage"; refreshCatalog() } }
                                    Button { text: "Abrir carpeta"; onClicked: appImageManager.openAppImageFolder() }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Aplicaciones descargadas"; color: primaryText; font.pixelSize: rem(0.9375); font.bold: true }
                            Item { Layout.fillWidth: true }
                            Button { text: "Actualizar lista"; onClicked: refreshAppImages() }
                        }
                        Text { id: appImageStatus; Layout.fillWidth: true; color: secondaryText; wrapMode: Text.WordWrap; font.pixelSize: rem(0.75) }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(150, appImageItems.length * 100)
                            interactive: false
                            model: appImageItems
                            spacing: rem(0.5)
                            delegate: Rectangle {
                                width: ListView.view.width; height: rem(5.75)
                                radius: rem(0.75); color: panel; border.color: panelBorder
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: rem(0.75); spacing: rem(0.5)
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: rem(0.25)
                                        Text { text: modelData.name; color: primaryText; font.pixelSize: rem(0.75); font.bold: true; elide: Text.ElideMiddle; Layout.fillWidth: true }
                                        Text { text: modelData.executable ? "Permisos de ejecución activos" : "Sin permisos de ejecución"; color: muted; font.pixelSize: rem(0.75) }
                                    }
                                    Button {
                                        text: "Abrir"
                                        onClicked: {
                                            const result = JSON.parse(appImageManager.launchAppImage(modelData.path))
                                            appImageStatus.text = modelData.name + ": " + result.message
                                        }
                                    }
                                    Button {
                                        text: "Permisos"
                                        visible: !modelData.executable
                                        onClicked: {
                                            const result = JSON.parse(appImageManager.makeAppImageExecutable(modelData.path))
                                            appImageStatus.text = modelData.name + ": " + result.message
                                            refreshAppImages()
                                        }
                                    }
                                    Button {
                                        text: modelData.customUpdater ? "Abrir gestor" : "Comprobar"
                                        onClicked: {
                                            if (modelData.customUpdater) {
                                                const result = JSON.parse(appImageManager.launchAppImage(modelData.path))
                                                appImageStatus.text = "Este instalador gestiona sus propias versiones: " + result.message
                                            } else {
                                                appImageStatus.text = "Comprobando actualizaciones de " + modelData.name + "…"
                                                appImageManager.checkAppImageUpdate(modelData.path)
                                            }
                                        }
                                    }
                                    Button {
                                        text: modelData.customUpdater ? "Abrir actualizador" : "Actualizar"
                                        onClicked: {
                                            if (modelData.customUpdater) {
                                                const result = JSON.parse(appImageManager.launchAppImage(modelData.path))
                                                appImageStatus.text = "Se ha abierto el actualizador propio: " + result.message
                                            } else {
                                                appImageStatus.text = "Actualizando " + modelData.name + "…"
                                                appImageManager.updateAppImage(modelData.path)
                                            }
                                        }
                                    }
                                    Button {
                                        text: "Eliminar"
                                        onClicked: {
                                            removeDialog.targetPath = modelData.path
                                            removeDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                        Text { Layout.fillWidth: true; text: "La comprobación requiere información de actualización compatible dentro de la AppImage. Si no encuentra AppImageUpdate, el Toolkit descarga el actualizador oficial en tu perfil y verifica su SHA-256; no necesita root. Si no existe esa información, consulta la web del desarrollador y descarga la nueva versión manualmente."; color: muted; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap }
                        Component.onCompleted: refreshAppImages()
                    }

                    ColumnLayout {
                        id: helpPage
                        width: parent.width
                        spacing: rem(1)
                        visible: activePage === "Ayuda"
                        Text { text: "Guía de ayuda"; color: primaryText; font.pixelSize: rem(1.375); font.bold: true }
                        Text { text: "PUNTO VUELA LINUX TOOLKIT"; color: accent; font.pixelSize: rem(0.75); font.bold: true; font.letterSpacing: rem(0.0625) }
                        Rectangle {
                            Layout.fillWidth: true; radius: rem(0.875); color: heroStart; border.color: panelBorder
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: rem(1.125); spacing: rem(0.5)
                                Text { text: "Tus aplicaciones, organizadas en un solo lugar"; color: "#202226"; font.pixelSize: rem(1.0625); font.bold: true }
                                Text { text: "Las AppImages se guardan en ~/.local/share/punto-vuela-linux-toolkit/AppImages. No necesitas permisos de administrador para descargarlas o gestionarlas."; color: "#343434"; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap; Layout.fillWidth: true }
                            }
                        }
                        Repeater {
                            model: [
                                {title:"1. Descargar", body:"En Mis aplicaciones, introduce el enlace HTTPS directo al archivo .AppImage. El Toolkit valida que el archivo sea ELF y lo guarda en tu carpeta personal."},
                                {title:"2. Ejecutar", body:"Al finalizar la descarga, el archivo recibe permisos de ejecución automáticamente. Pulsa Abrir carpeta para localizarlo."},
                                {title:"3. Actualizar", body:"Pulsa Comprobar. Si la AppImage incluye información compatible, AppImageUpdate consulta el origen del autor. Si existe una versión nueva, pulsa Actualizar."},
                                {title:"4. Sin actualizador", body:"No todas las AppImages del catálogo incluyen información de actualización. En ese caso no se puede confirmar automáticamente si hay una versión posterior: consulta la web del desarrollador."},
                                {title:"5. Seguridad", body:"Una AppImage es un programa ejecutable. Descarga software de fuentes fiables. La validación ELF no es un análisis antivirus ni verifica la identidad del autor. Las actualizaciones requieren una acción explícita."}
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true; radius: rem(0.75); color: panel; border.color: panelBorder
                                implicitHeight: helpText.implicitHeight + 30
                                ColumnLayout {
                                    id: helpText
                                    anchors.fill: parent; anchors.margins: rem(0.9375); spacing: rem(0.375)
                                    Text { text: modelData.title; color: primaryText; font.pixelSize: rem(0.8125); font.bold: true }
                                    Text { text: modelData.body; color: secondaryText; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                }
                            }
                        }
                        Text { Layout.fillWidth: true; text: "Guía completa: docs/GUIA-DE-AYUDA.md en el repositorio."; color: muted; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap }
                    }

                    ColumnLayout {
                        id: contactPage
                        width: parent.width
                        spacing: rem(1.125)
                        visible: activePage === "Contacto e información"

                        Text { text: "Solicita incorporar una aplicación"; color: primaryText; font.pixelSize: rem(1.375); font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: "Envía una propuesta para estudiar su inclusión en el catálogo Punto Vuela Linux Toolkit. Puedes enviar la solicitud directamente por correo corporativo o compartirla por WhatsApp."
                            color: secondaryText; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true; radius: rem(1); color: panel; border.color: panelBorder
                            implicitHeight: requestForm.implicitHeight + 36
                            ColumnLayout {
                                id: requestForm
                                anchors.fill: parent; anchors.margins: rem(1.125); spacing: rem(0.75)
                                Text { text: "Datos del centro y del/de la AIL"; color: primaryText; font.pixelSize: rem(0.9375); font.bold: true }
                                GridLayout {
                                    Layout.fillWidth: true; columns: width > rem(42.5) ? 2 : 1; columnSpacing: rem(0.75); rowSpacing: rem(0.5625)
                                    TextField {
                                        id: centreSearchField
                                        Layout.fillWidth: true
                                        Layout.columnSpan: parent.columns
                                        placeholderText: "Buscar centro por nombre, municipio o provincia…"
                                        enabled: !puntoVuelaCentresLoading && puntoVuelaCentres.length > 0
                                        onTextChanged: {
                                            const query = text.trim().toLocaleLowerCase()
                                            filteredPuntoVuelaCentres = query.length
                                                ? puntoVuelaCentres.filter(item => (item.name + " " + item.municipality + " " + item.province).toLocaleLowerCase().includes(query))
                                                : puntoVuelaCentres
                                            puntoVuelaField.currentIndex = -1
                                        }
                                    }
                                    ComboBox {
                                        id: puntoVuelaField
                                        Layout.fillWidth: true
                                        Layout.columnSpan: parent.columns
                                        model: filteredPuntoVuelaCentres
                                        textRole: "name"
                                        enabled: !puntoVuelaCentresLoading && filteredPuntoVuelaCentres.length > 0
                                        displayText: currentIndex >= 0 ? currentText : (puntoVuelaCentresLoading ? "Cargando centros oficiales…" : "Selecciona tu Punto Vuela *")
                                        onActivated: {
                                            if (index >= 0 && index < filteredPuntoVuelaCentres.length)
                                                selectPuntoVuelaCentre(filteredPuntoVuelaCentres[index])
                                        }
                                    }
                                    Label {
                                        id: centreDetailsStatus
                                        Layout.fillWidth: true
                                        Layout.columnSpan: 2
                                        text: "Al seleccionar el centro se consultará su ficha oficial y se completarán los datos públicos del AIL y del centro."
                                        color: muted
                                        wrapMode: Text.WordWrap
                                        font.pixelSize: rem(0.75)
                                    }
                                    Button {
                                        Layout.columnSpan: parent.columns
                                        visible: selectedCentreSourceUrl.length > 0
                                        text: "Ver ficha oficial en puntosvuela.es"
                                        onClicked: Qt.openUrlExternally(selectedCentreSourceUrl)
                                    }
                                    TextField { id: municipioField; Layout.fillWidth: true; placeholderText: "Municipio"; readOnly: true }
                                    TextField { id: provinciaField; Layout.fillWidth: true; placeholderText: "Provincia"; readOnly: true }
                                    TextField { id: ailField; Layout.fillWidth: true; placeholderText: "Nombre y apellidos del/de la AIL *" }
                                    TextField { id: telefonoField; Layout.fillWidth: true; placeholderText: "Teléfono de contacto *" }
                                    TextField { id: correoField; Layout.fillWidth: true; placeholderText: "Correo electrónico *" }
                                }
                                Rectangle { Layout.fillWidth: true; height: rem(0.0625); color: panelBorder }
                                Text { text: "Aplicación propuesta"; color: primaryText; font.pixelSize: rem(0.9375); font.bold: true }
                                GridLayout {
                                    Layout.fillWidth: true; columns: width > rem(42.5) ? 2 : 1; columnSpacing: rem(0.75); rowSpacing: rem(0.5625)
                                    TextField { id: softwareField; Layout.fillWidth: true; placeholderText: "Nombre de la aplicación *" }
                                    TextField { id: enlaceField; Layout.fillWidth: true; placeholderText: "Web oficial o descarga" }
                                    ComboBox { id: distroField; Layout.fillWidth: true; model: ["Ubuntu", "Debian", "Linux Mint", "Fedora", "Otra distribución", "Cualquier distribución"] }
                                }
                                TextArea {
                                    id: motivoField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: rem(6.5)
                                    visible: true
                                    placeholderText: "Motivo: utilidad y necesidad que cubriría la aplicación *"
                                    placeholderTextColor: muted
                                    color: primaryText
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    background: Rectangle { color: searchColor; border.color: panelBorder; radius: rem(0.5) }
                                }
                                TextArea {
                                    id: observacionesField
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: rem(4.75)
                                    placeholderText: "Observaciones adicionales (opcional)"
                                    placeholderTextColor: muted
                                    color: primaryText
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    background: Rectangle { color: searchColor; border.color: panelBorder; radius: rem(0.5) }
                                }
                                TextField {
                                    id: honeypotField
                                    visible: false
                                    enabled: false
                                    width: rem(0); height: rem(0)
                                    opacity: 0
                                    text: ""
                                    placeholderText: "No rellenar"
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    radius: rem(0.625); color: panel; border.color: panelBorder
                                    implicitHeight: legalColumn.implicitHeight + 24
                                    ColumnLayout {
                                        id: legalColumn
                                        anchors.fill: parent; anchors.margins: rem(0.75); spacing: rem(0.5625)
                                        Label { text: "INFORMACIÓN LEGAL Y ACEPTACIONES OBLIGATORIAS"; color: primaryText; font.bold: true; font.pixelSize: rem(0.75) }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Button { text: "Protección de datos y privacidad"; onClicked: Qt.openUrlExternally("https://toolkit.javigallego.es/privacy") }
                                            Button { text: "Términos y condiciones"; onClicked: Qt.openUrlExternally("https://toolkit.javigallego.es/terms") }
                                        }
                                        CheckBox {
                                            id: dataProtectionAcknowledged
                                            Layout.fillWidth: true
                                            spacing: rem(0.625)
                                            implicitHeight: Math.max(dataProtectionIndicator.implicitHeight, dataProtectionLabel.implicitHeight) + rem(0.5)
                                            indicator: Rectangle {
                                                id: dataProtectionIndicator
                                                implicitWidth: rem(1.25); implicitHeight: rem(1.25)
                                                x: 0; y: (parent.height - height) / 2
                                                radius: rem(0.25)
                                                color: parent.checked ? accent : searchColor
                                                border.color: parent.checked ? accent : muted
                                                border.width: rem(0.1)
                                                Text { anchors.centerIn: parent; text: "✓"; color: "#202226"; font.bold: true; font.pixelSize: rem(0.875); visible: parent.parent.checked }
                                            }
                                            enabled: true
                                            checked: dataProtectionRead
                                            onClicked: { if (!dataProtectionRead) dataProtectionDialog.open() }
                                            contentItem: Label {
                                                id: dataProtectionLabel
                                                text: "He leído la información sobre protección de datos (consulta el botón correspondiente)."
                                                textFormat: Text.PlainText
                                                color: primaryText
                                                opacity: 1
                                                wrapMode: Text.WordWrap
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: rem(0.25)
                                                rightPadding: rem(0.5)
                                                font.pixelSize: rem(0.8125)
                                            }
                                        }
                                        CheckBox {
                                            id: privacyAcknowledged
                                            Layout.fillWidth: true
                                            spacing: rem(0.625)
                                            implicitHeight: Math.max(privacyIndicator.implicitHeight, privacyLabel.implicitHeight) + rem(0.5)
                                            indicator: Rectangle {
                                                id: privacyIndicator
                                                implicitWidth: rem(1.25); implicitHeight: rem(1.25)
                                                x: 0; y: (parent.height - height) / 2
                                                radius: rem(0.25)
                                                color: parent.checked ? accent : searchColor
                                                border.color: parent.checked ? accent : muted
                                                border.width: rem(0.1)
                                                Text { anchors.centerIn: parent; text: "✓"; color: "#202226"; font.bold: true; font.pixelSize: rem(0.875); visible: parent.parent.checked }
                                            }
                                            enabled: true
                                            checked: privacyPolicyRead
                                            onClicked: { if (!privacyPolicyRead) privacyPolicyDialog.open() }
                                            contentItem: Label {
                                                id: privacyLabel
                                                text: "He leído la política de privacidad (consulta el documento completo)."
                                                textFormat: Text.PlainText
                                                color: primaryText
                                                opacity: 1
                                                wrapMode: Text.WordWrap
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: rem(1.625)
                                                rightPadding: rem(0.5)
                                                font.pixelSize: rem(0.8125)
                                            }
                                        }
                                        CheckBox {
                                            id: termsAcknowledged
                                            Layout.fillWidth: true
                                            spacing: rem(0.625)
                                            implicitHeight: Math.max(termsIndicator.implicitHeight, termsLabel.implicitHeight) + rem(0.5)
                                            indicator: Rectangle {
                                                id: termsIndicator
                                                implicitWidth: rem(1.25); implicitHeight: rem(1.25)
                                                x: 0; y: (parent.height - height) / 2
                                                radius: rem(0.25)
                                                color: parent.checked ? accent : searchColor
                                                border.color: parent.checked ? accent : muted
                                                border.width: rem(0.1)
                                                Text { anchors.centerIn: parent; text: "✓"; color: "#202226"; font.bold: true; font.pixelSize: rem(0.875); visible: parent.parent.checked }
                                            }
                                            enabled: true
                                            checked: termsAccepted
                                            onClicked: { if (!termsAccepted) termsDialog.open() }
                                            contentItem: Label {
                                                id: termsLabel
                                                text: "He leído y acepto los términos y condiciones de uso (consulta el documento completo)."
                                                textFormat: Text.PlainText
                                                color: primaryText
                                                opacity: 1
                                                wrapMode: Text.WordWrap
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: rem(1.625)
                                                rightPadding: rem(0.5)
                                                font.pixelSize: rem(0.8125)
                                            }
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            text: "Debes consultar la información de protección de datos, la política de privacidad y los términos y condiciones, y marcar las tres casillas."
                                            color: muted; wrapMode: Text.WordWrap; font.pixelSize: rem(0.75)
                                        }
                                    }
                                }
                                Button {
                                    text: "Generar solicitud y vista previa"
                                    onClicked: {
                                        if (puntoVuelaField.currentIndex < 0 || !municipioField.text.trim() || !provinciaField.text.trim() || !ailField.text.trim() ||
                                            !telefonoField.text.trim() || !correoField.text.trim() || !softwareField.text.trim() || !motivoField.text.trim()) {
                                            formError.text = "Completa los campos obligatorios para continuar."; formError.visible = true; return
                                        }
                                        if (!dataProtectionAcknowledged.checked || !privacyAcknowledged.checked || !termsAcknowledged.checked) {
                                            formError.text = "Debes consultar y aceptar la información legal, la política de privacidad y los términos y condiciones."; formError.visible = true; return
                                        }
                                        formError.visible = false
                                        previewText.text =
                                            "SOLICITUD DE INCORPORACIÓN DE APLICACIÓN\n\n" +
                                            "PUNTO VUELA\nCentro: " + puntoVuelaField.currentText.trim() + "\nMunicipio: " + municipioField.text.trim() + "\nProvincia: " + provinciaField.text.trim() + "\n\n" +
                                            "PERSONA DE CONTACTO\nNombre: " + ailField.text.trim() + "\nTeléfono: " + telefonoField.text.trim() +
                                            "\nCorreo: " + correoField.text.trim() + "\n\n" +
                                            "APLICACIÓN\nNombre: " + softwareField.text.trim() + "\nEnlace: " + (enlaceField.text.trim() || "No indicado") +
                                            "\nDistribución: " + distroField.currentText + "\nUtilidad: " + motivoField.text.trim() +
                                            "\nObservaciones: " + (observacionesField.text.trim() || "Ninguna")
                                        previewVisible = true
                                    }
                                }
                                Text { id: formError; Accessible.role: Accessible.AlertMessage; visible: false; color: "#D65A5A"; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; visible: previewVisible; radius: rem(1); color: panel; border.color: panelBorder
                            implicitHeight: previewColumn.implicitHeight + 36
                            ColumnLayout {
                                id: previewColumn
                                anchors.fill: parent; anchors.margins: rem(1.125); spacing: rem(0.625)
                                Text { text: "Vista previa editable"; color: primaryText; font.pixelSize: rem(0.9375); font.bold: true }
                                TextArea {
                                    id: previewText; Layout.fillWidth: true; Layout.preferredHeight: rem(16.25)
                                    wrapMode: TextEdit.Wrap; selectByMouse: true; color: primaryText
                                    background: Rectangle { color: searchColor; border.color: panelBorder; radius: rem(0.5) }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Button {
                                        text: "Enviar por WhatsApp"
                                        onClicked: {
                                            if (!dataProtectionAcknowledged.checked || !privacyAcknowledged.checked || !termsAcknowledged.checked) {
                                                emailStatus.text = "Debes consultar y aceptar la información legal, la política de privacidad y los términos y condiciones."; emailStatus.color = "#D65A5A"; return
                                            }
                                            if (previewText.text.trim()) Qt.openUrlExternally("https://wa.me/34633402959?text=" + encodeURIComponent(previewText.text))
                                        }
                                    }
                                    Button {
                                        text: emailSending ? "Enviando correo…" : "Enviar correo"
                                        enabled: !emailSending
                                        onClicked: {
                                            if(puntoVuelaField.currentIndex < 0 || !municipioField.text.trim() || !provinciaField.text.trim() || !ailField.text.trim() || !telefonoField.text.trim() || !correoField.text.trim() || !softwareField.text.trim() || !motivoField.text.trim()) {
                                                emailStatus.text="Completa los campos obligatorios antes de enviar."; emailStatus.color="#D65A5A"; return
                                            }
                                            if (!dataProtectionAcknowledged.checked || !privacyAcknowledged.checked || !termsAcknowledged.checked) {
                                                emailStatus.text="Debes confirmar que has leído la información de protección de datos."; emailStatus.color="#D65A5A"; return
                                            }
                                            const payload={
                                                center:puntoVuelaField.currentText.trim(),municipality:municipioField.text.trim(),province:provinciaField.text.trim(),
                                                contact:ailField.text.trim(),phone:telefonoField.text.trim(),reply_email:correoField.text.trim(),
                                                application:softwareField.text.trim(),url:enlaceField.text.trim(),
                                                distribution:distroField.currentText,purpose:motivoField.text.trim(),notes:observacionesField.text.trim(),data_protection_read:dataProtectionAcknowledged.checked,privacy_policy_read:privacyAcknowledged.checked,terms_accepted:termsAcknowledged.checked,website:honeypotField.text.trim()
                                            }
                                            emailSending = true
                                            emailStatus.text="Conectando con el servicio de correo y enviando la propuesta…"; emailStatus.color=secondaryText
                                            appImageManager.sendApplicationRequest(JSON.stringify(payload))
                                        }
                                    }
                                }
                                Text { id: emailStatus; Accessible.role: Accessible.Status; text: "Al pulsar «Enviar correo», la propuesta se envía al buzón corporativo y se remite una copia a tu dirección. La aplicación confirmará el resultado."; color: muted; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; radius: rem(1); color: panel; border.color: panelBorder
                            implicitHeight: rem(9.625)
                            RowLayout {
                                anchors.fill: parent; anchors.margins: rem(1.25); spacing: rem(1.125)
                                Rectangle { width: rem(4.5); height: rem(4.5); radius: rem(1.125); color: accent
                                    Image { anchors.fill: parent; anchors.margins: rem(0.3125); source: Qt.resolvedUrl("../assets/logotipovuela.svg"); fillMode: Image.PreserveAspectFit }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: rem(0.3125)
                                    Text { text: "Desarrollo y mantenimiento"; color: primaryText; font.pixelSize: rem(1); font.bold: true }
                                    Text { text: "Punto Vuela Montejaque"; color: secondaryText; font.pixelSize: rem(0.8125); font.bold: true }
                                    Text { text: "Desarrollador: Francisco Javier Gallego Orellana"; color: secondaryText; font.pixelSize: rem(0.75) }
                                    Text { text: "Proyecto comunitario de herramientas y aplicaciones para Linux."; color: muted; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap }
                                    Text { text: "Repositorio oficial: github.com/Montejaque/punto-vuela-linux-toolkit"; color: accent; font.pixelSize: rem(0.75); wrapMode: Text.WordWrap }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
