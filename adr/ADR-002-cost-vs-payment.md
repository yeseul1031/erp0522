# ADR-002: Separate Cost, Payable and Payment

## Status
Accepted

## Context
비용 발생과 실제 지급 행위를 하나의 엔티티로 처리하면
분할 지급, 승인 흐름, 현금/카드/이체 혼합 처리가 어려웠다.

## Decision
비용 발생(`cost`)과 지급 행위(`payment`)를 분리한다.
승인/통제는 `payable`로 처리한다.
- 카드/현금 즉시결제는 payable 없이 payment로 즉시 기록 된다.
- 분할 지급은 payable에 묶어서 처리한다.
  - payable을 다시 분할하지 않는다. 그럴땐 기존건을 취소하고 새로 만든다. (혹은 수정해서 요청하고, 추후 잔금에 대한 추가 요청을 진행한다.)
연결은 아래 링크로 표현한다.
- `payable_cost_allocations` (payable ↔ cost)
- `payment_payable_allocations` (payment ↔ payable)
- `payment_lines` (payment ↔ cost)

## Consequences
- 분할 지급(선금/중도금/잔금)이 가능해진다.
- 카드 즉시결제와 계좌이체 승인 흐름을 모두 지원한다.
- 재무팀 업무 상태는 payables만 보면 되고, 현금흐름은 payments만 보면 된다.
- 문서/증빙은 `documents` + `document_links`로 통합 연결한다.
