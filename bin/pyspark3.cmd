@echo off

rem
rem Licensed to the Apache Software Foundation (ASF) under one or more
rem contributor license agreements.  See the NOTICE file distributed with
rem this work for additional information regarding copyright ownership.
rem The ASF licenses this file to You under the Apache License, Version 2.0
rem (the "License"); you may not use this file except in compliance with
rem the License.  You may obtain a copy of the License at
rem
rem    http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.
rem

rem Figure out where the Spark framework is installed
set FWDIR=%~dp0..\

rem Export this as SPARK_HOME
set SPARK_HOME=%FWDIR%

set SCALA_VERSION=2.10

echo %* | findstr "\<--help\> \<-h\>" >nul
if %ERRORLEVEL% equ 0 (
  call :usage
  exit /b 0
)

rem Test whether the user has built Spark
if exist "%FWDIR%RELEASE" goto skip_build_test
set FOUND_JAR=0
for %%d in ("%FWDIR%assembly\target\scala-%SCALA_VERSION%\spark-assembly*hadoop*.jar") do (
  set FOUND_JAR=1
)
if [%FOUND_JAR%] == [0] (
  echo Failed to find Spark assembly JAR.
  echo You need to build Spark before running this program.
  exit /b 1
)
:skip_build_test

rem Load environment variables from conf\spark-env.cmd, if it exists
if exist "%FWDIR%conf\spark-env.cmd" call "%FWDIR%conf\spark-env.cmd"

rem Users should set environment variable PYTHON_PATH or IPYTHON_PATH
rem before call pyspark.cmd if python or ipython is not in the %PATH%.
if [%PYTHON_PATH%] == [] set PYTHON_PATH=python
if [%IPYTHON_PATH%] == [] set IPYTHON_PATH=ipython

rem Determine the Python executable to use in default.
set DEFAULT_PYTHON=%PYTHON_PATH%

rem Determine the Python executable to use for the driver:
if [%IPYTHON_OPTS%] == [] if not "%IPYTHON%" == "1" (
  if [%PYSPARK_PYTHON%] == [] (
    set PYSPARK_DRIVER_PYTHON=%PYSPARK_PYTHON%
  ) else (
    set PYSPARK_DRIVER_PYTHON=%DEFAULT_PYTHON%
) else (
  set PYSPARK_DRIVER_PYTHON_OPTS=%PYSPARK_DRIVER_PYTHON_OPTS% %IPYTHON_OPTS%
)

rem Determine the Python executable to use for the executors:
if [%PYSPARK_PYTHON%] == [] (
  echo %PYSPARK_DRIVER_PYTHON% | findstr "ipython" >/nul
  if %ERRORLEVEL% equ 0 (
    rem In Windows version
    echo "IPython requires Python 2.7+; please install python2.7 or set PYSPARK_PYTHON" 1>&2
  )
  set PYSPARK_PYTHON=%DEFAULT_PYTHON%
)
if [[ -z "$PYSPARK_PYTHON" ]]; then
  if [[ $PYSPARK_DRIVER_PYTHON == *ipython* && $DEFAULT_PYTHON != "python2.7" ]]; then
    echo "IPython requires Python 2.7+; please install python2.7 or set PYSPARK_PYTHON" 1>&2
    exit 1
  else
    PYSPARK_PYTHON="$DEFAULT_PYTHON"
  fi
fi
export PYSPARK_PYTHON

set PYTHONPATH=%FWDIR%python;%PYTHONPATH%
set PYTHONPATH=%FWDIR%python\lib\py4j-0.8.2.1-src.zip;%PYTHONPATH%

set OLD_PYTHONSTARTUP=%PYTHONSTARTUP%
set PYTHONSTARTUP=%FWDIR%python\pyspark\shell.py
call %SPARK_HOME%\bin\win-utils\gatherSparkSubmitOpts.cmd %*
if %ERRORLEVEL% equ 1 (
  call :usage
  exit /b 1
)
set PYSPARK_SUBMIT_ARGS=%SUBMISSION_OPTS%

rem For pyspart tests
if not [%SPARK_TESTING%] == [] (
  set YARN_CONF_DIR=
  set HADOOP_CONF_DIR=
  if not [%PYSPARK_DOC_TEST%] == [] (
    %PYSPARK_DRIVER_PYTHON% -m doctest %1
  ) else (
    %PYSPARK_DRIVER_PYTHON% %1
  )
  exit /b 0
)

echo Running %PYSPARK_PYTHON% with PYTHONPATH=%PYTHONPATH%

rem Check whether the argument is a file
set PYTHON_FILE=
for /f %%i in ('echo %1^| findstr /R "\.py"') do (
  set PYTHON_FILE=%%i
)

if [%PYTHON_FILE%] == [] (
  set PYSPARK_SHELL=1
  %PYSPARK_DRIVER_PYTHON% $PYSPARK_DRIVER_PYTHON_OPTS
) else (
  echo.
  echo WARNING: Running python applications through ./bin/pyspark.cmd is deprecated as of Spark 1.0.
  echo Use ./bin/spark-submit ^<python file^>
  echo.
  set primary=%1
  shift
  call %SPARK_HOME%\bin\win-utils\gatherSparkSubmitOpts.cmd %*
  if %ERRORLEVEL% equ 1 (
    call :usage
    exit /b 1
  )
  "%FWDIR%\bin\spark-submit.cmd" %SUBMISSION_OPTS% %primary% %APPLICATION_OPTS%
)

exit /b 0

:usage
echo "Usage: .\bin\pyspark.cmd [options]" >&2
%FWDIR%\bin\spark-submit --help 2>&1 | findstr /V "Usage" 1>&2
exit /b 0

:exit
