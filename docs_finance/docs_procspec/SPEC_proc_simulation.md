# 통합 비용 관리 시뮬레이션 정책 문서
# Proc Simulation — Policy & Developer Spec

> **문서 위치**: `docs_finance/docs_proc/SPEC_proc_simulation.md`
> **대상 시뮬레이션**: `docs_finance/docs_proc/index.html`
> **참조 정본**: `adr/`, `ddl/erp_finance_schema.sql`, `ddl/erp_contracts_schema.sql`, `docs_finance/01_finance_domain_overview.md`, `docs_finance/02_finance_data_flow.md`, `docs_finance/03_ap_payable_spec.md`, `docs/service-scenarios.md`
> **최종 갱신일**: 2026-04-24

---

## 1. 이 문서를 만든 이유

### 1.1 시뮬레이션의 목적

`docs_finance/docs_proc/index.html`은 **Balhea ERP 구매/조달 비용 인식 → 지급 요청 → CEO 승인 흐름**을 개발팀이 시각적으로 검증·공유하기 위한 **프론트엔드 시뮬레이션**이다.

현행 재무 도메인 문서(`01~06` 시리즈)는 재무 담당자 시점(AP 집행 이후)의 흐름을 중심으로 기술되어 있다.
반면, **조달 담당자 시점**—즉 PO 이후 비용을 인식하고 분할 지급을 기안하여 CEO에게 상신하는 흐름—은
별도의 시뮬레이션이 필요하다고 판단하여 제작하였다.

### 1.2 이 시뮬레이션이 커버하는 정책 위치

```
[전체 AP 흐름에서 이 시뮬레이션의 위치]

PO 확정
  │
  ▼
① 비용 인식 (costs + po_cost_links)          ← ★ 구매담당자/관리자 (비용등록)
  │
  ▼
② 지급 요청 기안 (payables - CREATED)         ← ★ 구매담당자/관리자 (지급요청중)
  │
  ▼
③ CEO 최종 승인 (payables - APPROVED)        ← ★ 대표이사 (지급대기)
  │
  ▼
④ 재무 담당자 지급 실행 (payments)           ← 재무 도메인 시뮬레이션 담당 (지급완료)
```

---

## 2. 설계 원칙 (정본 ADR 기준)

아래 모든 원칙은 `adr/` 디렉토리의 Accepted 상태 ADR을 정본으로 한다.

### 2.1 D3 분리 원칙 (ADR-002)

> **불변식**: 비용 발생(cost), 지급 단위(payable), 실지급(payment)은 반드시 분리된 엔티티로 관리한다.

| 개념 | 정본 엔티티 | 이 시뮬레이션에서의 역할 |
|---|---|---|
| 비용 발생 | `costs` | `costs[]` 배열로 Mock 데이터 표현 (ct_sn, amount, origin_type) |
| 지급 단위 (기안) | `payables` | `payables[]`, `payable_cost_allocations[]`로 Mock 표현 |
| 실지급 | `payments` | 이 시뮬레이션 범위 外 (재무 모듈 담당) |

카드/현금 선결제 건은 payables 큐를 통과하지 않으며, 이 시뮬레이션에서는 별도 배지(`법인카드`)로 표기 후
**"지급 내역 보고하기"** 버튼으로 처리 경로를 안내한다. (ADR-002, service-scenarios 시나리오 A 준거)

### 2.2 PO 1건 = Cost 1건 원칙 (ADR-012)

> `po_cost_links`는 1:1 관계를 유지한다. 셀러/사업자 분리 필요 시 PO를 분할한다.

이 시뮬레이션에서 `origin_sn` 필드가 PO 번호(`PO-YYYYMMDD-NNNN`) 또는
직접비용 번호(`DIR-NNNN`, `SH-NNNN`, `RF-YYYYMMDD-NNN`)를 담아 이 원칙을 표현한다.

| origin_sn 패턴 | 의미 | 정본 링크 테이블 |
|---|---|---|
| `PO-YYYYMMDD-NNNN` | 발주서 기반 비용 | `po_cost_links` |
| `SH-NNNN` | 물류/배송 비용 | `shipment_cost_links` |
| `DIR-NNNN` | 현장 직접 구매 | `sourcing_case_cost_links` 또는 `project_cost_links` |
| `RF-YYYYMMDD-NNN` | 환불/상계 항목 | `costs.amount < 0` 처리 원칙 |

### 2.3 비용 귀속의 정본은 cost_allocations (ADR-009)

> `po_cost_links` 등 링크 테이블은 UI 탐색 편의용이다. 회계/정산 기준은 반드시 `cost_allocations`다.

이 시뮬레이션의 `payable_cost_allocations[]` 배열은 위 원칙의 Mock 표현이다.
구현 시 실제 백엔드는 `cost_allocations` 테이블을 기준으로 원가 계산을 수행해야 한다.

### 2.4 마이너스 Cost = 상계(Offset) 처리 원칙 (docs_finance/01 v2.0)

> `costs.amount < 0`인 항목은 상계(Offset) 항목으로 취급한다.

이 시뮬레이션에서 `origin_type: 'REFUND'`이고 `amount < 0`인 항목이 이에 해당한다.
환불 확정 건은 `is_refund: true`로 별도 표시하며, 리스트에서 진행상태를 `확정`으로 표기한다.

---

## 3. 시뮬레이션 데이터 구조 설명

### 3.1 비용 종류 (origin_type) 정의

이 시뮬레이션이 표현하는 5가지 비용 종류는 모두 정본 DDL의 `costs.ct_type` 값에 대응한다.

| 시뮬레이션 origin_type_display | origin_type | DDL ct_type 대응 | 특징 |
|---|---|---|---|
| **프로젝트 발주비용** | `PO` | `PRODUCT` / `SERVICE` | 발주서(purchase_orders) 1:1 연결. 분할 지급(계약/중도/잔금)이 기본. 검수 후 기성 지급 요청. |
| **프로젝트 부대비용** | `PO` | `SERVICE` / `OTHER` | 발주서 기반이나 현장 운영비 성격. 법인카드 결제 또는 사후 정산. 품목 검수 불필요. **지급 수단별 증빙 정보(영수증/계좌) 등록이 핵심.** |
| **품목별 직접비용 (물류)** | `SHIPMENT` | `SHIPPING` | 물류 파트너사(배송, 상하차 등) 실비 정산건. ADR-008 4축 모델 중 `shipments` 연결. **계좌 정보 등록 필수.** |
| **품목별 직접비용 (구매)** | `DIRECT` | `OTHER` | PO 없이 현장 직접 구매(영수증 처리). 법인카드 결제 다수. 승인 즉시 재무 매입 기록 생성. **증빙 파일 첨부 필수.** |
| **환불 확정 (카드/계좌)** | `REFUND` | *(amount < 0)* | `costs.amount < 0`인 상계 항목. 카드: PG사 결제 취소. 계좌이체: 정산조정관리(recon) 연동 대상. |

### 3.2 지급수단 및 증빙 정보 등록 정책 (NEW)

부대비용(`INCIDENTAL`), 직접비용(`DIRECT`, `SHIPMENT`), 환불(`REFUND`) 항목은 상세 패널에서 실제 집행을 위한 정보를 등록해야 한다. (발주비용은 이미 발주서에 정보가 있으므로 제외)

| 지급 수단 | 등록 항목 | 로직 및 특이사항 |
|---|---|---|
| **카드 결제** | 증빙 파일 | '파일 등록' 버튼 클릭 시 파일 시뮬레이션(Prompt)을 통해 파일명을 `proof_filename`에 저장. |
| **계좌 이체** | 은행, 예금주, 계좌번호 | **마스터 거래처 검색**: `partners` 배열에서 업체명 검색 후 선택 시 은행/계좌 정보 자동 완성. |
| **수기 입력** | 은행, 예금주, 계좌번호 | 마스터 데이터에 없는 업체인 경우 직접 텍스트 입력 가능. |

등록된 정보는 `pbl_proof_details` 배열에 담겨 `localStorage: erp_shared_payables`를 통해 재무 모듈로 브릿징된다.

### 3.2 환불 처리 경로 분기

```
costs.amount < 0 (상계 항목)
  │
  ├── refund_method: 'Card'
  │     ▼
  │   PG사(카드사) 결제 취소 API 연동
  │   → 승인 시 입출금내역관리(docs_check/index.html)에 마이너스(-) 매입 기록
  │   → 카드 한도 즉시 복구
  │
  └── refund_method: 'Transfer'
        ▼
      정산조정관리(docs_check/recon.html) 이관 대상
      → 현금 반환 또는 차기 매입 대금과의 상계(Offset) 처리 선택 가능
      → [재무관리 > 정산조정] 시스템에서 최종 조정 컨펌 필요
```

> **정본 근거**: `docs_finance/02_finance_data_flow.md` §2.3 마이너스 Cost 처리 흐름, `01_finance_domain_overview.md` §3.5

---

## 4. 역할 분리 (RBAC) 및 상태 전이 설계

### 4.1 구현된 역할 (3-Role System)

구매 파트의 담당자와 관리자는 **동일한 업무 로직**을 공유하되, **조회 범위**에서 차이를 둡니다.

| 역할 | 시뮬레이션 구현 | 업무 로직 (Logic) | 가시성 (Visibility) |
|---|---|---|---|
| **구매담당자** (Staff) | `팀원1`, `팀원2` | **동일**: 비용 등록, 증빙 첨부, 지급 요청 기안 | **본인 건만** 조회 및 처리 가능 |
| **중간관리자** (Manager) | `중간관리자` (본인) | **동일**: 비용 등록, 증빙 첨부, 지급 요청 기안 | **팀 전체** (본인+팀원) 조회 및 처리 가능 |
| **대표이사** (CEO) | `CEO` | 상신건 최종 검토, 승인 / 반려 | **전사** 상신 내역 조회 가능 |

### 4.2 진행상태 매핑 (payables)

이 시뮬레이션은 실무 흐름에 맞춰 아래와 같이 진행상태를 정의합니다.

| 시뮬레이션 상태 | 정본 payable 상태 | 설명 |
|---|---|---|
| `비용등록` | `DRAFT` (Initial) | 구매 집행 그룹이 데이터를 생성하고 편집 중인 초기 상태. |
| `지급요청중` | `CREATED` (Submitted) | 결재 상신 완료. CEO 승인 대기 중. (내부 `payables` 생성 시점) |
| `승인반려` | `REJECTED` | CEO에 의해 반려된 상태. |
| `지급대기` | `APPROVED` | CEO 승인 완료. 재무 이체 전 단계. (데이터 재무 모듈 이관 시점) |
| `지급완료` | `PROCESSED` | 재무 시스템에서 이체 완료 보고됨. |

### 4.3 CEO 모드 진입 시 View 전환 정책

- CEO 전환 시 `filterUser = 'ALL'`, `filterStatus = 'ALL'` (단, 초기 로드는 지급요청중 위주)
- 전체 담당자의 **상신된 건 전체**를 기본으로 로드 (담당자별 필터 추가 선택 가능)
- 카드/법인카드 결제 건 + 환불 확정 건은 **내용 확인 완료** 단일 버튼만 노출 (승인/반려 분기 불필요)

---

## 5. 분할 지급 (installments) 기획

### 5.1 설계 배경

정본 ADR-002는 분할 지급 시 "payable을 다시 분할하지 않는다. 기존건을 취소하고 새로 만든다"고 정의한다.
그러나 **단일 PO의 계약금/중도금/잔금 분리 기안** 업무는 실무에서 빈번하다.

이 시뮬레이션은 **한 cost(PO) 안에서 여러 회차의 지급 요청을 시각화**하는 방식으로 이를 표현한다.
(service-scenarios 시나리오 E: "1 cost를 여러 번 분할 계좌이체" 준거)

```
PO 1건 (cost 1건)
  └── installments[]
        ├── 계약금 (지급대기 / 비고(Note) 입력 가능)
        ├── 1차 중도금 (승인요청중 / 잠금)
        └── 잔금 (지급대기 / 비고(Note) 입력 가능)
```

### 5.2 비고(Note) 및 메모 관리

- 각 지급 회차(Installment)별로 **비고(Note)** 컬럼을 제공하여 실무자가 특이사항을 기록할 수 있다.
- 입력된 비고 내용은 `payables` 상신 시 `pbl_proof_details`와 함께 재무 담당자에게 전달되어, 지급 실행 시 참고 자료로 활용된다.
- **담당자 의견(Manager Opinion)**: 상세 패널 상단의 의견란은 담당자가 기안 시 CEO에게 전달하는 메모이며, CEO는 이에 대한 승인/반려 코멘트를 별도로 남길 수 있다.

### 5.3 기안 추가 버튼 로직 (toggleInstallment)

- `inst.status === '지급대기' || '작성중'`인 회차만 기안 대상에 추가/제외 가능
- `inst._selected = true`인 회차들의 `req_amount` 합계 → 하단 `detailReqAmount` 실시간 갱신 (Computed)
- `isInstFrozen(inst)`: `['승인완료', '승인요청중'].includes(inst.status)` → 편집 잠금
- **전액 정산 차단 (isItemFullySettled)**: 
    - `sum(frozen installments) >= grandTotal.total` 이고 아이템 상태가 `승인완료`인 경우
    - 신규 행 추가 버튼 및 기존 행의 기안 버튼(`+`)을 모두 비활성화/숨김 처리하여 초과 기안을 방지한다.

### 5.3 잔액 자동 밸런싱 (balanceInstallments)

```
totalWithVAT = grandTotal.total
currentSum = sum(installments[].req_amount)
diff = totalWithVAT - currentSum

→ 편집 중이 아닌 마지막 editable 행에 diff 자동 반영
```

> **실제 구현 시 주의**: 잔금 자동 밸런싱은 공격적인 UX를 만들 수 있다. 0 미만(음수)이 되는 경우 UI 경고 처리 권장.

---

## 6. 총계 계산 공식

### 6.1 grandTotal Computed 로직

```
품목 소계 = SUM(items[].qty * items[].price)  (is_sub 제외)

특수비용 소계:
  - tax_application === 'inclusive': floor(qty * price / 1.1)  → subtotal
  - tax_application === 'separate': qty * price              → subtotal
  - VAT: inclusive면 (qty*price - subtotal), separate면 floor(subtotal * 0.1)

taxExcl = (품목 소계 + 특수비용 세전 소계 - 할인액) × sign
vat = (품목VAT + 특수비용VAT) × sign
total = taxExcl + vat

※ is_refund === true인 경우 sign = -1 (금액 전체 부호 반전)
```

---

## 7. DEV GUIDE 모드 설계

### 7.1 도입 목적

개발팀과 시뮬레이션을 공유할 때, 각 UI 요소의 **정본 데이터 소스·로직·주의사항**을 마우스 호버만으로
즉시 확인할 수 있도록 인라인 기술 문서화 시스템을 구축하였다.

### 7.2 마커 종류

| 마커 | 형태 | 의미 |
|---|---|---|
| **노란 원형** | ● (circle) | 읽기 전용 UI 요소. 데이터 표시 컬럼, 상태 배지, 헤더 등 |
| **주황 사각형 ⚡** | ■ (square + lightning) | 실행 가능한 요소. 버튼 클릭, 상태 전이, API 연동 로직 포함 |

### 7.3 등록된 메모 키 목록

| 메모 키 | 연결 UI | 내용 요약 |
|---|---|---|
| `page_title` | 화면 헤더 | 화면 개요, 전체 역할 설명 |
| `role_switcher` | PURCHASE/CEO 전환 버튼 | RBAC 권한 제어, 상태 전이 |
| `team_filter` | 담당자 필터 버튼 | CEO 모드 전체 조회 vs 개인 필터 |
| `bulk_request` | 일괄 지급승인요청 버튼 | 다건 상신 로직, localStorage Sync |
| `filter_date` | 기간 조회 필터 | 프리셋 및 커스텀 범위 제한 |
| `filter_status` | 진행상태 드롭다운 | 5단계 상태, CEO 기본값 정책 |
| `grid_main` | 리스트 헤더 (담당자 컬럼) | 그리드 컬럼 구조, 종류 분류 |
| `grid_amount` | 결제금액 컬럼 헤더 | 음수(환불) 표시 정책 |
| `drawer_header` | 상세 패널 닫기/고정 버튼 | Split-View 고정, 딥링크 계획 |
| `ceo_opinion_area` | 대표님 의견 영역 | 결재 의견 조건부 표시 |
| `item_detail_section` | 항목 상세내역 섹션 헤더 | Read-Only 원천 데이터, 부대비용 테이블 전환 |
| `project_info_btn` | 프로젝트 정보 보기 버튼 | project_info.html 팝업 연결 |
| `refund_section` | 환불 상세내역 섹션 | 음수 cost 처리, 환불 방식별 분기 |
| `special_cost_table` | 특수비용 섹션 | 부가세 계산 로직, 일회성 부대비용 |
| `grand_total_panel` | 발주 총계 패널 | 총계 계산식, VAT 적용 방식 |
| `installment_logic` | 지급 요청내역 섹션 | 분할 지급, 밸런싱, 기안 체크 |
| `installment_draft_btn` | 기안추가 버튼 | 기안 금액 합산 로직 (detailReqAmount) |
| `action_panel_logic` | 하단 지급요청일/금액 패널 | 기안 실행 (내부 결재 큐 진입) |
| `ceo_approval_btns` | CEO 의견 입력 + 승인/반려 버튼 | 최종 승인 시 재무 ERP 데이터 송신(syncToFinance), 상태 전이 |
| `row_type_PO` | 리스트 발주비용 행 | 분할 지급, 손익 연동 |
| `row_type_INCIDENTAL` | 리스트 부대비용 행 | 간접비용, 법인카드, 증빙 첨부 |
| `row_type_SHIPMENT` | 리스트 직접비용(물류) 행 | 물류 파트너사 정산, ADR-008 |
| `row_type_DIRECT` | 리스트 직접비용(구매) 행 | 현장 구매, 법인카드 결제 경로 |
| `row_type_REFUND_Card` | 리스트 카드환불 행 | PG 취소 API, 입출금내역 연동 |
| `row_type_REFUND_Transfer` | 리스트 계좌환불 행 | 정산조정관리 연동, 상계 처리 |
| `proof_registration_area` | 상세 증빙 등록 섹션 | 카드 파일 첨부, 마스터 데이터 기반 계좌 조회 |
| `partner_master_data` | 마스터 거래처 검색 필드 | `partners` 데이터 연동 및 다중 계좌 선택 로직 |
| `grid_incidental_guide` | 리스트 종류 컬럼 마커 | 부대비용/직접비용 대상 상세 가이드 안내 |

---

## 8. 타 시뮬레이션과의 연동 경계

| 연동 대상 | 연동 방식 | 시뮬레이션 위치 |
|---|---|---|
| **재무 AP 집행** (payable → payment) | `localStorage: erp_shared_payables` | `docs_finance/docs_check/index.html` |
| **카드 환불 이력** | `target_system: '입출금내역관리'` | `docs_finance/docs_check/index.html` |
| **계좌 환불 / 정산조정** | `target_system: '정산조정관리'` | `docs_finance/docs_check/recon.html` |
| **프로젝트 정보** | `window.open('project_info.html')` 팝업 | `docs_finance/docs_proc/project_info.html` |

---

## 9. 미구현 / Phase 2 확장 범위

현행 시뮬레이션에서 의도적으로 제외된 항목이다.

| 항목 | 이유 | 정본 근거 |
|---|---|---|
| 실 지급 실행 (payments 생성) | 재무 도메인 시뮬레이션(docs_check) 담당 | `docs_finance/01` §4 |
| 세금계산서 대사 | recon.html 담당 | `docs_finance/04_reconciliation_spec.md` |
| 상계(Offset) 불러오기 버튼 | 정기결제관리(AP)에 구현됨, 이 화면은 기안 단계 집중 | `docs_finance/02` §2.3 |
| 복수 담당자 | 현재 `teamMembers`는 단일 담당자(정성우) Mock | `docs_finance/03` §10 |
| 감사 로그 | `audit_changes` 연동 필요, Phase 2 | ADR-005 |
| AR(수금) 흐름 | 재무 도메인 Phase 2 | `docs_finance/02` §3 |

---

## 10. 개발자 체크리스트

### 10.1 백엔드 구현 시 반드시 확인할 정합성 규칙

- [ ] `po_cost_links` UNIQUE KEY on `po_sn` → PO 1건에 cost 1건만 연결
- [ ] `po_cost_links` UNIQUE KEY on `ct_sn` → cost 1건이 두 PO에 중복 연결 불가
- [ ] `payable:payment = 1:1` (운영 서비스 레벨 검증)
- [ ] `costs.amount < 0` 인 항목은 상계 파이프라인으로 처리 (일반 지급 요청 대상에서 제외)
- [ ] 구매 담당자 기안(CREATED) → CEO 승인(APPROVED) 없이 payment 생성 불가

### 10.2 시뮬레이션 데이터 Mock 검증

- [ ] `origin_sn` 패턴이 정합성 규칙(PO/SH/DIR/RF)을 따르는지
- [ ] `origin_meta` 키가 모든 `costs[].origin_sn`과 1:1 대응하는지
- [ ] `is_refund: true` 항목의 `amount`가 음수인지
- [ ] 분할 지급(`installments`)의 `req_amount` 합계가 `grandTotal.total`과 일치하는지

---

> **참조 정본 파일 목록**
>
> | 파일 | 주요 참조 내용 |
> |---|---|
> | `adr/ADR-002-cost-vs-payment.md` | D3 분리 원칙, 카드/현금 직행 처리 |
> | `adr/ADR-009-cost-links-vs-cost-allocations.md` | cost_allocations 정본, 링크 보조 역할 |
> | `adr/ADR-012-po-equals-cost-policy.md` | PO 1건 = cost 1건 불변식 |
> | `adr/ADR-008-po-after-4-axis-model.md` | 물류 4축 모델 (SHIPMENT 비용 근거) |
> | `adr/ADR-013-separate-document-physical-execution-no-items.md` | 단위 명명 규칙 |
> | `ddl/erp_finance_schema.sql` | costs, payables, payments, cost_allocations 스키마 |
> | `docs_finance/01_finance_domain_overview.md` | 재무 도메인 전체 원칙, 상계 처리 정책 |
> | `docs_finance/02_finance_data_flow.md` | AP 흐름, 상태 전이, 마이너스 Cost 처리 |
> | `docs_finance/03_ap_payable_spec.md` | AP 화면 기획, 지급 실행 블록, RBAC |
> | `docs/service-scenarios.md` | 재무 시나리오 A~E, 불변식 요약 |
