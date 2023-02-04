$('#bsModal').on('show.bs.modal', function (event) {
    let button = $(event.relatedTarget);    
    let showframe = button.data('showframe');
    let modal = $(this);
    modal.find('.modal-body .p').hide();
    if(showframe.match(/^(?!@)(config\..*|.*\.conf)$/)) {
        modal.find('.modal-title').text(`View ${showframe}`);
        modal.find('iframe').attr("src", `/tinyfilemanager/tinyfilemanager.php?p=${webpath}&view=${showframe}`);
    }
    else if (showframe === '@glsite') {
        modal.find('.modal-title').text('Browsr Glftpd Site');
        modal.find('iframe').attr("src", `/tinyfilemanager/tinyfilemanager.php?p=${webpath}/site`);
    }
    else if (showframe === '@filemanager') {
        modal.find('.modal-title').hide();
        modal.find('iframe').attr("src", "/tinyfilemanager/tinyfilemanager.php");
    } else {
        modal.find('iframe').attr("src", "");
        modal.find('iframe').attr("style", "display:none");
        modal.find('.modal-title').text('ERROR');
        modal.find('.modal-body').text('Hmm.. frame not found?!');
    }
});

$('#bsModal').on('shown.bs.modal', function () {
    let modal = $(this);
    if (modal.find('.modal-title').text() === 'ERROR') {
        $('#bsModal').modal('hide');
        $('.modal-backdrop').hide();
    }
});

$(document).keydown(function(event) { 
    if (event.keyCode == 27) { 
        $('.modal-backdrop').hide();
        $('#bsModal').hide();
        $('.out').hide();
    }
});
