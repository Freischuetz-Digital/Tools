xquery version "1.0";

(:
remove zone[@type='staff'] from specified file
author: Benjamin W. Bohl
date: 2014-04-04
:)

declare namespace mei = 'http://www.music-encoding.org/ns/mei';

declare namespace functx = "http://www.functx.com";
declare function functx:non-distinct-values
  ( $seq as xs:anyAtomicType* )  as xs:anyAtomicType* {

   for $val in distinct-values($seq)
   return $val[count($seq[. = $val]) > 1]
 } ;

declare variable $mode := 'report'; (:report|delete:)

for $file in doc('../../sources/D1849.xml')
let $change :=<change n="{count($file//mei:revisionDesc/mei:change)+1}" xmlns="http://www.music-encoding.org/ns/mei">
          <respStmt>
            <persName>Benjamin W. Bohl</persName>
          </respStmt>
          <changeDesc>
            <p>
              using 'udateDeleteZoneTypeStaff.xquery' by Benjamin W. Bohl
                * removed zone[@type='staff'] from specified file
            </p>
          </changeDesc>
          <date isodate="{current-date()}"/>
        </change>

where $file//mei:zone[@type='staff']
return (
  if($mode = 'delete')
  then(
    (:insert node $change as last into $file//mei:revisionDesc,
 
    for $zone in $file//mei:zone[@type='staff']
    let $preceedingIDs := $zone/preceding::mei:zone[@type='staff']/@xml:id
    return
      if($zone/@xml:id = $preceedingIDs)
      then(delete node $zone)
      else():)
  )
  else(
    fn:count($file//mei:zone[@type='staff']/@xml:id),
    fn:count(fn:distinct-values($file//mei:zone[@type='staff']/@xml:id)),
    fn:count(functx:non-distinct-values($file//mei:zone[@type='staff']/@xml:id)) (:if equal to distinct values all have at least one duplicate:)
  )
)