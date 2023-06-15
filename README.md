# SplicingPipeline
## Short description
This is a pipeline that allows predicting the putative isoforms in a reference genome using the long reads’ data.
## Dependencies
1. BEDtools
2. cutadapt
3. minimap2
4. SAMtools
5. TrackCluster

For peak-calling the pipeline uses a slightly modified version of PromoterPipeline (http://genome.gsc.riken.jp/plessy-20150516/PromoterPipeline_20150516.tar.gz). Its installation is not required, because all components are already included in this package.
## Installation
1. Install all the dependencies. It is recommended to use “pip --user” instead of conda for installation in order to not cause any conflicts between Python versions.
2. Download the pipeline:
```
git clone https://github.com/ArtemKasianov/SplicingPipeline
cd SplicingPipeline
```
3. Replace the initial bam2bigg.py script of TrackCluster with our edited version:
```
mv bam2bigg.py TRACKCLUSTER_INSTALLATION_DIR/trackcluster/script/bam2bigg.py.
```
It should be located in the directory that looks like: `TRACKCLUSTER_INSTALLATION_DIR/ trackcluster/script`. This is a critically important step, because the initial version has a bug that doesn’t allow our pipeline to work properly.

4. Edit the file “CONFIGURATION.txt”. Here you need to insert the paths to the required dependencies in your system. You can check on the example located in the “Example” folder. If the program is already in your PATH, you may not edit the corresponding line. Although it is recommended to insert the full paths for cutadapt and bam2bigg.py.
   
6. Make sure that the main script “run_pipeline.pl” is executable!
## Required input data and formats
1. Reads in “.fastq” format (including the compressed “.fastq.gz”). More entrusting results can be achieved by using multiple replicates of a sample.
2. The reference genome in “.fasta/.fa” format.
3. A list of reference splice sites. It should be made by the user. Make sure that the names of the chromosomes are the same in the reference “.fasta” and your file! You can see the examples of such file made for Arabidopsis thaliana in “Athaliana/SPLICING_LIST.txt”.
4. A reference “.bed” file with the coordinates of the genes. It should be made by the user. Make sure that the names of the chromosomes are the same in the reference “.fasta” and your file! You can see the examples of such file made for Arabidopsis thaliana in “Athaliana/SPLICING_LIST.txt”.
## Output format
The output is stored in the output directory (if specified). They are written into the files with extensions: “.MAPPING.NANO.bed”, “.SPLICE-SITES.txt”, and “.ISOFORMS.txt”. If several replicates are specified, these files will be made for each of them separately.
1. “.MAPPING.NANO.bed” – mappings in “.bigg” format.
2. “.SPLICE-SITES.txt” – a TAB-delimited file indicating the list of putative introns for each mapped read. 
3. “.ISOFORMS.txt” – a TAB-delimited file containing the final isoforms. It is considered as the final results of the pipeline. The format of the columns is, as follows:
    -  chromosome
    - 5’-end coordinate (maximal point of the peak)
    - 3’-end coordinate (maximal point of the peak)
    - strand
    - list of introns (delimited with “;”, if several introns are detected)
    - coordinates for the 5’-end peak
    - coordinates for the 3’-end peak
    - name of the gene
## Usage
1. The pipeline options’ management is implemented through the configuration file called “OPTIONS.txt”.

Simply insert the needed values below the corresponding header marked with “!”. Please, don’t leave empty lines between the headers marked with “!” and your value, because the pipeline will treat it as an empty value! See the “Options” section below for more information.

2. After specifying the options, run the main script as follows
```
./run_pipeline.pl OPTIONS.txt
```
## Options
There are three types of options in “OPTIONS.txt”: primary, secondary and additional.
1. Primary – are the basic options required for the pipeline to operate properly. They include the reads in “.fastq” format (including the compressed “.fastq.gz”), the reference genome in “.fasta/.fa” format, a list of reference splice sites and a reference “.bed” file with the coordinates of the genes.
If you need to specify multiple “.fastq” files, separate them with a comma “,” sign.
If any of these files are not specified or are specified incorrectly, the pipeline will finish with the corresponding warning.
2. Secondary options simply include the name for the output directory and the prefix name for the resulting files. They are secondary and not strictly required, because the pipeline can perfectly work without them. It will simply write everything into the current working directory with basic names.
3. Additional options – are the settings for each of the dependencies. They are simply all of the options for cutadapt, minimap2, and SAMtools. They are already set to the default settings, but we leave the opportunity for the user to configure them in any way needed. Simply specify the options in the same manner, as if you ran these tools independently by yourself.
