# ADR-006: Unify RFQ/PO Tables and Lock FX for Overseas Costs

## Status
Accepted

## Context
국내/해외를 분리한 RFQ/PO 테이블은 운영/개발/리포팅 복잡도를 증가시킨다.
해외 비용은 환율 변동이 있으므로 “당시 어떤 환율로 원가를 인식했는지”를 감사/재현 가능하게 남겨야 한다.

## Decision
RFQ와 PO는 단일 테이블 체계로 통일한다.
- RFQ: `rfq_plans` / `rfqp_lines` / `rfqs` / `rfq_lines` / `rfqp_allocations`
- PO: `purchase_orders` / `po_lines` / `po_allocations`

해외 비용은 적용한 환율 스냅샷과 선택 사유를 고정 저장한다.
- 권장: `cost_fx_applications`(+ 필요 시 `fx_rates` 참조)

## Consequences
- 국내/해외 분리 테이블 및 VIEW 통합 전략이 불필요해진다.
- 해외 원가/정산의 재현성과 감사 대응이 쉬워진다.
- 통화/인도조건/국가 등 차이는 옵션 컬럼과 코드북으로 흡수한다.
