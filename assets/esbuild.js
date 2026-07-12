const path = require("path")

module.exports = {
  targets: "defaults",
  entry: [
    path.join(__dirname, "../js/app.js")
  ],
  bundle: true,
  log_level: "error",
  target: "es2017",
  ignore: [],
  define: {},
  plugins: [],
  outdir: path.join(__dirname, "../priv/static/assets")
}
