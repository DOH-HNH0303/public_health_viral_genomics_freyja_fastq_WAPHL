version 1.0

import "../tasks/task_taxonID.wdl" as taxon_id
import "wf_read_QC_trim.wdl" as read_qc
import "../tasks/task_alignment.wdl" as align
import "../tasks/task_consensus_call.wdl" as consensus_call
import "../tasks/task_versioning.wdl" as versioning
import "../tasks/task_waphl_utils.wdl" as waphl_utils

workflow freyja_fastq {
  input {
    File read1_raw
    File read2_raw
    File primer_bed
    File reference_genome
    File ww_metadata_csv
    Int trimmomatic_minlen = 25
    String samplename
    String? samplecollectdate
    String? wwtpname
    String? submittersamplenumber
  }
  call read_qc.read_QC_trim {
    input:
      samplename = samplename,
      read1_raw  = read1_raw,
      read2_raw  = read2_raw,
      trimmomatic_minlen = trimmomatic_minlen
  }
  call align.bwa {
    input:
      samplename = samplename,
      reference_genome=reference_genome,
      read1 = read_QC_trim.read1_clean,
      read2 = read_QC_trim.read2_clean
  }
  call consensus_call.primer_trim {
    input:
      samplename = samplename,
      primer_bed = primer_bed,
      bamfile = bwa.sorted_bam
  }
  call taxon_id.freyja_one_sample as freyja {
    input:
      primer_trimmed_bam = primer_trim.trim_sorted_bam,
      samplename = samplename,
      reference_genome = reference_genome
  }
  call waphl_utils.freyja_epi_metadata as epi_input {
    input:
      ww_metadata_csv = ww_metadata_csv,
      samplename = samplename
  }
  call waphl_utils.freyja_epi_output as epi_output {
    input:
      submittersamplenumber = select_first([submittersamplenumber, epi_input.SubmitterSampleNumber]),
      wwtpname = select_first([wwtpname, epi_input.WWTPName]),
      samplecollectdate = select_first([samplecollectdate, epi_input.SampleCollectDate]),
      freyja_demixed = freyja.freyja_demixed,
      freyja_depths = freyja.freyja_depths,
      samplename = samplename
  }
  call versioning.version_capture{
    input:
  }
  output {
    # Version Capture
    String freyja_fastq_wf_version = version_capture.phvg_version
    String freyja_fastq_wf_analysis_date = version_capture.date
    # Raw Read QC
    File read1_dehosted = read_QC_trim.read1_dehosted
    File read2_dehosted = read_QC_trim.read2_dehosted
    File read1_clean = read_QC_trim.read1_clean
    File read2_clean = read_QC_trim.read2_clean
    Int num_reads_raw1 = read_QC_trim.fastq_scan_raw1
    Int num_reads_raw2 = read_QC_trim.fastq_scan_raw2
    String num_reads_raw_pairs = read_QC_trim.fastq_scan_raw_pairs
    String fastq_scan_version = read_QC_trim.fastq_scan_version
    # Read Trim
    Int num_reads_clean1 = read_QC_trim.fastq_scan_clean1
    Int num_reads_clean2 = read_QC_trim.fastq_scan_clean2
    String num_reads_clean_pairs = read_QC_trim.fastq_scan_clean_pairs
    String trimmomatic_version = read_QC_trim.trimmomatic_version
    String bbduk_docker = read_QC_trim.bbduk_docker
    # Contaminent Check
    String kraken_version = read_QC_trim.kraken_version
    Float kraken_human = read_QC_trim.kraken_human
    Float kraken_sc2 = read_QC_trim.kraken_sc2
    String kraken_report = read_QC_trim.kraken_report
    Float kraken_human_dehosted = read_QC_trim.kraken_human_dehosted
    Float kraken_sc2_dehosted = read_QC_trim.kraken_sc2_dehosted
    String kraken_report_dehosted = read_QC_trim.kraken_report_dehosted
    # Mapping and Alignment
    String bwa_version = bwa.bwa_version
    String samtools_version = bwa.sam_version
    String alignment_method = "~{bwa.bwa_version}; ~{primer_trim.ivar_version}"
    File aligned_bam = primer_trim.trim_sorted_bam
    File aligned_bai = primer_trim.trim_sorted_bai
    Float primer_trimmed_read_percent = primer_trim.primer_trimmed_read_percent
    String ivar_version_primtrim = primer_trim.ivar_version
    String samtools_version_primtrim = primer_trim.samtools_version
    String primer_bed_name = primer_trim.primer_bed_name

    String? SubmitterSampleNumber = epi_input.SubmitterSampleNumber
    String? WWTPName = epi_input.WWTPName
    String? SampleCollectDate = epi_input.SampleCollectDate
    String epi_metadata_docker = epi_input.epi_metadata_docker
    String epi_metadata_file = ww_metadata_csv
    # Freyja Analysis
    String freyja_version = freyja.freyja_version
    File freyja_variants = freyja.freyja_variants
    File freyja_depths = freyja.freyja_depths
    File? freyja_epi_file = epi_output.freyja_epi_file
    String? freyja_abundances = epi_output.freyja_abundances
    Float? freyja_unreportable = epi_output.freyja_unreportable
    String? freyja_resid = epi_output.freyja_resid
    String? freyja_10x_coverage = epi_output.freyja_coverage
    Float? freyja_avg_coverage = epi_output.freyja_avg_coverage
    Float? freyja_perc_uncovered = epi_output.freyja_uncovered
    String? missing_epi = epi_output.missing_epi
    String freyja_barcode_version = freyja.freyja_barcode_version
    String freyja_metadata_version = freyja.freyja_metadata_version
    File? freyja_bootstrap_lineages = freyja.freyja_bootstrap_lineages
    File? freyja_bootstrap_lineages_pdf = freyja.freyja_bootstrap_lineages_pdf
    File? freyja_bootstrap_summary = freyja.freyja_bootstrap_summary
    File? freyja_bootstrap_summary_pdf = freyja.freyja_bootstrap_summary_pdf
    }
}
