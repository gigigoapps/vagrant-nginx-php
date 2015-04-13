# Gigigo :: Infrastructura base para proyectos silex/symfony con nginx + mongodb

Este proyecto utiiza Vagrnat para montar y desplegar una plataforma válida para cualquier proyecto con base PHP, que incluye como servicios

* Nginx como servidor WEB
* FPM para PHP
* Memcache, utilizable como gestor de sesiones para PMP
* MongoDB o MySQL como motores de datos (opcional y configurable)

## Requisitos

Para que la plataforma funcione necesitas el siguiente software:

* Git 1.7+
* Vagrant 1.7.1+
* Virtualbox 4.3.26+

En principio es compatible con Linux (probado en Debian, Ubuntu y Arch Linux) y con MacOS X. 
No he probado la compatibilidad con Windows; para superar el problema de lentitud con carpetas compartidas de VirtualBOX y los miles de ficheros que despliega Symfony o Silex como framework base del desarrollo, he optado por utilizar enlaces simbólicos, los cuales no tienen buen comportamiento con Windows

## Configuración

Dentro de la carpeta vagrant/manifests/hieradata del proyecto tenemos tres ficheros de configuración. Estos ficheros deben revisarse antes de "levantar" el proyecto con "vagrant up"

### common.yml

Tiene dos parámetros:
* install_mongodb
* install_mysql

Pueden contener "true" o "false". Con ellos indicamos si queremos o no instalar MongoDB o MySQL en el proyecto

### environment.dev.yml y environment.staging.yml

Contienen dos variables con las que se establece el DNS del proyecto, para cada uno de los entornos de la plataforma. Sin entrar en mucho detalle, el fichero es "environment.dev.php" para nuestro entorno de desarrollo, y contienen el texto "local"; así nuestro proyecto se atenderá en el DNS "project.local" (aunque también responderá a la IP 10.12.12.2)


## Funcionamiento

Después de descargar e instalar las aplicaiones requeridas (vagrant, virtualbox, git), haremos lo siguiente

1. Descarga el proyecto en alguna carpeta de tu sistema de archivos

    $ git clone https://github.com/gigigoapps/vagrant-nginx-php.git
    Cloning into 'vagrant-nginx-php'...
    remote: Counting objects: 1227, done.
    remote: Compressing objects: 100% (873/873), done.
    remote: Total 1227 (delta 246), reused 1224 (delta 245), pack-reused 0
    Receiving objects: 100% (1227/1227), 657.89 KiB | 615.00 KiB/s, done.
    Resolving deltas: 100% (246/246), done.
    Checking connectivity... done.

2. Despliega la plataforma desde la carpeta "vagrant" del proyecto

    $ cd vagrant-nginx-php
    ~/vagrant-nginx-php/vagrant$ vagrant up
    Bringing machine 'project' up with 'virtualbox' provider...
    ==> project: Importing base box 'puppetlabs/ubuntu-14.04-64-puppet'...
    ==> project: Matching MAC address for NAT networking...
    ==> project: Checking if box 'puppetlabs/ubuntu-14.04-64-puppet' is up to date...
    
    [...]
    
    ==> project: Info: Creating state file /var/lib/puppet/state/state.yaml
    ==> project: Notice: Finished catalog run in 195.09 seconds
    ~/vagrant-nginx-php/vagrant$ 

La primera vez que se levanta la máquina virtual tarda menos de 5 minutos.

3. Acceso al sitio WEB del proyecto

Si abrimos el navegador y ponemos http://10.12.12.2 accedemos al "index.php" del proyecto. Ese "index.php" es el que está ubicado en /src/web/index.php

A partir de aquí podemos operar istalando silex o symfony como recomienda la WEB de esos frameworks, pero desde dentro de la máquina virtual

## Acceso a la máquina virtual

Desde la carpeta "vagrant" del proyecto

    ~/vagrant-nginx-php/vagrant$ vagrant ssh
    Welcome to Ubuntu 14.04.2 LTS (GNU/Linux 3.16.0-30-generic x86_64)

    * Documentation:  https://help.ubuntu.com/
    vagrant@project:~$
    vagrant@project:~$ sudo su - www-data
    www-data@project:~$ cd project/src
    www-data@project:~/project/src$ ls -l
    total 8
    lrwxr-xr-x 1 www-data www-data  13 Apr 13 12:40 var -> ../files/var/
    lrwxr-xr-x 1 www-data www-data  16 Apr 13 12:40 vendor -> ../files/vendor/
    drwxr-xr-x 1 www-data www-data 170 Apr 13 12:40 web

A partir de ese momento estaremoa ejecutando instruccione "dentro" de la máquina virtual. Si ya hemos bajado los ficheros del framework, podremos hacer "composer install" para que se instalen los "vendors" del proyecto. Este punto es importante: mientras los fuentes del proyecto se sitúan en la carpeta "/src", gracias a los enlaces simbólicos los "vendors" del proyecto se sitúan fuera de este proyecto; desde dentro de la máquina virtual están en una carpeta "local", y desde fuera de la máquina virtual (nuestra estación de trabajo) están en una carpeta "local". Por tanto, la velocidad de respuesta es anta en cualquier peticiíon.

## Tareas diarias

Se hacen desde la carpeta "vagrant" del proyecto deploy
* Arrancar máquina virtual: vagrant up
* Parar máquina virtual: vagrant halt
* Acceder a la máquina virtual: vagrant ssh

Es importante que antes de apagar nuestra estación de trabajo (nuestro PC) paremos la máqiuna virtual con el proyecto. Abrimos consola, y desde la carpeta "vagrant" del proyecto

    ~/vagrant-nginx-php/vagrant$ vagrant halt
    ==> project: Attempting graceful shutdown of VM...
    ~/vagrant-nginx-php/vagrant$

Comprobamos el estado en que se encuentra la máquina virtual

    ~/vagrant-nginx-php/vagrant$ vagrant status
    Current machine states:

    project                   poweroff (virtualbox)

    The VM is powered off. To restart the VM, simply run `vagrant up`
    ~/vagrant-nginx-php/vagrant$

## Despliegue

Podemos utilizar este mismo guión "puppet" para desplegar incluso el entorno de producción ("live")

Sólo necesitamos una máquina virtual, instancia o servidor con los paquetes "puppet" (versión 3.75 o mayor) y "git" instalados sobre un sistema base "ubuntu 14.04"

(TBD)


