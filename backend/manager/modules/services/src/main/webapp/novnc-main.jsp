<%@ taglib prefix="obrand" uri="obrand" %>
<!DOCTYPE html>
<html lang="en" class="noVNC_loading">
<!--
    noVNC client with automatic initialization for oVirt/RHEV-M

    Based on a client by Joel Martin.

    Copyright (C) 2011 Joel Martin
    Copyright (C) 2018 The noVNC Authors
    Licensed under LGPL-3 (see LICENSE.txt)

    Connect parameters are provided in query string:
        http://example.com/?host=HOST&port=PORT&encrypt=1&true_color=1
    -->
<head>
    <title>noVNC</title>
    <meta http-equiv="X-UA-Compatible" content="chrome=1">

    <meta charset="utf-8">

    <style>

        body {
            margin: 0;
            background-color: dimgrey;
            height: 100%;
            display: flex;
            flex-direction: column;
        }
        html {
            height: 100%;
        }

        #top_bar {
            background-color: #6e84a3;
            color: white;
            font: bold 12px Helvetica;
            padding: 6px 5px 4px 5px;
            border-bottom: 1px outset;
        }
        #status {
            text-align: center;
        }
        #sendCtrlAltDelButton {
            position: fixed;
            top: 0px;
            right: 0px;
            border: 1px outset;
            padding: 5px 5px 4px 5px;
            cursor: pointer;
        }

        #screen {
            flex: 1; /* fill remaining space */
            overflow: hidden;
        }

    </style>

    <!-- actual script modules -->
    <script type="module" crossorigin="anonymous">
        // RFB holds the API to connect and communicate with a VNC server
        import RFB from './files/novnc/core/rfb.js';

        let rfb;
        let desktopName;
        let eventData;

        function receiveEvtData(evt) {
            if (evt.data === null || evt.data.password === null || evt.data.connectionTicket === null) {
                alert("Incorrect connection data");
                return;
            }

            eventData = evt.data;

            checkAndConnect();
        };

        if (window.addEventListener) {
            // For standards-compliant web browsers
            window.addEventListener("message", receiveEvtData, false);
        } else {
            window.attachEvent("onmessage", receiveEvtData);
        }

        // When this function is called we have
        // successfully connected to a server
        function connectedToServer(e) {
            status("Connected to " + desktopName);
        }

        // This function is called when we are disconnected
        function disconnectedFromServer(e) {
            if (e.detail.clean) {
                status("Disconnected");
            } else {
                status("Something went wrong, connection is closed");
            }
        }

        // When this function is called, the server requires
        // credentials to authenticate
        function credentialsAreRequired(e) {
            const password = prompt("Password Required:");
            rfb.sendCredentials({ password: password });
        }

        // When this function is called we have received
        // a desktop name from the server
        function updateDesktopName(e) {
            desktopName = e.detail.name;
        }

        // Since most operating systems will catch Ctrl+Alt+Del
        // before they get a chance to be intercepted by the browser,
        // we provide a way to emulate this key sequence.
        function sendCtrlAltDel() {
            rfb.sendCtrlAltDel();
            return false;
        }

        // Show a status text in the top bar
        function status(text) {
            document.getElementById('status').textContent = text;
        }

        // This function extracts the value of one variable from the
        // query string. If the variable isn't defined in the URL
        // it returns the default value instead.
        function readQueryVariable(name, defaultValue) {
            // A URL with a query parameter can look like this:
            // https://www.example.com?myqueryparam=myvalue
            //
            // Note that we use location.href instead of location.search
            // because Firefox < 53 has a bug w.r.t location.search
            const re = new RegExp('.*[?&]' + name + '=([^&#]*)'),
                  match = document.location.href.match(re);
            if (typeof defaultValue === 'undefined') { defaultValue = null; }

            if (match) {
                // We have to decode the URL since want the cleartext value
                return decodeURIComponent(match[1]);
            }

            return defaultValue;
        }

        document.getElementById('sendCtrlAltDelButton')
            .onclick = sendCtrlAltDel;

        document.title = unescape(readQueryVariable('title', 'noVNC'));

        function checkAndConnect() {
            // Read parameters specified in the URL query string
            // By default, use the host and port of server that served this file
            const host = readQueryVariable('host', window.location.hostname);
            let port = readQueryVariable('port', window.location.port);
            const password = eventData.password
            const path = eventData.connectionTicket;

            // | | |         | | |
            // | | | Connect | | |
            // v v v         v v v

            status("Connecting");

            // Build the websocket URL used to connect
            let url = 'wss://' + host;
            if(port) {
                url += ':' + port;
            }
            url += '/' + path;

            // Creating a new RFB object will start a new connection
            rfb = new RFB(document.getElementById('screen'), url,
                          { credentials: { password: password },
                            wsProtocols: ['binary'] });

            // Add listeners to important events from the RFB module
            rfb.addEventListener("connect",  connectedToServer);
            rfb.addEventListener("disconnect", disconnectedFromServer);
            rfb.addEventListener("credentialsrequired", credentialsAreRequired);
            rfb.addEventListener("desktopname", updateDesktopName);

            // Set parameters that can be changed on an active connection
            rfb.viewOnly = readQueryVariable('view_only', false);
            rfb.scaleViewport = readQueryVariable('scale', false);
        }
    </script>

    <obrand:stylesheets />
    <obrand:javascripts />

    <%@ include file="WEB-INF/warning-template.html"%>
    <script src="html-console-common.js"></script>
    <link rel="stylesheet" type="text/css" href="html-console-common.css" />
</head>

<body style="margin: 0px;">
    <div id="top_bar">
        <div id="status">Loading</div>
        <div id="sendCtrlAltDelButton">Send CtrlAltDel</div>
    </div>
    <div id="screen">
        <!-- This is where the remote screen will appear -->
    </div>
</body>
</html>

