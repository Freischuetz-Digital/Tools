xquery version "1.0";

(:
insert changeDesc
author: Benjamin W. Bohl
date: 2014-03-24
:)

declare namespace mei = 'http://www.music-encoding.org/ns/mei';

declare variable $source := 'KA26';
declare variable $mov := 'mov6';

for $file in collection(concat('../',$source,'_merged/',$source,'_',$mov,'/?select=*.xml'))
let $doc := doc(document-uri($file))
let $change :=<change n="{count($doc//mei:revisionDesc/mei:change)+1}" xmlns="http://www.music-encoding.org/ns/mei">
          <respStmt>
            <persName>Benjamin W. Bohl</persName>
          </respStmt>
          <changeDesc>
            <p>
              * Checked scoreDef;
              * updated provided scoreDef;
              * checked clef elements;
            </p>
            <p>
              * inserterd mei:change with 'insertChangeDesc.xquery' by Benjamin w. Bohl
            </p>
          </changeDesc>
          <date isodate="{current-date()}"/>
        </change>
return
 insert node $change as last into $doc//mei:revisionDesc