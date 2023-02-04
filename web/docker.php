<?php
/*--------------------------------------------------------------------------*
 *   SHIT:WEB commands for docker mode
 *--------------------------------------------------------------------------*/
$cmds = array(
    'glftpd_status'   => array("docker_api", "GET", "/containers/json?filters=" . urlencode("{\"name\": [\"glftpd\"]}")),
    'glftpd_start'    => array("docker_api", "POST", "/containers/glftpd/start", ''),
    'glftpd_stop'     => array("docker_api", "POST", "/containers/glftpd/stop", null),
    'glftpd_restart'  => array("docker_api", "POST", "/containers/glftpd/restart", null),
    'glftpd_kill'     => array("docker_api", "POST", "/containers/glftpd/kill", null),
    'glftpd_pid'      => array("docker_api", "GET", "/containers/glftpd/top", null),
    'glftpd_log'      => array("docker_api", "GET", "/containers/glftpd/logs?stdout=true&stderr=true", null),
    'glftpd_tail'     => array("docker_api", "GET", "/containers/glftpd/logs?stdout=true&stderr=true&tail=10", null),
    'glftpd_inspect'  => array("docker_api", "GET", "/containers/glftpd/json", null),
    'glftpd_ports'    => array("docker_api", "GET", "/containers/glftpd/ports", null),
    'glspy_view'      => array("docker_exec", "glftpd", '["sh", "-c", "busybox killall -9 gotty; gotty /glftpd/bin/gl_spy -r/glftpd/glftpd.conf >/dev/null 2>&1 &"]'),
    'useredit_view'   => array("docker_exec", "glftpd", '["sh", "-c", "busybox killall -9 gotty; gotty /glftpd/bin/useredit -r/glftpd/glftpd.conf >/dev/null 2>&1 &"]'),
    'eggdrop_view'    => array("docker_exec", "glftpd", '["sh", "-c", "busybox killall -9 gotty; gotty busybox telnet localhost 3333 >/dev/null 2>&1 &"]'),
    'pywho_view'      => array("docker_exec", "glftpd", '["sh", "-c", "busybox killall -9 gotty; gotty /glftpd/bin/pywho --spy >/dev/null 2>&1 &"]'),
    'gl_gotty_kill'   => array("docker_exec", "glftpd", '["busybox", "killall", "-9", "gotty"]'),
    'gl_gotty_pid'    => array("docker_exec", "glftpd",'["sh", "-c", "busybox ps aux|grep \"[gG]otty\""]'),
    'glspy_kill'      => array("docker_exec", "glftpd", '["busybox", "killall", "-9", "gl_spy"]'),
    'useredit_kill'   => array("docker_exec", "glftpd", '["busybox", "killall", "-9", "useredit"]'),
    //'gl_gotty_pid'    => array("docker_exec", "glftpd", '["sh", "-c", "grep -ar [gG]otty /proc/[0-9]*/cmdline"]'),
    //'ip_add'          => "/glftpd/bin/xl-ipchanger.sh ADDIP",
    //'ip_del'          => "/glftpd/bin/xl-ipchanger.sh DELIP",
    //'ip_list'         => "/glftpd/bin/xl-ipchanger.sh LISTIP",
    //'ip_adds'         => "/glftpd/bin/xl-ipchanger.sh IPADDS",
);
