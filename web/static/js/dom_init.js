
import jQuery from "./jquery"
import HexFaktor from "./hex_faktor"
import Meta from "./meta"

jQuery(function($) {
  let csrf = Meta.get("csrf");

  $.ajaxSetup({
      headers: { "x-csrf-token": csrf }
  });

  if( $("[data-sync-github-repos]").length > 0 ) {
    jQuery.ajax("/projects/sync_github", {"method": "POST"});
    HexFaktor.ensureSyncProgressBar();
    HexFaktor.deactivateSyncRepoButton();
  }
  if( $("[data-sync-github-repo]").length > 0 ) {
    var name = $("[data-sync-github-repo]").data("sync-github-repo")
    jQuery.ajax("/projects/sync_github/"+name, {"method": "POST"})
  }


  // Loading indicators
  $("body").on("click", "a.btn[data-submit=parent], a[data-loadable]", function(event) {
    HexFaktor.addLoadingClass(this);
  });

  // No-op for buttons with loading indicators
  $("body").on("click", ".btn--loading", function(event) {
    event.preventDefault();
    event.stopImmediatePropagation();

    return false;
  });

  // AJAX ... it's like Channels, but from the 90's ...
  function ajax(url, method, replace_query) {
    let opts = {"method": method};
    if( replace_query ) opts.success = function(data) { $(replace_query).replaceWith(data); };
    jQuery.ajax(url, opts);
  }

  $("body").on("click", "a[data-ajax-post]", function(event) {
    event.preventDefault();
    event.stopImmediatePropagation();

    ajax($(this).data("ajax-post"), "POST", $(this).data("ajax-replace"))

    return false;
  });
  $("body").on("click", "a[data-ajax-get]", function(event) {
    event.preventDefault();
    event.stopImmediatePropagation();

    ajax($(this).data("ajax-get"), "GET", $(this).data("ajax-replace"))

    return false;
  });

  // Reload on click
  $("body").on("click", "[data-reload-on-click]", function(event) {
    event.preventDefault();
    event.stopImmediatePropagation();

    window.location.reload();

    return false;
  });

  // Project search filter
  $("body")
    .on("focus", "input[name=q]", function(event) {
      console.log("focussed input")
      $(this).closest(".tab-nav").addClass("tab-nav--search-active");
    })
    .on("blur", "input[name=q]", function(event) {
      var $this = $(this);
      if( $this.val() == "" ) {
        console.log("blurred input")
        //$this.closest(".tab-nav").removeClass("tab-nav--search-active");
      }
    });

  // Auto select form elements
  $("[data-auto-select]").select();
});
