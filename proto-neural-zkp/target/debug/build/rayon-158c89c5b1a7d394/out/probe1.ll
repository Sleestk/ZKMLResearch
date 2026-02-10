; ModuleID = 'probe1.ba0a74ba5d6827b6-cgu.0'
source_filename = "probe1.ba0a74ba5d6827b6-cgu.0"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx11.0.0"

@alloc_4aead6e2018a46d0df208d5729447de7 = private unnamed_addr constant [27 x i8] c"assertion failed: step != 0", align 1
@alloc_554dcd582536a28cc090588ecf73ae50 = private unnamed_addr constant [121 x i8] c"/Users/ble/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/src/rust/library/core/src/iter/adapters/step_by.rs\00", align 1
@alloc_724617a1c00795939282a94c83bff428 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_554dcd582536a28cc090588ecf73ae50, [16 x i8] c"x\00\00\00\00\00\00\00#\00\00\00\09\00\00\00" }>, align 8

; core::iter::traits::iterator::Iterator::rev
; Function Attrs: inlinehint uwtable
define void @_ZN4core4iter6traits8iterator8Iterator3rev17hb9fc78500eb5bbd5E(ptr sret([24 x i8]) align 8 %_0, ptr align 8 %self) unnamed_addr #0 {
start:
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %_0, ptr align 8 %self, i64 24, i1 false)
  ret void
}

; core::iter::traits::iterator::Iterator::step_by
; Function Attrs: inlinehint uwtable
define void @_ZN4core4iter6traits8iterator8Iterator7step_by17h0bf3d327b836187dE(ptr sret([24 x i8]) align 8 %_0, i32 %self.0, i32 %self.1, i64 %step) unnamed_addr #0 {
start:
; call core::iter::adapters::step_by::StepBy<I>::new
  call void @"_ZN4core4iter8adapters7step_by15StepBy$LT$I$GT$3new17hd3747df1724da6d9E"(ptr sret([24 x i8]) align 8 %_0, i32 %self.0, i32 %self.1, i64 %step) #5
  ret void
}

; core::iter::adapters::step_by::StepBy<I>::new
; Function Attrs: inlinehint uwtable
define void @"_ZN4core4iter8adapters7step_by15StepBy$LT$I$GT$3new17hd3747df1724da6d9E"(ptr sret([24 x i8]) align 8 %_0, i32 %iter.0, i32 %iter.1, i64 %step) unnamed_addr #0 personality ptr @rust_eh_personality {
start:
  %0 = alloca [16 x i8], align 8
  %_8 = alloca [1 x i8], align 1
  store i8 1, ptr %_8, align 1
  %_3 = icmp ne i64 %step, 0
  br i1 %_3, label %bb1, label %bb2

bb2:                                              ; preds = %start
; invoke core::panicking::panic
  invoke void @_ZN4core9panicking5panic17h30f5ec71e3af4326E(ptr align 1 @alloc_4aead6e2018a46d0df208d5729447de7, i64 27, ptr align 8 @alloc_724617a1c00795939282a94c83bff428) #6
          to label %unreachable unwind label %cleanup

bb1:                                              ; preds = %start
  store i8 0, ptr %_8, align 1
; invoke <T as core::iter::adapters::step_by::SpecRangeSetup<T>>::setup
  %1 = invoke { i32, i32 } @"_ZN76_$LT$T$u20$as$u20$core..iter..adapters..step_by..SpecRangeSetup$LT$T$GT$$GT$5setup17h60e6c508537daaa1E"(i32 %iter.0, i32 %iter.1, i64 %step)
          to label %bb3 unwind label %cleanup

bb6:                                              ; preds = %cleanup
  %2 = load i8, ptr %_8, align 1
  %3 = trunc nuw i8 %2 to i1
  br i1 %3, label %bb5, label %bb4

cleanup:                                          ; preds = %bb1, %bb2
  %4 = landingpad { ptr, i32 }
          cleanup
  %5 = extractvalue { ptr, i32 } %4, 0
  %6 = extractvalue { ptr, i32 } %4, 1
  store ptr %5, ptr %0, align 8
  %7 = getelementptr inbounds i8, ptr %0, i64 8
  store i32 %6, ptr %7, align 8
  br label %bb6

unreachable:                                      ; preds = %bb2
  unreachable

bb3:                                              ; preds = %bb1
  %iter.01 = extractvalue { i32, i32 } %1, 0
  %iter.12 = extractvalue { i32, i32 } %1, 1
  %_7 = sub i64 %step, 1
  store i32 %iter.01, ptr %_0, align 8
  %8 = getelementptr inbounds i8, ptr %_0, i64 4
  store i32 %iter.12, ptr %8, align 4
  %9 = getelementptr inbounds i8, ptr %_0, i64 8
  store i64 %_7, ptr %9, align 8
  %10 = getelementptr inbounds i8, ptr %_0, i64 16
  store i8 1, ptr %10, align 8
  ret void

bb4:                                              ; preds = %bb5, %bb6
  %11 = load ptr, ptr %0, align 8
  %12 = getelementptr inbounds i8, ptr %0, i64 8
  %13 = load i32, ptr %12, align 8
  %14 = insertvalue { ptr, i32 } poison, ptr %11, 0
  %15 = insertvalue { ptr, i32 } %14, i32 %13, 1
  resume { ptr, i32 } %15

bb5:                                              ; preds = %bb6
  br label %bb4
}

; probe1::probe
; Function Attrs: uwtable
define void @_ZN6probe15probe17h3e90ba54566a0479E() unnamed_addr #1 {
start:
  %_2 = alloca [24 x i8], align 8
  %_1 = alloca [24 x i8], align 8
; call core::iter::traits::iterator::Iterator::step_by
  call void @_ZN4core4iter6traits8iterator8Iterator7step_by17h0bf3d327b836187dE(ptr sret([24 x i8]) align 8 %_2, i32 0, i32 10, i64 2) #5
; call core::iter::traits::iterator::Iterator::rev
  call void @_ZN4core4iter6traits8iterator8Iterator3rev17hb9fc78500eb5bbd5E(ptr sret([24 x i8]) align 8 %_1, ptr align 8 %_2) #5
  ret void
}

; <T as core::iter::adapters::step_by::SpecRangeSetup<T>>::setup
; Function Attrs: inlinehint uwtable
define { i32, i32 } @"_ZN76_$LT$T$u20$as$u20$core..iter..adapters..step_by..SpecRangeSetup$LT$T$GT$$GT$5setup17h60e6c508537daaa1E"(i32 %inner.0, i32 %inner.1, i64 %_step) unnamed_addr #0 {
start:
  %0 = insertvalue { i32, i32 } poison, i32 %inner.0, 0
  %1 = insertvalue { i32, i32 } %0, i32 %inner.1, 1
  ret { i32, i32 } %1
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2

; Function Attrs: nounwind uwtable
declare i32 @rust_eh_personality(i32, i32, i64, ptr, ptr) unnamed_addr #3

; core::panicking::panic
; Function Attrs: cold noinline noreturn uwtable
declare void @_ZN4core9panicking5panic17h30f5ec71e3af4326E(ptr align 1, i64, ptr align 8) unnamed_addr #4

attributes #0 = { inlinehint uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #1 = { uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nounwind uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #4 = { cold noinline noreturn uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #5 = { inlinehint }
attributes #6 = { noreturn }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{!"rustc version 1.93.0 (254b59607 2026-01-19)"}
