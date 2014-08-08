MusicXML to MEI
===============

Use script musicxml2mei-3.0.xsl available at [google code of music-encoding](https://music-encoding.googlecode.com/svn/trunk/tools/musicxml2mei/musicxml2mei-3.0.xsl) for transforming time wise MusicXML to MEI.

```shell
ant musicXMLToMEI -Dfreidi.in=INPUT_MUSICXML -Dfreidi.out=OUTPUT_MEI
e.g. musicXMLToMEI -Dfreidi.in=musicXML/mov_02_timewise.xml -Dfreidi.out=mei/mov_02.xml
```
