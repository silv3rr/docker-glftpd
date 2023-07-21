function ttyModal() {   
    setTimeout(function(){
        $('#bsModalLabel').text('Terminal - by GoTTY');
        $('#bsModalFrame').attr("src", '/tty/');
    }, 2500);
    $('iframe').hide();
    $('#bsModalLabel').text('Loading...')
    $('.modal-body p').html('<div class="spinner-border text-secondary" role="status">');
    $('.modal-body p').append('&nbsp;&nbsp;Terminal is being started, please wait...<br/><br/>');
    $('#bsModal').modal('show');
    setTimeout(function(){
        $('.out').hide();
        $('.modal-body p').hide();
        $('iframe').attr('src', '/tty/');
        $('iframe').show();
    }, 2500);
    $(document).keydown(function(event) { 
        if (event.keyCode == 27) { 
            $('.modal-backdrop').hide();
            $('#bsModal').hide();
        }
    });
}