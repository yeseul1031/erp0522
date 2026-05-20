/* ============================================================================
 * Balhea ERP — Finance Schema (DDL)
 * ----------------------------------------------------------------------------
 * [이 파일의 성격]
 * - 본 파일은 Balhea ERP 스키마 중 "finance" 레이어에 해당한다.
 * - 계약/주문/수급의 실행 결과를 금액, 정산, 지급, 비용, 회계 관점에서
 *   기록·해석·집계하기 위한 엔티티들을 정의한다.
 * - 본 레이어는 업무 흐름을 생성하지 않으며,
 *   contracts / sourcing 레이어에서 생성된 사실(fact)을 재해석하는 역할을 한다.
 * - 회사의 여러 사업들이 공통으로 사용하는 "회계/재무적 사실"의 정본을 관리하는 레이어이다. 그러므로, 특정 사업에 의존적이지 않고 중립적으로 설계되어야 한다.
 *
 * ----------------------------------------------------------------------------
 * [의존 관계 — 중요]
 * - 본 파일은 다음 schema들을 전제로 한다:
 *   - erp_core_schema.sql
 *     : 조직, 담당자, 거래처, 물품, 문서, 변경이력 등 공통 기준 엔티티. 직접 연결 가능
 *   - erp_contracts_schema.sql
 *     : 계약, 주문, 수급, RFQ, PO 등 업무 실행의 정본 엔티티. 직접 연결이 아닌 참조/연결/집계를 통해 간접 연결만 한다.
 *
 * ----------------------------------------------------------------------------
 * [finance 레이어의 설계 관점]
 * - finance 레이어는 "무엇을 얼마에 샀는가 / 팔았는가"를
 *   독립적으로 정의하지 않는다.
 *
 * - 비용(costs) 원장, ct_type별 비용 연결/배분,
 *   실제 지급(payments) 및 관련 증빙을 관리한다.
 *
 * - 금액, 비용, 지급, 정산, 환율, 세금 등의 정보는
 *   contracts / sourcing 레이어의 실행 결과를 기준으로 파생된다.
 *
 * - 동일한 계약/주문/수급에 대해
 *   여러 회계 해석(예: 선급/후급, 분할 정산, 환율 차이)이
 *   동시에 존재할 수 있음을 전제로 설계한다.
 *
 * ----------------------------------------------------------------------------
 * [금액/환율 해석 원칙 — 중요]
 * - 환율은 비용(cost) 기준으로
 *   "적용 환율"과 원화 환산 결과를 고정 저장한다.
 *   이는 사후 재현성(reproducibility)과 감사(audit)를 위한 것이다.
 *
 * - finance 레이어의 수량/금액은
 *   계약 또는 수급의 "목표값"과 일치할 필요가 없다.
 *
 * - 실제 집행, 지급, 정산, 환율 적용 결과를
 *   있는 그대로 기록·추적하는 것이 목적이다.
 *
 * ----------------------------------------------------------------------------
 * [링크 vs 안분의 해석 원칙]
 * - *_links 테이블은 열린 관계 표현이다.
 *   본체 엔티티에 가능한 모든 FK를 직접 추가하지 않음으로써
 *   본체 테이블의 의존성 증가를 막고 엔티티 간 독립성을 유지한다.
 *   links 자체는 수량/금액/비율/실행 귀속을 의미하지 않는다.
 * - *_allocations 테이블은 원가 계산, 회계 처리, 정산의 기준이 되는 수치적 귀속을 의미한다.
 *
 * - finance 계산과 집계는 *_links가 아니라 *_allocations를 기준으로 수행해야 한다.
 *
 * ----------------------------------------------------------------------------
 * [DDL 편집 및 유지 원칙 — 요약]
 * - 본 파일의 ddl 편집 규율은
 *   erp_core_schema.sql 상단 주석을 정본으로 따른다.
 *
 * - 사용자가 명시적으로 요청한 변경만 수행한다.
 * - 임의 개선, 정리, 축약, 의미 변경은 금지한다.
 * - 필요하거나 더 나은 구조가 보일 경우,
 *   반드시 제안으로 분리하고 사용자의 동의를 받은 후 적용한다.
 *
 * ----------------------------------------------------------------------------
 * [ChatGPT / LLM 협업 규율 — 요약]
 * - 본 파일 단독으로 편집 요청을 받더라도,
 *   core / contracts 레이어의 설계 의도를 침해하지 않는다.
 *
 * - 편집 범위가 확대될 가능성이 있는 경우,
 *   작업 전에 영향 범위를 먼저 설명한다.
 *
 * 이 주석 블록은 finance schema를 읽는 모든 사람과
 * LLM 기반 편집자가 반드시 따라야 할 선언문이다.
 * ============================================================================

[도메인 정의]
- cost/payable/payment 는 "비용 정산(Account Payable, AP)" 도메인이다.
  - costs    : 우리가 부담해야 할 비용/채무의 발생 원장
  - payables : 비용을 근거로 재무에 지급/환불 처리를 요청하는 AP 정산 처리 요청 단위
  - payments : 해당 비용 정산 도메인에서 실제 지급 또는 환불이 처리된 AP 정산 결과
- receivable/receipt 는 "납품 정산(Account Receivable, AR)" 도메인이다.
  - receivables : 우리가 받아야 할 돈(채권/정산 단위; 수금 바구니)
  - receipts     : 해당 납품 정산 도메인에서 실제로 돈이 들어온 수금 이벤트
- payments와 receipts는 단순한 전사 현금 출납장 한 쌍이 아니다.
  AP(cost-payable-payment)는 낼 돈을 관리하고, AR(receivable-receipt)는 받을 돈을 관리한다.
  두 도메인의 결과를 함께 이용하면 수입/지출의 양쪽 흐름을 볼 수 있지만,
  은행계좌 잔고장이나 완전한 복식부기 총계정원장 자체를 의미하지는 않는다.

[요구사항 핵심]
- receivable은 개별 order_line과 붙지 않고, order_line들의 묶음인 order(주문서)와 1:1로 매핑된다.
   (계약방식에 따른 구성 설명 상세는 erp_contracts_schema.sql에서 관리)
- receivable은 정산 단위로, 실제 수금 이벤트인 receipt과는 별도의 엔티티로 관리된다.
- receivable은 특정 사업과 무관한 중립적인 데이터로 출처 정보는 FK가 아닌 receivable_order_links로 연결한다.

[문서 정책]
- 모든 문서/증빙/첨부는 documents 단일 저장
- document_links로 receivables / receipts / order_lines 등 필요한 대상에 연결
- 거래명세서/정산서/입금확인증 등은 documents로 저장 후 link만 건다.

===============================================================================
[코드/ENUM - 값과 의미]

1) recv_status (Receivable 상태)
- DRAFT        : 초안(아직 확정 전, 포함 라인/금액 변동 가능)
- ISSUED       : 발행/확정(정산 단위 확정, 외부 청구/요청에 준하는 상태)
- PARTIALLY_PAID : 일부 수금(총액 중 일부 receipts 존재)
- PAID         : 전액 수금 완료(잔액 0)
- CANCELLED    : 취소(정산 단위 무효)
- CLOSED       : 종료(회계 마감 등 운영상 종료)

2) recv_type (Receivable 유형)
- CUSTOMER_INVOICE : 고객 청구/정산(일반)
- PROGRESS_BILLING : 기성/중도금 등 단계별 청구
- FINAL_BILLING    : 잔금/최종 청구
- ADJUSTMENT       : 조정(할인/반품/차감/정산조정)
- OTHER            : 기타

3) receipt_method (수금 수단)
- TRANSFER : 계좌입금
- CARD     : 카드(고객 카드 결제)
- CASH     : 현금
- PG       : PG/플랫폼 정산 입금
- OFFSET   : 상계/대체(상계 처리)
- OTHER    : 기타

4) receipt_status (수금 이벤트 상태)
- PENDING   : 대기(입금 예정/확인 전)
- CONFIRMED : 확인(실입금 확인됨)
- REVERSED  : 취소/환불/되돌림(수금 이벤트 무효)
- CANCELLED : 취소

===============================================================================
[정합성/검증 규칙(중요)]
A. order_line은 receivable에 최대 1회만 포함
- receivable_order_links.rol_ol_sn 에 UNIQUE 걸어서 DB 강제

B. receivable 총액 계산/불일치 처리
- receivables.recv_amount_total 은 "정산 확정치(스냅샷)"로 저장 가능
- 포함된 order_lines의 금액 합계와 다를 수 있음(할인/조정/부분 정산)
- 차이가 생기면:
  - recv_adjustment_amount 또는 recv_note로 근거를 남긴다
  - 문서(정산서/조정근거)는 documents에 저장 후 document_links로 연결

C. receipts 합계로 상태 전이
- SUM(receipts.amount where status=CONFIRMED) < recv_amount_total  → PARTIALLY_PAID
- == recv_amount_total → PAID
- 초과 수금은 원칙적으로 금지(발생 시 ADJUSTMENT 처리/환불 receipt로 상쇄)

===============================================================================
*/



-- =============================================================================
-- TABLE: receivables
-- DESC : 납품처 정산 엔티티, 수금/정산(채권) 헤더. “우리가 받아야 할 돈”의 단위. (지출의 payables와 개념적으로 대칭)
-- 납품처 정산은 납품처로 구분될뿐, 조달이나 MRO에 따라 구분하기 위해서는 _links를 이용해야한다. (현재는 조달만 존재하고, 조달의 경우 주문서(order)단위로 구분하므로 receivable_order_links 로 간접 연결한다)
-- =============================================================================
CREATE TABLE receivables (
  recv_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수금(정산/채권) PK',
  recv_customer_pt_sn BIGINT UNSIGNED NULL COMMENT '고객/수금 대상 거래처 FK (parties.pt_sn). 없으면 프로젝트 기본 고객을 사용(운영 정책)',

  recv_type ENUM(
    'CUSTOMER_INVOICE',
    'PROGRESS_BILLING',
    'FINAL_BILLING',
    'ADJUSTMENT',
    'OTHER'
  ) NOT NULL DEFAULT 'CUSTOMER_INVOICE' COMMENT '수금/정산 유형. 값 의미는 DDL 상단 주석 참조',

  recv_status ENUM(
    'DRAFT',
    'ISSUED',
    'PARTIALLY_PAID',
    'PAID',
    'CANCELLED',
    'CLOSED'
  ) NOT NULL DEFAULT 'DRAFT' COMMENT '수금 상태. 값 의미는 DDL 상단 주석 참조',

  recv_issue_dt DATETIME NULL COMMENT '발행/확정 일시(ISSUED로 전환 시점). 청구/정산 확정 기준',
  recv_due_dt DATETIME NULL COMMENT '입금 기한(운영 기준)',

  recv_currency_code VARCHAR(16) NOT NULL DEFAULT 'KRW' COMMENT '통화 코드(확장 가능). 기본 KRW. 예: USD',
  recv_amount_total DECIMAL(18,6) NOT NULL DEFAULT 0 COMMENT '실제 입금 요청할 총액(정산 확정치/스냅샷). order_lines 합계와 다를 수 있음(조정된 금액)',
  recv_adjustment_amount DECIMAL(18,6) NOT NULL DEFAULT 0 COMMENT '조정액(할인/반품/차감 등). 0 != SUM(order_lines)라면, 사유를 recv_note와 함께 기록',

  recv_note TEXT NULL COMMENT '정산 메모(조정 사유, 정산 범위, 특이사항). 근거 문서는 documents로 저장 후 document_links로 연결',

  recv_create_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  recv_update_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

  PRIMARY KEY (recv_sn),

  KEY idx_recv_customer (recv_customer_pt_sn),
  KEY idx_recv_status (recv_status),
  KEY idx_recv_due (recv_due_dt),

  CONSTRAINT fk_recv_customer
    FOREIGN KEY (recv_customer_pt_sn) REFERENCES parties(pt_sn)

) COMMENT='수금/정산(채권) 헤더. 실제 수금 이벤트는 receipts로 기록.' AUTO_INCREMENT=100;


-- =============================================================================
-- TABLE: receivable_order_links
-- DESC : receivable ↔ order 연결(정본). 1:1 연결
-- =============================================================================
CREATE TABLE receivable_order_links (
  rol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수금-주문서 링크 PK',

  rol_recv_sn BIGINT UNSIGNED NOT NULL COMMENT '수금(정산) FK (receivables.recv_sn)',
  rol_o_sn BIGINT UNSIGNED NOT NULL COMMENT '주문서 FK (orders.o_sn)',

  rol_create_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  rol_update_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

  PRIMARY KEY (rol_sn),

  UNIQUE KEY uq_rol_recv_o_sn (rol_o_sn, rol_recv_sn),          -- 핵심 제약: 논리적으로는 청구서 1개당 주문서 1개이나, 상태 취소 등으로 인해 물리적으로 남아있는 경우를 고려하여 o_sn 단독 UNIQUE는 걸지 않음
  UNIQUE KEY uq_rol_recv_sn (rol_recv_sn),

  CONSTRAINT fk_rol_recv
    FOREIGN KEY (rol_recv_sn) REFERENCES receivables(recv_sn),

  CONSTRAINT fk_rol_o
    FOREIGN KEY (rol_o_sn) REFERENCES orders(o_sn)

) COMMENT='수금(정산)과 주문서 연결(정본). receivable:order는 1:1이다' AUTO_INCREMENT=100;


-- =============================================================================
-- TABLE: receipts
-- DESC : 실제 수금(입금) 이벤트. receivable 1건에 receipts N건(분할 수금) 가능.
-- =============================================================================
CREATE TABLE receipts (
  rcp_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수금 이벤트 PK',

  rcp_recv_sn BIGINT UNSIGNED NOT NULL COMMENT '수금(정산) FK (receivables.recv_sn). 어떤 receivable에 대한 입금인지',

  rcp_status ENUM('PENDING','CONFIRMED','REVERSED','CANCELLED')
    NOT NULL DEFAULT 'CONFIRMED' COMMENT '수금 이벤트 상태. 값 의미는 DDL 상단 주석 참조',

  rcp_amount DECIMAL(18,6) NOT NULL COMMENT '실제 수금 금액(입금액)',
  rcp_received_at DATETIME NULL COMMENT '입금 확인 일시(확정 시점). PENDING이면 NULL 가능',

  rcp_reference_no VARCHAR(64) NULL COMMENT '거래 참조번호(이체 거래번호, 카드 승인번호, PG 정산 ID 등)',
  rcp_note TEXT NULL COMMENT '수금 메모(부분수금/상계/환불/정산 특이사항). 증빙은 documents에 저장 후 document_links로 연결',

  rcp_create_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  rcp_update_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

  PRIMARY KEY (rcp_sn),

  KEY idx_rcp_recv_sn (rcp_recv_sn),
  KEY idx_rcp_status (rcp_status),
  KEY idx_rcp_received_at (rcp_received_at),

  CONSTRAINT fk_rcp_recv
    FOREIGN KEY (rcp_recv_sn) REFERENCES receivables(recv_sn)

) COMMENT='실제 수금(입금) 이벤트. receivable에 대한 분할 수금 가능. 증빙은 documents+document_links.' AUTO_INCREMENT=100;


-- ======================================================================
-- TABLE: costs
-- DESC : 비용(원장)
-- NOTE : costs는 '비용 발생' 원장이다(사유/금액/발생일). 원장은 단순 유지하고, 귀속/안분은 ct_type별 연결/배분 테이블에서 관리한다.
-- NOTE : ct_type은 PROJECT 또는 PO만 허용한다. PROJECT 비용은 project_cost_allocations로 프로젝트에 배분한다.
-- NOTE : PO 비용은 po_cost_links로 발주서와 1:1 연결한다. PO 내부 상품 비용은 po_allocations, 발주 특수 비용은 po_cost_line_allocations를 통해 해석/배분한다.
--        단, PO 환불/차감 cost는 po_cost_links를 새로 만들지 않고 ct_parent_ct_sn으로 원 PO cost를 참조한 뒤,
--        원 PO cost의 po_cost_links를 따라 PO 귀속을 해석한다.
-- NOTE : 환불/차감은 원 cost를 덮어쓰지 않고 별도 negative cost로 기록한다.
--        원 cost의 환불 여부/환불액/순비용은 ct_parent_ct_sn으로 연결된 자식 REFUND cost 집계로 계산한다.
-- NOTE : ORDER_LINES, ORDER_LINE_OVERRIDES, SOURCING_CASES, SOURCING_CASE_LINES에 비용을 직접 귀속하지 않는다.
-- NOTE : 비용 증빙(거래명세서/정산근거/통관서류 등)은 documents+document_links로 costs에 연결한다(다중 첨부 가능).
-- NOTE : 전자세금계산서(XML/PDF) 원본은 tax_invoices에 documents+document_links로 연결하고,
--        tax_invoices ↔ payments 대사는 tax_invoice_payment_allocations로 관리한다.
--        (즉, 세금계산서는 costs의 직접 정본이 아니다)
-- ======================================================================
CREATE TABLE costs (
  ct_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '비용 PK',
  ct_type ENUM('PROJECT','PO') NOT NULL COMMENT '비용 부과/배분 대상 타입(discriminator). PROJECT:프로젝트 귀속 비용, PO:발주서/주문서 귀속 비용.',
  ct_kind ENUM('PO_COST', 'LOGISTICS','HANDLING_EQUIPMENT','PROCESSING','LABOR_SERVICE','QUALITY_TEST','TAX_FINANCE','SITE_WORK', 'GENERAL_EXPENSE', 'ADDITIONAL_DELIVERY')
    NOT NULL COMMENT 'LOGISTICS(물류/운송비), HANDLING_EQUIPMENT(하역/장비비), PROCESSING(가공/제조/외주비), LABOR_SERVICE(인건비/용역비), QUALITY_TEST(시험/품질/인증비), TAX_FINANCE(통관/세금/금융비), SITE_WORK(현장/공사/설치비), GENERAL_EXPENSE(일반경비/운영비), ADDITIONAL_DELIVERY(추가 납품-계약외)',
/*
 | ENUM 코드 | 한글명      | 의미 |
|---|----------|---|
| `PO_COST` | 발주비   | 발주 비용 |
| `LOGISTICS` | 물류/운송비   | 물품 이동, 운반, 배송, 관련 비용 |
| `HANDLING_EQUIPMENT` | 하역/장비비   | 하역, 장비 투입 관련 비용 |
| `PROCESSING` | 가공/제조/외주비 | 제품 또는 자재를 제작·변형·가공하기 위해 발생한 비용 |
| `LABOR_SERVICE` | 인건비/용역비  | 사람의 작업, 노무, 공임, 용역 제공으로 발생한 비용 |
| `QUALITY_TEST` | 시험/품질/인증비 | 시험, 검사, 성적서, 검교정, 품질보증 관련 비용 |
| `TAX_FINANCE` | 통관/세금/금융비 | 관세, 부가세, 통관, 송금, 보증보험 등 세금·금융 관련 비용 |
| `SITE_WORK` | 현장/공사/설치비 | 납품 현장, 설치, 철거, 폐기물 처리, 현장 공사 관련 비용 |
| `GENERAL_EXPENSE` | 일반경비/운영비 | 특정 원가 성격으로 분류하기 어려운 일반 운영성 비용 |
| `ADDITIONAL_DELIVERY` | 추가 납품 (계약외) | 납품 과정에서 비정형적으로 추가 제공되는 물품 비용 |
 */
  ct_pt_sn BIGINT UNSIGNED NULL COMMENT '지출 대상 업체 PK(parties)',
  ct_occurred_at DATETIME NOT NULL COMMENT '지출 발생일시(업무 이벤트)',
  ct_price DECIMAL(18,2) NOT NULL COMMENT '비용 금액(세금제외)',
  ct_tax DECIMAL(18,2) NOT NULL COMMENT '비용 세금 부분',
  ct_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화',
  ct_note VARCHAR(500) NULL COMMENT '비용 설명',
  ct_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  ct_status ENUM('CREATE', 'CANCEL', 'REFUND') NOT NULL DEFAULT 'CREATE' COMMENT '비용 상태(ENUM) | CREATE:생성, CANCEL:취소(payable까지 생성 안되고 그냥 삭제시 조용히 쓱싹, payable이 있다면 reject시켜버리기), REFUND:환불/차감',
  ct_parent_ct_sn BIGINT UNSIGNED NULL COMMENT '취소, 부분환불 등으로 생성시 부모 비용 PK',
  ct_unpaid_amount DECIMAL(18,2) NOT NULL COMMENT '미지급금. payment 생성시마다 갱신한다. CREATE cost는 (ct_price+ct_tax) - sum(PAYMENT pay_amount), REFUND cost는 음수 cost 총액을 양수 REFUND payment가 상쇄하므로 (ct_price+ct_tax) + sum(REFUND pay_amount)로 해석한다.',
  ct_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ct_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ct_sn),
  KEY idx_costs_vendor (ct_pt_sn),
  KEY idx_costs_occurred_at (ct_occurred_at),
  KEY idx_costs_parent_status (ct_parent_ct_sn, ct_status),
  CONSTRAINT fk_costs_vendor
    FOREIGN KEY (ct_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_costs_creator
    FOREIGN KEY (ct_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_costs_parent
    FOREIGN KEY (ct_parent_ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용(원장)' AUTO_INCREMENT=100;

-- ======================================================================
-- TABLE: bank_accounts
-- DESC : 거래처 수취 계좌(국내/해외 겸용, 송금 입력용 주소록)
-- ======================================================================
CREATE TABLE bank_accounts (
  bk_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '거래처 계좌 PK (ERP 전용 약어)',
  bk_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '거래처 FK: parties.pt_sn (이 계좌의 소유/수취 대상)',

  bk_bank_name VARCHAR(80) NOT NULL COMMENT '은행명(국문/영문 모두 가능)',
  bk_account_number VARCHAR(80) NOT NULL COMMENT '계좌번호(문자열; 해외/IBAN 등 포함 가능)',
  bk_account_holder_name VARCHAR(120) NOT NULL COMMENT '예금주/계좌명(상대방 계좌명)',

  bk_contact VARCHAR(80) NULL COMMENT '연락처(옵션)',
  bk_account_label VARCHAR(80) NULL COMMENT '계좌 별칭(옵션; 예: 주계좌/세금계산서용/긴급용)',
  bk_note VARCHAR(500) NULL COMMENT '메모(옵션)',

  bk_is_primary TINYINT(1) NULL COMMENT '주 계좌 여부, 1이면 주사용계좌. NULL이면 그냥 계좌.',
  bk_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '사용중 여부(0/1)',

  -- 해외 송금 대응(필요 시에만 입력)
  bk_country_code CHAR(2) NULL COMMENT '국가코드(ISO 3166-1 alpha-2; 예: KR, US)',
  bk_ccy CHAR(3) NULL COMMENT '통화코드(ISO 4217; 예: KRW, USD)',
  bk_swift_bic VARCHAR(20) NULL COMMENT 'SWIFT/BIC(해외송금; 예: BOFAUS3N)',
  bk_iban VARCHAR(34) NULL COMMENT 'IBAN(해외; EU 등)',
  bk_routing_number VARCHAR(32) NULL COMMENT 'Routing/ABA/Sort code 등 지역별 은행코드',
  bk_bank_address VARCHAR(128) NULL COMMENT '은행 주소(해외송금 시 필요할 수 있음)',
  bk_intermediary_bank_info VARCHAR(255) NULL COMMENT '중개은행 정보(옵션)',

  bk_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 시각',
  bk_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 시각',

  PRIMARY KEY (bk_sn),

  KEY idx_bk_pt (bk_pt_sn, bk_is_active, bk_is_primary),
  KEY idx_bk_bank_account (bk_account_number, bk_bank_name),

  UNIQUE KEY uk_bk_pt_bank_acct (bk_pt_sn, bk_bank_name, bk_account_number),
  UNIQUE KEY uk_bk_is_primary (bk_pt_sn, bk_is_primary)

  -- FK는 운영정책에 따라 선택
  -- ,CONSTRAINT fk_bank_accounts_pt FOREIGN KEY (bk_pt_sn) REFERENCES parties(pt_sn)
) COMMENT='거래처 수취 계좌(국내/해외 겸용, 송금 입력용 주소록)' AUTO_INCREMENT=100;


-- ======================================================================
-- TABLE: payments
-- DESC : AP 정산 결과 원장(지급/환불)
-- NOTE : payments는 AP(비용 정산) 도메인의 정산 처리 결과 원장이다.
--        전사 전체 입출금 원장이 아니라, costs/payables를 근거로 지급(PAYMENT)
--        또는 환불/차감(REFUND)이 처리된 결과만 기록한다.
-- NOTE : payments에는 대기 상태를 두지 않는다. 처리 대기/승인/보류는 payables가 담당하고,
--        payments row는 실제 업무상 정산 결과가 확정된 뒤 생성한다.
-- NOTE : cost 1건은 여러 payables로 나뉠 수 있으나, payable 1건은 payment 1건으로만 처리된다.
-- NOTE : 실제 사람이 여러 번 이체했더라도 ERP 데이터상 payment는 payable 1건당 1건만 기록한다.
-- NOTE : payment_lines는 본 운영 정책에서는 사용하지 않는다.
-- NOTE : payment의 업무 방향은 pay_tx_type으로 해석한다.
--        PAYMENT는 비용 지급 처리 결과, REFUND는 환불/차감 처리 결과이다.
-- NOTE : payment의 처리 수단 계열은 pay_method로 해석한다.
--        CARD는 카드 처리 계열, TRANSFER는 계좌이체 처리 계열이다.
--        크레딧 적립/상계 여부와 금액은 pay_credit_amount로 표현하며,
--        pay_method에 CREDIT/OFFSET 같은 별도 값을 두지 않는다.
-- NOTE : pay_amount는 이번 payment가 처리한 총 정산 금액이다.
--        pay_credit_amount는 pay_amount 중 크레딧으로 처리한 금액이다.
--        REFUND에서는 크레딧 적립액, PAYMENT에서는 크레딧 상계 사용액으로 해석한다.
-- NOTE : CARD 즉시 지급은 pay_ct_sn으로 costs에 직접 연결하고 pay_pbl_sn은 NULL일 수 있다.
--        payable을 거쳐 생성된 payment는 pay_pbl_sn으로 payables에 연결한다.
--        pay_pbl_sn이 있는 경우 payments.pay_ct_sn은 조회 편의를 위한 cost 연결이며,
--        payables.pbl_ct_sn과 같은 cost를 가리켜야 한다.
-- NOTE : CASH는 현재 지급 처리 흐름을 서비스로 기획하지 않았으므로 payments에 기록하지 않는다.
--        현금으로 발생한 비용은 costs에만 등록하고, 실제 현금 출납/증빙 처리 방식은 추후 별도 설계한다.
-- ======================================================================
CREATE TABLE payments (
  pay_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'AP 정산 결과 PK',
  pay_tx_type ENUM('PAYMENT','REFUND')
    NOT NULL DEFAULT 'PAYMENT' COMMENT 'AP 정산 결과 유형(ENUM) | PAYMENT:비용 지급 처리 결과, REFUND:환불/차감 확인 처리 결과',
  pay_method ENUM('CARD','TRANSFER')
    NOT NULL COMMENT '정산 수단(ENUM) | CARD:카드, TRANSFER:계좌이체. CASH는 현재 payments에 기록하지 않고 costs에만 등록한다.',
  pay_amount DECIMAL(18,2) NOT NULL COMMENT '이번 payment가 처리한 총 정산 금액. payables.pbl_total_amount와 일치해야 한다. 항상 양수. 지급/환불 방향은 pay_tx_type으로 해석한다.',
  pay_credit_amount DECIMAL(18,2) NOT NULL DEFAULT 0 COMMENT 'pay_amount 중 크레딧으로 처리한 금액. REFUND에서는 크레딧 적립액, PAYMENT에서는 크레딧 상계 사용액. 항상 0 이상',

  pay_status ENUM('PROCESSED','CANCELLED')
    NOT NULL DEFAULT 'PROCESSED' COMMENT 'AP 정산 결과 상태(ENUM) | PROCESSED:처리 완료, CANCELLED:취소/무효',
  pay_pt_sn BIGINT UNSIGNED NULL COMMENT '정산 상대 업체 PK(parties) | PAYMENT는 지급 상대, REFUND는 환불/차감 상대',
  pay_ct_sn BIGINT UNSIGNED NULL COMMENT '정산 근거 비용 PK(costs). CARD 즉시 지급은 이 값으로 직접 연결하고, pay_pbl_sn이 있는 경우 payables.pbl_ct_sn과 같은 cost를 가리켜야 한다.',
  pay_pbl_sn BIGINT UNSIGNED NULL COMMENT 'AP 정산 처리 요청 PK(payables). TRANSFER 지급 또는 REFUND 환불 확인처럼 재무 처리 요청을 거친 경우 사용한다. 카드 즉시 지급은 NULL일 수 있다. payable:payment는 1:1이다.',

  pay_paid_at DATETIME NOT NULL COMMENT '정산 처리일시(업무 이벤트). PAYMENT는 지급 완료일시, REFUND는 환불 확인일시',
  pay_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화',
  pay_ref_no VARCHAR(32) NULL COMMENT '참조번호(카드 승인번호/카드취소번호/이체 거래번호/환불 거래번호 등)',
-- 계좌정보는 바뀔수 있으므로 FK로 연결하지 않고 스냅샷으로 보존한다.
--  pay_bk_sn BIGINT UNSIGNED NULL COMMENT '정산에 사용/확인된 거래처 계좌 PK(bank_accounts). PAYMENT는 수취 계좌, REFUND는 환불 출처/참조 계좌로 사용할 수 있다.',
  pay_bank_name VARCHAR(80) NULL COMMENT '정산 당시 은행명 스냅샷. pay_method=TRANSFER일 때 bank_accounts에서 복사하거나 수동 입력한다.',
  pay_account_number VARCHAR(80) NULL COMMENT '정산 당시 계좌번호 스냅샷. 통장 조회/거래처 매칭과 과거 payment 표시의 기준으로 사용한다.',
  pay_account_holder_name VARCHAR(120) NULL COMMENT '정산 당시 예금주/계좌명 스냅샷. bank_accounts 변경/거래처 통합 이후에도 payment 당시 정보를 보존한다.',
  pay_note VARCHAR(500) NULL COMMENT 'AP 정산 결과 메모',
  pay_data_json JSON NULL COMMENT '추가 메타(JSON)',
  pay_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  pay_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pay_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (pay_sn),
  UNIQUE KEY uk_payments_pbl (pay_pbl_sn),
  KEY idx_payments_cost (pay_ct_sn),
  KEY idx_payments_paid_at (pay_paid_at),
  KEY idx_payments_payee (pay_pt_sn),
  CONSTRAINT fk_payments_cost
    FOREIGN KEY (pay_ct_sn) REFERENCES costs(ct_sn),
  CONSTRAINT fk_payments_payee
    FOREIGN KEY (pay_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_payments_creator
    FOREIGN KEY (pay_a_sn) REFERENCES assignees(a_sn)
) COMMENT='AP 정산 결과 원장. 지급(PAYMENT)과 환불(REFUND)의 처리 결과를 기록하며, 실제 외부 입출금과 크레딧 적립/상계를 함께 표현한다.' AUTO_INCREMENT=100;


CREATE TABLE party_credit_balances
(
    pcb_sn              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '거래처 크레딧 잔액 PK',

    pcb_pt_sn           BIGINT UNSIGNED NOT NULL COMMENT '거래처 PK(parties)',
    pcb_ccy             CHAR(3)         NOT NULL DEFAULT 'KRW' COMMENT '통화',
    pcb_balance_amount  DECIMAL(18, 2)  NOT NULL DEFAULT 0 COMMENT '현재 크레딧 잔액 캐시. 정본은 payments.pay_credit_amount 집계',

    pcb_recalculated_at DATETIME        NULL COMMENT 'payments 집계 기준으로 잔액을 마지막 재계산한 일시',
    pcb_note            VARCHAR(500)    NULL COMMENT '잔액 메모',

    pcb_create_dt       DATETIME        NOT NULL COMMENT '레코드 생성일시',
    pcb_update_dt       DATETIME        NOT NULL COMMENT '레코드 수정일시',

    PRIMARY KEY (pcb_sn),
    UNIQUE KEY uk_party_credit_balance_pt (pcb_pt_sn), -- 거래처별 여러 CURRENCY별 잔액을 담고 싶다면 uk를 바꿔야함

    CONSTRAINT fk_pcb_pt
        FOREIGN KEY (pcb_pt_sn) REFERENCES parties (pt_sn)
) COMMENT ='거래처별 상계 가능 크레딧 현재 잔액 캐시. 정본은 payments의 pay_credit_amount 집계' AUTO_INCREMENT = 100;


-- ======================================================================
-- TABLE: fx_rates
-- DESC : 환율 스냅샷(재현/감사 목적)
-- NOTE : fx_rates는 환율 마스터(참조용)이며, 회계 재현(감사) 목적의 고정 환율/환산 결과는 cost_fx_applications에 저장한다.
-- ======================================================================
CREATE TABLE fx_rates (
  fx_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'FX 환율 스냅샷 PK',

  fx_base_ccy CHAR(3) NOT NULL COMMENT
'기준 통화 (ISO 4217, 예: USD).
- fx_rate는 "기준 1단위"에 대한 값으로 해석한다.',

  fx_quote_ccy CHAR(3) NOT NULL COMMENT
'대상/상대 통화 (ISO 4217, 예: KRW).
- fx_rate는 "대상 통화 단위"로 표현된다.',

  fx_rate DECIMAL(18, 8) NOT NULL COMMENT
'환율 값 (방향 고정: base -> quote).
- 정의: 1 {fx_base_ccy} = fx_rate {fx_quote_ccy}
- 예1) base=USD, quote=KRW, fx_rate=1300.50  => 1 USD = 1300.50 KRW
- 예2) base=EUR, quote=USD, fx_rate=1.08520000 => 1 EUR = 1.0852 USD
- 주의: "적용 정책/사유"는 fx_rates가 알지 않는다. (왜 이 값을 선택했는지는 application/비용/계약 레이어에서 관리)',

  fx_as_of_dt DATETIME NOT NULL COMMENT
'환율 기준 시각(as-of).
- 이 스냅샷이 “어느 시점의 값”인지 고정하는 기준.
- 목적: cost가 fx_sn을 참조하면, 나중에 동일 시점의 환율 상태를 재현할 수 있어야 한다.',

  fx_source VARCHAR(50) NOT NULL COMMENT
'환율 출처.
- 예: ECB, KEBHANA, BLOOMBERG, REUTERS, MANUAL(수동)
- 목적: 동일 통화쌍/동일 시각이라도 출처에 따라 값이 다를 수 있으므로 출처를 고정하여 재현/감사 가능하게 한다.',

  fx_source_ref VARCHAR(100) NULL COMMENT
'출처별 원본 식별자/코드(옵션).
- 예: API 응답의 rate_id, 고시 코드, 스크래핑 원문 키, 내부 업로드 파일 식별자 등
- 목적: 사후 검증 시 "이 값이 어디서 왔는지" 원문 추적을 돕는다.',

  fx_rate_type VARCHAR(30) NOT NULL COMMENT
'환율 값의 성격(스냅샷 메타).
- 이것은 "적용 정책/사유"가 아니라, 환율 값 자체가 어떤 성격의 값인지(고시/스팟/평균 등)를 나타낸다.
- 권장 값(예시):
  - SPOT    : 시장/실시간(또는 근실시간) 값
  - FIXING  : 특정 기준 시각의 고시/확정 값
  - AVERAGE : 기간 평균 값(월평균 등)
  - CUSTOM  : 내부 수동 입력 값(출처가 MANUAL일 때 주로 사용)',

  fx_created_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT
'스냅샷 레코드 생성 시각(시스템 기록).
- fx_as_of_dt는 “환율의 기준 시각”, fx_created_dt는 “DB에 저장된 시각”으로 의미가 다르다.',

  UNIQUE KEY uq_fx_rates_snapshot (
    fx_base_ccy,
    fx_quote_ccy,
    fx_as_of_dt,
    fx_rate_type,
    fx_source
  ) COMMENT
'동일 시점/유형/출처의 환율 스냅샷 중복 방지.
- 같은 as-of라도 source 또는 type이 다르면 다른 스냅샷으로 공존 가능'
) COMMENT='환율 스냅샷 정본 테이블 (과거 재현 가능해야 함)' AUTO_INCREMENT=100;


-- ======================================================================
-- TABLE: cost_fx_applications
-- DESC : 비용 환율 적용(적용환율 고정/감사용)
-- NOTE : 해외 비용은 적용한 환율 스냅샷과 선택 사유를 연결해 재현/감사를 가능하게 한다.
-- NOTE : 환율 값과 기준 시각은 fx_rates에 저장하고, cost_fx_applications는 fx_sn 및 적용 정책/사유만 저장한다.
-- ======================================================================
CREATE TABLE cost_fx_applications (
  cfxa_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Cost-FX 적용 관계 PK',

  ct_sn BIGINT UNSIGNED NOT NULL COMMENT
'적용 대상 cost PK (costs.ct_sn).
- 이 테이블은 cost와 fx_rates 스냅샷을 "연결"하는 링크 테이블이다.',

  fx_sn BIGINT UNSIGNED NOT NULL COMMENT
'적용된 환율 스냅샷 PK (fx_rates.fx_sn).
- 환율 값(rate) 자체는 fx_rates에만 존재해야 하며, 이 테이블에 중복 저장하지 않는다.',

  cfxa_policy_code VARCHAR(30) NULL COMMENT
'환율 선택/적용 기준(사유) 코드.
- fx_rates가 "무슨 값이었는가(what)"를 책임진다면,
  cfxa_policy_code는 "왜 이 fx_sn을 선택했는가(why)"를 기록한다.
- 예시(권장 패턴, 실제 값은 내부 정책에 맞게):
  - QUOTE_DATE   : 견적일 기준 환율
  - PO_DATE      : 발주일 기준 환율
  - PAYMENT_DATE : 지급일 기준 환율
  - CUSTOMS_DATE : 통관일 기준 환율
  - MANUAL_LOCK  : 수동 지정/고정 (특정 사유로 고정)
- 주의: 이 코드는 회사 운영 코드이며, 코드값은 주석/문서에 append-only로 누적 보강한다.',

  cfxa_applied_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT
'이 환율 스냅샷을 적용(선택)하기로 결정한 시각.
- fx_as_of_dt(환율 기준 시각)과 구분된다.
- fx_as_of_dt는 “환율 값이 대표하는 시점”
- cfxa_applied_dt는 “그 환율을 cost에 연결하기로 결정한 시점”',

  cfxa_note VARCHAR(255) NULL COMMENT
'비고 (수동 지정 사유, 예외 상황 설명 등).
- 환율 값/통화/계산 결과를 중복 저장하지 않고,
  "선택 근거"만 최소한으로 남긴다.',

  UNIQUE KEY uq_cfxa_ct (ct_sn) COMMENT
'1 cost = 1 fx 스냅샷 (현재 정책).
- cost에 적용된 환율은 하나로 고정한다.
- 정책이 바뀌어 이력이 필요해지면, UNIQUE를 해제하고 이력 테이블로 확장한다.',

  KEY idx_cfxa_fx (fx_sn),

  CONSTRAINT fk_cfxa_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn),

  CONSTRAINT fk_cfxa_fx
    FOREIGN KEY (fx_sn) REFERENCES fx_rates(fx_sn)
) COMMENT='Cost와 환율 스냅샷 간 적용 관계 (링크 + 선택 사유만 기록)' AUTO_INCREMENT=100;


-- ======================================================================
-- TABLE: payables
-- DESC : AP 정산 처리 요청 단위. 지급 요청(PAYMENT)과 환불 확인 요청(REFUND)을 모두 표현한다.
-- NOTE : payables는 내부 AP 정산 처리 요청이다(승인/보류/처리 대기의 기준).
--        테이블명은 payable이지만, 운영 의미는 "payment 관련 처리 요청"으로 해석한다.
-- NOTE : payables는 항상 costs 1건을 근거로 생성한다. cost 1건은 여러 payables로 나뉠 수 있다.
-- NOTE : payables 1건은 payments 1건으로 처리된다(1:1 불변). 여러 cost를 한 payable로 묶지 않는다.
-- NOTE : pbl_request_type으로 요청 성격을 구분한다.
--        PAYMENT: 비용 지급 처리 요청
--        REFUND : negative refund cost에 대해 환불 입금/카드취소 확인을 요청
-- NOTE : 비용 발생/요청 주체가 payable을 취소(CANCELLED)할 수 있는 것은 CREATED 상태뿐이다.
--        APPROVED는 재무담당자가 언제든 오프라인 지급할 수 있는 실행 가능 상태이므로,
--        cost 취소를 이유로 업무 주체가 임의로 CANCELLED로 되돌리면 실제 지급과 데이터가 어긋날 수 있다.
--        APPROVED/ON_HOLD 이후의 CANCELLED 전환은 재무담당자가 오프라인 지급 여부를 확인하고,
--        협의/정정 근거를 남긴 뒤 수행하는 예외 업무로만 허용한다.
-- NOTE : ON_HOLD는 요청 해석 보류가 아니라 승인 판단의 한 종류이다.
--        재무담당자가 즉시 지급 처리할 APPROVED와 달리, 정기결제/일괄결제처럼
--        나중에 모아서 처리할 건을 업무 화면의 즉시 처리 목록에서 분리하기 위한 상태이다.
-- ======================================================================
CREATE TABLE payables (
  pbl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'AP 정산 처리 요청 PK(payable)',
  pbl_ct_sn BIGINT UNSIGNED NOT NULL COMMENT '근거 비용 PK(costs). payable은 반드시 하나의 cost를 근거로 한다.',
  pbl_request_type ENUM('PAYMENT','REFUND')
    NOT NULL DEFAULT 'PAYMENT' COMMENT 'AP 정산 처리 요청 유형(ENUM) | PAYMENT:비용 지급 요청, REFUND:환불/차감 확인 요청',

  pbl_payee_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '정산 상대 업체 PK(parties). PAYMENT는 지급 대상, REFUND는 환불/차감 확인 대상이다.',
--  pbl_payee_bk_sn BIGINT UNSIGNED NULL COMMENT '정산 상대 계좌 PK(bank_accounts). PAYMENT는 지급 예정 수취 계좌, REFUND는 환불 출처/확인 참고 계좌로 사용할 수 있다.',
  pbl_bank_name VARCHAR(80) NULL COMMENT '정산 당시 은행명 스냅샷. pay_method=TRANSFER일 때 bank_accounts에서 복사하거나 수동 입력한다.',
  pbl_account_number VARCHAR(80) NULL COMMENT '정산 당시 계좌번호 스냅샷. 통장 조회/거래처 매칭과 과거 payables 표시의 기준으로 사용한다.',
  pbl_account_holder_name VARCHAR(120) NULL COMMENT '정산 당시 예금주/계좌명 스냅샷. bank_accounts 변경/거래처 통합 이후에도 payables 당시 정보를 보존한다.',

  pbl_status ENUM('CREATED','APPROVED','ON_HOLD','PROCESSED','REJECTED', 'CANCELLED')
    NOT NULL DEFAULT 'CREATED'
    COMMENT 'AP 정산 처리 요청 상태(ENUM) | CREATED:작성/요청됨, APPROVED:승인 및 즉시 처리 대상, ON_HOLD:승인되었으나 정기/일괄 처리 대상으로 보류, PROCESSED:처리 완료, REJECTED:반려, CANCELLED:취소(CREATE상태시에만 담당자가 취소 가능)',

  pbl_requested_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '요청자 PK(assignees) | 구매/운영/재무 등',
  pbl_responded_by_a_sn BIGINT UNSIGNED NULL COMMENT '처리자(승인/반려) PK(assignees) | 승인/반려 시 설정',

  pbl_requested_at DATETIME NOT NULL COMMENT 'AP 정산 처리 요청일시(업무 이벤트)',
  pbl_responded_at DATETIME NULL COMMENT '승인/반려 일시(업무 이벤트)',
  pbl_due_at DATE NULL COMMENT '처리 예정일/기한(업무 이벤트). PAYMENT는 지급 예정일, REFUND는 환불 확인 목표일',

  pbl_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '정산 통화',
  pbl_total_amount DECIMAL(18,2) NOT NULL COMMENT '정산 처리 요청 금액. 항상 양수로 저장하고, 지급/환불 방향은 pbl_request_type으로 해석한다.',

  pbl_note VARCHAR(500) NULL COMMENT '재무 메모 (자유 메모)',
  pbl_req_note VARCHAR(500) NULL COMMENT '재무 메모 (요청자용)',
  pbl_res_note VARCHAR(500) NULL COMMENT '재무 메모(승인자용)',

  pbl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pbl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pbl_sn),
  KEY idx_payables_cost (pbl_ct_sn),
  KEY idx_payables_payee (pbl_payee_pt_sn),
  KEY idx_payables_type_status (pbl_request_type, pbl_status),
  KEY idx_payables_due (pbl_due_at),
  KEY idx_payables_requested_by (pbl_requested_by_a_sn),

  CONSTRAINT fk_payables_cost
    FOREIGN KEY (pbl_ct_sn) REFERENCES costs(ct_sn),
  CONSTRAINT fk_payables_payee
    FOREIGN KEY (pbl_payee_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_payables_requested_by
    FOREIGN KEY (pbl_requested_by_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_payables_responded_by
    FOREIGN KEY (pbl_responded_by_a_sn) REFERENCES assignees(a_sn)
) COMMENT='AP 정산 처리 요청 단위. 지급 요청(PAYMENT)과 환불 확인 요청(REFUND)을 모두 표현한다.' AUTO_INCREMENT=100;

/* =======================================================================
 * 6) Payments(AP 정산 결과) <-> Payables(AP 정산 처리 요청) 연결(운영 정책: 1:1)
 *    - cost 1건은 여러 payables로 나눠 정산 처리 요청할 수 있다.
 *    - payables 1건은 payments.pay_pbl_sn으로 payment 1건에만 연결된다(1:1 불변).
 *    - 실제 사람이 여러 번 처리했더라도 ERP 데이터상 payment는 payable 1건당 1건만 기록한다.
 *    - CARD 즉시 결제는 payables 없이 payments.pay_ct_sn으로 costs에 바로 연결된다.
 *    - TRANSFER 지급과 REFUND 환불 확인은 payables를 거쳐 payments.pay_pbl_sn으로 연결된다.
 *    - CASH는 현재 비용 등록만 허용하며 payments에는 기록하지 않는다.
 * ======================================================================= */

ALTER TABLE payments
  ADD CONSTRAINT fk_payments_payable
    FOREIGN KEY (pay_pbl_sn) REFERENCES payables(pbl_sn);


-- ======================================================================
-- TABLE: finance_history_events
-- DESC : 재무 처리 이력 이벤트(화면 표시용 스냅샷)
-- NOTE : finance_history_events는 통합비용관리 상세 패널의 처리 이력 타임라인을 위한 이벤트 스냅샷 테이블이다.
-- NOTE : 모든 row는 costs.ct_sn을 조회 anchor로 가진다.
-- NOTE : 화면 조회 시 다른 업무 테이블 조인을 지양하기 위해 사건 금액, 담당자명, 발생시각, 상세 문구를 insert 시점에 기록한다.
-- NOTE : target_type/target_sn은 원천 추적용 참조이며, 화면 구성을 위한 필수 join 기준이 아니다.
-- NOTE : 이벤트별 값 기록 기준
--        - COST_CREATED       : 금액=ct_price+ct_tax, 담당자=비용 등록자명, 일시=비용 등록 완료 시각, 상세=현재 상세값 없음 또는 비용 메모 검토, target=COSTS/ct_sn
--        - PAYABLE_REQUESTED  : 금액=pbl_total_amount, 담당자=기안자명, 일시=pbl_requested_at, 상세=pbl_req_note, target=PAYABLES/pbl_sn
--        - PAYABLE_REJECTED   : 금액=pbl_total_amount, 담당자=응답자명, 일시=pbl_responded_at, 상세=pbl_res_note, target=PAYABLES/pbl_sn
--        - PAYABLE_APPROVED   : 금액=pbl_total_amount, 담당자=응답자명, 일시=pbl_responded_at, 상세=pbl_res_note, target=PAYABLES/pbl_sn
--        - TRANSFER_COMPLETED : 금액=pay_amount, 담당자=처리자명, 일시=pay_paid_at, 상세=pay_note, target=PAYMENTS/pay_sn
--        - CARD_SUBMITTED     : 금액=pay_amount, 담당자=제출자명, 일시=카드 제출 완료 시각, 상세=UI에서 추가 입력받은 텍스트, target=PAYMENTS/pay_sn
--        - CASH_REPORTED      : 금액=ct_price+ct_tax, 담당자=현금보고 버튼을 누른 사용자명, 일시=현금보고 버튼을 누른 시각, 상세=UI에서 추가 입력받은 텍스트, target=COSTS/ct_sn
--        - REFUND_COST_CREATED: 금액=환불 cost 총액, 담당자=환불 비용 등록자명, 일시=환불 비용 등록 완료 시각, 상세=현재 상세값 없음 또는 비용 메모 검토, target=COSTS/refund ct_sn
--        - REFUND_REQUESTED   : 금액=환불 요청금액, 담당자=요청자명, 일시=환불 처리 요청 시각, 상세=pbl_req_note, target=PAYABLES/pbl_sn
--        - REFUND_CONFIRMED   : 금액=pay_amount, 담당자=처리자명, 일시=pay_paid_at, 상세=pay_note, target=PAYMENTS/pay_sn
--        - PAYABLE_CANCELLED  : 금액=pbl_total_amount, 담당자=지급요청 취소 액션 수행자명, 일시=지급요청 취소 액션 수행 시각, 상세=UI에서 추가 입력받은 텍스트, target=PAYABLES/pbl_sn
--        - COST_CANCELLED     : 금액=ct_price+ct_tax, 담당자=비용 취소 액션 수행자명, 일시=비용 취소 액션 수행 시각, 상세=UI에서 추가 입력받은 텍스트, target=COSTS/ct_sn
-- ======================================================================
CREATE TABLE finance_history_events (
  fhe_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '재무 처리 이력 이벤트 PK',
  fhe_ct_sn BIGINT UNSIGNED NOT NULL COMMENT '이력 조회 기준 비용 PK(costs.ct_sn). 모든 재무 처리 이력은 특정 cost 기준으로 조회된다.',

  fhe_event_type ENUM(
    'COST_CREATED',
    'PAYABLE_REQUESTED',
    'PAYABLE_REJECTED',
    'PAYABLE_APPROVED',
    'TRANSFER_COMPLETED',
    'CARD_SUBMITTED',
    'CASH_REPORTED',
    'REFUND_COST_CREATED',
    'REFUND_REQUESTED',
    'REFUND_CONFIRMED',
    'PAYABLE_CANCELLED',
    'COST_CANCELLED'
  ) NOT NULL COMMENT '재무 처리 이력 이벤트 유형(ENUM) | COST_CREATED:비용 등록, PAYABLE_REQUESTED:지급요청 기안, PAYABLE_REJECTED:지급요청 반려, PAYABLE_APPROVED:지급 승인, TRANSFER_COMPLETED:이체 완료, CARD_SUBMITTED:카드 제출 완료, CASH_REPORTED:현금 보고 완료, REFUND_COST_CREATED:환불 비용 등록, REFUND_REQUESTED:환불 처리 요청, REFUND_CONFIRMED:환불 확인 완료, PAYABLE_CANCELLED:지급요청 취소, COST_CANCELLED:비용 취소. 화면 제목/강조/아이콘 선택 기준이며, 이벤트 발생 시 서비스가 세팅한다.',

  fhe_event_amount DECIMAL(18,2) NOT NULL COMMENT '사건 금액. 이벤트 발생 시점에 화면에 표시할 금액을 스냅샷으로 저장',
  fhe_event_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '사건 금액 통화',
  fhe_actor_name VARCHAR(100) NOT NULL COMMENT '사건 담당자명. 화면 표시 안정성을 위해 이벤트 발생 시점의 이름을 저장',
  fhe_occurred_at DATETIME NOT NULL COMMENT '사건 발생시각(업무 이벤트 시각). 화면 표시값',
  fhe_detail_text VARCHAR(500) NULL COMMENT '사건 상세 문구. 반려 사유, 승인 의견, 거래번호, UI 입력 텍스트 등 이벤트별 상세 표시값',

  fhe_target_type VARCHAR(30) NULL COMMENT '원천 추적용 대상 타입. Allowed values: COSTS, PAYABLES, PAYMENTS. 이벤트 발생 시 서비스가 세팅한다.',
  fhe_target_sn BIGINT UNSIGNED NULL COMMENT '원천 추적용 대상 PK 값. fhe_target_type에 의해 해석되는 동적 참조 키',

  fhe_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',

  PRIMARY KEY (fhe_sn),
  KEY idx_fhe_ct_sn (fhe_ct_sn),
  CONSTRAINT fk_fhe_cost
    FOREIGN KEY (fhe_ct_sn) REFERENCES costs(ct_sn)
) COMMENT='재무 처리 이력 이벤트(화면 표시용 스냅샷)' AUTO_INCREMENT=100;


CREATE TABLE tax_invoices (
  ti_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '전자세금계산서 PK',
  ti_approval_no VARCHAR(50) NOT NULL COMMENT '승인번호/승인키(외부 정본 식별자)',
  ti_issue_dt DATE NOT NULL COMMENT '작성일/발급일',
  ti_status ENUM('NORMAL','MODIFIED','CANCELLED') NOT NULL DEFAULT 'NORMAL'
    COMMENT '상태: NORMAL(정상), MODIFIED(수정), CANCELLED(취소/무효)',

  ti_supplier_biz_no VARCHAR(20) NOT NULL COMMENT '공급자 사업자번호(문자열)',
  ti_buyer_biz_no VARCHAR(20) NOT NULL COMMENT '공급받는자 사업자번호(문자열)',

  ti_supply_amount DECIMAL(18,3) NOT NULL COMMENT '공급가액',
  ti_tax_amount DECIMAL(18,3) NOT NULL COMMENT '세액',
  ti_total_amount DECIMAL(18,3) NOT NULL COMMENT '합계금액(공급가+세액)',
  ti_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화(기본 KRW)',

  ti_recon_status ENUM('UNMATCHED','PARTIAL','MATCHED') NOT NULL DEFAULT 'UNMATCHED'
    COMMENT '대사 상태(서비스 판단): UNMATCHED(미매칭), PARTIAL(부분), MATCHED(완료)',

  ti_note VARCHAR(500) NULL COMMENT '비고',
  ti_source VARCHAR(50) NOT NULL DEFAULT 'HOMETAX_API' COMMENT '수신 소스',

  ti_create_dt DATETIME NOT NULL COMMENT '생성일시',
  ti_update_dt DATETIME NOT NULL COMMENT '수정일시',

  PRIMARY KEY (ti_sn),
  UNIQUE KEY uk_ti_approval_no (ti_approval_no),
  KEY idx_ti_issue_dt (ti_issue_dt),
  KEY idx_ti_recon_status (ti_recon_status)
) COMMENT='전자세금계산서(세무 정본) - payments 대사 중심' AUTO_INCREMENT=100;

CREATE TABLE tax_invoice_payment_allocations (
  tipa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '세금계산서↔AP 정산 결과 대사 배분 PK',
  tipa_ti_sn BIGINT UNSIGNED NOT NULL COMMENT '전자세금계산서 PK(tax_invoices)',
  tipa_pay_sn BIGINT UNSIGNED NOT NULL COMMENT 'AP 정산 결과 PK(payments). 지급(PAYMENT)과 환불(REFUND)을 모두 대사할 수 있다.',

  tipa_amount DECIMAL(18,3) NOT NULL COMMENT '대사 매칭 금액(부분 매칭 허용). 항상 총액 기준 양수로 저장하고, 지급/환불 방향은 payments.pay_tx_type으로 해석한다.',
  tipa_note VARCHAR(500) NULL COMMENT '비고(매칭 규칙/사유/수동조정 메모)',

  tipa_create_dt DATETIME NOT NULL COMMENT '생성일시',
  tipa_update_dt DATETIME NOT NULL COMMENT '수정일시',

  PRIMARY KEY (tipa_sn),

  -- 같은 ti↔pay 조합이 여러 줄로 쪼개질 필요는 없으므로(부분은 amount로 표현),
  -- 실수 방지로 유니크 권장. (정말 여러 줄이 필요하면 이 제약 제거)
  UNIQUE KEY uk_tipa (tipa_ti_sn, tipa_pay_sn),

  KEY idx_tipa_ti (tipa_ti_sn),
  KEY idx_tipa_pay (tipa_pay_sn),

  CONSTRAINT fk_tipa_ti FOREIGN KEY (tipa_ti_sn) REFERENCES tax_invoices(ti_sn),
  CONSTRAINT fk_tipa_pay FOREIGN KEY (tipa_pay_sn) REFERENCES payments(pay_sn)
) COMMENT='전자세금계산서↔AP 정산 결과(payments) 대사 배분(부분 매칭/N:M 지원). 세금계산서 총액과 실제 지급/환불 총액을 대사한다.' AUTO_INCREMENT=100;
