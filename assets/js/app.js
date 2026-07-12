import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

let Hooks = {}

Hooks.AutoScroll = {
  mounted() {
    this.scrollToBottom()
  },
  updated() {
    this.scrollToBottom()
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: document.querySelector("meta[name='csrf-token']")?.getAttribute("content") }
})

liveSocket.connect()

window.liveSocket = liveSocket
