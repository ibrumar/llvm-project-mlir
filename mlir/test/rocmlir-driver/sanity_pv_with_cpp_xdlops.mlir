// Sanity test to -pv_with_cpp produces valid MLIR for all possible data types and
// XDLOPS lowering paths.

// RUN: rocmlir-gen --arch gfx908 -p -mfma=on -pv_with_cpp | rocmlir-driver -c | rocmlir-opt
// RUN: rocmlir-gen --arch gfx908 -p -mfma=on -pv_with_cpp -t f16 | rocmlir-driver -c | rocmlir-opt
// RUN: rocmlir-gen --arch gfx908 -p -mfma=on -pv_with_cpp -t bf16 | rocmlir-driver -c | rocmlir-opt
// RUN: rocmlir-gen --arch gfx908 -p -mfma=on -pv_with_cpp -t i8 | rocmlir-driver -c | rocmlir-opt
