; ModuleID = 'probe1.ba0a74ba5d6827b6-cgu.0'
source_filename = "probe1.ba0a74ba5d6827b6-cgu.0"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "arm64-apple-macosx11.0.0"

%"core::fmt::rt::Argument<'_>" = type { %"core::fmt::rt::ArgumentType<'_>" }
%"core::fmt::rt::ArgumentType<'_>" = type { ptr, [1 x i64] }

@alloc_bd3468a7b96187f70c1ce98a3e7a63bf = private unnamed_addr constant [283 x i8] c"unsafe precondition(s) violated: ptr::copy_nonoverlapping requires that both pointer arguments are aligned and non-null and the specified memory ranges do not overlap\0A\0AThis indicates a bug in the program. This Undefined Behavior check is optional, and cannot be relied on for safety.", align 1
@alloc_fad0cd83b7d1858a846a172eb260e593 = private unnamed_addr constant [42 x i8] c"is_aligned_to: align is not a power-of-two", align 1
@alloc_cbd398386c6b0a68e4d4318f6cb32319 = private unnamed_addr constant [113 x i8] c"/Users/ble/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/src/rust/library/core/src/ptr/const_ptr.rs\00", align 1
@alloc_6a4a6b457dc1cdd7f6c763de66db622f = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_cbd398386c6b0a68e4d4318f6cb32319, [16 x i8] c"p\00\00\00\00\00\00\00^\05\00\00\0D\00\00\00" }>, align 8
@alloc_64e308ef4babfeb8b6220184de794a17 = private unnamed_addr constant [221 x i8] c"unsafe precondition(s) violated: hint::assert_unchecked must never be called when the condition is false\0A\0AThis indicates a bug in the program. This Undefined Behavior check is optional, and cannot be relied on for safety.", align 1
@alloc_40c34489c87265628fd02c341c4a8f6a = private unnamed_addr constant [109 x i8] c"/Users/ble/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/src/rust/library/core/src/ub_checks.rs\00", align 1
@alloc_666c40b61d5c18b67fc5688955d7b67b = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_40c34489c87265628fd02c341c4a8f6a, [16 x i8] c"l\00\00\00\00\00\00\00\95\00\00\006\00\00\00" }>, align 8
@alloc_a28e8c8fd5088943a8b5d44af697ff83 = private unnamed_addr constant [279 x i8] c"unsafe precondition(s) violated: slice::from_raw_parts requires the pointer to be aligned and non-null, and the total size of the slice not to exceed `isize::MAX`\0A\0AThis indicates a bug in the program. This Undefined Behavior check is optional, and cannot be relied on for safety.", align 1
@alloc_763310d78c99c2c1ad3f8a9821e942f3 = private unnamed_addr constant [61 x i8] c"is_nonoverlapping: `size_of::<T>() * count` overflows a usize", align 1
@anon.deb8a73e04addbcadd00c269c165d9cc.0 = private unnamed_addr constant <{ [8 x i8], [8 x i8] }> <{ [8 x i8] zeroinitializer, [8 x i8] undef }>, align 8
@alloc_94241b918ecfae462341212fdf9148aa = private unnamed_addr constant [107 x i8] c"/Users/ble/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/src/rust/library/core/src/fmt/mod.rs\00", align 1
@alloc_926b3f7f07a38b77d0db47879e6e54ef = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_94241b918ecfae462341212fdf9148aa, [16 x i8] c"j\00\00\00\00\00\00\00q\03\00\00*\00\00\00" }>, align 8
@alloc_57d70e9d94c65ecfc15225d29a5ed72b = private unnamed_addr constant [198 x i8] c"unsafe precondition(s) violated: Vec::set_len requires that new_len <= capacity()\0A\0AThis indicates a bug in the program. This Undefined Behavior check is optional, and cannot be relied on for safety.", align 1
@alloc_257121d86c9619543ca2906c8740cb5b = private unnamed_addr constant [112 x i8] c"/Users/ble/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/src/rust/library/alloc/src/raw_vec/mod.rs\00", align 1
@alloc_bee8340bbc8d04815cb58245841e2079 = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_257121d86c9619543ca2906c8740cb5b, [16 x i8] c"o\00\00\00\00\00\00\00\A7\01\00\00\15\00\00\00" }>, align 8
@alloc_53973d2fe29b4adba8bb7390b5678745 = private unnamed_addr constant [8 x i8] zeroinitializer, align 8
@alloc_0c812808379efded5a4fb82d2790b556 = private unnamed_addr constant [2 x i8] c"\C0\00", align 1
@alloc_91f5359e86b0394ca912e4171d069d42 = private unnamed_addr constant [107 x i8] c"/Users/ble/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/src/rust/library/core/src/ptr/mod.rs\00", align 1
@alloc_3b9b57c28ca22a71154ff56761ba7f2c = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_91f5359e86b0394ca912e4171d069d42, [16 x i8] c"j\00\00\00\00\00\00\00\0F\02\00\00\05\00\00\00" }>, align 8
@alloc_8c302b8f8c2a085c393b91dc86cfc545 = private unnamed_addr constant [108 x i8] c"/Users/ble/.rustup/toolchains/stable-aarch64-apple-darwin/lib/rustlib/src/rust/library/alloc/src/vec/mod.rs\00", align 1
@alloc_642343cadec7ff6b7192aad9b90419fb = private unnamed_addr constant <{ ptr, [16 x i8] }> <{ ptr @alloc_8c302b8f8c2a085c393b91dc86cfc545, [16 x i8] c"k\00\00\00\00\00\00\00\95\07\00\00\09\00\00\00" }>, align 8

; core::intrinsics::cold_path
; Function Attrs: cold nounwind uwtable
define internal void @_ZN4core10intrinsics9cold_path17h2efd440330ec5f5bE() unnamed_addr #0 {
start:
  ret void
}

; core::fmt::rt::Argument::new_lower_exp
; Function Attrs: inlinehint uwtable
define void @_ZN4core3fmt2rt8Argument13new_lower_exp17h74822e2b5b63e4b3E(ptr sret([16 x i8]) align 8 %_0, ptr align 8 %x) unnamed_addr #1 {
start:
  %_2 = alloca [16 x i8], align 8
  store ptr %x, ptr %_2, align 8
  %0 = getelementptr inbounds i8, ptr %_2, i64 8
  store ptr @"_ZN4core3fmt3num3imp55_$LT$impl$u20$core..fmt..LowerExp$u20$for$u20$isize$GT$3fmt17hbffe55f61e6a73c4E", ptr %0, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %_0, ptr align 8 %_2, i64 16, i1 false)
  ret void
}

; core::fmt::Arguments::new
; Function Attrs: inlinehint uwtable
define { ptr, ptr } @_ZN4core3fmt9Arguments3new17h05a88ec119fec3c5E(ptr align 1 %template, ptr align 8 %args) unnamed_addr #1 {
start:
  %0 = insertvalue { ptr, ptr } poison, ptr %template, 0
  %1 = insertvalue { ptr, ptr } %0, ptr %args, 1
  ret { ptr, ptr } %1
}

; core::ops::function::FnOnce::call_once
; Function Attrs: inlinehint uwtable
define internal void @_ZN4core3ops8function6FnOnce9call_once17h0649bf2a3f18452aE(ptr sret([24 x i8]) align 8 %_0, ptr align 1 %0, i64 %1) unnamed_addr #1 {
start:
  %_2 = alloca [16 x i8], align 8
  store ptr %0, ptr %_2, align 8
  %2 = getelementptr inbounds i8, ptr %_2, i64 8
  store i64 %1, ptr %2, align 8
  %3 = load ptr, ptr %_2, align 8
  %4 = getelementptr inbounds i8, ptr %_2, i64 8
  %5 = load i64, ptr %4, align 8
; call alloc::str::<impl alloc::borrow::ToOwned for str>::to_owned
  call void @"_ZN5alloc3str56_$LT$impl$u20$alloc..borrow..ToOwned$u20$for$u20$str$GT$8to_owned17hf453bc955b5b5d45E"(ptr sret([24 x i8]) align 8 %_0, ptr align 1 %3, i64 %5) #11
  ret void
}

; core::ptr::copy_nonoverlapping::precondition_check
; Function Attrs: inlinehint nounwind uwtable
define internal void @_ZN4core3ptr19copy_nonoverlapping18precondition_check17h345c7a1f60ff3c55E(ptr %src, ptr %dst, i64 %size, i64 %align, i64 %count, ptr align 8 %0) unnamed_addr #2 personality ptr @rust_eh_personality {
start:
  %zero_size = alloca [1 x i8], align 1
  %_8 = icmp eq i64 %count, 0
  br i1 %_8, label %bb1, label %bb2

bb2:                                              ; preds = %start
  %1 = icmp eq i64 %size, 0
  %2 = zext i1 %1 to i8
  store i8 %2, ptr %zero_size, align 1
  br label %bb3

bb1:                                              ; preds = %start
  store i8 1, ptr %zero_size, align 1
  br label %bb3

bb3:                                              ; preds = %bb1, %bb2
  %3 = load i8, ptr %zero_size, align 1
  %is_zst = trunc nuw i8 %3 to i1
; invoke core::ptr::const_ptr::<impl *const T>::is_aligned_to
  %_16 = invoke zeroext i1 @"_ZN4core3ptr9const_ptr33_$LT$impl$u20$$BP$const$u20$T$GT$13is_aligned_to17h99e5ba77e3b78438E"(ptr %src, i64 %align)
          to label %bb15 unwind label %terminate

terminate:                                        ; preds = %bb5, %bb4, %bb3
  %4 = landingpad { ptr, i32 }
          filter [0 x ptr] zeroinitializer
; call core::panicking::panic_cannot_unwind
  call void @_ZN4core9panicking19panic_cannot_unwind17h3992364626a126abE() #12
  unreachable

bb15:                                             ; preds = %bb3
  br i1 %_16, label %bb11, label %bb12

bb12:                                             ; preds = %bb15
  br label %bb7

bb11:                                             ; preds = %bb15
  br i1 %is_zst, label %bb13, label %bb14

bb7:                                              ; preds = %bb14, %bb12
  br label %bb8

bb14:                                             ; preds = %bb11
  %_18 = ptrtoint ptr %src to i64
  %_17 = icmp eq i64 %_18, 0
  %_9 = xor i1 %_17, true
  br i1 %_9, label %bb4, label %bb7

bb13:                                             ; preds = %bb11
  br label %bb4

bb4:                                              ; preds = %bb13, %bb14
; invoke core::ptr::const_ptr::<impl *const T>::is_aligned_to
  %_19 = invoke zeroext i1 @"_ZN4core3ptr9const_ptr33_$LT$impl$u20$$BP$const$u20$T$GT$13is_aligned_to17h99e5ba77e3b78438E"(ptr %dst, i64 %align)
          to label %bb20 unwind label %terminate

bb8:                                              ; preds = %bb6, %bb7
  br label %bb9

bb20:                                             ; preds = %bb4
  br i1 %_19, label %bb16, label %bb17

bb17:                                             ; preds = %bb20
  br label %bb6

bb16:                                             ; preds = %bb20
  %5 = load i8, ptr %zero_size, align 1
  %6 = trunc nuw i8 %5 to i1
  br i1 %6, label %bb18, label %bb19

bb6:                                              ; preds = %bb19, %bb17
  br label %bb8

bb19:                                             ; preds = %bb16
  %_21 = ptrtoint ptr %dst to i64
  %_20 = icmp eq i64 %_21, 0
  %_11 = xor i1 %_20, true
  br i1 %_11, label %bb5, label %bb6

bb18:                                             ; preds = %bb16
  br label %bb5

bb5:                                              ; preds = %bb18, %bb19
; invoke core::ub_checks::maybe_is_nonoverlapping::runtime
  %_6 = invoke zeroext i1 @_ZN4core9ub_checks23maybe_is_nonoverlapping7runtime17h13561c9d419c26dcE(ptr %src, ptr %dst, i64 %size, i64 %count)
          to label %bb21 unwind label %terminate

bb9:                                              ; preds = %bb21, %bb8
; call core::panicking::panic_nounwind_fmt
  call void @_ZN4core9panicking18panic_nounwind_fmt17hbf0afcf6d5b364a7E(ptr @alloc_bd3468a7b96187f70c1ce98a3e7a63bf, ptr inttoptr (i64 567 to ptr), i1 zeroext false, ptr align 8 %0) #13
  unreachable

bb21:                                             ; preds = %bb5
  br i1 %_6, label %bb10, label %bb9

bb10:                                             ; preds = %bb21
  ret void
}

; core::ptr::drop_in_place<alloc::string::String>
; Function Attrs: uwtable
define void @"_ZN4core3ptr42drop_in_place$LT$alloc..string..String$GT$17h14cbda5c52f7bda6E"(ptr align 8 %_1) unnamed_addr #3 {
start:
; call core::ptr::drop_in_place<alloc::vec::Vec<u8>>
  call void @"_ZN4core3ptr46drop_in_place$LT$alloc..vec..Vec$LT$u8$GT$$GT$17h462aa23f37bf4a9cE"(ptr align 8 %_1)
  ret void
}

; core::ptr::drop_in_place<alloc::vec::Vec<u8>>
; Function Attrs: uwtable
define void @"_ZN4core3ptr46drop_in_place$LT$alloc..vec..Vec$LT$u8$GT$$GT$17h462aa23f37bf4a9cE"(ptr align 8 %_1) unnamed_addr #3 personality ptr @rust_eh_personality {
start:
  %0 = alloca [16 x i8], align 8
; invoke <alloc::vec::Vec<T,A> as core::ops::drop::Drop>::drop
  invoke void @"_ZN70_$LT$alloc..vec..Vec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17hffe18edb8ecf86cfE"(ptr align 8 %_1)
          to label %bb4 unwind label %cleanup

bb3:                                              ; preds = %cleanup
; invoke core::ptr::drop_in_place<alloc::raw_vec::RawVec<u8>>
  invoke void @"_ZN4core3ptr53drop_in_place$LT$alloc..raw_vec..RawVec$LT$u8$GT$$GT$17h8ba5ae48934defc9E"(ptr align 8 %_1) #14
          to label %bb1 unwind label %terminate

cleanup:                                          ; preds = %start
  %1 = landingpad { ptr, i32 }
          cleanup
  %2 = extractvalue { ptr, i32 } %1, 0
  %3 = extractvalue { ptr, i32 } %1, 1
  store ptr %2, ptr %0, align 8
  %4 = getelementptr inbounds i8, ptr %0, i64 8
  store i32 %3, ptr %4, align 8
  br label %bb3

bb4:                                              ; preds = %start
; call core::ptr::drop_in_place<alloc::raw_vec::RawVec<u8>>
  call void @"_ZN4core3ptr53drop_in_place$LT$alloc..raw_vec..RawVec$LT$u8$GT$$GT$17h8ba5ae48934defc9E"(ptr align 8 %_1)
  ret void

terminate:                                        ; preds = %bb3
  %5 = landingpad { ptr, i32 }
          filter [0 x ptr] zeroinitializer
; call core::panicking::panic_in_cleanup
  call void @_ZN4core9panicking16panic_in_cleanup17h7835a2d0cfa083fcE() #12
  unreachable

bb1:                                              ; preds = %bb3
  %6 = load ptr, ptr %0, align 8
  %7 = getelementptr inbounds i8, ptr %0, i64 8
  %8 = load i32, ptr %7, align 8
  %9 = insertvalue { ptr, i32 } poison, ptr %6, 0
  %10 = insertvalue { ptr, i32 } %9, i32 %8, 1
  resume { ptr, i32 } %10
}

; core::ptr::drop_in_place<alloc::raw_vec::RawVec<u8>>
; Function Attrs: uwtable
define void @"_ZN4core3ptr53drop_in_place$LT$alloc..raw_vec..RawVec$LT$u8$GT$$GT$17h8ba5ae48934defc9E"(ptr align 8 %_1) unnamed_addr #3 {
start:
; call <alloc::raw_vec::RawVec<T,A> as core::ops::drop::Drop>::drop
  call void @"_ZN77_$LT$alloc..raw_vec..RawVec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17hac12640c2bc2078eE"(ptr align 8 %_1)
  ret void
}

; core::ptr::const_ptr::<impl *const T>::is_aligned_to
; Function Attrs: inlinehint uwtable
define zeroext i1 @"_ZN4core3ptr9const_ptr33_$LT$impl$u20$$BP$const$u20$T$GT$13is_aligned_to17h99e5ba77e3b78438E"(ptr %self, i64 %align) unnamed_addr #1 {
start:
  %0 = alloca [4 x i8], align 4
  %1 = call i64 @llvm.ctpop.i64(i64 %align)
  %2 = trunc i64 %1 to i32
  store i32 %2, ptr %0, align 4
  %_9 = load i32, ptr %0, align 4
  %_3 = icmp eq i32 %_9, 1
  br i1 %_3, label %bb1, label %bb2

bb2:                                              ; preds = %start
; call core::panicking::panic_fmt
  call void @_ZN4core9panicking9panic_fmt17h6f8816b337451651E(ptr @alloc_fad0cd83b7d1858a846a172eb260e593, ptr inttoptr (i64 85 to ptr), ptr align 8 @alloc_6a4a6b457dc1cdd7f6c763de66db622f) #15
  unreachable

bb1:                                              ; preds = %start
  %_7 = ptrtoint ptr %self to i64
  %_8 = sub i64 %align, 1
  %_6 = and i64 %_7, %_8
  %_0 = icmp eq i64 %_6, 0
  ret i1 %_0
}

; core::hint::assert_unchecked::precondition_check
; Function Attrs: inlinehint nounwind uwtable
define internal void @_ZN4core4hint16assert_unchecked18precondition_check17h355d2191642b2d78E(i1 zeroext %cond, ptr align 8 %0) unnamed_addr #2 {
start:
  br i1 %cond, label %bb2, label %bb1

bb1:                                              ; preds = %start
; call core::panicking::panic_nounwind_fmt
  call void @_ZN4core9panicking18panic_nounwind_fmt17hbf0afcf6d5b364a7E(ptr @alloc_64e308ef4babfeb8b6220184de794a17, ptr inttoptr (i64 443 to ptr), i1 zeroext false, ptr align 8 %0) #13
  unreachable

bb2:                                              ; preds = %start
  ret void
}

; core::slice::raw::from_raw_parts::precondition_check
; Function Attrs: inlinehint nounwind uwtable
define internal void @_ZN4core5slice3raw14from_raw_parts18precondition_check17he04f8efbde43ed8fE(ptr %data, i64 %size, i64 %align, i64 %len, ptr align 8 %0) unnamed_addr #2 personality ptr @rust_eh_personality {
start:
  %max_len = alloca [8 x i8], align 8
; invoke core::ptr::const_ptr::<impl *const T>::is_aligned_to
  %_11 = invoke zeroext i1 @"_ZN4core3ptr9const_ptr33_$LT$impl$u20$$BP$const$u20$T$GT$13is_aligned_to17h99e5ba77e3b78438E"(ptr %data, i64 %align)
          to label %bb8 unwind label %terminate

terminate:                                        ; preds = %panic, %start
  %1 = landingpad { ptr, i32 }
          filter [0 x ptr] zeroinitializer
; call core::panicking::panic_cannot_unwind
  call void @_ZN4core9panicking19panic_cannot_unwind17h3992364626a126abE() #12
  unreachable

bb8:                                              ; preds = %start
  br i1 %_11, label %bb6, label %bb7

bb7:                                              ; preds = %bb8
  br label %bb4

bb6:                                              ; preds = %bb8
  %_13 = ptrtoint ptr %data to i64
  %_12 = icmp eq i64 %_13, 0
  %_5 = xor i1 %_12, true
  br i1 %_5, label %bb1, label %bb4

bb4:                                              ; preds = %bb6, %bb7
  br label %bb5

bb1:                                              ; preds = %bb6
  %_15 = icmp eq i64 %size, 0
  br i1 %_15, label %bb9, label %bb10

bb5:                                              ; preds = %bb3, %bb4
; call core::panicking::panic_nounwind_fmt
  call void @_ZN4core9panicking18panic_nounwind_fmt17hbf0afcf6d5b364a7E(ptr @alloc_a28e8c8fd5088943a8b5d44af697ff83, ptr inttoptr (i64 559 to ptr), i1 zeroext false, ptr align 8 %0) #13
  unreachable

bb10:                                             ; preds = %bb1
  br i1 %_15, label %panic, label %bb11

bb9:                                              ; preds = %bb1
  store i64 -1, ptr %max_len, align 8
  br label %bb12

bb11:                                             ; preds = %bb10
  %2 = udiv i64 9223372036854775807, %size
  store i64 %2, ptr %max_len, align 8
  br label %bb12

panic:                                            ; preds = %bb10
; invoke core::panicking::panic_const::panic_const_div_by_zero
  invoke void @_ZN4core9panicking11panic_const23panic_const_div_by_zero17hb1dd333295147004E(ptr align 8 @alloc_666c40b61d5c18b67fc5688955d7b67b) #16
          to label %unreachable unwind label %terminate

unreachable:                                      ; preds = %panic
  unreachable

bb12:                                             ; preds = %bb9, %bb11
  %3 = load i64, ptr %max_len, align 8
  %_7 = icmp ule i64 %len, %3
  br i1 %_7, label %bb2, label %bb3

bb3:                                              ; preds = %bb12
  br label %bb5

bb2:                                              ; preds = %bb12
  ret void
}

; core::option::Option<T>::map_or_else
; Function Attrs: inlinehint uwtable
define void @"_ZN4core6option15Option$LT$T$GT$11map_or_else17h3f8f380a3ac03d6dE"(ptr sret([24 x i8]) align 8 %_0, ptr align 1 %0, i64 %1, ptr align 8 %default) unnamed_addr #1 personality ptr @rust_eh_personality {
start:
  %2 = alloca [16 x i8], align 8
  %_10 = alloca [1 x i8], align 1
  %_9 = alloca [1 x i8], align 1
  %self = alloca [16 x i8], align 8
  store ptr %0, ptr %self, align 8
  %3 = getelementptr inbounds i8, ptr %self, i64 8
  store i64 %1, ptr %3, align 8
  store i8 1, ptr %_10, align 1
  store i8 1, ptr %_9, align 1
  %4 = load ptr, ptr %self, align 8
  %5 = getelementptr inbounds i8, ptr %self, i64 8
  %6 = load i64, ptr %5, align 8
  %7 = ptrtoint ptr %4 to i64
  %8 = icmp eq i64 %7, 0
  %_4 = select i1 %8, i64 0, i64 1
  %9 = trunc nuw i64 %_4 to i1
  br i1 %9, label %bb3, label %bb2

bb3:                                              ; preds = %start
  %t.0 = load ptr, ptr %self, align 8
  %10 = getelementptr inbounds i8, ptr %self, i64 8
  %t.1 = load i64, ptr %10, align 8
  store i8 0, ptr %_9, align 1
; invoke core::ops::function::FnOnce::call_once
  invoke void @_ZN4core3ops8function6FnOnce9call_once17h0649bf2a3f18452aE(ptr sret([24 x i8]) align 8 %_0, ptr align 1 %t.0, i64 %t.1)
          to label %bb4 unwind label %cleanup

bb2:                                              ; preds = %start
  store i8 0, ptr %_10, align 1
; invoke alloc::fmt::format::{{closure}}
  invoke void @"_ZN5alloc3fmt6format28_$u7b$$u7b$closure$u7d$$u7d$17h692f8f5a1f15e4eeE"(ptr sret([24 x i8]) align 8 %_0, ptr align 8 %default)
          to label %bb5 unwind label %cleanup

bb10:                                             ; preds = %cleanup
  %11 = load i8, ptr %_9, align 1
  %12 = trunc nuw i8 %11 to i1
  br i1 %12, label %bb9, label %bb7

cleanup:                                          ; preds = %bb3, %bb2
  %13 = landingpad { ptr, i32 }
          cleanup
  %14 = extractvalue { ptr, i32 } %13, 0
  %15 = extractvalue { ptr, i32 } %13, 1
  store ptr %14, ptr %2, align 8
  %16 = getelementptr inbounds i8, ptr %2, i64 8
  store i32 %15, ptr %16, align 8
  br label %bb10

bb5:                                              ; preds = %bb2
  br label %bb6

bb6:                                              ; preds = %bb4, %bb5
  ret void

bb4:                                              ; preds = %bb3
  br label %bb6

bb7:                                              ; preds = %bb9, %bb10
  %17 = load i8, ptr %_10, align 1
  %18 = trunc nuw i8 %17 to i1
  br i1 %18, label %bb11, label %bb8

bb9:                                              ; preds = %bb10
  br label %bb7

bb8:                                              ; preds = %bb11, %bb7
  %19 = load ptr, ptr %2, align 8
  %20 = getelementptr inbounds i8, ptr %2, i64 8
  %21 = load i32, ptr %20, align 8
  %22 = insertvalue { ptr, i32 } poison, ptr %19, 0
  %23 = insertvalue { ptr, i32 } %22, i32 %21, 1
  resume { ptr, i32 } %23

bb11:                                             ; preds = %bb7
  br label %bb8

bb1:                                              ; No predecessors!
  unreachable
}

; core::ub_checks::maybe_is_nonoverlapping::runtime
; Function Attrs: inlinehint uwtable
define internal zeroext i1 @_ZN4core9ub_checks23maybe_is_nonoverlapping7runtime17h13561c9d419c26dcE(ptr %src, ptr %dst, i64 %size, i64 %count) unnamed_addr #1 {
start:
  %diff = alloca [8 x i8], align 8
  %_9 = alloca [16 x i8], align 8
  %src_usize = ptrtoint ptr %src to i64
  %dst_usize = ptrtoint ptr %dst to i64
  %0 = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %size, i64 %count)
  %_13.0 = extractvalue { i64, i1 } %0, 0
  %_13.1 = extractvalue { i64, i1 } %0, 1
  br i1 %_13.1, label %bb1, label %bb3

bb3:                                              ; preds = %start
  %1 = getelementptr inbounds i8, ptr %_9, i64 8
  store i64 %_13.0, ptr %1, align 8
  store i64 1, ptr %_9, align 8
  %2 = getelementptr inbounds i8, ptr %_9, i64 8
  %size1 = load i64, ptr %2, align 8
  %_21 = icmp ult i64 %src_usize, %dst_usize
  br i1 %_21, label %bb4, label %bb5

bb1:                                              ; preds = %start
; call core::panicking::panic_nounwind
  call void @_ZN4core9panicking14panic_nounwind17h7d65473595109eb7E(ptr align 1 @alloc_763310d78c99c2c1ad3f8a9821e942f3, i64 61) #13
  unreachable

bb5:                                              ; preds = %bb3
  %3 = sub i64 %src_usize, %dst_usize
  store i64 %3, ptr %diff, align 8
  br label %bb6

bb4:                                              ; preds = %bb3
  %4 = sub i64 %dst_usize, %src_usize
  store i64 %4, ptr %diff, align 8
  br label %bb6

bb6:                                              ; preds = %bb4, %bb5
  %5 = load i64, ptr %diff, align 8
  %_0 = icmp uge i64 %5, %size1
  ret i1 %_0
}

; alloc::fmt::format
; Function Attrs: inlinehint uwtable
define internal void @_ZN5alloc3fmt6format17he5d2bcc550a478ffE(ptr sret([24 x i8]) align 8 %_0, ptr %0, ptr %1) unnamed_addr #1 {
start:
  %_2 = alloca [16 x i8], align 8
  %args = alloca [16 x i8], align 8
  store ptr %0, ptr %args, align 8
  %2 = getelementptr inbounds i8, ptr %args, i64 8
  store ptr %1, ptr %2, align 8
  %3 = getelementptr inbounds i8, ptr %args, i64 8
  %_7 = load ptr, ptr %3, align 8
  %bits = ptrtoint ptr %_7 to i64
  %_9 = and i64 %bits, 1
  %_8 = icmp eq i64 %_9, 1
  br i1 %_8, label %bb2, label %bb3

bb3:                                              ; preds = %start
  %4 = load ptr, ptr @anon.deb8a73e04addbcadd00c269c165d9cc.0, align 8
  %5 = load i64, ptr getelementptr inbounds (i8, ptr @anon.deb8a73e04addbcadd00c269c165d9cc.0, i64 8), align 8
  store ptr %4, ptr %_2, align 8
  %6 = getelementptr inbounds i8, ptr %_2, i64 8
  store i64 %5, ptr %6, align 8
  br label %bb4

bb2:                                              ; preds = %start
  %self = load ptr, ptr %args, align 8
  %len = lshr i64 %bits, 1
  br label %bb5

bb4:                                              ; preds = %bb7, %bb3
  %7 = load ptr, ptr %_2, align 8
  %8 = getelementptr inbounds i8, ptr %_2, i64 8
  %9 = load i64, ptr %8, align 8
; call core::option::Option<T>::map_or_else
  call void @"_ZN4core6option15Option$LT$T$GT$11map_or_else17h3f8f380a3ac03d6dE"(ptr sret([24 x i8]) align 8 %_0, ptr align 1 %7, i64 %9, ptr align 8 %args) #11
  ret void

bb5:                                              ; preds = %bb2
; call core::slice::raw::from_raw_parts::precondition_check
  call void @_ZN4core5slice3raw14from_raw_parts18precondition_check17he04f8efbde43ed8fE(ptr %self, i64 1, i64 1, i64 %len, ptr align 8 @alloc_926b3f7f07a38b77d0db47879e6e54ef) #17
  br label %bb7

bb7:                                              ; preds = %bb5
  store ptr %self, ptr %_2, align 8
  %10 = getelementptr inbounds i8, ptr %_2, i64 8
  store i64 %len, ptr %10, align 8
  br label %bb4
}

; alloc::fmt::format::{{closure}}
; Function Attrs: inlinehint uwtable
define void @"_ZN5alloc3fmt6format28_$u7b$$u7b$closure$u7d$$u7d$17h692f8f5a1f15e4eeE"(ptr sret([24 x i8]) align 8 %_0, ptr align 8 %_1) unnamed_addr #1 {
start:
  %_2.0 = load ptr, ptr %_1, align 8
  %0 = getelementptr inbounds i8, ptr %_1, i64 8
  %_2.1 = load ptr, ptr %0, align 8
; call alloc::fmt::format::format_inner
  call void @_ZN5alloc3fmt6format12format_inner17h63985d1d6aa0fe33E(ptr sret([24 x i8]) align 8 %_0, ptr %_2.0, ptr %_2.1)
  ret void
}

; alloc::str::<impl alloc::borrow::ToOwned for str>::to_owned
; Function Attrs: inlinehint uwtable
define internal void @"_ZN5alloc3str56_$LT$impl$u20$alloc..borrow..ToOwned$u20$for$u20$str$GT$8to_owned17hf453bc955b5b5d45E"(ptr sret([24 x i8]) align 8 %_0, ptr align 1 %self.0, i64 %self.1) unnamed_addr #1 {
start:
  %bytes = alloca [24 x i8], align 8
; call <T as alloc::slice::<impl [T]>::to_vec_in::ConvertVec>::to_vec
  call void @"_ZN87_$LT$T$u20$as$u20$alloc..slice..$LT$impl$u20$$u5b$T$u5d$$GT$..to_vec_in..ConvertVec$GT$6to_vec17h94c785aff666a765E"(ptr sret([24 x i8]) align 8 %bytes, ptr align 1 %self.0, i64 %self.1) #11
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %_0, ptr align 8 %bytes, i64 24, i1 false)
  ret void
}

; alloc::vec::Vec<T,A>::set_len::precondition_check
; Function Attrs: inlinehint nounwind uwtable
define internal void @"_ZN5alloc3vec16Vec$LT$T$C$A$GT$7set_len18precondition_check17h5a9e23f48c4d7eecE"(i64 %new_len, i64 %capacity, ptr align 8 %0) unnamed_addr #2 {
start:
  %_3 = icmp ule i64 %new_len, %capacity
  br i1 %_3, label %bb1, label %bb2

bb2:                                              ; preds = %start
; call core::panicking::panic_nounwind_fmt
  call void @_ZN4core9panicking18panic_nounwind_fmt17hbf0afcf6d5b364a7E(ptr @alloc_57d70e9d94c65ecfc15225d29a5ed72b, ptr inttoptr (i64 397 to ptr), i1 zeroext false, ptr align 8 %0) #13
  unreachable

bb1:                                              ; preds = %start
  ret void
}

; alloc::raw_vec::RawVecInner<A>::with_capacity_in
; Function Attrs: inlinehint uwtable
define { i64, ptr } @"_ZN5alloc7raw_vec20RawVecInner$LT$A$GT$16with_capacity_in17hcebbc5940b23c926E"(i64 %capacity, i64 %elem_layout.0, i64 %elem_layout.1) unnamed_addr #1 {
start:
  %self = alloca [8 x i8], align 8
  %_4 = alloca [24 x i8], align 8
; call alloc::raw_vec::RawVecInner<A>::try_allocate_in
  call void @"_ZN5alloc7raw_vec20RawVecInner$LT$A$GT$15try_allocate_in17h1c92bab4ce562b87E"(ptr sret([24 x i8]) align 8 %_4, i64 %capacity, i1 zeroext false, i64 %elem_layout.0, i64 %elem_layout.1)
  %_5 = load i64, ptr %_4, align 8
  %0 = trunc nuw i64 %_5 to i1
  br i1 %0, label %bb3, label %bb4

bb3:                                              ; preds = %start
  %1 = getelementptr inbounds i8, ptr %_4, i64 8
  %err.0 = load i64, ptr %1, align 8
  %2 = getelementptr inbounds i8, ptr %1, i64 8
  %err.1 = load i64, ptr %2, align 8
; call alloc::raw_vec::handle_error
  call void @_ZN5alloc7raw_vec12handle_error17he4f6e0c101caed0fE(i64 %err.0, i64 %err.1) #16
  unreachable

bb4:                                              ; preds = %start
  %3 = getelementptr inbounds i8, ptr %_4, i64 8
  %this.0 = load i64, ptr %3, align 8
  %4 = getelementptr inbounds i8, ptr %3, i64 8
  %this.1 = load ptr, ptr %4, align 8
  %_15 = icmp eq i64 %elem_layout.1, 0
  br i1 %_15, label %bb5, label %bb6

bb6:                                              ; preds = %bb4
  store i64 %this.0, ptr %self, align 8
  br label %bb7

bb5:                                              ; preds = %bb4
  store i64 -1, ptr %self, align 8
  br label %bb7

bb7:                                              ; preds = %bb5, %bb6
  %5 = load i64, ptr %self, align 8
  %_11 = sub i64 %5, 0
  %_7 = icmp ugt i64 %capacity, %_11
  %cond = xor i1 %_7, true
  br label %bb8

bb8:                                              ; preds = %bb7
; call core::hint::assert_unchecked::precondition_check
  call void @_ZN4core4hint16assert_unchecked18precondition_check17h355d2191642b2d78E(i1 zeroext %cond, ptr align 8 @alloc_bee8340bbc8d04815cb58245841e2079) #17
  br label %bb9

bb9:                                              ; preds = %bb8
  %6 = insertvalue { i64, ptr } poison, i64 %this.0, 0
  %7 = insertvalue { i64, ptr } %6, ptr %this.1, 1
  ret { i64, ptr } %7

bb2:                                              ; No predecessors!
  unreachable
}

; probe1::probe
; Function Attrs: uwtable
define void @_ZN6probe15probe17h3e90ba54566a0479E() unnamed_addr #3 {
start:
  %_7 = alloca [16 x i8], align 8
  %args = alloca [16 x i8], align 8
  %_2 = alloca [24 x i8], align 8
  %_1 = alloca [24 x i8], align 8
; call core::fmt::rt::Argument::new_lower_exp
  call void @_ZN4core3fmt2rt8Argument13new_lower_exp17h74822e2b5b63e4b3E(ptr sret([16 x i8]) align 8 %_7, ptr align 8 @alloc_53973d2fe29b4adba8bb7390b5678745) #11
  %0 = getelementptr inbounds nuw %"core::fmt::rt::Argument<'_>", ptr %args, i64 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %_7, i64 16, i1 false)
; call core::fmt::Arguments::new
  %1 = call { ptr, ptr } @_ZN4core3fmt9Arguments3new17h05a88ec119fec3c5E(ptr align 1 @alloc_0c812808379efded5a4fb82d2790b556, ptr align 8 %args) #11
  %_3.0 = extractvalue { ptr, ptr } %1, 0
  %_3.1 = extractvalue { ptr, ptr } %1, 1
; call alloc::fmt::format
  call void @_ZN5alloc3fmt6format17he5d2bcc550a478ffE(ptr sret([24 x i8]) align 8 %_2, ptr %_3.0, ptr %_3.1) #11
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %_1, ptr align 8 %_2, i64 24, i1 false)
; call core::ptr::drop_in_place<alloc::string::String>
  call void @"_ZN4core3ptr42drop_in_place$LT$alloc..string..String$GT$17h14cbda5c52f7bda6E"(ptr align 8 %_1)
  ret void
}

; <T as alloc::slice::<impl [T]>::to_vec_in::ConvertVec>::to_vec
; Function Attrs: inlinehint uwtable
define void @"_ZN87_$LT$T$u20$as$u20$alloc..slice..$LT$impl$u20$$u5b$T$u5d$$GT$..to_vec_in..ConvertVec$GT$6to_vec17h94c785aff666a765E"(ptr sret([24 x i8]) align 8 %v, ptr align 1 %s.0, i64 %s.1) unnamed_addr #1 {
start:
  %_18 = alloca [8 x i8], align 8
; call alloc::raw_vec::RawVecInner<A>::with_capacity_in
  %0 = call { i64, ptr } @"_ZN5alloc7raw_vec20RawVecInner$LT$A$GT$16with_capacity_in17hcebbc5940b23c926E"(i64 %s.1, i64 1, i64 1) #11
  %_10.0 = extractvalue { i64, ptr } %0, 0
  %_10.1 = extractvalue { i64, ptr } %0, 1
  store i64 %_10.0, ptr %v, align 8
  %1 = getelementptr inbounds i8, ptr %v, i64 8
  store ptr %_10.1, ptr %1, align 8
  %2 = getelementptr inbounds i8, ptr %v, i64 16
  store i64 0, ptr %2, align 8
  %3 = getelementptr inbounds i8, ptr %v, i64 8
  %_12 = load ptr, ptr %3, align 8
  br label %bb2

bb2:                                              ; preds = %start
; call core::ptr::copy_nonoverlapping::precondition_check
  call void @_ZN4core3ptr19copy_nonoverlapping18precondition_check17h345c7a1f60ff3c55E(ptr %s.0, ptr %_12, i64 1, i64 1, i64 %s.1, ptr align 8 @alloc_3b9b57c28ca22a71154ff56761ba7f2c) #17
  %4 = mul i64 %s.1, 1
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %_12, ptr align 1 %s.0, i64 %4, i1 false)
  br label %bb7

bb7:                                              ; preds = %bb2
  %self = load i64, ptr %v, align 8
  store i64 %self, ptr %_18, align 8
  br label %bb8

bb8:                                              ; preds = %bb6, %bb7
  %5 = load i64, ptr %_18, align 8
; call alloc::vec::Vec<T,A>::set_len::precondition_check
  call void @"_ZN5alloc3vec16Vec$LT$T$C$A$GT$7set_len18precondition_check17h5a9e23f48c4d7eecE"(i64 %s.1, i64 %5, ptr align 8 @alloc_642343cadec7ff6b7192aad9b90419fb) #17
  br label %bb5

bb6:                                              ; No predecessors!
  store i64 -1, ptr %_18, align 8
  br label %bb8

bb5:                                              ; preds = %bb8
  %6 = getelementptr inbounds i8, ptr %v, i64 16
  store i64 %s.1, ptr %6, align 8
  ret void

bb9:                                              ; No predecessors!
  unreachable
}

; core::fmt::num::imp::<impl core::fmt::LowerExp for isize>::fmt
; Function Attrs: uwtable
declare zeroext i1 @"_ZN4core3fmt3num3imp55_$LT$impl$u20$core..fmt..LowerExp$u20$for$u20$isize$GT$3fmt17hbffe55f61e6a73c4E"(ptr align 8, ptr align 8) unnamed_addr #3

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #4

; Function Attrs: nounwind uwtable
declare i32 @rust_eh_personality(i32, i32, i64, ptr, ptr) unnamed_addr #5

; core::panicking::panic_cannot_unwind
; Function Attrs: cold minsize noinline noreturn nounwind optsize uwtable
declare void @_ZN4core9panicking19panic_cannot_unwind17h3992364626a126abE() unnamed_addr #6

; core::panicking::panic_nounwind_fmt
; Function Attrs: cold noinline noreturn nounwind uwtable
declare void @_ZN4core9panicking18panic_nounwind_fmt17hbf0afcf6d5b364a7E(ptr, ptr, i1 zeroext, ptr align 8) unnamed_addr #7

; <alloc::vec::Vec<T,A> as core::ops::drop::Drop>::drop
; Function Attrs: uwtable
declare void @"_ZN70_$LT$alloc..vec..Vec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17hffe18edb8ecf86cfE"(ptr align 8) unnamed_addr #3

; core::panicking::panic_in_cleanup
; Function Attrs: cold minsize noinline noreturn nounwind optsize uwtable
declare void @_ZN4core9panicking16panic_in_cleanup17h7835a2d0cfa083fcE() unnamed_addr #6

; <alloc::raw_vec::RawVec<T,A> as core::ops::drop::Drop>::drop
; Function Attrs: uwtable
declare void @"_ZN77_$LT$alloc..raw_vec..RawVec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17hac12640c2bc2078eE"(ptr align 8) unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.ctpop.i64(i64) #8

; core::panicking::panic_fmt
; Function Attrs: cold noinline noreturn uwtable
declare void @_ZN4core9panicking9panic_fmt17h6f8816b337451651E(ptr, ptr, ptr align 8) unnamed_addr #9

; core::panicking::panic_const::panic_const_div_by_zero
; Function Attrs: cold noinline noreturn uwtable
declare void @_ZN4core9panicking11panic_const23panic_const_div_by_zero17hb1dd333295147004E(ptr align 8) unnamed_addr #9

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64) #8

; core::panicking::panic_nounwind
; Function Attrs: cold noinline noreturn nounwind uwtable
declare void @_ZN4core9panicking14panic_nounwind17h7d65473595109eb7E(ptr align 1, i64) unnamed_addr #7

; alloc::fmt::format::format_inner
; Function Attrs: uwtable
declare void @_ZN5alloc3fmt6format12format_inner17h63985d1d6aa0fe33E(ptr sret([24 x i8]) align 8, ptr, ptr) unnamed_addr #3

; alloc::raw_vec::RawVecInner<A>::try_allocate_in
; Function Attrs: uwtable
declare void @"_ZN5alloc7raw_vec20RawVecInner$LT$A$GT$15try_allocate_in17h1c92bab4ce562b87E"(ptr sret([24 x i8]) align 8, i64, i1 zeroext, i64, i64) unnamed_addr #3

; alloc::raw_vec::handle_error
; Function Attrs: cold minsize noreturn optsize uwtable
declare void @_ZN5alloc7raw_vec12handle_error17he4f6e0c101caed0fE(i64, i64) unnamed_addr #10

attributes #0 = { cold nounwind uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #1 = { inlinehint uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #2 = { inlinehint nounwind uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #3 = { uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nounwind uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #6 = { cold minsize noinline noreturn nounwind optsize uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #7 = { cold noinline noreturn nounwind uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #8 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #9 = { cold noinline noreturn uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #10 = { cold minsize noreturn optsize uwtable "frame-pointer"="non-leaf" "probe-stack"="inline-asm" "target-cpu"="apple-m1" }
attributes #11 = { inlinehint }
attributes #12 = { cold noreturn nounwind }
attributes #13 = { noinline noreturn nounwind }
attributes #14 = { cold }
attributes #15 = { noinline noreturn }
attributes #16 = { noreturn }
attributes #17 = { inlinehint nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 8, !"PIC Level", i32 2}
!1 = !{!"rustc version 1.93.0 (254b59607 2026-01-19)"}
