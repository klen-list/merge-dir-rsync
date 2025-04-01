#!/bin/bash

COPY_DIR="target_dir"
SRC_DIR1="source1"
SRC_DIR2="source2"
#SRC_DIR3="source3"

COPY_DIR_FLAG=0
SRC_DIR1_FLAG=0
SRC_DIR2_FLAG=0

sync_to_source() {
  local modified_dir="$1"

  if [ -d "$SRC_DIR1/$modified_dir" ]; then
    rsync -cqr --delete "$COPY_DIR/$modified_dir/" "$SRC_DIR1/$modified_dir/"
  elif [ -d "$SRC_DIR2/$modified_dir" ]; then
    rsync -cqr --delete "$COPY_DIR/$modified_dir/" "$SRC_DIR2/$modified_dir/"
  fi
}

sync_to_copy_dir() {
  local modified_dir="$1"

  if [ -d "$SRC_DIR1/$modified_dir" ]; then
    rsync -cqr --delete "$SRC_DIR1/$modified_dir/" "$COPY_DIR/$modified_dir/"
  elif [ -d "$SRC_DIR2/$modified_dir" ]; then
    rsync -cqr --delete "$SRC_DIR2/$modified_dir/" "$COPY_DIR/$modified_dir/"
  fi
}

inotifywait -m -r -e modify,create,delete --format "%w%f" "$COPY_DIR" | while read modified_file
do
  if [ $SRC_DIR1_FLAG -eq 1 ] || [ $SRC_DIR2_FLAG -eq 1 ]; then
    continue
  fi

  COPY_DIR_FLAG=1

  modified_dir=$(dirname "$modified_file" | sed "s|$COPY_DIR/||")

  sync_to_source "$modified_dir"
  sync_to_copy_dir "$modified_dir"

  COPY_DIR_FLAG=0
done &

inotifywait -m -r -e modify,create,delete --format "%w%f" "$SRC_DIR1" | while read modified_file
do
  if [ $COPY_DIR_FLAG -eq 1 ] || [ $SRC_DIR2_FLAG -eq 1 ]; then
    continue
  fi

  SRC_DIR1_FLAG=1

  modified_dir=$(dirname "$modified_file" | sed "s|$SRC_DIR1/||")

  sync_to_copy_dir "$modified_dir"
  sync_to_source "$modified_dir"

  SRC_DIR1_FLAG=0
done &

inotifywait -m -r -e modify,create,delete --format "%w%f" "$SRC_DIR2" | while read modified_file
do
  if [ $COPY_DIR_FLAG -eq 1 ] || [ $SRC_DIR1_FLAG -eq 1 ]; then
    continue
  fi

  SRC_DIR2_FLAG=1

  modified_dir=$(dirname "$modified_file" | sed "s|$SRC_DIR2/||")

  sync_to_copy_dir "$modified_dir"
  sync_to_source "$modified_dir"

  SRC_DIR2_FLAG=0
done &

wait