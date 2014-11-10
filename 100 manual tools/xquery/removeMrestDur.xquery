xquery version "1.0";

(:
remove @dur on mRest
author: Benjamin W. Bohl
date: 2014-04-04
:)

declare namespace mei = 'http://www.music-encoding.org/ns/mei';

import module namespace params = "http://www.freischuetz-digital.de/xq/params" at "params.xqm";

for $file in collection(concat($params:localCollection,$params:source,'_merged/',$params:source,'_',$params:mov,'/?select=*.xml'))
let $doc := doc(document-uri($file))
let $change :=<change n="{count($doc//mei:revisionDesc/mei:change)+1}" xmlns="http://www.music-encoding.org/ns/mei">
          <respStmt>
            <persName>Anna Maria Komprecht</persName>
          </respStmt>
          <changeDesc>
            <p>
            using 'removeMrestDur.xquery' by Benjamin W. Bohl
              * removed dur on mRest elements
              * inserted corresponding changeDesc
            </p>
          </changeDesc>
          <date isodate="{current-date()}"/>
        </change>

where $doc//mei:mRest/@dur
return (
  insert node $change as last into $doc//mei:revisionDesc,
 
  for $attDur in $doc//mei:mRest/@dur
  return
    delete node $attDur
)