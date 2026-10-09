# nix-strata

Nix flake and NixOS service module packaging [Niko1221/Strata](https://github.com/Niko1221/Strata), the specialized local inference engine for running the 125B parameter **Qwen3.8-Flash-Next** model on consumer and legacy GPUs.

> [!NOTE]
> **Name Disambiguation**: This flake packages **Strata the inference engine** (`Niko1221/Strata`). It is distinct from `lgse/strata`, which is the GTK4 Linux file manager. The binaries and service are explicitly named `strata-inference` and `strata-engine` to prevent any collision.

## Hardware & Architecture Support

- **Tesla P40 & Pascal GPUs (Compute Capability 6.1)**:
  Compiled with `-DSTRATA_EXPERIMENTAL_SM60=ON` and `CMAKE_CUDA_ARCHITECTURES="61"` using CUDA 12.
- **Modern RTX GPUs (Turing, Ampere, Ada, Blackwell)**:
  Supported via multi-architecture CUDA builds (`strata-inference`).

## Flake Outputs

- `packages.<system>.strata-inference-p40`: Inference daemon and engine optimized specifically for Tesla P40 / compute 6.1.
- `packages.<system>.strata-inference`: Multi-architecture CUDA package.
- `packages.<system>.strata-engine`: Standalone C++ engine binary (`bin/strata-engine`).
- `nixosModules.default`: NixOS systemd service module (`services.strata-inference`).

## NixOS Module Usage

```nix
{ inputs, ... }:
{
  imports = [
    inputs.nix-strata.nixosModules.default
  ];

  services.strata-inference = {
    enable = true;
    port = 8080;
    host = "0.0.0.0";
    modelsDir = "/var/lib/strata/models";
    openFirewall = true;
  };
}
```

The service exposes an OpenAI- and Anthropic-compatible API endpoint on port `8080` (or your configured port).
