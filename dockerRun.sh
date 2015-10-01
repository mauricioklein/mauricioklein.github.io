#!/bin/bash

#
# dockerRun.sh
#
# Automate common docker tasks.
#
# @CreatedBy: Mauricio Klein
# @CreatedAt: May 17th, 2014
#

# Docker variables
IMAGENAME="jekyll"
LOCALDIR=$(pwd)
CONTAINERDIR="/root/jekyll"
CONTAINERID=
PORT=4000


function getContainerId () {
  CONTAINERID=$(docker ps | grep "${IMAGENAME}:latest" | head -1 | cut -d ' ' -f 1)
}

function showUsage () {
  echo "Usage: $0 <option>"    >&2
  echo                         >&2
  echo "Available options:"    >&2
  echo "  build (b)"           >&2
  echo "  interactive (i)"     >&2
  echo "  noninteractive (ni)" >&2
  echo "  logs (l)"            >&2
  echo "  restart (r)"         >&2
  echo "  stop (s)"            >&2
}

[ $# -lt 1 ] && showUsage && exit 1;

OPTION="$1"


case "$OPTION" in
  "build"|"b")
      docker build -t ${IMAGENAME} .
      ;;

  "interactive"|"i")
      docker run -p ${PORT}:${PORT} -v "${LOCALDIR}":"${CONTAINERDIR}" -it ${IMAGENAME} bash
      ;;

  "noninteractive"|"ni")
      docker run -p ${PORT}:${PORT} -v "${LOCALDIR}":"${CONTAINERDIR}" -t ${IMAGENAME} preview
      ;;

  "logs"|"l")
      getContainerId
      docker logs -f $CONTAINERID
      ;;

  "restart"|"r")
      getContainerId
      docker restart $CONTAINERID
      ;;

  "stop"|"s")
      getContainerId
      docker stop $CONTAINERID
      ;;

  *)
      showUsage
      exit 1
      ;;
esac

exit 0
