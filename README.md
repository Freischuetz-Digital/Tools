Tools
=====

## Data structure and model ##

The tools for the BMBF-funded project Freischütz Digital are built on a newly thought data model for music encoding resp. digital editions of music. Each source of the opera is considered equal and is encoded independently, however, there will be one ’core’-file that acts as driver for all the sources. This core-file will contain an edited version of the music and variants from all sources. All source-files will point to the right place in the edition-file. The workflow represents all steps (from a single Finale-file to XML-snipptes for a single page) that need to be taken in order to be able to proofread data. This is necessary to create an edition, because firstly, all datasets are similar to the music that derives from the Weber-Gesamtausgabe. Not before the music is proofread the concept of core-/source-files is valid.

### Core file ###

### Source files ###

## Workflow (first steps with build script) ##

### ANT build script ###

Requires ANT installed on your plattform (https://ant.apache.org/).

The ANT build script defines tasks to transform your data via commandline. Invoking ANT without any further commands via commandline will prompt a  "help" listing all available sub-tasks.

#### Notice for Windows users ####

*XSLT-Processor*

Windows default to XALAN but our stylesheets were developed with Saxon. We recomment callin ant with the -lib parameter set to a saxon JAR-file, e.g.

```shell
ant -lib path\to\saxon9.jar improveMusic -Dfreidi.in=mei/mov_02.xml -Dfreidi.out=mei/mov_02_improved.xml -Dfreidi.mov.id=mov_02
```

*Powershell*

Invoking an ANT task from Powershell might result in an error message that certain parameters for the task are not defined, although you entered all parameters as described, e.g.

```shell
ant improveMusic -Dfreidi.in=mei/mov_02.xml -Dfreidi.out=mei/mov_02_improved.xml -Dfreidi.mov.id=mov_02
```

Solution to this is enclosing all "freidi" parameters in double quotes ("), e.g.

```shell
ant improveMusic "-Dfreidi.in=mei/mov_02.xml" "-Dfreidi.out=mei/mov_02_improved.xml" "-Dfreidi.mov.id=mov_02"
```

### Finale export to MusicXML ###

### MusicXML part wise to time wise ###

Use script MusicXML_parttime.xsl available at [developers page of musicxml.org](http://www.musicxml.com/for-developers/musicxml-xslt/partwise-to-timewise/) for transforming part wise MusicXML to time wise MusicXML and save the file in the corresponding folder.

```shell
ant musicXMLPartToTime -Dfreidi.in=INPUT_MUSICXML -Dfreidi.out=OUTPUT_MUSICXML
e.g. ant musicXMLPartToTime -Dfreidi.in=musicXML/mov_02_partwise.xml -Dfreidi.out=musicXML/mov_02_timewise.xml
```

### MusicXML to MEI ###

Use script musicxml2mei-3.0.xsl available at [google code of music-encoding](https://music-encoding.googlecode.com/svn/trunk/tools/musicxml2mei/musicxml2mei-3.0.xsl) for transforming time wise MusicXML to MEI and save the file in the corresponding folder.

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

The MOV_ID specifies the attribute @xml:id that will be appended to the mdiv-element.

```shell
ant improveMusic -Dfreidi.in=INPUT_MEI -Dfreidi.out=OUTPUT_MEI -Dfreidi.mov.id=MOV_ID
e.g. ant improveMusic -Dfreidi.in=mei/mov_02.xml -Dfreidi.out=mei/mov_02_improved.xml -Dfreidi.mov.id=mov_02

```

### Include MEI data in Core file and create blueprint ###

This script includes a movement into the core file and generates a blueprint file that is included into the source files in the next step.

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

This task generates a web xar for moving the files to a eXist database

```shell
ant generateXarPackage -Dfreidi.src.dir=SRC_DIR -Dfreidi.out=OUTPUT-XAR -Dfreidi.source.mov=SOURCE_MOV -Dfreidi.exist.col=EXIST_COL 
e.g. generateXarPackage -Dfreidi.src.dir=sources/A_mov0 -Dfreidi.out=build-dir/A_mov0.xar -Dfreidi.source.mov=A_mov0 -Dfreidi.exist.col=/db/contents/A_mov0 
```


## License ##

The FreiDi tools are released to the public under the terms of the [GNU GPL v.3](http://www.gnu.org/copyleft/gpl.html) open source license.