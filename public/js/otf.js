
var otf = {
  version: "otf.js version 2014-11-28"
}

otf.template_query = function (){
var query = "prefix ensembl: <http://rdf.ebi.ac.uk/resource/ensembl/>
prefix faldo: <http://biohackathon.org/resource/faldo#>
prefix taxon: <http://identifiers.org/taxonomy/>
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix ensemblvariation: <http://rdf.ebi.ac.uk/terms/ensemblvariation/>
prefix dc: <http://purl.org/dc/terms/>
prefix exon: <http://rdf.ebi.ac.uk/resource/ensembl.exon/>
prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix transcript: <http://rdf.ebi.ac.uk/resource/ensembl.transcript/>
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
prefix identifiers: <http://identifiers.org/>
prefix obo: <http://purl.obolibrary.org/obo/>
prefix sio: <http://semanticscience.org/resource/>
prefix term: <http://rdf.ebi.ac.uk/terms/ensembl/>
prefix protein: <http://rdf.ebi.ac.uk/resource/ensembl.protein/>
prefix vcf: <http://rdf.ebi.ac.uk/terms/ensemblvariation/vcf/>

select ?s ?quality where {
?s faldo:location ?location .
?location faldo:reference [ dc:identifier "Y" ] .
?location faldo:begin [ faldo:position ?begin ] .
?location faldo:end [ faldo:position ?end ] .
?s vcf:quality ?quality .
FILTER(?begin >= 2749180) .
FILTER(?end <= 2755180) .
}"

return query
}

otf.set_template = function (){

}