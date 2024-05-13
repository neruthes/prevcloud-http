#!/bin/bash

case $1 in docs/*.md)
    h=std:article-tech pentex "$1"
    ;;
esac
