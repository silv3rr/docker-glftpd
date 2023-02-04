<?php
/*                                          _
                        ____ _  ___    __ (___)______ __
-----------------------/       |   \  |   |   |         \\----------------------
          _/\          \    __ |    |_|   |   |_     ___//
         (._.)     _____\    \ |          |   | |    ||
        (_____)   ( _____\    \|    | |   |   | |    ||
       (_______)   (           \    | |   |   | |    ||
--------------------\_____ _ ___)___) |_ _)___) |__ _))-------------------------
              SHIT:WEB webinterface -- "Don't worry, be crappy"
  --------------------------------------------------------------------------- */

ini_set('display_startup_errors', 1);
ini_set('display_errors', 1);
error_reporting(-1);

if (!file_exists("config.php")) {
    header("Location: " . "error.html");
}

require_once('config.php');

if (!isset($cfg['mode'])) {
    $cfg['mode'] = "normal";
}

if ($cfg['debug']) {
    print('<span style="color:blue"><small>DEBUG: ' . $cfg['debug'] . ' mode=');
    print('<b>' . $cfg['mode'] . '</b>(' . __FILE__ . ')</small></span><br>' . PHP_EOL);
}

if ($cfg['debug'] > 1) {
    print("DEBUG: print_r \$_POST : ");
    print_r($_POST);
    print("<br>" . PHP_EOL);
}

if (!isset($_SESSION)) {
    session_start();
}

// include array with cmds for 'mode' (docker or systemd)
if ($cfg['mode'] == "normal") {
    // systemd: concat strings for common cmds
    $sudo_systemd = 'XDG_RUNTIME_DIR=/run/user/' . '$(id -u ' . $cfg['user'] . ')' .
                    "/usr/bin/sudo -u" . " " . $cfg['user'] . " " . '/bin/systemctl --user' . " ";
    $pgrep_userid = '/usr/bin/pgrep -a -u' . " " . $cfg['user'] . " ";
    $pkill_userid = '/usr/bin/sudo -u' . " " . $cfg['user'] . " " . '/usr/bin/pkill -9' . " ";
    // systemd: terminal multiplexer
    if ($cfg['term_mp'] == 'screen') {
        $gotty_mp = '/shit/cbftp/gotty /usr/bin/screen -RR -S cbftp >/dev/null 2>&1 &';
        $match_mp = '-f [sS][cC][rR][eE][eE][nN].*cbftp';
    } elseif ($cfg['term_mp'] == 'dtach') {
        $gotty_mp  = '/shit/cbftp/gotty --config /shit/cbftp/.gotty /usr/bin/dtach -a /tmp/cbftp.sock >/dev/null 2>&1 &';  //NOSONAR
        $match_mp = '-f dtach.*cbftp';
    }
    require_once('systemd.php');
}
if ($cfg['mode'] == "docker") {
    require_once('docker.php');
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $_SESSION['postData'] = array_map('htmlspecialchars', $_POST);
    $_SESSION['postData'] = array_map('trim', $_POST);
    if (array_sum(array_map('is_string', $_SESSION['postData'])) == count($_SESSION['postData'])) {
        unset($_POST);
        header("Location: " . $_SERVER['PHP_SELF']);
        exit();
    } else {
        unset($_SESSION['postData']);
    }
}

if (($cfg['debug'] > 1) && (isset($_SESSION['postData']))) {
    print("DEBUG: print_r postData :" . PHP_EOL);
    print_r($_SESSION['postData']);
    print("<br>" . PHP_EOL);
}

function test_ftp($host, $port) {
    if (@ftp_connect($host, $port, 3)) {
        return 0;
    }
    return 1;
}
function test_port($host, $port) {
    if (@fsockopen($host, $port, $errno, $errstr, 3)) {
        return 0;
    }
    return 1;
}

// call docker api with curl using socket
function docker_api($method, $endpoint, $postfields=null) {
    global $cfg;
    $url = $cfg['docker_api'] . $endpoint;
    if ($cfg['debug'] > 2) {
        print("DEBUG: docker_api \$url=" . $url  . " \$postfields=" . $postfields . "<br>" . PHP_EOL);
    }
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_UNIX_SOCKET_PATH, "/var/run/docker.sock");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_VERBOSE, true);
    if ($cfg['debug'] > 2) {
        $fp = fopen('/tmp/curl_err.log', 'a+');
        curl_setopt($ch, CURLOPT_STDERR, $fp);
    }
    if ($method == "POST") {
        curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
        curl_setopt($ch, CURLOPT_POST, 1);
        if (!is_null($postfields)) {
            if ($cfg['debug'] > 2) {
                print("DEBUG: docker_api \$postfields=" . $postfields . "<br>" . PHP_EOL);
            }
            curl_setopt($ch, CURLOPT_POSTFIELDS, $postfields);
        } else {
            unset($postfields);
        }
    }
    $data = curl_exec($ch);
    curl_close($ch);
    return $data;
}

// docker api examples/tests: TOP|EXEC|ATTACH|INSPECT_ALL
$_DOCKER_TEST = "";
if (!empty($_DOCKER_TEST)) {
    print("TEST: $_DOCKER_TEST<br>" . PHP_EOL);
    switch ($_DOCKER_TEST) {
        case "TOP":
            $top = docker_api("GET", "/containers/glftpd/top", null);
            foreach ($top as $key => $value) {
                print($key . " " . $value . PHP_EOL);
            }
            foreach ($top->Processes as $em) {
                print("TEST: " . implode($em, ' ') . PHP_EOL);
            }
            break;
        case "EXEC":
            // "AttachStderr": true,  "Privileged": true
            $exec = docker_api(
                "POST",
                "/containers/glftpd/exec",
                '{"AttachStdout": true, "Tty": false, "Cmd": ["tail", "/glftpd.log"]}'
            );
            docker_api("POST", "/exec/" . $exec->Id . "/start", '{ "Detach": false, "Tty": false },');
            $json = (docker_api("GET", "/exec/" . $exec->Id . "/json", null));
            break;
        case "ATTACH":
            $ws=true;
            var_dump(docker_api("POST", "/containers/glftpd/start", ""));
            if ($ws) {
                // use websockets
                $exec = docker_api("POST", "/containers/glftpd/attachws?stream=1&stdout=1&stderr=1", null);
            } else {
                // without ws
                $exec = docker_api("POST", "/containers/glftpd/attach?stream=1&stdout=1&stderr=1", null);
            }
            break;
        case "INSPECT_ALL":
            global $cfg;
            $json = (docker_api("GET", "/containers/json", null));
            print_r('<pre class="out">TEST: print_r \$json :<br>' . PHP_EOL);
            print_r($json);
            print("<br>" . PHP_EOL);
            $json = json_decode($json. true);
            if (json_last_error() === 0) {
                foreach ($json as $em) {
                    print("TEST: name=" .  $em->Names[0] . " id=" . $em->Id . PHP_EOL);
                    print("TEST: top" . PHP_EOL);
                    //NOSONAR  foreach ($top->Processes as $line) { print("INFO: " . implode($line, ' ') . PHP_EOL); }
                    $top = docker_api("GET", "/containers/" . $em->Id . "/top", null);
                    print_r($top);
                    print("TEST: print_r logs :<br>" . PHP_EOL);
                    $logs = docker_api("GET", "/containers/" .  $em->Id .   "/logs" . "?stdout=true&stderr=true", null);
                    print_r($logs);
                    print(PHP_EOL);
                }
            }
            exit();
        default:
            print_r('<pre class="out">TEST: missing<br>' . PHP_EOL);
            exit();
    }
}

// create and start exec instance (same as 'docker exec' via cli)
function docker_exec($id, $cmd) {
    global $cfg;
    if ($cfg['debug'] > 2) {
        print("DEBUG: docker_exec \$id=" . $id . " \$cmd=" . $cmd . "<br>" . PHP_EOL);
    }
    $exec = docker_api(
        "POST",
        "/containers/$id/exec",
        '{"AttachStdout": true,
        "AttachStdout": true,
        "Tty": false, "Cmd": ' . $cmd . '}'
    );
    if (preg_match('/No such container/', $exec)) {
        return 1;
    }
    $json = json_decode($exec);
    if ((json_last_error() === 0) && (isset($json->Id))) {
        $start = docker_api("POST", "/exec/" . $json->Id . "/start", '{ "Detach": false, "Tty": false }');
        $json = json_decode($start);
        if (json_last_error() === 0) {
            return $json;
        } else {
            return $start;
        }
    }
}

function docker_fmt_result($json) {
    if ((isset($json[0]['State'])) && (isset($json[0]['Status']))) {
        return print("<br>State: <strong>" . $json[0]['State'] .
                     "</strong>, Status: " . $json[0]['Status'] . "<br>" . PHP_EOL);
    }
    if (isset($json['Processes'])) {
        $_out = "<br>Processes:<br>" . PHP_EOL;
        $_out .= isset($json['Titles']) ? json_encode($json['Titles']) . PHP_EOL : "";
        foreach ($json['Processes'] as $p) {
            $_out .= json_encode($p) . PHP_EOL;
        }
        return print(preg_replace('/[]["]/', '', str_replace(',', ' ', stripslashes($_out))) . PHP_EOL);
    }
    try {
        $_out = "";
        foreach ($json as $em) {
            if (is_array($em)) {
                foreach (array_keys($em) as $k) {
                    $_out .= (string)$k . ": ";
                    if (is_array($em[$k])) {
                        if (isset($em[$k][1])) {
                            for ($i = 0; $i < count($em[$k]); $i++) {
                                $_out .=  PHP_EOL . "  - " . json_encode($em[$k][$i]);
                            }
                        } else {
                            $_out .= json_encode($em[$k]);
                        }
                    } else {
                        $_out .= $em[$k];
                    }
                    $_out .= PHP_EOL;
                }
                $_out .= PHP_EOL;
            } else {
                $_out .= $em;
            }
        }
        return print(stripslashes($_out) . "<br>" . PHP_EOL);
    } catch (Exception $e) {
        print(json_encode($json, JSON_PRETTY_PRINT));
    }
}

// run cmds using docker api (msg=0:status, msg=1:logs, msg=2:exec)
function docker_run($msg, $cmds, $act) {
    global $cfg;
    if (($msg < 0) || (!isset($cmds[$act])) || (empty($cmds[$act]))) {
        return 1;
    }
    if ($cfg['debug'] > 2) {
        print("DEBUG: docker_run \$msg=" . $msg . " print_r \$cmds[\$act]=" . PHP_EOL);
        print_r($cmds[$act]);
        print("<br>" . PHP_EOL);
    }
    // glftpd xl-ipchanger
    if (preg_match('/ip_(list|adds|add|del)/', $act)) {
       $msg = 2;
       $_tmp = explode(" ", $cmds[$act]);
       $cmds[$act] = '["' . implode('","', $_tmp) . '"]';
       $cmds[$act] = explode(" ", "docker_exec glftpd $cmds[$act]");
    }
    // hide gl passwd
    if ((isset($_SESSION['postData']['ip_pass'])) && (!empty($_SESSION['postData']['ip_pass']))) {
        $cmds[$act] = preg_replace('/' . $_SESSION['postData']['ip_pass'] . '/', "*****", $cmds[$act]);
    }
    $result = call_user_func_array(array_shift($cmds[$act]), $cmds["$act"]);
    if ($cfg['debug'] > 2) {
        print("DEBUG: docker_run \$result=" . $result . "<br>" . PHP_EOL);
    }
    // handle pid status
    if (($msg === 0) && (preg_match('/^(bot_pid|sitebot_pid|[a-z]+_gotty_pid)$/', $act))) {
        if (
                (!is_null($result)) &&
                (!empty($result)) &&
                (is_string($result) && (!preg_match('/is not running/', $result))) &&
                ($result !== 1)
        ) {
            return 0;
        }
        return 1;
    // output api calls result
    } else {
        $json = json_decode($result, true);
        if (json_last_error() === 0) {
            docker_fmt_result($json);
        } else {
            // output json error
            print_r($result);
        }
    }
}

// run local cmds (msg=0:status, msg=1:logs, msg=2:exec)
function local_run($msg, $cmds, $act) {  //NOSONAR
    global $cfg;
    if (($msg < 0) || (!isset($cmds[$act])) || (empty($cmds[$act]))) {
        if ($msg) {
            print('ERROR: invalid command' . PHP_EOL);
        }
        return 1;
    }
    exec($cmds[$act], $output, $rc);
    // debug: $output = shell_exec($cmds[$act]); $rc = 0;
    if ((isset($_SESSION['postData']['ip_pass'])) && (!empty($_SESSION['postData']['ip_pass']))) {
        $cmds[$act] = preg_replace('/' . $_SESSION['postData']['ip_pass'] . '/', "*****", $cmds[$act]);
    }
    if ($msg >= 2) {
        print('INFO: running "' . $cmds[$act] . '"' . PHP_EOL);
        if (!$rc) {
            print('INFO: cmd executed successfully' . PHP_EOL);
        } else {
            print('WARN: empty output or error' . PHP_EOL);
        }
    }
    if (($msg >= 1) && ($output)) {
        $prefix = 1;
        if ($cfg['debug'] > 2) {
            var_dump($output);
        }
        if ((preg_match('/_(log|status|tail)/', $act)) || (preg_grep('/(Warning:|ERROR:)/i', $output))) {
            $prefix = 0;
        }
        foreach ($output as $line) {
            print((($prefix == 1) ? "$line" : $line) . PHP_EOL);
        }
    }
    return $rc;
}

// run 'wrapper'
function run() {
    global $cfg;
    $rc = -1;
    $args = func_get_args();
    switch ($args[2]) {
        case "ftpd":
            $rc = test_ftp($cfg['ftpd']['host'], $cfg['ftpd']['port']);
            break;
        case "irc":
            $rc = test_port($cfg['irc']['host'], $cfg['irc']['port']);
            break;
        case "sitebot":
            // XXX: (TEMP) instead of test_port() check for sitebot on 127.0.0.1:3333 in glftpd container
            if ($cfg['mode'] == "docker") {
                $exec = json_decode(
                    docker_api(
                        "POST",
                        "/containers/glftpd/exec",
                        '{"AttachStdout": true, "Tty": false, "Cmd": ["echo", "|", "telnet", "localhost", "3333"]}'
                    )
                );
                if (isset($exec->Id)) {
                    docker_api("POST", "/exec/" . $exec->Id . "/start", '{ "Detach": false, "Tty": false },');
                    $json = (docker_api("GET", "/exec/" . $exec->Id . "/json", null));
                    if (isset(json_decode($json)->ExitCode) && (json_decode($json)->ExitCode === 0)) {
                        $rc = 0;
                        break;
                    }
                }
                $rc = 1;
            }
            break;
        default:
            if ($cfg['mode'] == "docker") {
                $rc = call_user_func_array('docker_run', $args);
            } else {
                $rc = call_user_func_array('local_run', $args);
            }
        }
    return $rc;
}

// TEST: run cmds
$_RUN_TEST=false;
if ($_RUN_TEST) {
    print("TEST: run cmds<br>" . PHP_EOL);
    run(0, $cmds, "bot_status");
    run(false, $cmds, "test");
    run(true, $cmds, "bot_tail");
    run(true, $cmds, "glftpd_tail");
    print('</pre>' . PHP_EOL);
    return;
}

// show top status bar
function status($cmds) {
    global $cfg;
    foreach ($cfg['services'] as $act) {
        if (run(0, $cmds, $act) === 0) {
            print('  <div id="up">' . str_replace('_pid', '', $act) . ':<b>UP</b></div>' . PHP_EOL);
        } else {
            print('  <div id="down">' . str_replace('_pid', '', $act) . ':<b>DOWN</b></div>' . PHP_EOL);
        }
    }
    foreach ($cmds as $key => $value) {
        if ((preg_match("/[a-z]_gotty_pid$/", $key)) && (run(0, $cmds, $key) === 0)) {
            // && (in_array($key, $cfg['services']))) {
            print('  <div id="running">' . str_replace('_pid', '', $key) . ':<b>RUNNING</b></div>' . PHP_EOL);
        }
    }
    print('  <hr class="vsep"><div id="refresh"><a href="' . $_SERVER['PHP_SELF'] . '">');
    print('<i class="fas fa-sync"></i>REFRESH</a></div>' . PHP_EOL);
    return false;
}

// show gotty link (unused)
function tty_link($cmds) {
  if ((isset($_SESSION['postData']['cbCmd'])) &&
      (!empty($_SESSION['postData']['cbCmd'])) ||
      ($_SESSION['postData']['cbCmd'] == 'cbftp_view')) {
    run(0, $cmds, 'view_cbftp');
    unset($_SESSION['postData']['cbCmd']);
    //NOSONAR (OLD) link:   print('<div class="cbview">Open Cbftp window: <a href="/tty"><button>GoTTY Terminal</a></button></div>' . PHP_EOL);
    //NOSONAR (OLD) iframe: print('<a href="/tty" _target="iFrame"><button>GoTTY Terminal</a></button>'); */
    //header("Location: " . $_SERVER['PHP_SELF']);
    print('<div class="cbview">Open cbftp window: ' . PHP_EOL);
    print('<button name="cbCmd" type="button" data-toggle="modal" data-target="#bsModal" data-frame="@gotty">' . PHP_EOL);
    print('GoTTY Terminal</button></div>' . PHP_EOL);
  }
}

function btn_bot_invite($nick) {
    $sockfile = '/tmp/shitbot.sock' ;
    @$sock = stream_socket_client('unix://' . $sockfile, $errno, $errstr);
    if ($sock) {
        fwrite($sock, 'INVITE ' . $nick);
        //NOSONAR echo fread($sock, 4096)."\n";
        fclose($sock);
    }
}

// handle form post submit buttons

/*
   TODO: $btn_name can get multiple names from the regex ( e.g. botCmdglCmd )
         inputs are always added to $_SESSION['postData'] array?
         see tmpl_idx:
            <h6>Invite:</h6>
            <input name="botCmd"
*/

/*
    print("DEBUG: preggrep: ");
    print_r(preg_grep('/^(bot|cb|gl|ip)Cmd$/', array_keys($_SESSION['postData'])));
    print(implode(preg_grep('/(^(bot|cb|gl|ip)Cmd)/', array_keys($_SESSION['postData']))) ?? null);
    $btn_name = implode(preg_grep('/(^(bot|cb|gl|ip)Cmd)/', array_keys($_SESSION['postData']))) ?? null;
    $btn_value = $_SESSION['postData'][$btn_name] ?? null;
    print('    -- >> btn_name:' . $btn_name);
    print('    -- >> btn_value:' . $btn_value . '<br>');
*/

if ((isset($_SESSION['postData'])) && (!empty(preg_grep('/^(bot|cb|gl|ip)Cmd$/', array_keys($_SESSION['postData']))))) {
    // first match '<button name="...">', instead getting 'value' directly
    $btn_name = implode(preg_grep('/^(bot|cb|gl|ip)Cmd$/', array_keys($_SESSION['postData']))) ?? null;
    $btn_value = $_SESSION['postData'][$btn_name] ?? null;
    $html_close = '</pre></body></html>' . PHP_EOL;
    if (preg_match('/^[a-z]+_log$/', $btn_value)) {
        // print("DEBUG: preg_match");
        unset($_SESSION['postData'][$btn_name]);
        include_once('tmpl_log.html');
        run(1, $cmds, $btn_value);
        print($html_close);
        exit();
    } else {
        include_once('tmpl_idx.html');
    }
    if (preg_match('/^[a-z]+_kill$/', $btn_value)) {
        run(0, $cmds, $btn_value);
        unset($_SESSION['postData'][$btn_name]);
        print($html_close);
        exit();
    }
    if (($btn_name === 'botCmd' && $btn_value === 'bot_invite') &&
        (!empty($_SESSION['postData']['irc_nick']))) {
        echo "INVITE ". $_SESSION['postData']['irc_nick'];
        btn_bot_invite($_SESSION['postData']['irc_nick']);
        unset($_SESSION['postData']['irc_nick']);
        print($html_close);
        exit();
    }
    if (($btn_name === 'ipCmd') && (!empty($_SESSION['postData']['ipCmd']))) {
        foreach (['ip_user', 'ip_pass', 'ip_addr'] as $input_name) {
            if (!empty($_SESSION['postData'][$input_name])) {
                $cmds[$btn_value] .= ' ' . $_SESSION['postData'][$input_name];
                unset($_SESSION['postData'][$input_name]);
            }
        }
    }
    if (preg_match('/^[a-z]+_view$/', $btn_value)) {
        print('<script type="text/javascript">ttyModal();</script>' . PHP_EOL);
        print('<pre class="out" id="wait" style="color: red;">' . '>> LOADING, PLEASE WAIT..' . PHP_EOL);
    } else {
        print('<h6 class="out">Output:</h6>' . PHP_EOL);
        print('<pre class="out">');
    }
    run(2, $cmds, $btn_value);
    unset($_SESSION['postData'][$btn_name]);
}

include_once('tmpl_idx.html');

$botpath = ($cfg['mode'] == "normal") ? "bot" : "/";
$webpath = ($cfg['mode'] == "normal") ? "web" : "/";
echo <<<_EOF_
</pre>
<script type="text/javascript">var botpath="${botpath}"; var webpath="${webpath}";</script>
<script type="text/javascript" src="js/modal_fm.js"></script>
<script type="text/javascript" src="js/col_btn.js"></script>
</body>
</html>
_EOF_;
