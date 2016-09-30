#!/bin/bash

pairjob=`qsub bash/pair_ends.sh`
echo "pair_ends: $pairjob"

splitjob=`qsub -W depend=afterok:"$pairjob" bash/split_derep.sh`
echo "split_derep: $splitjob"

extractjob=`qsub -W depend=afterok:"$splitjob" bash/extract_its2.sh`
echo "extract_its2: $extractjob"

pickjob=`qsub -W depend=afterok:"$extractjob" bash/pick_otu.sh`
echo "pick_otu: $pickjob"
