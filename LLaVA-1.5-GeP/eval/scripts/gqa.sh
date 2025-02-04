#!/bin/bash

gpu_list="${CUDA_VISIBLE_DEVICES:-0}"
IFS=',' read -ra GPULIST <<< "$gpu_list"

CHUNKS=${#GPULIST[@]}
SPLIT="llava_gqa_testdev_balanced"
GQADIR="/home/nfs03/zhaof/LLaVA/playground/data/eval/gqa/data"

for IDX in $(seq 0 $((CHUNKS-1))); do
    CUDA_VISIBLE_DEVICES=${GPULIST[$IDX]} python -m llava.eval.model_vqa_loader \
        --model-base /model/vicuna-7b-v1.5 \
        --model-path /model/llava-7b-lora\
        --question-file /playground/data/eval/gqa/$SPLIT.jsonl \
        --image-folder /playground/data/eval/gqa/data/images \
        --answers-file /LLaVA-1.5-GeP/eval/result/gqa/answers/${CHUNKS}_${IDX}.jsonl \
        --num-chunks $CHUNKS \
        --chunk-idx $IDX \
        --temperature 0 \
        --conv-mode vicuna_v1 
done

wait

# output_file=/home/nfs03/zhaof/LLaVA/playground/data/eval/gqa/answers/$SPLIT/$CKPT/merge.jsonl
output_file=/LLaVA-1.5-GeP/eval/result/gqa/answers/merge_1.jsonl

# Clear out the output file if it exists.
> "$output_file"

# Loop through the indices and concatenate each file.
for IDX in $(seq 0 $((CHUNKS-1))); do
    cat /LLaVA-1.5-GeP/eval/result/gqa/answers/${CHUNKS}_${IDX}.jsonl >> "$output_file"
done

python /LLaVA-1.5-GeP/eval/scripts/convert_gqa_for_eval.py --src $output_file --dst /LLaVA-1.5-GeP/eval/result/gqa/data/testdev_balanced_predictions.json

cd $GQADIR
# python eval/eval.py --tier testdev_balanced
python /LLaVA-1.5-GeP/eval/scripts/eval_1.py  --tier testdev_balanced