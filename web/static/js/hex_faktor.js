import jQuery from "./jquery"
let $ = jQuery

let faktor = {
  addLoadingClass: function(ele) {
    let $ele = $(ele);
    if( $ele.hasClass("btn") ) {
      $ele.addClass("btn--loading");
    } else {
      $ele.addClass("loading");
    }
  },
  updateComponent: function(name, id) {
    var $dom_element, url;
    if( id ) {
      $dom_element = $("#"+name+"-"+id);
      url = "/component/"+name+"/"+id;
    } else {
      $dom_element = $("#"+name);
      url = "/component/"+name;
    }

    if( $dom_element.length > 0 ) {
      jQuery.ajax(url,
        {
          "method": "GET",
          "success": function(html) {
            $dom_element.replaceWith(html)
          }
        }
      );
    }
  },
  deactivateSyncRepoButton: function() {
    var $btn = $("a[data-syncing-label]");
    if( !$btn.hasClass("btn--loading") ) {
      var label = $btn.data("syncing-label");
      $btn
        .removeClass("btn--sync")
        .addClass("btn--sync")
        .addClass("btn--loading")
        .html(label);
    }
  },
  ensureSyncProgressBar: function() {
    $(".sync-progress").show();
  }
}

export default faktor
