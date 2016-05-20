import {Socket} from "phoenix"
import Meta from "./meta"

import * as ProjectChannel from "./project_channel"
import * as UserChannel from "./user_channel"

let socket = new Socket("/socket", {params: {token: Meta.get("hf:user_token")}})
socket.connect()

ProjectChannel.init(socket)
UserChannel.init(socket)

export default socket
