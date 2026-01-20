# Balhea ERP 스키마 네이밍 및 운영 정책서 (정본 v7.9.1)

본 문서는 Balhea ERP 스키마/운영 규칙의 “정답”을 고정한다.

> 주의: 본 문서에는 “과거/레거시/마이그레이션” 관점의 서술이 없다. 현재의 단일 정본만 다룬다.

---

## A. 도메인/운영 정책

# Balhea 조달/주문/수급 정책서 (정본 요약)

본 문서는 대화에서 합의된 요구사항과 설계 의도를 정리한 정책서다. 

---

## 1. 비즈니스/프로젝트 모델
- 프로젝트(Project)는 계약 단위이며, 기본적으로 **프로젝트 1개 = 계약 1개**를 다룬다.
- 프로젝트 유형 예시:
 - `TENDER` : 공공 입찰(단건 입찰 포함)
 - `DIRECT` : 민간/직접 계약
 - `FRAME` : 장기/콜오프(기간 내 다수 주문 발생 가능)

## 2. 주문(Orders) / 주문라인(Order Lines)
- `orders`는 프로젝트 하위의 실제 주문 단위(단건이면 1개, 다건이면 다수).
- `order_lines`는 고객에게 납품해야 할 약속 단위(요구 품목/수량/규격).

## 3. 99% 경로(운영 편의성 우선)
- 대부분의 케이스는 **주문라인 1개 = 실제 구매/납품 상품(goods) 1개**다.
- `order_lines.ol_default_g_sn`(기본 goods FK)을 제공한다.
- RFQ/PO 생성 시:
 - override가 없다면 `ol_default_g_sn`을 사용해 문서 라인을 자동 생성한다.

## 4. 희소 케이스(1% 내외) — Override 패턴
희소 케이스(재고부족 분할, 대체품 일부, 불량 추가구매, PC 조합 등)는 
`order_line_overrides`로만 수용한다.

- override 유형:
 - `SPLIT` : 수량을 나누어 여러 상품/여러 발주로 처리
 - `SUBSTITUTE` : 일부를 유사 대체품으로 처리
 - `ADD_ON` : 불량/추가요청 등으로 추가 구매
 - `BUNDLE` : 조합 납품(PC 등) 구성품 구매 단위

- 문서 생성 규칙:
 - override가 있으면 override를 우선 전개하여 RFQ/PO 라인을 만든다.
 - override가 없으면 default goods를 사용한다.

## 5. 수급 케이스(Sourcing Case)
- 수급 케이스는 `sourcing_cases(sc_sn)`가 “현재 유효” 값을 가진다.
- 유효한 수급 방식은 동시에 1개로 제한하며, 변경 이력은 로그/감사 테이블로 남긴다.
- RFQ/PO 라인과의 배정은 allocation 테이블에서 `sc_sn`으로 묶는다.

## 6. 후보군 비교(드라이버/CPU/모니터 등)
- 후보 비교의 그룹 키는 `goods`가 아니라 **`order_line` 또는 `sc_sn`**이다.
- BUNDLE(PC)처럼 한 `sc_sn` 안에 구성품이 섞일 수 있으므로,
 RFQ/PO allocation에서 `olo_sn`(구성품 키)을 사용할 수 있어야 한다.

## 7. 거래처(Parties) 운영 원칙(정산 주체만)
- Parties는 “정산/결제 상대(플랫폼/업체)” 단위로만 관리한다.
 - 예: 네이버, 쿠팡, 알리익스프레스, 해외 벤더 등
- 퀵/대행/비정형 지출은 **예약된 party 1개(pt_sn)**로 처리하고,
 상세 판매자(오픈마켓 셀러 등)는 party로 분해하지 않는다.

## 8. 비용/지급/증빙(재무) 원칙

### 8.1 costs(비용 발생)
- `costs`는 비용 발생(사유/금액/발생일)을 기록한다.
- 비용은 특정 주문/라인/override/수급(sc_sn)에 귀속될 수 있으며,
 귀속은 `cost_allocations`로만 관리한다(원장은 단순 유지).

### 8.2 cost_allocations(비용 귀속)
- 비용 귀속 대상은 다음을 지원한다:
 - `p_sn` (프로젝트 단위)
 - `o_sn` (주문서 단위)
 - `ol_sn` (주문라인 단위)
 - `olo_sn` (override 단위: 구성품/분할/대체)
 - `sc_sn` (수급 케이스 단위)
- 퀵 비용은 PO가 아니라 **cost + allocation**으로만 귀속한다.

### 8.3 payments(실제 지급) / payment_lines(지급-비용 매핑)
- `payments`는 실제 지급 사건(카드/이체/현금)을 기록한다.
- `payment_lines`는 “이 지급이 어떤 비용(들)을 얼마만큼 정산했는지”를 연결한다.
- 선금/중도금/잔금 같은 단계는 `payment_lines.note`(또는 UI 라벨)로 표현한다. 
 (비용(costs)이나 PO-비용 링크에 중복 저장하지 않는다.)

### 8.4 payment_payment_documents(지급 증빙)
- 카드전표/이체확인/영수증 묶음 등 증빙은 `payment_documents`로 저장하고,
 `payment_payment_documents`로 `payments`에 연결한다.
- 오픈마켓 셀러 다수 케이스는 party 분해 없이,
 `payment_documents.issuer_name`에 표시명(셀러명)을 저장하고 payment에 일괄 첨부한다.


### 8.1 Invoice / Payable / Payment 모델(외부 문서 vs 내부 지급 단위 vs 실지급)

재무 데이터는 아래 3개의 “역할 분리”를 전제로 설계한다.

- **Invoice(`invoices`)**: 거래처/플랫폼/발행자가 제공하는 **외부 문서 컨테이너**
 - invoice 자체는 “지급 단위”가 아니다.
 - 영수증/세금계산서/거래명세서 등 문서 원본과 문서 라인(`invoice_lines`)을 담는다.
- **Payable(`payables`)**: 내부에서 관리하는 **지급 단위(결재/보류/대기/분할지급의 기준)**
 - “지급 요청”, “승인”, “보류”, “부분 지급”, “완료” 같은 상태는 payable이 가진다.
- **Payment(`payments`)**: **실제로 돈이 나간 기록(결과)**
 - payment는 “실지급이 발생한 사실”만 기록한다.
 - 승인/보류/대기 같은 상태는 payment에 두지 않고 payable에서 관리한다.

#### (1) 기본 연결 규칙
- payable 1건은 여러 invoice를 포함할 수 있으며, 그 연결은 `payable_invoice_allocations`로 관리한다.
- payable 1건은 여러 cost에 안분될 수 있으며, 그 연결은 `payable_cost_allocations`로 관리한다.
- payment 1건은 여러 payable에 안분(또는 1:1 연결)될 수 있으며, 그 연결은 `payment_payable_allocations`로 관리한다.

#### (2) 문서 첨부(증빙) 정책
- **비용 증빙(영수증/세금계산서 등)**은 `cost_documents`에 첨부한다.
 - 종합몰/플랫폼 결제처럼 “결제 1건에 판매자별 영수증이 여러 장”인 경우에도 cost_documents로 다중 첨부가 가능해야 한다.
- **지급 증빙(이체확인/카드승인/정산내역 등)**은 `payment_documents`에 첨부한다.

#### (3) 확정 코드값(ENUM) / 유동 코드값(VARCHAR) 운영 원칙(재무)
- 아래처럼 “상태가 거의 확정”이고 시스템 로직이 강하게 의존하는 값은 **ENUM**으로 고정한다.
 - `invoices.doc_type` (예: `SELLER_RECEIPT`, `STATEMENT`, `TAX_INVOICE`, `OTHER`)
 - `invoice_lines.line_type` (예: `GOODS`, `CHARGE`)
 - `payables.payable_status` (예: `CREATED`, `APPROVED`, `ON_HOLD`, `PARTIALLY_PAID`, `PAID`, `CANCELLED`)
- 반대로, 회사/고객/플랫폼별로 확장될 여지가 있는 값은 **VARCHAR + COMMENT**로 두고,
 COMMENT에 “권장 값 + 확장 가능”을 명시한다.


## 9. PO-비용 링크(link_type) 정책 (A안)
- `*_po_cost_links.link_type`는 “지급 단계(선금/잔금)”를 표현하지 않는다.
- `link_type`는 PO 관련 **부대비용 성격 분류** 용도로만 사용한다.
 - 예: `FREIGHT`, `CUSTOMS`, `INSPECTION`, `ETC`
- 지급 단계(선금/중도금/잔금)는 payments/payment_lines에만 기록한다.


---

## B. RFQ/PO 통합 및 환율 고정 정책


## 1. 목표

운영 관점에서 국내/해외는 **“필수 필드 차이”**라기보다 **“옵션 필드 차이(통화/인도조건/국가/환율)”**에 더 가깝기 때문에,
RFQ/PO는 단일 테이블로 통합하는 것이 장기적으로 단순합니다.

본 정책은 다음을 달성합니다.
- RFQ/PO를 단일 테이블로 통합: `rfqs`, `purchase_orders`
- 국내/해외 차이는 옵션 컬럼으로 흡수
- 비용/지급은 기존 `costs`, `payments`, `cost_allocations` 구조 유지
- 환율 재현성(감사 대응)을 위해 비용에 적용 환율을 고정 저장

## 2. 통합 테이블 개요

### 2.1 RFQ(견적요청)
- `rfqs` / `rfq_lines` / `rfq_allocations`
- 국내/해외 공통 필드: 업체, 작성자, 상태, 발행일, 라인 품목/수량, 회신 정보
- 해외 옵션 필드(필요 시만 채움): `trade_terms`, `ship_from_country`, `ship_to_country`

### 2.2 PO(발주)
- `purchase_orders` / `po_lines` / `po_allocations`
- 국내/해외 공통 필드: 업체, 작성자, 상태, 발행/수락, 납기, 결제/부가세
- 해외 옵션 필드: `trade_terms`, `ship_from_country`, `ship_to_country`
- 해외 통화는 라인 단위 `po_lines.currency`로 관리(국내는 기본 KRW)

## 3. 국내/해외 구분 정책

### 3.1 소스 오브 트루스
- 주문라인의 수급 방식은 `sourcing_cases.sourcing_type`가 **최종 기준**
- RFQ/PO 헤더의 `sourcing_type`는 **필터/조회 편의용(선택)**

### 3.2 필수/옵션 규칙(권장)
- DOMESTIC:
 - `ship_from_country/ship_to_country/trade_terms`는 NULL 허용
 - `po_lines.currency`는 KRW 사용 권장
- OVERSEAS:
 - `po_lines.currency`는 실제 매입 통화로 입력(USD/EUR/CNY 등)
 - `trade_terms`는 가능하면 입력(인도조건)
 - 환율/원화 환산이 필요한 비용은 `cost_fx_applications`로 고정

## 4. 비용/환율 처리(기존 finance 구조 존중)

### 4.1 비용 귀속
- 비용 원장: `costs`
- 비용 배분/안분: `cost_allocations`
- PO에 속한 비용을 빠르게 찾기 위한 연결: `po_cost_links` (조회용)

> 원가/마진 계산은 항상 `cost_allocations`를 기준으로 수행하고,
> `po_cost_links`는 "탐색"과 "UI 편의" 용도로만 사용합니다.

### 4.2 환율 재현(감사 대응)
해외 비용은 시점에 따라 환율이 달라집니다. 따라서 **정산 시점에 적용한 환율과 원화 환산 결과를 고정**해야 합니다.

- 권장 방식(본 DDL 제공): `cost_fx_applications`
 - `applied_fx_rate`, `as_of_dt`, `base_amount(KRW)`를 저장
 - 필요하면 `fx_sn`으로 환율 마스터(`fx_rates`) 참조



## 6. 운영 예시

### 6.1 국내 RFQ → PO
- `rfqs.sourcing_type = DOMESTIC` (또는 NULL)
- `rfq_lines.reply_currency = 'KRW'`
- `purchase_orders.po_status` 전개: DRAFT → SENT → ACCEPTED

### 6.2 해외 PO + 비용(USD) + 환율 고정
- `po_lines.currency = 'USD'`
- 통관비/포워딩 비용을 `costs`에 등록(통화 USD)
- 정산 시점 환율을 `cost_fx_applications`에 저장:
 - `src_currency='USD'`, `src_amount=...`, `applied_fx_rate=...`, `base_amount(KRW)=...`


---

## C. 네이밍/컬럼 규칙

# Balhea SQL 컬럼 네이밍 가이드 (MySQL)

본 문서는 Balhea ERP 스키마 설계/개발 시 **컬럼명 규칙을 일관되게 적용**하기 위한 가이드입니다. 
특히 PK/FK 규칙, 엔티티 메타 컬럼(`*_create_dt`, `*_update_dt`)과 비즈니스 이벤트 시각(`*_at`)을 명확히 구분합니다.

---

## 0. 핵심 원칙

### 0.1 테이블명
- **복수형** 사용 
 예: `projects`, `orders`, `order_lines`, `costs`, `payments`

### 0.2 PK 규칙
- 모든 테이블 PK는 다음 규칙을 따른다.
 - `[{table_abbr}]_sn BIGINT UNSIGNED AUTO_INCREMENT`

예시:
- `projects.p_sn`
- `orders.o_sn`
- `order_lines.ol_sn`
- `sourcing_cases.sc_sn`
- `costs.ct_sn`
- `payments.pay_sn`

### 0.3 FK 규칙
- FK는 **참조 대상의 PK 컬럼명과 동일**하게 사용한다.
 - `orders.p_sn`
 - `order_lines.o_sn`
 - `cost_allocations.sc_sn`

---

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

## 3. 상태/유형 컬럼 규칙

- 상태: `*_status`
- 유형: `*_type`
- ENUM은 `COMMENT`에 값:설명(요약)을 반드시 포함

---

## 4. 약어(테이블 prefix) 표

자주 쓰는 엔티티 약어는 다음과 같다.

- `p_` : projects
- `o_` : orders
- `ol_` : order_lines
- `olo_` : order_line_overrides
- `sc_` : sourcing_cases
- `drfq_` / `drfql_` / `drfqa_` : domestic_rfqs / domestic_rfq_lines / domestic_rfq_allocations
- `dpo_` / `dpol_` / `dpoa_` : domestic_purchase_orders / domestic_po_lines / domestic_po_allocations
- `orfq_` / `orfql_` / `orfqa_` : overseas_rfqs / overseas_rfq_lines / overseas_rfq_allocations
- `opo_` / `opol_` / `opoa_` : overseas_purchase_orders / overseas_po_lines / overseas_po_allocations
- `ct_` : costs
- `ca_` : cost_allocations
- `pay_` : payments
- `pyl_` : payment_lines
- `doc_` : documents
- `pd_` : payment_documents

---

## 5. 비용/지급 모델 네이밍 규칙

### 5.1 costs(비용 원장)
- `costs`는 “비용 발생”을 기록한다.
- 지급 단계(선금/중도금/잔금)는 `payments/payment_lines`에서 표현하며, 비용 자체에는 중복 저장하지 않는다.

### 5.2 payments(지급 원장)
- `payments`는 “실제 결제 사건(카드/이체/현금)”을 기록한다.
- `payment_lines`로 어떤 비용(ct)을 얼마나 정산했는지 연결한다(다대다/부분지급 지원).
- 증빙은 `documents` + `payment_documents`로 `payments`에 연결한다.


---

## D. 코드북(코드/상태/종류 값 표준)

이 섹션은 `*_sn` 같은 FK 숫자값/국가코드처럼 “자명한 값”이 아니라,
`trade_terms`, `delivery_method`처럼 **코드/상태/종류**로 보이는 컬럼에 대해
**실제 운영 시나리오에서 어떤 값을 넣어야 하는지**를 표준화한다.

> 원칙: **코드값은 가능한 한 “열거형(enum)처럼 고정”**한다. 
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
- 국내 구매: 보통 Incoterms를 쓰지 않으므로 **NULL 허용**(권장) 
 - 단, 국내에서도 계약서가 “인도조건”을 명시한다면 `DAP`(납품처 인도에 준함) 정도로 내부 표준화 가능
- 해외 구매: 가급적 **필수 입력**(권장)
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
너희 운영 케이스(국내/해외 공통) 3가지를 “코드값”으로 표준화한다.

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
IN_OFFICE → IN_WAREHOUSE → RESERVED_FOR_DELIVERY → DELIVERED

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

## 문서 허브 정책 (documents + document_links)

### 목적
문서/증빙/서류 저장 위치를 케이스별로 쪼개지 않고, **`documents` 단일 테이블로 통합**한다.
문서가 무엇의 근거인지(비용/지급/인보이스/배송 등)는 **`document_links`(다대다, polymorphic)** 로 표현한다.

### 핵심 규칙
- 문서 파일은 항상 `documents` 로 수집한다.
- 문서의 상위 분류는 `doc_category`, 세부 유형은 `doc_type`으로 표현한다(코드값은 확장 가능).
- 문서가 어떤 엔티티의 근거인지(예: costs, payments, invoices, deliveries 등)는 **오직 `document_links`** 로 연결한다.
- 엔티티 전용 문서 테이블(예: cost_documents, payment_documents)은 사용하지 않는다.


## 문서 코드 표준(권장; 확장 가능)


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
