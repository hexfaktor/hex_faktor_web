import jQuery from "./jquery"
let $ = jQuery
import Meta from "./meta"

export function init(socket) {
  let project_id = Meta.get("hf:project_id");
  if( project_id ) {
    let channel = socket.channel("projects:"+project_id, {})
    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", channel.topic) })
      .receive("error", resp => { console.log("Unable to join", channel.topic, resp) })

    channel.on("project.build", resp => {
      console.log("<project> project.build", resp);

      var text = "";
      if( resp.status == "scheduling" ) {
        text = "Scheduling worker ...";
      } else if( resp.status == "cloning" ) {
        text = "Cloning repo ...";
      } else if( resp.status == "running" ) {
        text = "Running deps analysis ...";
      } else if( resp.status == "success" ) {
        if( $("[data-auto-reload]").data("auto-reload") == "on-build-end" ) {
          window.location.reload();
        }

        text = 'Build successful! <a href="#" data-reload-on-click>Reload now!</a>';
      } else if( resp.status == "error" ) {
        text = "Build failed! Something went wrong ...";
      }
      var sync_html = $('<div class="sync-progress sync-progress--building"><div class=sync-progress__inner><span>&gt;</span> '+text+'</div><div class=sync-progress__bar></div></div>');
      $("#sync-progress-inject").html(sync_html);
    })
  }
}
