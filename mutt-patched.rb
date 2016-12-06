# Note: Mutt has a large number of non-upstream patches available for
# it, some of which conflict with each other. These patches are also
# not kept up-to-date when new versions of mutt (occasionally) come
# out.
#
# To reduce Homebrew's maintenance burden, patches are not accepted
# for this formula. The NeoMutt project has a Homebrew tap for their
# patched version of Mutt: https://github.com/neomutt/homebrew-neomutt

class MuttPatched < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage "http://www.mutt.org/"
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.7.2.tar.gz"
  mirror "ftp://ftp.mutt.org/pub/mutt/mutt-1.7.2.tar.gz"
  sha256 "1553501687cd22d5b8aaee4dc5a7d9dcf6cc61d7956f6aabaadd252d10cd5ff9"

  bottle do
    sha256 "1657ad34c085ac8db3ce49f415423ca57d479417e3f6128064dc85a68a18248f" => :sierra
    sha256 "b91545069060c8971aae46bd6add177e8a257d5865e895f7f3ef3d59dc2a6e4c" => :el_capitan
    sha256 "eef88ff9b9cf11901d39198d732d315b127addb37ef1d6ffe8fe88473f4752bf" => :yosemite
  end

  head do
    url "https://dev.mutt.org/hg/mutt#default", :using => :hg

    resource "html" do
      url "https://dev.mutt.org/doc/manual.html", :using => :nounzip
    end
  end

  option "with-debug", "Build with debug option enabled"
  option "with-s-lang", "Build against slang instead of ncurses"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"
  option "with-ignore-thread-patch", "Apply ignore-thread patch"
  option "with-pgp-verbose-mime-patch", "Apply PGP verbose mime patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "openssl"
  depends_on "tokyo-cabinet"
  depends_on "gettext" => :optional
  depends_on "gpgme" => :optional
  depends_on "libidn" => :optional
  depends_on "s-lang" => :optional

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  if build.with? "ignore-thread-patch"
    patch do
      url "https://gist.githubusercontent.com/SteveClement/6c6bcf9c7c2f09174e790033e2feef7f/raw/7de5336930c7411e29ac4f6052de1e8c8fff909b/ignore-thread-1.6.2.patch"
      sha256 "4bc1197c0005a55c0b8fd5baba193d1f1359bd3d903a46aa738dc2692b619d50"
    end
  end

  if build.with? "confirm-attachment-patch"
    patch do
      url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
      sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
    end
  end

  if build.with? "pgp-verbose-mime-patch"
    patch do
      url "https://localhost.lu/mutt/patches/patch-1.6.2.sc.pgp_verbose_mime"
      sha256 "681f304b8be1f2f2af9559133bb94b27130287ab3d5de10c30d6ffe3d45fbb80"
    end
  end

  def install
    user_admin = Etc.getgrnam("admin").mem.include?(ENV["USER"])

    args = %W[
      --disable-dependency-tracking
      --disable-warnings
      --prefix=#{prefix}
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --with-sasl
      --with-gss
      --enable-imap
      --enable-smtp
      --enable-pop
      --enable-hcache
      --with-tokyocabinet
      --enable-sidebar
    ]

    # This is just a trick to keep 'make install' from trying
    # to chgrp the mutt_dotlock file (which we can't do if
    # we're running as an unprivileged user)
    args << "--with-homespool=.mbox" unless user_admin

    args << "--disable-nls" if build.without? "gettext"
    args << "--enable-gpgme" if build.with? 'gpgme'
    args << "--with-slang" if build.with? 's-lang'

    if build.with? "debug"
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end

    system "./prepare", *args
    system "make"

    # This permits the `mutt_dotlock` file to be installed under a group
    # that isn't `mail`.
    # https://github.com/Homebrew/homebrew/issues/45400
    if user_admin
      inreplace "Makefile", /^DOTLOCK_GROUP =.*$/, "DOTLOCK_GROUP = admin"
    end

    system "make", "install"
    doc.install resource("html") if build.head?
  end

  test do
    system bin/"mutt", "-D"
  end
end
