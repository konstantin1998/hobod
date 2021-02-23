#!/usr/bin/env bash

OUT_DIR="streaming_wc_result"
NUM_REDUCERS=8

hadoop fs -rm -r -skipTrash $OUT_DIR*

yarn jar /opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -D mapreduce.job.reduces=0 \
    -files mapper.py,reducer.py \
    -mapper mapper.py \
    -reducer reducer.py \
    -input /data/wiki/en_articles_part \
    -output $OUT_DIR

# TODO:
# - turn off the Reduce phase: NUM_REDUCERS=0, investigate the result

# Checking result
for num in `seq 0 $[$NUM_REDUCERS - 1]`
do
    hadoop fs -cat ${OUT_DIR}/part-0000$num | head
done

exit

#!/usr/bin/env bash

OUT_DIR="streaming_wc_result"
NUM_REDUCERS=8

hadoop fs -rm -r -skipTrash $OUT_DIR*

# Wordcount
( hadoop jar /opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -D mapred.job.name="Straming wordCount" \
    -D mapreduce.job.reduces=$NUM_REDUCERS \
    -files count_mapper.py,sum_reducer.py \
    -mapper count_mapper.py \
    -reducer sum_reducer.py \
    -input /data/wiki/en_articles_part \
    -output ${OUT_DIR}_tmp &&

# Sorting (global if you set 1 reducer)
hadoop jar /opt/cloudera/parcels/CDH/lib/hadoop-mapreduce/hadoop-streaming.jar \
    -D stream.num.map.output.key.fields=2 \
    -D mapreduce.job.reduces=$NUM_REDUCERS \
    -D mapreduce.job.output.key.comparator.class=org.apache.hadoop.mapreduce.lib.partition.KeyFieldBasedComparator \
    -D mapreduce.partition.keycomparator.options=-k2,2nr \
    -mapper cat \
    -reducer cat \
    -input ${OUT_DIR}_tmp \
    -output $OUT_DIR ) || echo "Error happens"

# Checking result
for num in `seq 0 $[$NUM_REDUCERS - 1]`
do
    hadoop fs -cat ${OUT_DIR}/part-0000$num | head
done
