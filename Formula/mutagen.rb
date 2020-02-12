# TODO: This formula isn't particularly idiomatic. It treats the release archive
# as the source bundle and just copies the files in the bundle.
#
# There are two primary reasons for this: build complexity (Mutagen has a custom
# build script that relies on it being checked out into GOPATH) and build time
# (the build has to cross-compile agent binaries for each remote system). The
# first might be solved by switching to vgo (and we'd also need to add an
# additional build mode that only builds a release bundle for the current
# platform), and the second might be solved by using the official Homebrew
# bottle support (if we can find a place to host the bottles) (maybe we can even
# get merged into homebrew-core at some point to host the bottles).
#
# There are also a few additional reasons for this, including the fact that
# Mutagen uses cgo (and thus depends on having a sane toolchain available)
# (though we may be able to get around this by using Go's dynamic cgo support
# coming for macOS in Go 1.11), Mutagen only supports the most recent version of
# Go (though it may be possible to specify a minimum Go version as a build
# dependency) (but I can't find any examples of this), and Mutagen has a number
# of Git submodules that don't come in the source tarball that GitHub generates
# (though we might be able to use the GitDownloadStrategy that handles this).
#
# We can re-evaluate all of this once the Go dependency management landscape
# matures a bit, perhaps with Go 1.12.
class Mutagen < Formula
  desc "Fast, cross-platform, continuous, bidirectional file synchronization"
  homepage "https://mutagen.io"
  version "0.11.0"
  if OS.mac?
    url "https://github.com/mutagen-io/mutagen/releases/download/v0.11.0/mutagen_darwin_amd64_v0.11.0.tar.gz"
    sha256 "a48db7c66c8562adc44dc36c1f0775f00e054cfcc3e0e3a8e1f61602fbb89e17"
  else
    url "https://github.com/mutagen-io/mutagen/releases/download/v0.11.0/mutagen_linux_amd64_v0.11.0.tar.gz"
    sha256 "f62707fef15aa83e44c2e1a282f40952e0ab8acc9c3cb8d795ed4d0a23de1459"
  end

  devel do
    version "0.11.0"
    if OS.mac?
      url "https://github.com/mutagen-io/mutagen/releases/download/v0.11.0/mutagen_darwin_amd64_v0.11.0.tar.gz"
      sha256 "a48db7c66c8562adc44dc36c1f0775f00e054cfcc3e0e3a8e1f61602fbb89e17"
    else
      url "https://github.com/mutagen-io/mutagen/releases/download/v0.11.0/mutagen_linux_amd64_v0.11.0.tar.gz"
      sha256 "f62707fef15aa83e44c2e1a282f40952e0ab8acc9c3cb8d795ed4d0a23de1459"
    end
  end

  def install
    # Generate a bash completion script in a subdirectory and install it to the
    # bash completion directory.
    mkdir "generated" do
      system "../mutagen", "generate", "--bash-completion-script=mutagen"
      bash_completion.install "mutagen"
    end

    # Install the mutagen binary into the bin directory.
    bin.install "mutagen"

    # Install the agent bundle into the bin directory.
    # TODO: I'd prefer to install this in the libexec directory for hygiene
    # purposes. This is a bit of a pain to properly implement because Mutagen
    # use's Go's os.Executable function, which on some platforms (including
    # macOS) returns the symlink path used to launch the executable. Resolving
    # the symlink would be necessary to compute the libexec path because libexec
    # isn't linked into /usr/local by Homebrew. Other than that, probing for the
    # bundle in libexec wouldn't be particularly difficult.
    bin.install "mutagen-agents.tar.gz"
  end

  def caveats
    <<~EOS
      Mutagen has a daemon component that runs on a per-user basis. You'll need
      to invoke the following manually and/or add it to your shell
      initialization script:

        mutagen daemon start

      This command is idempotent and can be run any number of times.

      Experimental support for automatically starting the daemon on macOS via
      launchd is also available. To register Mutagen as a per-user daemon with
      launchd, use:

        mutagen daemon register

      This registration can be removed with:

        mutagen daemon unregister

      In order to take advantage of automatic start-up, either log out and log
      back in or run:

        mutagen daemon start

      This support is experimental, so please provide feedback if you run into
      any issues.

      Please note that the Mutagen daemon should be manually restarted after an
      update using:

        mutagen daemon stop
        mutagen daemon start
    EOS
  end

  test do
    system bin/"mutagen", "version"
  end
end
