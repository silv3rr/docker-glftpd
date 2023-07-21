<?php
   /*------------------------------------------------------------------------*
    *   SHIT:WEB CONFIGURATION                                               *
    *------------------------------------------------------------------------*/
    return $cfg = array(
        'mode'           => 'docker',
        'user'           => 'shit',
        'docker_api'     => "http://localhost/v1.42",
        'services'       => ['ftpd', 'sitebot'],
        'ftpd'           => array('host' => "localhost", 'port' => "1337"),
        'sitebot'        => array('host' => "localhost", 'port' => "3333"),
        'debug'          => 0,
    );
