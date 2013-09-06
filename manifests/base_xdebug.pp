include upgrade
include ntpd
include motd
include apachephp
include imagick
include db
include apc
include createdb
include ezfind
include virtualhosts
include composer
include prepareezpublish
include addhosts
include xdebug
include git

class xdebug {
    require upgrade
    package { "php5-xdebug":
        ensure => installed,
    } ~>
    file {'/etc/php5/conf.d/xdebug.ini':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/php/xdebug.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package["php5"],
    }
}

class git {
    package { "git":
      ensure => installed,
    }
}

class upgrade {
    exec { 'apt-get update':
        command => '/usr/bin/apt-get update',
        returns => [0, 1],
    } ~>
    exec { 'apt-get dist-upgrade':
        command => '/usr/bin/apt-get dist-upgrade -y',
        returns => [0, 1, 100],
    } ~>
    package { "vim":
        ensure => installed,
    }
}

class ntpd {
    require upgrade
    package { "ntpdate": 
        ensure => installed 
    }
}

class motd {
    require upgrade    
    file    {'/etc/motd':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/motd/motd.xdebug.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    }
}

class apachephp {
    $neededpackages = [ "apache2", "apache2-mpm-prefork", "php5", "php5-cli", "php5-gd" ,"php5-pgsql", "php-pear", "php-xml-rpc", "curl", "php5-intl", "php5-curl", "php5-xsl" ]
    require upgrade
    package { $neededpackages:
        ensure => present,
    } ~>
    file    {'/etc/apache2/sites-enabled/01.accept_pathinfo.conf':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/apache/01.accept_pathinfo.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    } ~>
    file    {'/etc/php5/conf.d/php.ini':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/php/php.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    } ~>
    exec { "rewrite rules":
        command => "/usr/sbin/a2enmod rewrite",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
        require => Package[ "apache2" ]
    } ~>
    exec { "restart apache2":
        command => "service apache2 restart",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    }
}

class imagick {
    require upgrade    
    $neededpackages = [ "imagemagick", "imagemagick-common", "php5-imagick" ]
    require upgrade
    package { $neededpackages:
        ensure => installed
    }
}

class db {
    require upgrade     
    $neededpackages = [ "postgresql-9.1","postgresql-client-9.1","postgresql-common" ]
    package { $neededpackages:
      ensure => installed
    } ->
    file    {'/var/lib/pgsql/data/pg_hba.conf':
      ensure  => file,
      content => template('/tmp/vagrant-puppet/manifests/postgres/pg_hba.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '644',
      require => Package["postgresql-server"],
    } ->
    file    {'/usr/share/pgsql/postgresql.conf':
      ensure  => file,
      content => template('/tmp/vagrant-puppet/manifests/postgres/postgresql.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '644',
      require => Package["postgresql-server"],
    } ->    
    service { "postgresql":
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => Package["postgresql-9.1"],
      restart => true,
      before => Exec["create-ezp-db"],
    }
}

class createdb {
    require db     
    exec { "create-ezp-db":
      command => "/bin/bash /tmp/vagrant-puppet/manifests/postgres/preparedb.sh",
      path    => "/usr/local/bin/:/bin/",
      require => Package["postgresql-9.1"]
    }
}


class apc {
    require upgrade    
    $neededpackages = [ "php5-dev", "php-apc" ]
    package { $neededpackages:
        ensure => installed
    } ~>
    file    {'/etc/php5/apache2/conf.d/20-apc.ini':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/php/apc.ini.erb'),
    }
}

class ezfind {
    require upgrade
    package { "openjdk-6-jdk":
        ensure => installed
    }
}

class virtualhosts {
    require upgrade
    file {'/etc/apache2/sites-enabled/02.namevirtualhost.conf':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/virtualhost/02.namevirtualhost.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package["apache2"],
    } ~>
    file {'/etc/apache2/sites-enabled/ezp5.conf':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/virtualhost/ezp5.xdebug.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package["apache2"],
    } ~>
    exec { "remove 000-default":
        command => "/bin/rm /etc/apache2/sites-enabled/000-default",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
    }
}

class composer {
    require upgrade    
    exec { "get composer":
        command => "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin",
        path    => "/usr/local/bin:/usr/bin/",
        require => Package["apache2"],
        returns => [ 0, 1, '', ' ']
    } ~>
    exec { "link composer":
        command => "/bin/ln -s /usr/local/bin/composer.phar /usr/local/bin/composer",
        path    => "/usr/local/bin:/usr/bin/:/bin",
        returns => [ 0, 1, '', ' ']
    }
}

class prepareezpublish {
    require upgrade
    service { 'apache2':
        ensure => running,
        enable => true,
        before => Exec["prepare eZ Publish"],
        require => [File['/etc/apache2/sites-enabled/01.accept_pathinfo.conf'], File['/etc/apache2/sites-enabled/ezp5.conf']]
    } ~>
    exec { "prepare eZ Publish":
        command => "/bin/bash /tmp/vagrant-puppet/manifests/preparezpublish.sh",
        path    => "/usr/local/bin/:/bin/",
        require => Package[ "apache2", "apache2-mpm-prefork", "php5", "php5-cli", "php5-gd" ,"php5-mysql", "php-pear", "php-xml-rpc", "curl", "php5-intl", "php5-curl", "php5-xsl" ]
    } ~>
    exec { "Fix Permissions":
        command => "/bin/chown -R www-data:www-data /var/www/",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    }
}

class addhosts {
    require upgrade    
    file {'/etc/hosts':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/hosts/hosts.xdebug.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    }
}