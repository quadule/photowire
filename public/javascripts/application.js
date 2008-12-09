(function($) {
  function scrollablePhoto(index, container) {
    container = $(container);
    var content = container.find('a'), contentPadding = parseInt(content.css('padding-top'));
    var contentHeight = content.height() + contentPadding, containerHeight = container.height();
    if(contentHeight > containerHeight) {
      container.mousemove(function(e) {
        var y = e.pageY - container.offset().top;
        var positionRatio = y / containerHeight;
        container[0].scrollTop = (contentHeight - containerHeight) * positionRatio;
        clearTimeout(container.data('scrollTimer'));
      });
      container.mouseout(function(e) {
        e.stopPropagation();
        clearTimeout(container.data('scrollTimer'));
        container.data('scrollTimer', setTimeout(function() {
          container[0].scrollTop = 0;
        }, 100));
      });
      content.find('img').mouseout(function(e) { e.stopPropagation(); });
    }
  }
  
  function zoomablePhoto() {
    var photo = $(this), container = photo.parent();
    var width = photo.width(), height = photo.height();
    var scale = container.innerWidth() / width;
    
    //don't zoom photos smaller than the viewport
    if(scale >= 1) return false;
    
    if(!$.browser.mozilla) photo.css('cursor', 'move');
    
    photo.click(function() {
      if(photo.data('zoomed')) {
        photo.width(width);
        photo.height(height);
        if($.browser.mozilla) photo.css('cursor', '-moz-zoom-out');
        photo.data('zoomed', false);
      } else {
        photo.width(Math.round(width * scale));
        photo.height(Math.round(height * scale));
        if($.browser.mozilla) photo.css('cursor', '-moz-zoom-in');
        photo.data('zoomed', true);
      }
    });
    photo.click();
  }
  
  $(function() {
    $('.photos.index .photo').each(scrollablePhoto);
    $('.photo.show img').each(zoomablePhoto);
  });
})(jQuery);
