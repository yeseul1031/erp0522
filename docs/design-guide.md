# Balhea ERP Design Guide (Canon v7.9.x)

> 목적: 스키마 “생성 규칙/네이밍”이 아니라, **서비스·업무 관점에서의 설계 의도 / 논리 모델 / 사용 규칙**을 설명한다.  
> 입력 예시(레코드 단위)는 `service-scenarios.md`로 분리한다.

---

## 1. 설계 철학(Why)

### 1.1 프로젝트 중심(Project-centric)
Balhea ERP의 최상위 단위는 **프로젝트(projects)** 다.

- 모든 비용(cost)은 프로젝트에 귀속/집계 가능해야 한다.
- 모든 책임/담당(assignee)은 프로젝트 기준으로 정의된다.
- 담당자 변경은 프로젝트/라인의 담당자 참조만 수정하면 된다.

> “조직(부서)·직원(인사) 데이터”는 ERP의 정체성이 아니라 외부 맥락이다.

### 1.2 조직/직원 정보를 ERP에 저장하지 않는 이유
- 직원/조직 정보는 그룹웨어(또는 HR 시스템)가 단일 진실 소스(SSOT)다.
- ERP에 조직 정보를 복제하면 동기화/정합성 문제가 발생한다.
- ERP는 “업무 사실(fact)”을 기록한다.

따라서 ERP에는 직원 상세정보가 아니라, 외부 시스템의 **principal(식별자)** 만 저장한다
(예: `..._assignee_principal` 같은 텍스트/식별자 컬럼).

---

## 2. 핵심 불변식(Core Invariants)

### 2.1 cost ≠ payment ≠ payable
재무 영역은 “발생/유출/통제”를 분리한다.

- **costs**: 비용/원가/채무의 *발생 사실*
- **payments**: 현금/자산의 *실제 유출(지급 행위)*
- **payables**: 이체 승인/보류/우선순위 등 내부 통제를 위한 *선택적 중간 단위*

이 분리를 통해 아래를 단순하게 지원한다.
- 분할 지급(선금/중도금/잔금)
- 카드 즉시결제 vs 계좌이체 승인 프로세스
- 현금 지급 처리 및 증빙 연결

### 2.2 Documents Hub: `documents` + `document_links` 단일 정책
문서/증빙/첨부는 엔티티별 전용 테이블로 쪼개지 않는다.

- 모든 파일 원본은 **`documents`** 에 *단일 저장*
- 문서가 무엇의 근거인지(비용/지급/인보이스/배송/작업 등)는 **`document_links`** 로만 연결
- 동일 문서는 여러 대상에 다대다로 연결 가능(저장은 1회, 링크만 다수)

#### 2.2.1 `document_links` 유효성 검증 원칙
`document_links`는 polymorphic이므로 DB FK로 전부 강제하지 않는다.  
`target_type + target_sn` 유효성은 애플리케이션에서 검증한다.


### 2.3 발주서
- 발주서(PO 문서)
  - 비용/지급 ‘증빙’이라기보다 **조달 의사결정/업무 문서**
  - 가능하면 별도 업무 문서 저장소(예: documents)에 관리 권장
  - 여건상 documents에 둘 경우, 문서 타입(PO_DOC 등)을 명확히 표시하여 혼선을 방지

---

## 3. 논리 도메인 모델(What)

### 3.1 End-to-End 흐름(개념)
대표적인 정본 흐름(국내/해외 공통)은 아래와 같다.

`projects` → `order_lines`
(+ 필요 시 `order_line_overrides`)
→ `sourcing_cases`
→ `rfqs` / `rfq_lines` / `rfq_allocations`
→ `purchase_orders` / `po_lines` / `po_allocations`
→ (비용) `costs` / `cost_allocations` (+ 보조: `po_cost_links`)
→ (지급) `payments` / `payment_lines` (+ 필요 시 `payables` 및 배정 테이블)
→ (증빙) `documents` + `document_links`

### 3.2 프로젝트/주문/주문라인
- **projects**: 계약 단위(기본적으로 프로젝트 1개 = 계약 1개)
- **order_lines**: 고객에게 납품해야 할 약속 단위(요구 품목/수량/규격)
  - order_lines는 프로젝트 하에서 정의되는
  '납품 또는 집행 요구의 최소 단위'이다.
  - 반드시 주문서(order)를 전제로 하지 않는다.
  - 수급(sourcing), 정산(receivable), 배송(delivery)의 기준점이 된다.
  - 계약 문서상 요구사항을 구조화한 내부 엔티티이다.


#### 프로젝트 유형(예시)
- `TENDER` : 공공 입찰(단건 입찰 포함)
- `DIRECT` : 민간/직접 계약
- `FRAME` : 장기/콜오프(기간 내 다수 주문 발생 가능)

---

## 4. 조달(Procurement) 모델링 의도

### 4.1 99% 경로 vs 1% 희소 케이스
#### 99% 경로(운영 편의성 우선)
대부분은 **주문라인 1개 = 실제 구매/납품 상품(goods) 1개**다.  
그래서 `order_lines.ol_default_g_sn`(기본 goods FK)을 제공한다.

- override가 없다면 `ol_default_g_sn`을 사용해 RFQ/PO 라인을 자동 생성할 수 있다.

#### 1% 희소 케이스: Override 패턴(`order_line_overrides`)
전체 스키마를 복잡하게 만들지 않기 위해 희소 케이스는 `order_line_overrides`로만 수용한다.

- `SPLIT` : 수량을 나눠 여러 상품/여러 발주로 처리
- `SUBSTITUTE` : 일부를 유사 대체품으로 처리
- `ADD_ON` : 불량/추가요청 등으로 추가 구매
- `BUNDLE` : 조합 납품(PC 등) 구성품 구매 단위

**문서 생성 규칙(정본)**  
override가 있으면 override 전개 결과를 우선하여 RFQ/PO 라인을 만든다.  
override가 없으면 default goods를 사용한다.

### 4.2 Sourcing Case는 “발주 단위”가 아니라 “수급 전략/관리 단위”
- `sourcing_cases`는 수급 전략(국내/해외/제작) 및 진행 상태를 담는 관리 단위다.
- 실제 구매 실행은 `purchase_orders`에서 이루어진다.
- 하나의 `sourcing_case`에 여러 PO가 연결될 수 있다(분할 발주 가능).

#### 다중 발주 검증 규칙(운영/리포트 레벨)
하나의 `sourcing_case`에 속한 모든 `po_lines.qty` 합은,
- 케이스 목표 수량(있는 경우) 또는
- 연결된 주문라인의 요구 수량
과 논리적으로 일치해야 한다.

이 규칙은 DB 제약으로 강제하지 않고, 운영 검증/리포트로 점검한다.

### 4.3 후보군 비교의 “그룹 키”는 goods가 아니라 `order_line`/`sc_sn`
드라이버/CPU/모니터 등 후보 비교는 “같은 요구(주문라인) 또는 같은 수급 케이스” 단위로 묶인다.

- BUNDLE(PC)처럼 한 `sc_sn` 안에 구성품이 섞일 수 있다.
- 그래서 allocation에서 `olo_sn`을 사용하여 구성품/후보군/분할을 명시할 수 있어야 한다.

### 4.4 RFQ/PO는 “진실의 원천(Source of Truth)”
실제로 업체에 전달한 RFQ/PO 문서와 라인 정보가 구매/정산/증빙의 기준이다.

- 주문라인의 default/override는 입력 편의 및 의사결정 기록 목적
- 최종 실제 구매는 **PO 라인**을 기준으로 계산한다.

---

## 5. 국내/해외/제작 도메인 분리

### 5.1 수급 방식(Sourcing Type)
수급 방식은 `sourcing_cases.sourcing_type`에서 관리한다.

- `DOMESTIC` : 국내 구매(견적→발주→납품)
- `OVERSEAS` : 해외 구매(통화/인도조건/운송/통관 등 옵션 필드/프로세스 추가)
- `IN_HOUSE` : 자체 제작(재료 수급 + 생산/검수 등 별도 프로세스)

수급 방식은 업무 중 변경될 수 있다(국내→해외 등).  
스키마를 과도하게 복잡하게 만들기보다, 현재 활성 타입을 갱신하고 이력은 로그(`audit_changes`/`activity_logs`)로 남긴다.

### 5.2 RFQ/PO 단일화 정책 + 해외 옵션 필드
운영 관점에서 국내/해외는 “테이블 분리”가 아니라 “옵션 필드 차이”에 가깝다.

- RFQ: `rfqs` / `rfq_lines` / `rfq_allocations`
- PO: `purchase_orders` / `po_lines` / `po_allocations`
- 해외 옵션(필요 시만): `trade_terms`, `ship_from_country`, `ship_to_country`, 라인 통화(`po_lines.ccy`) 등

#### 소스 오브 트루스(중요)
국내/해외 구분의 최종 기준은 **`sourcing_cases.sourcing_type`** 이다.  
RFQ/PO 헤더의 sourcing_type은 조회/필터 편의용(선택)으로 둘 수 있다.

### 5.3 해외 비용의 환율 재현(감사 대응)
해외 비용은 시점별 환율이 달라 감사 재현성이 중요하다.  
정산 시점의 적용 환율과 원화 환산 결과를 **고정 저장**한다.

- 권장: `cost_fx_applications`
  - `applied_fx_rate`, `as_of_dt`, `base_amount(KRW)` 저장
  - 필요 시 `fx_rates` 참조

---

## 6. 거래처(Parties) 모델링 의도

### 6.1 Parties는 “정산/결제 상대” 단위로만
- parties는 정산 주체(플랫폼/업체) 단위로만 관리한다.
  - 예: 네이버, 쿠팡, 알리익스프레스, 해외 벤더 등
- 오픈마켓 셀러 N곳을 parties로 분해하지 않는다.
  - 셀러 표시명/발행자명은 `documents` 메타(issuer_name 등) 텍스트로만 보존한다.
- 퀵/대행/비정형 지출은 예약된 party 1개로 처리한다.

---

## 7. 재무(비용/지급/증빙) 논리 모델

### 7.1 비용 귀속의 정답은 `cost_allocations`
- 원장(발생): `costs`
- 귀속/안분: `cost_allocations`
  - 귀속 키: `p_sn/o_sn/ol_sn/olo_sn/sc_sn` 등

> 원가/마진 계산의 기준은 항상 `cost_allocations`다.  
> `po_cost_links` 같은 링크는 조회/탐색/UI 편의용으로만 허용한다(회계 기준 아님).

### 7.2 Invoice / Payable / Payment 역할 분리
- **Invoice(`invoices`)**: 외부 거래/청구 문서 컨테이너(지급 단위 아님)
- **Payable(`payables`)**: 내부 지급 단위(승인/보류/우선순위/부분지급/마감)
- **Payment(`payments`)**: 실지급 결과(현금흐름)

기본 연결(다대다/분할 지원):
- payable ↔ invoice: `payable_invoice_allocations`
- payable ↔ cost: `payable_cost_allocations`
- payment ↔ payable: `payment_payable_allocations`
- payment ↔ cost(실정산): `payment_lines`

### 7.3 “무엇을 생성해야 하는지” 결정 트리(개념)
질문 흐름:
1) 비용이 발생했나? → YES면 `costs`
2) 특정 프로젝트/라인/수급에 기인하나? → YES면 `cost_allocations`
3) 돈이 실제로 나갔나? → YES면 `payments`
4) 승인/이체 프로세스가 필요한가? → YES면 `payables`
5) 분할 지급인가? → YES면 `payments` 여러 건 + `payment_lines` 분할 연결

---

## 8. 물류/배송(PO After) 논리 모델

### 8.1 “배송은 비용이 아니라 상태/흐름”이다
운송료 등 비용은 별도의 `costs`로 기록한다.  
배송/물류는 “무엇이 어디로 어떻게 이동했는가”를 추적한다.

### 8.2 PO After는 4축으로 분리한다(정본)
발주 이후 영역을 실무 추적 단위에 따라 4축으로 모델링한다.

1) **실물(바코드 단위)**: `inventory_units`  
2) **운송(외부 구간 추적)**: `shipments` + `shipment_milestones`  
3) **작업(사람이 수행)**: `logistics_jobs` + `logistics_job_stops` + `logistics_job_lines`  
4) **협의(요청/역제안/수락)**: `delivery_requests` + `delivery_request_lines` + `delivery_request_proposals`

이 분리로,
- 직송(회사 미접촉)과 바코드 기반 재고 흐름을 동시에 수용하고
- 물류팀의 실행 이력을 1급 엔티티로 남기며
- 구매팀↔물류팀 협의(역제안/수락/거절) 로그를 독립적으로 관리한다.

### 8.3 협의가 필요한 경우/불필요한 경우
- 필요: 요일/시간창 협의, 역제안/수락/거절이 중요한 경우  
  → `delivery_requests`(+ proposals)로 합의 로그를 남기고, 실행을 `logistics_jobs`로 만든다.
- 불필요: 협의 없이 바로 실행되는 긴급 출고/납품  
  → `logistics_jobs`만으로 실행 이력을 남긴다.

### 8.4 직송 vs 바코드 추적(회사 접촉 여부)
- 직송(회사 미접촉): `inventory_units` 생략 가능  
  - 운송 추적이 필요하면 `shipments` + `shipment_milestones`
  - 납품 증빙은 문서 허브로 연결(`documents` + `document_links`)
- 회사 접촉/바코드 필요: 입고/출고/재고가 필요하면 `inventory_units` 생성 후 작업 라인에 담는다.

---

## 9. 용어 불변(혼동 방지)

### 9.1 문서 / 실물 / 작업은 절대 섞지 않는다
- 문서(Document): 계약/주문/RFQ/PO 등 “서류/목록” 단위 → `*_lines`
- 실물(Physical): 바코드가 붙는 통제 가능한 실물 단위 → `inventory_units`
- 작업(Execution): 사람이 수행한 수거/이송/납품 실행 단위 → `logistics_jobs`

협의(요청/역제안/수락)는 실행이 아니므로 별도 엔티티로 둔다: `delivery_requests`(+ proposals)

### 9.2 “items”라는 단어/엔티티는 사용하지 않는다
아이템은 범위가 넓어(품목/라인/실물/작업) 혼동을 유발한다.  
정본에서 의미는 아래로 고정한다.

- 문서의 항목 = `*_lines`
- 실물 1개 = `inventory_units`
- 작업 1건 = `logistics_jobs`

---

## 10. (부록) 운영 코드 표준(드롭다운/검증용)
> 코드값은 가능한 한 enum처럼 고정하고, UI/백엔드에서 드롭다운으로 관리한다(임의 텍스트 입력 금지).

### 10.1 Incoterms / trade_terms (Incoterms 2020, 대문자)
`EXW`, `FCA`, `FOB`, `CFR`, `CIF`, `CPT`, `CIP`, `DAP`, `DPU`, `DDP`

- 국내 구매: 보통 NULL 허용(권장)
- 해외 구매: 가능하면 입력(권장)
- trade_terms는 가격조건이 아니라 책임 경계선이므로 운송/통관 비용 귀속과 함께 맞춘다.

### 10.2 delivery_method (PO 이후 물류 1차 방식)
- `PICKUP_BY_LOGISTICS` : 물류팀이 판매처 방문 수거
- `SELLER_SHIP_TO_COMPANY` : 판매처가 회사(사무실/창고)로 배송
- `SELLER_SHIP_TO_CUSTOMER` : 판매처가 납품처로 직송

(해외 확장 예시) `FORWARDER_MANAGED`, `COURIER`, `FREIGHT_TRUCK`

### 10.3 procurement_mode
`DOMESTIC`, `OVERSEAS`, `IN_HOUSE` (+ 필요 시 `SERVICE`)

### 10.4 fx_rate_policy (환율 적용 “정책” 메모)
`QUOTE_DATE`, `PO_DATE`, `PAYMENT_DATE`, `CUSTOMS_DATE`, `MANUAL`  
> 실제 환율 숫자는 costs 쪽에 고정 저장한다.

### 10.5 작업/운송 상태 코드(예시)
- `logistics_jobs.job_type`: `PICKUP`, `TRANSFER`, `DELIVERY`, `MIXED`
- `logistics_job_stops.stop_type`: `VENDOR`, `OFFICE`, `WAREHOUSE`, `CUSTOMER` (+ 해외 확장)
- `shipment_milestones.milestone_type`: `CREATED`, `PICKED_UP`, `IN_TRANSIT`, `ARRIVED`, `WAREHOUSE_IN`, `DELIVERED` (+ 해외 확장)
- `inventory_units.status`: `IN_TRANSIT`, `IN_OFFICE`, `IN_WAREHOUSE`, `RESERVED_FOR_DELIVERY`, `DELIVERED`, `DAMAGED`, `LOST`

### 10.6 기타 코드들
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

## 11. 감사/추적(Logging) 의도
- `activity_logs`: 주요 행위 기록(누가 무엇을 했는지)
- `audit_changes`: 값 변경 이력(JSON 기반 포함 가능)

외래키만으로는 “누가 언제 무엇을 왜 바꿨는지”를 완전히 설명하기 어렵다.  
따라서 로그를 통해 변경의 맥락을 보존한다.
