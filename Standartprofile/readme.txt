Hier beschreibe ich wie ich die Daten der Standartprofile aus 
dem Smartmeter Webportal der Wiener Netze herunter geladen habe.
Das csv File erzeugt habe. Dessen Format ist analogen dem Format, 
welches man beim herunterladen der eigenen Verbrauchsdaten bekommt.
Somit konnte ich diese der analogen Analyse, die ich im Ordner 
VerbrauchHist für mein Verbrauchsprofil durchgeführt habe, unterziehen.

Zunächst sei gesagt:
Alle hier zur Verfügung gestellte Programme und Quellcodes sind nur zum 
privaten Gebrauch durch private Personen bestimmt. Keinesfalls dürfen
diese zu illegale Zwecke oder kommerzielle Zwecke genützt werden. 

### Ordnerbeschreibung:
fuerForum                      ... Das Ergebnis meiner Analyse.
DelphiAutoInp                  ... Der Autoclicker zur Automatisierung des Download.
DelphiSVG                      ... Programme zur Aufbereitung der svg Files in das 
                                   benötigte csv File.

### Filebeschreibung:
make1P.bat, make3P.bat         ... Commandfiles welche die Aufbereitung der svg Files 
                                   in das csv File macht. Die exe aus DelphiSVG befinden
                                   sich dabei im selben Ordner wie die bat Files. Die Daten
                                   vorw_tag_1P.zip bzw. vorw_tag_3P.zip sind auch im selben 
                                   Ordner entpackt und liegen als Unterordner vor.
VideoSvgDownload.mp4           ... Eine Bildschirmaufzeichnung welche den Download 
                                   einiger svg Files zeigt.

### Datenfilebeschreibung:
vorw_tag_1P.zip                ... svg geordnet nach Monat und csv Ergebnis des Standardprofils
                                   mit Einstellung - vorwiegend Tag - und 1 Personen.
vorw_tag_3P.zip                ... svg geordnet nach Monat und csv Ergebnis des Standardprofils
                                   mit Einstellung - vorwiegend Tag - und 3 Personen.
chart_vorw_tag_2P_Jahr2023.svg ... Das nicht herunter geladen Standardprofil
                                   mit Einstellung - vorwiegend Tag - und 2 Personen.
