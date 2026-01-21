# ADR-008: Model PO-After Logistics with 4 Axes (Physical/Shipment/Job/Request)

## Status
Accepted

## Context
발주 이후(PO After) 물류/배송은 “국내/해외”보다 추적 단위(실물/운송/작업/협의)에 따라 달라진다.
직송(회사 미접촉)과 바코드 기반 재고(회사 접촉)를 동시에 지원해야 한다.

## Decision
PO After 영역은 4축으로 모델링한다.
1) 실물(바코드): `inventory_units`
2) 운송(구간/송장): `shipments` + `shipment_milestones` (+ `shipment_items`)
3) 작업(사람이 수행): `logistics_jobs` + `logistics_job_stops` + `logistics_job_lines`
4) 협의/역제안: `delivery_requests` + `delivery_request_lines` + `delivery_request_proposals`

## Consequences
- 직송과 재고/바코드 흐름을 동시에 수용한다.
- 실행 이력은 `logistics_jobs`에, 협의 로그는 `delivery_requests`에 분리 저장된다.
- 배송/납품 증빙은 문서 허브(`documents` + `document_links`)로 연결한다.
