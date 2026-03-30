# Left-over (Unsorted / Meta / Legacy-preservation)

과거 문서 내용들로서, 챗지피티에 의해 온전히 이전되지 못한 내용들을 보관하기 위한 공간이다.
최신 정보 데이터가 반영되지 않은 부분들이 남아 있으므로, 최신정본 MD와, 특히 DDL 문서를 최우선 해야한다.


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
- 해외 통화는 라인 단위 `po_lines.ccy`로 관리(국내는 기본 KRW)

### B-3. 국내/해외 구분 정책

#### B-3.1 소스 오브 트루스
- 주문라인의 수급 방식은 `sourcing_cases.sourcing_type`가 **최종 기준**
- RFQ/PO 헤더의 `sourcing_type`는 **필터/조회 편의용(선택)**

#### B-3.2 필수/옵션 규칙(권장)
- DOMESTIC:
  - `ship_from_country/ship_to_country/trade_terms`는 NULL 허용
  - `po_lines.ccy`는 KRW 사용 권장
- OVERSEAS:
  - `po_lines.ccy`는 실제 매입 통화로 입력(USD/EUR/CNY 등)
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
- `rfq_lines.reply_ccy = 'KRW'`
- `purchase_orders.po_status` 전개: DRAFT → SENT → ACCEPTED

#### B-5.2 해외 PO + 비용(USD) + 환율 고정
- `po_lines.ccy = 'USD'`
- 통관비/포워딩 비용을 `costs`에 등록(통화 USD)
- 정산 시점 환율을 `cost_fx_applications`에 저장:
  - `src_ccy='USD'`, `src_amount=...`, `applied_fx_rate=...`, `base_amount(KRW)=...`

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
