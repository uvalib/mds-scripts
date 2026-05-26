$(document).ready(function () {
    $('.marc-toggle').click(function () {
        id = $(this).attr('id').split('-')[0];
        
        container = '#' + id + '-container';
        
        $(container).toggle();
        
        if ($(container).children('code').text().length == 0) {
            $(container).children('code').text('Loading...');
            url = $(container).attr('path');
            $. get (url, function (data) {
                $(container).children('code').html(data);
            });
        }
    });
})