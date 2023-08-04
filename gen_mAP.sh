#!/bin/bash

# environment
source ~/localInstalls/set_python3.sh
conda activate mAP

detection_root="/work/codes/defect_detection/YOLOv3/output" # contains all the detection outputs using multiple models
# ${detection_root} contains folders in named in the format <resolution>_<epoch>
# e.g., "416_100", "416_1000", ..., "416_backup" for YOLOv3 trained models
gt_dir="ground-truth"                                       # contains the ground truth
output_root="./output"                                      # this is where where the mAP output will be generated
csv_file="${output_root}/all_res.csv"                       # this will store the mAP output for different models in a single file 

# remove existing files
eval "rm -rf ${output_root}"
eval "mkdir -p ${output_root}"
eval "touch ${csv_file}"
echo "see results in ${csv_file}..."
header=""


# loop
gt="${detection_root}/${gt_dir}"
for dr in `ls "${detection_root}" -I ${gt_dir}`; do
    # generate output and grab output string 
    cmd="python main.py -na -dr ${detection_root}/${dr} -gt ${gt} -rs ${output_root}/${dr}"
    res="$($cmd)"
    res=$(echo "${res}" | sed -z 's/\ \n/,/g;s/,$/\ \n/') # replace newline with comma

    # generate the prefix and combine with output string
    IFS='_' read -ra strarr <<< "${dr}"
    reso="${strarr[0]}=reso"
    epoch="${strarr[1]}=epoch"
    res="${reso},${epoch},${res}"
    res=$(echo "${res}" | sed -z 's/\ //g') # remove spaces

    # echo ${res} # single line output

    # split header and values 
    IFS=',' read -ra resarr <<< "${res}"
    N=${#resarr[@]}
    new_header=""
    new_values=""
    for (( i=0; i<N; ++i )); do
        IFS='=' read -ra key_val_arr <<< "${resarr[i]}"
        if [ ${i} -lt $(( ${N}-1 )) ]; then
            key=${key_val_arr[1]}
            val=${key_val_arr[0]}
        else
            key=${key_val_arr[0]}
            val=${key_val_arr[1]}
        fi
        val=$(echo ${val} | sed -z 's/\%//g') # remove %
        new_header="${new_header}${key},"
        new_values="${new_values}${val},"
    done

    # replace header when empty and print
    if [ -z "${header}" ]; then
        header="${new_header}"
        echo ${header}
    fi

    # print values
    echo ${new_values}

done > "${csv_file}" # write to csv_file

echo "done!"
