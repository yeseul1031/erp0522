/* ============================================================================
 * Balhea ERP — Finance Schema (DDL)
 * ----------------------------------------------------------------------------
 * [이 파일의 성격]
 * - 본 파일은 Balhea ERP 스키마 중 "finance" 레이어에 해당한다.
 * - 계약/주문/수급의 실행 결과를 금액, 정산, 지급, 비용, 회계 관점에서
 *   기록·해석·집계하기 위한 엔티티들을 정의한다.
 * - 본 레이어는 업무 흐름을 생성하지 않으며,
 *   contracts / sourcing 레이어에서 생성된 사실(fact)을 재해석하는 역할을 한다.
 *
 * ----------------------------------------------------------------------------
 * [의존 관계 — 중요]
 * - 본 파일은 다음 schema들을 전제로 한다:
 *   - erp_core_schema.sql
 *     : 조직, 담당자, 거래처, 물품, 문서, 변경이력 등 공통 기준 엔티티
 *   - erp_contracts_schema.sql
 *     : 계약, 주문, 수급, RFQ, PO 등 업무 실행의 정본 엔티티
 *
 * - 본 파일에는 위 엔티티들의 정의를 포함하지 않으며,
 *   참조/연결/집계만 수행한다.
 *
 * ----------------------------------------------------------------------------
 * [finance 레이어의 설계 관점]
 * - finance 레이어는 "무엇을 얼마에 샀는가 / 팔았는가"를
 *   독립적으로 정의하지 않는다.
 *
 * - 비용(costs) 원장, 비용 귀속(cost_allocations),
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
 * - *_links 테이블은 조회 및 편의를 위한 관계 표현이다.
 * - *_allocations 테이블은
 *   원가 계산, 회계 처리, 정산의 기준이 되는 수치적 귀속을 의미한다.
 *
 * - finance 계산과 집계는
 *   *_links가 아니라 *_allocations를 기준으로 수행해야 한다.
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
- 기존 cost/payable/payment 는 "지출(AP)" 도메인이다.
- 이번 receivable/receipt 는 "수금(AR)" 도메인이다.
  - receivables : 우리가 받아야 할 돈(채권/정산 단위; 수금 바구니)
  - receipts     : 실제로 돈이 들어온 행위(입금 이벤트; 분할 수금 가능)

[요구사항 핵심]
- receivable이 먼저 생성되고, 나중에 어떤 order_line이 포함될지 결정된다.
- 하나의 order_line은 여러 receivable에 나뉘어 붙지 않는다.
  - 즉, order_line은 receivable에 최대 1번만 포함(0..1)
- receivable은 여러 order_line을 포함할 수 있다(1..N)

따라서:
- order_lines에 FK를 두지 않고(레이어 의존성 최소화),
- 링크 테이블 receivable_order_line_links 로 연결하며,
- DB 제약 UNIQUE(rol_ol_sn) 으로 "order_line은 receivable 하나만"을 강제한다.

[레이어 철학 유지]
(계약/납품: order_lines) <--- 분리 ---> (수급) <--- 분리 ---> (견적/발주) <--- 분리 ---> (배송)
그리고 수금(AR)은 order_lines를 "묶어서" 관리하지만,
order_lines 스키마 자체에 수금 FK를 주입하지 않는다(의존성 최소).

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
- receivable_order_line_links.rol_ol_sn 에 UNIQUE 걸어서 DB 강제

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
-- DESC : 수금/정산(채권) 헤더. “우리가 받아야 할 돈”의 단위. (지출의 payables와 개념적으로 대칭)
-- =============================================================================
CREATE TABLE receivables (
  recv_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수금(정산/채권) PK',

  recv_p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 FK (projects.p_sn). 수금은 프로젝트에 귀속됨(최상위 추적 기준)',
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

  KEY idx_recv_p_sn (recv_p_sn),
  KEY idx_recv_customer (recv_customer_pt_sn),
  KEY idx_recv_status (recv_status),
  KEY idx_recv_due (recv_due_dt),

  CONSTRAINT fk_recv_project
    FOREIGN KEY (recv_p_sn) REFERENCES projects(p_sn),

  CONSTRAINT fk_recv_customer
    FOREIGN KEY (recv_customer_pt_sn) REFERENCES parties(pt_sn)

) COMMENT='수금/정산(채권) 헤더. order_lines를 묶는 단위이며, 실제 수금 이벤트는 receipts로 기록.';



-- =============================================================================
-- TABLE: receivable_order_line_links
-- DESC : receivable ↔ order_line 연결(정본). order_line은 receivable 하나에만 포함되도록 UNIQUE로 강제.
-- =============================================================================
CREATE TABLE receivable_order_line_links (
  rol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수금-주문항목 링크 PK',

  rol_recv_sn BIGINT UNSIGNED NOT NULL COMMENT '수금(정산) FK (receivables.recv_sn)',
  rol_ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문항목 FK (order_lines.ol_sn). UNIQUE로 “하나의 order_line은 receivable 하나만” 강제',

  rol_create_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  rol_update_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',

  PRIMARY KEY (rol_sn),

  UNIQUE KEY uq_rol_ol_sn (rol_ol_sn),          -- 핵심 제약: order_line은 receivable 하나만
  KEY idx_rol_recv_sn (rol_recv_sn),

  CONSTRAINT fk_rol_recv
    FOREIGN KEY (rol_recv_sn) REFERENCES receivables(recv_sn),

  CONSTRAINT fk_rol_ol
    FOREIGN KEY (rol_ol_sn) REFERENCES order_lines(ol_sn)

) COMMENT='수금(정산)과 주문항목 연결(정본). order_line은 receivable 하나에만 포함되도록 UNIQUE 강제.';



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

) COMMENT='실제 수금(입금) 이벤트. receivable에 대한 분할 수금 가능. 증빙은 documents+document_links.';



-- ======================================================================
-- TABLE: costs
-- DESC : 비용(원장)
-- NOTE : costs는 '비용 발생' 원장이다(사유/금액/발생일). 귀속/안분은 cost_allocations로만 관리한다(원장은 단순 유지).
-- NOTE : 비용은 프로젝트(p_sn)/주문라인(ol_sn)/override(olo_sn)/수급케이스(sc_sn) 등에 귀속될 수 있다(대상은 cost_allocations에서만 표현).
-- NOTE : 비용 증빙(영수증/세금계산서 등)은 documents/doc_links로 '비용 측 증빙'으로 연결한다(다중 첨부 가능).

-- ======================================================================
CREATE TABLE costs (
  ct_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '비용 PK',
  ct_type ENUM('PRODUCT','MATERIAL','SHIPPING','CUSTOMS','SERVICE','OTHER')
    NOT NULL COMMENT '비용 유형(ENUM) | PRODUCT:상품구매, MATERIAL:자재구매, SHIPPING:배송/운송, CUSTOMS:통관비, SERVICE:용역/수수료, OTHER:기타',
  ct_pt_sn BIGINT UNSIGNED NULL COMMENT '지출 대상 업체 PK(parties)',
  ct_occurred_at DATETIME NOT NULL COMMENT '지출 발생일시(업무 이벤트)',
  ct_amount DECIMAL(18,2) NOT NULL COMMENT '비용 금액',
  ct_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화',
  ct_note VARCHAR(500) NULL COMMENT '비용 설명',
  ct_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  ct_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ct_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ct_sn),
  KEY idx_costs_vendor (ct_pt_sn),
  KEY idx_costs_occurred_at (ct_occurred_at),
  CONSTRAINT fk_costs_vendor
    FOREIGN KEY (ct_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_costs_creator
    FOREIGN KEY (ct_a_sn) REFERENCES assignees(a_sn)
) COMMENT='비용(원장)';


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

  bk_is_primary TINYINT(1) NOT NULL DEFAULT 0 COMMENT '주 계좌 여부(0/1)',
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

  UNIQUE KEY uk_bk_pt_bank_acct (bk_pt_sn, bk_bank_name, bk_account_number)

  -- FK는 운영정책에 따라 선택
  -- ,CONSTRAINT fk_bank_accounts_pt FOREIGN KEY (bk_pt_sn) REFERENCES parties(pt_sn)
) COMMENT='거래처 수취 계좌(국내/해외 겸용, 송금 입력용 주소록)';



-- ======================================================================
-- TABLE: payments
-- DESC : 지급/결제(카드/이체/현금) 원장
-- NOTE : payments는 실제 지급 사건(카드/이체/현금)을 기록한다.
-- NOTE : 지급이 어떤 비용(들)을 얼마만큼 정산했는지는 payment_lines로만 연결한다(중복 저장 금지).
-- NOTE : 지급 증빙(이체확인/카드승인/정산내역 등)은 documents/doc_links로 '지급 측 증빙'으로 연결한다(다중 첨부 가능).

-- ======================================================================
CREATE TABLE payments (
  pay_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '지급/결제 PK',
  pay_method ENUM('CARD','TRANSFER','CASH')
    NOT NULL COMMENT '지급 수단(ENUM) | CARD:카드, TRANSFER:계좌이체, CASH:현금',
  pay_status ENUM('PENDING','PAID','CANCELLED')
    NOT NULL DEFAULT 'PAID' COMMENT '지급 상태(ENUM) | PENDING:대기, PAID:지급완료, CANCELLED:취소',
  pay_pt_sn BIGINT UNSIGNED NULL COMMENT '정산/지급 상대 업체 PK(parties) | 네이버/쿠팡 등 정산 주체, 비정형은 예약된 party 사용',
  pay_bk_sn BIGINT UNSIGNED NULL COMMENT '실제 이체 실행 시 사용된 거래처의 수취 계좌를 식별하는 외래키이다. 실제 지급 결과 기준의 계좌를 기록한다.',

  pay_paid_at DATETIME NOT NULL COMMENT '지급 완료일시(업무 이벤트)',
  pay_amount DECIMAL(18,2) NOT NULL COMMENT '지급 금액',
  pay_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화',
  pay_ref_no VARCHAR(32) NULL COMMENT '참조번호(카드 승인번호/이체 거래번호 등)',
  pay_note VARCHAR(500) NULL COMMENT '메모',
  pay_data_json JSON NULL COMMENT '추가 메타(JSON)',
  pay_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  pay_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pay_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (pay_sn),
  KEY idx_payments_paid_at (pay_paid_at),
  KEY idx_payments_payee (pay_pt_sn),
  CONSTRAINT fk_payments_payee
    FOREIGN KEY (pay_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_payments_creator
    FOREIGN KEY (pay_a_sn) REFERENCES assignees(a_sn)
) COMMENT='지급/결제(카드/이체/현금) 원장';


-- ======================================================================
-- TABLE: payment_lines
-- DESC : 지급과 비용의 매핑(다대다, 부분지급/일괄지급 지원)
-- NOTE : payment_lines는 payments(지급) ↔ costs(비용)를 금액으로 매핑한다(부분/분할 정산 포함).
-- NOTE : 선금/중도금/잔금 같은 '지급 단계'는 payment_lines.note(또는 UI 라벨)로만 표현한다(비용/PO-비용 링크에 중복 저장하지 않는다).
-- ======================================================================
CREATE TABLE payment_lines (
  pyl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '지급-비용 연결 PK',
  pyl_pay_sn BIGINT UNSIGNED NOT NULL COMMENT '지급 PK(payments)',
  pyl_ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs)',
  pyl_amount DECIMAL(18,2) NOT NULL COMMENT '이번 지급으로 해당 비용에 정산된 금액(부분/분할지급 지원)',
  pyl_note VARCHAR(500) NULL COMMENT '비고',
  pyl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pyl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (pyl_sn),
  UNIQUE KEY uk_payment_lines (pyl_pay_sn, pyl_ct_sn),
  KEY idx_payment_lines_pay (pyl_pay_sn),
  KEY idx_payment_lines_ct (pyl_ct_sn),
  CONSTRAINT fk_payment_lines_pay
    FOREIGN KEY (pyl_pay_sn) REFERENCES payments(pay_sn),
  CONSTRAINT fk_payment_lines_ct
    FOREIGN KEY (pyl_ct_sn) REFERENCES costs(ct_sn)
) COMMENT='지급과 비용의 매핑(다대다, 부분지급/일괄지급 지원)';


-- ======================================================================
-- TABLE: cost_allocations
-- DESC : 비용 배부(프로젝트/주문서/주문라인/override/수급케이스 단위 분배)
-- NOTE : 비용 귀속 대상은 p_sn/o_sn/ol_sn/olo_sn/sc_sn을 지원한다(비용 원장(ct_*)에는 귀속을 직접 저장하지 않는다).
-- NOTE : 퀵 비용(예: 카드결제 퀵비)은 PO가 아니라 'costs + cost_allocations'로만 귀속한다.
-- ======================================================================
CREATE TABLE cost_allocations (
  ca_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '비용 배부 PK',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs)',
  p_sn BIGINT UNSIGNED NULL COMMENT '프로젝트 PK(projects) | 여러 프로젝트 공통 비용이면 NULL 가능(배부 행 여러 개로 분해)',
  ol_sn BIGINT UNSIGNED NULL COMMENT '주문라인 PK(order_lines) | 특정 납품 항목을 위한 비용(검사/가공 등)',
  olo_sn BIGINT UNSIGNED NULL COMMENT '주문라인 override PK(order_line_overrides) | 희소 케이스 구성품/분할 단위 비용',
  sc_sn BIGINT UNSIGNED NULL COMMENT '수급케이스 PK(sourcing_cases) | 특정 수급(국내/해외/제작) 건에 귀속되는 비용',
  allocated_amount DECIMAL(18,2) NOT NULL COMMENT '배부 금액',
  ca_note VARCHAR(500) NULL COMMENT '비고',
  ca_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ca_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ca_sn),
  KEY idx_cost_allocations_ct (ct_sn),
  KEY idx_cost_allocations_p (p_sn),
  KEY idx_cost_allocations_ol (ol_sn),
  KEY idx_cost_allocations_olo (olo_sn),
  KEY idx_cost_allocations_sc (sc_sn),
  CONSTRAINT fk_cost_allocations_costs
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn),
  CONSTRAINT fk_cost_allocations_projects
    FOREIGN KEY (p_sn) REFERENCES projects(p_sn),
  CONSTRAINT fk_cost_allocations_order_lines
    FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn),
  CONSTRAINT fk_cost_allocations_order_line_overrides
    FOREIGN KEY (olo_sn) REFERENCES order_line_overrides(olo_sn),
  CONSTRAINT fk_cost_allocations_sourcing_cases
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='비용 배부(프로젝트/주문서/주문라인/override/수급케이스 단위 분배)';



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
) COMMENT='환율 스냅샷 정본 테이블 (과거 재현 가능해야 함)';



-- ======================================================================
-- TABLE: cost_fx_applications
-- DESC : 비용 환율 적용(적용환율 고정/감사용)
-- NOTE : 해외 비용은 정산 시점에 적용한 환율과 원화 환산 결과를 고정 저장해 재현/감사를 가능하게 한다.
-- NOTE : applied_fx_rate/as_of_dt/base_amount(KRW) 등은 '그 시점의 적용 결과'이며, 필요 시 fx_rates(fx_sn)로 환율 마스터를 참조한다.
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
) COMMENT='Cost와 환율 스냅샷 간 적용 관계 (링크 + 선택 사유만 기록)';


/* =======================================================================
 * Invoice / Payable 확장
 * -----------------------------------------------------------------------
 * - invoice(외부 청구/거래 문서) / payable(내부 지급 단위) / payment(실지급 결과) 모델
 * - invoice는 지급 단위가 아니며, 지급 단위는 payable
 * - payment는 실제 지급만 기록, 승인/보류/대기는 payable에서 관리
 * ======================================================================= */




-- ======================================================================
-- TABLE: po_cost_links
-- DESC : PO 1건 = cost 1건 정책을 위한 1:1 연결
-- NOTE : po_cost_links는 'PO에 연관된 비용을 빠르게 찾기 위한' 조회/편의 연결이다(원가/마진 계산의 기준이 아님).
-- NOTE : link_type는 지급 단계(선금/잔금)가 아니라 PO 관련 부대비용 성격 분류에만 사용한다(예: FREIGHT, CUSTOMS, INSPECTION, ETC).
-- ======================================================================
CREATE TABLE po_cost_links (
  pcl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PO-비용 1:1 연결 PK',
  po_sn BIGINT UNSIGNED NOT NULL COMMENT '발주서 PK(purchase_orders)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs) | (정책) PO 1건당 cost 1건',

  pcl_note VARCHAR(500) NULL COMMENT '비고(정책/예외 사유 등)',

  pcl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pcl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pcl_sn),
  UNIQUE KEY uk_po_cost_po (po_sn),
  UNIQUE KEY uk_po_cost_ct (ct_sn),
  KEY idx_po_cost_links_po (po_sn),
  KEY idx_po_cost_links_ct (ct_sn),

  CONSTRAINT fk_po_cost_links_po
    FOREIGN KEY (po_sn) REFERENCES purchase_orders(po_sn),
  CONSTRAINT fk_po_cost_links_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='PO 1건 = cost 1건 정책을 위한 1:1 연결';


/* =======================================================================
 * 2) Cost 첨부 문서(증빙) - 판매자별 영수증 다중 첨부 지원
 * ======================================================================= */


-- ======================================================================
-- TABLE: invoices
-- DESC : 인보이스/거래명세/세금계산서 등 외부 문서(지급 단위 아님)
-- NOTE : invoices는 외부 문서 컨테이너다(영수증/세금계산서/거래명세서 등). invoice 자체는 '지급 단위'가 아니다.
-- NOTE : invoice_type(유형) 코드는 주석(권장값)을 따른다. 지급/결재 상태는 payables에서 관리한다.
-- ======================================================================
CREATE TABLE invoices (
  inv_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '인보이스 PK(외부 문서 컨테이너)',

  inv_issuer_pt_sn BIGINT UNSIGNED NULL COMMENT '발행 주체 PK(parties) | 없거나 비정형이면 NULL',
  inv_issuer_name VARCHAR(200) NULL COMMENT '발행처 표시명(Party 미연결 시)',

  inv_invoice_type ENUM('STATEMENT','TAX_INVOICE','INVOICE','RECEIPT','OTHER') COMMENT '인보이스 유형(ENUM) | STATEMENT:거래명세, TAX_INVOICE:세금계산서, INVOICE:청구서, RECEIPT:영수증, OTHER:기타'
    NOT NULL DEFAULT 'INVOICE'
    COMMENT '문서 유형(ENUM) | STATEMENT:거래명세, TAX_INVOICE:세금계산서, INVOICE:청구서, RECEIPT:영수증, OTHER:기타',

  inv_doc_no VARCHAR(120) NULL COMMENT '문서번호(거래명세서 번호/세금계산서 번호 등)',
  inv_issued_at DATETIME NULL COMMENT '문서 발행일시(업무 이벤트)',
  inv_due_at DATE NULL COMMENT '문서상 지급기한(있으면)',

  inv_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '문서 통화',
  inv_subtotal_amount DECIMAL(18,2) NULL COMMENT '공급가액/소계(있으면)',
  inv_tax_amount DECIMAL(18,2) NULL COMMENT '세액(있으면)',
  inv_total_amount DECIMAL(18,2) NOT NULL COMMENT '총액',

  inv_note VARCHAR(500) NULL COMMENT '메모',

  inv_created_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  inv_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  inv_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (inv_sn),
  KEY idx_invoices_issuer (inv_issuer_pt_sn),
  KEY idx_invoices_issued_at (inv_issued_at),
  KEY idx_invoices_doc_no (inv_doc_no),

  CONSTRAINT fk_invoices_issuer
    FOREIGN KEY (inv_issuer_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_invoices_creator
    FOREIGN KEY (inv_created_by_a_sn) REFERENCES assignees(a_sn)) COMMENT='인보이스/거래명세/세금계산서 등 외부 문서(지급 단위 아님)';


-- ======================================================================
-- TABLE: invoice_lines
-- DESC : 인보이스 라인(GOODS/CHARGE). invoice는 지급단위가 아니므로 지급 연결은 payables에서 수행
-- NOTE : invoice_lines는 invoices의 문서 라인이다(재화/비용 항목 등).
-- NOTE : line_type 권장: GOODS/CHARGE. charge_category는 권장 표준값을 주석에 두고 확장 가능(VARCHAR+COMMENT)으로 운용한다.
-- ======================================================================
CREATE TABLE invoice_lines (
  invl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '인보이스 라인 PK',
  invl_inv_sn BIGINT UNSIGNED NOT NULL COMMENT '인보이스 PK(invoices)',
  invl_line_no INT NOT NULL COMMENT '문서 내 라인번호',

  invl_line_type ENUM('GOODS','CHARGE') COMMENT '라인 유형(ENUM) | GOODS:상품/재화, CHARGE:부대비용/수수료'
    NOT NULL COMMENT '라인 유형(ENUM) | GOODS:물품, CHARGE:부대비용/서비스/세금/할인 등',

  /* GOODS 라인 연결(선택) */
  po_sn BIGINT UNSIGNED NULL COMMENT '관련 PO PK(purchase_orders) | 문서가 PO 단위로 묶일 때 선택',
  invl_pol_sn BIGINT UNSIGNED NULL COMMENT '관련 PO 라인 PK(po_lines) | 가능하면 연결(선택)',

  /* CHARGE 라인 연결(선택) */
  ct_sn BIGINT UNSIGNED NULL COMMENT '관련 비용 PK(costs) | 배송비/통관비 등 비용으로 이미 관리되는 경우 연결(선택)',
  invl_charge_category VARCHAR(40) NULL COMMENT 'CHARGE 세부 분류(텍스트/코드) | 예: SHIPPING_DOMESTIC, CUSTOMS_DUTY, SERVICE_FEE, TAX, DISCOUNT | 권장 charge_category(확장 가능): SHIPPING_DOMESTIC/SHIPPING_INTERNATIONAL/CUSTOMS_DUTY/CUSTOMS_BROKER_FEE/INSPECTION_FEE/WAREHOUSE_FEE/PACKAGING_FEE/INSURANCE_FEE/HANDLING_FEE/SERVICE_FEE/TAX/DISCOUNT/OTHER',

  invl_description VARCHAR(500) NULL COMMENT '라인 설명(품목명/서비스명/비고)',
  invl_qty DECIMAL(14,3) NULL COMMENT '수량(있으면)',
  invl_unit_price DECIMAL(18,2) NULL COMMENT '단가(있으면)',
  invl_amount DECIMAL(18,2) NOT NULL COMMENT '라인 금액(할인 등은 음수 가능)',
  invl_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '라인 통화(기본: invoices.ccy)',

  invl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  invl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (invl_sn),
  UNIQUE KEY uk_invoice_lines (invl_inv_sn, invl_line_no),
  KEY idx_invoice_lines_inv (invl_inv_sn),
  KEY idx_invoice_lines_po (po_sn),
  KEY idx_invoice_lines_pol (invl_pol_sn),
  KEY idx_invoice_lines_ct (ct_sn),
  KEY idx_invoice_lines_type (invl_line_type),
  KEY idx_invoice_lines_charge_cat (invl_charge_category),

  CONSTRAINT fk_invoice_lines_inv
    FOREIGN KEY (invl_inv_sn) REFERENCES invoices(inv_sn),
  CONSTRAINT fk_invoice_lines_po
    FOREIGN KEY (po_sn) REFERENCES purchase_orders(po_sn),
  CONSTRAINT fk_invoice_lines_pol
    FOREIGN KEY (invl_pol_sn) REFERENCES po_lines(pol_sn),
  CONSTRAINT fk_invoice_lines_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)) COMMENT='인보이스 라인(GOODS/CHARGE). invoice는 지급단위가 아니므로 지급 연결은 payables에서 수행';


/* =======================================================================
 * 4) Payables(내부 지급 단위) + Allocations
 * ======================================================================= */


-- ======================================================================
-- TABLE: payables
-- DESC : 지급 단위(payable). invoice는 지급단위가 아니며, payment는 결과만 기록
-- NOTE : payables는 내부 '지급 단위'다(결재/보류/대기/분할지급의 기준).
-- NOTE : 승인/보류/부분지급/완료 같은 상태는 payables에만 둔다(실지급 결과는 payments).
-- ======================================================================
CREATE TABLE payables (
  pbl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '지급요청/지급단위 PK(payable)',

  pbl_payee_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '지급 대상 업체 PK(parties) | 송금/정산 상대',
  pbl_payee_bk_sn BIGINT UNSIGNED NULL COMMENT '지급 예정인 금액을 수취할 거래처의 계좌를 식별하는 외래키이다. 지급 승인 시점에 지정된 수취 계좌를 의미한다.',

  pbl_payable_status ENUM('CREATED','APPROVED','ON_HOLD','PARTIALLY_PAID','PAID','CANCELLED') COMMENT '지급 단위 상태(ENUM) | CREATED:생성, APPROVED:승인, ON_HOLD:보류, PARTIALLY_PAID:부분지급, PAID:완료, CANCELLED:취소'
    NOT NULL DEFAULT 'CREATED'
    COMMENT '지급 상태(ENUM) | CREATED:작성, APPROVED:승인, ON_HOLD:보류, PARTIALLY_PAID:부분지급, PAID:완료, CANCELLED:취소',

  pbl_requested_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '요청자 PK(assignees) | 구매/운영/재무 등',
  pbl_approved_by_a_sn BIGINT UNSIGNED NULL COMMENT '승인자 PK(assignees) | 승인 시 설정',

  pbl_requested_at DATETIME NOT NULL COMMENT '지급 요청일시(업무 이벤트)',
  pbl_approved_at DATETIME NULL COMMENT '승인일시(업무 이벤트)',
  pbl_due_at DATE NULL COMMENT '지급 예정/기한(업무 이벤트)',

  pbl_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '지급 통화',
  pbl_total_amount DECIMAL(18,2) NOT NULL COMMENT '지급 대상 총액(업무 기준)',

  /* 편의 필드(선택): payments 합산으로도 계산 가능 */
  paid_amount DECIMAL(18,2) NOT NULL DEFAULT 0 COMMENT '지급 완료 누적액(편의). 실제 값은 payment_payable_allocations 합으로도 검증 가능',

  pbl_note VARCHAR(500) NULL COMMENT '재무 메모(지급 사유/특이사항)',

  pbl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pbl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pbl_sn),
  KEY idx_payables_payee (pbl_payee_pt_sn),
  KEY idx_payables_status (pbl_payable_status),
  KEY idx_payables_due (pbl_due_at),
  KEY idx_payables_requested_by (pbl_requested_by_a_sn),

  CONSTRAINT fk_payables_payee
    FOREIGN KEY (pbl_payee_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_payables_requested_by
    FOREIGN KEY (pbl_requested_by_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_payables_approved_by
    FOREIGN KEY (pbl_approved_by_a_sn) REFERENCES assignees(a_sn)) COMMENT='지급 단위(payable). invoice는 지급단위가 아니며, payment는 결과만 기록';


-- ======================================================================
-- TABLE: payable_invoice_allocations
-- DESC : payable이 어떤 invoice(들)을 어떤 금액으로 정산/지급하는지 배분(묶음/분할/부분 지급 지원)
-- NOTE : payable 1건이 여러 invoice를 포함할 수 있으며, 그 연결/귀속은 payable_invoice_allocations로 관리한다.
-- ======================================================================
CREATE TABLE payable_invoice_allocations (
  pbia_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'payable-invoice 배분 PK',
  pbl_sn BIGINT UNSIGNED NOT NULL COMMENT 'payable PK(payables)',
  inv_sn BIGINT UNSIGNED NOT NULL COMMENT 'invoice PK(invoices)',

  pbia_allocated_amount DECIMAL(18,2) NOT NULL COMMENT '이번 payable이 해당 invoice에서 커버하는 금액(부분/분할/묶음 지원)',
  pbia_note VARCHAR(500) NULL COMMENT '비고',

  pbia_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pbia_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pbia_sn),
  UNIQUE KEY uk_payable_invoice_alloc (pbl_sn, inv_sn),
  KEY idx_payable_invoice_alloc_pbl (pbl_sn),
  KEY idx_payable_invoice_alloc_inv (inv_sn),

  CONSTRAINT fk_payable_invoice_alloc_pbl
    FOREIGN KEY (pbl_sn) REFERENCES payables(pbl_sn),
  CONSTRAINT fk_payable_invoice_alloc_inv
    FOREIGN KEY (inv_sn) REFERENCES invoices(inv_sn)
) COMMENT='payable이 어떤 invoice(들)을 어떤 금액으로 정산/지급하는지 배분(묶음/분할/부분 지급 지원)';


-- ======================================================================
-- TABLE: payable_cost_allocations
-- DESC : payable이 어떤 cost(들)을 어떤 금액으로 정산/지급하는지 배분(프로젝트 원가(cost)와 지급(payable) 연결)
-- NOTE : payable 1건은 여러 cost에 안분/귀속될 수 있으며, 그 연결/귀속은 payable_cost_allocations로 관리한다.
-- ======================================================================
CREATE TABLE payable_cost_allocations (
  pbca_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'payable-cost 배분 PK',
  pbl_sn BIGINT UNSIGNED NOT NULL COMMENT 'payable PK(payables)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT 'cost PK(costs)',

  pbca_allocated_amount DECIMAL(18,2) NOT NULL COMMENT '이번 payable이 해당 cost에 대해 정산하는 금액(부분/분할/묶음 지원)',
  pbca_note VARCHAR(500) NULL COMMENT '비고',

  pbca_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pbca_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pbca_sn),
  UNIQUE KEY uk_payable_cost_alloc (pbl_sn, ct_sn),
  KEY idx_payable_cost_alloc_pbl (pbl_sn),
  KEY idx_payable_cost_alloc_ct (ct_sn),

  CONSTRAINT fk_payable_cost_alloc_pbl
    FOREIGN KEY (pbl_sn) REFERENCES payables(pbl_sn),
  CONSTRAINT fk_payable_cost_alloc_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='payable이 어떤 cost(들)을 어떤 금액으로 정산/지급하는지 배분(프로젝트 원가(cost)와 지급(payable) 연결)';


/* =======================================================================
 * 5) Payments(실지급 결과) <-> Payables(지급단위) 연결(ALTER 없이)
 *    - 1 payment가 여러 payable을 커버하거나, 1 payable이 여러 payment로 분할될 수 있다.
 * ======================================================================= */


-- ======================================================================
-- TABLE: payment_payable_allocations
-- DESC : payment(실지급 결과)와 payable(지급단위)의 배분 연결(ALTER 없이 1:N/N:1 지원)
-- NOTE : payment 1건이 여러 payable에 안분(또는 1:1)될 수 있으며, 그 연결/정산 귀속은 payment_payable_allocations로 관리한다.
-- ======================================================================
CREATE TABLE payment_payable_allocations (
  ppa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'payment-payable 배분 PK',
  pay_sn BIGINT UNSIGNED NOT NULL COMMENT 'payment PK(payments)',
  pbl_sn BIGINT UNSIGNED NOT NULL COMMENT 'payable PK(payables)',

  ppa_allocated_amount DECIMAL(18,2) NOT NULL COMMENT '이번 payment가 해당 payable에 귀속되는 금액(부분/분할/묶음 지원)',
  ppa_note VARCHAR(500) NULL COMMENT '비고',

  ppa_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ppa_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (ppa_sn),
  UNIQUE KEY uk_payment_payable_alloc (pay_sn, pbl_sn),
  KEY idx_payment_payable_alloc_pay (pay_sn),
  KEY idx_payment_payable_alloc_pbl (pbl_sn),

  CONSTRAINT fk_payment_payable_alloc_pay
    FOREIGN KEY (pay_sn) REFERENCES payments(pay_sn),
  CONSTRAINT fk_payment_payable_alloc_pbl
    FOREIGN KEY (pbl_sn) REFERENCES payables(pbl_sn)
) COMMENT='payment(실지급 결과)와 payable(지급단위)의 배분 연결(ALTER 없이 1:N/N:1 지원)';
