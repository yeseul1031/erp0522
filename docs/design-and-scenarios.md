# Balhea ERP Design and Scenarios v7.9

## 1. 설계 철학 개요

### 1.1 프로젝트 중심 설계
Balhea ERP의 모든 업무와 데이터는 **프로젝트(Project)** 를 최상위 단위로 삼는다.
조직(부서)이나 직원 정보는 ERP의 정체성이 아니며, 프로젝트를 둘러싼 외부 맥락으로 취급한다.

- 모든 비용(cost)은 프로젝트에 귀속된다.
- 모든 책임/담당은 프로젝트 기준으로 정의된다.
- 담당자 변경은 프로젝트의 담당자 참조만 수정하면 된다.

### 1.2 조직/직원 정보를 ERP에 넣지 않는 이유
- 직원/조직 정보는 그룹웨어가 단일 진실 소스(Single Source of Truth)이다.
- ERP에 조직 정보를 복제하면 동기화/정합성 문제가 발생한다.
- ERP는 **업무 사실(fact)** 만 관리한다.

ERP에는 직원의 상세 정보가 아니라, 외부 시스템의 **식별자(principal)** 만 남긴다.

### 1.3 비용과 지급을 분리한 이유 (cost ≠ payment)
- cost: 비용/원가/채무의 발생 사실
- payment: 실제 현금/자산이 유출된 행위
- payable: 지급을 통제하기 위한 승인/요청 단위

이 분리를 통해 다음을 달성한다.
- 분할 지급
- 선금/중도금/잔금
- 카드 즉시결제 vs 계좌이체 승인
- 현금 지급 처리

---

## 2. End-to-End 업무 흐름

### 2.1 조달(Procurement)
1. 프로젝트 생성
2. 수급 대상 정의 (sourcing_case)
3. 견적(RFQ) 및 발주(PO)
4. 발주는 승인 후 진행되며, 승인 기록은 로그로 남긴다.

### 2.2 배송/물류(Logistics)
배송은 비용이 아니라 **상태와 흐름**이다.

- deliveries: 배송 단위
- delivery_lines: 배송 내 물품/수량
- shipment milestones: 배송 단계(출발, 통관, 도착 등)

배송 과정 중 발생하는 비용(운송료 등)은 별도의 cost로 기록한다.

### 2.3 비용 발생
- PO 기반 비용: 구매 원가
- 비PO 비용: 퀵서비스, 주유비, 미팅비 등
- 모든 비용은 costs에 기록되고, 필요 시 프로젝트/주문항목으로 배부된다.

### 2.4 지급
- 카드: 즉시 payment 생성
- 계좌이체: payable → 승인 → payment
- 현금: payment(pay_method=CASH)

현금영수증은 지급 증빙이므로 payment_documents에 첨부한다.

### 2.5 감사 및 추적
- activity_logs: 주요 행위 기록
- audit_logs: 값 변경 이력

외래키 대신 로그를 통해 “누가 언제 무엇을 바꿨는지”를 추적한다.

---

## 3. 실전 운영 시나리오

### 시나리오 1: 퀵서비스 + 현금 지급
- cost: 퀵서비스 비용 기록
- payment: CASH 지급 기록
- documents: 현금영수증 첨부

### 시나리오 2: 온라인 주문 + 카드 결제
- cost: 구매 원가
- payment: CARD 지급
- documents: 카드 승인
- documents: 구매명세서

### 시나리오 3: Invoice 1건에 여러 PO
- invoice + invoice_lines로 묶음
- cost로 원가 인식
- payable 승인 후 payment

### 시나리오 4: 분할 지급
- cost 1건
- payment 여러 건
- payment_lines로 분할 연결

본 문서는 운영과 설계 맥락을 이해하기 위한 설명서이며,
DDL 및 운영 가이드와 함께 사용한다.


## 문서 저장 정책(통합)
- 모든 문서/증빙/서류는 `documents` 테이블에 **단일 저장**한다.
- 문서가 어떤 엔티티의 근거인지(비용/지급/인보이스/배송 등)는 `document_links(target_type, target_sn)`로만 연결한다.
- 동일 문서는 여러 엔티티에 연결 가능하며(다대다), 저장은 1회/연결만 복수로 처리한다.
