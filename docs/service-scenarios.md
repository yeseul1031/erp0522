# Balhea ERP Service Scenarios

> 목적: 이 문서는 DDL 컬럼 사전이 아니라, 실제 업무 이벤트별로 어떤 테이블에 어떤 주요 필드를 넣고 갱신해야 하는지 설명하는 시나리오 명세다.
> 테이블/컬럼/enum/제약의 정본은 항상 `docs/db/ddl/*.sql`이다.

---

## 0. 공통 원칙

### 0.1 신규 시스템 기준만 다룬다

이 문서는 Balhea ERP의 현재 설계 기준 사용 시나리오만 설명한다. 특정 배치 작업이나 외부 시스템 적재 편의를 위한 일회성 판단은 이 문서에 넣지 않는다.

### 0.2 생성/수정/삭제의 기본 기록 방식

- 생성: 본체 테이블의 `*_create_dt`, `*_update_dt`, 작성자/담당자 FK를 함께 기록한다.
- 수정: 업무적으로 의미 있는 값이 바뀌면 본체 `*_update_dt`를 갱신하고, 중요한 변경은 `activity_logs`와 필요 시 `audit_changes`에 남긴다.
- 삭제: 의존 데이터가 없고 초안 단계인 경우에만 물리 삭제를 고려한다. 운영 데이터는 기본적으로 상태 컬럼을 `CANCELLED`, `CANCEL`, `CLOSED` 등으로 변경해 이력을 보존한다.
- 문서/증빙: 파일 원본은 `documents`에 저장하고, 대상 연결은 `document_links`로만 한다.

### 0.3 담당자 표기

예시에서 사용하는 담당자는 다음 의미다.

- `contract_a_sn`: 계약/프로젝트 담당자
- `buyer_a_sn`: 수급/구매 담당자
- `finance_a_sn`: 재무 담당자
- `vendor_pt_sn`: 공급사 `parties.pt_sn`
- `customer_pt_sn`: 고객사 `parties.pt_sn`

실제 컬럼에는 DDL이 정의한 FK 컬럼명을 사용한다.

---

## 1. 프로젝트 생성과 변경

### 1.1 TENDER 프로젝트

입찰/공고 기반 프로젝트다. 계약 전 검토 단계로 시작할 수 있고, 낙찰/계약 체결 후 진행 상태로 전환한다.

#### 생성

`projects`

- `p_name`: 프로젝트명
- `p_type`: `TENDER`
- `p_customer_pt_sn`: 고객사. 미정이면 `NULL`
- `p_contract_no`: 계약 전이면 `NULL`
- `p_signed_at`: 계약 전이면 `NULL`
- `p_contract_amount`: 계약 전이면 `NULL`
- `p_ccy`: `KRW` 등
- `p_status`: `PRE_CONTRACT`
- `p_assign_status`: 입찰/담당 상태 코드. 예: `RR`, `RO`, `RC`, `BP`
- `p_a_sn`: 현재 프로젝트 담당자
- `p_delivery_dt`, `p_delivery_dt_str`: 납기 정보가 있으면 입력
- `p_default_sc_type`: 기본 수급 방식. 보통 `DOMESTIC`
- `p_create_dt`, `p_update_dt`

`orders`

- 프로젝트 생성 시 기본 주문서를 1건 만든다.
- `o_p_sn`: 생성한 `projects.p_sn`
- `o_name`: 기본 주문서명
- `o_a_sn`: 생성자
- `o_create_dt`, `o_update_dt`

`projects` 갱신

- `p_default_o_sn`: 생성한 `orders.o_sn`

`announce_links`가 필요한 경우

- `al_p_sn`: 프로젝트 PK
- `al_ba_sn`: 외부 공고 PK
- `al_ba_title`, `al_ba_announce_no`

#### 낙찰/계약 체결

`projects` update

- `p_status`: `ACTIVE`
- `p_contract_no`: 계약서 번호
- `p_signed_at`: 계약 체결일
- `p_contract_amount`: 계약 총액
- `p_assign_status`: 낙찰 후 담당 확인/완료에 맞는 코드
- `p_started_at`: 진행 시작일시
- `p_update_dt`

기록 권장

- `activity_logs.al_action_code`: `PROJECT_CONTRACT_ACTIVATED`
- `documents.doc_category`: `PROJECTS`
- `document_links.dl_target_type`: `PROJECTS`

#### 유찰/진행 중단

`projects` update

- `p_status`: `CANCELLED`
- `p_assign_status`: `DR`
- `p_ended_at`: 중단일시
- `p_update_dt`

하위 데이터가 이미 있으면 물리 삭제하지 않는다. 아직 수급/견적/발주가 없고 단순 입력 오류라면 물리 삭제를 별도 운영 권한으로 허용할 수 있다.

### 1.2 DIRECT 프로젝트

공고 없이 바로 계약/주문이 생기는 직접 계약이다.

#### 생성

`projects`

- `p_type`: `DIRECT`
- `p_status`: 계약이 확정되어 있으면 `ACTIVE`, 계약 전 검토면 `PRE_CONTRACT`
- `p_customer_pt_sn`, `p_contract_no`, `p_signed_at`, `p_contract_amount`
- `p_a_sn`, `p_default_sc_type`, `p_create_dt`, `p_update_dt`

`orders`

- 기본 주문서 1건 생성 후 `projects.p_default_o_sn`에 반영한다.

`announce_links`

- 생성하지 않는다.

#### 계약 조건 변경

계약 번호, 금액, 납기, 현장명, 계약자 등이 바뀌면 `projects`를 update한다.

- 금액/납기 변경이 이미 생성된 OL/SC/PO/cost에 영향을 주면 해당 하위 엔티티도 별도 업무 이벤트로 갱신한다.
- 단순 프로젝트 메타 변경만으로 기존 PO나 cost를 자동 변경하지 않는다.

### 1.3 FRAME 프로젝트

기간/다건 계약이다. 전체 계약 총량을 먼저 만들고, 실제 주문이 발생할 때 개별 `orders`와 `order_lines`를 릴리즈한다.

#### 총량 계약 생성

`projects`

- `p_type`: `FRAME`
- `p_status`: `ACTIVE`
- `p_contract_amount`, `p_signed_at`, `p_started_at`, `p_ended_at`
- `p_default_o_sn`: 기본 주문서

`blanket_order_lines`

- `bol_p_sn`: 프로젝트 PK
- `bol_no`
- `web_*`, `doc_*`, `final_*`: 총 계약 요구
- `bol_released_qty`: `0`
- `bol_status`: `OPEN`
- `bol_due_date`
- `bol_create_dt`, `bol_update_dt`

필요 시 `blanket_order_line_overrides`

- `bolo_bol_sn`
- `bolo_item_name`, `bolo_item_spec`, `bolo_item_qty`, `bolo_item_unit`
- `bolo_released_qty`: `0`
- `bolo_note`

#### 개별 주문 릴리즈

`orders`

- `o_p_sn`: FRAME 프로젝트
- `o_name`: 개별 주문명
- `o_a_sn`, `o_create_dt`, `o_update_dt`

`order_lines`

- `ol_bol_sn`: 참조하는 총량 라인
- `ol_o_sn`: 개별 주문서
- `final_item_qty`: 이번 주문 수량
- `ol_status`: `OPEN`

`blanket_order_lines` update

- `bol_released_qty`: 기존 릴리즈 수량 + 이번 `order_lines.final_item_qty`
- 총량을 초과하지 않도록 애플리케이션에서 검증한다.

### 1.4 프로젝트 담당자 변경

`projects` update

- `p_a_sn`: 신규 프로젝트 담당자
- `p_update_dt`

연동 규칙

- 아직 수급이 인수되지 않은 `sourcing_cases.sc_status='OPEN'`은 `sc_assignee_a_sn`이 `NULL`이다. 프로젝트 담당자 변경이 SC 소유권 이관을 의미한다면 `sc_owner_a_sn`을 새 프로젝트 담당자로 변경한다.
- `SELF_ASSIGNED`이고 `sc_owner_a_sn = sc_assignee_a_sn`이면 owner와 assignee를 함께 바꿀 수 있다.
- `ASSIGNEE_WORKING`은 협업 담당자가 실제 수행 중이므로 `sc_assignee_a_sn`을 자동 변경하지 않는다. owner 이관만 필요한지 별도 판단한다.

기록 권장

- `activity_logs.al_action_code`: `PROJECT_ASSIGNEE_CHANGED`
- 변경 전후 담당자는 `audit_changes` 또는 `al_data_json`에 기록한다.

### 1.5 프로젝트 종료

`projects` update

- `p_status`: `CLOSED`
- `p_ended_at`: 종료일시
- `p_update_dt`

종료 전 검증 권장

- 열려 있는 `order_lines.ol_status`가 없는지 확인
- 열려 있는 `sourcing_cases.sc_status`가 없는지 확인
- 진행 중인 `purchase_orders.po_status`가 없는지 확인한다. 현재 DDL에는 PO `CLOSED` 상태가 없으므로, 취소된 PO는 `CANCELLED`로 닫고 정상 완료된 PO는 관련 SCL/입출고/정산 완료 여부로 검증한다.
- 관련 cost/payable/payment가 미완료 상태로 남아 있지 않은지 확인

프로젝트 종료는 하위 엔티티를 자동 종료한다는 뜻이 아니다. 종료 버튼은 검증 후 프로젝트 상태를 닫는 업무 이벤트다.

---

## 2. 계약 라인: OL/OLO

### 2.1 단순 계약 라인

하나의 고객 요구가 하나의 계약 라인으로 충분한 경우다.

`order_lines`

- `ol_p_sn`: 프로젝트
- `ol_o_sn`: 주문서
- `ol_no`: 주문서 내 라인 번호
- `web_item_*`: 웹/사이트 기준 원문
- `doc_item_*`: 첨부/계약 문서 기준 원문
- `final_item_*`: 내부 검토 후 실행 기준
- `ol_req_dept`, `ol_order_dt`, `ol_delivery_place`
- `ol_status`: `OPEN`
- `ol_due_date`
- `ol_create_dt`, `ol_update_dt`

이 단계에서 `goods.g_sn`을 억지로 매핑하지 않는다. 실제 조달 대상은 SCL에서 정한다.

### 2.2 OL 여러 건

계약 문서의 행이 여러 개면 `order_lines`를 여러 건 생성한다.

각 OL은 독립적으로 수급 케이스를 가질 수 있다.

- OL A: `ol_no=1`, `final_item_name='본체'`
- OL B: `ol_no=2`, `final_item_name='모니터'`
- OL C: `ol_no=3`, `final_item_name='설치 용역'`

각 OL의 납기/장소/요청 부서가 다르면 `ol_due_date`, `ol_delivery_place`, `ol_req_dept`에 각각 기록한다.

### 2.3 하나의 OL을 OLO로 나누는 경우

하나의 고객 약속을 계약 담당자가 협업/위임/대외 고정 단위로 쪼갤 필요가 있을 때 사용한다.

예: `업무용 PC 세트 10SET`

`order_lines`

- `final_item_name`: `업무용 PC 세트`
- `final_item_qty`: `10`
- `final_item_unit`: `SET`
- `ol_status`: `OPEN`

`order_line_overrides`

- `olo_ol_sn`: 위 OL
- `olo_item_name`: `본체`
- `olo_item_qty`: `10`
- `olo_item_unit`: `EA`
- `olo_note`: `계약상 구성품 고정`

`order_line_overrides`

- `olo_item_name`: `모니터`
- `olo_item_qty`: `10`
- `olo_item_unit`: `EA`
- `olo_note`: `계약상 구성품 고정`

OLO는 실제 구매 품목의 정본이 아니다. 계약 담당자가 관리하는 세부 계약/위임 단위다. 실제 구매 품목, 대체품, 수량 조정은 SCL에서 기록한다.

### 2.4 OLO를 협업 위임 단위로 사용하는 경우

계약 담당자가 하나의 OL 중 일부를 다른 수급 담당자에게 맡기는 경우다.

흐름

1. 계약 담당자가 OL을 생성한다.
2. 필요한 경우 OLO를 여러 건 생성한다.
3. OLO별로 `sourcing_cases`를 생성한다.
4. 각 SC를 본인 인수하거나 협업 요청한다.

예시

- OL: `방송 장비 패키지 1식`
- OLO 1: `카메라 본체`, 계약 담당자 본인이 수급
- OLO 2: `오디오 장비`, 협업 담당자에게 요청
- OLO 3: `설치 용역`, 외주/용역 담당자에게 요청

`sourcing_cases`

- OLO 1용 SC: `sc_olo_sn=OLO1`, `sc_owner_a_sn=contract_a_sn`, `sc_assignee_a_sn=contract_a_sn`, `sc_status='SELF_ASSIGNED'`
- OLO 2용 SC: `sc_olo_sn=OLO2`, `sc_owner_a_sn=contract_a_sn`, `sc_assignee_a_sn=NULL`, `sc_requested_a_sn=buyer_a_sn`, `sc_status='ASSIGNING'`

### 2.5 OL 상태 변경

`OPEN`

- 계약 라인이 생성되었고 아직 실행 진행 전이다.
- SC/SCL 생성 가능.

`IN_PROGRESS`

- 관련 SC/SCL/RFQ/PO 중 하나 이상이 실행 중이다.
- 단순 문구 수정은 가능하지만, 수량/납기/계약 금액 변경은 하위 실행 영향 검토 후 변경한다.

`DELIVERED`

- 납품 완료 상태다.
- 이후 정정은 기존 라인을 되돌리기보다 별도 조정 라인이나 비용/환불/추가 납품 이벤트로 처리한다.

`CANCELLED`

- 계약 라인이 취소되었다.
- 이미 SC/SCL이 있으면 해당 수급도 `CANCELLED` 또는 새 정정 시나리오로 닫는다.
- 이미 PO/cost/payment가 있으면 재무 취소/환불 규칙을 따른다.

### 2.6 OLO 수정과 삭제

OLO에는 상태 컬럼을 두지 않는다. OLO는 독립 라이프사이클을 가진 실행 엔티티가 아니라 계약 담당자가 만든 계약/위임 세부 구조이므로, 상태는 하위 SC/SCL/RFQ/PO에서 관리한다.

- 연결된 SC가 없으면 OLO를 수정하거나 물리 삭제할 수 있다.
- 연결된 SC가 있으면 OLO는 삭제하지 않는다. FK와 업무 이력 관점에서 하위 실행의 근거로 남긴다.
- OLO를 더 이상 쓰지 않게 된 경우에는 연결된 SC/SCL을 `CANCELLED`로 닫고, 필요한 경우 새 OLO/SC를 만든다.
- OLO 자체에 `CANCELLED` 같은 상태를 추가하지 않는다. UI에서 활성/비활성을 구분해야 하면 연결된 SC/SCL 상태로 판단한다.

---

## 3. 수급: SC/SCL

### 3.1 SC 생성

OL 또는 OLO를 수급 실행으로 넘기는 시점에 `sourcing_cases`를 만든다.

`sourcing_cases`

- `sc_ol_sn`: 대상 OL
- `sc_olo_sn`: OLO 단위 수급이면 입력, OL 전체 수급이면 `NULL`
- `sc_required_qty`: 목표/참조 수량
- `sc_type`: `DOMESTIC`, `OVERSEAS`, `IN_HOUSE`
- `sc_assignee_a_sn`: `NULL`
- `sc_status`: `OPEN`
- `sc_owner_a_sn`: SC를 생성하고 소유한 구매/계약 담당자
- `sc_requested_a_sn`: `NULL`
- `sc_requested_at`, `sc_accepted_at`, `sc_rejected_at`: `NULL`
- `sc_note`
- `sc_create_dt`, `sc_update_dt`

`OPEN`은 담당자 미확정/대기 상태다. 아직 실제 수행 중인 상태가 아니다.

### 3.2 본인 인수

SC owner가 직접 처리하는 경우다.

`sourcing_cases` update

- `sc_assignee_a_sn`: `sc_owner_a_sn`
- `sc_status`: `SELF_ASSIGNED`
- `sc_requested_a_sn`: `NULL`
- `sc_requested_at`: `NULL`
- `sc_accepted_at`: 현재 시각 또는 `NULL` 정책 중 하나로 고정
- `sc_rejected_at`: `NULL`
- `sc_update_dt`

기록 권장

- `activity_logs.al_action_code`: `SOURCING_SELF_ASSIGNED`

### 3.3 협업 요청

owner가 다른 담당자에게 수급 수행을 요청하는 경우다.

`sourcing_cases` update

- `sc_requested_a_sn`: 요청 대상 담당자
- `sc_requested_at`: 요청 시각
- `sc_status`: `ASSIGNING`
- `sc_assignee_a_sn`: `NULL`. 실제 수행자는 아직 확정되지 않았다.
- `sc_update_dt`

기록 권장

- `activity_logs.al_action_code`: `SOURCING_ASSIGN_REQUESTED`

### 3.4 협업 수락

요청 대상이 수락하면 실제 수행 담당자가 바뀐다.

`sourcing_cases` update

- `sc_assignee_a_sn`: 수락한 담당자
- `sc_status`: `ASSIGNEE_WORKING`
- `sc_accepted_at`: 수락 시각
- `sc_rejected_at`: `NULL`
- `sc_update_dt`

`sc_owner_a_sn`은 바꾸지 않는다. owner는 이 SC를 생성하고 소유한 구매 담당자이고, assignee는 실제 수행자다.

### 3.5 협업 거절

요청 대상이 거절한 경우다.

`sourcing_cases` update

- `sc_status`: 일반적으로 `OPEN`
- `sc_rejected_at`: 거절 시각
- `sc_requested_a_sn`: 거절 대상 이력 보존을 위해 유지할 수 있다.
- `sc_assignee_a_sn`: `NULL`
- `sc_update_dt`

거절 이력은 `activity_logs`/`audit_changes`로 남긴다. 거절되었다고 기존 SC를 반드시 `CANCELLED`로 만들지는 않는다. 같은 SC에서 다시 요청할지, 새 SC를 만들지는 서비스 정책으로 결정한다.

### 3.6 협업 회수/취소

요청 중인 협업을 회수하는 경우다.

`sourcing_cases` update

- 요청 자체를 되돌려 대기열에 놓으려면 `sc_status='OPEN'`
- 해당 수급 케이스 자체를 폐기하려면 `sc_status='CANCELLED'`
- `sc_update_dt`

이미 협업자가 수락해 `ASSIGNEE_WORKING`인 경우에는 단순 회수보다 담당자 변경 이벤트로 처리한다.

### 3.7 SC 담당자/소유자 변경

퇴사, 조직 변경, 장기 부재처럼 업무 소유권을 이관하는 경우다.

`SELF_ASSIGNED`

- `sc_owner_a_sn`: 신규 담당자
- `sc_assignee_a_sn`: 신규 담당자
- `sc_status`: 유지

`ASSIGNEE_WORKING`

- owner 이관이면 `sc_owner_a_sn`만 변경한다.
- 수행자 이관이면 `sc_assignee_a_sn`을 변경한다.
- 둘은 서로 다른 업무 이벤트로 기록한다.

기록 권장

- `SOURCING_OWNER_CHANGED`
- `SOURCING_ASSIGNEE_CHANGED`

### 3.8 SCL 생성

수급 담당자가 실제 조달 대상을 확정하기 전/후로 `sourcing_case_lines`를 만든다.

`sourcing_case_lines`

- `scl_no`: SC 안의 라인 번호
- `scl_sc_sn`: SC
- `scl_ol_sn`: OL 전체를 커버하면 입력
- `scl_olo_sn`: OLO 단위 조달이면 입력
- `scl_line_type`: `FINISHED_GOOD`, `COMPONENT`, `CONSUMABLE`, `SERVICE`, `OUTSOURCED`, `FREIGHT`, `ADJUSTMENT`
- `scl_purpose_code`: `FULFILL_ORDER_LINE`, `UPGRADE_TO_MEET_SPEC`, `SUBSTITUTE`, `MANUFACTURING_INPUT`, `QUALITY_PROCESS`, `DELIVERY_SUPPORT`, `OTHER`
- `scl_status`: 최초 `DRAFT`, 조달 대상으로 확정하면 `CONFIRMED`
- `scl_g_sn`: 운영 중 goods가 확정되면 입력한다. SCL 생성 시점에는 `NULL`일 수 있다.
- `scl_item_name`: 비정형/임시 품목이면 입력
- `scl_item_qty`, `scl_uom_code`
- `scl_unit_price`: 견적 전 추정 단가
- `scl_need_by_dt`
- `scl_parent_scl_sn`: BOM/구성품 트리 필요 시
- `scl_note`
- `scl_create_dt`, `scl_update_dt`

권장 검증

- `scl_ol_sn` 또는 `scl_olo_sn` 중 하나는 채우는 것을 기본으로 한다.
- `scl_g_sn` 또는 `scl_item_name` 중 하나는 채운다.
- 현재 RFQ/PO는 물품 구매를 위한 흐름이다. `SERVICE`, `FREIGHT`, `OUTSOURCED` 같은 라인은 현재 범위에서는 RFQ/PO로 전개하지 않고, 추후 별도 실행 테이블을 설계한다.
- RFQ/PO로 전개하려면 해당 SCL에 `scl_g_sn`이 확정되어 있어야 한다.
- RFQ/PO 라인은 SCL을 유추하지 않고 allocation으로 연결한다.

### 3.9 SCL 상태 전이

`DRAFT`

- 수급 담당자가 검토 중이다.
- 자유롭게 수정/삭제 가능하다. 단, RFQ/PO 연결이 없을 때만.

`CONFIRMED`

- 조달 대상으로 확정되었다.
- 물품 구매 라인이고 `scl_g_sn`이 확정되면 RFQ/PO 대상으로 삼을 수 있다.

`QUOTING`

- `rfqs`, `rfq_lines`, `rfq_allocations`가 생성되어 견적 진행 중이다.

`ORDERING`

- PO 작성/승인 요청/승인 완료 대기 중이다.

`IN_PROGRESS`

- 제작/가공/수입/준비 등 실제 진행 중이다.

`RECEIVED`

- 입고/수령 완료 상태다.

`CANCELLED`

- 이 SCL은 더 이상 조달하지 않는다.
- 이미 RFQ/PO가 있으면 해당 하위 문서도 취소/종료한다.

`CLOSED`

- 조달과 정산이 운영상 닫힌 상태다.

---

## 4. 견적: RFQ

현재 DDL 기준으로 견적기안(`rfq_plans`) 계층은 없다. 견적 요청은 업체별 `rfqs`를 바로 만들고, 요청/응답 라인은 `rfq_lines`에 둔다.

### 4.1 업체별 RFQ 생성

같은 품목을 여러 업체에 비교 견적하려면 업체별로 `rfqs`를 각각 만든다. 현재 DDL 주석 기준으로 `DRAFT`는 예비 상태이고, 서비스 기획상 생성 시 바로 `SENT`로 만들 수 있다.

`rfqs`

- `rfq_name`: RFQ명/견적서명
- `rfq_pt_sn`: 견적 요청 대상 업체
- `rfq_a_sn`: 작성자
- `rfq_status`: 보통 `SENT`, 초안 보존이 필요하면 `DRAFT`
- `rfq_issued_at`: 발행/발송일시. `DRAFT`면 `NULL` 가능
- `rfq_req_pub_note`: 업체 전달용 요청 메모
- `rfq_res_pub_note`: 최초 `NULL`
- `rfq_note`: 내부 메모
- `rfq_create_dt`, `rfq_update_dt`

### 4.2 RFQ 라인 생성

`rfq_lines`

- `rfql_rfq_sn`
- `rfql_no`
- `rfql_g_sn`: 견적 대상 goods. 현재 RFQ는 goods가 확정된 물품 SCL만 대상으로 한다.
- `rfql_manufacturer_name`, `rfql_name`, `rfql_model_no`, `rfql_spec`, `rfql_coo`
- `rfql_req_name`, `rfql_req_model`, `rfql_req_manufacturer_name`, `rfql_req_spec_name`
- `rfql_req_qty`, `rfql_req_unit`, `rfql_req_note`
- `rfql_supply_type`: 회신 전이면 `NULL`
- `rfql_res_qty`: 회신 전 `0`
- `rfql_res_unit`: 회신 전 `''`
- `rfql_res_unit_price`: 회신 전 `0`
- `rfql_res_tax_price`: 회신 전 `0`
- `rfql_res_note`: 회신 전 `NULL`
- `rfql_create_dt`, `rfql_update_dt`

`rfq_lines`는 견적 요청 시점의 상품/요청 정보와 업체 응답 정보를 함께 보유한다. 견적은 계약 정본이 아니며, 최종 수량/단가/세금/통화/납기는 PO 라인에서 확정한다. 과거 특정 시점에 업체가 본 요청서를 재현해야 하면 RFQ 발송 문서/PDF를 `documents`로 저장하고 `document_links`로 `RFQS`에 연결한다.

### 4.3 RFQ 라인 배분

SCL과의 귀속은 `rfq_allocations`에 기록한다.

`rfq_allocations`

- `rfq_sn`: RFQ 조회 편의 캐시
- `rfql_sn`: RFQ 라인
- `sc_sn`: 수급 케이스 조회 편의 캐시
- `scl_sn`: 실행 라인 정본
- `p_sn`: 프로젝트 조회 캐시
- `rfqa_qty`: 이 RFQ 라인이 커버하는 SCL 기준 요청 수량
- `rfqa_note`
- `rfqa_create_dt`, `rfqa_update_dt`

한 RFQ 라인이 여러 SCL을 커버하면 allocation을 여러 건 만든다. 여러 RFQ 라인이 하나의 SCL에 대해 비교견적, 재견적, 취소 후 재시도처럼 여러 번 연결될 수도 있다. 중복 진행 방지는 DB 제약이 아니라 상태와 서비스 로직에서 검증한다.

### 4.4 RFQ 생성 이후 변경 규칙

허용

- 업체 회신 전 `rfq_lines` 요청 품목/규격/수량/단위 수정
- 업체 회신 전 `rfq_lines` 추가
- 발송 취소나 재견적이 필요한 경우 기존 RFQ를 보존하고 새 RFQ를 생성

주의

- 업체가 이미 응답한 뒤 요청 품목/규격/수량을 바꾸면, 그 응답이 어떤 요청 조건에 대한 응답이었는지 불명확해질 수 있다.
- 주요 요청값 변경은 추적성을 위해 `activity_logs`/`audit_changes`에 남긴다.
- 견적은 계약 정본이 아니므로 최종 구매 값은 `purchase_orders`와 `po_lines`에서 확정한다.

금지

- 업체가 회신한 `rfq_lines`를 잃게 만드는 수정
- 견적 이력을 삭제하고 최신 값만 남기는 방식의 정리

### 4.5 RFQ 상태 전이

`DRAFT`

- 아직 발송 전이다.
- 업체에게 발송되기 전이므로 RFQ 생성 동기화 범위 안에서 라인 조정이 가능하다.

`SENT`

- 업체에 발송했다.
- `rfq_issued_at` 입력.
- 관련 SCL은 `QUOTING`으로 전환할 수 있다.

`REPLIED`

- 업체가 회신했다.
- `rfq_replied_at` 입력.
- `rfq_lines`에 회신 수량/단가/세금/공급 가능 여부 입력.

`DECLINED`

- 업체가 견적을 거절했다.
- `rfq_res_pub_note` 또는 `rfq_note`에 사유 기록.

`CANCELLED`

- 발송 취소/견적 취소.
- 이미 업체 회신이 있으면 업무 이력으로 취소 사유를 남긴다.

`CLOSED`

- 비교/선정이 끝났거나 폐기되어 더 이상 사용하지 않는다.

### 4.6 업체 선택

선택한 업체와 RFQ가 정해지면 선택된 RFQ를 기반으로 PO를 만든다.

`purchase_orders`

- `po_source_rfq_sn`: 선택된 RFQ
- `po_vendor_pt_sn`: 선택 업체

선택되지 않은 RFQ는 비교/선정이 끝났으면 `CLOSED`로 닫는다. 별도의 `rfq_plans.rfqp_status='DONE'` 같은 선택 상태는 현재 DDL 기준으로 사용하지 않는다.

---

## 5. 발주: PO

### 5.1 RFQ 기반 PO 생성

`purchase_orders`

- `po_name`: 발주서명
- `po_vendor_pt_sn`: 선택 업체
- `po_a_sn`: 작성자
- `po_source_rfq_sn`: 근거 RFQ
- `po_status`: 최초 `DRAFT`
- `po_issued_at`: 작성/발행 기준일시. DRAFT에서도 시스템 정책상 입력
- `po_accepted_at`: 최초 `NULL`
- `po_expected_delivery_at`
- `po_payment_method`, `po_payment_terms`
- `po_tax_type`
- `po_ship_from_country`, `po_ship_to_country`
- `po_pub_note`, `po_priv_note`, `po_assignee_note`, `po_ceo_note`
- `po_delivery_terms`
- `po_nego_price`, `po_nego_reason`
- `po_valid_until_dt`
- `po_create_dt`, `po_update_dt`

`po_lines`

- `pol_po_sn`
- `pol_no`
- `g_sn`: 발주 대상 goods. 현재 PO는 goods가 확정된 물품 SCL만 대상으로 한다.
- `pol_manufacturer_name`, `pol_name`, `pol_model_no`, `pol_spec`, `pol_coo`
- `pol_qty`: 발주 수량. MOQ/샘플/여분 때문에 SCL 목표 수량과 다를 수 있다.
- `pol_unit`
- `pol_unit_price`, `pol_tax_price`, `pol_ccy`
- `pol_note`
- `pol_is_sample`
- `pol_sample_disposition`
- `source_rfql_sn`: RFQ 기반이면 입력
- `source_note`
- `pol_in_qty`: 최초 `NULL` 또는 `0`
- `pol_in_dt`: 최초 `NULL`
- `pol_create_dt`, `pol_update_dt`

`po_allocations`

- `po_sn`
- `pol_sn`
- `sc_sn`
- `scl_sn`
- `p_sn`
- `poa_qty`: 이 PO 라인이 커버하는 SCL 기준 수량
- `poa_out_qty`: 최초 `0`
- `poa_out_dt`: 최초 `NULL`
- `poa_delivery_dt`: 계약/발주 납기 기준
- `poa_note`
- `poa_create_dt`, `poa_update_dt`

`project_purchase_order_links`

- 프로젝트별 PO 조회 편의를 위해 생성한다.
- `ppol_p_sn`, `ppol_po_sn`

### 5.2 RFQ 없이 직접 PO 생성

긴급 구매나 이미 가격이 확정된 반복 구매처럼 RFQ 없이 PO를 만들 수 있다.

차이점

- `purchase_orders.po_source_rfq_sn`: `NULL`
- `po_lines.source_rfql_sn`: `NULL`
- `po_lines.source_note`: 구두견적/메일/기존 단가 등 근거 설명

그래도 `po_allocations`는 반드시 SCL 기준으로 생성한다. 직접 PO라고 해서 계약 라인이나 프로젝트에 직접 PO 라인을 붙이지 않는다.

직접 PO도 물품 발주 흐름이므로 `po_lines.g_sn`이 필요하다. SCL이 아직 자유 텍스트 상태라면 먼저 goods를 확정하거나 등록한 뒤 PO로 전개한다.

### 5.3 PO 특수 비용 라인

발주서 내부에 운송료, 포장비, 보험료, 통관 부대비 같은 특수 비용이 있으면 `po_cost_lines`를 만든다.

`po_cost_lines`

- `pocl_po_sn`
- `pocl_name`
- `pocl_cost`
- `pocl_tax`
- `pocl_tax_type`
- `pocl_note`
- `pocl_create_dt`, `pocl_update_dt`

PO 특수 비용 라인이 있으면 cost 생성 시 `po_cost_line_allocations`도 반드시 함께 만든다.

### 5.4 PO 상태 전이

`DRAFT`

- 구매 담당자 또는 수급 담당자가 내부 작성 중.
- 라인/금액/allocation 수정 가능.
- cost/payable/payment는 아직 만들지 않는 것이 기본이다.

`SENT`

- 작성자가 승인권자에게 발주 승인을 요청한 상태다.
- 승인 전 검토 대상이며 cost/payable/payment는 아직 만들지 않는 것이 기본이다.
- 관련 SCL은 `ORDERING`으로 전환 가능.

`ACCEPTED`

- 승인권자가 발주를 승인한 상태다.
- `po_accepted_at` 입력.
- 이 시점에 PO 비용 원장을 생성한다.

`REJECTED`

- 승인권자가 발주를 반려한 상태다.
- 기존 PO는 닫고, 필요하면 새 PO를 만든다.

`CANCELLED`

- 발주 취소.
- cost/payable/payment 생성 여부에 따라 재무 처리 방식이 달라진다.

### 5.5 PO 입고/출고 편의 필드

담당자가 자체적으로 입출고 현황을 관리하는 경우다.

입고 완료

- `po_lines.pol_in_qty`: 입고 수량
- `po_lines.pol_in_dt`: 입고일시

출고/납품 완료

- `po_allocations.poa_out_qty`: 출고 수량
- `po_allocations.poa_out_dt`: 출고일시
- `po_allocations.poa_delivery_dt`: 납품 기준일

정교한 물류/재고 흐름은 logistics DDL의 `inventory_units`, `shipments`, `logistics_jobs`를 사용한다. PO 편의 필드는 발주 담당자가 관리하는 간단한 현황 필드다.

---

## 6. 비용, 지급요청, 지급

### 6.0 AP/AR 도메인 경계

이 장의 시나리오는 DDL과 design-guide의 AP 3계층 정책을 전제로 한다.

공통 입력 원칙

- 지급 요청은 `payables.pbl_request_type='PAYMENT'`
- 환불/차감 확인 요청은 `payables.pbl_request_type='REFUND'`
- payment 생성 시 `pay_amount`는 처리 총액, `pay_credit_amount`는 그중 크레딧 처리분
- `pay_method`는 CARD/TRANSFER 처리 계열만 기록

AR 납품 정산(`receivables -> receipts`)과 전사 통합 입출금 원장은 이 장의 시나리오 범위가 아니다.

### 6.1 PO 비용 생성

PO가 승인되어 `purchase_orders.po_status='ACCEPTED'`가 되면 PO 비용을 만든다.

`costs`

- `ct_type`: `PO`
- `ct_kind`: `PO_COST`
- `ct_pt_sn`: 공급사
- `ct_occurred_at`: 비용 발생일시
- `ct_price`: PO 상품 금액 세전 합계
- `ct_tax`: PO 상품 세금 합계
- `ct_ccy`: PO 통화
- `ct_note`: 발주 비용 설명
- `ct_a_sn`: 등록자
- `ct_status`: `CREATE`
- `ct_parent_ct_sn`: `NULL`
- `ct_create_dt`, `ct_update_dt`

`po_cost_links`

- `po_sn`
- `ct_sn`
- `pcl_note`
- `pcl_create_dt`, `pcl_update_dt`

PO 1건은 cost 1건으로 연결한다. PO 내부 상품 비용의 프로젝트/수급 해석은 `po_allocations`를 통해 한다.

### 6.2 PO 특수 비용 배분

PO에 `po_cost_lines`가 있으면 각 비용 라인을 프로젝트에 배분한다.

`po_cost_line_allocations`

- `pcla_pocl_sn`: PO 특수 비용 라인
- `pcla_p_sn`: 프로젝트
- `pcla_po_sn`: PO
- `pcla_price`: 배분 세전 금액
- `pcla_tax`: 배분 세금
- `pcla_note`
- `pcla_create_dt`, `pcla_update_dt`

`po_cost_lines`를 등록했는데 `po_cost_line_allocations`가 없으면 정산 누락 위험이 있으므로 허용하지 않는다.

### 6.3 프로젝트 부대비용 생성

PO와 직접 연결되지 않는 배송비, 검수비, 현장 작업비, 일반 경비 등은 프로젝트 비용으로 기록한다.

`costs`

- `ct_type`: `PROJECT`
- `ct_kind`: `LOGISTICS`, `QUALITY_TEST`, `SITE_WORK`, `GENERAL_EXPENSE` 등
- `ct_pt_sn`
- `ct_occurred_at`
- `ct_price`, `ct_tax`, `ct_ccy`
- `ct_note`
- `ct_a_sn`
- `ct_status`: `CREATE`

`project_cost_allocations`

- `pca_ct_sn`
- `pca_p_sn`
- `pca_price`
- `pca_tax`
- `pca_note`
- `pca_create_dt`, `pca_update_dt`

배분 합계는 cost 원장 금액과 맞아야 한다.

### 6.4 카드 즉시 지급

카드는 승인 대기 흐름을 만들지 않는다. 이미 실제 카드 결제가 완료된 결과를 등록하는 것이므로 payable 없이 cost에서 payment로 바로 간다.

`payments`

- `pay_tx_type`: `PAYMENT`
- `pay_method`: `CARD`
- `pay_status`: `PROCESSED`
- `pay_pt_sn`: 지급 상대
- `pay_ct_sn`: cost PK
- `pay_pbl_sn`: `NULL`
- `pay_paid_at`: 지급 완료일시
- `pay_amount`: 처리 총 정산 금액
- `pay_credit_amount`: 보통 `0`
- `pay_ccy`
- `pay_ref_no`: 카드 승인번호 등
- `pay_note`
- `pay_data_json`
- `pay_a_sn`
- `pay_create_dt`, `pay_update_dt`

증빙

- 카드 승인 내역, 영수증, 구매명세서는 `documents`에 저장한다.
- `document_links.dl_target_type='PAYMENTS'`, `dl_target_sn=payments.pay_sn`

### 6.4.1 현금 비용 등록

현금 처리 흐름은 아직 서비스 기획 전이다. 따라서 현금은 현재 `payments`에 실제 정산 결과를 만들지 않고, 비용 발생 사실만 `costs`에 등록한다.

`costs`

- `ct_status`: `CREATE`
- `ct_price`, `ct_tax`, `ct_ccy`
- `ct_note`: 현금 비용 사유와 증빙 설명

현금영수증 등 증빙은 `documents`에 저장하고 `document_links`로 cost에 연결한다. 실제 현금 출납, 시재, 환급 처리 방식은 별도 기획 후 확장한다.

### 6.5 계좌이체 지급요청

계좌이체는 payable을 만든 뒤 payment로 집행한다.

`payables`

- `pbl_ct_sn`: 근거 cost
- `pbl_request_type`: `PAYMENT`
- `pbl_payee_pt_sn`: 지급 대상
- `pbl_bank_name`, `pbl_account_number`, `pbl_account_holder_name`: 지급 예정 계좌 스냅샷
- `pbl_status`: `CREATED`
- `pbl_requested_by_a_sn`: 요청자
- `pbl_responded_by_a_sn`: 최초 `NULL`
- `pbl_requested_at`
- `pbl_responded_at`: 최초 `NULL`
- `pbl_due_at`
- `pbl_ccy`
- `pbl_total_amount`
- `pbl_note`
- `pbl_create_dt`, `pbl_update_dt`

### 6.6 payable 승인/보류/반려/취소

승인

- `pbl_status`: `APPROVED`
- `pbl_responded_by_a_sn`: 승인자
- `pbl_responded_at`: 승인일시
- `pbl_update_dt`

정기결제/일괄결제 보류

- `pbl_status`: `ON_HOLD`
- 승인자는 정했지만 즉시 처리하지 않고, 나중에 모아서 처리할 대상으로 분리한 상태다.
- 요청 해석 보류가 아니라 승인 판단의 한 종류다.

반려

- `pbl_status`: `REJECTED`
- `pbl_note`: 반려 사유

취소

- `pbl_status`: `CANCELLED`
- `CREATED` 상태에서만 허용한다.
- `APPROVED`는 재무담당자가 언제든 오프라인 처리할 수 있는 실행 가능 상태이므로, payment row가 아직 없더라도 비용 발생 주체가 임의로 `CANCELLED`로 바꾸지 않는다.
- `ON_HOLD`도 승인/보류 업무 판단이 들어간 상태이므로 단순 취소로 되돌리지 않는다.
- `APPROVED` 또는 `ON_HOLD` 이후 취소 사유가 생기면 재무담당자가 실제 지급/환불 확인 여부를 먼저 확인하고, 협의/정정 근거를 남긴 뒤 예외적으로 처리한다.

상태별 취소 가능성

| 현재 상태 | `CANCELLED` 전환 | 처리 원칙 |
|---|---:|---|
| `CREATED` | 가능 | 아직 승인 전이므로 요청자가 취소 가능 |
| `APPROVED` | 비용 주체 금지 | 즉시 처리 가능 상태. 재무 확인/정정 이벤트 필요 |
| `ON_HOLD` | 비용 주체 금지 | 승인된 일괄/정기 처리 대상. 재무 확인/정정 이벤트 필요 |
| `PROCESSED` | 금지 | payment 보존, 환불/정정 흐름 사용 |
| `REJECTED` | 불필요 | 이미 반려된 상태 |
| `CANCELLED` | 불필요 | 이미 취소된 상태 |

### 6.7 계좌이체 지급 결과

승인된 payable을 지급 또는 크레딧 상계로 처리하면 payment를 만든다.

`payments`

- `pay_tx_type`: `PAYMENT`
- `pay_method`: `TRANSFER`
- `pay_status`: `PROCESSED`
- `pay_pt_sn`: 지급 상대
- `pay_bank_name`, `pay_account_number`, `pay_account_holder_name`: 실제 지급 계좌 스냅샷
- `pay_ct_sn`: cost PK
- `pay_pbl_sn`: payable PK
- `pay_paid_at`
- `pay_amount`: payable 처리 총액
- `pay_credit_amount`: 크레딧 상계 사용액. 크레딧을 사용하지 않으면 `0`
- `pay_ccy`
- `pay_ref_no`: 이체 거래번호
- `pay_note`
- `pay_a_sn`
- `pay_create_dt`, `pay_update_dt`

`payables` update

- `pbl_status`: `PROCESSED`
- `pbl_update_dt`

payable 1건은 payment 1건으로만 집행한다. 정산 처리 총액의 정본은 `payments.pay_amount`이고, 그중 크레딧 처리분은 `payments.pay_credit_amount`다.

예: 100만원 지급요청 중 30만원을 크레딧으로 상계하고 70만원을 계좌 처리하면 `pay_amount=1000000`, `pay_credit_amount=300000`, `pay_method='TRANSFER'`로 기록한다.

### 6.8 하나의 cost를 여러 번 나누어 이체

선금/중도금/잔금처럼 cost 하나를 여러 지급요청으로 나누는 경우다.

`costs`

- 총 비용 1건을 생성한다.

`payables`

- 선금 payable: `pbl_ct_sn=cost`, `pbl_total_amount=선금`
- 중도금 payable: `pbl_ct_sn=cost`, `pbl_total_amount=중도금`
- 잔금 payable: `pbl_ct_sn=cost`, `pbl_total_amount=잔금`

각 payable은 각자 승인되고, 각자 하나의 payment로 집행된다.

### 6.9 여러 cost를 한 번에 이체한 경우

현재 데이터 모델에서는 여러 cost를 payable 1건으로 묶지 않는다.

운영 입력

- cost별 payable을 각각 만든다.
- cost별 payment를 각각 만든다.
- 실제 은행 이체가 하나로 묶였다는 사실은 `pay_ref_no`, `pay_note`, `documents`로 공통 참조를 남길 수 있다.

나중에 하나의 은행 실행 이벤트를 여러 payment가 공유해야 하면, payment 바깥에 별도 지급 실행 계층을 추가로 설계한다.

### 6.10 AP 환불/취소/차감 공통 원칙

환불은 `receipts`에 넣지 않는다. `receipts`는 AR 납품 정산 도메인의 수금 이벤트이고, AP 환불은 cost 기반 정산의 반대 방향 결과다.

환불은 실제로 돈이 나갔거나 카드 승인이 잡힌 금액을 되돌려 받는 사건이다. 아직 지급되지 않은 payable을 줄이거나 취소하는 것은 환불이 아니라 지급요청 정정이다.

원 cost는 원 비용 발생 사실로 보존한다. 환불/차감은 별도 negative cost로 기록하고, 이 refund cost가 `ct_parent_ct_sn`으로 원 cost를 가리킨다. `ct_parent_ct_sn`은 자기참조 FK로 부모 cost의 존재를 보장한다. 원 cost의 환불 여부, 환불액, 순비용은 자식 refund cost 집계로 계산한다.

기본 판단 순서

1. 원 cost에 연결된 `payments(pay_tx_type='PAYMENT', pay_status='PROCESSED')`가 있는지 확인한다.
2. 실제 지급/카드승인이 없으면 refund payable/payment를 만들지 않고 cost/payable 정정으로 처리한다.
3. 실제 지급/카드승인이 있으면 환불 대상 금액만큼 negative refund cost를 만든다.
4. refund cost를 근거로 `payables(pbl_request_type='REFUND')`를 만든다.
5. 재무담당자가 카드취소나 계좌환불을 수동 확인한 뒤 `payments(pay_tx_type='REFUND')`를 만든다.

환불 cost

`costs`

- `ct_status`: `REFUND`
- `ct_parent_ct_sn`: 원 cost
- `ct_type`: 원 cost와 동일하게 둔다.
- `ct_kind`: 원 cost 성격을 따른다.
- `ct_price`, `ct_tax`: 음수. 부분 환불이면 환불 대상 금액만큼만 음수로 기록한다.
- `ct_note`: 환불 사유, 환불 범위, 원 지급/payment 참조

환불 확인 요청

`payables`

- `pbl_ct_sn`: refund cost
- `pbl_request_type`: `REFUND`
- `pbl_payee_pt_sn`: 환불/차감 확인 대상
- `pbl_bank_name`, `pbl_account_number`, `pbl_account_holder_name`: 필요 시 환불 출처/확인 참고 계좌 스냅샷
- `pbl_status`: 최초 `CREATED`, 승인 후 `APPROVED` 또는 `ON_HOLD`
- `pbl_total_amount`: 환불 확인 대상 금액. 양수로 저장한다.

환불/차감 처리 확인

`payments`

- `pay_tx_type`: `REFUND`
- `pay_method`: 원 지급과 같은 수단을 기본으로 한다. 카드 취소는 `CARD`, 계좌 환불은 `TRANSFER`.
- `pay_status`: `PROCESSED`
- `pay_pt_sn`: 환불/차감 상대
- `pay_bank_name`, `pay_account_number`, `pay_account_holder_name`: 필요 시 확인 계좌 스냅샷
- `pay_ct_sn`: refund cost
- `pay_pbl_sn`: refund payable
- `pay_paid_at`: 환불 확인일시
- `pay_amount`: 환불/차감 처리 총액
- `pay_credit_amount`: 환불금을 실제로 돌려받지 않고 크레딧으로 장부화한 금액. 실제 입금/카드취소로 처리하면 `0`
- `pay_ref_no`: 카드취소번호/환불거래번호 등

`payables` update

- `pbl_status`: `PROCESSED`
- `pbl_update_dt`

현금 환급은 아직 서비스 기획 전이므로 `payments`에 기록하지 않는다.

환불/차감 처리 방식

- 실제 계좌 입금 또는 카드취소로 처리: `pay_credit_amount=0`
- 돈을 받지 않고 향후 지급에서 차감할 크레딧으로 장부화: `pay_credit_amount=pay_amount`
- 일부는 실제 입금/카드취소, 일부는 크레딧 장부화: `0 < pay_credit_amount < pay_amount`

환불/정정 판단 표

| 원 cost 처리 단계 | 전체 취소/환불 | 부분 취소/환불 | refund payment 생성 |
|---|---|---|---|
| cost만 있음 | 원 cost를 `CANCEL`로 닫거나 금액을 정정 | 금액 수정 또는 이력 보존용 negative cost | 아니오 |
| payable `CREATED` | payable `CANCELLED`, 원 cost `CANCEL` | payable 취소 후 남길 금액으로 새 payable 생성 | 아니오 |
| payable `APPROVED`/`ON_HOLD` | 재무담당자가 지급 여부 확인 후 처리 | 재무담당자가 지급 여부 확인 후 처리 | 지급 전이면 아니오, 지급 후이면 예 |
| payment `PROCESSED` | negative refund cost + refund payable + refund payment | 환불 대상 금액만큼 negative refund cost + refund payable + refund payment | 예 |

`APPROVED` 또는 `ON_HOLD`는 재무담당자가 오프라인에서 언제든 처리할 수 있는 상태다. 비용 발생 주체는 이 상태의 payable을 임의로 `CANCELLED`로 바꾸지 않는다.

### 6.11 카드 지급 환불 시나리오

카드 지급은 원 지급 시 payable이 없다. 이미 실제 카드 결제가 완료된 결과를 등록하는 것이므로 `costs -> payments`로 바로 간다.

원 지급

- `costs`: 원 cost
- `payments`: `pay_tx_type='PAYMENT'`, `pay_method='CARD'`, `pay_ct_sn=원 cost`, `pay_pbl_sn=NULL`

카드 결제 전 cost만 등록된 경우

- 실제 카드 승인이 없으므로 환불이 아니다.
- 전체 무효는 원 cost를 `ct_status='CANCEL'`로 닫는다.
- 부분 정정은 하위 정산이 없으면 원 cost 금액을 수정한다.
- 이력을 보존해야 하면 별도 negative cost를 만들 수 있지만, refund payable/payment는 만들지 않는다.

전체 카드 취소

1. 원 cost와 원 payment는 보존한다.
2. 원 cost 금액 전체에 해당하는 negative refund cost를 만든다.
3. refund payable을 만든다.
4. 카드취소 확인 후 `payments(pay_tx_type='REFUND', pay_method='CARD')`를 만든다.
5. refund payable을 `PROCESSED`로 닫는다.

부분 카드 취소

- 전체 카드 취소와 동일하다.
- refund cost의 `ct_price`, `ct_tax`는 부분 취소 금액만큼만 음수로 기록한다.
- 원 cost와 원 payment는 부분 취소 때문에 수정하지 않는다.
- 카드 환불은 원칙적으로 카드취소 확인으로 처리하고 `pay_credit_amount=0`으로 둔다. 카드 환불분을 거래처 크레딧으로 장부화하는 운영은 별도 승인 정책이 있을 때만 허용한다.

### 6.12 계좌이체 지급 취소/환불 시나리오

계좌이체는 `costs -> payables(pbl_request_type='PAYMENT') -> payments(pay_tx_type='PAYMENT')` 흐름이다.

#### cost만 있고 payable이 없는 경우

아직 재무 처리 요청이 없으므로 환불이 아니다.

- 전체 무효: 원 cost를 `ct_status='CANCEL'`로 닫는다.
- 부분 정정: 하위 정산이 없으면 원 cost 금액을 수정한다. 이력 보존이 필요하면 원 cost를 유지하고 별도 negative cost를 만들 수 있지만, refund payable/payment는 만들지 않는다.

#### 전체 금액 payable이 `CREATED`인 경우

아직 승인 전이므로 요청자가 취소할 수 있다.

- 전체 무효: payment payable을 `CANCELLED`로 닫고 원 cost를 `CANCEL`로 닫는다.
- 부분 정정: 기존 payment payable을 `CANCELLED`로 닫고, 남겨야 할 금액 기준으로 새 payment payable을 만든다. 실제 지급이 없으므로 refund payable/payment는 만들지 않는다.

#### 전체 금액 payable이 `APPROVED` 또는 `ON_HOLD`인 경우

비용 발생 주체가 임의로 취소할 수 없다. 재무담당자가 오프라인 지급 여부를 먼저 확인한다.

- 지급 전임이 확인됨: 재무담당자가 payment payable을 `CANCELLED` 또는 `REJECTED`로 닫고, cost는 전체/부분 정정 원칙에 따라 `CANCEL`, 금액 수정, 새 payable 생성 중 하나로 처리한다.
- 지급 여부가 불확실하거나 이미 지급됨: 먼저 원 지급 payment를 정확히 기록한 뒤 payment 완료 후 환불 시나리오를 따른다.

#### 전체 금액 payment까지 `PROCESSED`된 경우

실제 돈이 나갔으므로 환불 시나리오다.

- 전체 환불: 원 cost 금액 전체에 해당하는 negative refund cost를 만들고, refund payable을 만든 뒤, 계좌 환불 확인 또는 크레딧 장부화 후 `payments(pay_tx_type='REFUND', pay_method='TRANSFER')`를 만든다.
- 부분 환불: 환불/차감 대상 금액만큼 negative refund cost를 만들고 동일하게 refund payable/payment를 만든다.
- 계좌 환불을 실제로 받으면 `pay_credit_amount=0`이다. 돈을 받지 않고 향후 지급에서 차감하기로 하면 `pay_credit_amount=pay_amount`로 기록하고, 거래처 크레딧 잔액을 증가시킨다.

#### 일부 금액만 payable로 등록된 경우

원 cost 100 중 40만 payable로 등록된 예를 기준으로 한다.

- 40 payable이 `CREATED`: unpaid 요청 정정이다. 기존 payable을 취소하고 필요한 금액으로 새 payable을 만든다. refund payment는 만들지 않는다.
- 40 payable이 `APPROVED` 또는 `ON_HOLD`: 재무담당자가 실제 지급 여부를 먼저 확인한다. 지급 전이면 정정, 지급 후이면 환불 시나리오다.
- 40 payable이 `PROCESSED`되어 payment가 있음: 이미 지급된 40 범위 안에서 환불이 발생하면 refund cost/payable/payment를 만든다. 아직 payable로 등록되지 않은 나머지 60은 지급요청을 새로 만들지 않거나 줄이는 것으로 정리한다.

#### 일부 금액만 payment까지 처리된 경우

원 cost 100 중 40만 payment가 있고 60이 미처리인 경우다.

- 환불 대상이 이미 지급된 40 안에 있으면 refund cost/payable/payment를 만든다.
- 환불 또는 차감 대상이 아직 지급되지 않은 60에만 해당하면 새 환불 payment를 만들지 않는다. 남은 payable을 만들지 않거나, 이미 열린 payable이 있으면 취소/수정한다.
- 지급된 금액 일부와 미지급 금액 일부가 함께 줄어들면 지급된 부분만 refund cost/payable/payment로 처리하고, 미지급 부분은 payable 정정으로 처리한다.

### 6.13 PROJECT cost와 PO cost의 환불 귀속

환불 처리의 AP 흐름은 `ct_type='PROJECT'`와 `ct_type='PO'`가 동일하다. 차이는 환불 cost의 귀속 해석이다.

PROJECT cost 환불

- refund cost의 `ct_type`: `PROJECT`
- `ct_parent_ct_sn`: 원 PROJECT cost
- 환불 금액이 프로젝트 비용 집계에서 빠져야 하므로 `project_cost_allocations`에도 음수 배분을 만든다.
- 부분 환불이면 환불 대상 프로젝트/금액만큼만 음수 배분한다.

PO cost 환불

- refund cost의 `ct_type`: `PO`
- `ct_parent_ct_sn`: 원 PO cost
- refund cost는 같은 PO에 대해 별도 `po_cost_links`를 만들지 않는다.
- PO 귀속은 `refund cost -> ct_parent_ct_sn -> 원 PO cost -> po_cost_links`로 해석한다.
- PO 내부 상품 비용 귀속은 원 PO의 `po_allocations`를 기준으로 해석한다.
- PO 특수 비용 라인 환불은 원 `po_cost_line_allocations`를 기준으로 해석한다.

PO cost에서 특정 라인, 특정 프로젝트, 특정 특수 비용만 환불되는 경우에는 현재 스키마에 별도 refund allocation 테이블을 추가하지 않는다. 운영상 필요한 상세 범위는 refund cost의 `ct_note`, 증빙 문서, 원 PO/라인 참조로 남긴다. 추후 정산 자동화에 이 정보가 부족하면 별도 refund allocation 설계를 검토한다.

### 6.14 부분환불 금액과 세금계산서 대사

`payments.pay_amount`는 실제 현금 이동액이 아니라 payment가 처리한 총 정산 금액이다. `pay_credit_amount`는 그중 크레딧으로 처리한 금액이다. 세전/세금 분리는 `payments`에 넣지 않는다.

세금 구조의 정본

- `costs.ct_price`, `costs.ct_tax`
- `tax_invoices.ti_supply_amount`, `tax_invoices.ti_tax_amount`, `tax_invoices.ti_total_amount`

세금계산서 지급 대사

- 세금계산서 총액은 `tax_invoices.ti_total_amount`다.
- 정산 처리 총액은 `payments.pay_amount`다.
- 세금계산서와 payment의 매칭 금액은 `tax_invoice_payment_allocations.tipa_amount`다.
- `pay_tx_type='PAYMENT'`는 양수 방향, `pay_tx_type='REFUND'`는 음수 방향으로 합산해 대사한다.

부분환불 계산 값

- 원 비용 총액: `original.ct_price + original.ct_tax`
- 환불 결정액: 자식 refund cost 합계의 절대값
- 환불 확인액: refund payment 합계
- 순 비용: 원 cost 총액 + 자식 refund cost 합계
- 순 지급액: PAYMENT payment 합계 - REFUND payment 합계
- 크레딧 잔액 증가: REFUND payment의 `pay_credit_amount`
- 크레딧 잔액 감소: PAYMENT payment의 `pay_credit_amount`

이 값들은 별도 잔액 필드에 중복 저장하지 않고 조회/검증 로직으로 계산한다.

검증 규칙

- 자식 refund cost 합계 절대값은 원 cost 총액을 넘으면 안 된다.
- refund payment 합계는 refund payable 금액을 넘으면 안 된다.
- refund payment 합계는 해당 refund cost 절대금액을 넘으면 안 된다.
- 원 지급 payment의 처리 총액보다 더 많이 환불 처리하면 안 된다.
- `pay_credit_amount`는 `pay_amount`보다 클 수 없다.

### 6.15 거래처 크레딧 잔액과 상계 시나리오

거래처 크레딧 잔액은 환불금을 실제로 받지 않고 향후 지급에서 차감하기로 한 금액의 현재 잔액이다.

정본은 `payments`다.

- REFUND payment의 `pay_credit_amount`: 잔액 증가
- PAYMENT payment의 `pay_credit_amount`: 잔액 감소

`party_credit_balances`는 현재 잔액 조회를 위한 캐시다.

`party_credit_balances`

- `pcb_pt_sn`: 거래처
- `pcb_ccy`: 통화. 현재 정책은 거래처별 1개 통화만 허용한다.
- `pcb_balance_amount`: 현재 크레딧 잔액 캐시
- `pcb_recalculated_at`: payments 집계 기준 마지막 재계산 시각

운영 규칙

- payment 생성/취소 시 balance를 같이 갱신한다.
- 불일치하면 `payments` 집계가 정본이고 balance를 재계산한다.
- 신규 payment의 `pay_ccy`가 기존 `pcb_ccy`와 다르면 크레딧 적립/상계를 막는다.
- 현재는 거래처별 다통화 크레딧 잔액을 허용하지 않는다.
- `pcb_balance_amount`는 현재 잔액이므로 항상 0 이상이어야 한다. 증가/감소는 변화량으로 설명하고, 필드값은 차감/가산 후 현재 잔액으로 기록한다.

#### 80만원 환불을 전액 계좌로 받음

`payables`

- `pbl_request_type`: `REFUND`
- `pbl_total_amount`: `800000`

`payments`

- `pay_tx_type`: `REFUND`
- `pay_method`: `TRANSFER`
- `pay_amount`: `800000`
- `pay_credit_amount`: `0`

`party_credit_balances`

- 변화 없음

#### 80만원 환불을 전액 크레딧으로 장부화

`payables`

- `pbl_request_type`: `REFUND`
- `pbl_total_amount`: `800000`

`payments`

- `pay_tx_type`: `REFUND`
- `pay_method`: `TRANSFER`
- `pay_amount`: `800000`
- `pay_credit_amount`: `800000`

`party_credit_balances`

- 기존 잔액에 `800000`을 더한다.
- 반영 후 `pcb_balance_amount`: 기존 잔액 + `800000`

#### 80만원 환불 중 30만원은 계좌로 받고 50만원은 크레딧으로 장부화

`payments`

- `pay_tx_type`: `REFUND`
- `pay_method`: `TRANSFER`
- `pay_amount`: `800000`
- `pay_credit_amount`: `500000`

`party_credit_balances`

- 기존 잔액에 `500000`을 더한다.
- 반영 후 `pcb_balance_amount`: 기존 잔액 + `500000`

#### 100만원 지급요청을 전액 계좌로 지급

`payables`

- `pbl_request_type`: `PAYMENT`
- `pbl_total_amount`: `1000000`

`payments`

- `pay_tx_type`: `PAYMENT`
- `pay_method`: `TRANSFER`
- `pay_amount`: `1000000`
- `pay_credit_amount`: `0`

`party_credit_balances`

- 변화 없음

#### 100만원 지급요청 중 80만원은 기존 크레딧으로 상계하고 나머지만 지급

전제: 같은 거래처, 같은 통화의 `party_credit_balances.pcb_balance_amount`가 `800000` 이상이어야 한다.

`payables`

- `pbl_request_type`: `PAYMENT`
- `pbl_total_amount`: `1000000`

`payments`

- `pay_tx_type`: `PAYMENT`
- `pay_method`: `TRANSFER`
- `pay_amount`: `1000000`
- `pay_credit_amount`: `800000`

`party_credit_balances`

- 기존 잔액에서 `800000`을 차감한다.
- 반영 후 `pcb_balance_amount`: 기존 잔액 - `800000`
- 반영 후 `pcb_balance_amount`는 `0` 이상이어야 한다.

#### 100만원 지급요청을 전액 크레딧으로 상계

전제: 같은 거래처, 같은 통화의 `party_credit_balances.pcb_balance_amount`가 `1000000` 이상이어야 한다.

`payments`

- `pay_tx_type`: `PAYMENT`
- `pay_method`: `TRANSFER`
- `pay_amount`: `1000000`
- `pay_credit_amount`: `1000000`

`party_credit_balances`

- 기존 잔액에서 `1000000`을 차감한다.
- 반영 후 `pcb_balance_amount`: 기존 잔액 - `1000000`
- 반영 후 `pcb_balance_amount`는 `0` 이상이어야 한다.

크레딧을 전액 사용하더라도 `pay_method`는 `CARD`/`TRANSFER` 처리 계열을 유지한다. 크레딧 사용 여부는 `pay_method`가 아니라 `pay_credit_amount`로만 표현한다.

검증 규칙

- `pay_amount = payables.pbl_total_amount`
- `0 <= pay_credit_amount <= pay_amount`
- PAYMENT payment에서 `pay_credit_amount`를 쓰려면 같은 거래처, 같은 통화의 크레딧 잔액이 충분해야 한다.
- REFUND payment의 `pay_credit_amount`는 거래처 크레딧 잔액을 증가시킨다.
- PAYMENT payment의 `pay_credit_amount`는 거래처 크레딧 잔액을 감소시킨다.

---

## 7. PO 수정/취소와 재무 영향

### 7.1 DRAFT PO 수정

아직 승인 요청 전이다.

수정 가능

- `purchase_orders` 헤더 정보
- `po_lines`
- `po_allocations`
- `po_cost_lines`

재무 처리

- cost/payable/payment는 생성하지 않는 것이 기본이므로 재무 변경은 없다.

### 7.2 SENT/ACCEPTED PO 수정

승인 요청 중이거나 승인 완료된 PO다.

경미한 내부 메모 수정

- `po_priv_note`, `po_assignee_note`, `po_ceo_note`
- `po_update_dt`

금액/수량/납기/공급사에 영향을 주는 수정

- 기존 PO를 직접 덮어쓸지, 취소 후 새 PO를 만들지는 업무 정책으로 결정한다.
- 이미 cost가 생성되었으면 단순 덮어쓰기 금지. cost 정정 시나리오를 따른다.

### 7.3 cost 생성 전 PO 취소

`purchase_orders` update

- `po_status`: `CANCELLED`
- `po_update_dt`

`sourcing_case_lines` update

- 해당 PO만 취소되고 다른 수급이 필요하면 `CONFIRMED` 또는 `ORDERING` 상태로 되돌린다.
- 수급 자체도 폐기되면 `CANCELLED`

재무 처리

- cost/payable/payment가 없으므로 재무 row는 만들지 않는다.

### 7.4 cost 생성 후 payable 전 PO 취소

`purchase_orders`

- `po_status`: `CANCELLED`

`costs`

- 기존 cost를 무의미하게 삭제하지 않는다.
- 업무적으로 비용 발생이 무효라면 `ct_status='CANCEL'`로 변경한다.
- 이미 일부 비용이 실제 발생했으면 기존 cost는 유지하고, 환불/차감 cost를 별도 생성한다.

`po_cost_links`

- 기존 연결은 보존한다.

### 7.5 payable 생성 후 payment 전 PO 취소

`purchase_orders`

- `po_status`: `CANCELLED`

`payables`가 `CREATED`인 경우

- `pbl_status='CANCELLED'`로 닫을 수 있다.
- 반려 성격이면 `REJECTED`를 사용할 수 있다.

`costs`

- 실제 비용 발생이 무효면 `ct_status='CANCEL'`
- 일부 비용이 발생했으면 `CREATE` 유지 후 차감/환불 비용을 별도 기록

`payables`가 `APPROVED` 또는 `ON_HOLD`인 경우

- payment row가 아직 없더라도 시스템이 자동으로 `CANCELLED`로 바꾸지 않는다.
- 재무담당자가 오프라인 처리 여부를 먼저 확인한다.
- 실제 지급 전임이 확인되면 정정/반려/보류 해제 등 별도 업무 이벤트로 처리하고 로그를 남긴다.
- 이미 지급되었거나 지급 여부가 불확실하면 payment 완료 후 취소/환불 시나리오를 따른다.

### 7.6 payment 완료 후 PO 취소/환불

돈이 이미 나갔으므로 기존 payment를 조용히 삭제하거나 단순 취소로 덮지 않는다.

`payments`

- 기존 payment는 원 지급 처리 사실로 보존한다.
- 잘못 등록한 payment 자체를 무효화하는 경우에만 `pay_status='CANCELLED'`를 사용한다.
- 업무상 환불/차감은 기존 payment를 취소로 덮지 않고, 별도 refund cost/payable/payment로 기록한다.

`costs`

- 환불/차감 금액을 새 cost로 생성한다.
- `ct_status`: `REFUND`
- `ct_parent_ct_sn`: 원 cost
- `ct_price`, `ct_tax`: 음수 환불/차감 금액
- `ct_note`: 환불 사유

`payables`

- `pbl_request_type`: `REFUND`
- `pbl_status`: `CREATED`, 승인 후 `APPROVED` 또는 `ON_HOLD`
- 재무담당자가 실제 환불 또는 크레딧 장부화 여부를 확인할 업무 큐 역할을 한다.

환불 확인 후 `payments`

- `pay_tx_type`: `REFUND`
- `pay_status`: `PROCESSED`
- `pay_amount`: 환불/차감 처리 총액
- `pay_credit_amount`: 크레딧으로 장부화한 금액. 실제 입금/카드취소로 처리하면 `0`
- `pay_paid_at`: 환불 확인일시
- `pay_ref_no`: 카드취소번호/환불거래번호 등

이후 refund payable은 `pbl_status='PROCESSED'`로 닫는다. 환불/차감 처리 총액은 `payments.pay_amount`이고, 크레딧 장부화 금액은 `payments.pay_credit_amount`다.

---

## 8. 대표 End-to-End 시나리오

### 8.1 TENDER 단일 품목 국내 구매, 카드 결제

1. `projects`: `p_type='TENDER'`, `p_status='PRE_CONTRACT'`
2. 낙찰 후 `projects`: `p_status='ACTIVE'`
3. `orders`: 기본 주문서
4. `order_lines`: `final_item_name='드라이버'`, `final_item_qty=10`, `ol_status='OPEN'`
5. `sourcing_cases`: `sc_type='DOMESTIC'`, `sc_status='SELF_ASSIGNED'`
6. `sourcing_case_lines`: `scl_line_type='FINISHED_GOOD'`, `scl_purpose_code='FULFILL_ORDER_LINE'`, `scl_status='CONFIRMED'`
7. 업체별 `rfqs`, `rfq_lines`, `rfq_allocations`
8. 선택된 RFQ를 근거로 `purchase_orders`: `po_source_rfq_sn=선택 RFQ`, 최초 `po_status='DRAFT'`
9. `po_lines`, `po_allocations`
10. 승인 요청 후 `purchase_orders`: `po_status='SENT'`
11. 승인 완료 후 `purchase_orders`: `po_status='ACCEPTED'`
12. `costs`: `ct_type='PO'`, `ct_kind='PO_COST'`
13. `po_cost_links`
14. `payments`: `pay_method='CARD'`, `pay_ct_sn=cost`, `pay_pbl_sn=NULL`
15. `documents` + `document_links`: 카드 승인, 구매명세서, PO 문서

### 8.2 DIRECT 프로젝트, RFQ 없이 직접 PO, 계좌이체

1. `projects`: `p_type='DIRECT'`, `p_status='ACTIVE'`
2. `orders`, `order_lines`
3. `sourcing_cases`: `SELF_ASSIGNED` 또는 `ASSIGNEE_WORKING`
4. `sourcing_case_lines`: `CONFIRMED`
5. `purchase_orders`: `po_source_rfq_sn=NULL`, 최초 `po_status='DRAFT'`
6. `po_lines`: `source_rfql_sn=NULL`, `source_note='기존 단가표 기준'`
7. `po_allocations`
8. 승인 요청 후 `purchase_orders`: `po_status='SENT'`
9. 승인 완료 후 `purchase_orders`: `po_status='ACCEPTED'`
10. `costs`: `ct_type='PO'`, `ct_kind='PO_COST'`
11. `po_cost_links`
12. `payables`: `pbl_request_type='PAYMENT'`, `pbl_status='CREATED'`
13. 승인 후 `payables`: `APPROVED`
14. `payments`: `pay_tx_type='PAYMENT'`, `pay_method='TRANSFER'`, `pay_status='PROCESSED'`, `pay_pbl_sn=payable`
15. `payables`: `PROCESSED`로 갱신

### 8.3 FRAME 계약 총량에서 개별 주문 릴리즈

1. `projects`: `p_type='FRAME'`, `p_status='ACTIVE'`
2. `blanket_order_lines`: 총 계약 수량
3. 고객의 1차 주문 발생
4. `orders`: 1차 주문서
5. `order_lines`: `ol_bol_sn=blanket_order_lines.bol_sn`
6. `blanket_order_lines.bol_released_qty` 증가
7. 이후 OL/OLO/SC/SCL/RFQ/PO/재무 흐름은 일반 주문과 동일

### 8.4 OL 하나를 OLO 여러 건으로 나누어 협업 수급

1. `order_lines`: `final_item_name='PC 세트'`
2. `order_line_overrides`: `본체`, `모니터`, `설치`
3. 본체 OLO용 `sourcing_cases`: `SELF_ASSIGNED`
4. 모니터 OLO용 `sourcing_cases`: `ASSIGNING`
5. 협업 수락 후 모니터 SC: `ASSIGNEE_WORKING`
6. 각 SC 아래 `sourcing_case_lines` 생성
7. 각 담당자가 자기 SC/SCL 범위 안에서 RFQ/PO 진행
8. cost는 PO면 `PO`, 기타 부대비용이면 `PROJECT`로 생성

### 8.5 해외 구매와 환율 스냅샷

1. `sourcing_cases`: `sc_type='OVERSEAS'`
2. `sourcing_case_lines`: 해외 구매 대상
3. `purchase_orders`: `po_ship_from_country`, `po_ship_to_country`, `po_payment_terms`
4. `po_lines`: `pol_ccy='USD'`
5. `costs`: `ct_ccy='USD'`
6. `fx_rates`: 환율 스냅샷
7. `cost_fx_applications`: `ct_sn`, `fx_sn`, `cfxa_policy_code`, `cfxa_applied_dt`
8. 지급은 카드면 payment 직접, 이체면 payable 후 payment, 현금이면 현재 costs 등록까지만 진행

### 8.6 프로젝트 부대비용 카드 결제

1. `costs`: `ct_type='PROJECT'`, `ct_kind='LOGISTICS'` 또는 적절한 cost kind
2. `project_cost_allocations`: 프로젝트 배분
3. `payments`: `pay_method='CARD'`, `pay_ct_sn=cost`
4. `documents`: 카드 승인/영수증
5. `document_links`: `PAYMENTS` 및 필요 시 `COSTS`에도 연결

---

## 9. 문서/증빙 연결 시나리오

### 9.1 프로젝트/계약 문서

`documents`

- `doc_category`: `PROJECTS`
- `doc_file_key`, `doc_file_name`, `doc_mime_type`
- `doc_note`
- `doc_created_by_a_sn`

`document_links`

- `dl_target_type`: `PROJECTS`
- `dl_target_sn`: `projects.p_sn`
- `dl_link_role`: `EVIDENCE` 또는 `REFERENCE`

### 9.2 OL/OLO 근거 문서

`documents.doc_category`

- `ORDER_LINES` 또는 `ORDER_LINE_OVERRIDES`

`document_links.dl_target_type`

- `ORDER_LINES` 또는 `ORDER_LINE_OVERRIDES`

웹 기준, 문서 기준, 최종 검토 기준이 서로 다를 수 있으므로 문서 원본은 가능하면 OL/OLO에 연결한다.

### 9.3 RFQ/PO 문서

RFQ 요청서/회신서

- `doc_category`: `RFQS`
- `dl_target_type`: `RFQS`
- `dl_link_role`: `REQUEST`, `EVIDENCE`, `REFERENCE`

PO 문서

- `doc_category`: `PURCHASE_ORDERS`
- `dl_target_type`: `PURCHASE_ORDERS`
- `dl_link_role`: `REQUEST` 또는 `EVIDENCE`

### 9.4 비용/지급 증빙

거래명세서, 세금계산서, 통관서류

- `doc_category`: `COSTS`
- `dl_target_type`: `COSTS`
- `dl_target_sn`: `costs.ct_sn`

카드 승인, 이체 확인

- `doc_category`: `PAYMENTS`
- `dl_target_type`: `PAYMENTS`
- `dl_target_sn`: `payments.pay_sn`

현금영수증

- `doc_category`: `COSTS`
- `dl_target_type`: `COSTS`
- `dl_target_sn`: `costs.ct_sn`

계좌이체 요청서/승인 근거

- `doc_category`: `PAYABLES`
- `dl_target_type`: `PAYABLES`
- `dl_target_sn`: `payables.pbl_sn`

동일 문서가 cost와 payment 양쪽 근거가 되면 `documents`는 1건만 만들고 `document_links`를 여러 건 만든다.

---

## 10. 상태 전이 빠른 표

### 10.1 Project

| 상태 | 의미 | 주요 전이 |
|---|---|---|
| `PRE_CONTRACT` | 계약 전/입찰 검토 | 생성, 입찰 진행 |
| `ACTIVE` | 진행 | 계약 체결, 직접 계약 시작 |
| `CLOSED` | 종료 | 납품/정산 완료 후 |
| `CANCELLED` | 취소 | 유찰, 계약 취소, 진행 중단 |

### 10.2 Order Line

| 상태 | 의미 | 주요 전이 |
|---|---|---|
| `OPEN` | 생성/대기 | SC 생성 가능 |
| `IN_PROGRESS` | 수급/발주/납품 진행 | SC/RFQ/PO 진행 중 |
| `DELIVERED` | 납품 완료 | 배송/납품 완료 후 |
| `CANCELLED` | 취소 | 하위 실행 취소 필요 |

### 10.3 Sourcing Case

| 상태 | 의미 | 주요 필드 |
|---|---|---|
| `OPEN` | 담당자 미확정 | `sc_owner_a_sn`, `sc_assignee_a_sn` |
| `SELF_ASSIGNED` | owner가 직접 수행 | `sc_assignee_a_sn=sc_owner_a_sn` |
| `ASSIGNING` | 협업 요청 중 | `sc_requested_a_sn`, `sc_requested_at` |
| `ASSIGNEE_WORKING` | 협업자가 수행 중 | `sc_assignee_a_sn`, `sc_accepted_at` |
| `CANCELLED` | 취소 | 취소 사유 기록 |
| `DONE` | 수행 완료 | 사람이 수동 종료 |

### 10.4 Sourcing Case Line

| 상태 | 의미 |
|---|---|
| `DRAFT` | 수급 검토 중 |
| `CONFIRMED` | 조달 대상으로 확정 |
| `QUOTING` | 견적 진행 중 |
| `ORDERING` | 발주 진행 중 |
| `IN_PROGRESS` | 제작/가공/수입/준비 진행 |
| `RECEIVED` | 입고/수령 완료 |
| `CANCELLED` | 조달 대상에서 제외 |
| `CLOSED` | 운영상 종료 |

### 10.5 RFQ / PO / Finance

| 엔티티 | 주요 상태 | 처리 원칙 |
|---|---|---|
| `rfqs` | `DRAFT`, `SENT`, `REPLIED`, `DECLINED`, `CANCELLED`, `CLOSED` | 업체별 요청/회신 컨테이너 |
| `purchase_orders` | `DRAFT`, `SENT`, `ACCEPTED`, `REJECTED`, `CANCELLED` | 실제 구매 문서. `SENT`는 승인 요청, `ACCEPTED`는 승인 완료 |
| `costs` | `CREATE`, `CANCEL`, `REFUND` | 비용 원장. 삭제보다 취소/환불 기록 |
| `payables` | `CREATED`, `APPROVED`, `ON_HOLD`, `PROCESSED`, `CANCELLED`, `REJECTED` | AP 정산 처리 요청. PAYMENT/REFUND는 `pbl_request_type`으로 구분 |
| `payments` | `PROCESSED`, `CANCELLED` | AP 정산 처리 결과. PAYMENT/REFUND는 `pay_tx_type`으로 구분 |
