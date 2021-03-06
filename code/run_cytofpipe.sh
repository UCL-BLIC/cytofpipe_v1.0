#!/bin/bash -l


set -o pipefail


configfile="${CYTOFPIPE_HOME}/aux_files/clustering_config.txt"
inputfiles="";
outputfiles="";
markersfile="";
ref="";
conditions="";
transform="-";
merge="-";
downsample="-";
asinh="-";
displayAll="-";
medians="-";
groups="-";
randomTsneSeed="-";
randomSampleSeed="-";
randomFlowSeed="-";
array="-";


arguments=$@

# Process mode options
while getopts ":i:o:m:-:" opt; do
  case ${opt} in
    -)
        case "${OPTARG}" in
            displayAll)
                displayAll="yes";
                ;;
            flow)
                transform="autoLgcl";
                ;;
            cytof)
                transform="arcsinh";
                ;;
            all)
                merge="all";
                ;;
            downsample)
                downsample="${!OPTIND}";
                OPTIND=$(( $OPTIND + 1 ))
                ;;
            config)
                configfile="${PWD}/${!OPTIND}";
                OPTIND=$(( $OPTIND + 1 ))
                ;;
            randomSampleSeed)
                randomSampleSeed="yes";
                ;;
            randomTsneSeed)
                randomTsneSeed="yes";
                ;;
            randomFlowSeed)
                randomFlowSeed="yes";
                ;;
            array)
                array="yes";
                ;;
            groups)
                groups="${!OPTIND}";
                OPTIND=$(( $OPTIND + 1 ))
                ;;
            *)
                if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                    echo "Unknown option --${OPTARG}" >&2
                fi
                ;;
        esac;;
    i )
        inputfiles=$OPTARG
        ;;
    o )
        outputfiles=$OPTARG
        ;;
    m )
        markersfile=$OPTARG
        ;;
    \? )
        echo "Invalid Option: -$OPTARG" 1>&2
        exit 1
        ;;
    : )
        echo "Invalid Option: -$OPTARG requires an argument" 1>&2
        exit 1
        ;;
  esac
done



## Sets the name of the output file for the times command
if [[ ! $SGE_TASK_ID ]]; then \
  TIMES_FILE=.times.$JOB_NAME.$JOB_ID
else
  TIMES_FILE=.times.$JOB_NAME.$JOB_ID.$SGE_TASK_ID
fi

## Required by function die
trap "exit 1" TERM
export TOP_PID=$$

function die {
  echo "******************************************************"
  echo "["`date`"] ERROR while running $1"
  echo "******************************************************"
  cat $TIMES_FILE
  rm $TIMES_FILE
  kill -s TERM $TOP_PID
}

function run {
  echo ""
  echo "======================================================"
  echo "["`date`"] Starting $1"
  echo " $*"
  echo "======================================================"

  cmd=""
  out=""
  mode="cmd"
  for arg in $*; do
    if [[ $arg == ">" ]]; then mode="out"; else
      if [ $mode == "cmd" ]; then cmd="$cmd $arg"; else out=$arg; fi
    fi
  done

  if [ $mode == "out" ]
  then
    if ! time > $TIMES_FILE \
      $cmd > $out
    then
      die $*
    fi
  else
    if ! time > $TIMES_FILE \
      $*
    then
      die $*
    fi
  fi
}


function run_clustering {

	JOB=${RAND_ID} R CMD BATCH --vanilla --no-save ${CYTOFPIPE_HOME}/code/cytofpipe_clustering.R  ${PWD}/${outputfiles}/log_R.txt

	for i in $PWD/$outputfiles/*_mean_*; do
	  if [ -f "$i" ];
		then
		        run "rm ${PWD}/${outputfiles}/*cluster_mean_heatmap.*"
		        run "rm ${PWD}/${outputfiles}/*cluster_mean_data.*"
			break;
	 fi
	done

        if [ $array == "yes" ]
        then
                find $PWD/$outputfiles -type f ! -name '*cluster_*.csv' -print0 | xargs -0 rm -vf       #- delete everything except *cluster_*.csv files
                find $PWD/$outputfiles -type d -empty -print0 | xargs -0 rmdir -v                       #- delete any empty folders (this shouldn't happen anyway)
        else

		for i in $PWD/$outputfiles/*Rphenograph*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/Rphenograph";
				run "mv $PWD/$outputfiles/*Rphenograph*\.* $PWD/$outputfiles/Rphenograph/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/Rphenograph/*expression_values.csv; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/Rphenograph/expression_values";
				run "mv $PWD/$outputfiles/Rphenograph/*expression_values.csv $PWD/$outputfiles/Rphenograph/expression_values/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/Rphenograph/*group_cluster_percentage*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/Rphenograph/cluster_percentage_data_by_group";
				run "mv $PWD/$outputfiles/Rphenograph/*group_cluster_percentage* $PWD/$outputfiles/Rphenograph/cluster_percentage_data_by_group/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/*FlowSOM*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/FlowSOM";
				run "mv $PWD/$outputfiles/*FlowSOM*\.* $PWD/$outputfiles/FlowSOM/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/FlowSOM/*expression_values.csv; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/FlowSOM/expression_values";
				run "mv $PWD/$outputfiles/FlowSOM/*expression_values.csv $PWD/$outputfiles/FlowSOM/expression_values/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/FlowSOM/*group_cluster_percentage*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/FlowSOM/cluster_percentage_data_by_group";
				run "mv $PWD/$outputfiles/FlowSOM/*group_cluster_percentage* $PWD/$outputfiles/FlowSOM/cluster_percentage_data_by_group/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/*DensVM*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/DensVM";
				run "mv $PWD/$outputfiles/*DensVM*\.* $PWD/$outputfiles/DensVM/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/DensVM/*expression_values.csv; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/DensVM/expression_values";
				run "mv $PWD/$outputfiles/DensVM/*expression_values.csv $PWD/$outputfiles/DensVM/expression_values/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/DensVM/*group_cluster_percentage*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/DensVM/cluster_percentage_data_by_group";
				run "mv $PWD/$outputfiles/DensVM/*group_cluster_percentage* $PWD/$outputfiles/DensVM/cluster_percentage_data_by_group/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/*ClusterX*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/ClusterX";
				run "mv $PWD/$outputfiles/*ClusterX*\.* $PWD/$outputfiles/ClusterX/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/ClusterX/*expression_values.csv; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/ClusterX/expression_values";
				run "mv $PWD/$outputfiles/ClusterX/*expression_values.csv $PWD/$outputfiles/ClusterX/expression_values/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/ClusterX/*group_cluster_percentage*; do
		  if [ -f "$i" ];
			then
				run "mkdir -p $PWD/$outputfiles/ClusterX/cluster_percentage_data_by_group";
				run "mv $PWD/$outputfiles/ClusterX/*group_cluster_percentage* $PWD/$outputfiles/ClusterX/cluster_percentage_data_by_group/.";
				break;
		 fi
		done

		for i in $PWD/$outputfiles/*_sample_level_plot*; do
		   if [ -f "$i" ];
		 	then
		 		run "mkdir -p $PWD/$outputfiles/Marker_level_plots_by_sample";
		 		run "mv $PWD/$outputfiles/*_sample_level_plot* $PWD/$outputfiles/Marker_level_plots_by_sample/.";
		 		break;
		  fi
		done

		for i in $PWD/$outputfiles/*_group_level_plot*; do
		   if [ -f "$i" ];
		 	then
		 		run "mkdir -p $PWD/$outputfiles/Marker_level_plots_by_group";
		 		run "mv $PWD/$outputfiles/*_group_level_plot* $PWD/$outputfiles/Marker_level_plots_by_group/.";
		 		break;
		  fi
		done

		cp ${CYTOFPIPE_HOME}/code/summary_clustering.Rmd ${PWD}/${outputfiles}/.
		R --vanilla  -e "rmarkdown::render('${PWD}/${outputfiles}/summary_clustering.Rmd',params=list(rscript='${CYTOFPIPE_HOME}/code/cytofpipe_clustering.R',rdata='${PWD}/${outputfiles}/cytofpipe.RData',inputparams='${FILE}'))"
		rm -rf ${PWD}/${outputfiles}/summary_clustering.Rmd
		if [ -e "${PWD}/${outputfiles}/summary_clustering.tex" ]
		  then
		      rm ${PWD}/${outputfiles}/summary_clustering.tex
		fi

		for i in $PWD/Rplots*; do
		   if [ -f "$i" ];
		 	then
		 		rm -rf $PWD/Rplots*
		 		break;
		  fi
		done

	fi

	if [ -e "$PWD/${RAND_ID}.txt" ]
	  then
	      rm $PWD/${RAND_ID}.txt
	fi

}



echo "======================================================"
echo " HOST: "`hostname`
echo " TIME: "`date`
echo " ARGS: ${arguments[*]}"
echo "======================================================"


FILE=${PWD}/${RAND_ID}.txt

/bin/cat <<EOM >$FILE
[ params ]
INPUTFILE = ${PWD}/${inputfiles}
OUTPUTFILE = ${PWD}/${outputfiles}
MARKERSFILE = ${PWD}/${markersfile}
CONFIGFILE = $configfile
TRANSFORM = $transform
MERGE = $merge
DOWNSAMPLE = $downsample
DISPLAY_ALL = $displayAll
GROUPS = ${PWD}/${groups}
RANDOM_SAMPLE_SEED = $randomSampleSeed
RANDOM_TSNE_SEED = $randomTsneSeed
RANDOM_FLOW_SEED = $randomFlowSeed
ARRAY = $array
ARGS = ${arguments[*]}
EOM

mkdir -p $PWD/$outputfiles
run_clustering;


echo
echo "======================================================"
echo "["`date`"] Done."
echo "======================================================"

