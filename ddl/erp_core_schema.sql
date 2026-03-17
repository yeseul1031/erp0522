/* ============================================================================
 * Balhea ERP — Core Schema (DDL)
 * ----------------------------------------------------------------------------
 * [이 파일의 성격]
 * - 본 파일은 Balhea ERP 전체 스키마 중 "core" 레이어에 해당한다.
 * - core는 특정 업무 흐름(계약/주문/수급/배송)에 종속되지 않는
 *   공통 엔티티와 기준 정보를 정의한다.
 * - 이 파일에 정의된 엔티티들은 finance / logistics / contracts 등
 *   다른 스키마 파일에서 공통으로 참조된다.
 *
 * [core 레이어의 범위]
 * - 조직/부서/담당자 (organizations, departments, assignees 등)
 * - 거래 상대방/업체 (parties)
 * - 물품 기준 정보 (goods)
 * - 문서 허브 및 연결 (documents, document_links)
 * - 변경 이력 / 활동 로그 (audit_changes, activity_logs 등)
 *
 * core는 "업무가 무엇이든 항상 존재해야 하는 기준 엔티티"만을 다룬다.
 * 계약, 주문, 수급, 견적, 발주, 배송과 같은 업무 흐름 엔티티는
 * 본 파일에 포함되지 않으며, 별도의 schema 파일에서 정의된다.
 *
 * ----------------------------------------------------------------------------
 * [DDL 편집 및 유지 원칙 — 중요]
 *
 * 1. ddl.sql 주석은 이 파일에 포함된 엔티티의
 *    값, 코드, 제약, 설계 의도를 설명하는 단일 정본이다.
 *
 * 2. 기존 주석은 과거 설계 결정의 기록이므로,
 *    삭제, 요약, 축약, 무의미한 재작성은 허용되지 않는다.
 *
 * 3. 편집은 "raw text 보존"이 아니라 "의미 보존"을 기준으로 한다.
 *    - 동일한 의미의 중복 설명은 자연스럽게 통합할 수 있다.
 *    - 단, 정보(의도/규칙/값/주의)는 1개도 소실되어서는 안 된다.
 *
 * 4. 단순한 append-only 누적(addendum 나열)은 지양한다.
 *    - 새로운 설명은 기존 주석과 문맥상 자연스럽게 합쳐
 *      한 번에 읽히는 형태로 편집하는 것을 원칙으로 한다.
 *
 * 5. 이 파일에는 다음만 포함한다.
 *    - 테이블 정의
 *    - 해당 테이블의 역할, 경계, 관계 해석, 코드/상태 의미,
 *      그리고 엔지니어가 의도대로 다루기 위해 필요한 주의/금지 사항
 *
 * 6. 업무 시나리오, 프로세스 흐름, 단계별 운영 설명은
 *    md 문서 또는 다른 schema 파일에서 다룬다.
 *    본 파일은 "엔티티 자체를 어떻게 해석하고 사용해야 하는가"에만 집중한다.
 *
 * ----------------------------------------------------------------------------
 * [관계 인지에 대한 원칙]
 * - 본 파일에 정의되지 않은 엔티티(예: contracts, orders, sourcing_cases 등)와의
 *   관계가 중요한 경우, 해당 엔티티의 존재와 역할은 주석으로 명시할 수 있다.
 * - 단, 정의/제약의 정본은 각 엔티티가 속한 schema 파일을 따른다.
 *
 * ----------------------------------------------------------------------------
 * [ChatGPT / LLM 협업 규율 — 중요]
 * - 본 파일을 편집할 때, 사용자가 명시적으로 요청한 변경만 수행한다.
 * - "더 좋아 보이는 개선"은 임의 적용하지 않는다.
 *   필요하거나 권장되는 개선이 있으면,
 *   1) 먼저 제안(why 포함)만 하고,
 *   2) 사용자의 동의가 있을 때만 적용한다.
 * - 편집 범위가 넓어질 가능성이 있으면(연관 변경, 리팩터링, 정리 등),
 *   작업을 시작하기 전에 반드시 영향 범위를 제안/설명한다.
 *
 * 이 주석 블록은 core schema를 읽는 모든 사람과
 * (특히 LLM 기반 편집자)에게 이 파일의 경계와 편집 규칙을 전달하기 위한 선언문이다.
 * ============================================================================
 */


-- ======================================================================
-- TABLE: departments
-- DESC : 부서(조직 단위)
-- NOTE : 조직은 그룹웨어에서 관리할꺼고 이건 분리될 수 있다. 지금은 둔다.
-- ======================================================================
CREATE TABLE departments (
  d_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '부서 PK',
  d_name VARCHAR(100) NOT NULL COMMENT '부서명',
  d_manager_a_sn BIGINT UNSIGNED NULL COMMENT '부서 매니저(팀장) 담당자 PK',
  d_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  d_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (d_sn),
  UNIQUE KEY uk_departments_name (d_name)
) COMMENT='부서(조직 단위)';


-- ======================================================================
-- TABLE: assignees
-- DESC : 업무 담당자(직원/협업 담당자 공용)
-- NOTE : 조직은 그룹웨어에서 관리하지만, DB Relation을 위해 간단히 엔티티 레코드를 유지한다. 그룹웨어 -> 사내인증 -> assignees, email을 키값으로 한다. email 바뀌면 수정 필요
-- a_u_id는 users.id 이다. users는 인프라 디비고 독립적으로 간다.
-- assignees에는 서비스 구현상 조인을 위한 필수(이름)만 비정규화하고, 남어진 필요하면 users 를 호출하는 api를 활용하기
-- ======================================================================
CREATE TABLE assignees (
  a_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '담당자 PK',
  a_u_id BIGINT UNSIGNED not null comment 'users.id fk',
  a_d_sn BIGINT UNSIGNED NULL COMMENT '부서 PK',
  a_name VARCHAR(32) NOT NULL COMMENT '담당자 이름',
  a_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '재직/활성 여부(1=활성, 0=비활성)',
  a_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  a_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (a_sn),
  KEY idx_assignees_a_d_sn (a_d_sn),
  KEY idx_assignees_email (a_email),
  CONSTRAINT fk_assignees_departments
    FOREIGN KEY (a_d_sn) REFERENCES departments(d_sn)
) COMMENT='업무 담당자(직원/협업 담당자 공용)';

ALTER TABLE departments
  ADD CONSTRAINT fk_departments_manager
  FOREIGN KEY (d_manager_a_sn) REFERENCES assignees(a_sn);


-- ======================================================================
-- TABLE: parties
-- DESC : 업체/기관(고객사/공급사/물류/중개 등)
-- NOTE: 거래은행 정보는 별도 테이블로 관리한다(bank_accounts).
-- 수령지 주소: 물건을 우리가 직접 받으러 갈때, 본사 주소와 별개로 창고 주소가 필요함
-- pt_type은 해외시, 중계사들만 조회하거나, 무언가 필터링해서 보고싶을때 쓰기 위한 용도
-- ======================================================================
CREATE TABLE parties (
  pt_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '업체/기관 PK',
  pt_type ENUM('CUSTOMER','VENDOR','FORWARDER','BROKER','OTHER')
    NOT NULL COMMENT '업체 유형(ENUM) | CUSTOMER:고객사, VENDOR:공급사/판매사, FORWARDER:포워더/물류, BROKER:관세사/중계, OTHER:기타(단순 퀵/배송기사 처럼 영수증 처리용으로만 등록하는 업체들)',
  pt_name VARCHAR(128) NOT NULL COMMENT '업체명',
  pt_name_alias JSON NOT NULL DEFAULT '[]' COMMENT '검색을 위한 2차 이름. 여러개 넣을수 있게, json_array로. 예> Korea -> [''코리아'']' CHECK (json_valid(`pt_name_alias`)),
  pt_country_code CHAR(2) NULL COMMENT '국가코드(ISO 2자리, 예: KR, US)',
  pt_biz_no VARCHAR(16) NULL COMMENT '사업자번호/등록번호',
  pt_biz_owner VARCHAR(32) NULL COMMENT '대표자명',
  pt_biz_type VARCHAR(64) NULL COMMENT '업태',
  pt_biz_ctg VARCHAR(64) NULL COMMENT '종목',
  pt_phone VARCHAR(20) NULL COMMENT '대표전화',
  pt_contact_name VARCHAR(32) NULL COMMENT '담당자명',
  pt_contact_phone VARCHAR(16) NULL COMMENT '연락처',
  pt_mobile VARCHAR(16) NULL COMMENT '휴대전화',
  pt_fax VARCHAR(16) NULL COMMENT '팩스전화',
  pt_zipcode VARCHAR(7) NULL COMMENT '우편번호',
  pt_addr_1 VARCHAR(64) NULL COMMENT '우편주소',
  pt_addr_2 VARCHAR(64) NULL COMMENT '상세주소',
  pt_url VARCHAR(64) NULL COMMENT '홈페이지',
  pt_contact_email VARCHAR(128) NULL COMMENT '이메일',
  pt_note_1 VARCHAR(512) NULL COMMENT '비고1',
  pt_note_2 VARCHAR(128) NULL COMMENT '비고2',
  pt_note_3 VARCHAR(128) NULL COMMENT '비고3',
  pt_disabled ENUM('Y','N') NULL COMMENT '거래중지',
  pt_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pt_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  pt_shipping_zipcode VARCHAR(7) NULL COMMENT '수령지 우편번호',
  pt_shipping_addr_1 VARCHAR(64) NULL COMMENT '수령지 주소1',
  pt_shipping_addr_2 VARCHAR(64) NULL COMMENT '수령지 주소 상세',
  PRIMARY KEY (pt_sn),
  KEY idx_parties_pt_name (pt_name)
) COMMENT='업체/기관(고객사/공급사/물류/중개 등)';

-- ======================================================================
-- TABLE: goods
-- DESC : 기성상품(재사용 카탈로그/품목 마스터)
-- ======================================================================
CREATE TABLE goods (
  g_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '기성상품 PK',
  g_manufacturer_name VARCHAR(128) NULL COMMENT '제조사명(텍스트, 예: 삼성전자 / Panasonic / 华为)',
  g_name VARCHAR(128) NOT NULL COMMENT '상품명(카탈로그명)',
  g_model_no VARCHAR(32) NULL COMMENT '모델번호',
  g_unit VARCHAR(16) NULL COMMENT '물품 단위(예: EA, 개, 톤 등)',
  g_average_price INT NOT NULL DEFAULT 0 COMMENT '평단가 (부가세 제외 금액, 해외는 포함된 금액)',
  g_stock INT NOT NULL DEFAULT 0 COMMENT 'IO/IOL(및 IU state 변화)에 의해 트랜잭션으로 항상 최신화되는 현재잔고(balance)',
  g_tags JSON NULL COMMENT '태그들 (JSON 배열 권장)' CHECK (json_valid(`g_tags`)),
  g_spec_json JSON NULL COMMENT '규격/옵션(JSON). 기존 text g_spec은 마이그레이션 시 JSON으로 포장하여 저장',
  g_coo VARCHAR(48) NULL COMMENT '소재지(Country of Origin)',
  g_applicable_spec VARCHAR(128) NULL COMMENT '적용 규격/참조',
  g_note VARCHAR(500) NULL COMMENT '비고 (기존 g_etc 포함 가능)',
  g_stock_location VARCHAR(128) NULL COMMENT '재고위치',
  g_disabled ENUM('Y','N') NOT NULL DEFAULT 'N' COMMENT '비활성화 여부',
  g_thumbnail_path VARCHAR(255) NULL COMMENT '썸네일/파일 경로(버킷 이후 경로)',
  g_major_pt_sn BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '주거래처(pt_sn)',
  g_category VARCHAR(64) NOT NULL DEFAULT '' COMMENT '카테고리',
  g_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  g_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (g_sn),
  KEY idx_goods_name (g_name),
  KEY idx_goods_manufacturer_name (g_manufacturer_name)
) COMMENT='기성상품(재사용 카탈로그/품목 마스터)';



-- ======================================================================
-- TABLE: activity_logs
-- DESC : 행위 로그(요약)
-- ======================================================================
CREATE TABLE activity_logs (
  al_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '행위 로그 PK',
  al_actor_a_sn BIGINT UNSIGNED NOT NULL COMMENT '행위 수행자 PK(assignees)',
  al_action_code VARCHAR(100) NOT NULL COMMENT '행위 코드(예: PROJECT_UPDATED, SOURCING_ASSIGNEE_CHANGED, RFQ_SENT, RFQ_REPLY_UPDATED, PO_SENT 등)',
  al_target_table VARCHAR(100) NOT NULL COMMENT '대상 테이블명',
  al_target_pk BIGINT UNSIGNED NOT NULL COMMENT '대상 PK 값',
  al_p_sn BIGINT UNSIGNED NULL COMMENT '관련 프로젝트 PK(검색 편의)',
  al_data_json JSON NULL COMMENT 'al_action_code에 따른 데이터 JSON',
  al_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  PRIMARY KEY (al_sn),
  KEY idx_activity_logs_actor (al_actor_a_sn),
  KEY idx_activity_logs_project (al_p_sn),
  KEY idx_activity_logs_target (al_target_table, al_target_pk),
  CONSTRAINT fk_activity_logs_actor
    FOREIGN KEY (al_actor_a_sn) REFERENCES assignees(a_sn)
) COMMENT='행위 로그(요약)';

-- 이건 나중에 projects 생성하고 넣기
ALTER TABLE activity_logs
  ADD CONSTRAINT fk_activity_logs_project
  FOREIGN KEY (al_p_sn) REFERENCES projects(p_sn);



-- ======================================================================
-- TABLE: audit_changes
-- DESC : 변경 상세(diff/스냅샷) ... activity_logs와 1:N 관계, 변경된 필드 상세 기록 가능시 입력 (선택)
-- ======================================================================
CREATE TABLE audit_changes (
  ac_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '변경 상세 PK',
  ac_al_sn BIGINT UNSIGNED NOT NULL COMMENT '행위 로그 PK(activity_logs)',
  ac_target_table VARCHAR(100) NOT NULL COMMENT '대상 테이블명',
  ac_target_pk BIGINT UNSIGNED NOT NULL COMMENT '대상 PK 값',
  ac_before_json JSON NULL COMMENT '변경 전 스냅샷(JSON, 필요 시)',
  ac_after_json JSON NULL COMMENT '변경 후 스냅샷(JSON, 필요 시)',
  ac_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  PRIMARY KEY (ac_sn),
  KEY idx_audit_changes_ac_al_sn (ac_al_sn),
  KEY idx_audit_changes_target (ac_target_table, ac_target_pk),
  CONSTRAINT fk_audit_changes_activity
    FOREIGN KEY (ac_al_sn) REFERENCES activity_logs(al_sn)
) COMMENT='변경 상세(diff/스냅샷)';


-- ======================================================================
-- DOCUMENTS HUB
-- DESC : 모든 문서/증빙/서류를 documents에 통합 저장하고, document_links로 느슨하게 연결한다.
--        비용/지급/배송 등 엔티티별 전용 문서 테이블은 사용하지 않는다.
-- ======================================================================

/*
Balhea ERP - Documents Hub (documents + document_links) Extension v7.8.2

목적
- v7.8.2에서 문서(증빙/서류)를 cost/payment/shipment 등 엔티티별로 쪼개어 저장하지 않고,
  단일 문서 허브 `documents` + 다대다 연결 `document_links`로 통합한다.
- 배송 시스템 연동/상세 트래킹은 하지 않으며, 문서는 “업무 사건(Event)”과 “재무 근거(Fact)”에 연결하여 관리한다.
- 비용 단계 근거는 shipment_milestone_cost_links(단계↔비용 링크)로 유지하며,
  문서는 해당 cost/payable/shipment/milestone/job 등에 document_links로 연결한다.
- dl_target_type/target_sn은 polymorphic 참조로 FK를 강제하지 않는다(운영 정책/검증으로 보장).

아래 코드는 DDL의 `documents.doc_type`, `documents.doc_type`에 사용되는 **표준 코드**다.

| 코드 | 설명 |
|---|---|
| CASH_RECEIPT | 현금영수증 |
| CARD_RECEIPT | 카드 매출전표/영수증(항목 명세가 포함된 경우) |
| CARD_APPROVAL | 카드 승인 내역(승인번호/금액/일시 등 지급 사실) |
| BANK_TRANSFER_RECEIPT | 계좌이체 영수증/송금확인(지급 사실) |
| INVOICE_TAX | 세금계산서(전자/종이) |
| INVOICE | 청구서/인보이스(지급요청서 성격) |
| STATEMENT | 거래명세서/지급요청서(여러 발주 묶음 가능) |
| PURCHASE_DETAILS | 구매명세서/구매항목정보(셀러별 N개 가능) |
| DELIVERY_NOTE | 납품서/인수증/검수확인서 |
| SHIPMENT_PROOF | 운송장/배송내역/송장(B/L 등) |
| PLATFORM_SETTLEMENT | 플랫폼/PG 정산서(수수료/차감 포함) |
| REFUND_PROOF | 환불/취소 증빙(카드취소전표 등) |
| CARD_STATEMENT | 카드사 청구서(월 단위) |
| OTHER | 기타(자유 입력; note에 상세 기재) |


*/

/* 문서 허브: 모든 파일/서류는 여기로 수집 */
CREATE TABLE documents (
  doc_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'PK',
  doc_category VARCHAR(30) NOT NULL COMMENT '문서 카테고리(권장; 확장 가능): COST, PAYMENT, INVOICE, PURCHASE, DELIVERY, CUSTOMS, QUALITY, CONTRACT, TAX, SETTLEMENT, REFUND, OTHER',
  doc_type VARCHAR(40) NOT NULL COMMENT '문서 타입(권장 예시; 확장 가능): CASH_RECEIPT, SELLER_RECEIPT, CARD_APPROVAL, CARD_SLIP, BANK_TRANSFER_RECEIPT, BANK_TRANSFER_PROOF, TAX_INVOICE, STATEMENT, PURCHASE_DETAILS, BL, AWB, PACKING_LIST, CUSTOMS_DOC, DELIVERY_NOTE, DELIVERY_PROOF, SHIPMENT_PROOF, INSPECTION_REPORT, PHOTO, PLATFORM_SETTLEMENT, REFUND_PROOF, OTHER',
  doc_issuer_name VARCHAR(120) NULL COMMENT '발행처/제공처(거래처/포워더/관세사/창고/검사기관 등)',
  doc_issuer_pt_sn BIGINT UNSIGNED NULL COMMENT 'parties.pt_sn (가능하면)',
--  doc_no VARCHAR(80) NULL COMMENT '문서번호(있으면)',
--  doc_date DATE NULL COMMENT '문서일자(있으면)',
--  doc_ccy CHAR(3) NULL COMMENT '문서 금액 통화(있으면)',
--  doc_amount DECIMAL(18,2) NULL COMMENT '문서 금액(있으면)',
--  doc_tax_amount DECIMAL(18,2) NULL COMMENT '세액(있으면)',
  doc_file_key VARCHAR(255) NOT NULL COMMENT '파일 식별자(스토리지 경로/키)',
  doc_file_name VARCHAR(255) NULL COMMENT '원본 파일명(선택)',
  doc_mime_type VARCHAR(80) NULL COMMENT 'MIME 타입(선택)',
  doc_note VARCHAR(255) NULL COMMENT '비고',
  doc_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  doc_created_by_a_sn BIGINT UNSIGNED NULL COMMENT 'actors.a_sn (업로더/등록자)',
  KEY idx_doc_category_type (doc_category, doc_type),
  KEY idx_doc_issuer_pt_sn (doc_issuer_pt_sn)
--  KEY idx_doc_docno (doc_no),
--  KEY idx_doc_date (doc_date)
) COMMENT='문서 허브: 모든 증빙/서류/파일을 단일 테이블로 저장. 업무/재무/물류 엔티티와의 연결은 document_links로만 표현(엔티티별 문서 테이블 금지).';

/* 문서 연결: 문서가 어떤 엔티티의 근거/증빙인지 연결(다대다) */
CREATE TABLE IF NOT EXISTS document_links (
  dl_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'PK',
  doc_sn BIGINT UNSIGNED NOT NULL COMMENT 'documents.doc_sn',
  dl_target_type VARCHAR(30) NOT NULL COMMENT '연결 대상 타입(명확한 테이블명으로 기입하기): PROJECT, CONTRACT, ORDER, ORDER_LINE, SOURCING_CASE, RFQ, PURCHASE_ORDER(PO), PO_LINE, COST, PAYABLE, PAYMENT, INVOICE, DELIVERY, DELIVERY_LINE, SHIPMENT, SHIPMENT_MILESTONE, JOB, JOB_STOP, INVENTORY_UNIT, so on',
  dl_target_sn BIGINT UNSIGNED NOT NULL COMMENT '연결 대상 PK (type별로 의미)',
  dl_link_role VARCHAR(30) NOT NULL DEFAULT 'EVIDENCE' COMMENT '연결 역할: EVIDENCE(근거), PROOF(완료증빙), REFERENCE(참고), REQUEST(요청서), OUTPUT(산출물)',
  dl_note VARCHAR(255) NULL COMMENT '비고',
  dl_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  UNIQUE KEY uk_dl_doc_dl_target (doc_sn, dl_target_type, dl_target_sn, dl_link_role),
  KEY idx_dl_dl_target (dl_target_type, dl_target_sn),
  CONSTRAINT fk_dl_doc FOREIGN KEY (doc_sn) REFERENCES documents(doc_sn)
) COMMENT='문서 ↔ 업무/재무/물류 엔티티 연결(다대다, polymorphic). dl_target_type+dl_target_sn 유효성은 애플리케이션에서 검증.';

/* 선택: 문서 간 관계(원본/정정/대체/첨부 묶음) */
CREATE TABLE IF NOT EXISTS document_relations (
  dr_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'PK',
  dr_parent_doc_sn BIGINT UNSIGNED NOT NULL COMMENT '상위/원본 documents.doc_sn',
  dr_child_doc_sn BIGINT UNSIGNED NOT NULL COMMENT '하위/첨부/정정 documents.doc_sn',
  dr_relation_type VARCHAR(30) NOT NULL COMMENT '관계: ATTACHMENT, REVISION, REPLACEMENT, TRANSLATION, BUNDLE_MEMBER',
  dr_note VARCHAR(255) NULL COMMENT '비고',
  dr_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  UNIQUE KEY uk_dr_parent_child (dr_parent_doc_sn, dr_child_doc_sn, dr_relation_type),
  CONSTRAINT fk_dr_parent FOREIGN KEY (dr_parent_doc_sn) REFERENCES documents(doc_sn),
  CONSTRAINT fk_dr_child FOREIGN KEY (dr_child_doc_sn) REFERENCES documents(doc_sn)
) COMMENT='문서 간 관계(첨부/정정/대체/묶음 등)';
