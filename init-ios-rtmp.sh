#! /usr/bin/env bash
#
# Copyright (C) 2013-2015 HatsuneMikuV <anglemiku_v@163.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

IJK_RTMP_UPSTREAM=https://github.com/HatsuneMikuV/librtmp.git
IJK_RTMP_FORK=https://github.com/HatsuneMikuV/librtmp.git
IJK_RTMP_COMMIT=librtmp-1.0.0
IJK_RTMP_LOCAL_REPO=extraRtmp/rtmp

set -e
TOOLS=tools

echo "== pull rtmp base =="
sh $TOOLS/pull-repo-base.sh $IJK_RTMP_UPSTREAM $IJK_RTMP_LOCAL_REPO

function pull_fork()
{
    echo "== pull rtmp fork $1 =="
    sh $TOOLS/pull-repo-ref.sh $IJK_RTMP_FORK ios/rtmp-$1 ${IJK_RTMP_LOCAL_REPO}
    cd ios/rtmp-$1
    git checkout ${IJK_RTMP_COMMIT} -B ijkplayer
    cd -
}

pull_fork "armv7"
pull_fork "armv7s"
pull_fork "arm64"
pull_fork "i386"
pull_fork "x86_64"
