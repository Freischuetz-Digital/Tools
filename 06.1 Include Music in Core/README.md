Include music in Core
=====================

This script includes a movement into the core file

```shell
ant includeMusicInCore -Dfreidi.in=INPUT_MEI -Dfreidi.core=CORE_MEI -Dfreidi.core.tmp=TMP_CORE_MEI -Dfreidi.blueprint=BLUEPRINT_MEI -Dfreidi.mov.id=MOV_ID
e.g. ant includeMusicInCore -Dfreidi.in=mei/mov_02_improved.xml -Dfreidi.core=edition/core.xml -Dfreidi.core.tmp=edition/core_tmp.xml -Dfreidi.blueprint=mei/blueprint_mov_02.xml -Dfreidi.mov.id=mov_02
```