$(document).ready(function() {
    $('.multi-collapse').collapse('show');
});

$('.multi-collapse').on('shown.bs.collapse', function (event) {
    let id = String("#" + event.target.id);
    $(id + "Right").attr("style", "display:none");
    $(id + "Up").attr("style", "display:inline-block");
});
$('.multi-collapse').on('hidden.bs.collapse', function (event) {
    let id = String("#" + event.target.id);
    $(id + "Up").attr("style", "display:none");
    $(id + "Right").attr("style", "display:inline-block");
});

$('#colShow').on('click', function() {
    $('.multi-collapse').collapse('show');
});
$('#colHide').on('click', function () {
    $('.multi-collapse').collapse('hide');
});

$(document).on('keydown', function(event) { 
    if (event.keyCode == 39) { 
        $('.multi-collapse').collapse('show');
    }
    if (event.keyCode == 37) { 
        $('.multi-collapse').collapse('hide');
    }
});