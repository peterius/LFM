#!/bin/bash

git submodule init
git submodule update

scripts/step_one.sh
scripts/step_two.sh
scripts/stepthree.sh
