# ADR-003: Documents Hub (documents + document_links)

## Status
Accepted

## Context
엔티티별 문서 테이블(cost_documents, payment_documents 등)은
확장성과 중복 관리 문제를 야기했다.

## Decision
모든 문서/증빙/서류를 `documents` 단일 테이블에 저장하고,
`document_links`로 다대다(polymorphic) 연결한다.

## Consequences
- 문서 저장은 1회, 연결은 복수로 처리 가능.
- 비용/지급/배송/인보이스 간 문서 공유가 쉬워진다.
