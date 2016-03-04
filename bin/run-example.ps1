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

$EXAMPLES_DIR = "$env:SPARK_HOME\examples"

. "$env:SPARK_HOME\bin\load-spark-env.ps1"

if ($args.Count -gt 0) {
  $EXAMPLE_CLASS, $rest_args = $args
} else {
  Write-Warning "Usage: .\bin\run-example <example-class> [example-args]"
  Write-Warning "  - set MASTER=XX to use a specific master"
  Write-Warning "  - can use abbreviated example class name relative to com.apache.spark.examples"
  Write-Warning "     (e.g. SparkPi, mllib.LinearRegression, streaming.KinesisWordCountASL)"
  exit 1
}

$JAR_PATH = ""
if (Test-Path "$env:SPARK_HOME\RELEASE") {
  $JAR_PATH = "$env:SPARK_HOME\lib"
} else {
  $JAR_PATH = "$EXAMPLES_DIR\target\scala-$env:SPARK_SCALA_VERSION"
}

$SPARK_EXAMPLES_JARS = ls $JAR_PATH | ? {$_.Name -match "^spark-examples-.*hadoop.*\.jar$"}
$JAR_COUNT = ($SPARK_EXAMPLES_JARS | Measure-Object).Count
if ($JAR_COUNT -eq 0) {
  Write-Warning "Failed to find Spark examples assembly in $SPARK_HOME\lib or $SPARK_HOME\examples\target"
  Write-Warning "You need to build Spark before running this program"
  exit 1
}
if ($JAR_COUNT -gt 1) {
  Write-Warning "Found multiple Spark examples assembly jars in $JAR_PATH"
  Write-Warning "$SPARK_EXAMPLES_JARS"
  Write-Warning "Please remove all but one jar."
  exit 1
}

$SPARK_EXAMPLES_JAR = $SPARK_EXAMPLES_JARS.FullName

$EXAMPLE_MASTER = if($env:MASTER) { $env:MASTER } else { "local[*]" }

if (! ($EXAMPLE_CLASS -like "org.apache.spark.examples*")) {
  $EXAMPLE_CLASS = "org.apache.spark.examples.$EXAMPLE_CLASS"
}

& "$env:SPARK_HOME\bin\spark-submit.ps1" "--master $EXAMPLE_MASTER --class $EXAMPLE_CLASS $SPARK_EXAMPLES_JAR $rest_args"
