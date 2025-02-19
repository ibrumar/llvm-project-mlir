//===- RockGemmWrapperInterface.td - ops that wrap rock.gemm ---------===//
//
// Part of the rocMLIR Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Copyright (c) 2022 Advanced Micro Devices INc.
//===----------------------------------------------------------------------===//
//
// This file defines RockGemmWrapperInterface, which abstracts convolutions and
// matrix multiplies to allow code to operate on them generically.
//
//===----------------------------------------------------------------------===//

#ifndef ROCK_GEMM_WRAPPER_INTERFACE
#define ROCK_GEMM_WRAPPER_INTERFACE

include "mlir/IR/OpBase.td"

def RockGemmWrapperInterface : OpInterface<"RockGemmWrapperInterface"> {
  let description = [{
    Interface to abstract away gemm-wrapping operators in the rock dialect,
    which mainly include convolutions that can be transformed to matrix
    multiplications.

    This should include functions to get common attributes.
  }];
  let cppNamespace = "::mlir::rock";

  let methods = [
    InterfaceMethod<
        /*desc=*/[{
          Return the KernelType of this op
        }],
        /*retType=*/"::mlir::rock::KernelType",
        /*methodName=*/"getKernelType",
        /*args=*/(ins),
        /*methodBody=*/"",
        /*defaultImplementation=*/""
      >,

    InterfaceMethod<
        /*desc=*/[{
          Return the OpOperand that corresponds to the operand argument
          that corresponds to the output result of the operation.
        }],
        /*retType=*/"OpOperand *",
        /*methodName=*/"getOutArgument",
        /*args=*/(ins),
        /*methodBody=*/"",
        /*defaultImplementation=*/""
      >,
    InterfaceMethod<
        /*desc=*/[{
          Return the size of the matrix multiplication that this op will eventually
          perform.
        }],
        /*retType=*/"::mlir::rock::GemmSize",
        /*methodName=*/"getGemmSize",
        /*args=*/(ins),
        /*methodBody=*/"",
        /*defaultImplementation=*/""
      >,
    InterfaceMethod<
        /*desc=*/[{
          Return the element type of the input to this operation.
        }],
        /*retType=*/"::mlir::Type",
        /*methodName=*/"getInputType",
        /*args=*/(ins),
        /*methodBody=*/"",
        /*defaultImplementation=*/[{
          return $_op->getOperand(1).getType().template cast<::mlir::ShapedType>()
            .getElementType();
        }]
      >,
    InterfaceMethod<
        /*desc=*/[{
          Return the features attribute of this op.
        }],
        /*retType=*/"::mlir::rock::GemmFeatures",
        /*methodName=*/"getGemmFeatures",
        /*args=*/(ins),
        /*methodBody=*/"",
        /*defaultImplementation=*/[{
          return $_op.getFeatures();
        }]
      >,

    /// Setters for tuning-related data
    InterfaceMethod<
        /*desc=*/[{
          Set the block size attribute of this operation

          This is needed for --affix-tuning-params to work and can go away if it does
        }],
        /*retType=*/"void",
        /*methodName=*/"setDerivedBlockSizeAttr",
        /*args=*/(ins "::mlir::IntegerAttr":$blockSize),
        /*methodBody=*/"",
        /*defaultImplementation=*/[{
          $_op->setAttr($_op.getDerivedBlockSizeAttrName(), blockSize);
        }]
      >,
    InterfaceMethod<
        /*desc=*/[{
          Set the grid size attribute of this operation

          This is needed for --affix-tuning-params to work and can go away if it does
        }],
        /*retType=*/"void",
        /*methodName=*/"setGridSizeAttr",
        /*args=*/(ins "::mlir::IntegerAttr":$gridSize),
        /*methodBody=*/"",
        /*defaultImplementation=*/[{
          $_op->setAttr($_op.getGridSizeAttrName(), gridSize);
        }]
      >,
    InterfaceMethod<
        /*desc=*/[{
          Set the tuning parameters attribute of this operation

          This is needed for --affix-tuning-params to work and can go away if it does
        }],
        /*retType=*/"void",
        /*methodName=*/"setGemmParamsAttr",
        /*args=*/(ins "::mlir::Attribute":$params),
        /*methodBody=*/"",
        /*defaultImplementation=*/[{
          $_op->setAttr($_op.getParamsAttrName(), params);
        }]
      >,
    InterfaceMethod<
        /*desc=*/[{
          Get the value of the derived block size attribute if it is set.
        }],
        /*retType=*/"Optional<uint32_t>",
        /*methodName=*/"getDerivedBlockSize",
        /*args=*/(ins),
        /*methodBody=*/"",
        /*defaultImplementation=*/""
      >,
    InterfaceMethod<
        /*desc=*/[{
          Return the block size this operation will execute with if it has been selected 
          or None otherwise. Prioritizes the block size defined in tuning parameters
        }],
        /*retType=*/"uint32_t",
        /*methodName=*/"getBlockSize",
        /*args=*/(ins),
        /*methodBody=*/"",
        /*defaultImplementation=*/[{
          if (auto generalParams = $_op.getParamsAttr().template dyn_cast_or_null<GeneralGemmParamsAttr>()) {
            return generalParams.getBlockSize();
          }
          return $_op.getDerivedBlockSize().value_or(0);
        }]
      >

    // TODO: more methods here as needed
  ];

  let verify = [{
    auto concreteOp = ::mlir::cast<ConcreteOp>($_op);
    if ($_op->getNumResults() == 1) {
      if ($_op->getResult(0).getType() !=
          concreteOp.getOutArgument()->get().getType()) {
        return $_op->emitOpError("result type must match output argument type");
      }
    }
    return ::mlir::success();
  }];
}

#endif // ROCK_GEM_WRAPPER_INTERFACE
