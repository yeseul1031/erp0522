# schema-policy-and-naming.md
## Database Schema Policy & Naming (Constitution)

본 문서는 본 시스템 데이터베이스 스키마(DDL)의 **정책(Policy) + 네이밍(Naming) + 작성/변경 방식**에 대한 정본이다.  
우선순위는 **조인 시 오사용 방지**와 **장기 운영에서의 일관성**이다.

---

## 0. 전제

- 약어(prefix) 중심: 테이블마다 고정 약어 `{t}`가 있고, 그 테이블의 “자기 필드”는 기본적으로 `{t}_`로 시작한다.
- 컬럼은 “길게 친절한 이름”보다 **“조인 실수 방지”**가 우선이라 약어를 붙인다.

---

## 0-1. (GPT 작업 지침 섹션) — 사람이 아니라 GPT를 위한 규칙

> 이 섹션은 **스키마 작업을 수행하는 GPT(및 자동화 도구)**가 “어떻게 일해야 하는지”를 명확히 하기 위한 지침이다.  
> 스키마 자체의 비즈니스 규칙이 아니라, **작업 방식/변경 방식/출력 방식**에 대한 규칙이다.

### A. 역할과 책임
- GPT의 의견/개선 제안은 언제나 환영되지만, **승인 없이 적용하지 않는다.**
- GPT가 더 좋아 보이는 방향을 떠올려도, 그것은 **제안**일 뿐이며 최종 결정은 설계 책임자가 한다.

### B. 변경 범위 원칙(핵심)
- “없던 내용을 추가”하는 보강은 가능하되, **기존에 있던 내용의 방향/의미를 바꾸는 변경은 반드시 승인 필요**이다.
- 기존에 합의된 방식(A)이 있는데 B가 더 좋아 보여도, GPT는 **A를 유지**하고 B는 **대안(제안)**으로만 제시한다.
- 문서/DDL의 톤 정리, 재배치, 요약, 재서술은 기본적으로 금지이며, 필요하면 **제안으로만** 제시한다.

### C. DDL/주석 취급 원칙
- DDL은 단순 SQL이 아니라 **의사결정과 운영 규칙을 담은 정본 문서**다.
- 기존 주석은 삭제/요약/재작성 금지. 필요한 경우 허용되는 작업은 아래 둘 뿐:
  1) **append-only 보강**
  2) **컬럼명 변경에 따른 주석 내 컬럼명 토큰 치환(다른 문장/의미는 불변)**

### D. 작업 산출물 규칙
- 사용자가 요청한 범위(예: 컬럼명/인덱스명/인덱스 참조 컬럼 등)만 수정한다.
- 추가 개선이 필요해 보여도, 승인이 없으면 **적용하지 않고 제안 목록으로만** 분리한다.

---

## 0-2. docs 파일 고정 목록(정본)

아래 4개 문서만 정본으로 유지하며, 사용자가 명시적으로 요청하지 않는 이상 파일명 자체는 변경하지 않는다.

- `docs/operations-guide.md` (HOW: 실무 입력/운영 절차)
- `docs/design-and-scenarios.md` (WHY/WHAT: 설계 맥락/시나리오)
- `docs/schema-policy-and-naming.md` (RULES: 정책/네이밍/코드/운영 규칙) ✅ 본 파일
- `docs/design-decisions-log.md` (DECISIONS INDEX: 결정 요약 + 기각 사유)

---

## 1. 테이블 / 약어 기본 규칙

- 테이블명은 **복수형**
- 각 테이블은 고유 약어 `{t}`
- 약어는 충돌 방지를 위해 **1글자보다 2~4글자 사용 가능**

---

## 2. 컬럼 네이밍 기본 (키 필드 제외 일반 필드)

### 2.1 “자기 필드”는 `{t}_`로 시작
엔티티 자체 속성은 `{t}_*` 형식을 따른다.

- `{t}_name` : 이름
- `{t}_code` : 코드(사번/내부코드 등)
- `{t}_status` : 상태
- `{t}_type` : 유형(종류)
- `{t}_note` : 기본 설명/비고(아래 2.4 참고)
- `{t}_desc` : 설명(긴 텍스트)

### 2.2 의미가 자명한 경우 중복 서술 금지
- 예: `assignees`(약어 `a`)에서 담당자명은 `a_name`이지 `a_manager_name` 같은 과잉 서술은 피한다.

### 2.3 role은 “업무 의미”로 붙인다
- 같은 종류가 2개 이상이거나 혼동 여지가 있으면 role로 분기
- 기술적 role도 허용: `current_`, `previous_`
- 도메인 role 권장: `home_`, `parent_`, `prev_`, `primary_`, `billing_`, `shipping_`
- role 위치는 보통 `{t}_{role}_...`

### 2.4 `{t}_note` 필드 규칙 (표준)
- `{t}_note`는 **해당 엔티티 레코드에 대한 기본 설명/비고**로 거의 고정한다.
- 기본 타입/크기 전제:
  - `{t}_note`는 기본적으로 `varchar(500)` 사용
- 만약 “기본 비고”가 아니라 특정 목적의 노트라면:
  - `{t}_{purpose}_note` 또는 `{t}_{role}_note`처럼 목적/역할을 명시한다.
- 만약 `varchar(500)`이 아닌 다른 타입/크기(예: `TEXT`)를 쓴다면:
  - 타입/성격이 드러나도록 이름을 바꾼다(예: `{t}_long_note`, `{t}_desc` 등).
- 구조화 데이터는:
  - `{t}_data_json`을 사용하며 타입은 `JSON`이다.

---

## 3. 상태 / 유형 / 코드성 필드 규칙

- 타입이 `varchar` / `char`라도 **실질적으로 enum처럼 쓰는 값**은 컬럼명에서 코드성임을 드러낸다.
- 예시 접미사: `_status`, `_type`, `_method`, `_kind`, `_role`, `_stage` 등  
  (코드 종류가 다양하므로 “예시 톤”으로 유지한다.)

### 3.1 상태(status) 네이밍 추가 규칙
- 단순히 “엔티티의 단일 상태”가 아니라, 성격이 다른 상태가 여러 개 존재할 수 있다.
- 이 경우 `_status`만 쓰지 말고, **무슨 상태인지 목적/대상을 명시**한다:
  - `{t}_{purpose}_status`

예(예시는 도메인에 맞게 조정):
- `sourcing_cases`에서
  - 수급 담당자 승인/수락 여부: `{t}_acceptance_status`
  - 수급 진행 단계: `{t}_process_status`

### 3.2 코드성 필드 주석 권장 구성
코드성 필드는 주석에 다음을 포함하는 것을 원칙으로 한다(가능하면 반드시 포함).

1. **What**: 이 필드가 의미하는 것  
2. **Allowed values**: 허용 값 / 코드 목록  
3. **When / Who sets**: 언제 / 누가 세팅하는지(자동 / 사용자 / 배치 / 외부연동)

---

## 4. 시간(Time) 컬럼 정책

- 엔티티 메타(레코드 생성/수정): `{t}_create_dt`, `{t}_update_dt`
- 비즈니스 이벤트(의미 기반): `*_at`

비즈니스 이벤트 시간 예:
- `issued_at` : 문서 발행/발송 시각
- `replied_at` : 회신 시각
- `accepted_at` : 수락 시각
- `delivered_at` : 납품 시각
- `occurred_at` : 비용 발생 시각
- `paid_at` : 지급 완료 시각

기간이 필요한 경우(필요한 엔티티에만):
- `started_at`, `ended_at`

---

## 5. 금액 / 수량 / 단가 / 통화 / 세금 규칙

- 금액: `{t}_amt`
- 세금: `{t}_tax_amt`
- 합계: `{t}_total_amt`
- 수량: `{t}_qty`
- 단가: `{t}_unit_price` 또는 `{t}_unit_amt` 중 하나로 표준화(선택 필요)
- 통화: `{t}_ccy` (예: KRW, USD)
- 환율: `{t}_fx_rate`

---

## 6. 문서 / 링크 / 할당 테이블 성격 규칙

- `_lines`: 상위 문서/오더의 “라인/항목” (row 개념)
- `_allocations`: N:M 매핑 + 수량/금액 배분(alloc) 성격이 포함되는 경우가 많음
- `_links`: N:M 연결이지만 배분 수치 없이 “관계만” 표현

---

## 7. 브릿지 테이블 예외 규칙  
(_links / _allocations)

브릿지 성격의 테이블들은 아래와 같은 예외 상황을 둔다.  
(현재 브릿지 성격의 테이블은 `_links`, `_allocations`가 있다.)

### A안: 정본 유지(예외 없음)
- FK도 일반 규칙 유지:
  ```
  {t}_{role?}_{ref}_sn
  ```

### B안: 브릿지에 한해 예외 허용
- 적용 대상: 테이블명이 `_links`, `_allocations`로 끝나는 테이블만
- FK 형식:
  ```
  {role?}_{ref}_sn
  ```
- 동일 `{ref}` 2개 이상이면 role 필수는 동일

---

## 8. 폴리모픽 링크(Polymorphic Link) 규칙 — 승인된 추가 규칙

폴리모픽 링크는 “대상 엔티티가 여러 종류”인 링크 구조를 말하며, 일반적인 `{ref}_sn` 패턴으로 `{ref}`를 고정할 수 없다.  
따라서 폴리모픽 링크는 아래의 표준 컬럼 구성을 허용한다.

- `target_type` : 대상 엔티티 타입 코드
- `target_sn` : 대상 엔티티의 PK 값(숫자 키)

원칙:
- `target_type`은 코드성 필드이므로 주석에 **What / Allowed values / When-Who**를 포함한다.
- `target_sn`은 `target_type`에 의해 해석되는 **동적 참조 키**이다.

---

## 9. 인덱스 네이밍 / 제약 / 운영 규칙

### 9.1 인덱스 네이밍은 “거짓말 금지”
- 인덱스명은 컬럼 의미를 반영해야 하며, 컬럼 리네임 등으로 **거짓말이 되면 인덱스명도 수정**한다.
- 인덱스 네이밍은 프로젝트 단일 규칙을 따른다.

권장 인덱스명 템플릿:
- 단일 컬럼:
  - `idx_{t}_{col}`
- 복합 인덱스:
  - `idx_{t}_{col1}_{col2}_...`
- UNIQUE:
  - `uq_{t}_{col1}_{col2}_...`
- FK 제약:
  - `fk_{t}_{col}_{ref}` 또는 `fk_{t}_{col}_{ref}_sn`

> `{t}`는 테이블 약어, `{col}`은 실제 컬럼명(전체)이다.

### 9.2 DDL/주석 운영 원칙(핵심)
- DDL은 단순 생성문이 아니라, 주석/의도/허용값이 포함된 문서여야 한다.
- 기존 주석은 삭제/요약/재작성하지 않는다(0-1 섹션의 원칙을 따른다).

---

## 10. 저장소 운영 규칙(정본)

### 10.1 DDL 파일 네이밍
- DDL은 반드시 `erp_*_schema.sql` (예: `erp_core_schema.sql`, `erp_finance_schema.sql`, `erp_logistics_schema.sql`)
- 파일명에 버전은 넣지 않는다.
- 버전/날짜/요약은 파일 헤더로 관리한다.

### 10.2 문서 변경 원칙
- 설계가 바뀌면 **삭제가 아니라 “현재 기준으로 재서술 + 기각 사유 기록”**을 한다.
- 문서의 상세(필드 설명/시나리오/결정 사유)는 축약하지 않는다.

---

## 11. 약어(Abbreviation) / Prefix 표준 (현황)

아래 표는 “현재까지의 약어 현황”이다. (표의 표기 방식은 추후 사용자 지침에 따라 조정될 수 있다.)

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

| 부서 | `departments` | `d` | `d_sn` |
| 품목(상품) | `goods` | `g` | `g_sn` |

| RFQ(견적요청) | `rfqs` | `rfq` | `rfq_sn` |
| RFQ 라인 | `rfq_lines` | `rfql` | `rfql_sn` |
| RFQ 배정(allocations) | `rfq_allocations` | `rfqa` | `rfqa_sn` |

| 발주서(PO) | `purchase_orders` | `po` | `po_sn` |
| 발주 라인 | `po_lines` | `pol` | `pol_sn` |
| 발주 배정(allocations) | `po_allocations` | `poa` | `poa_sn` |
| 발주-비용 연결 | `po_cost_links` | `pcl` | `pcl_sn` |

| 선적/배송(Shipment) | `shipments` | `sh` | `sh_sn` |
| 선적 라인 | `shipment_lines` | `shl` | `shl_sn` |
| 선적 마일스톤 | `shipment_milestones` | `sm` | `sm_sn` |
| 재고 단위 | `inventory_units` | `iu` | `iu_sn` |

| 납품 라인 | `delivery_lines` | `dvl` | `dvl_sn` |
| 납품 요청 | `delivery_requests` | `dr` | `dr_sn` |
| 납품 요청 라인 | `delivery_request_lines` | `drl` | `drl_sn` |
| 납품 요청 제안 | `delivery_request_proposals` | `drp` | `drp_sn` |

| 물류 작업(Job) | `logistics_jobs` | `lj` | `lj_sn` |
| 물류 작업 정차지(Stop) | `logistics_job_stops` | `ljs` | `ljs_sn` |
| 물류 작업 라인 | `logistics_job_lines` | `ljl` | `ljl_sn` |

| 제작 BOM 라인 | `inhouse_bom_lines` | `ibl` | `ibl_sn` |
| 제작 작업지시 | `inhouse_work_orders` | `iwo` | `iwo_sn` |

| 환율 | `fx_rates` | `fx` | `fx_sn` |
| 비용 환율 적용 | `cost_fx_applications` | `cfxa` | `cfxa_sn` |

| 인보이스 | `invoices` | `inv` | `inv_sn` |
| 인보이스 라인 | `invoice_lines` | `invl` | `invl_sn` |

| 거래처 수 계좌 | `bank_accounts` | `bk` | `bk_sn` |
| 지급대상(Payable) | `payables` | `pbl` | `pbl_sn` |
| 지급대상-비용 배정 | `payable_cost_allocations` | `pbca` | `pbca_sn` |
| 지급대상-인보이스 배정 | `payable_invoice_allocations` | `pbia` | `pbia_sn` |
| 지급-지급대상 배정 | `payment_payable_allocations` | `ppa` | `ppa_sn` |

| 활동 로그 | `activity_logs` | `al` | `al_sn` |
| 감사 변경 로그 | `audit_changes` | `ac` | `ac_sn` |

> 새 테이블 추가 시: “이미 사용 중인 약어”와 충돌하지 않게 정하고, 이 표를 업데이트한다.
