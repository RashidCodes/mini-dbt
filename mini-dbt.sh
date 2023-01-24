#!/bin/bash 

arg=${1};

# colors 
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"


build_model(){
    echo -e "${YELLOW}$(date +%F:%H-%M-%S) [INFO]: Building ${1}${ENDCOLOR}";
    sqlcmd -S server -b -d datastore -E -i ${1} -r

    if [ $? -ne 0 ]
    then 
        echo -e "${RED}$(date +%F:%H-%M-%S) [ERROR]: Failed to build ${1}${ENDCOLOR}";
        exit 1;
    fi 

    if [[ ${1} == "cleanup/cleanup.sql" ]]
    then 
        echo -e "${GREEN}$(date +%F:%H-%M-%S) [INFO]: Successfully removed all objects${ENDCOLOR}";
        exit 0;
    fi;

    echo -e "${GREEN}$(date +%F:%H-%M-%S) [INFO]: Successfully built ${1}${ENDCOLOR}";
}


containsElement () {
    local legendary_array match="$1"
    shift
    for legendary_array; do [[ "$legendary_array" == "$match" ]] && return 0; done;
    return 1;
}


usage() {
    echo "Usage: $0 {[OPTION] {folder_name} | {model_name} | {[folder_name][model_name]}}" 1>&2; 
    echo "Build Models for Adhoc Analysis"
    echo "Example: mini-dbt init"


    echo "Pattern selection and interpretation "
    echo "  --exclude-models-from-build         Build entire project excluding selected models "
    echo "  --build-models-in-folder            Build all models in a single folder "
    echo "  --exclude-models-in-folder          Build models in a single folder excluding selected models "
    echo "  --exclude-folder                    Build entire project excluding selected folders "
    echo "  --build-model                       Build a single model."


    echo
    echo
    echo "Examples"
    echo "Build entire project:                                          mini-dbt "
    echo "Build models in the staging folder:                            mini-dbt --build-models-in-folder staging "
    echo "Build entire project excluding cleanup and analyses folders:   mini-dbt --exclude-folder cleanup/ analyses/"
    echo "Build a single model:                                          mini-dbt --build-model stg_res_mod__accounts.sql "

    exit 1; 
}




# Exclude models from build
if [[ $arg == --exclude-models-from-build ]]
then 
    shift

    # models to be excluded
    exclude_models=${@}
    array=(functions staging optimisation intermediate serving analyses)

    for folder in ${array[@]};
    do
 
        for model in $(find ${folder}/*.sql 2> /dev/null)
        do 
        
            containsElement "${model}" "${folder}/${exclude_models}";

            if [[ $? -ne 0 ]]
            then 
                build_model "${model}"
            fi;

        done;
    done;

    exit 0;
fi;


# Build models in a particular folder
if [[ $arg == --build-models-in-folder ]]
then 
    shift 

    # build single folder 
    single_folder=${@}

    for folder in $single_folder
    do 

        for file in $(find ${folder}/*.sql)
        do
            build_model "${file}"
        done;
    done;

    exit 0;
fi;


# Build models in a particular folder but exclude some models 
if [[ $arg == --exclude-models-in-folder ]]
then 
    shift;

    # get the folder name 
    single_folder=${1}

    shift;

    # get the models to be excluded 
    exclude_models=${@}

    for folder in $single_folder;
    do 
        # model 
        for model in $(find ${folder}/*.sql)
        do 
        
            containsElement "${model}" "${single_folder}/${exclude_models}";

            if [[ $? -ne 0 ]]
            then 
                build_model "${model}"
            else 
                echo -e "${BLUE}$(date +%F:%H-%M-%S) [INFO]: Skipping model ${model}${ENDCOLOR}"; 
            fi;

        done;
    done;

    exit 0;
fi;



# Exclude folder
if [[ $arg == --exclude-folder ]]
then 
    shift

    exclude_folders=${@};

    array=(functions staging optimisation intermediate serving analyses)

    for folder in ${array[@]};
    do 
        containsElement "${folder}/" "${exclude_folders}";

        if [[ $? -ne 0 ]]
        then 
            for model in $(find ${folder}/*.sql)
            do 
                build_model "${model}"
            done;
        else 
            echo -e "${BLUE}$(date +%F:%H-%M-%S) [INFO]: Skipping folder ${folder}${ENDCOLOR}"; 
        fi;

    done;

    exit 0;
fi;





# Build a single model
if [[ $arg == --build-model ]]
then 
    shift

    model_name=${1}

    # build a single model 
    for folder in $(echo */);
    do 

        # files 
        for model in $(find ${folder}*.sql 2> /dev/null)
        do 
            if [[ $model == "${folder}${model_name}" ]]
            then 
                build_model "${model}";
                exit 0;
            fi 
        done;
    done;

    exit 0;
fi;


# Build entire project
if [[ $arg == --all ]]
then 

    array=(functions staging optimisation intermediate serving analyses)
    for folder in ${array[@]};
    do 

        # files 
        for model in $(find ${folder}/*.sql 2> /dev/null)
        do 
            build_model "${model}"
        done;
    done;
    exit 0;
fi;


# Intialise project 
if [[ ${arg} == init ]]
then 
    echo -e "${YELLOW}Initializing your mini-dbt project${ENDCOLOR}"
    array=(analyses assets cleanup functions intermediate optimisation serving staging tests)

    for folder in ${array[@]}; do 
        if [[ ! -d ${folder} ]]
        then
            mkdir ${folder}
        fi;
    done;

    if [[ ! -f ./README.md ]]
    then 
        touch README.md 
    fi;

    echo -e "${GREEN}Initialization successful${ENDCOLOR}"
    echo -e "Try mini-dbt.sh --help for more information"

    exit 0;

fi; 

# Delete all objects
# Build a single model
if [[ $arg == --cleanup ]]
then 

    build_model "cleanup/cleanup.sql"
        
    exit 0;
fi;


if [[ $arg == --help ]]
then 
    usage; 
fi;


echo "rashid's mini-dbt v0.1.5"
echo "Try mini-dbt --help for more information"
