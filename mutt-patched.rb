require 'formula'

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

  unless Tab.for_name("signing-party").with? "rename-pgpring"
    conflicts_with "signing-party",
      :because => "mutt installs a private copy of pgpring"
  end

  conflicts_with 'tin',
    :because => 'both install mmdf.5 and mbox.5 man pages'

  option "with-debug", "Build with debug option enabled"
  option "with-sidebar-patch", "Build with sidebar patch"
  option "with-trash-patch", "Apply trash folder patch"
  option "with-s-lang", "Build against slang instead of ncurses"
  option "with-ignore-thread-patch", "Apply ignore-thread patch"
  option "with-pgp-verbose-mime-patch", "Apply PGP verbose mime patch"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on 'openssl'
  depends_on 'tokyo-cabinet'
  depends_on 's-lang' => :optional
  depends_on 'gpgme' => :optional
  depends_on "gettext" => :optional
  depends_on "libidn" => :optional

  patch do
    url "http://localhost.lu/mutt/patches/trash-folder"
    sha1 "159d8f016275d239fd2fc847a0d243fb46e6cf2c"
  end if build.with? "trash-patch"

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  patch do
    url "https://gist.githubusercontent.com/mistydemeo/5522742/raw/1439cc157ab673dc8061784829eea267cd736624/ignore-thread-1.5.21.patch"
    sha256 "7290e2a5ac12cbf89d615efa38c1ada3b454cb642ecaf520c26e47e7a1c926be"
  end if build.with? "ignore-thread-patch"

  patch do
    url "https://raw.githubusercontent.com/skn/homebrew/master/mutt/patches/patch-1.5.4.vk.pgp_verbose_mime"
    sha256 "bb9108955aa8e1ddeb6a28ef60aa12713bc5c497e07f0544f556c6e6ad225280"
  end if build.with? "pgp-verbose-mime-patch"

  patch do
    url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
    sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
  end if build.with? "confirm-attachment-patch"

  patch do
    url "https://raw.githubusercontent.com/SteveClement/mutt-sidebar-patch/master/mutt-sidebar.patch"
    sha256 "ff92ef50811bc77ee1b7657aef6d2b5f48fae9e6d6dc0fd1dcd0296f983c21f4"
  end if build.with? "sidebar-patch"

  def install
    user_admin = Etc.getgrnam("admin").mem.include?(ENV["USER"])

    args = ["--disable-dependency-tracking",
            "--disable-warnings",
            "--prefix=#{prefix}",
            "--with-ssl=#{Formula['openssl'].opt_prefix}",
            "--with-sasl",
            "--with-gss",
            "--enable-imap",
            "--enable-smtp",
            "--enable-pop",
            "--enable-hcache",
            "--with-tokyocabinet",
            # This is just a trick to keep 'make install' from trying to chgrp
            # the mutt_dotlock file (which we can't do if we're running as an
            # unpriviledged user)
            "--with-homespool=.mbox"]
    args << "--with-slang" if build.with? 's-lang'
    args << "--enable-gpgme" if build.with? 'gpgme'

    if build.with? 'debug'
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end

    if build.head?
      system "./prepare", *args
    else
      system "./configure", *args
    end
    system "make"
    system "make", "install"

    (share/'doc/mutt').install resource('html') if build.head?
  end
end
