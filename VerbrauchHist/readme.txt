csvfile.pas
VerbrauchHist.cfg
VerbrauchHist.dof
VerbrauchHist.dpr
VerbrauchHist.exe            ... ermittelt aus den Smartmeterdaten das Histogram
                                 wie häufig ein Viertelstundenenergiewert vorkommt.
                                 Weiters wird ein Nutzugsgrad abhängig einer 
                                 Wechselrichterleistung abgeschätzt. 
                                 Hinweis: die Wechselrichternennleistung wird nicht 
                                 wie hier angenommen immer abgegeben. Für den 
                                 tatsächlich zu erwartenden Nutzungsgrad ist eine
                                 geeignete mittlere Wechselrichterleistung zu nehmen.

VIERTELSTUNDENWERTE.csv      ... Input: Smartmeterdaten, 
                                 download von Wiener-Netze Smartmeterportal

Astronomische_Sonne_Wien.txt ... Input: Kopie von der Hompage der ZMAG
                                 Wenn diese Daten vorliegen wird auch ein 
                                 Nacht-Histogram erstellt. Ansonsten findet sich 
                                 alles im Tag-Histogram. Die Tag-Nacht-Grenze wird 
                                 Abends um 1h früher und Morgens um 1h später als 
                                 diese astronomischen Werte genommen.
                                 
VerbrauchHist.csv            ... Output: Histogram/e und theoretische Nutzungsgrad 
                                 der Ernte bezogen auf die Wechselrichterleistung.  

VerbrauchHist.xls            ... In einen Tabellenkalkulationsprogram (hier Kingsoft 
                                 Spreadsheets) als Diagram dargestellt. Hier auch der
                                 Prozentsatz des Verbrauches (am Tag) berechnet, welcher 
                                 unterhalb der Leistung auf der Ordinatenachse liegt.






