#Install-Module -Name SqlServerDsc

#set-psrepository -Name PSGallery -InstallationPolicy Trusted
#install-module xPSDesiredStateConfiguration
#install-module SqlServerDsc
sa


Configuration SQLInstall
{
    param (        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SQLSVCPSCred,        [string[]]$ComputerName = 'localhost'     )

    Import-DscResource -ModuleName PSDesiredStateConfiguration    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName SqlServerDsc

    Node $ComputerName {


        WindowsFeature 'NetFramework45'
        {
            Name = 'Net-Framework-45-Core'
            Ensure = 'Present'
        }

        WindowsFeature 'FailoverClustering'
        {
            Name = 'Failover-Clustering'
            Ensure = 'Present'
        }
        

        SqlSetup 'InstallDefaultInstance'
        {
            Action              = 'Install'
            InstanceName        = 'MSSQLSERVER'
            Features            = 'SQLENGINE'
            SourcePath          = 'D:\'
            SQLSysAdminAccounts = @('Administrators')
            SqlTempdbFileCount  = 8
            SqlTempdbFileSize   = 512 #megabytes
            SqlTempdbFileGrowth = 512
            SqlTempdbLogFileSize = 512
            SqlTempdbLogFileGrowth = 512
            TcpEnabled          = $true

            SQLSvcAccount       = $SQLSVCPSCred
            AgtSvcAccount       = $SQLSVCPSCred

            DependsOn           = '[WindowsFeature]NetFramework45'

           
        }

        SqlAlwaysOnService 'EnableAlwaysOn'
        {
            Ensure               = 'Present'
            ServerName           = $Node.NodeName
            InstanceName         = 'MSSQLSERVER'
            RestartTimeout       = 120

            DependsOn =          = '[SqlSetup]InstallDefaultInstance'
        }

        SqlDatabase 'DBADatabase'
        {
            ServerName          = $Node.NodeName    #optional
            InstanceName        = 'MSSQLSERVER'     #optional
            Name                = 'DBA'
            RecoveryModel       = 'Simple'
            OwnerName           = 'sa'
            Ensure              = 'Present'
            DependsOn           = '[SqlSetup]InstallDefaultInstance'
        }

        SqlConfiguration 'MAXDOP'
        {

            ServerName     = $Node.NodeName
            InstanceName   = 'MSSQLSERVER'
            OptionName     = 'max degree of parallelism'
            OptionValue    = 4
            RestartService = $false
            DependsOn      = '[SqlSetup]InstallDefaultInstance'
        }

    }                }SQLInstallstart-DscConfiguration .\SQLInstall -wait -force -verbose

#Get-dscconfigurationstatus
#test-dscconfiguration
#update-dscconfiguration #staging and enacting -use existing
#get-dsclocalconfigurationmanager
#Get-DscResource -Module SqlServerDsc


Get-dscconfiguration
test-dscconfiguration


