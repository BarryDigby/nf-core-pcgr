#!/usr/bin/env nextflow

files = collect_sarek_files(file(params.input))
files.collectFile( name: 'constructed_samplesheet.csv', newLine:false, storeDir: "${params.outdir}", keepHeader: true ){ ids, vcf, cna -> "sample,vcf,cna" + "\n" + "$ids,$vcf,$cna" + "\n"}.set{ constructed_samplesheet }
constructed_samplesheet.view()

def collect_sarek_files(input){
    vcf_files = []
    cna_files = []
    input.eachFileRecurse{ it ->
        vcf = it.name.contains('_vs_') && ( it.name.endsWith('.vcf') || it.name.endsWith('.vcf.gz') ) && !it.name.endsWith('.tbi') ? file(it) : []
        if(params.cna_analysis){ cna = it.name.contains('.cns') ? file(it) : [] }else{ cna = 'NA' }
        ids = ( it.name.contains('.cns') || it.name.contains('_vs_') && ( it.name.endsWith('.vcf') || it.name.endsWith('.vcf.gz') ) && !it.name.endsWith('.tbi') ) ? it.simpleName.tokenize('_')[0] : 'NA'
        vcf_files << [ ids, vcf ]
        cna_files << [ ids, cna ]
        }
    collect_vcf = Channel.fromList( vcf_files ).filter{ ids, vcf -> vcf.toString().contains('.vcf') }
    collect_cna = params.cna_analysis ? Channel.fromList( cna_files ).filter{ ids, cna -> cna.toString().contains('.cns') } : Channel.fromList( cna_files ).set{ collect_cna }
    sarek_files = collect_vcf.combine(collect_cna, by:0).unique()
    return sarek_files
}
