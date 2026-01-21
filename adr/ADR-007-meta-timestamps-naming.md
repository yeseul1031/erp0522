# ADR-007: Use {abbr}_create_dt / {abbr}_update_dt for Meta Timestamps

## Status
Accepted

## Context
`created_at/updated_at`처럼 공통 컬럼명을 쓰면 JOIN/리포팅 시 컬럼 충돌과 의미 혼동이 잦다.
또한 레코드가 어떤 엔티티의 메타 시간인지 한눈에 파악하기 어렵다.

## Decision
엔티티 메타(생성/수정) 시간 컬럼은 `{abbr}_create_dt`, `{abbr}_update_dt`로 고정한다.
(예: `p_create_dt`, `p_update_dt`, `po_create_dt`, `po_update_dt`)

## Consequences
- SELECT/JOIN 시 충돌을 줄이고 가독성이 좋아진다.
- 감사/이력 확인 시 “어떤 엔티티의 시간인지”가 명확해진다.
- 이벤트 시간(납기/지급일 등)과 메타 시간의 구분이 쉬워진다.
