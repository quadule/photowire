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
  
  $(function() {
    setTimeout(function() { $('.photo').each(scrollablePhoto); }, 50);
  });
})(jQuery);
