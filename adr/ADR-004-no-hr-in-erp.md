# ADR-004: ERP Does Not Own HR Data

## Status
Accepted

## Context
직원/조직 정보를 ERP에 포함하면
그룹웨어와의 동기화/정합성 문제가 발생한다.

## Decision
ERP는 직원/조직 정보를 소유하지 않는다.
외부 시스템의 식별자(principal)만 참조한다.

## Consequences
- HR 변경이 ERP 구조에 영향을 주지 않는다.
- 인증/권한은 외부 시스템과 연계한다.
