# ADR-002: Separate Cost, Payable and Payment

## Status
Accepted

## Context
비용 발생과 실제 AP 정산 결과를 하나의 엔티티로 처리하면
분할 지급, 승인 흐름, 카드/이체/환불 확인 처리가 어려웠다.

## Decision
비용 발생(`cost`)과 AP 정산 결과(`payment`)를 분리한다.
승인/통제/처리 요청은 `payable`로 처리한다.
- 카드 즉시결제는 payable 없이 payment로 즉시 기록된다.
- 현금은 아직 서비스 기획 전이므로 payment에 기록하지 않고 cost 등록까지만 허용한다.
- 분할 지급은 payable에 묶어서 처리한다.
  - payable을 다시 분할하지 않는다. 그럴땐 기존건을 취소하고 새로 만든다. (혹은 수정해서 요청하고, 추후 잔금에 대한 추가 요청을 진행한다.)
- 환불 확인 요청도 payable에 기록하고, 실제 환불 확인 결과는 payment에 기록한다.
연결은 DDL 기준의 직접 FK로 표현한다.
- CARD: `payments.pay_ct_sn` → `costs.ct_sn`
- TRANSFER/REFUND: `payments.pay_pbl_sn` → `payables.pbl_sn` → `payables.pbl_ct_sn` → `costs.ct_sn`

## Consequences
- 분할 지급(선금/중도금/잔금)이 가능해진다.
- 카드 즉시결제, 계좌이체 승인 흐름, 환불 확인 흐름을 모두 지원한다.
- 재무팀 AP 처리 요청은 payables에서 보고, AP 실제 처리 결과는 payments에서 본다.
- 문서/증빙은 `documents` + `document_links`로 통합 연결한다.
