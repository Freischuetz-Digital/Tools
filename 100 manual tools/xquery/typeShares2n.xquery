xquery version "1.0";

(:
transform @type="generated" to @n="freidi:generated"
author: Benjamin W. Bohl
date: 2014-05-07
:)

declare namespace mei = 'http://www.music-encoding.org/ns/mei';

import module namespace params = "http://www.freischuetz-digital.de/xq/params" at "params.xqm";

for $file in collection(concat('../',$params:source,'_merged/',$params:source,'_',$params:mov,'/?select=*.xml')),
    $doc in doc(document-uri($file))
let $change :=<change n="{count($doc//mei:revisionDesc/mei:change)+1}" xmlns="http://www.music-encoding.org/ns/mei">
          <respStmt>
            <persName>Benjamin W. Bohl</persName>
          </respStmt>
          <changeDesc>
            <p>
            using 'typeShares2n.xquery' by Benjamin W. Bohl
              * renamed @type to @n
              * prependen 'freidi:' to value of @n
            </p>
          </changeDesc>
          <date isodate="{current-date()}"/>
        </change>

where $doc//mei:*/@type[contains(.,'sharesLayer')]
return (
  insert node $change as last into $doc//mei:revisionDesc,
 
  for $attTypeGen in $doc//@type
  where contains($attTypeGen,'sharesLayer')
  return(
    replace value of node $attTypeGen with fn:concat('freidi:',$attTypeGen),
    rename node $attTypeGen
    as 'n'
  )
)