class Mpeghdec < Formula
  desc "Libraries of Fraunhofer MPEG-H decoder"
  homepage "https://www.mpegh.com"
  url "https://github.com/Fraunhofer-IIS/mpeghdec/archive/refs/tags/r4.0.1.tar.gz"
  sha256 "e7842b46c8054367eea0537922b61180be7e7dc9747d872071854b08139c6016"
  license "Apache-2.0"
  head "https://github.com/Fraunhofer-IIS/mpeghdec.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build

  resource "ilo" do
    url "https://github.com/Fraunhofer-IIS/ilo/archive/refs/tags/r2.0.2.tar.gz"
    sha256 "2f0e57652e5c028f0fc5cfe640c7fe652635db9796a19835d786ccd09a227b2d"
  end

  resource "mmtisobmff" do
    url "https://github.com/Fraunhofer-IIS/mmtisobmff/archive/refs/tags/r1.0.4.tar.gz"
    sha256 "c0a10c0f32aa10f204be5629a6d7e5d74f8ac785dfa19ee68662d0c4ddad749c"
  end

  deny_network_access!

  def install
    resources.each do |dep|
      dep.stage do
        system "cmake", "-S", ".", "-B", "build",
               "-DUSE_PKGCONFIG_DEPS=ON",
               *std_cmake_args(install_prefix: buildpath/dep.name/"build")
        system "cmake", "--build", "build"
        system "cmake", "--install", "build"
        ENV.prepend_path "PKG_CONFIG_PATH", buildpath/dep.name/"build/share/pkgconfig"
      end
    end

    system "cmake", "-S", ".", "-B", "build",
           "-DCMAKE_INSTALL_DATAROOTDIR=#{lib}",
           "-DBUILD_SHARED_LIBS=ON",
           "-DUSE_PKGCONFIG_DEPS=ON",
           *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <stdio.h>
      #include <mpeghdec/mpeghdecoder.h>

      int main()
      {
          HANDLE_MPEGH_DECODER_CONTEXT decoder = mpeghdecoder_init(2);
          if (decoder == nullptr) {
              fprintf(stderr, "mpeghdecoder_init() failed\\n");
              return 1;
          }

          printf("mpeghdec initialized successfully\\n");
          mpeghdecoder_destroy(decoder);
          return 0;
      }
    CPP

    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-lmpeghdec", "-o", "test"
    system "./test"
  end
end
