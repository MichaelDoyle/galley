fs = require 'fs'
path = require 'path'
url = require 'url'
_ = require 'lodash'
homeDir = require 'home-dir'

# Used to look up auth credentials when we know we're going to the official
# DockerHub registry.
DEFAULT_DOCKERHUB_HOST = 'https://index.docker.io/v1/'

module.exports =
  # Checks the user's docker config file for login information. The file is a JSON hash, and there are two
  # versions, in two different locations.
  #
  # The old version in ~/.dockercfg (pre-docker 1.7) is keyed by registry host name.
  # {
  #   "docker.crash.io": {
  #     "auth": "base64user:pass",
  #     "email": "email@email"
  #   }
  # }
  #
  # The new version in ~/.docker/config.json
  # {
  #   "auths": {
  #     "docker.crash.io": {
  #       "auth": "base64user:pass",
  #       "email": "email@email"
  #     },
  #     "https://index.docker.io/v1/": {
  #       "auth": "base64user:pass",
  #       "email": "email@email"
  #     }
  #   }
  # }
  authConfig: (host = DEFAULT_DOCKERHUB_HOST) ->
    hostConfig = try
      dockerOneSevenConfig = path.resolve homeDir(), '.docker/config.json'
      config = if fs.existsSync(dockerOneSevenConfig)
        configFile = fs.readFileSync dockerOneSevenConfig
        config = JSON.parse configFile.toString()
        config['auths']
      else
        configFile = fs.readFileSync path.resolve(homeDir(), '.dockercfg')
        JSON.parse configFile.toString()

      config[host]
    catch e
      # If file doesn't exist don't explode, just don't have auth
      throw e unless e?.code is 'ENOENT'

    if hostConfig?
      authBuffer = new Buffer hostConfig.auth, 'base64'
      [username, password] = authBuffer.toString().split ':'

      username: username
      password: password
      serveraddress: host
