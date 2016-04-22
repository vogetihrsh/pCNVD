# RD based CNV detection tool

## Requirements
Make sure that these tools are added to your PATH variable 
* samtools (Download [here] (https://sourceforge.net/projects/samtools/))
* bedtools ([Install bedtools](http://bedtools.readthedocs.org/en/latest/content/installation.html))
* openMPI  ([Installation Guide](http://lsi.ugr.es/~jmantas/pdp/ayuda/datos/instalaciones/Install_OpenMPI_en.pdf))

# Installation
Download the source code from https://github.com/vogetihrsh/pCNVD, extract the zip file
```
unzip pCNVD.zip
cd pCNVD
make install
```


# Usage
```
pCNVD/cnvtv -i <input BAM file> -o <output prefix> -m <mappability file> -z <bed file contaning windows>
```

## Parameters 
There are several paramters both optional and mandatory. The parameter values can be passed through command line as well as config file. 

| CLI FLAG | CONFIG FILE NAME | DESCRIPTION | OPTIONAL/REQUIRED|
| --- | --- | --- | --- |
| -i | input_file | Input file name | required |
| -o | output | Output file prefix | required |
| -z | window_file | A bed file containing information about windows chromosome name followed by start and stop. The length of each window should be the same for all entries. This length is taken as the bin/window_size | required |
| -m | mappability_file | Mappability values of the corresponding bins in the window file | required | 
| -w | window_length | Window size that is to be used for detection. This value must be equal to the length of the windows in the bed file containing window information | required |
| -c | NA | Configuration file that will be used for paramters. It is important to note that values from config file will overwrite those given through CLI. | optional |
| -p | no_of_procs | Number of segmentation processes that are executed in paralell. The work load is evenly distributed among the processes. Its default value is 32, which is recommended. Segmentation takes time of O(n^2). | optional |
| -u | upper_threshold | This paramater is used to the upper threshold. This factor is multiplied to the average RD value to obtain upper threshold. Default is 1.45 | optional |
| -l | lower_threshold | This paramater is used to the lower threshold. This factor is multiplied to the average RD to obtain lower threshold. Default is 0.55. | optional |
| -f | merge_fraction | Determines when two CNV regions should be merged. Two CNVs separated by a non-CNV region x are merged if they have similar copy number and the codition ((x/y)< Merge_fraction), where is y is the length of the combined CNVs along with the non-CNV region. Default value is 0.2 | optional |

# Contact
For any queries contact vogetisri.harsha@research.iiit.ac.in
