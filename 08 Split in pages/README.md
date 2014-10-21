Split a source file in multiple files per page
==============================================

This script splits a source file in multiple files per page

```shell
ant splitInPages -Dfreidi.in=INPUT_MEI -Dfreidi.dest.dir=DEST_DIR -Dfreidi.mov.id=MOV_ID
e.g. ant splitInPages -Dfreidi.in=sources/A.xml -Dfreidi.dest.dir=dest -Dfreidi.mov.id=2
```

This task generates a web xar for moving the files to a eXist database

```shell
ant generateXarPackage -Dfreidi.src.dir=SRC_DIR -Dfreidi.out=OUTPUT-XAR -Dfreidi.source.mov=SOURCE_MOV -Dfreidi.exist.col=EXIST_COL 
e.g. generateXarPackage -Dfreidi.src.dir=sources/A_mov0 -Dfreidi.out=build-dir/A_mov0.xar -Dfreidi.source.mov=A_mov0 -Dfreidi.exist.col=/db/contents/A_mov0 
```

Beware that -Dfreidi.exist.col is an optional parameter and will default to:
'pitchtool-data/SOURCE-SIGLUM/SOURCE-MOV'
e.g. 'pitchtool-data/A/A_mov5'

where  SOURCE-SIGLUM is a substring-beore '_' from SOURCE-MOV (-Dfreidi.source-mov)