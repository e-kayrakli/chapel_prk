#!/bin/sh

for rad in 01 10 20 50 100 200 300 400 500;
do
  make radius_analysis r=$rad
done
