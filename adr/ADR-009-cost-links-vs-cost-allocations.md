# ADR-009: Treat *_cost_links as Convenience Links; Cost Allocations are the Accounting Truth

## Status
Accepted

## Context
UI/탐색 편의를 위해 “이 PO/배송/작업에 붙은 비용”을 빠르게 조회해야 한다.
하지만 링크 기반으로 정산 기준을 삼으면 안분/귀속의 정확성이 깨질 수 있다.

## Decision
정산/원가 귀속의 정답은 `cost_allocations`로 고정한다.
조회/분류 편의를 위한 보조 연결은 허용한다.
- `po_cost_links`
- `shipment_cost_links`
- `logistics_job_cost_links`

## Consequences
- 회계/정산 로직은 `cost_allocations`만 보면 된다.
- 화면/리포트에서는 링크를 통해 빠르게 관련 비용을 탐색할 수 있다.
- 링크가 있어도 정산 기준이 바뀌지 않도록 운영 규칙이 명확해진다.
