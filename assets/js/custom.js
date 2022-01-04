(function($){
    $(function(){
        $.initialize('.chOOHy img', function () {
            var $el = $(this);
            var $anch = $('<a></a>').addClass('magnific-popup').attr({"href": $el.attr("src")});
            $anch.insertAfter($el);

            $el.detach().appendTo($anch)

            $anch.magnificPopup({type: "image", closeOnContentClick: true});
            $anch.closest('div').addClass('magnific-popup-wrapper');
            $anch.find('img').each(function () {
                this.onload = function () {
                    var imgWidth = this.clientWidth * 0.8;
                    if(imgWidth > 0)
                    {
                        $(this).attr('width', imgWidth);
                    }
                }
            });
        })
    });
})(jQuery);
