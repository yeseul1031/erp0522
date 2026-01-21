# ADR-011: Separate Invoice (External Doc), Payable (Work Unit), and Payment (Cash Flow)

## Status
Accepted

## Context
invoice를 지급 단위로 간주하면 분할 지급/묶음 지급/승인 흐름을 자연스럽게 표현하기 어렵다.
재무팀은 “지급 요청/승인/보류/기한”을 업무 큐로 관리할 필요가 있다.

## Decision
`invoices`는 외부 문서 컨테이너(거래/청구)로 유지하고,
지급 업무 단위는 `payables`, 실제 현금흐름은 `payments`로 분리한다.
연결은 아래 링크로 표현한다.
- `payable_invoice_allocations` (payable ↔ invoice)
- `payable_cost_allocations` (payable ↔ cost)
- `payment_payable_allocations` (payment ↔ payable)
- `payment_lines` (payment ↔ cost)

## Consequences
- 분할/묶음 지급을 자연스럽게 지원한다.
- 재무팀 업무 상태는 payables만 보면 되고, 현금흐름은 payments만 보면 된다.
- 문서/증빙은 `documents` + `document_links`로 통합 연결한다.
