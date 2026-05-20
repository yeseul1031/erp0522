# ADR-012: Operational Invariant: 1 PO equals 1 Cost (Split PO if Needed)

## Status
Accepted

## Context
플랫폼/멀티셀러 결제 등 실무에서 “결제 1건에 영수증 N장”이 흔하다.
PO가 여러 정산 주체를 섞으면 정산/세금계산서/증빙 관리가 어려워진다.

## Decision
운영 불변식으로 `PO 1건 = cost 1건`을 유지한다.
- 권장: `po_cost_links`를 1:1로 유지
- 셀러/사업자 단위 분리가 필요하면 PO를 분할 생성한다.
- 분할이 불필요하면 PO=cost로 묶고, 판매자별 거래 증빙(N장)은 cost에 연결한다.

## Consequences
- 정산 단위가 단순해지고 운영 오류가 줄어든다.
- 멀티셀러 케이스에서 문서 허브 기반 증빙 연결이 자연스러워진다.
- 실제 비용 해석은 `costs.ct_type`에 따라 `po_cost_links`, `po_allocations`, `po_cost_line_allocations`, `project_cost_allocations`를 사용한다.
