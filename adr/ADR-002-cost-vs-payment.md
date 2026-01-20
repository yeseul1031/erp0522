# ADR-002: Separate Cost and Payment

## Status
Accepted

## Context
비용 발생과 실제 지급 행위를 하나의 엔티티로 처리하면
분할 지급, 승인 흐름, 현금/카드/이체 혼합 처리가 어려웠다.

## Decision
비용 발생(`cost`)과 지급 행위(`payment`)를 분리한다.
승인/통제는 `payable`로 처리한다.

## Consequences
- 분할 지급(선금/중도금/잔금)이 가능해진다.
- 카드 즉시결제와 계좌이체 승인 흐름을 모두 지원한다.
