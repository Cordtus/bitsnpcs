#!/bin/bash

echo "Running dd benchmark..."

echo "Starting dd-write..."
temp_file=$(mktemp)
for i in {1..10}; do
    speed=$(dd if=/dev/zero of=testfile bs=1G count=1 oflag=dsync 2>&1 | \
            awk '/copied/ {print $(NF-1),$NF}')
    if echo "$speed" | grep -q "GB"; then
        speed=$(echo "$speed" | awk '{printf("%.0f MB/s", $1 * 1024)}')
    fi
    echo "Run $i Speed: $speed" | tee -a "$temp_file"
done

awk '{s+=$4} END {printf("Average speed: %.0f MB/s\n", s/NR)}' "$temp_file"
rm "$temp_file"
echo "Finished dd-write."

sleep 1.5s

echo "Starting dd-read..."
temp_file=$(mktemp)
for i in {1..10}; do
    speed=$(dd if=testfile of=/dev/null bs=1G count=1 iflag=direct 2>&1 | \
            awk '/copied/ {print $(NF-1),$NF}')
    if echo "$speed" | grep -q "GB"; then
        speed=$(echo "$speed" | awk '{printf("%.0f MB/s", $1 * 1024)}')
    fi
    echo "Run $i Speed: $speed" | tee -a "$temp_file"
done

awk '{s+=$4} END {printf("Average speed: %.0f MB/s\n", s/NR)}' "$temp_file"
rm "$temp_file"

echo "Finished dd-read."

rm testfile 

echo "Benchmark finished."
