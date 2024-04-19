# Prepare databanks for SoFuR

This page details the process to download and format resources required.

## Table of Contents
0. [Pre-set databanks folder](#pre-set-databanks-folder)
1. [Software resources](#software-resource)
2. [Annotations](#annotations)
3. [Sequences](#sequences)
4. [Healthy fusions](#healthy-fusions)
5. [Known fusions](#known-fusions)


## 0. Pre-set databanks folder

    export CURR_DATE=`date '+%Y-%m-%d'`
    export BANK=/labos/Anapath/bank/Homo_sapiens/fusions/GRCh38  # !! Change !!
    export ENSEMBL_RELEASE=104
    export COSMIC_RELEASE=94
    export APP_DIR=/soft/sofur  # !! Change !!
    # Virtual environments
    export CONDA_INSTALL=/labos/Anapath/soft/conda/miniconda3  # !! Change !!
    export ANACORE_UTILS_ENV=a1fc435972f2fb68385bbd162ca4ca38  # !! Change: name of AnaCore-utils environment created by snakemake !!
    export STAR_ENV=6c4bdf640c78f6de187c79cc8dffc17f  # !! Change: name of STAR environment created by snakemake !!


## 1. Software resources

### 1.1. STAR-Fusion

* Form https://data.broadinstitute.org/Trinity/CTAT_RESOURCE_LIB/ download
GRCh38_gencode_v37_CTAT_lib_Mar012021.source.tar.gz

* Extract and move data:

      tar -xvf GRCh38_gencode_v37_CTAT_lib_Mar012021.source.tar.gz
      mkdir -p ${BANK}/starfusion
      mv GRCh38_gencode_v37_CTAT_lib_Mar012021 ${BANK}/starfusion
      rm GRCh38_gencode_v37_CTAT_lib_Mar012021.source.tar.gz

### 1.2. Arriba

Extract `database/blacklist_hg38_GRCh38_2018-11-04.tsv.gz` from arriba source [archive](https://github.com/suhrig/arriba/releases/tag/v1.2.0) and save as `${BANK}/arriba/blacklist_hg38_GRCh38_2018-11-04.tsv.gz`.

### 1.3. RESeQC

    mkdir -p ${BANK}/reseqc
    cd ${BANK}/reseqc
    curl 'https://sourceforge.net/projects/rseqc/files/BED/Human_Homo_sapiens/hg38_Gencode_V28.bed.gz/download'
    gzip -d hg38_Gencode_V28.bed.gz
    mv hg38_Gencode_V28.bed genes_RefSeq_ReSeQC_hg38_Gencode_V28.bed

## 2. Annotations

### 2.1. Gene name aliases

* From [Ensembl BioMart](https://www.ensembl.org/biomart/martview) select `Ensembl Genes`
then `Human genes`.

* From left panel click on `Attributes` and check only:
 * Gene stable ID version,
 * Gene name,
 * Gene synonym

* Click on `Results` and download the TSV file.

* Save result as `${BANK}/${CURR_DATE}/aliases_ensembl.tsv`.

### 2.2. Genes annotations

    cd ${BANK}/${CURR_DATE}
    wget http://ftp.ensembl.org/pub/release-${ENSEMBL_RELEASE}/gtf/homo_sapiens/Homo_sapiens.GRCh38.${ENSEMBL_RELEASE}.chr.gtf.gz -o annotations_ensembl.gtf.gz
    gzip -d annotations_ensembl.gtf.gz

### 2.3. Proteins domains

* From [Ensembl BioMart](https://www.ensembl.org/biomart/martview) select `Ensembl Genes`
then `Human genes`.

* From left panel click on `Attributes` and check only:
 * Transcript stable ID version,
 * Protein stable ID version,
 * Interpro ID,
 * Interpro Short Description,
 * Interpro Description,
 * Interpro start,
 * Interpro end

* Click on `Results` and download the TSV file.

* Save result as `${BANK}/${CURR_DATE}/interpro_ensembl.tsv`.

* Transform TSV to GFF3:

      source ${CONDA_INSTALL}/bin/activate ${ANACORE_UTILS_ENV}  # Activate AnaCore-utils environment

      cd ${BANK}/${CURR_DATE}
      ensemblInterProToGFF.py \
        --input-annotations annotations_ensembl.gtf \
        --input-domains interpro_ensembl.tsv \
        --output-annotations interpro_ensembl.gff3 \
        2> interpro_ensembl.log

      conda deactivate


## 3. Sequences

* Download human genome assembly from Ensembl and remove additional haplotypes
and unmaped contigs:

      source ${CONDA_INSTALL}/bin/activate ${ANACORE_UTILS_ENV}  # Activate AnaCore-utils environment

      mkdir -p ${BANK}/${CURR_DATE}/sequences
      cd ${BANK}/${CURR_DATE}/sequences
      wget ftp://ftp.ensembl.org/pub/release-${ENSEMBL_RELEASE}/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
      mv Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz Homo_sapiens_GRCh38_ensembl-v${ENSEMBL_RELEASE}.fa.gz
      echo """import sys
      from anacore.sequenceIO import FastaIO

      keep = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', 'X', 'Y', 'MT'}

      with FastaIO(sys.argv[2], 'w') as writer:
          with FastaIO(sys.argv[1]) as reader:
              for record in reader:
                  if record.id in keep:
                      writer.write(record)""" > filter.py
      python filter.py Homo_sapiens_GRCh38_ensembl-v${ENSEMBL_RELEASE}.fa.gz Homo_sapiens_GRCh38_ensembl-v${ENSEMBL_RELEASE}_chrOnly.fa.gz
      rm filter.py Homo_sapiens_GRCh38_ensembl-v${ENSEMBL_RELEASE}.fa.gz

      conda deactivate

* Index genome with the STAR release used in SoFuR:

      source ${CONDA_INSTALL}/bin/activate ${STAR_ENV}  # Activate STAR environment

      STAR \
        --runThreadN 8 \
        --runMode genomeGenerate \
        --genomeDir . \
        --genomeFastaFiles Homo_sapiens_GRCh38_ensembl-v${ENSEMBL_VERSION}_chrOnly.fa.gz \
        --sjdbGTFfile ../annotations_ensembl.gtf \
        --sjdbOverhang 74 \
        --limitGenomeGenerateRAM 36000000000

      conda deactivate


## 4. Healthy fusions

    source ${CONDA_INSTALL}/bin/activate ${ANACORE_UTILS_ENV}  # Activate AnaCore-utils environment

    cd ${BANK}/${CURR_DATE}
    buildKnownBNDDb.py \
      --input-aliases genes-alias_ensembl.txt \
      --input-annotations annotations_ensembl.gtf \
      --inputs-databases \
        babiceanu:2016:${APP_DIR}/config/healthy/Babiceanu-2016.tsv \
        bodymap:v2:${APP_DIR}/config/healthy/BodyMap2.tsv \
      --output-database healthy_bnd_${CURR_DATE}.tsv

    conda deactivate


## 5. Known fusions

### 5.1. ChimerDb

* Download ChimerKB and ChimerPub in sql format from https://www.kobic.re.kr/chimerdb/download:

      cd ${BANK}/${CURR_DATE}
      wget https://www.kobic.re.kr/chimerdb/downloads?name=ChimerKBV41.sql
      wget https://www.kobic.re.kr/chimerdb/downloads?name=ChimerPubV41.sql

* Convert database to parsable file:

      cd ${BANK}/${CURR_DATE}
      python3 ${APP_DIR}/scripts/chimerFromDump.py -i ChimerKBV41.sql > chimerKb_4.tsv
      python3 ${APP_DIR}/scripts/chimerFromDump.py -i ChimerPubV41.sql > chimerPub_4.tsv

### 5.2. Cosmic

Your first request needs to supply your registered email address and COSMIC password. We use HTTP Basic Auth to check your credentials, which requires you to combine your email address and password and then Base64 encode them. For example, using standard Unix command line tools:

    export AUTH_STRING=`echo "email@example.com:mycosmicpassword" | base64`  # !! Change email and password !!
    curl -H "Authorization: Basic ${AUTH_STRING}" https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/v${COSMIC_RELEASE}/CosmicFusionExport.tsv.gz

That request will return a snippet of JSON containing the link that you need to use to download your file. For example:

    {
        "url" : "https://cog.sanger.ac.uk/cosmic/GRCh38/cosmic/v94/CosmicFusionExport.tsv.gz?AWSAccessKeyId=KFGH85D9KLWKC34GSl88&Expires=1521726406&Signature=Jf834Ck0%8GSkwd87S7xkvqkdfUV8%3D"
    }

Extract the URL from the JSON response and make another request to that URL to download the file. For example:

    curl "https://cog.sanger.ac.uk/cosmic/GRCh38/cosmic/v94/CosmicFusionExport.tsv.gz?AWSAccessKeyId=KFGH85D9KLWKC34GSl88&Expires=1521726406&Signature=Jf834Ck0%8GSkwd87S7xkvqkdfUV8%3D"

### 5.3. Mitelman

    cd ${BANK}
    mkdir mitelman_db
    cd mitelman_db
    wget https://storage.googleapis.com/mitelman-data-files/prod/mitelman_db.zip
    unzip mitelman_db.zip

### 5.4. Create aggregated database

    source ${CONDA_INSTALL}/bin/activate ${ANACORE_UTILS_ENV}  # Activate AnaCore-utils environment

    cd ${BANK}/${CURR_DATE}
    buildKnownBNDDb.py \
      --input-aliases genes-alias_ensembl.txt \
      --input-annotations annotations_ensembl.gtf \
      --inputs-databases \
        cosmic:${COSMIC_RELEASE}:CosmicFusionExport.tsv.gz \
        chimerdb:Kb-v4:chimerKb_4.tsv \
        chimerdb:Pub-v4:chimerPub_4.tsv \
        mitelman:${CURR_DATE}:mitelman_db/MBCA.TXT.DATA,mitelman_db/REF.TXT.DATA \
      --output-database known_bnd_${CURR_DATE}.tsv \
    2> known_ensembl.log \
    > known_ensembl_pb.tsv

    conda deactivate
