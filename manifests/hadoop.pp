#
# == Class cdh::hadoop
#
# Installs the main Hadoop/HDFS packages and config files.  This
# By default this will set Hadoop config files to run YARN (MapReduce 2).
#
# This assumes that your JBOD mount points are already
# formatted and mounted at the locations listed in $datanode_mounts.
#
# dfs.datanode.data.dir will be set to each of ${dfs_data_dir_mounts}/$data_path
# yarn.nodemanager.local-dirs will be set to each of ${dfs_data_dir_mounts}/$yarn_local_path
# yarn.nodemanager.log-dirs will be set to each of ${dfs_data_dir_mounts}/$yarn_logs_path
#
# == Parameters
#   $namenode_hosts                     - Array of NameNode host(s).  The first entry in this
#                                         array will be the primary NameNode.  The primary NameNode
#                                         will also be used as the host for the historyserver, proxyserver,
#                                         and resourcemanager.   Use multiple hosts hosts if you
#                                         configuring Hadoop with HA NameNodes.
#   $dfs_name_dir                       - Path to hadoop NameNode name directory.  This
#                                         can be an array of paths or a single string path.
#   $dfs_hosts_exclude                  - Path to dfs.exclude file
#   $cluster_name                       - Arbitrary logical HDFS cluster name.  This will be used
#                                         as the nameserivce id if you set $ha_enabled to true.
#                                         Default: 'cdh'.
#   $journalnode_hosts                  - Array of JournalNode hosts.  If this is provided,
#                                         Hadoop will be configured to expect to have
#                                         a primary NameNode as well as at least
#                                         one Standby NameNode for use in high availibility mode.
#   $dfs_journalnode_edits_dir          - Path to JournalNode edits dir.  This will be
#                                         ignored if $ha_enabled is false.
#   $datanode_mounts                    - Array of JBOD mount points.  Hadoop datanode and
#                                         mapreduce/yarn directories will be here.
#   $dfs_data_path                      - Path relative to JBOD mount point for HDFS data directories.
#   $datanode_failed_volumes_tolerated  - The number of volumes that are allowed to fail before a datanode stops offering service.
#                                         Default: 0 
#
#   $resourcemanager_hosts      - Array of hosts on which ResourceManager is running.  If this has
#                                 more than one host in it AND $zookeeper_hosts is set, HA YARN ResourceManager
#                                 and automatic failover will be enabled.  This defaults to the value provided
#                                 for $namenode_hosts.  Please be sure to include cdh::hadoop::resourcemanager
#                                 directly on any standby RM hosts.  (The master RM will be included automatically)
#                                 when you include cdh::hadoop::master).
#   $zookeeper_hosts            - Array of Zookeeper hosts to use for HA YARN ResouceManager.
#                                 Default: undef
#   $enable_jmxremote           - enables remote JMX connections for all Hadoop services.
#                                 Ports are not currently configurable.  Default: true.
#   $yarn_local_path            - Path relative to JBOD mount point for yarn local directories.
#   $yarn_logs_path             - Path relative to JBOD mount point for yarn log directories.
#   $dfs_block_size             - HDFS block size in bytes.  Default 64MB.
#   $dfs_replication            - Default block replication. Default: 3
#   $io_file_buffer_size
#   $map_tasks_maximum
#   $reduce_tasks_maximum
#   $mapreduce_job_reuse_jvm_num_tasks
#   $reduce_parallel_copies
#   $map_memory_mb
#   $reduce_memory_mb
#   $mapreduce_system_dir
#   $mapreduce_task_io_sort_mb
#   $mapreduce_task_io_sort_factor
#   $mapreduce_map_java_opts
#   $mapreduce_child_java_opts
#   $yarn_app_mapreduce_am_resource_mb        - The amount of memory the MR AppMaster needs.
#   $yarn_app_mapreduce_am_command_opts       - Java opts for the MR App Master processes. The following symbol, if
#                                              present, will be interpolated: @taskid@ is replaced by current TaskID
#   $mapreduce_shuffle_port
#   $mapreduce_intermediate_compression       - If true, intermediate MapReduce data
#                                               will be compressed.  Default: true.
#   $mapreduce_intermediate_compression_codec - Codec class to use for intermediate compression.
#                                               Default: org.apache.hadoop.io.compress.DefaultCodec
#   $mapreduce_output_compession              - If true, final output of MapReduce
#                                               jobs will be compressed. Default: false.
#   $mapreduce_output_compession_codec        - Codec class to use for final output compression.
#                                               Default: org.apache.hadoop.io.compress.DefaultCodec
#   $mapreduce_output_compession_type         - Whether to output compress on BLOCK or RECORD level.
#                                               Default: RECORD
#   $yarn_nodemanager_resource_memory_mb
#   $yarn_nodemanager_resource_cpu_vcores     - Default: max($::processorcount - 1, 1)
#   $yarn_scheduler_minimum_allocation_mb     - The minimum allocation for every container request at the RM,
#                                               in MBs. Memory requests lower than this won't take effect, and
#                                               the specified value will get allocated at minimum.
#   $yarn_scheduler_maximum_allocation_mb     - The maximum allocation for every container request at the RM,
#                                               in MBs. Memory requests higher than this won't take effect, and
#                                               will get capped to this value.
#   $yarn_scheduler_minimum_allocation_vcores - The minimum allocation for every container request at the RM,
#                                               in terms of virtual CPU cores. Requests lower than this won't
#                                               take effect, and the specified value will get allocated the
#                                               minimum.  Default: undef (1)
#   $yarn_scheduler_maximum_allocation_vcores - The maximum allocation for every container request at the RM,
#                                               in terms of virtual CPU cores. Requests higher than this won't
#                                               take effect, and will get capped to this value.  Default: undef (32)
#   $yarn_resourcemanager_scheduler_class     - If you change this (e.g. to
#                                               FairScheduler), you should also provide
#                                               your own scheduler config .xml files
#                                               outside of the cdh module.
#   $hadoop_heapsize                          - -Xmx for NameNode and DataNode.  Default: undef
#   $hadoop_namenode_opts                     - Any additional opts to pass to NameNode node on startup.  Default: undef
#   $yarn_heapsize                            - -Xmx for YARN Daemons.           Default: undef
#   $dfs_datanode_hdfs_blocks_metadata_enabled - Boolean which enables backend datanode-side support for the experimental
#                                                DistributedFileSystem#getFileVBlockStorageLocations API..
#                                                This is required if you want to use Impala.  Default: undef (false)

#   $ganglia_hosts                            - Set this to an array of ganglia host:ports
#                                               if you want to enable ganglia sinks in hadoop-metrics2.properites
#   $net_topology_script_template             - Puppet ERb template path  to script that will be
#                                               invoked to resolve node names to row or rack assignments.
#                                               Default: undef
#   $gelf_logging_enabled                     - Set this to true in order to configure GELF logging output, for Logstash
#                                             - Needs: libjson-simple-java (Debian package)
#                                             - Needs: logstash-gelf.jar (https://github.com/mp911de/logstash-gelf/releases)
#   $gelf_logging_host                        - Destination host for GELF output. Default is localhost.
#   $gelf_logging_port                        - Destination port for GELF output. Default is 12201.
#   $fair_scheduler_template                  - The fair-scheduler.xml queue configuration template.
#                                               If you set this to false or undef, FairScheduler will
#                                               be disabled.  Default: cdh/hadoop/fair-scheduler.xml.erb
#   $yarn_site_extra_properties               - Hash of extra property names to values that will be
#                                               be rendered in yarn-site.xml.erb.  Default: undef
#   $hdfs_site_extra_properties               - Hash of extra property names to values that will be
#                                               rendered in hdfs-site.xml.erb. Default: undef
#
class cdh::hadoop(
    $namenode_hosts,
    $dfs_name_dir,
    $dfs_hosts_exclude                           = $::cdh::hadoop::defaults::dfs_hosts_exclude,
    $mapred_hosts_exclude                        = $::cdh::hadoop::defaults::mapred_hosts_exclude,
    $yarn_hosts_exclude                          = $::cdh::hadoop::defaults::yarn_hosts_exclude,
    $cluster_name                                = $::cdh::hadoop::defaults::cluster_name,
    $journalnode_hosts                           = $::cdh::hadoop::defaults::journalnode_hosts,
    $dfs_journalnode_edits_dir                   = $::cdh::hadoop::defaults::dfs_journalnode_edits_dir,

    $datanode_mounts                             = $::cdh::hadoop::defaults::datanode_mounts,
    $dfs_data_path                               = $::cdh::hadoop::defaults::dfs_data_path,
    $datanode_failed_volumes_tolerated           = $::cdh::hadoop::defaults::datanode_failed_volumes_tolerated,

    $resourcemanager_hosts                       = $namenode_hosts,
    $zookeeper_hosts                             = $::cdh::hadoop::defaults::zookeeper_hosts,

    $resourcemanager_jmxremote_port              = $::cdh::hadoop::defaults::resourcemanager_jmxremote_port,
    $datanode_jmxremote_port                     = $::cdh::hadoop::defaults::datanode_jmxremote_port,
    $namenode_jmxremote_port                     = $::cdh::hadoop::defaults::namenode_jmxremote_port,
    $proxyserver_jmxremote_port                  = $::cdh::hadoop::defaults::proxyserver_jmxremote_port,
    $nodemanager_jmxremote_port                  = $::cdh::hadoop::defaults::nodemanager_jmxremote_port,

    $intermediate_compression                    = $::cdh::hadoop::defaults::intermediate_compression,

    $yarn_local_path                             = $::cdh::hadoop::defaults::yarn_local_path,
    $yarn_logs_path                              = $::cdh::hadoop::defaults::yarn_logs_path,
    $dfs_block_size                              = $::cdh::hadoop::defaults::dfs_block_size,
    $dfs_replication                             = $::cdh::hadoop::defaults::dfs_replication,
    $enable_jmxremote                            = $::cdh::hadoop::defaults::enable_jmxremote,
    $webhdfs_enabled                             = $::cdh::hadoop::defaults::webhdfs_enabled,
    $httpfs_enabled                              = $::cdh::hadoop::defaults::httpfs_enabled,
    $io_file_buffer_size                         = $::cdh::hadoop::defaults::io_file_buffer_size,
    $io_compression_codecs                       = undef,
    $io_compression_codec_lzo_class              = undef,
    $hadoop_gc_opts                              = undef,
    $mapreduce_system_dir                        = $::cdh::hadoop::defaults::mapreduce_system_dir,
    $mapreduce_map_tasks_maximum                 = $::cdh::hadoop::defaults::mapreduce_map_tasks_maximum,
    $mapreduce_reduce_tasks_maximum              = $::cdh::hadoop::defaults::mapreduce_reduce_tasks_maximum,
    $mapreduce_job_reuse_jvm_num_tasks           = $::cdh::hadoop::defaults::mapreduce_job_reuse_jvm_num_tasks,
    $mapreduce_reduce_shuffle_parallelcopies     = $::cdh::hadoop::defaults::mapreduce_reduce_shuffle_parallelcopies,
    $mapreduce_map_memory_mb                     = $::cdh::hadoop::defaults::mapreduce_map_memory_mb,
    $mapreduce_reduce_memory_mb                  = $::cdh::hadoop::defaults::mapreduce_reduce_memory_mb,
    $mapreduce_jobhistory_webapp_addr            = $::cdh::hadoop::defaults::mapreduce_jobhistory_webapp_addr,
    $yarn_app_mapreduce_am_resource_mb           = $::cdh::hadoop::defaults::yarn_app_mapreduce_am_resource_mb,
    $yarn_app_mapreduce_am_command_opts          = $::cdh::hadoop::defaults::yarn_app_mapreduce_am_command_opts,
    $mapreduce_task_io_sort_mb                   = $::cdh::hadoop::defaults::mapreduce_task_io_sort_mb,
    $mapreduce_task_io_sort_factor               = $::cdh::hadoop::defaults::mapreduce_task_io_sort_factor,
    $mapreduce_map_java_opts                     = $::cdh::hadoop::defaults::mapreduce_map_java_opts,
    $mapreduce_reduce_java_opts                  = $::cdh::hadoop::defaults::mapreduce_reduce_java_opts,
    $mapreduce_shuffle_port                      = $::cdh::hadoop::defaults::mapreduce_shuffle_port,
    $mapreduce_intermediate_compression          = $::cdh::hadoop::defaults::mapreduce_intermediate_compression,
    $mapreduce_intermediate_compression_codec    = $::cdh::hadoop::defaults::mapreduce_intermediate_compression_codec,
    $mapreduce_output_compression                = $::cdh::hadoop::defaults::mapreduce_output_compession,
    $mapreduce_output_compression_codec          = $::cdh::hadoop::defaults::mapreduce_output_compession_codec,
    $mapreduce_output_compression_type           = $::cdh::hadoop::defaults::mapreduce_output_compression_type,
    $yarn_app_mapreduce_am_admin_user_env        = $::cdh::hadoop::defaults::yarn_app_mapreduce_am_admin_user_env,
    $yarn_resourcemanager_scheduler_class        = $::cdh::hadoop::defaults::yarn_resourcemanager_scheduler_class,
    $yarn_nodemanager_resource_memory_mb         = $::cdh::hadoop::defaults::yarn_nodemanager_resource_memory_mb,
    $yarn_nodemanager_resource_cpu_vcores        = $::cdh::hadoop::defaults::yarn_nodemanager_resource_cpu_vcores,
    $yarn_scheduler_minimum_allocation_mb        = $::cdh::hadoop::defaults::yarn_scheduler_minimum_allocation_mb,
    $yarn_scheduler_maximum_allocation_mb        = $::cdh::hadoop::defaults::yarn_scheduler_maximum_allocation_mb,
    $yarn_scheduler_minimum_allocation_vcores    = $::cdh::hadoop::defaults::yarn_scheduler_minimum_allocation_vcores,
    $yarn_scheduler_maximum_allocation_vcores    = $::cdh::hadoop::defaults::yarn_scheduler_maximum_allocation_vcores,
    $yarn_nodemanager_remote_app_log_dir         = $::cdh::hadoop::defaults::yarn_nodemanager_remote_app_log_dir,
    $hadoop_heapsize                             = $::cdh::hadoop::defaults::hadoop_heapsize,
    $hadoop_namenode_opts                        = $::cdh::hadoop::defaults::hadoop_namenode_opts,
    $yarn_heapsize                               = $::cdh::hadoop::defaults::yarn_heapsize,
    $dfs_datanode_hdfs_blocks_metadata_enabled   = $::cdh::hadoop::defaults::dfs_datanode_hdfs_blocks_metadata_enabled,
    $ganglia_hosts                               = $::cdh::hadoop::defaults::ganglia_hosts,
    $net_topology_script_template                = $::cdh::hadoop::defaults::net_topology_script_template,
    $gelf_logging_enabled                        = $::cdh::hadoop::defaults::gelf_logging_enabled,
    $gelf_logging_host                           = $::cdh::hadoop::defaults::gelf_logging_host,
    $gelf_logging_port                           = $::cdh::hadoop::defaults::gelf_logging_port,
    $fair_scheduler_template                     = $::cdh::hadoop::defaults::fair_scheduler_template,
    $capacity_scheduler_template                 = $::cdh::hadoop::defaults::capacity_scheduler_template,
    $core_site_extra_properties                  = $::cdh::hadoop::defaults::core_site_extra_properties,
    $yarn_site_extra_properties                  = $::cdh::hadoop::defaults::yarn_site_extra_properties,
    $hdfs_site_extra_properties                  = $::cdh::hadoop::defaults::hdfs_site_extra_properties,
    $capacity_scheduler_extra_properties         = $::cdh::hadoop::defaults::capacity_scheduler_extra_properties,
) inherits cdh::hadoop::defaults
{
    # If $dfs_name_dir is a list, this will be the
    # first entry in the list.  Else just $dfs_name_dir.
    # This used in a couple of execs throughout this module.
    $dfs_name_dir_main = inline_template('<%= (@dfs_name_dir.class == Array) ? @dfs_name_dir[0] : @dfs_name_dir %>')

    # Config files are installed into a directory
    # based on the value of $cluster_name.
    $config_directory = "/etc/hadoop/conf.${cluster_name}"

    # Set a boolean used to indicate that HA NameNodes
    # are intended to be used for this cluster.  HA NameNodes
    # require the JournalNodes are configured.
    $ha_enabled = $journalnode_hosts ? {
        undef   => false,
        default => true,
    }
    # If $ha_enabled is true, use $cluster_name as $nameservice_id.
    $nameservice_id = $ha_enabled ? {
        true    => $cluster_name,
        default => undef,
    }
    # Assume the primary namenode is the first entry in $namenode_hosts,
    # Set a variable here for reference in other classes.
    $primary_namenode_host = $namenode_hosts[0]
    # This is the primary NameNode ID used to identify
    # a NameNode when running HDFS with a logical nameservice_id.
    # We can't use '.' characters because NameNode IDs
    # will be used in the names of some Java properties,
    # which are '.' delimited.
    $primary_namenode_id   = inline_template('<%= @primary_namenode_host.tr(\'.\', \'-\') %>')


    # Set a boolean used to indicate that HA YARN
    # is intended to be used for this cluster.  HA YARN
    # require the zookeeper is configured, and that
    # multiple ResourceManagers are specificed.
    if $ha_enabled and size($resourcemanager_hosts) > 1 and $zookeeper_hosts {
        $yarn_ha_enabled = true
        $yarn_cluster_id = $cluster_name
    }
    else {
        $yarn_ha_enabled = false
        $yarn_cluster_id = undef
    }

    # Assume the primary resourcemanager is the first entry in $resourcemanager_hosts
    # Set a variable here for reference in other classes.
    $primary_resourcemanager_host = $resourcemanager_hosts[0]


    package { 'hadoop-client':
        ensure => 'installed'
    }

    # Some Hadoop jobs need Zookeeper libraries, but for some reason they
    # are not installed via package dependencies.  Install the CDH
    # zookeeper package here explicitly.  This avoids
    # java.lang.NoClassDefFoundError: org/apache/zookeeper/KeeperException
    # errors.
    package { 'zookeeper':
        ensure => 'installed'
    }

    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hadoop-client'],
    }
    cdh::alternative { 'hadoop-conf':
        link    => '/etc/hadoop/conf',
        path    => $config_directory,
    }

    # Render net-topology.sh from $net_topology_script_template
    # if it was given.
    $net_topology_script_ensure = $net_topology_script_template ? {
        undef   => 'absent',
        default => 'present',
    }
    $net_topology_script_path = "${config_directory}/net-topology.sh"
    file { $net_topology_script_path:
        ensure  => $net_topology_script_ensure,
        mode    => '0755',
    }
    # Conditionally overriding content attribute since
    # $net_topology_script_template is default undef.
    if ($net_topology_script_ensure == 'present') {
        File[$net_topology_script_path] {
            content => template($net_topology_script_template),
        }
    }

    case $yarn_resourcemanager_scheduler_class {
      'FairScheduler': {
        $fair_scheduler_enabled = true 
        $capacity_scheduler_enabled = false 
      }
      'CapacityScheduler': {
        $fair_scheduler_enabled = false 
        $capacity_scheduler_enabled = true 
      }
      # enable CapacityScheduler by default
      default: {
        $fair_scheduler_enabled = false 
        $capacity_scheduler_enabled = true 
      }
    }

    $fair_scheduler_allocation_file_ensure = $fair_scheduler_enabled ? {
        true  => 'present',
        false => 'absent',
    }

    $capacity_scheduler_allocation_file_ensure = $capacity_scheduler_enabled ? {
        true  => 'present',
        false => 'absent',
    }

    file { "${config_directory}/fair-scheduler.xml":
        ensure  => $fair_scheduler_allocation_file_ensure,
        content => template($fair_scheduler_template),
    }

    file { "${config_directory}/capacity-scheduler.xml":
        ensure  => $capacity_scheduler_allocation_file_ensure,
        content => template($capacity_scheduler_template),
    }

    file { "${config_directory}/log4j.properties":
        content => template('cdh/hadoop/log4j.properties.erb'),
    }

    file { "${config_directory}/core-site.xml":
        content => template('cdh/hadoop/core-site.xml.erb'),
    }

    file { "$config_directory/hdfs-site.xml":
        content => template('cdh/hadoop/hdfs-site.xml.erb'),
    }

    file { "${config_directory}/hadoop-env.sh":
        content => template('cdh/hadoop/hadoop-env.sh.erb'),
    }

    file { "${config_directory}/mapred-site.xml":
        content => template('cdh/hadoop/mapred-site.xml.erb'),
    }

    file { "${config_directory}/yarn-site.xml":
        content => template('cdh/hadoop/yarn-site.xml.erb'),
    }

    file { "${config_directory}/yarn-env.sh":
        content => template('cdh/hadoop/yarn-env.sh.erb'),
    }

    file { "${config_directory}/hadoop-policy.xml":
        content => template('cdh/hadoop/hadoop-policy.xml.erb'),
    }

    # Render hadoop-metrics2.properties
    # if we have Ganglia Hosts to send metrics to.
    $hadoop_metrics2_ensure = $ganglia_hosts ? {
        undef   => 'absent',
        default => 'present',
    }
    file { "${config_directory}/hadoop-metrics2.properties":
        ensure  => $hadoop_metrics2_ensure,
        content => template('cdh/hadoop/hadoop-metrics2.properties.erb'),
    }

    # If the current node is meant to be JournalNode,
    # include the journalnode class.  JournalNodes can
    # be started at any time.
    if ($journalnode_hosts and (
            ($::fqdn           and $::fqdn           in $journalnode_hosts) or
            ($::ipaddress      and $::ipaddress      in $journalnode_hosts) or
            ($::ipaddress_eth1 and $::ipaddress_eth1 in $journalnode_hosts)))
    {
            include cdh::hadoop::journalnode
    }
}
