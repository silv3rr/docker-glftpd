<?php
   /*------------------------------------------------------------------------*
    *   SHIT:WEB CONFIGURATION                                               *
    *------------------------------------------------------------------------*/
    return $cfg = array(
        'mode'           => 'docker',
        'user'           => 'shit',
        'term_mp'        => 'dtach',
        'bot_log'        => '/shit/bot/bot.log',
        'xl_ip'          => '/shit/bot/xl-ipchanger.sh',
        'docker_api'     => "http://localhost/v1.40",
        'services'       => ['ftpd', 'sitebot'],
        'ftpd'           => array('host' => "glftpd", 'port' => "1337"),
        'sitebot'        => array('host' => "glftpd", 'port' => "3333"),
        'debug'          => 0,
    );
