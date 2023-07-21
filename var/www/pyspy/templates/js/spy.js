var timeout_id
const debug = false;
const div_users = document.getElementById("include_users");
const div_totals = document.getElementById("include_totals");
const div_response = document.getElementById("api_result");
const url_users = {{ url_for('webspy', route='users') | tojson }};
const url_totals = {{ url_for('webspy', route='totals') | tojson }};

function set_norefresh() {
    clearTimeout(timeout_id)
    document.getElementById('show_info').innerText = ('autorefresh: off (reload page to re-enable)');
}
function api_call(endpoint, username) {
    fetch(encodeURI(`/${endpoint}/${username}`), {
        method: "GET",
    })
    .then(response => response.json())
    .then(data => {
        let text = `${username}\n\n`;
        Object.keys(data).forEach(k => {
            if (k) {
                text += `${k}: ${data[k]}\n`
            }
        });
        div_response.innerHTML = `<pre>${text}</pre>`
    })
    div_response.style = "display:block;"
    setTimeout(() => {
        div_response.style = "display:none;"
    }, 8000);
}
let spy_params = new URLSearchParams(window.location.search);
let el = document.getElementById('sort_rev') ? document.getElementById('sort_rev') : null
let p = spy_params.get('sort_rev')
if (el && p == "") {
    el.checked = false;
} else if (el && p == "True") {
    el.checked = true;
}  
(function loop() {
    timeout_id = window.setTimeout(() => {
        let spy_params = new URLSearchParams(window.location.search);
        fetch(encodeURI(`${url_users}?${spy_params}`), {
            method: "GET",
        })
        .then(response => response.text())
        .then(text => {
            div_users.innerHTML = text  ;
        })
        fetch(encodeURI(`${url_users}?${spy_params}`), {
            method: "GET",
        })
        .then(response => response.text())
        .then(text => {
            div_users.innerHTML = text  ;
        })
        fetch(encodeURI(url_totals), {
            method: "GET",
        })
        .then(response => response.text())
        .then(text => {
            div_totals.innerHTML = text;
        })
        loop()
    }, 1000);
})()
if (debug) {
    console.log('interval_id after', interval_id)
}
const toggleSwitch = document.querySelector('.theme-switch input[type="checkbox"]');
toggleSwitch.addEventListener('change', switchTheme, false);
function switchTheme(e) {
    if (e.target.checked) {
        document.documentElement.setAttribute('data-theme', 'dark');
        localStorage.setItem('theme', 'dark');
    }
    else {
        document.documentElement.setAttribute('data-theme', 'light');
        localStorage.setItem('theme', 'light');
    }    
}
const currentTheme = localStorage.getItem('theme') ? localStorage.getItem('theme') : null;
if (currentTheme) {
    document.documentElement.setAttribute('data-theme', currentTheme);

    if (currentTheme === 'dark') {
        toggleSwitch.checked = true;
    }
}
