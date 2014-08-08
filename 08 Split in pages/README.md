Split a source file in multiple files per page
==============================================

This script splits a source file in multiple files per page

```shell
ant splitInPages -Dfreidi.in=INPUT_MEI -Dfreidi.dest.dir=DEST_DIR -Dfreidi.mov.id=MOV_ID
e.g. ant splitInPages -Dfreidi.in=sources/A.xml -Dfreidi.dest.dir=dest -Dfreidi.mov.id=2
```