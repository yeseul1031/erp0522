# ADR-010: Deprecate Domestic/Overseas VIEW Unification Strategy

## Status
Accepted

## Context
과거에는 국내/해외 분리 테이블을 VIEW로 통합 조회하는 전략을 검토했다.
하지만 정본은 RFQ/PO 단일 테이블이므로 VIEW 전략은 혼동과 유지보수 비용만 증가시킨다.

## Decision
국내/해외 분리 테이블과 이를 VIEW로 통합 조회하는 전략은 폐지한다.
신규 개발/운영은 `rfqs`/`purchase_orders` 단일 체계를 따른다.

## Consequences
- 데이터 모델이 단순해지고 신규 기능 개발이 쉬워진다.
- 운영/리포트/권한 모델에서 불필요한 분기 로직이 줄어든다.
