version 1.0

task freyja_epi_metadata {
  input {
    String samplename
    File ww_metadata_csv
    Int memory = 4
    String docker = "staphb/freyja:1.3.10"
  }
  command <<<
  # capture version

  python3 <<CODE
  import pandas as pd

  accession="~{samplename}"
  accession=accession[0:9]
  file="~{ww_metadata_csv}"
  df = pd.read_csv(file)
  df = df[["PHLAccessionNumber", "SubmitterSampleNumber", "WWTPName",  "SampleCollectDate"]]
  print(df)

  submitter_num=df.loc[df['PHLAccessionNumber'] == accession, 'SubmitterSampleNumber'].iloc[0]
  wwtpname=df.loc[df['PHLAccessionNumber'] == accession, 'WWTPName'].iloc[0]
  collection_date=df.loc[df['PHLAccessionNumber'] == accession, 'WWTPName'].iloc[0]

  submitter_file = open("SUBMITTER_NUM", "w")
  n = submitter_file.write(str(submitter_num))
  submitter_file.close()

  wwtpname_file = open("WWTPNAME", "w")
  n = wwtpname_file.write(str(wwtpname))
  wwtpname_file.close()

  collection_date_file = open("COLLECTION_DATE", "w")
  n = collection_date_file.write(str(collection_date))
  collection_date_file.close()

  CODE

  >>>
  runtime {
    memory: "~{memory} GB"
    cpu: 2
    docker: "~{docker}"
    disks: "local-disk 100 HDD"
    maxRetries: 3
  }
  output {
    String SubmitterSampleNumber = read_string("SUBMITTER_NUM")
    String WWTPName = read_string("WWTPNAME")
    String SampleCollectDate = read_string("COLLECTION_DATE")
    String epi_metadata_docker = "~{docker}"
  }
}

task freyja_epi_output {
  input {
    String samplename
    String samplecollectdate
    String wwtpname
    String submittersamplenumber
    File freyja_demixed
    Int memory = 4
    String docker = "staphb/freyja:1.3.10"
  }
  command <<<
  # capture version
  freyja --version | tee FREYJA_VERSION
  # update freyja reference files if specified


  python3 <<CODE

  import csv
  import fileinput
  import pandas as pd


  id = "~{samplename}"
  sc_date = "~{samplecollectdate}"
  location = "~{wwtpname}"
  submitter = "~{submittersamplenumber}"
  with open("~{freyja_demixed}") as f:
    lines = f.readlines()
    for line in lines:
      if "lineages" in line:
        lineages=line.split("\t")[1].strip().split(" ")
        text_file = open("LINEAGES", "w")
        n = text_file.write(str(lineages))
        text_file.close()

      if "abundances" in line:
        abundances=line.split("\t")[1].strip().split(" ")
        text_file = open("ABUNDANCES", "w")
        n = text_file.write(str(abundances))
        text_file.close()

      if "resid" in line:
        line=line.split("\t")[1]
        #print("resid", line)
        text_file = open("RESID", "w")
        n = text_file.write(line)
        text_file.close()
      if "coverage" in line:
        line=line.split("\t")[1]
        #print("coverage", line)
        text_file = open("COVERAGE", "w")
        n = text_file.write(line)
        text_file.close()

  assert len(abundances) == len(lineages), "error: There should be one relative abundance for every lineage"

  print(len(abundances))
  id_list=[id]*len(abundances)
  date_list=[sc_date]*len(abundances)
  submitter_list=[submitter]*len(abundances)
  location_list=[location]*len(abundances)
  print(id_list)
  for i in range(len(abundances)):
    print(i)
  df = pd.DataFrame({'Sample_ID':submitter_list, 'Sample_Collection_date':date_list,
  'Sample_Site':location_list, "lineages":lineages, "abundances":abundances})
  print(df)
  df.to_csv('~{samplename}_for_epi.tsv', sep="\t", header=False, index=False)
  CODE

  >>>
  runtime {
    memory: "~{memory} GB"
    cpu: 2
    docker: "~{docker}"
    disks: "local-disk 100 HDD"
    maxRetries: 3
  }
  output {
    String freyja_version = read_string("FREYJA_VERSION")
    String freyja_lineages = read_string("LINEAGES")
    String freyja_abundances = read_string("ABUNDANCES")
    String freyja_resid = read_string("RESID")
    String freyja_coverage = read_string("COVERAGE")
    File freyja_epi_file = "~{samplename}_for_epi.tsv"
  }
}