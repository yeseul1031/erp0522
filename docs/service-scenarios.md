# Balhea ERP Service Scenarios (Canon v7.9.x)

> 목적: `design-guide.md`를 보충하는 **레코드 단위 입력 예시(케이스별)** 모음이다.  
> “어떤 엔티티에 어떤 값을 어떤 순서로 넣는지”를 최대한 구체적으로 기술한다.

---

## 0. 공통 전제(예시 적용 기준)

### 0-1. 99% 경로 / 희소 케이스(override)
- 99%: `order_lines.ol_default_g_sn`로 기본 goods를 지정하고, RFQ/PO 라인은 기본 goods로 생성한다.
- 희소: `order_line_overrides(override_type in {SPLIT,SUBSTITUTE,ADD_ON,BUNDLE})`가 있으면 전개 결과로 RFQ/PO 라인을 만든다.

### 0-2. 재무 레이어 분리(입력 관점)
- 비용 발생(원장): `costs`
- 비용 귀속/안분: `cost_allocations`
- 실제 지급: `payments`
- 지급-비용 매핑: `payment_lines`
- (필요 시) 지급 승인/통제: `payables` (+ 배정 테이블)
- (필요 시) 외부 청구 문서: `invoices` / `invoice_lines`

### 0-3. 문서/증빙(정본)
- 원본 저장: `documents`
- 근거 연결: `document_links(target_type, target_sn)`

권장 분류:
- 거래/원가 증빙: `documents.doc_category='COST'`
- 지급/현금흐름 증빙: `documents.doc_category='PAYMENT'`

---

## 1. 조달(Procurement) 시나리오

### 예시 1) 기본 케이스: 단일 품목 10개 (99% 경로, DOMESTIC)

#### 상황
- 주문서에 “드라이버 10개” 1줄
- 실제로도 동일 goods 10개를 구매/납품

#### 입력(권장 순서)
1) `goods`
- (g_sn=2001) goods_name='십자 드라이버 6인치'

2) `projects`
- (p_sn=100) 프로젝트/계약

3) `order_lines`
- (ol_sn=1001) p_sn=100, line_no=1, requirement_name='드라이버', qty_required=10, **ol_default_g_sn=2001**

4) `sourcing_cases`
- (sc_sn=9001) ol_sn=1001, sourcing_type='DOMESTIC', sc_status='OPEN'

5) `parties` (견적/발주 대상 업체)
- (pt_sn=3001) A업체
- (pt_sn=3002) B업체

6) RFQ 생성
- `rfqs`
  - (rfq_sn=4001) vendor_pt_sn=3001, sourcing_type='DOMESTIC', rfq_status='SENT'
  - (rfq_sn=4002) vendor_pt_sn=3002, sourcing_type='DOMESTIC', rfq_status='SENT'
- `rfq_lines`
  - (rfql_sn=4101) rfq_sn=4001, line_no=1, g_sn=2001, request_qty=10
  - (rfql_sn=4201) rfq_sn=4002, line_no=1, g_sn=2001, request_qty=10
- `rfq_allocations`
  - (rfqa_sn=4111) rfql_sn=4101, sc_sn=9001, olo_sn=NULL, allocated_qty=10
  - (rfqa_sn=4211) rfql_sn=4201, sc_sn=9001, olo_sn=NULL, allocated_qty=10

7) 업체 선정 후 PO 생성
- `purchase_orders`
  - (po_sn=5001) vendor_pt_sn=3002, sourcing_type='DOMESTIC', po_status='SENT', po_kind='NORMAL'
- `po_lines`
  - (pol_sn=5101) po_sn=5001, line_no=1, g_sn=2001, po_qty=10, unit_price=..., ccy='KRW'
  - (선택) source_rfq_line: pol이 어떤 rfql에서 왔는지 추적 컬럼이 있으면 함께 채움(정책/DDL에 따름)
- `po_allocations`
  - (poa_sn=5111) pol_sn=5101, sc_sn=9001, olo_sn=NULL, allocated_qty=10

#### 조회/검증 포인트
- “주문라인(ol_sn=1001)의 견적 비교”
  - `rfq_allocations`로 sc_sn=9001을 찾고, 연결된 `rfq_lines`의 회신 가격/리드타임을 비교
- “sc의 발주 현황”
  - `po_allocations`로 sc_sn=9001에 연결된 `po_lines`/`purchase_orders` 탐색

---

### 예시 2) 대체품 후보 비교 (SUBSTITUTE)

#### 상황
- 고객 요구는 “드라이버 10개”지만 후보 goods가 여러 개
- 담당자는 후보별 가격/리드타임을 비교 후 선택

#### 입력
1) `order_lines`
- (ol_sn=1101) requirement_name='드라이버(후보 비교)', qty_required=10
  - 후보군이므로 **ol_default_g_sn = NULL 허용(정책 선택)**

2) 후보 goods를 `order_line_overrides`로 기록
- (olo_sn=3101) ol_sn=1101, override_type='SUBSTITUTE', g_sn=2001, qty=10, note='후보A'
- (olo_sn=3102) ol_sn=1101, override_type='SUBSTITUTE', g_sn=2002, qty=10, note='후보B'

3) `sourcing_cases`
- (sc_sn=9101) ol_sn=1101, sourcing_type='DOMESTIC', sc_status='OPEN'

4) RFQ 라인 작성 원칙
- RFQ 라인은 goods 기준으로 만든다(후보별 1줄).
- `rfq_allocations.olo_sn`로 후보군을 표시한다.
  - g_sn=2001 라인 → olo_sn=3101
  - g_sn=2002 라인 → olo_sn=3102

(2개 업체에 2개 후보를 모두 요청하는 예)
- `rfqs`: (rfq_sn=4011 vendor_pt_sn=3001), (rfq_sn=4012 vendor_pt_sn=3002)
- `rfq_lines`: 후보 2개 × 업체 2개 = 4줄
- `rfq_allocations`: 각 rfql에 (sc_sn=9101, olo_sn=후보 override) 배정

#### 조회(개념)
- `rfq_lines` ↔ `rfq_allocations` 조인 후 `olo_sn`별 그룹으로 후보별 가격 비교

---

### 예시 3) 분할 + 대체 조합 (SPLIT + SUBSTITUTE)

#### 상황
- 기본 goods(9001) 100개를 생각했으나 재고 부족
  - 60개는 9001
  - 40개는 대체품 9002

#### 입력
`goods`
- (g_sn=9001) goods_name='강철 십자드라이버 PH2', model_no='PH2-01'
- (g_sn=9002) goods_name='동급 PH2 드라이버', model_no='PH2-ALT'

`order_lines`
- (ol_sn=1001) qty_required=100, ol_default_g_sn=9001

`order_line_overrides`
- (olo_sn=2001) override_type='SPLIT', g_sn=9001, qty=60, note='재고 60 한도'
- (olo_sn=2002) override_type='SUBSTITUTE', g_sn=9002, qty=40, note='대체품 구매'

`sourcing_cases`
- (sc_sn=9001) ol_sn=1001, sourcing_type='DOMESTIC'

#### RFQ/PO 생성 규칙
- override가 있으면 RFQ/PO 라인은 override 전개 결과(2줄)로 생성된다.
- 내부 귀속은 동일 sc_sn으로 연결하되, `*_allocations.olo_sn`으로 구분한다.

---

### 예시 4) PC 세트 납품: 구성품(BUNDLE) 전개 + 구성품별 비용 귀속

#### 상황
- 주문라인: “업무용 PC 세트(본체+모니터) 10세트”
- 실제 견적/발주는 구성품 단위(본체/모니터)로 이뤄짐

#### 입력
`order_lines`
- (ol_sn=1201) qty_required=10, requirement_name='PC 세트'
  - (선택) 세트 goods가 없으면 ol_default_g_sn은 NULL 가능

`order_line_overrides` (구성품)
- (olo_sn=3201) override_type='BUNDLE', g_sn=2101, qty=10, note='본체'
- (olo_sn=3202) override_type='BUNDLE', g_sn=2102, qty=10, note='모니터'

`sourcing_cases`
- (sc_sn=9201) ol_sn=1201, sourcing_type='DOMESTIC', sc_status='OPEN'

#### RFQ/PO 작성 원칙
- RFQ/PO 라인은 구성품 기준으로 생성(2줄)
- allocations에서 `olo_sn`을 사용해 본체/모니터를 분리하여
  가격 비교/원가 산출이 가능하게 한다.

#### 부대 비용 귀속 예(모니터 검사비)
- `costs`: (ct_sn=7301) cost_type='SERVICE', amount=120,000, ccy='KRW', description='모니터 품질검사서 발급'
- `cost_allocations`: (ca_sn=...) ct_sn=7301, sc_sn=9201, olo_sn=3202, allocated_amount=120,000, note='모니터 검사비'

---

### 예시 5) 해외구매(OVERSEAS) 샘플 PO → 본발주 + 환율 고정

#### 상황 A: 샘플 2개 테스트 후 폐기 → 본발주 100개 별도
`goods`
- (g_sn=9101) manufacturer_name='Shenzhen ABC', goods_name='Sensor Module X v2', model_no='SMX-V2'

`order_lines` / `sourcing_cases`
- (ol_sn=1002) qty_required=100, ol_default_g_sn=9101
- (sc_sn=5002) sourcing_type='OVERSEAS', sc_status='OPEN'

1) 샘플 PO
- `purchase_orders`: (po_sn=9002) vendor_pt_sn=401, sourcing_type='OVERSEAS', po_kind='SAMPLE', po_status='SENT'
- `po_lines`: (pol_sn=9102) po_qty=2, ccy='USD', is_sample=1, sample_disposition='DISCARD'
- `po_allocations`: (poa_sn=...) sc_sn=5002, allocated_qty=2

2) 본발주 PO
- `purchase_orders`: (po_sn=9003) po_kind='NORMAL'
- `po_lines`: (pol_sn=9103) po_qty=100, ccy='USD', is_sample=0
- `po_allocations`: (poa_sn=...) allocated_qty=100

3) 해외 비용(USD) + 환율 고정(감사 재현)
- `costs`: (ct_sn=8101) cost_type='CUSTOMS', amount=300, ccy='USD', occurred_at='2026-01-18', description='통관비(USD)'
- (선택) `po_cost_links`: (pcl_sn=...) po_sn=9003, ct_sn=8101
- `cost_allocations`: (ca_sn=...) ct_sn=8101, sc_sn=5002, ol_sn=1002, allocated_amount=300
- `cost_fx_applications`:
  - src_ccy='USD', src_amount=300, applied_fx_rate=1,350.00, as_of_dt='2026-01-18', base_amount=405,000(KRW)

#### 상황 B: 샘플 2개 내부 보관(납품 제외) → 잔량 98개만 본발주
- 샘플 PO: sample_disposition='KEEP_INTERNAL', po_qty=2
- 본발주 PO: po_qty=98

#### 운영 주의
샘플이 납품 수량에 포함되는지 회사 정책을 고정해야 한다.

---

### 예시 6) 국내+해외 혼합 수급(단일 주문항목)

#### 상황
- 주문항목(ol_sn=20) 총 100개
- 국내 60 + 해외 40으로 나눠 수급

#### 입력
1) `order_lines`: ol_sn=20, qty=100

2) `sourcing_cases` 2개 생성
- 국내: sc_sn=201, sourcing_type='DOMESTIC'
- 해외: sc_sn=202, sourcing_type='OVERSEAS'

3) (레거시/구조 선택) 해외 단계가 있으면 steps 엔티티로 진행 상태 기록
- 예: `overseas_steps`(step_type='SHIPPING', status='IN_PROGRESS')

4) 각 수급 케이스별 PO 생성 및 allocation
- 국내 PO: po_qty=60 → sc_sn=201로 allocation
- 해외 PO: po_qty=40 → sc_sn=202로 allocation

#### 요약 검증
- 각 케이스는 독립 발주/비용 흐름을 가진다.
- 최종적으로 두 케이스의 확보 수량 합이 주문항목 요구 수량을 충족해야 한다.

---

## 2. 재무(비용/지급/증빙) 시나리오

### 시나리오 A) 온라인 주문 + 카드 즉시결제(재무 이체 요청 없음)
1) PO 생성(검토/승인 후 발행)
2) cost 생성 + (선택) allocation
3) payment 생성(pay_method='CARD')
4) documents: 카드 승인 내역 첨부
5) documents: 구매명세서(셀러별 N개 가능) 첨부
6) (선택) 현금영수증 첨부
- payable은 생성하지 않는다.

### 시나리오 B) PO 기반 + 계좌이체(재무 승인/집행 필요)
1) PO 생성
2) cost 생성
3) payable 생성(지급요청/승인 단위)
4) 승인 후 payment 생성(pay_method='TRANSFER')
5) documents: 이체 영수증 첨부
6) (권장) payment_lines로 cost와 금액 연결(분할지급 대응)

### 시나리오 C) 비PO 비용(배송료/미팅/주유/검수 등)
1) cost 직접 생성
2) (선택) cost_allocations로 귀속
3) payment 생성(CARD/TRANSFER/CASH)
4) documents: 영수증/현금영수증 첨부
5) 지급이 발생했다면 documents에 카드승인/이체확인 첨부

### 시나리오 D) Invoice 1건에 여러 PO 묶음 + PO 외 부대비용 포함
1) invoice 생성(외부 문서 컨테이너)
2) invoice_lines 생성(PO 연결 + 부대비용 라인 분리)
3) cost 생성(원가/채무 인식)
4) payable 생성(필요 시)
5) 승인 후 payment 생성
6) documents: 거래명세서/세금계산서 첨부
7) documents: 이체확인/카드승인 첨부

### 시나리오 E) 1 cost를 여러 번 분할 지급(선금/중도금/잔금)
1) cost 1건 생성(총액)
2) payment 3건 생성
3) 각 payment_lines로 동일 cost에 분할 연결
4) 각 payment마다 documents로 지급 증빙 첨부

---

### 예시 7) 오픈마켓 1회 결제 + 셀러 영수증 N장(문서 허브)

#### 목표
- party는 정산 주체(플랫폼)만 둔다.
- 셀러들은 party로 만들지 않는다.
- 셀러 표시는 `documents.issuer_name` 같은 텍스트 메타로만 보존한다.

#### 상황
- 네이버 1회 결제(3,240,000원)
- 셀러 영수증 N장(예: 100장)

#### 입력
`parties`
- (pt_sn=90000001) name='네이버(정산 주체)'

`costs`
- (ct_sn=7001) vendor_pt_sn=90000001, occurred_at='2026-01-15 10:00', amount=3,240,000, ccy='KRW', description='네이버 구매(여러 셀러 합산)'

(선택) `cost_allocations`
- 단일 ol 전액 or 여러 ol 분할(N줄)

`payments`
- (pay_sn=9001) pay_method='CARD', pay_status='PAID', payee_pt_sn=90000001, paid_at='2026-01-15 10:01', amount=3,240,000, ccy='KRW', ref_no='CARD-APPROVAL-1234'

`payment_lines`
- (pyl_sn=...) pay_sn=9001, ct_sn=7001, paid_amount=3,240,000, note='일괄 결제'

`documents`
- 카드 승인 내역: (doc_sn=60000) doc_category='PAYMENT', doc_type='CARD_APPROVAL', issuer_name='네이버', file_name='card_approval.pdf'
- 플랫폼 정산서: (doc_sn=60010) doc_category='SETTLEMENT', doc_type='PLATFORM_SETTLEMENT', issuer_name='네이버', file_name='settlement_202601.pdf'
- 셀러별 영수증 N장: (doc_sn=60001...) doc_category='PAYMENT', doc_type='PURCHASE_DETAILS', issuer_name='스마트스토어 A상점', file_name='receipt_a.pdf' ...

`document_links`
- 모두 target_type='PAYMENT', target_sn=9001 로 다중 연결

#### 운영 팁
- “영수증 모아보기”: `document_links WHERE target_type='PAYMENT' AND target_sn=9001`
- 셀러 단위 집계가 필요하면 `documents.issuer_name` 텍스트로 집계한다.

---

### 예시 8) 퀵/대행 비용(PO 무관) + 특정 sc/ol 귀속 + 다음날 이체

`parties`
- (pt_sn=90000099) name='퀵/대행(예약 거래처)'

`costs`
- (ct_sn=7101) cost_type='SHIPPING', vendor_pt_sn=90000099, occurred_at='2026-01-15 14:30', amount=18,000, ccy='KRW', description='긴급 퀵 배송'

`cost_allocations`
- (ca_sn=...) ct_sn=7101, sc_sn=9001, ol_sn=1001, olo_sn=NULL, allocated_amount=18,000, note='드라이버 납품용 퀵'

`payments`
- (pay_sn=70002) pay_method='TRANSFER', pay_status='PAID', paid_at='2026-01-16 18:00', amount=18,000, ccy='KRW'

`payment_lines`
- (pyl_sn=...) pay_sn=70002, ct_sn=7101, paid_amount=18,000

(선택) `documents` + `document_links`
- 이체 영수증: doc_category='PAYMENT', doc_type='BANK_TRANSFER_RECEIPT' → target_type='PAYMENT', target_sn=70002

---

## 3. 물류/배송(PO After) 시나리오

### 3.1 배송요청이 필요한 경우/필요 없는 경우
- 필요: `delivery_requests` + proposals로 합의 → 실행은 `logistics_jobs`
- 불필요: `logistics_jobs`만 생성하여 실행 이력 보존

### 3.2 직송 vs 바코드 추적
- 직송: `inventory_units` 생략 가능, 운송은 `shipments`로, 증빙은 문서 허브로 연결
- 바코드 추적: `inventory_units` 생성 후 `logistics_job_lines`에 담아 스캔/수동 작업

### 3.3 현업 3가지 케이스(권장)
A) 물류팀이 판매처 방문 수거 → 직납 또는 창고 입고  
B) 판매처 배송 → 사무실/창고 도착 후 물류팀 분류/이동  
C) 판매처가 납품처로 직접 배송(직송)

> 각 케이스에서 “회사 실물 접촉 여부”에 따라 `inventory_units` 생성 여부를 결정하고,  
> 납품/운송 증빙은 `documents` + `document_links`로 연결한다.


---

## 4. 감사/정산 최소 증빙 세트(운영 체크)

## 7. 감사/정산 관점 최소 요구 증빙(필수 문서 세트)

아래는 운영·감사·정산에서 “최소한 이 정도는 남겨야 한다”는 **권장 최소 세트**다.
(업무/거래 특성에 따라 추가 문서가 필요할 수 있다.)

### 7.1 카드 결제(온라인 즉시결제 포함) - 최소 세트
- `documents`
  - 카드 승인 내역(`CARD_APPROVAL`) **필수**
  - (월 정산 필요 시) 카드사 청구서(`CARD_STATEMENT`) 권장
- `documents`
  - 구매명세서/구매항목정보(`PURCHASE_DETAILS`) **필수**
  - 세금계산서/계산서(`INVOICE_TAX`) 발급 시 첨부

### 7.2 계좌이체 - 최소 세트
- `documents`
  - 이체 영수증/송금확인(`BANK_TRANSFER_RECEIPT`) **필수**
- `documents`
  - 거래명세서/지급요청서(`STATEMENT`) **필수**
  - 세금계산서/계산서(`INVOICE_TAX`) 발급 시 첨부
- (승인 프로세스가 있는 경우) `payables` 상태 이력(승인자/승인일 등)은 시스템 로그로 남기는 것을 권장

### 7.3 현금 지출(직원 현금 지출 포함) - 최소 세트
- `documents`
  - 현금영수증(`CASH_RECEIPT`) **필수**
- `costs`
  - 비용 내역(예: 퀵서비스/주유비/미팅비 등)을 `costs`에 기록 **필수**
  - 특정 프로젝트/주문항목에 기인한 비용이면 `cost_allocations`로 귀속 **권장**
- (권장) `payments(pay_method=CASH)` 기록
  - 현금이 실제로 지급되었다는 사실을 시스템 내에도 남김
  - 직원 정산/환급 프로세스는 별도 정책(본 범위 외)

### 7.4 Invoice(지급요청서/거래명세서)로 여러 PO를 묶는 경우 - 최소 세트
- `documents`
  - 거래명세서/지급요청서(`STATEMENT`) **필수**
  - 세금계산서/계산서(`INVOICE_TAX`) 발급 시 첨부
- `documents`
  - 지급 방식에 따른 증빙(카드 승인 또는 이체 영수증) **필수**
- (가능하면) invoice_lines에 PO/PO line 연결, PO 외 부대비용 라인은 별도 invoice_line으로 분리


---

## 5. 시나리오별 코드값 빠른 표(드롭다운 입력 참고)

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

## (추가) 재무 불변식 요약 (Invoice/Payable/Payment) — v7.8.2 → v7.9.7 정본

운영에서 혼동이 잦은 3가지를 **정본 불변식**으로 고정한다.

1) **Invoice는 지급 단위가 아니다.**  
   - invoice는 외부 문서 컨테이너이며, 지급은 payable 단위로 이루어진다.

2) **Payable이 지급 단위(재무 업무 단위)이다.**  
   - 승인/보류/기한/부분지급/마감 등의 업무 상태는 payables에서만 관리한다.

3) **Payment는 실제 돈이 나간 결과이다.**  
   - payment는 “지급 사실”만 기록하며, 무엇을 얼마나 정산했는지는 `payment_lines`(cost 기준)로 정리한다.
   - payment ↔ payable은 `payment_payable_allocations`로 연결한다(분할/묶음 지급 지원).

추가로, 운영 정책:
- **PO 1건 = cost 1건**을 기본으로 유지한다(`po_cost_links` 1:1 권장).  
  멀티셀러/사업자 분리가 필요하면 PO를 분할하고, 분할이 불필요하면 PO=cost로 묶는다.

문서/증빙:
- 모든 증빙은 `documents`에 저장하고, 연결은 `document_links`로 한다.
- invoice/payable 관련 코드값(예: `invoice_status`, `invoice_type`, `charge_category`, `priority_level`)은
  `schema-policy-and-naming`의 코드북을 정본으로 따른다.
