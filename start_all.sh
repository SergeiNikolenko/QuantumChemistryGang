#!/bin/bash

find . -type d -mindepth 1 -maxdepth 1 | while read dir; do
  cd "$dir"
  
  if [[ -f "submit_jobs.sh" ]]; then
    bash submit_jobs.sh
  else
    pass
  fi
  
  cd ..
done
