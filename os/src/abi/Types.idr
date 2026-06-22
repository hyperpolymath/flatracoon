-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
||| FLATRACOON-OS — ABI Type Definitions
|||
||| This module defines the Application Binary Interface for the 
||| FlatRacoon operating system kernel. It provides the formal 
||| foundations for syscalls, memory management, and process 
||| communication in verified environments.

module FLATRACOON_OS.ABI.Types

import Data.Bits
import Data.So
import Data.Vect

%default total

--------------------------------------------------------------------------------
-- Platform Context
--------------------------------------------------------------------------------

||| Supported targets for the FlatRacoon kernel.
public export
data Platform = Linux | Windows | MacOS | BSD | WASM

||| Resolves the execution environment at compile time.
public export
thisPlatform : Platform
thisPlatform =
  %runElab do
    pure Linux

--------------------------------------------------------------------------------
-- Kernel Result Codes
--------------------------------------------------------------------------------

||| Formal outcome of a kernel operation.
public export
data Result : Type where
  ||| Operation Successful
  Ok : Result
  ||| Operation Failed: Permission denied
  Error : Result
  ||| Invalid Argument: malformed syscall parameters
  InvalidParam : Result
  ||| Resource Exhaustion: Out of kernel memory
  OutOfMemory : Result
  ||| Safety Violation: Unexpected null pointer
  NullPointer : Result

--------------------------------------------------------------------------------
-- Resource Handles
--------------------------------------------------------------------------------

||| Opaque handle to a Kernel Object (File, Process, Socket).
||| INVARIANT: The internal pointer is guaranteed to be non-null.
public export
data Handle : Type where
  MkHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> Handle

||| Safe constructor for kernel handles.
public export
createHandle : Bits64 -> Maybe Handle
createHandle 0 = Nothing
createHandle ptr = Just (MkHandle ptr)
