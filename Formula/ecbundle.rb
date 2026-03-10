class Ecbundle < Formula
  include Language::Python::Virtualenv

  desc "Bundle management tool for CMake projects"
  homepage "https://github.com/ecmwf/ecbundle"
  url "https://github.com/ecmwf/ecbundle/archive/refs/tags/2.4.0.tar.gz"
  sha256 "542da932b6884383690b3ea144e3ec0f88f466364bec0422be11e6ea2faf457b"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/ecmwf/ecbundle/tags"
    regex(/^v?(\d(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/recmanj-org/homebrew-ecmwf/releases/download/ecbundle-2.4.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "34f2c6670e941768a45d4cb42e46aeb455e7b7adb594e1150dffaf7b49ce5d54"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "0e05b263849554e0c79362a0969145f8a1e8835a0d695ac6f3dbef9933b908de"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "8c1ba36c580da4782c62cbb3acacaf73f9a81219c0fc45e64ab2743a937f7725"
    sha256 cellar: :any_skip_relocation, tahoe:         "fb2addfab926a55028cf8b9779b819bc495cb54a45177be2ad31de9b85d0fe3b"
    sha256 cellar: :any_skip_relocation, sequoia:       "bf5b604ff13f35d84c54408a056c0277e41c1193f48b7c275f47e90ba2abe0b1"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "aa21b78af9d89b288e72007f9efd6520b4fb0927dd9d3c2f6aae097c9a3908b5"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "a1d2b215364701f202c35a143c2a0461bd8f5cd2737bb9eee5fbbfc6e3570908"
  end

  depends_on "python@3.13"

  resource "ruamel-yaml" do
    url "https://files.pythonhosted.org/packages/c7/3b/ebda527b56beb90cb7652cb1c7e4f91f48649fbcd8d2eb2fb6e77cd3329b/ruamel_yaml-0.19.1.tar.gz"
    sha256 "53eb66cd27849eff968ebf8f0bf61f46cdac2da1d1f3576dd4ccee9b25c31993"
  end

  resource "ruamel-yaml-clib" do
    url "https://files.pythonhosted.org/packages/ea/97/60fda20e2fb54b83a61ae14648b0817c8f5d84a3821e40bfbdae1437026a/ruamel_yaml_clib-0.2.15.tar.gz"
    sha256 "46e4cc8c43ef6a94885f72512094e482114a8a706d3c555a34ed4b0d20200600"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ecbundle --version")
  end
end
