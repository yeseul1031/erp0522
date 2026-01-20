# Balhea ERP Design Decisions Log v7.9

본 문서는 Balhea ERP 설계 과정에서 내려진 **중요한 결정과 그 이유**를 기록한다.

---

## D1. 프로젝트 중심 설계
- 조직 중심 설계를 배제하고 프로젝트를 최상위 단위로 선택
- 담당자 변경 시 영향 범위를 최소화하기 위함

## D2. 조직/부서 정보를 ERP에서 관리하지 않음
- 그룹웨어를 진실 소스로 유지
- ERP는 업무 사실만 기록

## D3. cost / payable / payment 분리
- 비용 발생과 자금 유출을 분리
- 분할 지급, 승인 흐름 지원

## D4. 현금영수증은 documents
- 현금영수증의 본질은 지급 증빙
- 비용 내용은 cost에 기록

## D5. procurement_mode 제거
- sourcing_type으로 개념 통합
- 도메인 용어 일관성 확보

## D6. 조직 권한을 ERP 밖으로 이동
- ERP는 권한 계산을 하지 않음
- UI/백엔드가 외부 조직도를 활용

## D7. FK 대신 로그 중심 감사
- 유연한 변경 허용
- audit_logs / activity_logs로 추적

이 문서는 향후 설계 변경 시 반드시 참고해야 하는 기준 문서이다.


## D8. 문서 허브(documents + document_links)
- 문서/증빙/서류를 엔티티별 테이블로 분리하지 않고 `documents` 단일 테이블에 저장한다.
- 문서가 무엇의 근거인지(비용/지급/인보이스/배송 등)는 `document_links`로 느슨하게 연결한다.
- 이 결정은 cost/payment 분리 원칙을 유지하면서 문서 관리의 확장성을 높인다.
