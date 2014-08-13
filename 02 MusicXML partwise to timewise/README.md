MusicXML partwise to timewise
=============================

Use script MusicXML_parttime.xsl available at [developers page of musicxml.org](http://www.musicxml.com/for-developers/musicxml-xslt/partwise-to-timewise/) for transforming part wise MusicXML to time wise MusicXML and save the file in the corresponding folder.

```
ant musicXMLPartToTime -Dfreidi.in=INPUT_MUSICXML -Dfreidi.out=OUTPUT_MUSICXML
e.g. ant musicXMLPartToTime -Dfreidi.in=musicXML/mov_02_partwise.xml -Dfreidi.out=musicXML/mov_02_timewise.xml
```
