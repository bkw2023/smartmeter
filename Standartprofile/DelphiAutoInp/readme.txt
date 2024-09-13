Beschreibung DelphiAutoInp

Alle hier zur Verfügung gestellte Programme und Quellcodes sind nur zum 
privaten Gebrauch durch private Personen bestimmt. Keinesfalls dürfen
diese zu illegale Zwecke oder kommerzielle Zwecke genützt werden. 

Dieses Programm ist ein so genannter Autoclicker. Es können Mauseereignisse und
Tastenereignisse aufgezeichnet werden und abgespielt werden. Es können nur
Ereignisse aufgezeichnet werden die auf Windowsapplikationsniveau sind. Explizit
getestet habe ich den Firefox Browser. 

Hinweis: Spiele verwenden oft ein tieferes Niveau und können hiermit nicht bedient 
         werden.

Ziel dieser Arbeit war den Firefox Webbrowser automatisch bedienen zu können, 
also z.B. Downloads zu automatisieren. Bei der Aufzeichnung werden die Mausbewegungen
komprimiert, wobei die Komprimierungsgrenzen die Maustaste und Tastaturtastenereignisse
sind. Es wird also die Mausbewegung zwischen zwei solchen Ereignissen als geradlinige 
Bewegung aufgezeichnet. Beim Abspielen werden die aufgezeichneten Zeitdifferenzen
zwischen den Ereignissen begrenzt. Nach unten auf mindestens 50ms und nach oben
auf maximal 1000ms.


### Filebeschreibung:

DelphiAutoInp.*            ... die delphi 6 Projektfiles
uMainForm.*                ... das Window der Applikation
uunluremouseevent.pas      ... Kapselung der Entzerrung der Maussimulation.
                               Die Entzerrung hat zwei Größenbereiche und ist 
                               dort linear. Siehe auch testme.
                               Hinweis: 
                               Die implementierte Entzerrung ist für meinen Computer.
                               Andere Computer brauchen ggf. eine andere eigene Entzerrung
                               oder auch keine. 
                               Ich habe weder bei Microsoft noch in Foren dazu etwas gefunden.
uHookTypes.pas             ... gemeinsame Typen und Funktionen mit der nötigen dll
uhook.pas                  ... Interface zur dll

HookInp.*                  ... dll zur Aufzeichnung

testme.*                   ... Testprogramm zur Entzerrungsbestimmung der Maussimulation.
