require 'java'
require 'lib/jar/htsjdk-1.119.jar' #http://sourceforge.net/projects/picard/files/latest/download?source=files
require 'lib/jar/bzip2.jar' #wget http://www.kohsuke.org/bzip2/bzip2.jar
require 'digest'
require 'yaml'

java_import "htsjdk.variant.vcf.VCFFileReader"
java_import "htsjdk.variant.variantcontext.VariantContext"

module OTF
  class VCF

    def initialize(vcf,config)
        @vcf = vcf
        @config = config
    end

    def to_rdf
      refBaseURI = "http://rdf.ebi.ac.uk/resource/ensembl/#{@config['ensemblVersion']}/chromosome:#{@config['assemblyVersion']}:#{@vcf.getChr}"
      varBaseURI = "http://rdf.ebi.ac.uk/terms/ensemblvariation"
      vcf_rdf = []
      varURI = nil
      varID = nil
      case @vcf.getID
        when "." 
          varID = Digest::MD5.hexdigest("#{@config["species"]}:#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}")
          varURI = "#{varBaseURI}/#{varID}"
        else 
          varID = @vcf.getID
          varURI = "#{varBaseURI}/#{varID}"
          vcf_rdf << [varURI,"dc:identifier",@vcf.getID]
          vcf_rdf << [varURI,"rdfs:label",@vcf.getID]
      end
      vcf_rdf << [RDF::URI.new(refBaseURI),"dc:identifier","#{@vcf.getChr}"]
      faldoRegion = RDF::URI.new(refBaseURI+":#{@vcf.getStart}-#{@vcf.getEnd}:1")
      vcf_rdf << [RDF::URI.new(varURI),"faldo:location",faldoRegion]
      vcf_rdf << [faldoRegion,"rdfs:label","#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}:1"]
      vcf_rdf << [faldoRegion,"rdf:type","faldo:Region"]
      vcf_rdf << [faldoRegion,"faldo:begin",RDF::URI.new(refBaseURI+":#{@vcf.getStart}:1")]
      vcf_rdf << [faldoRegion,"faldo:end",RDF::URI.new(refBaseURI+":#{@vcf.getEnd}:1")]
      vcf_rdf << [faldoRegion,"faldo:reference",refBaseURI]
      if @vcf.getStart == @vcf.getEnd
        faldoExactPosition = RDF::URI.new(refBaseURI+":#{@vcf.getStart}:1")
        vcf_rdf << [faldoExactPosition,"rdf:type","faldo:ExactPosition"]
        vcf_rdf << [faldoExactPosition,"rdf:type","faldo:ForwardStrandPosition"]
        vcf_rdf << [faldoExactPosition,"faldo:position",@vcf.getStart]
        vcf_rdf << [faldoExactPosition,"faldo:reference",refBaseURI]
      end
      refAllele = @vcf.getReference.getBaseString
      refAlleleURI = RDF::URI.new(varURI+"\##{refAllele}")
      vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(varURI+":has_allele"),refAlleleURI]
      vcf_rdf << [refAlleleURI,"rdfs:label","#{varID} allele #{refAllele}"] 
      vcf_rdf << [refAlleleURI,"a",RDF::URI.new(varURI+":reference_allele")] 
      altAllele = @vcf.getAlternateAlleles.first.getBaseString
      altAlleleURI = RDF::URI.new(varURI+"\##{altAllele}")
      vcf_rdf << [varURI,RDF::URI.new(varURI+":has_allele"),altAlleleURI]
      vcf_rdf << [altAlleleURI,"rdfs:label","#{varID} allele #{altAllele}"] 
      vcf_rdf << [altAlleleURI,"a",RDF::URI.new(varURI+":ancestral_allele")]
    end #to_rdf
  end #VCF

  module Query

    def self.normalize_filters(query)
      query.gsub(/FILTER(.*)\./) do |s| 
        variable, filter, value = s.gsub(/FILTER\(/,'').gsub(/\)/,'').split
        filter = "<filter_by>"
        # case filter
        # when '>'
        #   "value_gt"
        # when '<'
        #   "value_lt"
        # when '='
        #   "value_equal"
        # when '>='
        #   "value_get"
        # when '<='
        #   "value_let"
        # end
        "#{variable} #{filter} #{value} ."
      end
    end

    def self.where_graph(query)
      vary_diz = Hash.new{|h,k| h[k] = SecureRandom.hex }

      pre_parse = RDF::Graph.new

      puts "Original Query"
      puts query

      query_normalized = normalize_filters(query)

      puts "Normalized Query"
      puts query_normalized

# [83] pry(main)> q.operands[1].class
# => SPARQL::Algebra::Operator::Project
# [84] pry(main)> q.operands[1].operands[1].class
# => SPARQL::Algebra::Operator::Filter
# [85] pry(main)> q.operands[1].operands[1].operands[1].class
# => RDF::Query
      SPARQL::Grammar.parse(query_normalized).operands[1].operands[1].patterns.each do |pattern|
        if pattern.subject.variable?
          pattern.subject=RDF::URI(vary_diz[pattern.subject.to_s])
        end
        if pattern.object.variable?
          pattern.object=RDF::URI(vary_diz[pattern.object.to_s])
        end
        # puts pattern.to_s
        pre_parse << pattern
      end
      pre_parse
    end #where_graph

    def self.get_parameters(original_query, parameters_query)
      where_graph(original_query).query(SPARQL::Grammar.parse(parameters_query)).first.to_a
    end

  end #Query

end #OTF