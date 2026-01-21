---
project: "ERP Data Guide"
repo: "erp-data-guide"
file: "docs/schema-policy-and-naming.md"
version: "1.0.0"
date: "2026-01-20"
summary: "스키마 정책 + 네이밍 규칙 + 문서/버전 운영 대전제 정본화"
---

# Schema Policy and Naming (정본)

> **대전제(불변)**
> 1) docs의 파일명은 아래 4개만 사용하며, 사용자가 명시적으로 요청하지 않는 이상 바꾸지 않는다.  
> 2) 문서에는 “최근 논의만” 남기지 않고, **현재 기준의 전체 내용(정책/예외/이력/시나리오/필드 설명)**을 모두 유지한다.  
> 3) 이력은 단순 연대기 나열이 아니라, **(a) 최종 결정 (b) 결정 사유 (c) 다른 선택지 기각 사유**를 함께 기록한다.  
> 4) 스키마 필드 설명/값/관계는 반드시 보유한다.  
> 5) 모든 케이스별 입력 시나리오(입력 순서/입력값/테이블 영향)를 반드시 보유한다.

## 0. docs 파일 고정 목록(정본)
- `docs/operations-guide.md` (HOW: 실무 입력/운영 절차)
- `docs/design-and-scenarios.md` (WHY/WHAT: 설계 맥락/시나리오)
- `docs/schema-policy-and-naming.md` (RULES: 정책/네이밍/코드/운영 규칙)  ✅ **본 파일**
- `docs/design-decisions-log.md` (DECISIONS INDEX: 결정 요약 + 기각 사유)

---

## 1. 네이밍 규칙 (DB 스키마 정본)

### 1.1 테이블/PK/FK 기본 규칙
- 테이블명: **복수형**
- PK: `*_sn` 형태의 `BIGINT UNSIGNED AUTO_INCREMENT`
- FK: 참조 대상 PK 컬럼명과 동일(예: `p_sn` → projects.p_sn)
- 날짜/시간:
  - 레코드 메타: `*_create_dt`, `*_update_dt`
  - 업무 이벤트: `*_at` (예: approved_at, paid_at)

### 1.2 링크/배부(Allocation) 네이밍
- **links**: “관계 연결”에 집중(보통 가벼운 N:M)
- **allocations**: “금액/수량 배분”의 의미가 있을 때 사용
- 정책: 배부가 의미를 갖는 경우 `*_allocations`를 우선한다.

### 1.3 코드 필드(ENUM vs VARCHAR+COMMENT) 규칙
- **99% 확정적**이고 변경 가능성이 낮은 값 집합 → `ENUM`
- 값이 유동적이거나 향후 확장 가능성이 큰 경우 → `VARCHAR + COMMENT`
  - COMMENT에 “권장 값 + 확장 가능”을 명시

---

## 2. 핵심 아키텍처 정책(정본)

### 2.1 프로젝트 중심(Project-centric)
- ERP의 최상위 단위는 프로젝트다.
- 계약/주문/수급/배송/비용/지급은 프로젝트 기준으로 추적 가능해야 한다.

### 2.2 cost ≠ payment ≠ payable
- `costs`: 비용/원가/부채의 **발생**
- `payments`: 현금/자산의 **실제 유출(지급 행위)**
- `payables`: 승인/통제용 **선택적** 중간 단위(특히 이체 승인 흐름)

### 2.3 Documents Hub (documents + document_links) — 유일한 문서 정책
- 모든 문서/증빙/첨부는 **`documents`에 단일 저장**
- 무엇의 근거인지(비용/지급/인보이스/배송 등)는 **`document_links`로만 연결**
- 엔티티별로 별도의 **문서 전용 테이블**을 만들지 않는다. 문서는 `documents`에 저장하고, 관계는 `document_links`로 표현한다.

#### 2.3.1 document_links 유효성 검증
- document_links는 polymorphic이므로 DB FK로 전부 강제하지 않는다.
- `target_type + target_sn`의 유효성은 애플리케이션에서 검증한다.

---

## 3. 문서 코드 정책(권장; 확장 가능)

> 아래는 “권장 코드”이며, 유연성을 위해 VARCHAR+COMMENT 또는 ENUM(확정 시)로 운용한다.
> 코드 확장은 design-decisions-log에 사유와 함께 기록한다.

### 3.1 documents.doc_category (권장)
- COST, PAYMENT, INVOICE, PURCHASE, DELIVERY, CUSTOMS, QUALITY, CONTRACT, TAX, SETTLEMENT, REFUND, OTHER

### 3.2 documents.doc_type (권장 예시)
- CASH_RECEIPT, CARD_APPROVAL, BANK_TRANSFER_RECEIPT, TAX_INVOICE, STATEMENT, PURCHASE_DETAILS,
  DELIVERY_NOTE, SHIPMENT_PROOF, PLATFORM_SETTLEMENT, REFUND_PROOF, OTHER

### 3.3 document_links.target_type (권장 예시)
- PROJECT, CONTRACT, ORDER, ORDER_LINE, SOURCING_CASE, RFQ, PURCHASE_ORDER,
  COST, PAYABLE, PAYMENT, INVOICE, DELIVERY, DELIVERY_LINE, OTHER

---

## 4. 저장소 운영 규칙(정본)

### 4.1 DDL 파일 네이밍
- DDL은 반드시 `erp_*_schema.sql` (예: erp_core_schema.sql, erp_finance_schema.sql, erp_logistics_schema.sql)
- 파일명에 버전은 넣지 않는다.
- 버전/날짜/요약은 파일 헤더로 관리한다.

### 4.2 문서 변경 원칙
- 설계가 바뀌면 **삭제가 아니라 “현재 기준으로 재서술 + 기각 사유 기록”**을 한다.
- 문서의 상세(필드 설명/시나리오/결정 사유)는 축약하지 않는다.

---

# schema-policy-and-naming (정본 통합본) — Canon v7.9.7

본 문서는 다음 자료를 바탕으로, **현재 정본(v7.9.7) 구조/정책에 유효한 내용만**을 선별하여
`schema-policy-and-naming.md`의 흐름/포맷에 맞게 **병합/정리**한 것이다.

- `schema-policy-and-naming.md` (사용자 지정 4-docs 규칙/정본 정책)
- `Balhea_Schema_Policy_and_Naming_ALL_IN_ONE_canon_v7.9.7.md` (스키마 정책+컬럼 네이밍 가이드 통합본)
- `Balhea_Policy_and_Assumptions_canon_v7.9.7.md` (문서 허브, RFQ/PO 통합, 환율 고정 등 정본 정책)

정리 원칙(요약):
- deprecated 엔티티/명칭은 본문에 남기지 않고, **정본 엔티티로 치환된 정책만** 수록한다.
- 과거 문서의 풍부한 표/템플릿/설명은 **형식을 유지**하되, 내용은 최신 구조로 통일한다.

## (병합 수록) 스키마/네이밍/코드 정책 정본

## A. 도메인/운영 정책 (정본)

### A-1. 비즈니스/프로젝트 모델
- 프로젝트(Project)는 계약 단위이며, 기본적으로 **프로젝트 1개 = 계약 1개**를 다룬다.
- 프로젝트 유형 예시:
  - `TENDER` : 공공 입찰(단건 입찰 포함)
  - `DIRECT` : 민간/직접 계약
  - `FRAME` : 장기/콜오프(기간 내 다수 주문 발생 가능)

### A-2. 주문(Orders) / 주문라인(Order Lines)
- `orders`는 프로젝트 하위의 실제 주문 단위(단건이면 1개, 다건이면 다수).
- `order_lines`는 고객에게 납품해야 할 약속 단위(요구 품목/수량/규격).

### A-3. 99% 경로(운영 편의성 우선)
- 대부분의 케이스는 **주문라인 1개 = 실제 구매/납품 상품(goods) 1개**다.
- `order_lines.ol_default_g_sn`(기본 goods FK)을 제공한다.
- RFQ/PO 생성 시:
  - override가 없다면 `ol_default_g_sn`을 사용해 문서 라인을 자동 생성한다.

### A-4. 희소 케이스(1% 내외) — Override 패턴
희소 케이스(재고부족 분할, 대체품 일부, 불량 추가구매, PC 조합 등)는 `order_line_overrides`로 수용한다.

- override 유형:
  - `SPLIT` : 수량을 나누어 여러 상품/여러 발주로 처리
  - `SUBSTITUTE` : 일부를 유사 대체품으로 처리
  - `ADD_ON` : 불량/추가요청 등으로 추가 구매
  - `BUNDLE` : 조합 납품(PC 등) 구성품 구매 단위

- 문서 생성 규칙:
  - override가 있으면 override를 우선 전개하여 RFQ/PO 라인을 만든다.
  - override가 없으면 default goods를 사용한다.

### A-5. 수급 케이스(Sourcing Case)
- 수급 케이스는 `sourcing_cases(sc_sn)`가 “현재 유효” 값을 가진다.
- 유효한 수급 방식은 동시에 1개로 제한하며, 변경 이력은 로그/감사 테이블로 남긴다.
- RFQ/PO 라인과의 배정은 allocation 테이블에서 `sc_sn`으로 묶는다.

### A-6. 후보군 비교(드라이버/CPU/모니터 등)
- 후보 비교의 그룹 키는 `goods`가 아니라 **`order_line` 또는 `sc_sn`**이다.
- BUNDLE(PC)처럼 한 `sc_sn` 안에 구성품이 섞일 수 있으므로,
  RFQ/PO allocation에서 `olo_sn`(구성품 키)을 사용할 수 있어야 한다.

### A-7. 거래처(Parties) 운영 원칙(정산 주체만)
- Parties는 “정산/결제 상대(플랫폼/업체)” 단위로만 관리한다.
  - 예: 네이버, 쿠팡, 알리익스프레스, 해외 벤더 등
- 퀵/대행/비정형 지출은 **예약된 party 1개(pt_sn)**로 처리하고,
  상세 판매자(오픈마켓 셀러 등)는 party로 분해하지 않는다.

### A-8. 비용/지급/증빙(재무) 원칙 (핵심)

#### A-8.1 costs(비용 발생)
- `costs`는 비용 발생(사유/금액/발생일)을 기록한다.
- 비용은 특정 주문/라인/override/수급(sc_sn)에 귀속될 수 있으며,
  귀속은 `cost_allocations`로만 관리한다(원장은 단순 유지).

#### A-8.2 cost_allocations(비용 귀속)
- 비용 귀속 대상은 다음을 지원한다:
  - `p_sn` (프로젝트 단위)
  - `o_sn` (주문서 단위)
  - `ol_sn` (주문라인 단위)
  - `olo_sn` (override 단위: 구성품/분할/대체)
  - `sc_sn` (수급 케이스 단위)
- 퀵 비용은 PO가 아니라 **cost + allocation**으로만 귀속한다.

#### A-8.3 payments(실제 지급) / payment_lines(지급-비용 매핑)
- `payments`는 실제 지급 사건(카드/이체/현금)을 기록한다.
- `payment_lines`는 “이 지급이 어떤 비용(들)을 얼마만큼 정산했는지”를 연결한다.
- 선금/중도금/잔금 같은 단계는 `payment_lines.note`(또는 UI 라벨)로 표현한다.
  - (비용(costs)이나 PO-비용 링크에 중복 저장하지 않는다.)

#### A-8.4 지급 증빙
- 카드전표/이체확인/정산내역/영수증 묶음 등 지급 관련 증빙은 **`documents`**에 저장한다.
  - 권장: `documents.doc_category = PAYMENT`
- 증빙이 무엇의 근거인지(예: 특정 `payments.pay_sn`)는 **`document_links`로만 연결**한다.
  - 권장: `document_links.target_type = PAYMENT`, `document_links.target_sn = pay_sn`
- 오픈마켓 셀러 다수(결제 1건에 판매자별 증빙 다수) 케이스는
  - party를 셀러 단위로 분해하지 않고
  - 셀러 표시명/발행자명 등 메타는 **`documents`의 메타 컬럼(예: issuer_name / issuer_display_name / note)**에 기록하며
  - 모두 `document_links`로 동일 payment에 다중 연결한다.

#### A-8.5 Invoice / Payable / Payment (외부 문서 vs 내부 지급 단위 vs 실지급)

재무 데이터는 아래 3개의 “역할 분리”를 전제로 설계한다.

- **Invoice(`invoices`)**: 거래처/플랫폼/발행자가 제공하는 **외부 문서 컨테이너**
  - invoice 자체는 “지급 단위”가 아니다.
  - 영수증/세금계산서/거래명세서 등 문서 원본과 문서 라인(`invoice_lines`)을 담는다.
- **Payable(`payables`)**: 내부에서 관리하는 **지급 단위(결재/보류/대기/분할지급의 기준)**
  - “지급 요청”, “승인”, “보류”, “부분 지급”, “완료” 같은 상태는 payable이 가진다.
- **Payment(`payments`)**: **실제로 돈이 나간 기록(결과)**
  - payment는 “실지급이 발생한 사실”만 기록한다.
  - 승인/보류/대기 같은 상태는 payment에 두지 않고 payable에서 관리한다.

(1) 기본 연결 규칙
- payable 1건은 여러 invoice를 포함할 수 있으며, 그 연결은 `payable_invoice_allocations`로 관리한다.
- payable 1건은 여러 cost에 안분될 수 있으며, 그 연결은 `payable_cost_allocations`로 관리한다.
- payment 1건은 여러 payable에 안분(또는 1:1 연결)될 수 있으며, 그 연결은 `payment_payable_allocations`로 관리한다.

(2) 문서 첨부(증빙) 정책
- **비용 증빙(영수증/세금계산서 등)**은 “비용 측 증빙 링크(예: `documents`(doc_category=COST))”로 연결한다.
  - 종합몰/플랫폼 결제처럼 “결제 1건에 판매자별 영수증이 여러 장”인 경우에도 다중 첨부 가능해야 한다.
- **지급 증빙(이체확인/카드승인/정산내역 등)**은 “지급 측 증빙 링크(예: `documents`(doc_category=PAYMENT))”로 연결한다.

(3) 확정 코드값(ENUM) / 유동 코드값(VARCHAR) 운영 원칙(재무)
- 상태가 거의 확정이고 시스템 로직이 강하게 의존하는 값은 **ENUM**으로 고정한다.
  - 예: `invoices.doc_type`, `invoice_lines.line_type`, `payables.payable_status`
- 회사/고객/플랫폼별로 확장될 여지가 있는 값은 **VARCHAR + COMMENT**로 두고,
  COMMENT에 “권장 값 + 확장 가능”을 명시한다.

### A-9. PO-비용 링크(link_type) 정책 (정본)
- `po_cost_links.link_type`는 “지급 단계(선금/잔금)”를 표현하지 않는다.
- `link_type`는 PO 관련 **부대비용 성격 분류** 용도로만 사용한다.
  - 예: `FREIGHT`, `CUSTOMS`, `INSPECTION`, `ETC`
- 지급 단계(선금/중도금/잔금)는 payments/payment_lines에만 기록한다.

---

## A-8A. 문서 허브 정책 (documents + document_links)

### 목적
(아래 내용은 “문서 허브 정책”의 상세 설명이며, 본 문서의 정본 규칙이다.)

---

### 문서 허브 상세

### 목적
문서/증빙/서류 저장 위치를 케이스별로 쪼개지 않고, **`documents` 단일 테이블로 통합**한다.
문서가 무엇의 근거인지(비용/지급/인보이스/배송 등)는 **`document_links`(다대다, polymorphic)** 로 표현한다.

### 핵심 규칙
- 문서 파일은 항상 `documents` 로 수집한다.
- 문서의 상위 분류는 `doc_category`, 세부 유형은 `doc_type`으로 표현한다(코드값은 확장 가능).
- 문서가 어떤 엔티티의 근거인지(예: costs, payments, invoices, deliveries 등)는 **오직 `document_links`** 로 연결한다.
- 엔티티별로 별도의 **문서 전용 테이블**을 만들지 않는다. 문서는 `documents`에 저장하고, 관계는 `document_links`로 표현한다.


### 문서 코드 표준(권장; 확장 가능)


- `documents.doc_category`
  doc_category (권장 코드; 확장 가능)
  - COST: 비용/원가/부채 관련 근거 문서
  - PAYMENT: 지급/현금흐름 관련 증빙
  - INVOICE: 청구/요청/거래명세(인보이스)
  - PURCHASE: 조달/구매(발주, 견적 등)
  - DELIVERY: 배송/물류(운송, 인수, 검수)
  - CUSTOMS: 통관/무역 서류(B/L, 신고필증 등)
  - QUALITY: 품질/검수/시험 성적서
  - CONTRACT: 계약/약정/합의서
  - TAX: 세무(세금계산서, 계산서 등)
  - SETTLEMENT: 정산/대사(플랫폼/PG/카드사 청구 등)
  - REFUND: 환불/취소 관련
  - OTHER: 기타(설명은 note에 기재)

- `documents.doc_type`
  doc_type (권장 코드; 확장 가능)
  - CASH_RECEIPT: 현금영수증
  - CARD_APPROVAL: 카드 승인 내역(승인번호/금액/일시)
  - BANK_TRANSFER_RECEIPT: 계좌이체 영수증/송금확인
  - CARD_STATEMENT: 카드사 청구서(월 단위)
  - TAX_INVOICE: 전자/종이 세금계산서
  - BILL: 계산서(면세 등)
  - STATEMENT: 거래명세서/지급요청서(여러 발주 묶음 가능)
  - INVOICE: 청구서/인보이스(요청)
  - PURCHASE_DETAILS: 구매명세서/구매항목정보(셀러별 N개 가능)
  - QUOTE: 견적서
  - PO_DOC: 발주서(업무 문서)
  - DELIVERY_NOTE: 납품서/인수증/검수확인서
  - SHIPMENT_PROOF: 운송장/배송내역/송장(B/L 포함)
  - CUSTOMS_CLEARANCE: 통관서류(수입신고필증 등)
  - QUALITY_REPORT: 시험성적서/검사성적서/품질보고서
  - PLATFORM_SETTLEMENT: 플랫폼/PG 정산서(수수료/차감 포함)
  - REFUND_PROOF: 환불/취소 증빙(카드취소전표 등)
  - ETC: 기타(설명은 note에 기재)

- `document_links.target_type`
  target_type (권장 코드; 확장 가능)
  - PROJECT: projects(p_sn)
  - ORDER: orders(o_sn)
  - ORDER_LINE: order_lines(ol_sn)
  - SOURCING_CASE: sourcing_cases(sc_sn)
  - RFQ: rfqs(rfq_sn)
  - RFQ_LINE: rfq_lines(rfql_sn)
  - PURCHASE_ORDER: purchase_orders(po_sn)
  - PO_LINE: po_lines(pol_sn)
  - COST: costs(ct_sn)
  - PAYABLE: payables(pv_sn)
  - PAYMENT: payments(pay_sn)
  - INVOICE: invoices(inv_sn)
  - INVOICE_LINE: invoice_lines(invl_sn)
  - DELIVERY: deliveries(dv_sn)
  - DELIVERY_LINE: delivery_lines(dvl_sn)
  - SHIPMENT: shipments(sh_sn)
  - OTHER: 기타(설명은 note에 기재)

## B. RFQ/PO 통합 및 환율 고정 정책 (정본)

### B-1. 목표
운영 관점에서 국내/해외는 **“필수 필드 차이”**라기보다 **“옵션 필드 차이(통화/인도조건/국가/환율)”**에 더 가깝기 때문에,
RFQ/PO는 단일 테이블로 통합하는 것이 장기적으로 단순하다.

- RFQ/PO를 단일 테이블로 통합: `rfqs`, `purchase_orders`
- 국내/해외 차이는 옵션 컬럼으로 흡수
- 비용/지급은 기존 `costs`, `payments`, `cost_allocations` 구조 유지
- 환율 재현성(감사 대응)을 위해 비용에 적용 환율을 고정 저장

### B-2. 통합 테이블 개요

#### B-2.1 RFQ(견적요청)
- `rfqs` / `rfq_lines` / `rfq_allocations`
- 국내/해외 공통 필드: 업체, 작성자, 상태, 발행일, 라인 품목/수량, 회신 정보
- 해외 옵션 필드(필요 시만 채움): `trade_terms`, `ship_from_country`, `ship_to_country`

#### B-2.2 PO(발주)
- `purchase_orders` / `po_lines` / `po_allocations`
- 국내/해외 공통 필드: 업체, 작성자, 상태, 발행/수락, 납기, 결제/부가세
- 해외 옵션 필드: `trade_terms`, `ship_from_country`, `ship_to_country`
- 해외 통화는 라인 단위 `po_lines.currency`로 관리(국내는 기본 KRW)

### B-3. 국내/해외 구분 정책

#### B-3.1 소스 오브 트루스
- 주문라인의 수급 방식은 `sourcing_cases.sourcing_type`가 **최종 기준**
- RFQ/PO 헤더의 `sourcing_type`는 **필터/조회 편의용(선택)**

#### B-3.2 필수/옵션 규칙(권장)
- DOMESTIC:
  - `ship_from_country/ship_to_country/trade_terms`는 NULL 허용
  - `po_lines.currency`는 KRW 사용 권장
- OVERSEAS:
  - `po_lines.currency`는 실제 매입 통화로 입력(USD/EUR/CNY 등)
  - `trade_terms`는 가능하면 입력(인도조건)
  - 환율/원화 환산이 필요한 비용은 `cost_fx_applications`로 고정

### B-4. 비용/환율 처리(기존 finance 구조 존중)

#### B-4.1 비용 귀속
- 비용 원장: `costs`
- 비용 배분/안분: `cost_allocations`
- PO에 속한 비용을 빠르게 찾기 위한 연결: `po_cost_links` (조회용)

> 원가/마진 계산은 항상 `cost_allocations`를 기준으로 수행하고,
> `po_cost_links`는 "탐색"과 "UI 편의" 용도로만 사용한다.

#### B-4.2 환율 재현(감사 대응)
해외 비용은 시점에 따라 환율이 달라지므로, **정산 시점에 적용한 환율과 원화 환산 결과를 고정**해야 한다.

- 권장 방식: `cost_fx_applications`
  - `applied_fx_rate`, `as_of_dt`, `base_amount(KRW)` 저장
  - 필요하면 `fx_sn`으로 환율 마스터(`fx_rates`) 참조

### B-5. 운영 예시

#### B-5.1 국내 RFQ → PO
- `rfqs.sourcing_type = DOMESTIC` (또는 NULL)
- `rfq_lines.reply_currency = 'KRW'`
- `purchase_orders.po_status` 전개: DRAFT → SENT → ACCEPTED

#### B-5.2 해외 PO + 비용(USD) + 환율 고정
- `po_lines.currency = 'USD'`
- 통관비/포워딩 비용을 `costs`에 등록(통화 USD)
- 정산 시점 환율을 `cost_fx_applications`에 저장:
  - `src_currency='USD'`, `src_amount=...`, `applied_fx_rate=...`, `base_amount(KRW)=...`

---

## C. 네이밍/키/컬럼 규칙 (요약)

> 상세는 `Balhea_SQL_Column_Naming_Guide_MERGED_canon_v7.9.7.md`를 참조.

### C-1. 테이블/PK/FK
- 테이블명: 복수형
- PK: `[{table_abbr}]_sn BIGINT UNSIGNED AUTO_INCREMENT`
- FK: 참조 대상 PK 컬럼명과 동일하게 사용

### C-2. 엔티티 메타 컬럼 vs 비즈니스 이벤트 시간
- 메타 컬럼(레코드 생성/수정): `{abbr}_create_dt`, `{abbr}_update_dt`
- 비즈니스 이벤트 시간: 의미 기반 `*_at` (예: `issued_at`, `replied_at`, `paid_at`, `occurred_at`)

---

## D. 코드북(운영 입력/검증 기준)

> v7.6~v7.9.1에서 확장된 “코드값 표준(Incoterms, delivery_method, fx_rate_policy 등)”은
> `Balhea_SQL_Column_Naming_Guide_MERGED_canon_v7.9.7.md`의 **[10~11절]**에 원문 수준으로 보존했다.

### D-1. DDL 기반 ENUM/코드값 레퍼런스 (v7.8.0 FINAL에서 보존)

> 아래 목록은 DDL에 명시된 ENUM/코드값을 운영 입력/검증 기준으로 옮긴 것이다.

- `party_type`: CUSTOMER, VENDOR, FORWARDER, BROKER, OTHER
- `project_type`: TENDER, DIRECT, FRAME
- `p_status`: PRE_CONTRACT, ACTIVE, CLOSED, CANCELLED
- `order_type`: CONTRACT_ORDER, PRE_CONTRACT_ORDER
- `o_status`: OPEN, IN_PROGRESS, CLOSED, CANCELLED
- `ol_status`: OPEN, IN_PROGRESS, DELIVERED, CANCELLED
- `override_type`: SPLIT, SUBSTITUTE, ADD_ON, BUNDLE
- `sourcing_type`: DOMESTIC, OVERSEAS, IN_HOUSE
- `sc_status`: OPEN, IN_PROGRESS, READY_TO_HANDOFF, HANDED_OFF, CANCELLED
- `cost_type`: PRODUCT, MATERIAL, SHIPPING, CUSTOMS, SERVICE, OTHER
- `pay_method`: CARD, TRANSFER, CASH
- `pay_status`: PENDING, PAID, CANCELLED
- `step_code`: RFQ, SUPPLIER_SELECTED, PAYMENT, SHIPMENT, CUSTOMS, DELIVERY, QC
- `os_status`: TODO, DOING, DONE, BLOCKED, CANCELLED
- `iwo_status`: TODO, DOING, DONE, BLOCKED, CANCELLED
- `rfq_status`: DRAFT, SENT, REPLIED, CANCELLED, CLOSED
- `reply_status`: PENDING, REPLIED, DECLINED
- `po_kind`: NORMAL, SAMPLE
- `po_status`: DRAFT, SENT, ACCEPTED, REJECTED, CANCELLED, CLOSED
- `tax_type`: TAX_INCLUDED, TAX_EXCLUDED, UNKNOWN
- `sample_disposition`: DISCARD, KEEP_INTERNAL, INCLUDE_IN_DELIVERY

---

## E. 과거/폐지 정책 (보존)

이 섹션은 “현재 정본”에 반하지 않는 한, 과거 버전의 풍부한 설명/표/운영 팁을 삭제하지 않고 보존한다.

### E-1. 레거시 RFQ/PO 분리 테이블(domestic_*/overseas_*)
- 과거(v7.6 이전/동시)에는 국내/해외 RFQ/PO를 분리 테이블로 두고,
  약어도 `rfq_`, `po_`, `rfq_`, `po_` 계열을 사용했다.
- 통합 정책(v7.8+) 이후 **신규 개발은 통합 테이블만** 사용을 권장한다.
- 단, 감사/추적 또는 레거시 화면/리포트 때문에 **레거시 테이블을 즉시 삭제하지 않고 보존**하는 전략을 유지한다.

### E-2. (폐지) 엔티티 메타 시간: created_at/updated_at
- v1.0에서는 `created_at/updated_at`을 공통 메타 컬럼으로 두었다.
- v1.1에서 `{abbr}_create_dt/{abbr}_update_dt`로 정본 변경되었으므로,
  신규 테이블/신규 DDL에서는 `created_at/updated_at`을 사용하지 않는다.



---

## Z-1. 레거시/폐지 정책 보존: documents / documents

과거 일부 문서/논의에서는 ‘비용 증빙은 documents, 지급 증빙은 documents’처럼
엔티티 전용 문서 테이블을 전제로 설명이 작성되어 있었다.

**현재 정본은 문서 허브(`documents` + `document_links`) 단일 정책**이며, 엔티티 전용 문서 테이블은 사용하지 않는다.


- (과거 분리형 문서 테이블 개념) → **문서 허브 단일화(정본)** 로 통합한다.
  - 비용/지급/인보이스/배송 등 “문서의 성격”은 `documents.doc_category`(상위 분류)와 `documents.doc_type`(세부 유형)로 구분한다.
  - 문서가 무엇의 근거인지(비용/지급/견적/발주/배송/기타)는 `document_links.target_type + target_sn`으로 연결한다.
  - 즉, “엔티티마다 문서 테이블을 따로 두고 거기에 첨부”하는 구조를 만들지 않는다.

---

## 2. 엔티티 메타 컬럼 vs 비즈니스 이벤트 시각 (정본)

### 2.1 엔티티 메타 컬럼 (생성/수정 시각) — 고정 규칙

엔티티(테이블) 레코드 자체의 생명주기를 나타내는 컬럼은 반드시 아래 규칙을 따른다.

```text
{abbr}_create_dt
{abbr}_update_dt
```

예시:
- `projects.p_create_dt`, `projects.p_update_dt`
- `orders.o_create_dt`, `orders.o_update_dt`
- `payment_lines.pyl_create_dt`, `payment_lines.pyl_update_dt`

**적용 대상**
- 모든 엔티티 테이블

**설계 의도**
- JOIN 시 alias 없이도 충돌 방지
- 레코드 소속 엔티티가 즉시 식별 가능
- audit_changes/activity_logs 기반 추적에 적합

### 2.2 비즈니스 이벤트/상태 변화 시각 — 의미 기반

업무 행위/이벤트의 시점을 의미하는 컬럼은 약어 prefix를 쓰지 않고, 의미 기반 `*_at` 컬럼을 사용한다.

권장 예시:
- `assigned_at` : 담당자 지정 시각
- `issued_at` : 문서 발행 시각
- `replied_at` : 견적 회신 시각
- `accepted_at` : 발주 수락 시각
- `handed_off_at` : 인계 완료 시각
- `delivered_at` : 납품 완료 시각
- `occurred_at` : 비용 발생 시각
- `paid_at` : 지급 완료 시각

> 주의: 이런 컬럼에 `p_assigned_dt`, `ol_issued_dt` 같은 형태는 쓰지 않는다.

---

## 3. 컬럼 네이밍 스타일

### 3.1 기본 스타일
- `snake_case`
- 축약 남용 금지
- 도메인 의미가 우선
  - 예: `delivery_address`, `payment_terms`, `expected_delivery_at`

### 3.2 충돌이 잦은 컬럼에 대한 하이브리드 전략

JOIN 시 alias를 줄이기 위해, 아래 범주의 컬럼은 **테이블 약어 prefix**를 붙이는 것을 권장한다.

- 상태/진행: `*_status`
- 단독 의미가 약한 범용 단어: `name`, `type` 등

권장 예시:
- `projects.p_status`
- `orders.o_status`
- `order_lines.ol_status`
- `sourcing_cases.sc_status`

반대로, 아래는 prefix를 강제하지 않는다.
- `{abbr}_create_dt`, `{abbr}_update_dt` (이미 약어 포함)
- 비즈니스 이벤트 시각 컬럼(`*_at`)

---

## 4. 표준 컬럼 사전 (풍부 버전 유지)

### 4.1 시간 컬럼
- 엔티티 메타(정본): `{abbr}_create_dt`, `{abbr}_update_dt`
- 비즈니스 이벤트(의미 기반):
  - `issued_at` : 문서 발행/발송 시각
  - `replied_at` : 회신 시각
  - `accepted_at` : 수락 시각
  - `delivered_at` : 납품 시각
  - `occurred_at` : 비용 발생 시각
  - `paid_at` : 지급 완료 시각
- “기간”이 필요한 경우:
  - `started_at`, `ended_at` (필요한 엔티티에만)

### 4.2 상태 컬럼(ENUM)
- 상태 컬럼명은 `*_status` 형태를 권장
  - `p_status`, `o_status`, `ol_status`, `sc_status` 처럼 테이블 약어 포함 권장
- ENUM 컬럼은 반드시 `COMMENT`에 **값:설명**을 명시한다.

예:
```sql
o_status ENUM('OPEN','CLOSED','CANCELLED')
COMMENT '주문서 상태 | OPEN:진행중, CLOSED:종결, CANCELLED:취소'
```

### 4.3 boolean / flag
- `is_` 접두어 사용
  - 예: `is_active`, `is_selected`
- MySQL에서는 `TINYINT(1)` 사용 (0/1)

### 4.4 수량/금액/단가
- 수량: `qty`, `qty_required`, `qty_delivered`, `allocated_qty`
- 금액: `amount`, `allocated_amount`
- 단가: `unit_cost`, `unit_price_sales`, `reply_unit_cost`

> 규칙: “단위당”은 `unit_`, “총액”은 `amount`를 우선한다.

### 4.5 통화
- `currency CHAR(3)` (ISO 4217)
- 회신/문서별 통화가 다르면 도메인 접두어를 사용
  - 예: `reply_currency`

### 4.6 텍스트 설명/메모
- 짧은 설명: `summary`
- 내부 메모: `memo`
- 라인 비고/특이사항: `line_note` 또는 `note`
- 상세 설명: `description`

### 4.7 JSON 컬럼
- 자유형/확장형 데이터는 `*_json` 접미어 사용
  - 예: `requirement_spec_json`, `spec_json`, `metadata_json`, `changed_fields_json`

---

## 5. 문서(서류) 계열 네이밍 규칙

> 이 섹션은 “가장 풍부한 설명”을 보존하기 위해 유지한다.
> 단, RFQ/PO 통합 이후 신규 설계에서는 `domestic_*`, `overseas_*` 대신 통합 테이블(`rfqs`, `purchase_orders`)을 사용한다.

### 5.1 헤더/라인 표준
- 문서 헤더 테이블: `rfqs`, `purchase_orders`
- 문서 라인 테이블: `rfq_lines`, `po_lines`
- “한 줄” 엔티티 명은 **모든 서류에서 `*_lines`로 통일**한다.

### 5.2 line 번호
- 문서 내 순번은 항상 `line_no INT`

---

## 6. 인덱스/제약 네이밍(권장)

- Unique: `uk_{table}_{cols}`
  - 예: `uk_order_lines_order_line_no (o_sn, line_no)`
- Index: `idx_{table}_{cols}`
  - 예: `idx_rfq_lines_reply_status (reply_status)`
- FK: `fk_{child}_{parent}` 또는 `fk_{table}_{meaning}`
  - 예: `fk_orders_projects`, `fk_sourcing_cases_order_lines`

---

## 8. 약어(Abbreviation) / Prefix 표준

### 8.1 엔티티 약어 + PK 표 (확장 통합)

| 엔티티 | 테이블 | 약어 | PK |
|---|---|---:|---|
| 프로젝트 | `projects` | `p` | `p_sn` |
| 주문서 | `orders` | `o` | `o_sn` |
| 주문라인 | `order_lines` | `ol` | `ol_sn` |
| 주문라인 오버라이드 | `order_line_overrides` | `olo` | `olo_sn` |
| 수급케이스 | `sourcing_cases` | `sc` | `sc_sn` |
| 국내케이스 | `sourcing_cases( subtype=DOMESTIC )` | `dc` | `dc_sn` |
| 해외케이스 | `sourcing_cases( subtype=OVERSEAS )` | `oc` | `oc_sn` |
| 제작케이스 | `inhouse_cases` | `ic` | `ic_sn` |
| 업체(정산 주체) | `parties` | `pt` | `pt_sn` |
| 담당자 | `assignees` | `a` | `a_sn` |
| 비용 | `costs` | `ct` | `ct_sn` |
| 비용귀속 | `cost_allocations` | `ca` | `ca_sn` |
| 지급/결제 | `payments` | `pay` | `pay_sn` |
| 지급-비용 라인 | `payment_lines` | `pyl` | `pyl_sn` |
| 문서/증빙 | `documents` | `doc` | `doc_sn` |
| 문서-엔티티 연결 | `document_links` | `dl` | `dl_sn` |
| 납품 | `deliveries` | `dv` | `dv_sn` |

> 새 테이블 추가 시: “이미 사용 중인 약어”와 충돌하지 않게 정하고, 이 표를 업데이트한다.

### 8.2 테이블 prefix 패턴 (문서 도메인 포함)

자주 쓰는 엔티티 prefix는 다음과 같다.

- `p_` : projects
- `o_` : orders
- `ol_` : order_lines
- `olo_` : order_line_overrides
- `sc_` : sourcing_cases

(레거시 분리형 RFQ/PO — 보존)
- `rfq_` / `rfql_` / `rfqa_` : rfqs / rfq_lines / rfq_allocations
- `po_` / `pol_` / `poa_` : purchase_orders / po_lines / po_allocations
- `rfq_` / `rfql_` / `rfqa_` : rfqs / rfq_lines / rfq_allocations
- `po_` / `pol_` / `poa_` : purchase_orders / po_lines / po_allocations

(재무)
- `ct_` : costs
- `ca_` : cost_allocations
- `pay_` : payments
- `pyl_` : payment_lines
- `doc_` : documents
- `dl_` : document_links



#### 8.3 레거시(폐지): documents
- 과거 버전에서 `documents`/`과거_문서분리구조(payment)` 같은 “엔티티 전용 문서 테이블”을 논의했으나,
  현재 정본은 **문서 허브(`documents` + `document_links`)로 단일화**한다.
- 기존 표현을 참고해야 하는 경우에만 다음처럼 해석한다:
  - `documents` → `documents` (doc_category=PAYMENT)
  - `과거_문서분리구조(payment)` → `document_links` (target_type=PAYMENT, target_sn=pay_sn)


---

## 9. 비용/지급 모델 네이밍 규칙(요약)

### 9.1 costs(비용 원장)
- `costs`는 “비용 발생”을 기록한다.
- 지급 단계(선금/중도금/잔금)는 `payments/payment_lines`에서 표현하며, 비용 자체에는 중복 저장하지 않는다.

### 9.2 payments(지급 원장)
- `payments`는 “실제 결제 사건(카드/이체/현금)”을 기록한다.
- `payment_lines`로 어떤 비용(ct)을 얼마나 정산했는지 연결한다(다대다/부분지급 지원).
- 증빙은 `documents`(원본) + `document_links`(연결)로 `payments`에 연결한다.

---

## 10. 코드북(코드/상태/종류 값 표준) — 운영 입력/검증 기준

이 섹션은 `trade_terms`, `delivery_method`처럼 **코드/상태/종류**로 보이는 컬럼에 대해
**운영 시 어떤 값을 넣어야 하는지**를 표준화한다.

> 원칙: 코드값은 가능한 한 “열거형(enum)처럼 고정”한다.
> UI/백엔드에서 드롭다운으로 관리하고, 텍스트 임의 입력을 금지한다.

### 10.1 trade_terms (인도조건 / Incoterms)

**추천 값 집합(Incoterms 2020 기반, 대문자 고정):**
- `EXW` : 공장인도 (판매처/공장 인도, 구매자가 거의 전부 부담)
- `FCA` : 운송인 인도
- `FOB` : 본선인도 (해상)
- `CFR` : 운임포함 인도 (해상)
- `CIF` : 운임+보험료 포함 (해상)
- `CPT` : 운송비지급 인도
- `CIP` : 운송비+보험료지급 인도
- `DAP` : 도착지 인도(하역 제외)
- `DPU` : 도착지 인도(하역 포함) *(구 DAT 대체)*
- `DDP` : 관세지급 인도(판매자가 관세/세금까지 부담)

**운영 입력 규칙(핵심):**
- 국내 구매: 보통 Incoterms를 쓰지 않으므로 **NULL 허용(권장)**
  - 단, 국내에서도 계약서가 “인도조건”을 명시한다면 `DAP`(납품처 인도에 준함) 정도로 내부 표준화 가능
- 해외 구매: 가급적 **필수 입력(권장)**
  - 포워더/통관/관세 책임을 누가 지는지 판단 근거가 됨

**시나리오별 권장 매핑:**
- 해외 판매처 → 한국 창고까지 판매처 책임(문전 인도) + 관세는 구매자: `DAP`
- 해외 판매처가 관세/세금까지 모두 처리: `DDP`
- 해상 운송 + 보험 포함 조건: `CIF`
- 구매자가 모든 운송을 잡고 판매처에서 픽업: `EXW` 또는 `FCA`

**주의(데이터 품질):**
- `trade_terms`는 “가격조건”이 아니라 **책임경계선**이다.
- 운송/통관 비용 귀속(costs/allocations) 정책과 **반드시 함께** 맞춰야 한다.

---

### 10.2 delivery_method (발주 이후 물류 흐름의 방식)

운영 케이스(국내/해외 공통) 3가지를 “코드값”으로 표준화한다.

**추천 코드값(대문자, snake 없이 단어 2~3개):**

1) 물류팀이 판매처 방문 수거
- `PICKUP_BY_LOGISTICS`
  - 물류팀 담당자가 직접 판매처 방문 수거
  - 이후 경로는 logistics_job / stops로 표현 (직납/창고입고)

2) 판매처가 회사로 배송
- `SELLER_SHIP_TO_COMPANY`
  - 온라인몰/택배로 사무실 또는 회사 지정 주소로 도착
  - “사무실 → 창고” 이동은 별도 `logistics_job(TRANSFER)`로 기록

3) 판매처가 납품처로 직송
- `SELLER_SHIP_TO_CUSTOMER`
  - 회사가 실물을 통제하지 않으므로 inventory_unit 생략 가능
  - 단, 납품 증빙(송장/인수증)과 납품 완료 이력은 job/milestone로 남김(권장)

**추가로 해외에서 자주 필요한 값(선택 확장):**
- `FORWARDER_MANAGED` : 포워더 주도(해상/항공/내륙 연계)로 이동하는 케이스(보통 shipment가 주축)
- `COURIER` : 국제 특송(UPS/DHL/FedEx) 중심
- `FREIGHT_TRUCK` : 국내 화물/용달 중심

**입력 규칙:**
- `delivery_method`는 “PO 이후의 1차 방식”을 의미한다.
  실제 세부 흐름은 `shipments` 또는 `logistics_jobs`가 책임진다.
- 하나의 PO가 분할되어 여러 방식이 섞이면:
  - **PO 단위로 하나를 강제하지 말고**, shipment/job 단위로 기록한다.
  - (가능하면) PO에는 “대표값”으로만 두고, 실 흐름은 shipment/job의 method로 둔다.

---

### 10.3 procurement_mode (국내/해외/자체제작 등)
- `DOMESTIC`
- `OVERSEAS`
- `IN_HOUSE` (자체제작)
- (필요 시) `SERVICE` (용역성 구매)

**입력 규칙:**
- PO 생성 시 가능한 입력(권장). 이후 물류/환율 정책의 기본값에 영향.

---

### 10.4 fx_rate_policy (환율 적용 기준 “정책”)

이 값은 “자동 환율 계산”이 아니라, **팀이 어떤 기준을 쓰겠다는 메모/정책**이다.
실제 환율 숫자는 costs에 고정 저장한다.

**추천 값:**
- `QUOTE_DATE` : 견적일 기준 환율
- `PO_DATE` : 발주일 기준 환율
- `PAYMENT_DATE` : 지급일 기준 환율(회계/정산 관점)
- `CUSTOMS_DATE` : 통관일 기준 환율(관세/부가세 관점)
- `MANUAL` : 수동 입력(특수 케이스)

**운영 권장:**
- 원가/관리 목적이면 `PO_DATE` 또는 `CUSTOMS_DATE`가 현실적
- 회계/정산 일치가 중요하면 `PAYMENT_DATE`

---

### 10.5 logistics_jobs.job_type (작업 종류)
**추천 값:**
- `PICKUP` : 판매처 수거
- `TRANSFER` : 사무실↔창고, 창고↔창고 이동
- `DELIVERY` : 납품처 배송
- `MIXED` : 수거+납품 같이 수행(한 번에 끝)

---

### 10.6 logistics_job_stops.stop_type (정차 지점 종류)
- `VENDOR`
- `OFFICE`
- `WAREHOUSE`
- `CUSTOMER`
- (해외 확장) `PORT`, `AIRPORT`, `CUSTOMS`, `FORWARDER_HUB`

---

### 10.7 shipment_milestones.milestone_type (운송 이벤트)
**기본 값(국내/해외 공통):**
- `CREATED`
- `PICKED_UP`
- `IN_TRANSIT`
- `ARRIVED`
- `WAREHOUSE_IN`
- `DELIVERED`

**해외 확장(필요 시):**
- `DEPARTURE`
- `ARRIVAL_PORT`
- `CUSTOMS_CLEARANCE_START`
- `CUSTOMS_CLEARANCE_DONE`
- `INSPECTION`
- `DOMESTIC_DELIVERY`

---

### 10.8 inventory_units.status (바코드 실물 상태)
- `IN_TRANSIT`
- `IN_OFFICE`
- `IN_WAREHOUSE`
- `RESERVED_FOR_DELIVERY`
- `DELIVERED`
- `DAMAGED`
- `LOST`

**권장 상태 전이:**
`IN_OFFICE → IN_WAREHOUSE → RESERVED_FOR_DELIVERY → DELIVERED`

---

### 10.9 delivery_requests.status / proposals

**delivery_requests.status 추천:**
- `SUBMITTED`
- `COUNTERED`
- `ACCEPTED`
- `REJECTED`
- `CONFIRMED`
- `CANCELED`

**delivery_request_proposals.proposal_type 추천:**
- `INITIAL`
- `COUNTER`
- `ACCEPT`
- `REJECT`

---

## 11. 시나리오별 “어떤 코드값을 넣는지” 빠른 표

### 11.1 물류팀이 판매처 방문 수거 후 직납
- delivery_method: `PICKUP_BY_LOGISTICS`
- trade_terms: 국내면 NULL(또는 내부 표준 `DAP`), 해외면 실제 계약 Incoterms
- logistics_job: `MIXED`
- stops: `VENDOR → CUSTOMER`
- inventory_units: 현장 바코드 발급(권장) 또는 생략(정책 선택)

### 11.2 온라인몰 배송 → 사무실 도착 → 창고 이동
- delivery_method: `SELLER_SHIP_TO_COMPANY`
- logistics_job: `TRANSFER` (OFFICE → WAREHOUSE)
- inventory_units: 사무실 도착 시점에 필수 생성 + barcode

### 11.3 판매처 직송(회사 미경유)
- delivery_method: `SELLER_SHIP_TO_CUSTOMER`
- inventory_units: 보통 생략
- 납품 이력: logistics_job(DELIVERY, assignee=vendor or internal) 또는 shipment_milestones로 증빙

---

## (병합 수록) 추가 정본 정책 — Policy & Assumptions

## 7. 문서(RFQ/PO)의 진실성
- 실제로 업체에 전달한 문서(견적요청서 RFQ, 발주서 PO)와 그 라인 정보가
  구매/정산/증빙의 기준(“진실의 원천”)이다.
- 주문라인의 default/override는 **입력 편의 및 의사결정 기록** 목적이며,
  최종 실제 구매는 PO 라인을 기준으로 계산한다.

## A-8A. 문서 허브 정책 (documents + document_links)

### 목적
(아래 내용은 “문서 허브 정책”의 상세 설명이며, 본 문서의 정본 규칙이다.)

---

### 문서 허브 상세

### 목적
문서/증빙/서류 저장 위치를 케이스별로 쪼개지 않고, **`documents` 단일 테이블로 통합**한다.
문서가 무엇의 근거인지(비용/지급/인보이스/배송 등)는 **`document_links`(다대다, polymorphic)** 로 표현한다.

### 핵심 규칙
- 문서 파일은 항상 `documents` 로 수집한다.
- 문서의 상위 분류는 `doc_category`, 세부 유형은 `doc_type`으로 표현한다(코드값은 확장 가능).
- 문서가 어떤 엔티티의 근거인지(예: costs, payments, invoices, deliveries 등)는 **오직 `document_links`** 로 연결한다.
- 엔티티별로 별도의 **문서 전용 테이블**을 만들지 않는다. 문서는 `documents`에 저장하고, 관계는 `document_links`로 표현한다.


### 문서 코드 표준(권장; 확장 가능)


- `documents.doc_category`
  doc_category (권장 코드; 확장 가능)
  - COST: 비용/원가/부채 관련 근거 문서
  - PAYMENT: 지급/현금흐름 관련 증빙
  - INVOICE: 청구/요청/거래명세(인보이스)
  - PURCHASE: 조달/구매(발주, 견적 등)
  - DELIVERY: 배송/물류(운송, 인수, 검수)
  - CUSTOMS: 통관/무역 서류(B/L, 신고필증 등)
  - QUALITY: 품질/검수/시험 성적서
  - CONTRACT: 계약/약정/합의서
  - TAX: 세무(세금계산서, 계산서 등)
  - SETTLEMENT: 정산/대사(플랫폼/PG/카드사 청구 등)
  - REFUND: 환불/취소 관련
  - OTHER: 기타(설명은 note에 기재)

- `documents.doc_type`
  doc_type (권장 코드; 확장 가능)
  - CASH_RECEIPT: 현금영수증
  - CARD_APPROVAL: 카드 승인 내역(승인번호/금액/일시)
  - BANK_TRANSFER_RECEIPT: 계좌이체 영수증/송금확인
  - CARD_STATEMENT: 카드사 청구서(월 단위)
  - TAX_INVOICE: 전자/종이 세금계산서
  - BILL: 계산서(면세 등)
  - STATEMENT: 거래명세서/지급요청서(여러 발주 묶음 가능)
  - INVOICE: 청구서/인보이스(요청)
  - PURCHASE_DETAILS: 구매명세서/구매항목정보(셀러별 N개 가능)
  - QUOTE: 견적서
  - PO_DOC: 발주서(업무 문서)
  - DELIVERY_NOTE: 납품서/인수증/검수확인서
  - SHIPMENT_PROOF: 운송장/배송내역/송장(B/L 포함)
  - CUSTOMS_CLEARANCE: 통관서류(수입신고필증 등)
  - QUALITY_REPORT: 시험성적서/검사성적서/품질보고서
  - PLATFORM_SETTLEMENT: 플랫폼/PG 정산서(수수료/차감 포함)
  - REFUND_PROOF: 환불/취소 증빙(카드취소전표 등)
  - ETC: 기타(설명은 note에 기재)

- `document_links.target_type`
  target_type (권장 코드; 확장 가능)
  - PROJECT: projects(p_sn)
  - ORDER: orders(o_sn)
  - ORDER_LINE: order_lines(ol_sn)
  - SOURCING_CASE: sourcing_cases(sc_sn)
  - RFQ: rfqs(rfq_sn)
  - RFQ_LINE: rfq_lines(rfql_sn)
  - PURCHASE_ORDER: purchase_orders(po_sn)
  - PO_LINE: po_lines(pol_sn)
  - COST: costs(ct_sn)
  - PAYABLE: payables(pv_sn)
  - PAYMENT: payments(pay_sn)
  - INVOICE: invoices(inv_sn)
  - INVOICE_LINE: invoice_lines(invl_sn)
  - DELIVERY: deliveries(dv_sn)
  - DELIVERY_LINE: delivery_lines(dvl_sn)
  - SHIPMENT: shipments(sh_sn)
  - OTHER: 기타(설명은 note에 기재)

## B. RFQ/PO 통합 및 환율 고정 정책 (정본)

### B-1. 목표
운영 관점에서 국내/해외는 **“필수 필드 차이”**라기보다 **“옵션 필드 차이(통화/인도조건/국가/환율)”**에 더 가깝기 때문에,
RFQ/PO는 단일 테이블로 통합하는 것이 장기적으로 단순하다.

- RFQ/PO를 단일 테이블로 통합: `rfqs`, `purchase_orders`
- 국내/해외 차이는 옵션 컬럼으로 흡수
- 비용/지급은 기존 `costs`, `payments`, `cost_allocations` 구조 유지
- 환율 재현성(감사 대응)을 위해 비용에 적용 환율을 고정 저장

### B-2. 통합 테이블 개요

#### B-2.1 RFQ(견적요청)
- `rfqs` / `rfq_lines` / `rfq_allocations`
- 국내/해외 공통 필드: 업체, 작성자, 상태, 발행일, 라인 품목/수량, 회신 정보
- 해외 옵션 필드(필요 시만 채움): `trade_terms`, `ship_from_country`, `ship_to_country`

#### B-2.2 PO(발주)
- `purchase_orders` / `po_lines` / `po_allocations`
- 국내/해외 공통 필드: 업체, 작성자, 상태, 발행/수락, 납기, 결제/부가세
- 해외 옵션 필드: `trade_terms`, `ship_from_country`, `ship_to_country`
- 해외 통화는 라인 단위 `po_lines.currency`로 관리(국내는 기본 KRW)

### B-3. 국내/해외 구분 정책

#### B-3.1 소스 오브 트루스
- 주문라인의 수급 방식은 `sourcing_cases.sourcing_type`가 **최종 기준**
- RFQ/PO 헤더의 `sourcing_type`는 **필터/조회 편의용(선택)**

#### B-3.2 필수/옵션 규칙(권장)
- DOMESTIC:
  - `ship_from_country/ship_to_country/trade_terms`는 NULL 허용
  - `po_lines.currency`는 KRW 사용 권장
- OVERSEAS:
  - `po_lines.currency`는 실제 매입 통화로 입력(USD/EUR/CNY 등)
  - `trade_terms`는 가능하면 입력(인도조건)
  - 환율/원화 환산이 필요한 비용은 `cost_fx_applications`로 고정

### B-4. 비용/환율 처리(기존 finance 구조 존중)

#### B-4.1 비용 귀속
- 비용 원장: `costs`
- 비용 배분/안분: `cost_allocations`
- PO에 속한 비용을 빠르게 찾기 위한 연결: `po_cost_links` (조회용)

> 원가/마진 계산은 항상 `cost_allocations`를 기준으로 수행하고,
> `po_cost_links`는 "탐색"과 "UI 편의" 용도로만 사용한다.

#### B-4.2 환율 재현(감사 대응)
해외 비용은 시점에 따라 환율이 달라지므로, **정산 시점에 적용한 환율과 원화 환산 결과를 고정**해야 한다.

- 권장 방식: `cost_fx_applications`
  - `applied_fx_rate`, `as_of_dt`, `base_amount(KRW)` 저장
  - 필요하면 `fx_sn`으로 환율 마스터(`fx_rates`) 참조

### B-5. 운영 예시

#### B-5.1 국내 RFQ → PO
- `rfqs.sourcing_type = DOMESTIC` (또는 NULL)
- `rfq_lines.reply_currency = 'KRW'`
- `purchase_orders.po_status` 전개: DRAFT → SENT → ACCEPTED

#### B-5.2 해외 PO + 비용(USD) + 환율 고정
- `po_lines.currency = 'USD'`
- 통관비/포워딩 비용을 `costs`에 등록(통화 USD)
- 정산 시점 환율을 `cost_fx_applications`에 저장:
  - `src_currency='USD'`, `src_amount=...`, `applied_fx_rate=...`, `base_amount(KRW)=...`

---

## (정본) 거래처(Parties) 운영 원칙 — v7.9.7 기준

## (정본) 비용/지급/증빙(재무) 모델 — v7.9.7 기준

---

## (정본 통합) PO After 확장 엔티티/네이밍/연결 정책 — v7.9.7

### 1) RFQ/PO 단일화(정본)
- RFQ: `rfqs`, `rfq_lines`, `rfq_allocations`
- PO: `purchase_orders`, `po_lines`, `po_allocations`
- 국내/해외 차이는 테이블 분리가 아니라 **옵션 컬럼(통화/인도조건/국가/환율 등)**으로 흡수한다.

### 2) PO After 확장 축(정본 유지)
발주 이후(물류/배송/재고/협의) 영역은 아래 엔티티로 확장한다.

1. 실물(바코드): `inventory_units`
2. 운송: `shipments` + `shipment_milestones` (+ `shipment_items`)
3. 작업: `logistics_jobs` + `logistics_job_stops` + `logistics_job_lines`
4. 협의: `delivery_requests` + `delivery_request_lines` + `delivery_request_proposals`

### 3) `_lines` / `_allocations` / `_links` 의미(불변)
- `*_lines`: 문서/목록의 세부 항목(줄)
- `*_allocations`: 배분/안분(금액/수량을 여러 대상으로 나눔)
- `*_links`: 단순 연결(association)
  - 주의: 정산의 기준은 링크가 아니라 **항상 `cost_allocations`**

### 4) 비용/환율/정산(정본)
- 비용 원장: `costs`
- 지급 원장: `payments`
- 비용 귀속/안분의 정답: `cost_allocations`
- 빠른 탐색/분류/조회용 보조 연결(정본 허용, 회계 기준 아님):
  - `po_cost_links`
  - `shipment_cost_links`
  - `logistics_job_cost_links`

환율 재현성(감사 대응):
- 권장: `cost_fx_applications`(+ 필요 시 `fx_rates`)
- “적용한 환율/원화환산 결과”는 정산 시점 기준으로 **고정 저장**한다.

### 5) 문서(증빙) 정책(정본)
- 모든 문서/증빙/첨부는 `documents`에 단일 저장
- 무엇의 근거인지(비용/지급/인보이스/배송/작업 등)는 `document_links`로 연결
- 엔티티별 전용 문서 테이블을 만들지 않는다.

---

# (정본 병합) v7.9.1/v7.9 문서에서 가져온 유효 내용 보강

아래 내용은 v7.9~v7.9.1 문서에서 **현재 정본(v7.9.7)에도 유효한 정책/템플릿만**을 추려,
deprecated 구조를 **정본 구조로 재작성(Rewrite)** 한 뒤 병합(Merge)한 것이다.

## (추가 병합) 문서 타입 권장 목록 보강

아래 `doc_type` 값은 “권장 기본값”이며, 회사/프로세스에 따라 확장 가능하다.
(정본 원칙: 상위 분류는 `doc_category`, 세부 분류는 `doc_type`)

### PAYMENT 계열(doc_category='PAYMENT')
- `CARD_SLIP` : 카드 승인 전표/매출전표
- `TRANSFER_PROOF` : 이체 확인/입금 확인 증빙
- `REFUND_SLIP` : 환불/취소 전표
- `CARD_STATEMENT` : 카드사 청구서/명세서(월별)

### COST 계열(doc_category='COST')
- `SELLER_RECEIPT` : 판매자 영수증(오픈마켓 셀러 영수증 포함)
- `TAX_INVOICE` : 세금계산서
- `STATEMENT` : 거래명세서
- `INVOICE` : 해외 인보이스(문서 원본)
- `PACKING_LIST` : 패킹리스트
- `BILL_OF_LADING` : B/L
- `AIR_WAYBILL` : AWB
- `CUSTOMS_DOCUMENT` : 통관 관련 서류

### WORK 계열(doc_category='WORK')
- `PO_PDF` : 발주서 PDF/스캔본 등(업무 문서)
- `RFQ_PDF` : 견적요청서 PDF/스캔본 등(업무 문서)

---

# (정본 병합) v7.8.0에서 보강된 시간 컬럼 규칙

아래 내용은 v7.8.0 문서에서 **현재 정본(v7.9.7)에도 유효한 규칙**을 선별하여,
deprecated 구조를 **정본 구조로 재작성(Rewrite)** 한 뒤 병합(Merge)한 것이다.

## 1. 엔티티 메타 컬럼 규칙 (생성/수정 시각)

엔티티(테이블) 레코드 자체의 생명주기를 나타내는 컬럼은 반드시 다음 규칙을 따른다.

- `{abbr}_create_dt`
- `{abbr}_update_dt`

예시:
- `projects.p_create_dt`, `projects.p_update_dt`
- `payments.pay_create_dt`, `payments.pay_update_dt`
- `payment_lines.pyl_create_dt`, `payment_lines.pyl_update_dt`

---

## 2. 비즈니스 이벤트 시각 규칙

업무 이벤트/상태 변화 시각은 약어 prefix를 사용하지 않고, 의미 기반의 `*_at` 컬럼을 사용한다.

예시:
- `issued_at` : 문서 발행 시각
- `replied_at` : 견적 회신 시각
- `paid_at` : 지급 완료 시각
- `occurred_at` : 비용 발생 시각

> `*_create_dt`, `*_update_dt`는 “DB 레코드”의 생성/수정 시간,  
> `*_at`는 “업무 이벤트” 시간이다.

---

---

## (추가 병합) Invoice/Payable/Payment 정책·코드북 보강 (v7.8.2 → v7.9.7 정본)

이 섹션은 v7.8.2 재무 설계 메모/정책에서 **현재 정본(v7.9.7)에도 유효한 개념/코드 표준만**을 선별해,
deprecated 표현을 정본 구조로 **재작성(Rewrite)** 한 뒤 병합(Merge)한 것이다.

### 1) 엔티티 역할 정의(정본)

- `costs` : **비용 사실(원장)**  
  - 결제 여부와 무관하게 “비용이 발생했다”는 사실을 기록한다.
  - 프로젝트/주문/라인/수급케이스 등 어디에 귀속되는지는 `cost_allocations`로 표현한다.

- `invoices` / `invoice_lines` : **외부 거래/청구 문서 컨테이너**  
  - **Invoice는 지급 단위가 아니다.**
  - invoice는 여러 payable로 **분할 지급**될 수도 있고, 여러 invoice가 하나의 payable로 **묶음 지급**될 수도 있다.
  - 물품/서비스/세금/할인 등 항목은 `invoice_lines`로 관리한다.

- `payables` : **내부 지급 단위(재무 업무 단위)**  
  - 승인/보류/기한/부분지급/마감 등 “업무 큐”는 `payables`가 책임진다.
  - payable이 커버하는 invoice는 `payable_invoice_allocations`로,
    payable이 정산하는 cost는 `payable_cost_allocations`로 연결한다.

- `payments` : **실지급 결과(현금흐름)**  
  - 실제 돈이 나간 기록만 담는다(카드/이체/현금).
  - 어떤 비용을 얼마나 정산했는지는 `payment_lines`로 연결한다.
  - payment ↔ payable 연결은 `payment_payable_allocations`로 표현한다(분할/묶음 지급 지원).

### 2) 운영 불변 정책(정본)

#### 2.1 PO 1건 = cost 1건 (불변)
- 발주서 1건을 비용 1건으로 매핑한다(권장: `po_cost_links`로 1:1을 유지).
- 멀티셀러/사업자 단위 분리가 필요하면 **PO를 분할 생성**한다.
- 분할이 불필요하면 **PO=cost 단위**로 묶고, 판매자별 거래 증빙(N장)은 비용(cost)에 연결한다.

> 주의: “PO=cost”는 업무 편의/정산 단순화를 위한 **운영 정책**이며,  
> 실제 품목/프로젝트/라인 귀속은 `cost_allocations`가 정답이다.

#### 2.2 문서/증빙(정본)
- 모든 문서/증빙/첨부는 `documents`에 저장한다.
- 문서가 무엇의 근거인지(비용/지급/invoice/배송/작업 등)는 `document_links`로 연결한다.
- 권장 분류:
  - 거래/원가 증빙: `documents.doc_category='COST'` → `document_links(target_type in {costs, invoices, shipments, ...})`
  - 지급/현금흐름 증빙: `documents.doc_category='PAYMENT'` → `document_links(target_type='payments')`

### 3) 코드북(ENUM/코드 값) — 운영 입력 표준

#### 3.1 invoices
- `invoice_status` : `RECEIVED` / `CONFIRMED` / `DISPUTED` / `VOID`
- `source_channel` : `VENDOR` / `PLATFORM` / `INTERNAL`
- `invoice_type` : `STATEMENT` / `TAX_INVOICE` / `RECEIPT` / `OTHER`

#### 3.2 invoice_lines
- `line_type` : `GOODS` / `CHARGE`

`charge_category` (권장 표준값; 확장 가능)
- `SHIPPING_DOMESTIC`
- `SHIPPING_INTERNATIONAL`
- `CUSTOMS_DUTY`
- `CUSTOMS_BROKER_FEE`
- `INSPECTION_FEE`
- `WAREHOUSE_FEE`
- `PACKAGING_FEE`
- `INSURANCE_FEE`
- `HANDLING_FEE`
- `SERVICE_FEE`
- `TAX`
- `DISCOUNT`
- `OTHER`

#### 3.3 payables
- `payable_status` : `CREATED` / `APPROVED` / `ON_HOLD` / `PARTIALLY_PAID` / `PAID` / `CANCELED`
- `priority_level` : `LOW` / `NORMAL` / `HIGH`
