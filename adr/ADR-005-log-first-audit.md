# ADR-005: Log-first Auditing

## Status
Accepted

## Context
모든 변경을 강한 FK와 상태 테이블로 관리하면
유연한 운영과 이력 추적이 어려워진다.

## Decision
핵심 변경 이력은 `activity_logs`, `audit_logs`로 추적한다.

## Consequences
- 변경 이력의 가독성과 감사 대응이 개선된다.
- 구조 변경에 대한 유연성이 확보된다.
