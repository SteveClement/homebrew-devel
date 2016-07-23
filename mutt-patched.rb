/si# Note: Mutt has a large number of non-upstream patches available for
# it, some of which conflict with each other. These patches are also
# not kept up-to-date when new versions of mutt (occasionally) come
# out.
#
# To reduce Homebrew's maintenance burden, new patches are not being
# accepted for this formula. We would be very happy to see members of
# the mutt community maintain a more comprehesive tap with better
# support for patches.

class MuttPatched < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage 'http://www.mutt.org/'
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.5.24.tar.gz"
  mirror "ftp://ftp.mutt.org/pub/mutt/mutt-1.5.24.tar.gz"
  sha256 "a292ca765ed7b19db4ac495938a3ef808a16193b7d623d65562bb8feb2b42200"

  bottle do
    revision 2
    sha256 "5bb0c9590b522bbcc38bfecaf0561810db2660792f472aa12a3b6c8f5e5b28d7" => :el_capitan
    sha256 "8cad91b87b615984871b6bed35a029edcef006666bc7cf3b8f6b8b74d91c5b97" => :yosemite
    sha256 "c57d868588eb947002902c90ee68af78298cbb09987e0150c1eea73f9e574cce" => :mavericks
  end

  head do
    url 'http://dev.mutt.org/hg/mutt#default', :using => :hg

    resource 'html' do
      url 'http://dev.mutt.org/doc/manual.html', :using => :nounzip
    end
  end

  conflicts_with 'tin',
    :because => 'both install mmdf.5 and mbox.5 man pages'

  option "with-debug", "Build with debug option enabled"
  option "with-s-lang", "Build against slang instead of ncurses"
  option "with-ignore-thread-patch", "Apply ignore-thread patch"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"
  option "with-sidebar-patch", "Build with sidebar patch"
  option "with-trash-patch", "Apply trash folder patch"
  option "with-pgp-verbose-mime-patch", "Apply PGP verbose mime patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on 'openssl'
  depends_on 'tokyo-cabinet'
  depends_on "gettext" => :optional
  depends_on 'gpgme' => :optional
  depends_on "libidn" => :optional
  depends_on 's-lang' => :optional

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  if build.with? "ignore-thread-patch"
    patch do
      url "https://gist.githubusercontent.com/mistydemeo/5522742/raw/1439cc157ab673dc8061784829eea267cd736624/ignore-thread-1.5.21.patch"
      sha256 "7290e2a5ac12cbf89d615efa38c1ada3b454cb642ecaf520c26e47e7a1c926be"
    end
  end

  if build.with? "confirm-attachment-patch"
    patch do
      url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
      sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
    end
  end

  if build.with? "sidebar-patch"
    patch do
      url "https://raw.githubusercontent.com/SteveClement/mutt-sidebar-patch/master/mutt-sidebar.patch"
      sha256 "ff92ef50811bc77ee1b7657aef6d2b5f48fae9e6d6dc0fd1dcd0296f983c21f4"
    end
  end

  if build.with? "trash-patch"
    patch do
      url "http://localhost.lu/mutt/patches/trash-folder"
      sha256 "9e7484ebed013b575150a8edc20821594d514b45703931b99f1e4a7e87c4de64"
    end
  end

  if build.with? "pgp-verbose-mime-patch"
    patch do
      url "http://localhost.lu/mutt/patches/patch-1.5.24.sc.pgp_verbose_mime"
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
    ]

    # This is just a trick to keep 'make install' from trying
    # to chgrp the mutt_dotlock file (which we can't do if
    # we're running as an unprivileged user)
    args << "--with-homespool=.mbox" unless user_admin

    args << "--disable-nls" if build.without? "gettext"
    args << "--enable-gpgme" if build.with? 'gpgme'
    args << "--with-slang" if build.with? 's-lang'

    if build.with? 'debug'
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
