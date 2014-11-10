xquery version "1.0";

(:
transform @type="generated" to @n="freidi:generated"
author: Benjamin W. Bohl
date: 2014-05-07
:)

declare namespace mei = 'http://www.music-encoding.org/ns/mei';

import module namespace params = "http://www.freischuetz-digital.de/xq/params" at "params.xqm";

for $file in doc('file:///C:/Users/bwb/Desktop/temp/SVN_FreiDi/data/core.xml'),
    $doc in doc(document-uri($file))
let $change :=<change n="{count($doc//mei:revisionDesc/mei:change)+1}" xmlns="http://www.music-encoding.org/ns/mei">
          <respStmt>
            <persName>Benjamin W. Bohl</persName>
          </respStmt>
          <changeDesc>
            <p>
            using 'typeGen2n.xquery' by Benjamin W. Bohl in mov8
              * renamed @type to @n
              * prependen 'freidi:' to value of @n
            </p>
          </changeDesc>
          <date isodate="{current-date()}"/>
        </change>

where $doc//mei:mdiv[@xml:id="core_mov8"]//@type[contains(.,'generated')]
return (
  insert node $change as last into $doc//mei:revisionDesc,
 
  for $attTypeGen in $doc//mei:mdiv[@xml:id="core_mov8"]//@type
  where contains($attTypeGen,'generated')
  return(
    replace value of node $attTypeGen with fn:concat('freidi:',$attTypeGen),
    rename node $attTypeGen
    as 'n'
  )
)