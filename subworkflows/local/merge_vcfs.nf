
include { ISEC_VCFS } from '../../modules/local/Merge/isec_vcfs'
include { PCGR_VCF  } from '../../modules/local/Merge/pcgr_vcf'

workflow MERGE_VCFS {
    take:
    files
    fasta

    main:
    // create master TSV file with variant <-> tool mapping
    sample_vcfs = files.map{ it -> return it[1..2] }.flatten().map{ it -> meta = it.simpleName; return [ meta, it ] }.groupTuple()
    ISEC_VCFS( sample_vcfs )

    // merge back with sample VCFs, produce PCGR ready VCFs.
    sample_vcfs_keys = ISEC_VCFS.out.variant_tool_map.join(sample_vcfs)

    PCGR_VCF( sample_vcfs_keys, "${projectDir}/bin/pcgr_vcf.py")

    emit:
    pcgr_ready_vcf = params.cna_analysis ? PCGR_VCF.out.vcf : PCGR_VCF.out.vcf.map{ meta, vcf, tbi -> return [ meta, vcf, tbi, [] ] }
    //sample_vcfs
}