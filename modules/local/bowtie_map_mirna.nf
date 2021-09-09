// Import generic module functions
include { saveFiles; initOptions; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process MAP_MIRNA {
    label 'process_medium'
    tag "$meta.id"

    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:[:], publish_by_meta:[]) }

    conda (params.enable_conda ? 'bioconda::bowtie=1.3.0-2' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bowtie:1.3.0--py38hcf49a77_2"
    } else {
        container "quay.io/biocontainers/bowtie:1.3.0--py38hcf49a77_2"
    }

    input:
    tuple val(meta), path(reads)
    path index
    val name_unmapped

    output:
    tuple val(meta), path("*sam"), emit: sam
    tuple val(meta), path('unmapped/*fq.gz') , emit: unmapped

    script:
    def software = getSoftwareName(task.process)
    def process_name = task.process.tokenize(':')[-1]
    def index_base = index.toString().tokenize(' ')[0].tokenize('.')[0]

    """

    bowtie \\
        $index_base \\
        -q <(zcat $reads) \\
        -p ${task.cpus} \\
        -t \\
        -k 50 \\
        --best \\
        --strata \\
        -e 99999 \\
        --chunkmbs 2048 \\
        --un ${meta.id}_${name_unmapped}_unmapped.fq -S > ${meta.id}_${name_unmapped}.sam

    gzip ${meta.id}_${name_unmapped}_unmapped.fq
    mkdir unmapped
    mv  ${meta.id}_${name_unmapped}_unmapped.fq.gz  unmapped/.
    """

}
