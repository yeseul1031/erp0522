# Balhea ERP Design Decisions Log v7.9

본 문서는 Balhea ERP 설계 과정에서 내려진 **중요한 결정과 그 이유**를 기록한다.

---

## D1. 프로젝트 중심 설계
- 조직 중심 설계를 배제하고 프로젝트를 최상위 단위로 선택
- 담당자 변경 시 영향 범위를 최소화하기 위함

## D2. 조직/부서 정보를 ERP에서 관리하지 않음
- 그룹웨어를 진실 소스로 유지
- ERP는 업무 사실만 기록

## D3. cost / payable / payment 분리
- 비용 발생과 자금 유출을 분리
- 분할 지급, 승인 흐름 지원

## D4. 현금영수증은 documents
- 현금영수증의 본질은 지급 증빙
- 비용 내용은 cost에 기록

## D5. procurement_mode 제거
- `sourcing_cases.sc_type`으로 수급 방식 개념 통합
- 도메인 용어 일관성 확보

## D6. 조직 권한을 ERP 밖으로 이동
- ERP는 권한 계산을 하지 않음
- UI/백엔드가 외부 조직도를 활용

## D7. FK 대신 로그 중심 감사
- 유연한 변경 허용
- audit_logs / activity_logs로 추적

이 문서는 향후 설계 변경 시 반드시 참고해야 하는 기준 문서이다.


## D8. 문서 허브(documents + document_links)
- 문서/증빙/서류를 엔티티별 테이블로 분리하지 않고 `documents` 단일 테이블에 저장한다.
- 문서가 무엇의 근거인지(비용/지급/인보이스/배송 등)는 `document_links`로 느슨하게 연결한다.
- 이 결정은 cost/payment 분리 원칙을 유지하면서 문서 관리의 확장성을 높인다.

---

## ADR-DOCS-0001 문서 허브 단일화 (documents + document_links)

- 결정: 비용/지급/인보이스/배송 등 모든 첨부/증빙은 `documents`에 단일 저장하고, 연결은 `document_links`로 표현한다.
- 이유: 문서 저장 위치를 케이스별로 쪼개면 중복/누락/확장 비용이 커지고, “결제 1건에 증빙 N장” 같은 실무 케이스를 자연스럽게 수용하기 어렵다.
- 기각: 엔티티별 전용 문서 테이블(cost/payment 등) 분리 방식 — 확장/연결 복잡도 증가, 다대다 연결 취약.

## ADR-PROC-0001 RFQ/PO 단일화 및 환율 고정

- 결정: 국내/해외 RFQ/PO를 분리 테이블로 두지 않고 `rfqs`/`purchase_orders`로 단일화한다.
- 이유: 국내/해외 차이는 옵션 필드 차이(통화/인도조건/국가/환율)에 가깝고, 분리는 운영/개발/리포팅 복잡도를 증가시킨다.
- 결정: 해외 비용은 감사/재현을 위해 적용 환율과 환산 결과를 고정 저장한다(예: `cost_fx_applications`).

## ADR-PROC-0002 RFQ Plan 계층 제거 및 RFQ 직접 사용

- 결정: 현재 DDL 기준 견적 흐름은 `rfq_plans`, `rfqp_lines`, `rfqp_vendors`, `rfqp_allocations`를 사용하지 않고 `rfqs`, `rfq_lines`, `rfq_allocations`를 직접 사용한다.
- 결정: 여러 업체 비교견적은 업체별 `rfqs`를 각각 생성하고, 선택 결과는 `purchase_orders.po_source_rfq_sn`으로 표현한다.
- 이유: 견적기안 계층을 별도로 두지 않아도 RFQ 라인과 SCL 귀속은 `rfq_allocations`로 표현할 수 있고, PO 생성 시점의 근거 RFQ를 명확히 남길 수 있다.

## ADR-NAME-0001 메타 시간 컬럼 규칙

- 결정: 엔티티 메타(생성/수정) 시간은 `{abbr}_create_dt/{abbr}_update_dt`로 고정한다.
- 이유: JOIN/리포팅 충돌을 줄이고, 레코드 소속 엔티티 식별 및 감사 추적을 단순화한다.

---

## ADR-LOGI-0001 PO After 4축 모델 유지

- 결정: 발주 이후 영역은 4축(실물 `inventory_units`, 운송 `shipments`, 작업 `logistics_jobs`, 협의 `delivery_requests`)으로 모델링한다.
- 이유: “직송/미접촉”과 “입고/재고/바코드” 흐름을 동시에 수용하고, 작업/협의 로그를 독립적으로 남기기 위함.
- 비고: 배송요청(`delivery_requests`)은 협의가 필요할 때만 사용하고, 실행 이력은 항상 `logistics_jobs`로 남긴다.

## ADR-LOGI-0002 비용 귀속은 ct_type별 연결/배분 테이블로 관리

- 결정: `costs.ct_type`은 `PROJECT`, `PO`만 허용한다.
- 결정: PROJECT 비용은 `project_cost_allocations`로 프로젝트에 배분한다.
- 결정: PO 비용은 `po_cost_links`로 PO와 1:1 연결한다.
- 결정: PO 특수 비용 라인은 `po_cost_line_allocations`로 프로젝트에 배분한다.
- 이유: 비용 원장을 단순하게 유지하면서 프로젝트 비용과 PO 복합 비용의 성격 차이를 분리한다.
- 정본: ORDER_LINES, ORDER_LINE_OVERRIDES, SOURCING_CASES, SOURCING_CASE_LINES에는 비용을 직접 귀속하지 않는다.

## ADR-LOGI-0003 RFQ/PO 통합 조회 VIEW 전략 폐지

- 결정: 국내/해외 분리 테이블을 VIEW로 통합 조회하는 전략은 폐지한다.
- 이유: 정본은 RFQ/PO 단일 테이블(`rfqs`, `purchase_orders`)이므로 신규 개발은 VIEW 전략이 불필요하며 혼동을 유발한다.

---

## ADR-FIN-0002 PO 1건 = cost 1건 (운영 불변)

- 결정: PO 1건을 cost 1건으로 매핑하는 운영 정책을 유지한다(권장: `po_cost_links` 1:1).
- 이유:
  - 정산 단위를 단순화하고, 멀티셀러/플랫폼 결제 같은 케이스에서 운영 비용을 줄인다.
- 운영 규칙:
  - 셀러/사업자 단위 분리가 필요하면 PO를 분할 생성한다.
  - 분할이 불필요하면 PO=cost로 묶고, 거래 증빙은 cost에 연결한다.


## ADR-FIN-0003 AP Invoice 제거 및 Cost 기반 Payable 생성

- 결정: AP 영역에서 `invoices`, `invoice_lines`, `invoice_cost_allocations`, `payable_invoice_allocations`를 제거한다.
- 결정: `costs`를 모든 비용의 유일한 원천 원장으로 사용한다.
- 결정: `payables`는 costs를 근거로 한 AP 정산 처리 요청으로 사용한다. 지급 요청(`PAYMENT`)과 환불 확인 요청(`REFUND`)은 `pbl_request_type`으로 구분한다.
- 결정: 카드 직접 지급은 payable 없이 `payments.pay_ct_sn`으로 cost에 직접 연결한다.
- 결정: 현금은 아직 서비스 기획 전이므로 `payments`에 기록하지 않고 `costs`에만 등록한다.
- 결정: 계좌이체 지급과 환불 확인은 `payables.pbl_ct_sn` + `payments.pay_pbl_sn`으로 연결한다.
- 결정: `payments`는 `pay_tx_type`으로 지급 처리 결과(`PAYMENT`)와 환불 확인 결과(`REFUND`)를 구분하며, `pay_status`는 `PROCESSED`/`CANCELLED`만 사용한다.
- 결정: 여러 cost를 payable 1건으로 묶지 않는다. cost 1건은 여러 payable로 분할 가능하고, payable 1건은 payment 1건으로만 집행한다.
- 이유:
  - 동일한 사실을 `costs`와 `invoices`에 이중 기록하는 중복을 제거한다.
  - 계좌이체 통제와 환불 확인 업무 큐는 유지하되, 카드 직접 지급 경로는 단순화할 수 있다.

## ADR-FIN-0004 환불/차감 Cost와 지급 대사

- 결정: 원 cost는 원 비용 발생 사실로 보존하고, 환불/차감은 별도 negative cost로 기록한다.
- 결정: refund cost는 `ct_parent_ct_sn`으로 원 cost를 참조한다. 원 cost의 환불 여부, 환불액, 순비용은 자식 refund cost 집계로 계산한다.
- 결정: PO refund cost는 별도 `po_cost_links`를 만들지 않는다. `ct_parent_ct_sn -> 원 PO cost -> po_cost_links`를 따라 PO 귀속을 해석한다.
- 결정: payment는 실제 주고받은 총액만 기록하고 세전/세금 분리 필드를 두지 않는다.
- 결정: 세금계산서 지급 대사는 `tax_invoices.ti_total_amount`와 `tax_invoice_payment_allocations.tipa_amount`의 합계를 payment 방향(`pay_tx_type`)에 따라 비교한다.
- 이유:
  - 원 비용 발생 사실과 환불/차감 사건을 분리해 원장 이력을 보존한다.
  - PO 1건 = cost 1건 정책과 `po_cost_links` 1:1 제약을 유지하면서 PO 환불 귀속을 해석할 수 있다.
  - payment를 세무 구성 정보가 아닌 실제 정산 결과 원장으로 유지한다.

## ADR-DOM-0001 문서/실물/작업 분리 및 items 금지

- 결정: 문서(`*_lines`) / 실물(`inventory_units`) / 작업(`logistics_jobs`)을 섞지 않는다.
- 이유: 데이터가 커질수록 “대상(문서항목 vs 실물 vs 작업)”이 섞이면 운영/리포팅/자동화가 무너진다.
- 결정: items라는 용어/엔티티는 사용하지 않는다(혼동 유발).
