MEI cleaning
============

This script resolves some issues not covered with the standard script from music-encoding.org

This includes following tasks:

* resolve bTrems, fTrems
* resolve intermediary scoreDefs and staffDefs
* strip mei:pb and mei:sb
* convert chords with stemmod to bTrem
* convert mei:artic and mei:accid to respective attributes
* generate mei:bTrem elements where applicable
