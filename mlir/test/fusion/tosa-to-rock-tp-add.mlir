// RUN: rocmlir-driver --host-pipeline highlevel %s | rocmlir-opt --rock-fold-transpose --rock-affix-params --rock-conv-to-gemm --rock-gemm-to-gridwise --rock-gridwise-gemm-to-blockwise --rock-linalg-align | FileCheck %s
// CHECK-DAG: #[[MAP1:.*]] = #rock.transform_map<affine_map<{{.*}} by [<PassThrough ["dim0", "dim1", "dim2", "dim3"] at [0, 1, 2, 3] -> ["dim0", "dim1", "dim2", "dim3"] at [0, 1, 2, 3]>, <AddDim{1} ["g"] at [4] -> [] at []>] bounds = [256, 28, 28, 64, 1] -> [256, 28, 28, 64]>
// CHECK-DAG: #[[MAP2:.*]] = #rock.transform_map<affine_map<{{.*}}> by [<PassThrough ["dim0", "dim1", "dim2", "dim3"] at [0, 3, 1, 2] -> ["dim0", "dim1", "dim2", "dim3"] at [0, 1, 2, 3]>] bounds = [256, 28, 28, 64] -> [256, 64, 28, 28]>
// CHECK: rock.transforming_for{{.*}}#[[MAP1]]
// CHECK: rock.transforming_for
// CHECK-SAME: [#[[MAP2]]]
// CHECK-SAME: bounds [1, 1, 1, 1]
// CHECK-NEXT: rock.global_load %arg2
// CHECK: linalg.generic{{.*}} outs(%[[outBuf:.*]] : memref<1xf32, 5>)
// CHECK: global_store %[[outBuf]]{{.*}} -> %arg3
// to test transpose is converted as transform and fused.

func.func @test_fusion(%arg0: tensor<256x28x28x128xf32>, %arg1: tensor<64x3x3x128xf32>, %arg2: tensor<256x64x28x28xf32>) -> tensor<256x28x28x64xf32> attributes {kernel, arch = ""} {
    %cst = arith.constant dense<[0, 2, 3, 1]> : tensor<4xi64>
    %cst_0 = arith.constant dense<0.000000e+00> : tensor<1xf32>
    %0 = "tosa.conv2d"(%arg0, %arg1, %cst_0) {dilation = [1, 1], expected_filter_layout = "kyxc", expected_input_layout = "nhwc", expected_output_layout = "nhwk", pad = [1, 1, 1, 1], stride = [1, 1]} : (tensor<256x28x28x128xf32>, tensor<64x3x3x128xf32>, tensor<1xf32>) -> tensor<256x28x28x64xf32>
    %1 = "tosa.transpose"(%arg2, %cst) : (tensor<256x64x28x28xf32>, tensor<4xi64>) -> tensor<256x28x28x64xf32>
    %2 = "tosa.add"(%0, %1) : (tensor<256x28x28x64xf32>, tensor<256x28x28x64xf32>) -> tensor<256x28x28x64xf32>
    return %2 : tensor<256x28x28x64xf32>
}

