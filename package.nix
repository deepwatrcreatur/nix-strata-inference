{ lib
, stdenv
, fetchFromGitHub
, cmake
, ninja
, pkg-config
, python3
, cudaPackages
, cudaArch ? "61" # Default to Pascal sm_61 for Tesla P40
, experimentalSm60 ? true
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    numpy
    jinja2
    regex
    pyyaml
    tqdm
    requests
    pillow
    psutil
  ]);

  llamaCppSrc = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "3cf03257f219afbe7334045ff7c6a06ac68c627d";
    hash = "sha256-SRGoXa+4ACBCB3eaG9XFYhMN1i0FyPEy9Rrer+dFGYI=";
  };
in
stdenv.mkDerivation rec {
  pname = "strata-inference";
  version = "0.1.41";

  src = fetchFromGitHub {
    owner = "Niko1221";
    repo = "Strata";
    rev = "v${version}";
    hash = "sha256-WhoIwg8GgeG3jAXYLSjNoZyN3RZ3T3JhgJX57fM80eE=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    cudaPackages.cuda_cudart
    cudaPackages.libcublas
    pythonEnv
  ];

  cmakeFlags = [
    "-DSTRATA_ENABLE_CUDA=ON"
    "-DSTRATA_BUILD_TESTS=OFF"
    "-DCMAKE_CUDA_ARCHITECTURES=${cudaArch}"
    "-DSTRATA_GGML_DIR=${llamaCppSrc}"
  ] ++ lib.optionals experimentalSm60 [
    "-DSTRATA_EXPERIMENTAL_SM60=ON"
  ];

  preConfigure = ''
    export CUDA_PATH="${cudaPackages.cuda_cudart}"
    export CUDACXX="${cudaPackages.cuda_nvcc}/bin/nvcc"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/strata $out/share/strata

    # Install the compiled C++ strata engine binary
    if [ -f strata ]; then
      cp strata $out/libexec/strata/strata
    elif [ -f src/strata ]; then
      cp src/strata $out/libexec/strata/strata
    elif [ -f bin/strata ]; then
      cp bin/strata $out/libexec/strata/strata
    fi

    # Symlink engine binary with distinct name to prevent collision with file manager
    ln -s $out/libexec/strata/strata $out/bin/strata-engine

    # Copy server code and tools
    cp -r ../serve $out/share/strata/
    cp -r ../tools $out/share/strata/
    cp ../setup.py $out/share/strata/ || true

    # Create the strata-inference server wrapper script
    cat <<WRAPPER > $out/bin/strata-inference
#!/bin/sh
export PATH="$out/libexec/strata:\$PATH"
export PYTHONPATH="$out/share/strata:$out/share/strata/tools:\$PYTHONPATH"
exec ${pythonEnv}/bin/python -m serve.server --engine strata "\$@"
WRAPPER
    chmod +x $out/bin/strata-inference

    runHook postInstall
  '';

  meta = with lib; {
    description = "High-performance inference engine and API server for Qwen3.8-Flash-Next 125B MoE";
    homepage = "https://github.com/Niko1221/Strata";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "strata-inference";
  };
}
