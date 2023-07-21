function gotoTop() {
    document.body.scrollTop=0;
    document.documentElement.scrollTop=0;
};

function gotoEnd() {
    var scrollingElement = (document.scrollingElement || document.body);
    scrollingElement.scrollTop = scrollingElement.scrollHeight;
};