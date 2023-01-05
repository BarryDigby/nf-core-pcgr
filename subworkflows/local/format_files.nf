include { BCFTOOLS_NORM as NORMALISE_VARIANTS } from '../../modules/nf-core/bcftools/norm/main'
include { BCFTOOLS_FILTER as FILTER_VARIANTS  } from '../../modules/nf-core/bcftools/filter/main'
include { TABIX_TABIX as TABIX_NORMALISED     } from '../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as TABIX_FILTERED       } from '../../modules/nf-core/tabix/tabix/main'
include { REFORMAT_VCF } from '../../modules/local/PCGR/Format/pcgr_reformat'
include { REFORMAT_CNA } from '../../modules/local/PCGR/Format/pcgr_reformat'

workflow FORMAT_FILES {
    take:
    fasta
    vcf_files
    cna_files

    main:
    // CPSR can take raw input germline files, but we will normalise them.
    // PCGR requires somatic VCF files to be simplified to TAF, TDP, NAF, NDP fields
    // which requires removing empty DP fields (filter) and manual calculations.

    NORMALISE_VARIANTS( vcf_files, fasta )
    //TABIX_NORMALISED( NORMALISE_VARIANTS.out.vcf )
    //normalised_germline = NORMALISE_VARIANTS.out.vcf.join( TABIX_NORMALISED.out.tbi ).filter{ it -> meta = it[0]; meta.status == 'germline' }
    //normalised_somatic  = NORMALISE_VARIANTS.out.vcf.join( TABIX_NORMALISED.out.tbi ).filter{ it -> meta = it[0]; meta.status == 'somatic' }

    FILTER_VARIANTS( NORMALISE_VARIANTS.out.vcf )
    TABIX_FILTERED( FILTER_VARIANTS.out.vcf )

    normalised_germline = FILTER_VARIANTS.out.vcf.join( TABIX_FILTERED.out.tbi ).filter{ it -> meta = it[0]; meta.status == 'germline' }
    normalised_somatic  = FILTER_VARIANTS.out.vcf.join( TABIX_FILTERED.out.tbi ).filter{ it -> meta = it[0]; meta.status == 'somatic' }

    REFORMAT_VCF( normalised_somatic )
    REFORMAT_CNA( cna_files )

    copy_number = REFORMAT_CNA.out.cna.map{ meta, tsv -> var = [:]; var.id = meta.id; var.patient = meta.patient; var.status = meta.status; var.sample = meta.sample; var.tool = meta.tool; return [ var, tsv ] }

    somatic_files = params.cna_analysis ? REFORMAT_VCF.out.vcf.join( copy_number ) : REFORMAT_VCF.out.vcf.map{ meta, vcf, tbi -> return [ meta, vcf, tbi, [] ] }.view()

    emit:
    somatic_files
    normalised_germline
}
