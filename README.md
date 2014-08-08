Tools
=====

## Data structure and modell ##

### Core file ###

### Source files ###

## Workflow (first steps with build script) ##

### ANT build script ###

### Finale export to MusicXML ###

### MusicXML part wise to time wise ###

Use script MusicXML_parttime.xsl available at [developers page of musicxml.org](http://www.musicxml.com/for-developers/musicxml-xslt/partwise-to-timewise/) for transforming part wise MusicXML to time wise MusicXML.

```shell
ant musicXMLPartToTime -Dfreidi.in=INPUT_MUSICXML -Dfreidi.out=OUTPUT_MUSICXML
e.g. ant musicXMLPartToTime -Dfreidi.in=musicXML/mov_02_partwise.xml -Dfreidi.out=musicXML/mov_02_timewise.xml
```

### MusicXML to MEI ###

Use script musicxml2mei-3.0.xsl available at [google code of music-encoding](https://music-encoding.googlecode.com/svn/trunk/tools/musicxml2mei/musicxml2mei-3.0.xsl) for transforming time wise MusicXML to MEI.

```shell
ant musicXMLToMEI -Dfreidi.in=INPUT_MUSICXML -Dfreidi.out=OUTPUT_MEI
e.g. musicXMLToMEI -Dfreidi.in=musicXML/mov_02_timewise.xml -Dfreidi.out=mei/mov_02.xml
```

### Clean up the MEI ###

This script resolves some issues not covered with the standard script from the previous step.

This includes following tasks:

* resolve bTrems, fTrems
* resolve intermediary scoreDefs and staffDefs
* strip mei:pb and mei:sb
* convert chords with stemmod to bTrem
* convert mei:artic and mei:accid to respective attributes
* generate mei:bTrem elements where applicable

```shell
ant improveMusic -Dfreidi.in=INPUT_MEI -Dfreidi.out=OUTPUT_MEI -Dfreidi.mov.id=MOV_ID
e.g. ant improveMusic -Dfreidi.in=mei/mov_02.xml -Dfreidi.out=mei/mov_02_improved.xml -Dfreidi.mov.id=mov_02

```

### Include MEI data in Core file and create blueprint ###

This script includes a movement into the core file.

```shell
ant includeMusicInCore -Dfreidi.in=INPUT_MEI -Dfreidi.core=CORE_MEI -Dfreidi.core.tmp=TMP_CORE_MEI -Dfreidi.blueprint=BLUEPRINT_MEI -Dfreidi.mov.id=MOV_ID
e.g. ant includeMusicInCore -Dfreidi.in=mei/mov_02_improved.xml -Dfreidi.core=edition/core.xml -Dfreidi.core.tmp=edition/core_tmp.xml -Dfreidi.blueprint=mei/blueprint_mov_02.xml -Dfreidi.mov.id=mov_02
```

### Include blueprint data in source files ###

This script includes a movement into the source files.

```shell
ant includeMusicInSources -Dfreidi.blueprint=BLUEPRINT_MEI -Dfreidi.source.dir=SOURCES_DIR -Dfreidi.mov.id=MOV_ID
e.g. ant includeMusicInSources -Dfreidi.blueprint=mei/blueprint_mov_02.xml -Dfreidi.source.dir=sources -Dfreidi.mov.id=mov_02
```

### Generate merged version from Core and sources ###

This script merges core data into source files.

```shell
ant mergeCoreAndSources -Dfreidi.core=CORE_MEI -Dfreidi.source.dir=SOURCES_DIR -Dfreidi.dest.dir=DEST_DIR
e.g. ant mergeCoreAndSources -Dfreidi.core=edition/core.xml -Dfreidi.source.dir=sources -Dfreidi.dest.dir=dest
```

### Prepare for proofreading ###

This script splits a source file in multiple files per page.

```shell
ant splitInPages -Dfreidi.in=INPUT_MEI -Dfreidi.dest.dir=DEST_DIR -Dfreidi.mov.id=MOV_ID
e.g. ant splitInPages -Dfreidi.in=sources/A.xml -Dfreidi.dest.dir=dest -Dfreidi.mov.id=2
```

## License ##

The FreiDi tools are released to the public under the terms of the [GNU GPL v.3](http://www.gnu.org/copyleft/gpl.html) open source license.