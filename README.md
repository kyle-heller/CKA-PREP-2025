# CKA-PREP-2025

17 hands-on CKA practice questions with automated setup, verification, and solve scripts. Designed for [KillerCoda](https://killercoda.com/) CKA playground.

Based on [vj2201/CKA-PREP-2025-v2](https://github.com/vj2201/CKA-PREP-2025-v2) with added `Verify.bash` scripts and automated solve-and-verify pipeline.

## Questions

| # | Topic | Difficulty |
|---|-------|-----------|
| 01 | MariaDB Persistent Volume | Medium |
| 02 | ArgoCD Helm (no CRDs) | Easy |
| 03 | Sidecar Container | Easy |
| 04 | Resource Allocation | Medium |
| 05 | HPA (autoscaling/v2) | Medium |
| 06 | CRDs (cert-manager) | Easy |
| 07 | PriorityClass | Easy |
| 08 | CNI & Network Policy | Easy |
| 09 | CRI-Dockerd + sysctl | Medium |
| 10 | Taints & Tolerations | Easy |
| 11 | Gateway API Migration | Medium |
| 12 | Ingress | Easy |
| 13 | Network Policy (least-permissive) | Medium |
| 14 | StorageClass | Easy |
| 15 | Etcd Fix (API server broken) | Hard |
| 16 | NodePort Service | Easy |
| 17 | TLS Configuration | Medium |

## Directory Structure

```
NN-topic-slug/
├── Questions      # Scenario and task description
├── LabSetUp       # Environment setup script
├── Verify.bash    # Automated verification (PASS/FAIL)
└── SolutionNotes  # Step-by-step solution
```

## Usage

### Practice Mode
```bash
git clone https://github.com/kyle-heller/CKA-PREP-2025.git
cd CKA-PREP-2025
bash scripts/setup-tools.sh              # Install helm, metrics-server
bash 05-hpa/LabSetUp                     # Set up one question
cat 05-hpa/Questions                     # Read the task
# ... solve it yourself ...
bash 05-hpa/Verify.bash                  # Check your answer
cat 05-hpa/SolutionNotes                 # Hints if stuck
```

### Automated Solve + Verify (all 17)
```bash
bash scripts/setup-tools.sh
bash scripts/solve-and-verify.sh 2>&1 | tee /tmp/solve-cka.log
```

### Test All (setup + verify only, no solve)
```bash
bash scripts/test-all.sh
```

## Important Notes

- **Q15 (Etcd Fix)** intentionally breaks the API server during setup. The solve script handles this by fixing Q15 first in Phase 2.
- **Q02** requires Helm — run `scripts/setup-tools.sh` first.
- **Q05** requires metrics-server — also handled by `setup-tools.sh`.
- **Q09** (CRI-Dockerd) is environment-specific; `dpkg` may not work on non-Debian systems.
- **Q08** (CNI) is a no-op on KillerCoda (Cilium pre-installed).

## Credits

Original questions: [vj2201/CKA-PREP-2025-v2](https://github.com/vj2201/CKA-PREP-2025-v2)
