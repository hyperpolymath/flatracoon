# proven Integration Plan

This document outlines the recommended [proven](https://github.com/hyperpolymath/proven) modules for flatracoon-os.

## Recommended Modules

| Module | Purpose | Priority |
|--------|---------|----------|
| SafeCapability | Capability-based security with delegation proofs for microkernel permissions | High |
| SafeResource | Resource lifecycle with leak prevention for system resources | High |
| SafeStateMachine | State machines with invertibility proofs for container lifecycle | High |

## Integration Notes

flatracoon-os as a Minix-Flatcar hybrid OS requires formally verified security primitives:

- **SafeCapability** is essential for the microkernel's permission model. Capabilities in microkernel architectures must be unforgeable and properly delegated. The `ConfinedCapability` type ensures capabilities cannot leak outside their designated domain, and `attenuate` guarantees permissions can only be reduced.

- **SafeResource** manages system resources (memory, file handles, devices) with linear typing that prevents double-free and use-after-free bugs. The `LeakDetector` tracks acquire/release to prove no leaks occur.

- **SafeStateMachine** models container lifecycle states (created, running, paused, stopped, removed). The `HistoryMachine` enables undo/redo for container operations, and `GuardedTransition` enforces valid state transitions only.

For an immutable OS, these guarantees ensure the core security model cannot be violated even under adversarial conditions.

## Related

- [proven library](https://github.com/hyperpolymath/proven)
- [Idris 2 documentation](https://idris2.readthedocs.io/)
