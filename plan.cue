package main

import (
  "dagger.io/dagger"
  "dagger.io/dagger/core"
  // "universe.dagger.io/bash"
  // "universe.dagger.io/alpine"
  "universe.dagger.io/docker"
  // "universe.dagger.io/docker/cli"
)

dagger.#Plan & {

  client: {
    filesystem: ".": {
      read: contents: dagger.#FS
    }
    env: {
      DOCKER_IMAGE: string
      DOCKER_TAG: string
      DOCKER_REGISTRY: string
      DOCKER_USERNAME: string
      DOCKER_PASSWORD: dagger.#Secret
    }
    network: "unix:///var/run/docker.sock": connect: dagger.#Socket
  }

  actions: {

    src: core.#Source & {
      path: "."
    }

    build: docker.#Build & {
      steps: [
        docker.#Pull & {
          source: "docker:20.10.13-alpine3.15"
        },

        docker.#Run & {
          // input: _sourceimg.output
          command: {
            name: "apk"
            args: ["add", "git", "curl", "jq", "bash"]
            flags: {
              "-U":         true
              "--no-cache": true
            }
          }
        },

        docker.#Copy & {
          // input: _customize.output
          contents: client.filesystem.".".read.contents
          dest: "/code"
        },
      ]
    }

    versions: docker.#Run & {
      input: build.output
      command: {
        name: "bash"
        args: ["/code/get-versions.sh"]
      }
    }

    dockerlogin: docker.#Run & {
      input: versions.output
      env: {
        "DOCKER_USERNAME": client.env.DOCKER_USERNAME
        "DOCKER_PASSWORD": client.env.DOCKER_PASSWORD
        "DOCKER_REGISTRY": client.env.DOCKER_REGISTRY
      }
      entrypoint: []

      command: {
        name: "bash"
        args: [
          "-x",
          "-c",
          "echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin $DOCKER_REGISTRY"
        ]
      }
      mounts: {
        docker: {
          dest:     "/var/run/docker.sock"
          contents: client.network."unix:///var/run/docker.sock".connect
        }
      }
    }

    generator: docker.#Run & {
      input: dockerlogin.output
      workdir: "/code"
      env: {
        "IMAGE_NAME": client.env.DOCKER_IMAGE
      }
      command: {
        name: "sh"
        flags: "-c": #"""
        /code/generator.sh versions.txt
        """#
      }
      mounts: docker: {
        dest:     "/var/run/docker.sock"
        contents: client.network."unix:///var/run/docker.sock".connect
      }
    }

  }
}
