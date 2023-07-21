$('#bsModal').on('show.bs.modal', function (event) {
    let button = $(event.relatedTarget);    
    let type = button.data('type');
    let path = button.data('path');
    let view = button.data('view');
    let modal = $(this);
    // NOSONAR modal.find('.modal-body .p').hide();
    modal.find('iframe').show();
    modal.find('.modal-header').show();
    modal.find('.modal-title').show();
    // NOSONAR if (view.match(/^(?!@).*\.conf$/)) {
    if (type === 'file' && view !== undefined)  {
        modal.find('.modal-title').text(`Filemanager: view ${view}`);
        modal.find('iframe').attr("src", `/lib/tinyfilemanager/tinyfilemanager.php?p=${path}&view=${view}`);
        modal.find('iframe').attr("style", "display:block");
    } else if (type === 'dir') {
        modal.find('.modal-title').text(`Filemanager: browse ${path}`);
        modal.find('iframe').attr("src", `/lib/tinyfilemanager/tinyfilemanager.php?p=${path}`);
    } else if (type === 'html') {
        modal.find('.modal-header').hide();
        modal.find('.modal-title').hide();
        modal.find('iframe').attr("src", `${path}`);
    } else {
        modal.find('iframe').attr("src", "");
        modal.find('iframe').hide();
        modal.find('.modal-title').text('ERROR');
        // NOSONAR modal.find('.modal-body').text('Hmm.. frame not found?!');
    }
});

$('#bsModal').on('shown.bs.modal', function () {
    let modal = $(this);
    if (modal.find('.modal-title').text() === 'ERROR') {
        $('#bsModal').modal('hide');
        $('#bsModal').hide();
        $('.modal-backdrop').hide();
    } else {
        // NOSONAR $('iframe').contents().find('nav').hide();
        // NOSONAR $('#bsModal').find('iframe').css(".text-muted", "display:none");
        $('#bsModal').find('iframe').contents().find('nav').hide()
        $('#bsModal').find('iframe').contents().find('.float-right.text-muted').hide()
    }
});

$(document).keydown(function(event) { 
    if (event.keyCode == 27) { 
        $('#bsModal').modal('hide');
        $('#bsModal').hide();
        $('.modal-backdrop').hide();
        $('.out').hide();
    }
});
