xquery version "1.0";

(:
propageate provided scoreDef of a page to all following pages
author: Benjamin W. Bohl, Anna Maria Komprecht
date: 2014-04-04
:)

declare namespace mei = 'http://www.music-encoding.org/ns/mei';

import module namespace params = "http://www.freischuetz-digital.de/xq/params" at "params.xqm";

(: ENTER VARIABLES HERE :)
declare variable $sourcePageFileName := 'K15_page268.xml';
declare variable $lastPageFileName := 'K15_page279.xml';

(: THE REST IS BEING CALCULATED :)
declare variable $sourcePageFile := doc(concat($params:localCollection, $params:source,'_merged/',$params:source,'_',$params:mov,'/',$sourcePageFileName));
declare variable $lastPageFile := doc(concat($params:localCollection, $params:source,'_merged/',$params:source,'_',$params:mov,'/',$lastPageFileName));
declare variable $newProvidedScoreDef := $sourcePageFile//mei:annot[@type='providedScoreDef']//mei:scoreDef;

for $file in collection(concat($params:localCollection, $params:source,'_merged/',$params:source,'_',$params:mov,'/?select=*.xml'))
let $doc := doc(document-uri($file))
let $change :=<change n="{count($doc//mei:revisionDesc/mei:change)+1}" xmlns="http://www.music-encoding.org/ns/mei">
          <respStmt>
            <persName>Anna Maria Komprecht</persName>
          </respStmt>
          <changeDesc>
            <p>
            propagated provided scoreDef from {$sourcePageFileName} using 'propagateScoreDef.xquery' by Benjamin W. Bohl
            </p>
          </changeDesc>
          <date isodate="{current-date()}"/>
        </change>
where (number(substring-after($doc//mei:mei/@xml:id,'page')) gt number(substring-after($sourcePageFile//mei:mei/@xml:id,'page'))) and (number(substring-after($doc//mei:mei/@xml:id,'page')) lt number(substring-after($lastPageFile//mei:mei/@xml:id,'page'))+1)
return (
 insert node $change as last into $doc//mei:revisionDesc,
 
 for $providedScoreDefAnnot in $doc//mei:annot[@type='providedScoreDef']
 return (
  delete node $providedScoreDefAnnot//mei:scoreDef,
  insert node $newProvidedScoreDef as first into $providedScoreDefAnnot//mei:section
  )
)