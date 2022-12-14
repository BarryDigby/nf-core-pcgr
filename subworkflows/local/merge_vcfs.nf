
include { ISEC_VCFS } from '../../modules/local/Merge/isec_vcfs'
include { PCGR_VCF  } from '../../modules/local/Merge/pcgr_vcf'

workflow MERGE_VCFS {
    take:
    files
    fasta

    main:
    // create master TSV file with variant <-> tool mapping
    // Extract VCF and TBI from channel, keeping the meta information.
    sample_vcfs = files.map{ it -> return it[1..2] }.flatten().map{ it -> meta = [:]; meta.id = it.simpleName; return [ meta, it ] }.groupTuple()
    ISEC_VCFS( sample_vcfs )

    // merge back with sample VCFs, produce PCGR ready VCFs.
    sample_vcfs_keys = ISEC_VCFS.out.variant_tool_map.join(sample_vcfs)

    PCGR_VCF( sample_vcfs_keys, "${projectDir}/bin/pcgr_header.txt")

    // Add the CNVkit file back to the PCGR ready VCFs
    emit:
    pcgr_ready_vcf = params.cna_analysis ? PCGR_VCF.out.vcf.join( files.map{ it -> return it[3] }.flatten().take(1).map{ it -> meta = [:]; meta.id = it.simpleName; return [ meta, it ] } ) : PCGR_VCF.out.vcf.map{ meta, vcf, tbi -> return [ meta, vcf, tbi, [] ] }

}
