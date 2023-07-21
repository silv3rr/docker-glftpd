// refreshes whole page
const url = "/spy"
const div = document.getElementById("refresh")
console.log(url, div)
fetch(url)
    .then(response => response.text)
    .then(text => div.innerHtml = text)
setTimeout(function() {
    window.location.reload();
}, 1000);
