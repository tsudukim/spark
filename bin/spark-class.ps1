#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if (! $env:SPARK_HOME) {
  $env:SPARK_HOME = Split-Path -Parent $MyInvocation.MyCommand.Path
}

. "$env:SPARK_HOME\bin\load-spark-env.ps1"

# Find the java binary
$RUNNER = ""
if ($env:JAVA_HOME) {
  $RUNNER = "$env:JAVA_HOME\bin\java"
} else {
  if (where.exe "java" > /dev/null 2>&1) {
    $RUNNER = "java"
  } else {
    Write-Error "JAVA_HOME is not set"
    exit 1
  }
}

# Find assembly jar
$SPARK_ASSEMBLY_JAR = ""
if (Test-Path $env:SPARK_HOME\RELEASE) {
  $ASSEMBLY_DIR = "$env:SPARK_HOME\lib"
} else {
  $ASSEMBLY_DIR = "$env:SPARK_HOME\assembly\target\scala-$env:SPARK_SCALA_VERSION"
}

$ASSEMBLY_JARS = ls $ASSEMBLY_DIR | ? {$_.Name -match "^spark-assembly.*hadoop.*\.jar$"}
$num_jars = ($ASSEMBLY_JARS | Measure-Object).Count
if (($num_jars -eq 0) -and (-not $SPARK_ASSEMBLY_JAR) -and ($env:SPARK_PREPEND_CLASSES -ne "1")) {
  Write-Warning "Failed to find Spark assembly in $ASSEMBLY_DIR."
  Write-Warning "You need to build Spark before running this program."
  exit 1
}
if (Test-Path $ASSEMBLY_DIR) {
  if ($num_jars -gt 2) {
    Write-Warning "Found multiple Spark assembly jars in ${ASSEMBLY_DIR}:"
    Write-Warning "$ASSEMBLY_JARS"
    Write-Warning "Please remove all but one jar."
    exit 1
  }
}

$SPARK_ASSEMBLY_JAR = $ASSEMBLY_JARS.FullName

$LAUNCH_CLASSPATH = $SPARK_ASSEMBLY_JAR

# Add the launcher build dir to the classpath if requested.
if ($env:SPARK_PREPEND_CLASSES) {
  $LAUNCH_CLASSPATH = "$env:SPARK_HOME\launcher\target\scala-$SPARK_SCALA_VERSION\classes;$LAUNCH_CLASSPATH"
}

$env:_SPARK_ASSEMBLY = $SPARK_ASSEMBLY_JAR

# For tests
if ($env:SPARK_TESTING) {
  $env:YARN_CONF_DIR = ""
  $env:HADOOP_CONF_DIR = ""
}

# The launcher library prints the command to be executed in a single line suitable for being
# executed by the batch interpreter. So read all the output of the launcher into a variable.
$SPARK_CMD = (
    Invoke-Expression "& '$RUNNER' -cp `"$LAUNCH_CLASSPATH`" org.apache.spark.launcher.Main $args"
  )
Invoke-Expression "& $SPARK_CMD"
