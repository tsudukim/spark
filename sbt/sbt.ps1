# When creating new tests for Spark SQL Hive, the HADOOP_CLASSPATH must contain the hive jars so
# that we can run Hive to generate the golden answer.  This is not required for normal development
# or testing.
if ("$env:HIVE_HOME" -ne ""){
  $hive_lib = Join-Path "$env:HIVE_HOME" "lib"
  if (Test-Path $hive_lib){
    Get-ChildItem $hive_lib | ForEach-Object {
      $env:HADOOP_CLASSPATH = "$env:HADOOP_CLASSPATH" + ":" + "$_"
    }
  }
}
echo $env:HADOOP_CLASSPATH

$script_dir = Split-Path $script:myInvocation.MyCommand.path -parent
. (Join-Path $script_dir "sbt-launch-lib.ps1")

$noshare_opts = "-Dsbt.global.base=project\.sbtboot -Dsbt.boot.directory=project\.boot -Dsbt.ivy.home=project\.ivy"
$sbt_opts_file = ".sbtopts"
$sbt_opts_file = "C:\Users\tsudukim\Downloads\AMPCAMP\sbt\conf\sbtopts"
$etc_sbt_opts_file = "/etc/sbt/sbtopts"

function usage(){
  Write-Output @'
Usage: $script_name [options]

  -h | -help         print this message
  -v | -verbose      this runner is chattier
  -d | -debug        set sbt log level to debug
  -no-colors         disable ANSI color codes
  -sbt-create        start sbt even if current directory contains no sbt project
  -sbt-dir   <path>  path to global settings/plugins directory (default: ~/.sbt)
  -sbt-boot  <path>  path to shared boot directory (default: ~/.sbt/boot in 0.11 series)
  -ivy       <path>  path to local Ivy repository (default: ~/.ivy2)
  -mem    <integer>  set memory options (default: $sbt_mem, which is $(get_mem_opts $sbt_mem))
  -no-share          use all local caches; no sharing
  -no-global         uses global caches, but does not use global ~/.sbt directory.
  -jvm-debug <port>  Turn on JVM debugging, open at the given port.
  -batch             Disable interactive mode

  # sbt version (default: from project/build.properties if present, else latest release)
  -sbt-version  <version>   use the specified version of sbt
  -sbt-jar      <path>      use the specified jar as the sbt launcher
  -sbt-rc                   use an RC version of sbt
  -sbt-snapshot             use a snapshot version of sbt

  # java version (default: java from PATH, currently $(java -version 2>&1 | grep version))
  -java-home <path>         alternate JAVA_HOME

  # jvm options and output control
  JAVA_OPTS          environment variable, if unset uses "$java_opts"
  SBT_OPTS           environment variable, if unset uses "$default_sbt_opts"
  .sbtopts           if this file exists in the current directory, it is
                     prepended to the runner args
  /etc/sbt/sbtopts   if this file exists, it is prepended to the runner args
  -Dkey=val          pass -Dkey=val directly to the java runtime
  -J-X               pass option -X directly to the java runtime
                     (-J is stripped)
  -S-X               add -X to sbt's scalacOptions (-J is stripped)
  -PmavenProfiles     Enable a maven profile for the build.

In the case of duplicated or conflicting options, the order above
shows precedence: JAVA_OPTS lowest, command line options highest.
'@
}

function process_my_args($_args){
  while ($_args.Count -ne 0){
    switch -CaseSensitive ($_args[0]){
      "-no-colors"     {addJava "-Dsbt.log.noformat=true" ; shift $_args 1}
      "-no-share"      {addJava $noshare_opts ; shift $_args 1}
      "-no-global"     {$a = "-Dsbt.global.base=" + (pwd) + "\project\.sbtboot"; addJava $a; shift $_args 1}
      "-sbt-boot"      {require_arg "path" $_args; $a="-Dsbt.boot.directory="+$_args[1]; addJava $a; shift $_args 2}
      "-sbt-dir"       {require_arg "path" $_args; $a="-Dsbt.global.base="+$_args[1]; addJava $a; shift $_args 2}
      "-debug-inc"     {addJava "-Dxsbt.inc.debug=true" ; shift $_args 1}
      "-batch"         {}

      "-sbt-create"    {$global:sbt_create=1; shift $_args 1}

      default          {addResidual $_args[0]; shift $_args 1}
    }
  }
}

function loadConfigFile($file, $_args){
  Get-Content $file | ForEach-Object {
    $_.Trim() -replace '^#.*$' -split " "
  } | Where-Object {
    $_.Length -gt 0
  } | ForEach-Object{
    $_args.Add($_)
  }
}

# In powershell, it is difficult to operate $args (which is powershell array) like bash way.
# So, we convert it to List<String> in .NET Framework first.
$argslist = New-Object 'System.Collections.Generic.List[System.String]'

# if sbtopts files exist, prepend their contents to $argslist so it can be processed by this runner
if(Test-Path $sbt_opts_file){
  loadConfigFile $sbt_opts_file $argslist
}

$args | ForEach-Object {
  $argslist.Add($_)
}
run $argslist

echo " + debug: $debug"
echo " + verbose: $debug"
echo " + sbt_mem: $sbt_mem"
echo " + sbt_create: $sbt_create"

