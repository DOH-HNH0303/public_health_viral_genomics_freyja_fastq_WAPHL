version 1.0

task freyja_epi_output {
  input {
    String samplename
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
  print(id_list)
  for i in range(len(abundances)):
    print(i)
  df = pd.DataFrame({'sample_id':id_list, "lineages":lineages, "abundances":abundances})
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
