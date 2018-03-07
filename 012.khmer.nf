//params.reads = "$baseDir/001.Data.sample/Rus*_R{1,2}.fastq.gz"

params.reads = "$baseDir/003.Data.trimmomatic/Rus*trimmed*_R{1,2}.fastq.gz"

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs }


process interleave{
    echo true

    executor 'lsf'

    module 'khmer'

    input:
    set pair_id, file(reads) from read_pairs

    output:
    file("*il.fastq.gz")  into ilreads

    """
    interleave-reads.py --gzip -o ${pair_id}.il.fastq.gz ${reads} 
    """
}


ilreadsm = ilreads.collectFile(name:"ilreads.fastq.gz")

process load_into_contig{
   module "khmer"
   cpus 8 

   executor 'lsf'

   publishDir "$baseDir/012.khmer", mode: "copy" 

   input:
   file "ilreads.fastq.gz" from ilreadsm

   output:
   file "reads.ct" into counts
   file "ilreads.fastq.gz" into ilreadsmload


   """
   load-into-counting.py -x 1e8 -k 20 -s json --threads 8 -f reads.ct ilreads.fastq.gz 
   """
}

process abundance_dist{
    module "khmer"
    executor "lsf"

    publishDir "$baseDir/012.khmer", mode: "copy"

    input:
    file "reads.ct" from counts
    file "ilreads.fastq.gz" from ilreadsmload

    output:
    file "reads.dist" into hist

    """
    abundance-dist.py reads.ct ilreads.fastq.gz reads.dist
    """
}



