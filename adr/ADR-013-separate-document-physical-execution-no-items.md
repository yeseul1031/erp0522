# ADR-013: Do Not Mix Document/Physical/Execution; Avoid Ambiguous 'Item' Terminology

## Status
Accepted

## Context
‘아이템(item)’은 문서 항목/실물/작업의 의미가 섞여 혼동을 유발한다.
데이터가 커질수록 대상 단위가 섞이면 운영/리포팅/자동화가 무너진다.

## Decision
정본에서 단위를 다음처럼 고정한다.
- 문서 항목: `*_lines`
- 실물 1개(바코드): `inventory_units`
- 작업 1건: `logistics_jobs`
또한 items라는 용어/엔티티는 사용하지 않는다.

## Consequences
- 모델의 경계가 명확해져 확장/자동화가 쉬워진다.
- 운영/리포팅에서 대상 단위 혼동이 줄어든다.
- 직송(미접촉)과 재고(접촉) 흐름을 일관되게 설명할 수 있다.
