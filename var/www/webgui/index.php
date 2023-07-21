<?php

// SHIT:WEB webinterface -- "Don't worry, be crappy"

if (!file_exists("config.php")) {
    header("Location: " . "error_4xx.html");
}
require_once('config.php');  //NOSONAR

if ($cfg['debug'] > 0) {
    ini_set('display_startup_errors', 1);
    ini_set('display_errors', 1);
    error_reporting(-1);
}

if (!isset($cfg['mode'])) {
    //NOSONAR $cfg['mode'] = "normal";
    $cfg['mode'] = "docker";
}

if ($cfg['debug']) {
    print('<span style="color:blue"><small>DEBUG: ' . $cfg['debug'] . ' mode=');
    print('<b>' . $cfg['mode'] . '</b>(' . __FILE__ . ')</small></span><br>' . PHP_EOL);
}

if ($cfg['debug'] > 1) {
    print("DEBUG: print_r \$_POST : " . print_r($_POST, true) . "<br>" . PHP_EOL);
}

if (!isset($_SESSION)) {
    session_start();
}

// include array with cmds for 'mode' (docker or systemd)
// unused systemd code removed
if ($cfg['mode'] == "docker") {
    require_once('docker.php');  //NOSONAR
}

// store all $_POST values as $_SESSION['postData']['var']
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
    

if (($cfg['debug'] > 1) && (isset($_SESSION['postData']))) {
    print("DEBUG: print_r postData :" . print_r($_SESSION['postData'], true) . "<br>" . PHP_EOL);
}

// check host:port funcs, incl. in container
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

function test_port_docker($host, $port) {
    $exec = json_decode(
        docker_api(
            "POST",
            "/containers/glftpd/exec",
            '{
                "AttachStdout": true, "Tty": false, "Cmd": [
                    "echo", "|", "/bin/busybox", "telnet", "'. $host . '", "' . $port . '"
                ]
            }'
        )
    );
    if (isset($exec->Id)) {
        docker_api("POST", "/exec/" . $exec->Id . "/start", '{ "Detach": false, "Tty": false }');
        $json = (docker_api("GET", "/exec/" . $exec->Id . "/json", null));
        if (isset(json_decode($json)->ExitCode) && (json_decode($json)->ExitCode === 0)) {
            return 0;
        }
    }
    return 1;
}

// call docker api with curl, uses unix socket
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

// create and start exec instance (same as 'docker exec' via cli)
function docker_exec($id, $cmd) {
    global $cfg;
    if ($cfg['debug'] > 2) {
        print("DEBUG: docker_exec \$id=" . $id . " \$cmd=" . $cmd . "<br>" . PHP_EOL);
    }
    $exec = docker_api(
        "POST",
        "/containers/$id/exec",
        '{
            "AttachStdout": true,
            "AttachStdout": true,
            "Tty": false,
            "Cmd": ' . $cmd . '
        }'
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

// run cmds using docker api (type=0:status, type=1:logs, type=2:exec)
function docker_run($type, $cmds, $action) {
    global $cfg;
    if (($type < 0) || (!isset($cmds[$action])) || (empty($cmds[$action]))) {
        return 1;
    }
    if ($cfg['debug'] > 2) {
        print("DEBUG: docker_run \$type=" . $type . " print_r \$cmds[\$action]=<br>" . PHP_EOL);
        print_r($cmds[$action]);
    }
    // glftpd xl-ipchanger
    if (preg_match('/ip_(list|adds|add|del)/', $action)) {
       $type = 2;
       $_tmp = explode(" ", $cmds[$action]);
       $cmds[$action] = '["' . implode('","', $_tmp) . '"]';
       $cmds[$action] = explode(" ", "docker_exec glftpd $cmds[$action]");
    }
    // hide gl passwd
    if ((isset($_SESSION['postData']['ip_pass'])) && (!empty($_SESSION['postData']['ip_pass']))) {
        $cmds[$action] = preg_replace('/' . $_SESSION['postData']['ip_pass'] . '/', "*****", $cmds[$action]);
    }
    $result = call_user_func_array(array_shift($cmds[$action]), $cmds["$action"]);
    if ($cfg['debug'] > 2) {
        print("DEBUG: docker_run \$result=" . $result . "<br>" . PHP_EOL);
    }
    // handle pid status
    if (($type === 0) && (preg_match('/^(bot|sitebot|[a-z_]+_gotty)_pid$/', $action))) {
        if ( (!is_null($result)) &&
             (!empty($result)) &&
             (is_string($result) && (!preg_match('/is not running/', $result))) &&
             ($result !== 1) ) {
            return 0;
        }
        return 1;
    // output result from api call
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

// run local cmds (type=0:status, type=1:logs, type=2:exec)
function local_run($type, $cmds, $action) {  //NOSONAR
    global $cfg;
    if (($type < 0) || (!isset($cmds[$action])) || (empty($cmds[$action]))) {
        if ($type) {
            print('ERROR: invalid command' . PHP_EOL);
        }
        return 1;
    }
    exec($cmds[$action], $output, $rc);
    // debug: $output = shell_exec($cmds[$action]); $rc = 0;
    if ((isset($_SESSION['postData']['ip_pass'])) && (!empty($_SESSION['postData']['ip_pass']))) {
        $cmds[$action] = preg_replace('/' . $_SESSION['postData']['ip_pass'] . '/', "*****", $cmds[$action]);
    }
    if ($type >= 2) {
        print('INFO: running "' . $cmds[$action] . '"' . PHP_EOL);
        if (!$rc) {
            print('INFO: cmd executed successfully' . PHP_EOL);
        } else {
            print('WARN: empty output or error' . PHP_EOL);
        }
    }
    if (($type >= 1) && ($output)) {
        $prefix = 1;
        if ($cfg['debug'] > 2) {
            var_dump($output);
        }
        if ((preg_match('/_(log|status|tail)/', $action)) || (preg_grep('/(Warning:|ERROR:)/i', $output))) {
            $prefix = 0;
        }
        foreach ($output as $line) {
            print((($prefix == 1) ? "$line" : $line) . PHP_EOL);
        }
    }
    return $rc;
}

// run 'wrapper' local/docker
function run() {
    global $cfg;
    $rc = -1;
    $args = func_get_args();
    if ($cfg['mode'] == "normal") {
        switch ($args[2]) {
            case "ftpd":
                $rc = test_ftp($cfg['ftpd']['host'], $cfg['ftpd']['port']);
                break;
            case "irc":
                $rc = test_port($cfg['irc']['host'], $cfg['irc']['port']);
                break;
            case "sitebot":
                $rc = test_port($cfg['sitebot']['host'], $cfg['sitebot']['port']);
                break;
            default:
                $rc = call_user_func_array('local_run', $args);
        }
    } elseif ($cfg['mode'] == "docker") {
        switch ($args[2]) {
            case "ftpd":
                $rc = test_port_docker($cfg['ftpd']['host'], $cfg['ftpd']['port']);
                break;
            case "irc":
                $rc = test_port_docker($cfg['irc']['host'], $cfg['irc']['port']);
                break;
            case "sitebot":
                $rc = test_port_docker($cfg['sitebot']['host'], $cfg['sitebot']['port']);
                break;
            default:
                $rc = call_user_func_array('docker_run', $args);
        }
    }
    return $rc;
}

// TEST: run cmds
$_RUN_TEST=false;
if ($_RUN_TEST) {
    print("<pre>TEST: run cmds<br>" . PHP_EOL);
    //run(0, "lftp --help", test);
    run(0, $cmds, "bot_status");
    run(false, $cmds, "test");
    run(true, $cmds, "bot_tail");
    run(true, $cmds, "glftpd_tail");
    print('</pre>' . PHP_EOL);
    return;
}

// show top status bar
function status_bar($cmds) {
    global $cfg;
    foreach ($cfg['services'] as $action) {
        if (run(0, $cmds, $action) === 0) {
            print('  <div id="up">' . str_replace('_pid', '', $action) . ':<b>UP</b></div>' . PHP_EOL);
        } else {
            print('  <div id="down">' . str_replace('_pid', '', $action) . ':<b>DOWN</b></div>' . PHP_EOL);
        }
    }
    foreach (preg_grep("/[a-z]_gotty_pid$/", array_keys($cmds)) as $key => $value) {
        // && (in_array($key, $cfg['services']))) {
        if (run(0, $cmds, $key) === 0) {
            print('  <div id="running">' . str_replace('_pid', '', $key) . ':<b>RUNNING</b></div>' . PHP_EOL);
        }
    }
    return false;
}

// handle form submits and include templates
// 1) match button name $btn_name:  <button name="NAME"
// 2) get button's value $btn_value: <button name="foo" value="VALUE">

#print('</pre>');
if (isset($_SESSION['postData'])) {
    foreach (preg_grep('/^(bot|cb|gl|ip)Cmd$/', array_keys($_SESSION['postData'])) as $idx => $key) {
        $btn_name = $key ?? null;
        $btn_value = $_SESSION['postData'][$btn_name] ?? null;
        $html_close = '</pre>' . PHP_EOL . '</body>' . PHP_EOL . '</html>' . PHP_EOL;
        if (preg_match('/^[a-z]+_log$/', $btn_value)) {
            unset($_SESSION['postData'][$btn_name]);
            include_once('templates/logs.html');  //NOSONAR
            run(1, $cmds, $btn_value);
            print($html_close);
            exit();
        } else {
            include_once('templates/main.html');  //NOSONAR
            echo <<<_EOF_
            <script type="text/javascript">
                $('html, body').animate({scrollTop: $('.bottom').offset().top}, 1100);
            </script>
            _EOF_;
        }
        if (preg_match('/^[a-z]+_kill$/', $btn_value)) {
            run(0, $cmds, $btn_value);
            unset($_SESSION['postData'][$btn_name]);
            print($html_close);
            exit();
        }
        if ( ($btn_name === 'botCmd' && $btn_value === 'bot_invite') &&
            (!empty($_SESSION['postData']['irc_nick']))) {
            echo "INVITE ". $_SESSION['postData']['irc_nick'];
            btn_bot_invite($_SESSION['postData']['irc_nick']);
            unset($_SESSION['postData']['irc_nick']);
            print($html_close);
            exit();
        }
        if (($btn_name === 'ipCmd') && (!empty($btn_value))) {
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
}

include_once('templates/main.html');  //NOSONAR

echo <<<_EOF_
</pre>
<script type="text/javascript" src="js/modal.js"></script>
<script type="text/javascript" src="js/col_btn.js"></script>
<script type="text/javascript" src="/spy.js"></script>  
</body>
</html>
_EOF_;
