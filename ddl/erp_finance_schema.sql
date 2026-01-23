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
 */



-- ======================================================================
-- TABLE: costs
-- DESC : 비용(원장)
-- ======================================================================
CREATE TABLE costs (
  ct_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '비용 PK',
  ct_type ENUM('PRODUCT','MATERIAL','SHIPPING','CUSTOMS','SERVICE','OTHER')
    NOT NULL COMMENT '비용 유형(ENUM) | PRODUCT:상품구매, MATERIAL:자재구매, SHIPPING:배송/운송, CUSTOMS:통관비, SERVICE:용역/수수료, OTHER:기타',
  ct_pt_sn BIGINT UNSIGNED NULL COMMENT '지출 대상 업체 PK(parties)',
  ct_occurred_at DATETIME NOT NULL COMMENT '지출 발생일시(업무 이벤트)',
  ct_amount DECIMAL(18,2) NOT NULL COMMENT '비용 금액',
  ct_currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화',
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
  pt_sn BIGINT UNSIGNED NOT NULL COMMENT '거래처 FK: parties.pt_sn (이 계좌의 소유/수취 대상)',

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
  bk_currency_code CHAR(3) NULL COMMENT '통화코드(ISO 4217; 예: KRW, USD)',
  bk_swift_bic VARCHAR(20) NULL COMMENT 'SWIFT/BIC(해외송금; 예: BOFAUS3N)',
  bk_iban VARCHAR(34) NULL COMMENT 'IBAN(해외; EU 등)',
  bk_routing_number VARCHAR(32) NULL COMMENT 'Routing/ABA/Sort code 등 지역별 은행코드',
  bk_bank_address VARCHAR(128) NULL COMMENT '은행 주소(해외송금 시 필요할 수 있음)',
  bk_intermediary_bank_info VARCHAR(255) NULL COMMENT '중개은행 정보(옵션)',

  bk_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 시각',
  bk_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 시각',

  PRIMARY KEY (bk_sn),

  KEY idx_bk_pt (pt_sn, bk_is_active, bk_is_primary),
  KEY idx_bk_bank_account (bk_bank_name, bk_account_number),

  UNIQUE KEY uk_bk_pt_bank_acct (pt_sn, bk_bank_name, bk_account_number)

  -- FK는 운영정책에 따라 선택
  -- ,CONSTRAINT fk_bank_accounts_pt FOREIGN KEY (pt_sn) REFERENCES parties(pt_sn)
) COMMENT='거래처 수취 계좌(국내/해외 겸용, 송금 입력용 주소록)';



-- ======================================================================
-- TABLE: payments
-- DESC : 지급/결제(카드/이체/현금) 원장
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
  pay_currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화',
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
-- ======================================================================
CREATE TABLE payment_lines (
  pyl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '지급-비용 연결 PK',
  pay_sn BIGINT UNSIGNED NOT NULL COMMENT '지급 PK(payments)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs)',
  pyl_amount DECIMAL(18,2) NOT NULL COMMENT '이번 지급으로 해당 비용에 정산된 금액(부분/분할지급 지원)',
  pyl_note VARCHAR(500) NULL COMMENT '비고',
  pyl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pyl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (pyl_sn),
  UNIQUE KEY uk_payment_lines (pay_sn, ct_sn),
  KEY idx_payment_lines_pay (pay_sn),
  KEY idx_payment_lines_ct (ct_sn),
  CONSTRAINT fk_payment_lines_pay
    FOREIGN KEY (pay_sn) REFERENCES payments(pay_sn),
  CONSTRAINT fk_payment_lines_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='지급과 비용의 매핑(다대다, 부분지급/일괄지급 지원)';


-- ======================================================================
-- TABLE: cost_allocations
-- DESC : 비용 배부(프로젝트/주문서/주문라인/override/수급케이스 단위 분배)
-- ======================================================================
CREATE TABLE cost_allocations (
  ca_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '비용 배부 PK',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs)',
  p_sn BIGINT UNSIGNED NULL COMMENT '프로젝트 PK(projects) | 여러 프로젝트 공통 비용이면 NULL 가능(배부 행 여러 개로 분해)',
  o_sn BIGINT UNSIGNED NULL COMMENT '주문서 PK(orders) | 주문서 단위 비용(출장/접대 등)',
  ol_sn BIGINT UNSIGNED NULL COMMENT '주문라인 PK(order_lines) | 특정 납품 항목을 위한 비용(검사/가공 등)',
  olo_sn BIGINT UNSIGNED NULL COMMENT '주문라인 override PK(order_line_overrides) | 희소 케이스 구성품/분할 단위 비용',
  sc_sn BIGINT UNSIGNED NULL COMMENT '수급케이스 PK(sourcing_cases) | 특정 수급(국내/해외/제작) 건에 귀속되는 비용',
  allocated_amount DECIMAL(18,2) NOT NULL COMMENT '배부 금액',
  note VARCHAR(500) NULL COMMENT '비고',
  ca_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ca_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ca_sn),
  KEY idx_cost_allocations_ct (ct_sn),
  KEY idx_cost_allocations_p (p_sn),
  KEY idx_cost_allocations_o (o_sn),
  KEY idx_cost_allocations_ol (ol_sn),
  KEY idx_cost_allocations_olo (olo_sn),
  KEY idx_cost_allocations_sc (sc_sn),
  CONSTRAINT fk_cost_allocations_costs
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn),
  CONSTRAINT fk_cost_allocations_projects
    FOREIGN KEY (p_sn) REFERENCES projects(p_sn),
  CONSTRAINT fk_cost_allocations_orders
    FOREIGN KEY (o_sn) REFERENCES orders(o_sn),
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
-- ======================================================================
CREATE TABLE fx_rates (
  fx_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '환율 PK',
  base_currency CHAR(3) NOT NULL COMMENT '기준 통화(예: KRW)',
  quote_currency CHAR(3) NOT NULL COMMENT '상대 통화(예: USD)',
  fx_rate DECIMAL(18,8) NOT NULL COMMENT '환율 값(1 quote = fx_rate base)',
  as_of_dt DATETIME NOT NULL COMMENT '환율 기준일시(스냅샷)',
  source VARCHAR(100) NULL COMMENT '환율 출처(예: KEB, ECB, Fixer 등)',
  note VARCHAR(200) NULL COMMENT '비고',
  fx_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  fx_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (fx_sn),
  UNIQUE KEY uk_fx_rates (base_currency, quote_currency, as_of_dt),
  KEY idx_fx_rates_pair (base_currency, quote_currency),
  KEY idx_fx_rates_as_of (as_of_dt)
) COMMENT='환율 스냅샷(재현/감사 목적)';


-- ======================================================================
-- TABLE: cost_fx_applications
-- DESC : 비용 환율 적용(적용환율 고정/감사용)
-- ======================================================================
CREATE TABLE cost_fx_applications (
  cfxa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '비용 환율 적용 PK',
  c_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs)',

  src_currency CHAR(3) NOT NULL COMMENT '원 통화(예: USD)',
  src_amount DECIMAL(18,2) NOT NULL COMMENT '원 금액',

  base_currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '환산 기준 통화(기본 KRW)',
  fx_sn BIGINT UNSIGNED NULL COMMENT '적용 환율 PK(fx_rates) | 선택(숫자 직접 저장해도 됨)',
  applied_fx_rate DECIMAL(18,8) NOT NULL COMMENT '적용 환율 값(재현용, 필수)',
  as_of_dt DATETIME NOT NULL COMMENT '적용 환율 기준일시(재현용)',

  base_amount DECIMAL(18,2) NOT NULL COMMENT '환산 금액(예: KRW)',

  cfxa_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  cfxa_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (cfxa_sn),
  UNIQUE KEY uk_cost_fx_applications (c_sn),
  KEY idx_cost_fx_applications_fx (fx_sn),

  CONSTRAINT fk_cost_fx_applications_c FOREIGN KEY (c_sn) REFERENCES costs(c_sn),
  CONSTRAINT fk_cost_fx_applications_fx FOREIGN KEY (fx_sn) REFERENCES fx_rates(fx_sn)
) COMMENT='비용 환율 적용(적용환율 고정/감사용)';

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
-- ======================================================================
CREATE TABLE po_cost_links (
  pcl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PO-비용 1:1 연결 PK',
  po_sn BIGINT UNSIGNED NOT NULL COMMENT '발주서 PK(purchase_orders)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs) | (정책) PO 1건당 cost 1건',

  note VARCHAR(500) NULL COMMENT '비고(정책/예외 사유 등)',

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
-- ======================================================================
CREATE TABLE invoices (
  inv_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '인보이스 PK(외부 문서 컨테이너)',

  issuer_pt_sn BIGINT UNSIGNED NULL COMMENT '발행 주체 PK(parties) | 없거나 비정형이면 NULL',
  issuer_name VARCHAR(200) NULL COMMENT '발행처 표시명(Party 미연결 시)',

  invoice_type ENUM('STATEMENT','TAX_INVOICE','INVOICE','RECEIPT','OTHER')
    NOT NULL DEFAULT 'INVOICE'
    COMMENT '문서 유형(ENUM) | STATEMENT:거래명세, TAX_INVOICE:세금계산서, INVOICE:청구서, RECEIPT:영수증, OTHER:기타',

  doc_no VARCHAR(120) NULL COMMENT '문서번호(거래명세서 번호/세금계산서 번호 등)',
  issued_at DATETIME NULL COMMENT '문서 발행일시(업무 이벤트)',
  due_at DATE NULL COMMENT '문서상 지급기한(있으면)',

  currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '문서 통화',
  subtotal_amount DECIMAL(18,2) NULL COMMENT '공급가액/소계(있으면)',
  tax_amount DECIMAL(18,2) NULL COMMENT '세액(있으면)',
  total_amount DECIMAL(18,2) NOT NULL COMMENT '총액',

  memo VARCHAR(500) NULL COMMENT '메모',

  created_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  inv_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  inv_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (inv_sn),
  KEY idx_invoices_issuer (issuer_pt_sn),
  KEY idx_invoices_issued_at (issued_at),
  KEY idx_invoices_doc_no (doc_no),

  CONSTRAINT fk_invoices_issuer
    FOREIGN KEY (issuer_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_invoices_creator
    FOREIGN KEY (created_by_a_sn) REFERENCES assignees(a_sn)
) COMMENT='인보이스/거래명세/세금계산서 등 외부 문서(지급 단위 아님)';


-- ======================================================================
-- TABLE: invoice_lines
-- DESC : 인보이스 라인(GOODS/CHARGE). invoice는 지급단위가 아니므로 지급 연결은 payables에서 수행
-- ======================================================================
CREATE TABLE invoice_lines (
  invl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '인보이스 라인 PK',
  inv_sn BIGINT UNSIGNED NOT NULL COMMENT '인보이스 PK(invoices)',
  line_no INT NOT NULL COMMENT '문서 내 라인번호',

  line_type ENUM('GOODS','CHARGE')
    NOT NULL COMMENT '라인 유형(ENUM) | GOODS:물품, CHARGE:부대비용/서비스/세금/할인 등',

  /* GOODS 라인 연결(선택) */
  po_sn BIGINT UNSIGNED NULL COMMENT '관련 PO PK(purchase_orders) | 문서가 PO 단위로 묶일 때 선택',
  pol_sn BIGINT UNSIGNED NULL COMMENT '관련 PO 라인 PK(po_lines) | 가능하면 연결(선택)',

  /* CHARGE 라인 연결(선택) */
  ct_sn BIGINT UNSIGNED NULL COMMENT '관련 비용 PK(costs) | 배송비/통관비 등 비용으로 이미 관리되는 경우 연결(선택)',
  charge_category VARCHAR(40) NULL COMMENT 'CHARGE 세부 분류(텍스트/코드) | 예: SHIPPING_DOMESTIC, CUSTOMS_DUTY, SERVICE_FEE, TAX, DISCOUNT',

  description VARCHAR(500) NULL COMMENT '라인 설명(품목명/서비스명/비고)',
  qty DECIMAL(14,3) NULL COMMENT '수량(있으면)',
  unit_price DECIMAL(18,2) NULL COMMENT '단가(있으면)',
  amount DECIMAL(18,2) NOT NULL COMMENT '라인 금액(할인 등은 음수 가능)',
  currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '라인 통화(기본: invoices.currency)',

  invl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  invl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (invl_sn),
  UNIQUE KEY uk_invoice_lines (inv_sn, line_no),
  KEY idx_invoice_lines_inv (inv_sn),
  KEY idx_invoice_lines_po (po_sn),
  KEY idx_invoice_lines_pol (pol_sn),
  KEY idx_invoice_lines_ct (ct_sn),
  KEY idx_invoice_lines_type (line_type),
  KEY idx_invoice_lines_charge_cat (charge_category),

  CONSTRAINT fk_invoice_lines_inv
    FOREIGN KEY (inv_sn) REFERENCES invoices(inv_sn),
  CONSTRAINT fk_invoice_lines_po
    FOREIGN KEY (po_sn) REFERENCES purchase_orders(po_sn),
  CONSTRAINT fk_invoice_lines_pol
    FOREIGN KEY (pol_sn) REFERENCES po_lines(pol_sn),
  CONSTRAINT fk_invoice_lines_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='인보이스 라인(GOODS/CHARGE). invoice는 지급단위가 아니므로 지급 연결은 payables에서 수행';


/* =======================================================================
 * 4) Payables(내부 지급 단위) + Allocations
 * ======================================================================= */


-- ======================================================================
-- TABLE: payables
-- DESC : 지급 단위(payable). invoice는 지급단위가 아니며, payment는 결과만 기록
-- ======================================================================
CREATE TABLE payables (
  pbl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '지급요청/지급단위 PK(payable)',

  payee_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '지급 대상 업체 PK(parties) | 송금/정산 상대',
  payee_bk_sn BIGINT UNSIGNED NULL COMMENT '지급 예정인 금액을 수취할 거래처의 계좌를 식별하는 외래키이다. 지급 승인 시점에 지정된 수취 계좌를 의미한다.',

  payable_status ENUM('CREATED','APPROVED','ON_HOLD','PARTIALLY_PAID','PAID','CANCELLED')
    NOT NULL DEFAULT 'CREATED'
    COMMENT '지급 상태(ENUM) | CREATED:작성, APPROVED:승인, ON_HOLD:보류, PARTIALLY_PAID:부분지급, PAID:완료, CANCELLED:취소',

  requested_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '요청자 PK(assignees) | 구매/운영/재무 등',
  approved_by_a_sn BIGINT UNSIGNED NULL COMMENT '승인자 PK(assignees) | 승인 시 설정',

  requested_at DATETIME NOT NULL COMMENT '지급 요청일시(업무 이벤트)',
  approved_at DATETIME NULL COMMENT '승인일시(업무 이벤트)',
  due_at DATE NULL COMMENT '지급 예정/기한(업무 이벤트)',

  currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '지급 통화',
  total_amount DECIMAL(18,2) NOT NULL COMMENT '지급 대상 총액(업무 기준)',

  /* 편의 필드(선택): payments 합산으로도 계산 가능 */
  paid_amount DECIMAL(18,2) NOT NULL DEFAULT 0 COMMENT '지급 완료 누적액(편의). 실제 값은 payment_payable_allocations 합으로도 검증 가능',

  memo VARCHAR(500) NULL COMMENT '재무 메모(지급 사유/특이사항)',

  pbl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pbl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pbl_sn),
  KEY idx_payables_payee (payee_pt_sn),
  KEY idx_payables_status (payable_status),
  KEY idx_payables_due (due_at),
  KEY idx_payables_requested_by (requested_by_a_sn),

  CONSTRAINT fk_payables_payee
    FOREIGN KEY (payee_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_payables_requested_by
    FOREIGN KEY (requested_by_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_payables_approved_by
    FOREIGN KEY (approved_by_a_sn) REFERENCES assignees(a_sn)
) COMMENT='지급 단위(payable). invoice는 지급단위가 아니며, payment는 결과만 기록';


-- ======================================================================
-- TABLE: payable_invoice_allocations
-- DESC : payable이 어떤 invoice(들)을 어떤 금액으로 정산/지급하는지 배분(묶음/분할/부분 지급 지원)
-- ======================================================================
CREATE TABLE payable_invoice_allocations (
  pbia_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'payable-invoice 배분 PK',
  pbl_sn BIGINT UNSIGNED NOT NULL COMMENT 'payable PK(payables)',
  inv_sn BIGINT UNSIGNED NOT NULL COMMENT 'invoice PK(invoices)',

  allocated_amount DECIMAL(18,2) NOT NULL COMMENT '이번 payable이 해당 invoice에서 커버하는 금액(부분/분할/묶음 지원)',
  note VARCHAR(500) NULL COMMENT '비고',

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
-- ======================================================================
CREATE TABLE payable_cost_allocations (
  pbca_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'payable-cost 배분 PK',
  pbl_sn BIGINT UNSIGNED NOT NULL COMMENT 'payable PK(payables)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT 'cost PK(costs)',

  allocated_amount DECIMAL(18,2) NOT NULL COMMENT '이번 payable이 해당 cost에 대해 정산하는 금액(부분/분할/묶음 지원)',
  note VARCHAR(500) NULL COMMENT '비고',

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
-- ======================================================================
CREATE TABLE payment_payable_allocations (
  ppa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'payment-payable 배분 PK',
  pay_sn BIGINT UNSIGNED NOT NULL COMMENT 'payment PK(payments)',
  pbl_sn BIGINT UNSIGNED NOT NULL COMMENT 'payable PK(payables)',

  allocated_amount DECIMAL(18,2) NOT NULL COMMENT '이번 payment가 해당 payable에 귀속되는 금액(부분/분할/묶음 지원)',
  note VARCHAR(500) NULL COMMENT '비고',

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
