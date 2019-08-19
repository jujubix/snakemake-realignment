#!/bin/bash

INPUT_BAM=$1

samtools view -H $INPUT_BAM | grep "@RG" | awk '{print $2}' | awk '{sub(/ID:/,""); print;}'
