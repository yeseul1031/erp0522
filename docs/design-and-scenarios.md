---
project: "ERP Data Guide"
repo: "erp-data-guide"
file: "docs/design-and-scenarios.md"
version: "7.9.7"
date: "2026-01-21"
summary: "데이터 입력 예시(정본) 및 역사 보존 예시 재배치/통합"
---

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

현금영수증은 **지급(결제) 증빙 문서**이므로 `documents`에 저장하고, 해당 `payments`(또는 `expenses`)와의 관계는 `document_links`로 연결한다.

### 2.5 감사 및 추적
- activity_logs: 주요 행위 기록
- audit_logs: 값 변경 이력

외래키 대신 로그를 통해 “누가 언제 무엇을 바꿨는지”를 추적한다.

---

---

## 2.6 정본 설계 정책 (Policy & Assumptions 통합)

아래 섹션은 과거 버전의 정책/가정 문서에서 **현재 정본(v7.9.7) 스키마에도 유효한 내용만**을 선별하여,
현재 구조(단일 `rfqs`/`purchase_orders`, 문서 허브 `documents + document_links`, override 패턴 등)에 맞게 **병합/정리**한 것이다.

- 과거 문서에서 **폐지된 엔티티(domestic_*, *_documents 등)** 를 전제로 한 표현은 본문에 남기지 않는다.
- 동일한 정책이 본문/부록에 중복되는 경우, **더 풍부한 설명/템플릿**을 기준으로 이 섹션을 정본으로 삼고,
  나머지는 참조용으로만 유지한다.

## 3. 99% 경로(운영 편의성 우선)
- 대부분의 케이스는 **주문라인 1개 = 실제 구매/납품 상품(goods) 1개**다.
- 업무자는 주문서를 작성/검토하는 시점에 “실제로 어떤 기성품(goods)을 수급해서 납품할지”를 결정한다.
- 이를 위해 `order_lines.ol_default_g_sn`(기본 goods FK)을 제공한다.
- RFQ/PO 생성 시:
  - override가 없다면 `ol_default_g_sn`을 사용해 문서 라인을 자동 생성한다.

## 4. 희소 케이스(1% 내외) — Override 패턴
희소 케이스(재고부족 분할, 대체품 일부, 불량 추가구매, PC 조합 등)는
전체 스키마를 복잡하게 만들지 않기 위해 `order_line_overrides`로만 수용한다.

- override 유형:
  - `SPLIT` : 수량을 나누어 여러 상품/여러 발주로 처리
  - `SUBSTITUTE` : 일부를 유사 대체품으로 처리
  - `ADD_ON` : 불량/추가요청 등으로 추가 구매
  - `BUNDLE` : 조합 납품(PC 등) 구성품 구매 단위
- 문서 생성 규칙:
  - override가 있으면 override를 우선 전개하여 RFQ/PO 라인을 만든다.
  - override가 없으면 default goods를 사용한다.
- 변경 이력은 `audit_changes`에 JSON 기반으로 남긴다.

## 5. 수급 담당/협업(Assignee)
- 프로젝트는 단일 담당자가 관리(병렬 공동관리 없음).
- 주문라인 단위로 협업 담당자(수급 담당자)를 지정할 수 있다.
- 협업 담당자는 자신에게 할당된 라인만 중심으로 보되,
  문서(RFQ/PO)는 여러 프로젝트/라인이 혼합될 수 있으므로
  프로젝트 담당자는 **참고 목적으로** 혼합 문서를 조회할 수 있다.
- 담당자 변경은 드물며, 퇴사/인계 시 변경하고 로그만 남긴다(기간별 성과 분할 최소화).

## 6. 수급 방식(Sourcing Type) 및 도메인 분리
- 수급 방식은 `sourcing_cases`에서 관리:
  - `DOMESTIC` : 국내 구매(견적→발주→납품)
  - `OVERSEAS` : 해외 구매(통화/인코텀즈/운송/통관 등 추가)
  - `IN_HOUSE` : 자체 제작(재료 수급 + 생산/검수 등 별도 프로세스)
- 수급 방식은 업무 중 변경될 수 있다(국내→해외→국내 등).
  - 스키마를 과도하게 복잡하게 만들기보다, 현재 활성 타입을 갱신하고 이력은 `audit_changes`/`activity_logs`로 남긴다.
- 해외/제작은 국내와 다른 단계/테이블을 가질 수 있으며,
  내부 프로세스(steps/work orders/bom 등)는 별도 엔티티로 관리하고 최종적으로 프로젝트 납품에 기여한다.

## 7. 문서(RFQ/PO)의 진실성
- 실제로 업체에 전달한 문서(견적요청서 RFQ, 발주서 PO)와 그 라인 정보가
  구매/정산/증빙의 기준(“진실의 원천”)이다.
- 주문라인의 default/override는 **입력 편의 및 의사결정 기록** 목적이며,
  최종 실제 구매는 PO 라인을 기준으로 계산한다.

## 8. 샘플 발주 정책
- 샘플 발주는 PO 헤더/라인에서 구분한다.
- 샘플 이후 케이스:
  1) 샘플은 납품 불가(폐기) → 본발주를 별도로
  2) 샘플은 내부 보관(납품 제외) → 잔량만 본발주
  3) 샘플도 납품 포함 가능 → 잔량만 본발주 + 납품 계산에 포함
- 샘플 관련 비용은 `costs` 및 `*_po_cost_links`를 통해 별도로 기록/배분 가능하다.


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


---

# Appendix: 데이터 입력 예시 (정본/역사 보존)

아래 내용은 데이터 입력 예시 문서를 4개 정본 문서 체계에 맞춰 재배치한 것이다.
최신 정본 기준 입력 예시는 `design-and-scenarios.md` 내에 유지하며, 운영 절차 관점 예시는 `operations-guide.md`에 배치한다.

## A) (최신 정본) 데이터 입력 예시 — Canon v7.9.7+

# Balhea 데이터 입력 예시 (Canon v7.9.7)

본 문서는 **현재 정본(v7.9.7+) 스키마/정책에 맞는 데이터 입력 예시만** 포함한다.

- 현재 정본(v7.9.7+)에서 **존재하는 엔티티/관계만**을 전제로 예시를 구성했다.
- 과거 버전에서 축적된 **표현 스타일(입력 순서/의사결정 포인트/검증 포인트/레코드 서술 템플릿)** 은 그대로 유지하되,
  모든 예시는 **정본 테이블(`rfqs`, `purchase_orders`, `documents`, `document_links` 등)** 로 통일했다.

---

## 0) 현재 정본(v7.9.7+) 전제/원칙 (예시 적용 기준)

### 0-1. 99% 경로 / 1% 희소 케이스
- **99% 경로:** `order_lines.ol_default_g_sn` (주문라인 = 실제 수급 단위)
- **희소 케이스:** `order_line_overrides(olo)` 로만 확장
  - `override_type`: `SPLIT`, `SUBSTITUTE`, `ADD_ON`, `BUNDLE`

### 0-2. 재무 레이어 분리
- 비용 발생(원장): `costs`
- 비용 귀속/안분: `cost_allocations` (귀속 키: `p_sn/o_sn/ol_sn/olo_sn/sc_sn` 등)
- 실제 지급(현금흐름): `payments`
- 지급-비용 매핑(부분지급/다대다): `payment_lines`

### 0-3. 문서/증빙: 문서 허브 단일화(정본)
- 모든 파일/증빙/서류 원본은 **`documents`** 에 저장
- “무엇의 근거인지(비용/지급/인보이스/배송 등)” 연결은 **`document_links`** 로만 표현

> 문서 코드값(권장; 확장 가능)
> - `documents.doc_category`: COST, PAYMENT, INVOICE, PURCHASE, DELIVERY, CUSTOMS, QUALITY, CONTRACT, TAX, SETTLEMENT, REFUND, OTHER
> - `documents.doc_type`: CASH_RECEIPT, CARD_APPROVAL, BANK_TRANSFER_RECEIPT, CARD_STATEMENT, TAX_INVOICE, BILL, STATEMENT, INVOICE,
>   PURCHASE_DETAILS, QUOTE, PO_DOC, DELIVERY_NOTE, SHIPMENT_PROOF, CUSTOMS_CLEARANCE, QUALITY_REPORT, PLATFORM_SETTLEMENT, REFUND_PROOF, ETC

---

---

### 0-4. 공통 샘플 값(프로젝트/주문/담당) — 예시 가독성용
아래 값들은 “예시를 읽기 쉽게 하기 위한” 샘플이다. (정본 정책/DDL에 따라 컬럼 유무/명칭은 달라질 수 있다.)

- `projects.project_type` 예시: `TENDER` (공공입찰), `DIRECT`(직접계약), `PERIOD`(기간계약)
- `sourcing_cases`는 **RFQ/PO를 실제로 만들 때 생성(지연 생성)** 해도 된다.  
  - 즉, “주문라인이 생겼다 = 즉시 수급케이스를 만든다”가 아니라, 담당자가 수급을 시작하는 시점에 `sc_status='OPEN'`으로 생성해도 된다.
- 담당자 식별자는 ERP에 직원 정보를 저장하지 않고, 외부 시스템의 principal(식별자)만 저장한다(설계 철학 1.2).  
  - 예: `sourcing_cases.sourcing_assignee_principal` 같은 텍스트/식별자 컬럼(정책 선택)


## 1) 엔티티 흐름 (요약)

정본 기준의 대표 흐름(국내/해외 공통):

`projects` → `orders` → `order_lines`
(+ 필요 시 `order_line_overrides`)
→ `sourcing_cases(sc_sn)`
→ `rfqs` / `rfq_lines` / `rfq_allocations`
→ `purchase_orders` / `po_lines` / `po_allocations`
→ (비용) `costs` / `cost_allocations` (+ 선택: `po_cost_links`)
→ (지급) `payments` / `payment_lines`
→ (증빙) `documents` + `document_links`

메모
- 국내/해외 구분은 **소스 오브 트루스가 `sourcing_cases.sourcing_type`** 이다.
- RFQ/PO의 `sourcing_type` 는 조회/필터용으로만 두고, 필수는 아니다(정책 선택).
- 샘플 발주는 `purchase_orders.po_kind = SAMPLE` 로 표준화한다.

---

## 2) 정본 예시 (v7.9.7+ 스키마 기준)

### 예시 1) 기본 케이스: 단일 품목 10개 (99% 경로, DOMESTIC)

#### 상황
- 주문서에 “드라이버 10개” 1줄
- 실제로도 드라이버(특정 goods) 10개를 구매/납품

#### 입력(순서)
1) `goods`
- (g_sn=2001) goods_name='십자 드라이버 6인치'

2) `projects`, `orders`
- (p_sn=100) 프로젝트/계약
- (o_sn=500) 주문서 (p_sn=100)

3) `order_lines`
- (ol_sn=1001) o_sn=500, line_no=1, requirement_name='드라이버', qty_required=10, **ol_default_g_sn=2001**

4) `sourcing_cases`
- (sc_sn=9001) ol_sn=1001, sourcing_type='DOMESTIC', sc_status='OPEN'

5) `parties` (견적/발주 대상 업체)
- (pt_sn=3001) A업체
- (pt_sn=3002) B업체

6) RFQ 생성 (견적요청)
- `rfqs`
  - (rfq_sn=4001) vendor_pt_sn=3001, sourcing_type='DOMESTIC', rfq_status='SENT'
  - (rfq_sn=4002) vendor_pt_sn=3002, sourcing_type='DOMESTIC', rfq_status='SENT'
- `rfq_lines` (각 RFQ에 1줄)
  - (rfql_sn=4101) rfq_sn=4001, line_no=1, g_sn=2001, request_qty=10
  - (rfql_sn=4201) rfq_sn=4002, line_no=1, g_sn=2001, request_qty=10
- `rfq_allocations` (내부 귀속: 이 RFQ라인이 어떤 수급(sc)에 대한 것인지)
  - (rfqa_sn=4111) rfql_sn=4101, sc_sn=9001, olo_sn=NULL, allocated_qty=10
  - (rfqa_sn=4211) rfql_sn=4201, sc_sn=9001, olo_sn=NULL, allocated_qty=10

7) 업체 선정 후 PO 생성 (발주)
- (선정: B업체, rfq_sn=4002)
- `purchase_orders`
  - (po_sn=5001) vendor_pt_sn=3002, sourcing_type='DOMESTIC', po_status='SENT', po_kind='NORMAL'
- `po_lines`
  - (pol_sn=5101) po_sn=5001, line_no=1, g_sn=2001, po_qty=10, unit_price=..., currency='KRW'
  - (선택) source_rfq_line: pol이 어떤 rfql에서 왔는지 추적 컬럼이 있으면 함께 채움(정책/DDL에 따름)
- `po_allocations`
  - (poa_sn=5111) pol_sn=5101, sc_sn=9001, olo_sn=NULL, allocated_qty=10

#### 조회/검증 포인트
- “해당 주문라인(ol_sn=1001)의 견적 비교”
  - `rfq_allocations`로 sc_sn=9001을 찾고, 연결된 `rfq_lines`의 가격(회신 컬럼)을 비교
- “해당 sc의 발주 현황”
  - `po_allocations`로 sc_sn=9001에 연결된 `po_lines`/`purchase_orders`를 탐색

---

### 예시 2) 대체품 비교: 같은 주문라인 후보 goods 여러 개 (SUBSTITUTE)

#### 상황
- 고객 요구는 “드라이버 10개”지만, 제조사/모델이 여러 후보(goods)일 수 있음
- 담당자는 “어느 후보가 싸지?”를 보고 선택

#### 입력
1) `order_lines`
- (ol_sn=1101) o_sn=500, line_no=2, requirement_name='드라이버(후보 비교)', qty_required=10
  - 후보군이므로 **ol_default_g_sn은 NULL 허용(정책 선택)**

2) 후보 goods를 `order_line_overrides`로 기록
- (olo_sn=3101) ol_sn=1101, override_type='SUBSTITUTE', g_sn=2001, qty=10, note='후보A'
- (olo_sn=3102) ol_sn=1101, override_type='SUBSTITUTE', g_sn=2002, qty=10, note='후보B'

3) `sourcing_cases`
- (sc_sn=9101) ol_sn=1101, sourcing_type='DOMESTIC', sc_status='OPEN'

4) RFQ 라인 작성 원칙(정본)
- RFQ 라인은 **goods 기준**으로 만든다.
  - (rfql ... g_sn=2001)
  - (rfql ... g_sn=2002)
- 그리고 `rfq_allocations.olo_sn` 로 후보군을 표시한다.
  - g_sn=2001 라인 → olo_sn=3101
  - g_sn=2002 라인 → olo_sn=3102

#### RFQ 예시(2개 업체에 2개 후보를 모두 요청)
- `rfqs`
  - (rfq_sn=4011) vendor_pt_sn=3001, sourcing_type='DOMESTIC', rfq_status='SENT'
  - (rfq_sn=4012) vendor_pt_sn=3002, sourcing_type='DOMESTIC', rfq_status='SENT'
- `rfq_lines`
  - (rfql_sn=4112) rfq_sn=4011, line_no=1, g_sn=2001, request_qty=10
  - (rfql_sn=4113) rfq_sn=4011, line_no=2, g_sn=2002, request_qty=10
  - (rfql_sn=4212) rfq_sn=4012, line_no=1, g_sn=2001, request_qty=10
  - (rfql_sn=4213) rfq_sn=4012, line_no=2, g_sn=2002, request_qty=10
- `rfq_allocations`
  - (rfqa_sn=...) rfql_sn=4112, sc_sn=9101, olo_sn=3101, allocated_qty=10
  - (rfqa_sn=...) rfql_sn=4113, sc_sn=9101, olo_sn=3102, allocated_qty=10
  - (rfqa_sn=...) rfql_sn=4212, sc_sn=9101, olo_sn=3101, allocated_qty=10
  - (rfqa_sn=...) rfql_sn=4213, sc_sn=9101, olo_sn=3102, allocated_qty=10

#### 조회(개념)
- “드라이버(ol_sn=1101) 후보별 가격 비교”
  - `rfq_lines` ↔ `rfq_allocations` 조인 후 `olo_sn`별로 그룹
  - 후보별 최저가/평균가/리드타임을 계산

---

### 예시 3) 동일 주문라인을 분할/대체로 전개 (SPLIT + SUBSTITUTE)

#### 상황
- 기본 goods는 9001로 생각했으나, 재고 부족으로
  - 60개는 9001
  - 40개는 대체품 9002
  로 구매해야 함

#### 입력
`goods`
- (g_sn=9001) manufacturer_name='OOO', goods_name='강철 십자드라이버 PH2', model_no='PH2-01'
- (g_sn=9002) manufacturer_name='MMM', goods_name='동급 PH2 드라이버', model_no='PH2-ALT'

`order_lines` (기본 유지)
- (ol_sn=1001) qty_required=100, ol_default_g_sn=9001

`order_line_overrides` (희소 케이스만 추가)
- (olo_sn=2001) ol_sn=1001, override_type='SPLIT', g_sn=9001, qty=60, note='OOO 재고 60 한도'
- (olo_sn=2002) ol_sn=1001, override_type='SUBSTITUTE', g_sn=9002, qty=40, note='대체품 구매'

`sourcing_cases`
- (sc_sn=9001) ol_sn=1001, sourcing_type='DOMESTIC'

#### RFQ/PO 생성 규칙(정본)
- override가 있으면 RFQ/PO 라인은 **override 전개 결과**를 우선한다.
  - 즉, RFQ/PO 라인은 2줄(또는 N줄)로 생성된다.
- 내부 귀속(allocation)은 동일 sc_sn으로 연결 가능하되,
  구성품/후보군/분할 구분이 필요하면 `*_allocations.olo_sn`로 명시한다.

#### RFQ 예시
- `rfqs`: (rfq_sn=5001) vendor_pt_sn=3001, rfq_status='SENT'
- `rfq_lines`
  - (rfql_sn=5101) rfq_sn=5001, line_no=1, g_sn=9001, request_qty=60
  - (rfql_sn=5102) rfq_sn=5001, line_no=2, g_sn=9002, request_qty=40
- `rfq_allocations`
  - (rfqa_sn=...) rfql_sn=5101, sc_sn=9001, olo_sn=2001, allocated_qty=60
  - (rfqa_sn=...) rfql_sn=5102, sc_sn=9001, olo_sn=2002, allocated_qty=40

#### PO 예시
- `purchase_orders`: (po_sn=6001) vendor_pt_sn=3001, po_status='SENT', po_kind='NORMAL'
- `po_lines`
  - (pol_sn=6101) po_sn=6001, line_no=1, g_sn=9001, po_qty=60, unit_price=..., currency='KRW'
  - (pol_sn=6102) po_sn=6001, line_no=2, g_sn=9002, po_qty=40, unit_price=..., currency='KRW'
- `po_allocations`
  - (poa_sn=...) pol_sn=6101, sc_sn=9001, olo_sn=2001, allocated_qty=60
  - (poa_sn=...) pol_sn=6102, sc_sn=9001, olo_sn=2002, allocated_qty=40

---

### 예시 4) PC 세트 납품: 구성품(BUNDLE)으로 전개 + 구성품별 비용 귀속(olo_sn)

#### 상황
- 주문라인은 “업무용 PC 세트(본체+모니터) 10세트”
- 실제 구매/견적/발주는 구성품 단위(본체/모니터)로 이뤄짐

#### 입력
1) `order_lines`
- (ol_sn=1201) requirement_name='업무용 PC 세트(본체+모니터)', qty_required=10
  - (선택) 세트 자체 goods가 없으면 ol_default_g_sn은 NULL 가능

2) `order_line_overrides` (구성품)
- (olo_sn=3201) ol_sn=1201, override_type='BUNDLE', g_sn=2101, qty=10, note='본체'
- (olo_sn=3202) ol_sn=1201, override_type='BUNDLE', g_sn=2102, qty=10, note='모니터'

3) `sourcing_cases`
- (sc_sn=9201) ol_sn=1201, sourcing_type='DOMESTIC', sc_status='OPEN'

#### RFQ/PO 작성 원칙(정본)
- RFQ/PO 라인은 **override 전개 결과(구성품) 기준**으로 생성
- `rfq_allocations.olo_sn` / `po_allocations.olo_sn` 를 사용해
  “PC(ol_sn=1201) 안에서 본체/모니터를 분리”해서 가격 비교/검증/원가 산출이 가능하게 한다.

#### RFQ 예시(구성품 2개를 각각 라인으로 요청)
- `rfqs`: (rfq_sn=7001) vendor_pt_sn=3001, rfq_status='SENT'
- `rfq_lines`
  - (rfql_sn=7101) rfq_sn=7001, line_no=1, g_sn=2101, request_qty=10
  - (rfql_sn=7102) rfq_sn=7001, line_no=2, g_sn=2102, request_qty=10
- `rfq_allocations`
  - (rfqa_sn=...) rfql_sn=7101, sc_sn=9201, olo_sn=3201, allocated_qty=10
  - (rfqa_sn=...) rfql_sn=7102, sc_sn=9201, olo_sn=3202, allocated_qty=10

#### PO 예시(구성품별로 발주)
- `purchase_orders`: (po_sn=8001) vendor_pt_sn=3001, po_status='SENT', po_kind='NORMAL'
- `po_lines`
  - (pol_sn=8101) po_sn=8001, line_no=1, g_sn=2101, po_qty=10, unit_price=..., currency='KRW'
  - (pol_sn=8102) po_sn=8001, line_no=2, g_sn=2102, po_qty=10, unit_price=..., currency='KRW'
- `po_allocations`
  - (poa_sn=...) pol_sn=8101, sc_sn=9201, olo_sn=3201, allocated_qty=10
  - (poa_sn=...) pol_sn=8102, sc_sn=9201, olo_sn=3202, allocated_qty=10

#### 부대 비용 귀속(예: 모니터 검사비)
- `costs`: (ct_sn=7301) cost_type='SERVICE', amount=120,000, currency='KRW', description='모니터 품질검사서 발급'
- `cost_allocations`: (ca_sn=...) ct_sn=7301, sc_sn=9201, olo_sn=3202, allocated_amount=120,000, note='PC 세트 구성품(모니터) 검사비'

---

### 예시 5) 해외구매(OVERSEAS) 샘플 발주 → 본발주 + 환율 고정

#### 상황 A: 샘플 2개 테스트 후 폐기(납품 불가) → 본발주 100개 별도

`goods`
- (g_sn=9101) manufacturer_name='Shenzhen ABC', goods_name='Sensor Module X v2', model_no='SMX-V2'

`order_lines` / `sourcing_cases`
- (ol_sn=1002) qty_required=100, ol_default_g_sn=9101
- (sc_sn=5002) ol_sn=1002, sourcing_type='OVERSEAS', sc_status='OPEN'

#### 1) 샘플 PO(폐기)
- `purchase_orders`
  - (po_sn=9002) vendor_pt_sn=401(해외업체), sourcing_type='OVERSEAS', po_kind='SAMPLE', po_status='SENT'
  - (선택) trade_terms='EXW', ship_from_country='CN', ship_to_country='KR'
- `po_lines`
  - (pol_sn=9102) po_sn=9002, line_no=1, g_sn=9101, po_qty=2, unit_price=..., currency='USD', is_sample=1, sample_disposition='DISCARD'
- `po_allocations`
  - (poa_sn=...) pol_sn=9102, sc_sn=5002, olo_sn=NULL, allocated_qty=2

#### 2) 본발주 PO(샘플과 별개로 100개)
- `purchase_orders`
  - (po_sn=9003) vendor_pt_sn=401, sourcing_type='OVERSEAS', po_kind='NORMAL', po_status='SENT'
- `po_lines`
  - (pol_sn=9103) po_sn=9003, line_no=1, g_sn=9101, po_qty=100, unit_price=..., currency='USD', is_sample=0
- `po_allocations`
  - (poa_sn=...) pol_sn=9103, sc_sn=5002, olo_sn=NULL, allocated_qty=100

#### 3) 해외 비용(USD) + 환율 고정(감사 재현)

예: 통관비/포워딩/국제운송 등

- `costs`
  - (ct_sn=8101) cost_type='CUSTOMS', vendor_pt_sn=402(관세사/통관대행), occurred_at='2026-01-18', amount=300, currency='USD', description='통관비(USD)'
- (선택) `po_cost_links`
  - (pcl_sn=...) po_sn=9003, ct_sn=8101  (조회/탐색 편의; 원가 계산의 근거는 아님)
- `cost_allocations`
  - (ca_sn=...) ct_sn=8101, sc_sn=5002, ol_sn=1002, olo_sn=NULL, allocated_amount=300, note='해외 통관비를 해당 수급에 귀속'

정산/회계 재현을 위한 환율 고정
- `cost_fx_applications`
  - (cfa_sn=...) ct_sn=8101
    - src_currency='USD', src_amount=300
    - applied_fx_rate=1,350.00
    - as_of_dt='2026-01-18'
    - base_amount=405,000  (KRW)

#### 상황 B: 샘플 2개 내부 보관(납품 제외) → 잔량 98개만 본발주
- 샘플 PO: sample_disposition='KEEP_INTERNAL', po_qty=2
- 본발주 PO: po_qty=98

#### 운영 주의(정본)
- “납품 약속 수량(qty_required)”을 샘플 포함 여부에 따라 어떻게 충족할지 회사 정책을 고정해야 한다.
  - 샘플이 납품 불가면 본발주를 100으로 해야 함
  - 샘플이 납품 가능이면 본발주 98 + 샘플 2로 100 납품 가능

---

### 예시 6) 오픈마켓 1회 결제 + 셀러 영수증 N장 (문서 허브 정본)

#### 목표/원칙
- ERP는 **정산 주체(플랫폼)** 만 party로 기억한다.
- 셀러 N곳은 `parties`로 만들지 않는다.
- 셀러 표시명/발행자명은 `documents.issuer_name`(또는 issuer_display_name) 텍스트로만 보존한다.
- 영수증/정산서/카드전표 등 파일은 `documents`에 넣고,
  어떤 결제(payments)의 근거인지 `document_links` 로 연결한다.

#### 상황
- 네이버에서 1회 결제(3,240,000원)
- 셀러 영수증은 여러 장(예: 100장)

#### 입력
`parties`
- (pt_sn=90000001) name='네이버(정산 주체)'

`costs` (비용 발생)
- (ct_sn=7001) vendor_pt_sn=90000001, occurred_at='2026-01-15 10:00', amount=3,240,000, currency='KRW', description='네이버 구매(여러 셀러 합산)'

(선택) `cost_allocations` (귀속)
- 단일 주문라인에 전액 귀속: (ca_sn=...) ct_sn=7001, ol_sn=1001, allocated_amount=3,240,000
- 여러 주문라인에 분할 귀속: (ca_sn=...) ct_sn=7001, ol_sn=..., allocated_amount=... ... (N줄)

`payments` (실제 지급)
- (pay_sn=9001) pay_method='CARD', pay_status='PAID', payee_pt_sn=90000001, paid_at='2026-01-15 10:01', amount=3,240,000, currency='KRW', ref_no='CARD-APPROVAL-1234'

`payment_lines` (지급-비용 연결)
- (pyl_sn=...) pay_sn=9001, ct_sn=7001, paid_amount=3,240,000, note='일괄 결제'

`documents` (원본 파일)
- 카드 승인 내역(카드전표):
  - (doc_sn=60000) doc_category='PAYMENT', doc_type='CARD_APPROVAL', issuer_name='네이버', file_name='card_approval.pdf', storage_key='s3://.../card_approval.pdf'
- 플랫폼 정산서(수수료/차감 포함):
  - (doc_sn=60010) doc_category='SETTLEMENT', doc_type='PLATFORM_SETTLEMENT', issuer_name='네이버', file_name='settlement_202601.pdf', storage_key='s3://.../settlement_202601.pdf'
- 셀러별 영수증 N장(발행 주체는 셀러 표시명):
  - (doc_sn=60001) doc_category='PAYMENT', doc_type='PURCHASE_DETAILS', issuer_name='스마트스토어 A상점', file_name='receipt_a.pdf', storage_key='s3://.../receipt_a.pdf'
  - (doc_sn=60002) doc_category='PAYMENT', doc_type='PURCHASE_DETAILS', issuer_name='스마트스토어 B상점', file_name='receipt_b.pdf', storage_key='s3://.../receipt_b.pdf'
  - ...

`document_links` (증빙 연결: payment 근거)
- (dl_sn=61000) doc_sn=60000, target_type='PAYMENT', target_sn=9001
- (dl_sn=61010) doc_sn=60010, target_type='PAYMENT', target_sn=9001
- (dl_sn=61001) doc_sn=60001, target_type='PAYMENT', target_sn=9001
- (dl_sn=61002) doc_sn=60002, target_type='PAYMENT', target_sn=9001
- ...

#### 운영 팁
- “영수증 모아보기”는 `document_links WHERE target_type='PAYMENT' AND target_sn=9001` 로 구현한다.
- 셀러명을 party로 만들지 않으므로, 셀러 단위 집계가 필요하면 `documents.issuer_name` 텍스트를 기준으로 집계한다.

---

### 예시 7) 퀵/대행 비용 (PO와 무관) + 특정 주문라인/수급(sc)에 귀속

#### 상황
- 긴급 퀵 배송비 18,000원 발생
- 특정 수급건(sc) / 주문라인(ol)에 원가로 귀속해야 함
- 지급은 다음날 이체로 처리

#### 입력
`parties`
- (pt_sn=90000099) name='퀵/대행(예약 거래처)'

`costs`
- (ct_sn=7101) cost_type='SHIPPING', vendor_pt_sn=90000099, occurred_at='2026-01-15 14:30', amount=18,000, currency='KRW', description='긴급 퀵 배송'

`cost_allocations` (귀속)
- (ca_sn=...) ct_sn=7101, sc_sn=9001, ol_sn=1001, olo_sn=NULL, allocated_amount=18,000, note='드라이버 납품용 퀵'

`payments`
- (pay_sn=70002) pay_method='TRANSFER', pay_status='PAID', payee_pt_sn=90000099, paid_at='2026-01-16 18:00', amount=18,000, currency='KRW'

`payment_lines`
- (pyl_sn=...) pay_sn=70002, ct_sn=7101, paid_amount=18,000

`documents` + `document_links` (선택: 증빙)
- `documents`
  - (doc_sn=62001) doc_category='PAYMENT', doc_type='BANK_TRANSFER_RECEIPT', issuer_name='은행', file_name='transfer_70002.png', storage_key='s3://.../transfer_70002.png'
- `document_links`
  - (dl_sn=63001) doc_sn=62001, target_type='PAYMENT', target_sn=70002

---

### 예시 8) 선금/중도금/잔금 분할 지급 (비용 1건, 지급 3건)

#### 상황
- 동일 비용(ct) 1건에 대해 3회 분할 지급
  - 선금 3,000,000
  - 중도금 5,000,000
  - 잔금 2,000,000

#### 입력
`costs`
- (ct_sn=7201) description='공급업체 A 대금(총액)', amount=10,000,000, currency='KRW'

`payments`
- (pay_sn=9201) pay_method='TRANSFER', pay_status='PAID', paid_at='2026-01-10', amount=3,000,000, currency='KRW'
- (pay_sn=9202) pay_method='TRANSFER', pay_status='PAID', paid_at='2026-02-10', amount=5,000,000, currency='KRW'
- (pay_sn=9203) pay_method='TRANSFER', pay_status='PAID', paid_at='2026-03-10', amount=2,000,000, currency='KRW'

`payment_lines`
- (pyl_sn=...) pay_sn=9201, ct_sn=7201, paid_amount=3,000,000, note='선금'
- (pyl_sn=...) pay_sn=9202, ct_sn=7201, paid_amount=5,000,000, note='중도금'
- (pyl_sn=...) pay_sn=9203, ct_sn=7201, paid_amount=2,000,000, note='잔금'

`documents` + `document_links` (선택: 각 지급에 대한 증빙 첨부)
- documents: (doc_sn=...) doc_category='PAYMENT', doc_type='BANK_TRANSFER_RECEIPT', file_name='deposit_9201.pdf'
- document_links: (dl_sn=...) doc_sn=..., target_type='PAYMENT', target_sn=9201

---

---

## (정본 통합) PO After 시나리오 관점 메모 — v7.9.7

본 문서의 운영 디테일은 `operations-guide`를 정본으로 한다. 여기에는 “스키마 사용법/입력 흐름” 관점에서
PO After 영역을 이해하기 위한 핵심 연결만 정리한다.

### 1) 배송요청이 필요한 경우/필요 없는 경우
- **필요:** 구매팀↔물류팀 협의(요일/시간창, 역제안/수락/거절)가 중요할 때  
  → `delivery_requests` + `delivery_request_proposals`로 협의 로그를 남긴 뒤, 합의된 실행을 `logistics_jobs`로 만든다.
- **불필요:** 긴급 출고/납품 등 협의 없이 바로 실행되는 작업  
  → `logistics_jobs`만으로 실행 이력을 남기고, 증빙은 문서 허브로 연결한다.

### 2) 직송(회사 미접촉) vs 바코드 추적(회사 접촉)
- **직송:** 회사가 실물을 만지지 않으면 `inventory_units`는 생략 가능  
  - 운송 추적이 필요하면 `shipments` + `shipment_milestones`
  - 납품 증빙은 `documents` 저장 후 `document_links`로 `shipment_milestones` 또는 `logistics_jobs`에 연결
- **바코드 추적:** 입고/출고/재고가 필요하면 `inventory_units`를 생성하고
  `logistics_job_lines`에 스캔/수동 담기로 작업 대상에 포함한다.

---

## (추가) 대전제: 문서/실물/작업 분리 + items 금지 (v7.8.1 → v7.9.7 정본)

### 1) 문서(Document) / 실물(Physical) / 작업(Execution)은 절대 섞지 않는다

- **문서(Document)**: 계약/주문/RFQ/PO 등 “서류/목록”의 단위  
  - 표준 네이밍: `*_lines`
- **실물(Physical)**: 바코드가 붙는 “통제 가능한 실물 단위”  
  - 표준 네이밍: `inventory_units`
- **작업(Execution)**: 사람이 수행한 “수거/이송/납품”의 실행 단위  
  - 표준 네이밍: `logistics_jobs`

협의(요청/역제안/수락)는 실행이 아니므로 별도로 둔다:
- `delivery_requests` (+ proposals)

### 2) items라는 단어/엔티티는 사용하지 않는다

- “아이템”은 의미 범위가 넓어(품목/라인/실물/작업) 혼동을 유발한다.
- 정본에서 의미는 아래처럼 고정한다:
  - “문서의 항목” = `*_lines`
  - “실물 1개” = `inventory_units`
  - “작업 1건” = `logistics_jobs`
