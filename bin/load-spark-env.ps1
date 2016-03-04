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

# This script loads spark-env.ps1 if it exists, and ensures it is only loaded once.
# spark-env.ps1 is loaded from SPARK_CONF_DIR if set, or within the current directory's
# conf\ subdirectory.

# Figure out where Spark is installed
if (! $env:SPARK_HOME) {
  $env:SPARK_HOME = Split-Path -Parent $MyInvocation.MyCommand.Path
}

if (! $env:SPARK_ENV_LOADED) {
  $env:SPARK_ENV_LOADED = 1

  # Returns the parent of the directory this script lives in.
  $parent_dir = $SPARK_HOME

  $user_conf_dir = if ($env:SPARK_CONF_DIR) {$env:SPARK_CONF_DIR} else {"$parent_dir\conf"}

  if (Test-Path "$user_conf_dir\spark-env.ps1") {
    . "$user_conf_dir\spark-env.ps1"
  }
}

# Setting SPARK_SCALA_VERSION if not already set.

if (! $env:SPARK_SCALA_VERSION) {
  $ASSEMBLY_DIR2 = "$env:SPARK_HOME\assembly\target\scala-2.11"
  $ASSEMBLY_DIR1 = "$env:SPARK_HOME\assembly\target\scala-2.10"

  if ((Test-Path $ASSEMBLY_DIR2) -and (Test-Path $ASSEMBLY_DIR1)) {
    Write-Warning "Presence of build for both scala versions(SCALA 2.10 and SCALA 2.11) detected."
    Write-Warning "Either clean one of them or, $env:SPARK_SCALA_VERSION = "2.11" in spark-env.ps1."
    exit 1
  }

  if (Test-Path $ASSEMBLY_DIR2) {
    $env:SPARK_SCALA_VERSION = "2.11"
  } else {
    $env:SPARK_SCALA_VERSION = "2.10"
  }
}
