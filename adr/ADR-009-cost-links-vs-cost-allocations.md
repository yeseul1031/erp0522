# ADR-009: Cost Links and Allocations by ct_type

## Status
Accepted

## Context
비용 원장(`costs`)은 단순하게 유지해야 하지만, 비용이 프로젝트 비용인지 PO 비용인지에 따라 해석 방식이 다르다.
특히 PO는 내부 상품 라인과 특수 비용 라인을 함께 가진 복합 비용 단위이므로 단순 N분할만으로 정산 기준을 만들 수 없다.

## Decision
`costs.ct_type`은 `PROJECT`, `PO`만 사용한다.
- PROJECT 비용은 `project_cost_allocations`로 프로젝트에 금액/세금을 배분한다.
- PO 비용은 `po_cost_links`로 PO와 1:1 연결한다.
- PO 내부 상품 비용은 `po_allocations`의 분배 정보를 활용한다.
- PO 특수 비용 라인은 `po_cost_line_allocations`를 반드시 함께 생성해 프로젝트에 배분한다.

## Consequences
- ORDER_LINES, ORDER_LINE_OVERRIDES, SOURCING_CASES, SOURCING_CASE_LINES에는 비용을 직접 귀속하지 않는다.
- PO 비용은 PO 자체와 연결하되, 세부 해석은 PO 라인/배분/특수 비용 라인 구조를 통해 수행한다.
- `_links`는 열린 관계 표현이고, 수량/금액/실행 귀속은 `_allocations`에서 해석한다.
