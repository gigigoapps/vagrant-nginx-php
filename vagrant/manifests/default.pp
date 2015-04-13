## Gigigo :: Infrastructure base for PHP project with nginx + mongodb
$hostname_suffix = hiera('hostname_suffix')
$dns_suffix = hiera('dns_suffix')
$install_mongodb = hiera('install_mongodb')
$install_mysql = hiera('install_mysql')

node 'default' {
    Exec {
        path      => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ],
        logoutput => 'on_failure'
    }
    File { owner => 0, group => 0, mode => 0644 }

    # Prepare
    user {'www-data':
        ensure => present,
        home   => '/var/www',
        shell  => '/bin/bash',
        before => Class['nginx']
    }

    # Packages
    class { 'apt': }
    package { [
            'atop',
            'bash-completion',
            'bmon',
            'build-essential',
            'curl',
            'ccze',
            'git',
            'htop',
            'iotop',
            'joe',
            'memcached',
            'multitail',
            'rsync',
            'sudo',
            'vim'
        ]:
        ensure => 'installed',
    }
    if $install_mongodb {
        php::module { 'mongo': }
        class { '::mongodb::globals':
            manage_package_repo => true
        } ->
        class { '::mongodb::server':
            nojournal => true
        } ->
        class {'::mongodb::client': }
    }
    if $install_mysql {
        php::module { 'mysql': }
        class { '::mysql::server':
          root_password           => 'root',
          remove_default_accounts => true,
          override_options        => $override_options,
          package_ensure          => $ensure_mysql
        }
        mysql::db { 'project':
          user     => 'project',
          password => 'project'
        }
    }
    
    # Project files and folders
    file { '/var/www':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data'
    } ->
    file {"/var/www/project":
        ensure => 'directory',
        mode   => 755,
        owner  => www-data,
        group  => www-data
    } ->
    file {"/var/www/project/files":
        ensure => 'directory',
        mode   => 755,
        owner  => www-data,
        group  => www-data
    } ->
    file {"/var/www/project/files/var":
        ensure => 'directory',
        mode   => 755,
        owner  => www-data,
        group  => www-data
    } ->
    file {"/var/www/project/files/var/cache":
        ensure => 'directory',
        mode   => 755,
        owner  => www-data,
        group  => www-data
    } ->
    file {"/var/www/project/files/var/logs":
        ensure => 'directory',
        mode   => 755,
        owner  => www-data,
        group  => www-data
    } ->
    file {"/var/www/project/files/vendor":
        ensure => 'directory',
        mode   => 755,
        owner  => www-data,
        group  => www-data
    }

    # NGINX prepare
    file { '/etc/nginx':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data'
    } ->
    file { '/etc/nginx/sites-available':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root'
    } ->
    file { '/etc/nginx/sites-enabled':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root'
    }

    # PHP prepare
    file { '/etc/php5':
    	ensure => 'directory',
    	owner  => 'root',
    	group  => 'root'
    } ->
    file { '/etc/php5/fpm':
    	ensure => 'directory',
    	owner  => 'root',
    	group  => 'root'
    } ->
    file { '/etc/php5/conf.d':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root'
    }

    # WEB configuration
    # Ensure pachage "apache2" in all of his flavours are purged
    package { ['apache2', 'apache2-mpm-prefork', 'apache2-mpm-worker', 'apache2.2-common']:
        ensure => purged,
        before => Class['nginx']
    }
    # Use nginx
    class { "nginx":
        source_dir_purge => true, # Set to true to purge any existing file not present in $source_dir
        source           => 'puppet:///modules/common/nginx/nginx.conf'
    }
    nginx::vhost { "project${hostname_suffix}":
        docroot  => '/var/www/project/src/web',
        template => 'common/nginx/project.conf.erb',
        priority => 10
    }
    file { '/etc/nginx/sites-enabled/default':
        ensure  => 'absent',
        require => Package['nginx'],
        notify  => Service['nginx']
    }

    # PHP configuration
    class { 'php':
        config_file => '/etc/php5/fpm/php.ini',
        service     => 'nginx'
    }
    php::module { 'fpm': }
    php::module { 'apc': module_prefix => 'php-' }
    php::module { 'cli': }
    php::module { 'curl': }
    php::module { 'gd': }
    php::module { 'mcrypt': }
    php::module { 'memcached': }
    file { '/etc/php5/conf.d/90-timezone.ini':
        owner  => 'root',
        group  => 'root',
        ensure => 'present',
        require => File['/etc/php5/conf.d'],
        source => 'puppet:///modules/common/php/timezone.ini',
        notify => Service['php5-fpm']
    }
    if $vm_env == 'dev' {
        php::module { 'xdebug': }
        file { '/etc/php5/conf.d/91-xdebug.ini':
            owner   => root,
            group   => root,
            mode    => 755,
            require => File['/etc/php5/conf.d'],
            source  => 'puppet:///modules/common/php/xdebug.ini',
            notify  => Service['php5-fpm']
        } ->
        file { '/var/log/xdebug':
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root'
        }
        exec { 'enableerrorlog' :
            command => 'sed -i "s/;catch_workers_output = yes/catch_workers_output = yes/" /etc/php5/fpm/pool.d/www.conf',
            user    => 'root',
            require => Package['php5-fpm'],
            notify  => Service['php5-fpm']
        }
    }
    class { 'composer':
        require => Package['php5', 'curl']
    }

    # Memcache config
    file { '/etc/memcached.conf':
        source  => 'puppet:///modules/common/memcached/memcached.conf',
        owner   => 'root',
        group   => 'root',
        ensure  => 'present',
        require => Package['memcached'],
        notify  => Service['memcached']
    }

    # Services
    service { 'memcached':
        ensure  => running,
        enable  => true,
        require => Package["memcached"]
    }
    service { 'php5-fpm':
        ensure  => running,
        enable  => true,
        require => Package["php5-fpm"]
    }
}
