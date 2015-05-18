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
  echo "Usage: $0 <option>" >&2
  echo                      >&2
  echo "Available options:" >&2
  echo "  build"            >&2
  echo "  interactive"      >&2
  echo "  noninteractive"   >&2
  echo "  logs"             >&2
  echo "  restart"          >&2
  echo "  stop"             >&2
}

[ $# -lt 1 ] && showUsage && exit 1;

OPTION="$1"


case "$OPTION" in
  "build")
      docker build -t ${IMAGENAME} .
      ;;

  "interactive")
      docker run -p ${PORT}:${PORT} -v "${LOCALDIR}":"${CONTAINERDIR}" -it ${IMAGENAME} bash
      ;;

  "noninteractive")
      docker run -p ${PORT}:${PORT} -v "${LOCALDIR}":"${CONTAINERDIR}" -d ${IMAGENAME}
      ;;

  "logs")
      getContainerId
      docker logs -f $CONTAINERID
      ;;

  "restart")
      getContainerId
      docker restart $CONTAINERID
      ;;

  "stop")
      getContainerId
      docker stop $CONTAINERID
      ;;

  *)
      showUsage
      exit 1
      ;;
esac

exit 0
