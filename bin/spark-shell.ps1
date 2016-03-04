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

# PowerShell script for starting the Spark Shell REPL

if (! $env:SPARK_HOME) {
  $env:SPARK_HOME = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$_SPARK_CMD_USAGE = "Usage: .\bin\spark-shell [options]"

# SPARK-4161: scala does not assume use of the java classpath,
# so we need to add the "-Dscala.usejavacp=true" flag manually. We
# do this specifically for the Spark shell because the scala REPL
# has its own class loader, and any additional classpath specified
# through spark.driver.extraClassPath is not automatically propagated.
$SPARK_SUBMIT_OPTS = "$SPARK_SUBMIT_OPTS -Dscala.usejavacp=true"

function main(){
  $env:SPARK_SUBMIT_OPTS = $SPARK_SUBMIT_OPTS
  & "$env:SPARK_HOME\bin\spark-submit.ps1" "--class org.apache.spark.repl.Main --name `"Spark shell`" $args"
}

main "$args"
exit $lastexitcode
