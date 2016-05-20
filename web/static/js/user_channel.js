import jQuery from "./jquery"
let $ = jQuery
import Meta from "./meta"
import HexFaktor from "./hex_faktor"

export function init(socket) {
  let user_id = Meta.get("hf:user_id");
  if( user_id ) {
    let channel = socket.channel("users:"+user_id, {})
    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", channel.topic) })
      .receive("error", resp => { console.log("Unable to join", channel.topic, resp) })

    channel.on("user.github_sync_projects", resp => {
      console.log("~> github_sync", resp);

      HexFaktor.ensureSyncProgressBar();
      HexFaktor.deactivateSyncRepoButton();

      if( resp.link ) {
        var percent = 0;
        var result = resp.link.match(/page=(\d+)/);
        if( result ) {
          var page = result[1];
          percent = page / 10;
        }
        var width_in_percent = Math.floor(20 + Math.min(percent, 1) * 70);
        $("#sync-progress-indicator").css("width", width_in_percent+"%");
      }

      if( resp.complete ) {
        console.log("User projects are now in sync!");
        window.location.reload();
      }
    })

    channel.on("project.build", resp => {
      console.log("<user> project.build", resp);

      HexFaktor.updateComponent("project-list-item", resp.project_id);
    })

    channel.on("project.github_sync", resp => {
      console.log("~> github_sync", resp);
      if( resp.complete ) {
        var text = 'Sync successful! <a href="#" data-reload-on-click>Reload now!</a>';
        var sync_html = $("<div class=sync-progress><div class=sync-progress__inner><span>&gt;</span> "+text+"</div></div>");
        $("#sync-progress-inject").html(sync_html);

        if( $("[data-auto-reload]").data("auto-reload") == "on-sync-github-repo" ) {
          window.location.reload();
        }
      }
    })

    channel.on("project.webhook", resp => {
      console.log("~> project.webhook", resp);
      HexFaktor.updateComponent("project-list-item", resp.project_id);
    })

    var __notification__last_project_id = null;
    channel.on("notification.new", resp => {
      console.log("~> notification.new", resp, resp.project_id, __notification__last_project_id);

      if( resp.project_id != __notification__last_project_id ) {
        __notification__last_project_id = resp.project_id;
        HexFaktor.updateComponent("notification-counter");
        HexFaktor.updateComponent("project-list-item", resp.project_id);
      }
    })
  }
}
