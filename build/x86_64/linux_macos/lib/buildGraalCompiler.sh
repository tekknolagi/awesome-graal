#!/usr/bin/env bash

set -e
set -u
set -o pipefail

source ${SCRIPTS_LIB_DIR}/utils.sh

BASEDIR=$1
MX=$2
BUILD_ARTIFACTS_DIR=$3
echo ">>> Building Graal"
cd ${BASEDIR}
gitClone oracle \
         graal  \
         master \
         "Getting sources for the Graal compiler"

echo ">>>> Currently JAVA_HOME=${JAVA_HOME}"
JDK8_JVMCI_HOME="$(cd ${BASEDIR}/graal-jvmci-8/ && ${MX} --java-home ${JAVA_HOME} jdkhome)"
export JVMCI_VERSION_CHECK='ignore'
export JAVA_HOME=${JDK8_JVMCI_HOME}
echo ">>>> Newly set JAVA_HOME=${JAVA_HOME}"

cd ${BASEDIR}/graal/compiler
export JVMCI_VERSION_CHECK='ignore'
echo ">>>> Setting environment variable JVMCI_VERSION_CHECK=${JVMCI_VERSION_CHECK}"
echo ">>>> Setting BUILD_GRAAL_COMPILER_VERBOSE_MODE_FLAG=${BUILD_GRAAL_COMPILER_VERBOSE_MODE_FLAG:-}"
echo ">>>> Setting JAVA_OPTS=${JAVA_OPTS}"

MAX_CPUS=${MAX_CPUS:-$(getAvailableThreads)}
echo ">>>> Setting MAX_CPUS=${MAX_CPUS}"

set -x
${MX} --max-cpus ${MAX_CPUS} --java-home=${JDK8_JVMCI_HOME} \
      ${BUILD_GRAAL_COMPILER_VERBOSE_MODE_FLAG:-} "-A-J${JAVA_OPTS}" build
set +x

echo "Applying and checking patch to mx_jvmci.py..."
git apply ${SCRIPTS_LIB_DIR}/patch/mx_compiler.py-VM-string-fix.patch || true
grep "pattern \= re.compile" -B 2 compiler/mx.compiler/mx_compiler.py || true

set -x
${MX} --max-cpus ${MAX_CPUS}          \
      --java-home=${JDK8_JVMCI_HOME}  \
      "-A-J${JAVA_OPTS}" makegraaljdk \
      --force ${BUILD_ARTIFACTS_DIR}
set +x