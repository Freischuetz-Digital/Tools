xquery version "1.0";

(:
remove @dur on mRest
author: Benjamin W. Bohl
date: 2014-04-04
:)

declare namespace mei = 'http://www.music-encoding.org/ns/mei';

import module namespace params = "http://www.freischuetz-digital.de/xq/params" at "params.xqm";

for $file in doc('file:///C:/Users/bwb/Desktop/temp/SVN_FreiDi/data/core.xml')
let $change :=<change n="{count($file//mei:revisionDesc/mei:change)+1}" xmlns="http://www.music-encoding.org/ns/mei">
          <respStmt>
            <persName>Benjamin W. Bohl</persName>
          </respStmt>
          <changeDesc>
            <p>
            using 'Core_removeMrestDur.xquery' by Benjamin W. Bohl
              * removed dur on mRest elements in mov8
              * inserted corresponding changeDesc
            </p>
          </changeDesc>
          <date isodate="{current-date()}"/>
        </change>

where $file//mei:mdiv[@xml:id="core_mov8"]//mei:mRest/@dur
return (
  insert node $change as last into $file//mei:revisionDesc,
 
  for $attDur in $file//mei:mdiv[@xml:id="core_mov8"]//mei:mRest/@dur
  return
    delete node $attDur
)