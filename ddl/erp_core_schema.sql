/* =======================================================================
 * Balhea ERP - Core Schema (DDL)
 * -----------------------------------------------------------------------
 * 목적
 * - 프로젝트/주문/수급(국내·해외·자체제작)과 RFQ/PO(견적/발주)까지의 핵심 도메인
 * - 99% 경로(order_lines) + 1% 예외(order_line_overrides) 패턴 유지
 * - 주석/ENUM/코드값 설명은 운영자/개발자 가이드 역할을 하므로 축약하지 않음
 * ======================================================================= */

/* =======================================================================

===============================================================================
[불변 철학 / 경계]
(계약&계약물품) <--- 분리 ---> (수급, 수급방식별 *_cases) <--- 분리 ---> (견적/RFQ 또는 발주/PO) <--- 분리 ---> (배송)

- RFQ/PO는 “거래처에게 요청하는 행위” 컨테이너다.
- RFQ/PO 라인은 ‘무엇을 사야 하는지’를 생성/유추하면 안 된다.
- 조달 대상 정본은 오직 sourcing 레이어(sourcing_case_lines)에 존재한다.

따라서:
- rfq_lines / po_lines는 반드시 sourcing_case_lines.scl_sn을 참조해야 한다.
- RFQ/PO 라인에 goods를 직접 들고 있지 않는다(중복/불일치 방지).
  (단, 라인 스냅샷/표시용 텍스트는 허용: 예를 들어 item_name_snapshot)

주요 테이블들:
- orders/order_lines(+order_line_overrides) :
  "고객에게 약속한 납품/계약 물품 정보" 레이어 (계약 담당자 컨트롤)
- sourcing_cases(+ subtype *_cases) :
  "수급 전략/방식" 레이어 (수급 담당자 컨트롤)
- sourcing_case_lines :
  "수급이 정의한 조달 대상(무엇을/얼마나/어떤 목적/어떤 단위로 조달할지)" 레이어 (수급 담당자 컨트롤)
- rfqs/purchase_orders :
  "여러 수급 라인(sourcing_case_lines)을 거래처에 요청하는 행위 컨테이너" 레이어
  → RFQ/PO가 ‘무엇을 사야 하는지’를 유추하면 안 됨.
  → RFQ/PO 라인은 반드시 sourcing_case_lines를 참조해야 함.
- deliveries :
  "상태/흐름" 레이어 (배송은 비용이 아니라 흐름)

[왜 sc_lines가 필요한가]
- 주문항목(order_line) 1개를 만족시키기 위해 조달 대상이 N개가 필요한 현실(추가 RAM, 제조 BOM 등)을
  ‘계약 레이어’를 오염시키지 않고 수급 레이어 내부에서만 표현하기 위함.
- 단순 케이스: order_line 1개 → sourcing_case 1개 → sc_line 1개(자동 생성 가능)
- 복잡 케이스: order_line 1개 → sourcing_case 1..N → 각 sc에 sc_line N개(BOM/부품/용역/운송/외주 등)

[권한(운영 규칙)]
- 계약 담당자: orders/order_lines/order_line_overrides 범위만 입력/수정/삭제
- 수급 담당자: sourcing_cases 및 sourcing_case_lines 범위만 입력/수정/삭제
- RFQ/PO 담당자: RFQ/PO 생성/발송은 가능하나, 조달 대상(무엇을 살지)은 sc_lines에서만 정의

테이블 관계 구조도:
--------------------  | ------------------------------------------------------------------------------
프로젝트(계약) 담당자 영역  |  projects 1 (프로젝트)
                      |     |
                      |     +---> N orders 1 (주문서)
                      |               |
                      |               +---> N order_lines (주문항목, 뭘 납품할지 정의)
                      |                           |
                      |                           +---> N order_line_overrides (예외 케이스)
                      |                           |             |
                      |                           +---> 1 sourcing_cases (수급 담당자 지정, 물리적으로는 여러개지만 논리적으로는 1:1 매핑임. sourcing_cases.dc_is_active = true)
                      |                                         |
수급 담당자 영역          |   (수급 담당자가 수락할때 생성)                +---> 1 subtype_cases (국내/해외/자체제작 등)
                      |                                         |
                      |                                         +-------> N sourcing_case_lines (조달 대상 정의, g_sn 또는 자유텍스트)
                      |                                                            /
(견적/발주 진행 과정)      |     +-----------------------------------------------------/
                      |      |
                      |  [rfq | po]_allocations (RFQ/PO - sc_lines 매핑 테이블)
                      |      |
                      |  rfqs/purchase_orders
                      |      |
                      |      +---> N rfq_lines/po_lines
                      |              (sourcing_case_lines 참조)

 * ======================================================================= */


/* -----------------------------------------------------------------------
 * NOTE (ANNOTATION)
 * - 본 파일은 DDL 자체가 최우선 정본(Source of Truth)이다.
 * - schema-policy-and-naming.md 등에 존재하는 코드/상태/값 설명 중,
 *   실행/운영에 필요한 항목은 가능한 한 본 DDL에 라인 주석/블록 주석으로도 중복 기록한다.
 * - 기존 CREATE 문 및 SQL COMMENT는 축소/요약/삭제하지 않는다.
 * - 본 파일 내 TODO/FIXME 주석은 스키마 설계 검토를 위한 메모이며, DDL 정본 변경은 별도 합의가 필요하다.
 * ----------------------------------------------------------------------- */


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
-- ======================================================================
CREATE TABLE assignees (
  a_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '담당자 PK',
  d_sn BIGINT UNSIGNED NULL COMMENT '부서 PK',
  a_name VARCHAR(32) NOT NULL COMMENT '담당자 이름',
  a_email VARCHAR(128) NULL COMMENT '이메일',
  a_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '재직/활성 여부(1=활성, 0=비활성)',
  a_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  a_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (a_sn),
  KEY idx_assignees_d_sn (d_sn),
  KEY idx_assignees_email (a_email),
  CONSTRAINT fk_assignees_departments
    FOREIGN KEY (d_sn) REFERENCES departments(d_sn)
) COMMENT='업무 담당자(직원/협업 담당자 공용)';


-- ======================================================================
-- TABLE: parties
-- DESC : 업체/기관(고객사/공급사/물류/중개 등)
-- ======================================================================
CREATE TABLE parties (
  pt_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '업체/기관 PK',
  party_type ENUM('CUSTOMER','VENDOR','FORWARDER','BROKER','OTHER')
    NOT NULL COMMENT '업체 유형(ENUM) | CUSTOMER:고객사, VENDOR:공급사/판매사, FORWARDER:포워더/물류, BROKER:관세사/중개, OTHER:기타',
  name VARCHAR(128) NOT NULL COMMENT '업체명',
  country_code CHAR(2) NULL COMMENT '국가코드(ISO 2자리, 예: KR, US)',
  biz_no VARCHAR(16) NULL COMMENT '사업자번호/등록번호',
  contact_name VARCHAR(32) NULL COMMENT '담당자명',
  contact_phone VARCHAR(16) NULL COMMENT '연락처',
  contact_email VARCHAR(128) NULL COMMENT '이메일',
  pt_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pt_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (pt_sn),
  KEY idx_parties_name (name)
) COMMENT='업체/기관(고객사/공급사/물류/중개 등)';


-- ======================================================================
-- TABLE: goods
-- DESC : 기성상품(재사용 카탈로그/품목 마스터)
-- ======================================================================
CREATE TABLE goods (
  g_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '기성상품 PK',
  g_manufacturer_name VARCHAR(64) NULL COMMENT '제조사명(텍스트, 예: 삼성전자 / Panasonic / 华为)',
  g_name VARCHAR(128) NOT NULL COMMENT '상품명(카탈로그명)',
  g_model_no VARCHAR(32) NULL COMMENT '모델번호',
  g_spec_json JSON NULL COMMENT '규격/옵션(JSON)',
  g_note VARCHAR(500) NULL COMMENT '비고',
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
  al_occurred_at DATETIME NOT NULL COMMENT '발생일시(업무 이벤트)',
  al_note VARCHAR(500) NULL COMMENT '요약/노트/메모 등',
  al_data_json JSON NULL COMMENT '부가 정보(JSON)',
  al_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  PRIMARY KEY (al_sn),
  KEY idx_activity_logs_actor (al_actor_a_sn),
  KEY idx_activity_logs_project (al_p_sn),
  KEY idx_activity_logs_target (al_target_table, al_target_pk),
  CONSTRAINT fk_activity_logs_actor
    FOREIGN KEY (al_actor_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_activity_logs_project
    FOREIGN KEY (al_p_sn) REFERENCES projects(p_sn)
) COMMENT='행위 로그(요약)';


-- ======================================================================
-- TABLE: audit_changes
-- DESC : 변경 상세(diff/스냅샷) ... activity_logs와 1:N 관계, 변경된 필드 상세 기록 가능시 입력 (선택)
-- ======================================================================
CREATE TABLE audit_changes (
  ac_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '변경 상세 PK',
  al_sn BIGINT UNSIGNED NOT NULL COMMENT '행위 로그 PK(activity_logs)',
  ac_target_table VARCHAR(100) NOT NULL COMMENT '대상 테이블명',
  ac_target_pk BIGINT UNSIGNED NOT NULL COMMENT '대상 PK 값',
  ac_changed_fields_json JSON NOT NULL COMMENT '변경된 필드 diff(JSON: from/to)',
  ac_before_json JSON NULL COMMENT '변경 전 스냅샷(JSON, 필요 시)',
  ac_after_json JSON NULL COMMENT '변경 후 스냅샷(JSON, 필요 시)',
  ac_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  PRIMARY KEY (ac_sn),
  KEY idx_audit_changes_al (al_sn),
  KEY idx_audit_changes_target (ac_target_table, ac_target_pk),
  CONSTRAINT fk_audit_changes_activity
    FOREIGN KEY (al_sn) REFERENCES activity_logs(al_sn)
) COMMENT='변경 상세(diff/스냅샷)';


-- ======================================================================
-- TABLE: projects
-- DESC : 프로젝트(=계약)
-- NOTE : p_sn 대신 코드를 쓰고 싶으면 P-[YYYY]-[p_sn] 을 쓰기
-- ======================================================================
CREATE TABLE projects (
  p_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '프로젝트(=계약 통합) PK',
  p_name VARCHAR(128) NOT NULL COMMENT '프로젝트명',
  p_type ENUM('TENDER','DIRECT','FRAME')
    NOT NULL COMMENT '프로젝트 유형(ENUM) | TENDER:입찰(공공/민간), DIRECT:직접계약, FRAME:기간/다건 계약(프레임/콜오프)',
  p_customer_pt_sn BIGINT UNSIGNED NULL COMMENT '고객사 PK(parties)',
  p_contract_no VARCHAR(32) NULL COMMENT '계약서 번호(외부 식별자, 계약 전 NULL 가능)',
  p_signed_at DATE NULL COMMENT '계약 체결일(계약 전 NULL 가능)',
  p_contract_amount DECIMAL(18,2) NULL COMMENT '계약 총액(계약 전 NULL 가능)',
  p_currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화(예: KRW, USD)',
  p_status ENUM('PRE_CONTRACT','ACTIVE','CLOSED','CANCELLED')
    NOT NULL COMMENT '프로젝트 상태(ENUM) | PRE_CONTRACT:계약전/입찰검토, ACTIVE:진행, CLOSED:종료, CANCELLED:취소',
  p_a_sn BIGINT UNSIGNED NOT NULL COMMENT '현재 프로젝트 담당자 PK(assignees)',
  p_started_at DATETIME NULL COMMENT '프로젝트 시작일시(업무 이벤트)',
  p_ended_at DATETIME NULL COMMENT '프로젝트 종료일시(업무 이벤트)',
  p_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  p_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (p_sn),
  UNIQUE KEY uk_projects_project_code (p_code),
  KEY idx_projects_customer_pt_sn (customer_pt_sn),
  KEY idx_projects_manager (p_a_sn),
  KEY idx_projects_status (p_status),
  CONSTRAINT fk_projects_customer
    FOREIGN KEY (customer_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_projects_manager
    FOREIGN KEY (p_a_sn) REFERENCES assignees(a_sn)
) COMMENT='프로젝트(=계약)';


-- ======================================================================
-- TABLE: orders
-- DESC : 주문서(프로젝트 하위)
-- ======================================================================
CREATE TABLE orders (
  o_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문서 PK',
  p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects)',
  o_no VARCHAR(32) NULL COMMENT '주문서 번호(외부/내부 식별용)',
  o_type ENUM('CONTRACT_ORDER','PRE_CONTRACT_ORDER')
    NOT NULL DEFAULT 'CONTRACT_ORDER'
    COMMENT '주문서 유형(ENUM) | CONTRACT_ORDER:실제 주문서, PRE_CONTRACT_ORDER:계약전(입찰검토/사전견적) 용도',
  o_status ENUM('OPEN','IN_PROGRESS','CLOSED','CANCELLED')
    NOT NULL COMMENT '주문서 상태(ENUM) | OPEN:오픈, IN_PROGRESS:진행, CLOSED:종결, CANCELLED:취소',
  o_ordered_at DATETIME NULL COMMENT '주문서 생성/접수 일시(업무 이벤트)',
  o_due_date DATE NULL COMMENT '납품 예정일(업무 이벤트)',
  o_note VARCHAR(500) NULL COMMENT '메모',
  o_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  o_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (o_sn),
  KEY idx_orders_p_sn (p_sn),
  KEY idx_orders_status (o_status),
  CONSTRAINT fk_orders_projects
    FOREIGN KEY (p_sn) REFERENCES projects(p_sn)
) COMMENT='주문서(프로젝트 하위)';


-- ======================================================================
-- TABLE: order_lines
-- DESC : 주문라인(고객 요구/납품 약속 단위)
-- web_* 공고 사이트에 게시된 주문항목 정보
-- doc_* 공고 문서상에 기록된 주문항목 정보
-- final_* 담당자가 확인한 실제 납품해야할 주문항목 정보
-- ======================================================================

/* -----------------------------------------------------------------------
 * TABLE: order_lines
 * PURPOSE
 * - 공공조달 계약에서 '요구된 납품 조건'은 출처별로 상이/오류 가능하므로 3벌을 계약의 일부로 보존한다.
 *   1) web_*   : 공고 사이트 웹페이지에 게시된 값(원문/게시 기준)
 *   2) doc_*   : 공고 첨부/문서에 기재된 값(문서 기준)
 *   3) final_* : 내부 담당자가 최종 확인·합의한 값(실제 납품/견적/발주 기준)
 * - 최종 실행(견적/RFQ/PO/납품)은 기본적으로 final_* 값을 기준으로 한다.
 * - web_* / doc_* / final_*는 '서로 모순될 수 있으며', 분쟁/정산/감사 시 근거로 활용한다.
 *
 * NOTE
 * - 본 테이블은 3벌 데이터를 한 레코드에 고정 저장한다(출처가 유동적이지 않음).
 * - 문서/웹 원문 파일 자체는 documents + document_links로 연결하는 것을 권장한다.
 * - 계약에서는 요구사항에 촛점을 맞추고, g_sn 과 매핑은 실제 수급 영역에서 다룬다.
 * ----------------------------------------------------------------------- */

CREATE TABLE order_lines (
  ol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문라인 PK',
  o_sn BIGINT UNSIGNED NOT NULL COMMENT '주문서 PK(orders)',
  ol_no INT NOT NULL COMMENT '주문서 내 라인 번호',

  web_item_name VARCHAR(128) NOT NULL COMMENT '(사이트상) 요구 품목명(예: 십자 드라이버)',
  web_item_spec JSON NULL COMMENT '(사이트상) 요구 규격/조건(자유형 JSON)',
  web_item_qty DECIMAL(14,3) NOT NULL COMMENT '(사이트상) 요구 수량(납품 약속 수량)',
  web_item_unit VARCHAR(20) NULL COMMENT '(사이트상) 단위(예: EA, SET)',
  web_unit_price DECIMAL(18,2) NULL COMMENT '(사이트상) 판매 단가(고객에 납품 단가, 모르면 NULL)',

  doc_item_name VARCHAR(128) NOT NULL COMMENT '(문서상) 요구 품목명(예: 십자 드라이버)',
  doc_item_spec JSON NULL COMMENT '(문서상) 요구 규격/조건(자유형 JSON)',
  doc_item_qty DECIMAL(14,3) NOT NULL COMMENT '(문서상) 요구 수량(납품 약속 수량)',
  doc_item_unit VARCHAR(20) NULL COMMENT '(문서상) 단위(예: EA, SET)',
  doc_unit_price DECIMAL(18,2) NULL COMMENT '(문서상) 판매 단가(고객에 납품 단가, 모르면 NULL)',

  final_item_name VARCHAR(128) NOT NULL COMMENT '(검토된) 요구 품목명(예: 십자 드라이버)',
  final_item_spec JSON NULL COMMENT '(검토된) 요구 규격/조건(자유형 JSON)',
  final_item_qty DECIMAL(14,3) NOT NULL COMMENT '(검토된) 요구 수량(납품 약속 수량)',
  final_item_unit VARCHAR(20) NULL COMMENT '(검토된) 단위(예: EA, SET)',
  final_unit_price DECIMAL(18,2) NULL COMMENT '(검토된) 판매 단가(고객에 납품 단가, 모르면 NULL)',

  ol_status ENUM('OPEN','IN_PROGRESS','DELIVERED','CANCELLED')
    NOT NULL COMMENT '라인 상태(ENUM) | OPEN:오픈, IN_PROGRESS:진행, DELIVERED:납품완료, CANCELLED:취소',
  ol_due_date DATE NULL COMMENT '납품 예정일(업무 이벤트)',
  ol_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ol_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ol_sn),
  UNIQUE KEY uk_order_lines_order_line_no (o_sn, ol_no),
  KEY idx_order_lines_o_sn (o_sn),
  KEY idx_order_lines_status (ol_status),
  CONSTRAINT fk_order_lines_orders
    FOREIGN KEY (o_sn) REFERENCES orders(o_sn)
) COMMENT='주문라인(고객 요구/납품 약속 단위)';


-- ======================================================================
-- TABLE: order_line_overrides
-- DESC : 주문라인 희소 케이스(분할/대체/추가/조합) 지원
-- NOTE :
-- * - 계약에서는 요구사항에 촛점을 맞추고, g_sn 과 매핑은 실제 수급 영역에서 다룬다.
-- ======================================================================
CREATE TABLE order_line_overrides (
  olo_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문라인 예외(override) PK',
  ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines)',
  olo_type ENUM('SPLIT','SUBSTITUTE','ADD_ON','BUNDLE')
    NOT NULL COMMENT '예외 유형(ENUM) | SPLIT:분할구매, SUBSTITUTE:대체품, ADD_ON:추가구매, BUNDLE:조합구성품',

  olo_item_name VARCHAR(128) NOT NULL COMMENT '(override) 요구 품목명(예: 십자 드라이버)',
  olo_item_spec JSON NULL COMMENT '(override) 요구 규격/조건(자유형 JSON)',
  olo_item_qty DECIMAL(14,3) NOT NULL COMMENT '(override) 요구 수량(납품 약속 수량)',
  olo_item_unit VARCHAR(20) NULL COMMENT '(override) 단위(예: EA, SET)',
-- olo_unit_price 는 없다. 왜냐하면 주문라인의 단가 1개만 실 단가이고 남어지는 참조일뿐이다.


  olo_note VARCHAR(500) NULL COMMENT '사유/메모',
  olo_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  olo_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (olo_sn),
  KEY idx_olo_ol (ol_sn),
  KEY idx_olo_type (olo_type),
  CONSTRAINT fk_olo_ol
    FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn)
) COMMENT='주문라인 희소 케이스(분할/대체/추가/조합) 지원';


-- ======================================================================
-- TABLE: sourcing_cases
-- DESC : 수급 케이스(주문라인 단위 공통 컨테이너)
-- ======================================================================

/* -----------------------------------------------------------------------
 * TABLE: sourcing_cases
 * PURPOSE
 * - 주문항목(order_lines) 단위의 '수급 실행 케이스'이다.
 * - 케이스는 수급 방식(DOMESTIC/OVERSEAS/IN_HOUSE)별로 생성될 수 있으며, 기본은 1 order_line : 1+ sourcing_cases.
 * - sc_status는 '단계 진행'이 아니라, '책임/수락/거절에 따른 지속 상태'를 표현한다.
 *
 * STATUS MODEL (minimal)
 * - OPEN             : 담당자 미확정(대기열)
 * - SELF_ASSIGNED    : 프로젝트 담당자가 직접 처리(인수)
 * - ASSIGNING        : 특정 담당자에게 위임 요청(수락/거절 대기)
 * - ASSIGNEE_WORKING : 요청 받은 담당자가 수락하여 처리 중
 * - CANCELLED        : 취소
 *
 * FIELD USAGE
 * - sc_owner_a_sn      : '현재 책임자' (OPEN에서는 NULL 가능)
 * - sc_requested_a_sn  : 위임 요청 대상(ASSIGNING에서 사용)
 * - sc_requested_at    : 요청 시각
 * - sc_accepted_at     : 수락 시각
 * - sc_rejected_at     : 거절 시각
 * - 상세 액션 이력은 audit/activity_logs로 남긴다(별도 이벤트 테이블 신설 없음).
 * ----------------------------------------------------------------------- */

CREATE TABLE sourcing_cases (
  sc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수급 케이스 PK',
  ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines) (1:1)',
  sc_required_qty DECIMAL(14,3) NOT NULL COMMENT '요구된 수급 수량(order_line 의 수량과는 다를 수 있음)',
  sc_type ENUM('DOMESTIC','OVERSEAS','IN_HOUSE')
    NOT NULL COMMENT '수급 방식(ENUM) | DOMESTIC:국내구매, OVERSEAS:해외구매, IN_HOUSE:자체제작',
  sc_assignee_a_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 수행 담당자 PK(assignees) | 협업 담당자 또는 프로젝트 담당자',
  sc_status VARCHAR(32) NOT NULL COMMENT
    '수급 케이스의 현재 처리 상태를 나타내는 코드이다.
    - OPEN               : 담당자 미확정 상태이다. 누구도 인수하지 않았으며, 담당자 지정 대기열에 해당한다.
    - SELF_ASSIGNED      : 케이스 생성자/프로젝트 담당자가 본인이 직접 처리하기로 인수한 상태이다.
    - ASSIGNING          : 특정 담당자에게 처리를 요청한 상태이다. 요청 대상의 수락/거절을 기다린다.
    - ASSIGNEE_WORKING   : 요청 받은 담당자가 수락하여 실제로 처리 중인 상태이다.
    - CANCELLED          : 케이스가 취소된 상태이다.',
  sc_owner_a_sn BIGINT UNSIGNED NULL COMMENT
    '현재 이 수급 케이스를 실제로 처리할 책임(소유권)을 가진 담당자를 식별하는 외래키이다. OPEN 상태에서는 NULL일 수 있다.',

  sc_requested_a_sn BIGINT UNSIGNED NULL COMMENT
    '담당자에게 처리를 요청했을 때, 요청 대상 담당자를 식별하는 외래키이다. sc_status=ASSIGNING일 때 주로 사용된다.',

  sc_requested_at DATETIME NULL COMMENT
    '담당자 지정 요청이 발생한 시각이다. sc_status가 ASSIGNING으로 전환된 시점을 기록한다.',

  sc_accepted_at DATETIME NULL COMMENT
    '요청 대상 담당자가 요청을 수락한 시각이다. sc_status가 ASSIGNEE_WORKING으로 전환된 시점을 기록한다.',

  sc_rejected_at DATETIME NULL COMMENT
    '요청 대상 담당자가 요청을 거절한 시각이다. 거절 시 sc_status는 일반적으로 OPEN으로 되돌아간다.',

  sc_note VARCHAR(500) NULL COMMENT '진행 요약(담당자 메모)',
  sc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (sc_sn),
  UNIQUE KEY uk_sourcing_cases_ol_sn (ol_sn),
  KEY idx_sourcing_cases_assignee (sc_assignee_a_sn),
  KEY idx_sourcing_cases_status (sc_status),
  CONSTRAINT fk_sourcing_cases_order_lines
    FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn),
  CONSTRAINT fk_sourcing_cases_assignee
    FOREIGN KEY (sc_assignee_a_sn) REFERENCES assignees(a_sn),
) COMMENT='수급 케이스(주문라인 단위 공통 컨테이너)';


/* =============================================================================
-- TABLE: sourcing_case_lines
-- DESC : 수급(sourcing) 레이어에서 “조달 대상(무엇을, 얼마나, 어떤 목적/성격으로)”을 정의하는 정본 라인.
--        RFQ/PO는 이 라인을 ‘참조하여’ 거래처에 요청한다(유추 금지).
-- NOTE : 본 테이블은 실제 수급담당자가 관리(수정)하는 영역이다. 견적/발주는 scl 단위로 이루어진다. sc는 헤더(메타) 테이블
===============================================================================

[검증/정합성 규칙(앱 레벨 강제 권장)]
- sc_lines는 반드시 sc_sn을 가진다.
- sc_lines는 "어떤 납품 요구(order_line)를 위해 존재하는가"를 추적할 수 있어야 한다:
  - 기본: sc_sn → order_line(간접)로 추적
  - 필요 시: scl_ol_sn 또는 scl_olo_sn으로 명시 연결(아래 컬럼 참조)
- 한 order_line을 여러 sourcing_case로 나눈 경우:
  - 각 sc_lines의 목표수량 합이 order_line 목표수량을 커버(= 또는 <=)하도록 운영 정책을 둔다.
- RFQ/PO 라인은 반드시 scl_sn을 참조한다(유추 금지).

===============================================================================
[주요 FK/참조 정책]
- scl_sc_sn: sourcing_cases.sc_sn (필수)
- (선택) scl_ol_sn: order_lines.ol_sn  — 라인이 특정 주문항목을 직접 커버할 때
- (선택) scl_olo_sn: order_line_overrides.olo_sn — override 단위의 조달 대상일 때
  ※ 운영 규칙: scl_ol_sn과 scl_olo_sn 중 하나만 채우는 것을 권장(둘 다 NULL 금지까지 강제하려면 앱 검증)

- goods 참조:
  - scl_g_sn: goods.g_sn (조달 대상이 명확한 경우)
  - scl_free_text_item: 자유 텍스트 품목(임시/비정형 품목)
  → 둘 중 하나는 채우도록 권장(앱 검증)


-- =============================================================================
 */
CREATE TABLE sourcing_case_lines (
  scl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수급라인 PK',
  scl_no INT NOT NULL COMMENT '발주서 내 줄번호',
  -- 필수 연결: 수급 케이스
  scl_sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급케이스 FK (sourcing_cases.sc_sn). 이 라인이 속한 수급 전략/방식 컨텍스트',

  -- 선택 연결: 계약/납품 레이어 추적 (권장: 둘 중 하나만 사용)
  scl_ol_sn BIGINT UNSIGNED NULL COMMENT '주문항목 FK (order_lines.ol_sn). 이 라인이 특정 주문항목을 직접 커버할 때 사용(권장)',
  scl_olo_sn BIGINT UNSIGNED NULL COMMENT '주문항목 override FK (order_line_overrides.olo_sn). override 단위(구성품/대체품) 조달 대상일 때 사용(권장)',

  -- 조달 대상의 성격/목적
  scl_line_type ENUM(
    'FINISHED_GOOD',
    'COMPONENT',
    'CONSUMABLE',
    'SERVICE',
    'OUTSOURCED',
    'FREIGHT',
    'ADJUSTMENT'
  ) NOT NULL COMMENT 'scl_line_type (조달 라인의 성격)
- FINISHED_GOOD : 납품 대상(완제품). order_line의 “약속된 물품”과 동일하거나 대응되는 라인.
- COMPONENT     : 부품/BOM 구성품(제조 또는 커스터마이징을 위해 필요)
- CONSUMABLE    : 소모품(테이프/포장재/케이블타이 등, 원가/재고 처리 정책에 따라 사용)
- SERVICE       : 용역(설치/조립/검수/시험/세팅/가공 등)
- OUTSOURCED    : 외주/하도급(제작/가공을 외부에 맡김)
- FREIGHT       : 운송/탁송/배송료(조달 실행에 수반되는 운송 단위로 “조달 라인”으로 표현 필요 시)
- ADJUSTMENT    : 조정 라인(반품/추가 청구/정산 조정 등, 원가/정산 목적의 보정)',

  scl_purpose_code ENUM(
    'FULFILL_ORDER_LINE',
    'UPGRADE_TO_MEET_SPEC',
    'SUBSTITUTE',
    'MANUFACTURING_INPUT',
    'QUALITY_PROCESS',
    'DELIVERY_SUPPORT',
    'OTHER'
  ) NOT NULL DEFAULT 'scl_purpose_code (조달 목적/의도)
- FULFILL_ORDER_LINE : 특정 order_line을 충족하기 위한 조달
- UPGRADE_TO_MEET_SPEC : 스펙 충족을 위한 업그레이드/추가 구매(예: RAM 추가)
- SUBSTITUTE          : 대체품(원래 품목이 단종/미판매 등으로 대체)
- MANUFACTURING_INPUT : 제조 투입(내부 제작을 위한 BOM 입력)
- QUALITY_PROCESS     : 품질/검수/시험을 위한 용역/소모품
- DELIVERY_SUPPORT    : 운송/설치 등 납품 지원
- OTHER               : 기타 (detail_note에 상세)',


  -- 상태/진행
  scl_status ENUM(
    'DRAFT',
    'CONFIRMED',
    'QUOTING',
    'ORDERING',
    'IN_PROGRESS',
    'RECEIVED',
    'CANCELLED',
    'CLOSED'
  ) NOT NULL DEFAULT 'DRAFT' COMMENT 'scl_status (라인 상태)
- DRAFT       : 초안(수급 검토 중, 아직 RFQ/PO로 요청하지 않음)
- CONFIRMED   : 확정(이 라인을 조달 대상으로 확정, RFQ/PO 대상으로 삼을 수 있음)
- QUOTING     : 견적 진행 중(RFQ 발송/응답 수집 중)
- ORDERING    : 발주 진행 중(PO 작성/발송/수락 대기 포함)
- IN_PROGRESS : 진행 중(제작/가공/준비 등)
- RECEIVED    : 입고/수령 완료(조달 완료)
- CANCELLED   : 취소(조달 대상에서 제외)
- CLOSED      : 종료(완료/정산 완료 등 운영상 클로즈)',

  -- 조달 대상 식별: goods 또는 자유 텍스트(비정형)
  scl_g_sn BIGINT UNSIGNED NULL COMMENT '조달 대상 goods FK (goods.g_sn). 명확한 품목이면 사용',
  scl_item_name VARCHAR(255) NULL COMMENT '비정형/임시 품목명. goods로 모델링되지 않았거나 즉시 등록이 어려울 때 사용. 예: "RAM 8GB DDR4 추가 구매"',

  -- 목표 수량/단위
  scl_item_qty DECIMAL(14,3) NULL COMMENT '조달 목표 수량. order_line 1개를 여러 수급 라인으로 나눌 때 필수',
  scl_uom_code VARCHAR(32) NULL COMMENT '단위 코드(확장 가능). 예: EA, SET, BOX, KG. 고정 ENUM 대신 VARCHAR+COMMENT로 유연성 유지',
  scl_unit_price DECIMAL(18,2) NULL COMMENT '예상 단가(통화는 sourcing_case 또는 PO 라인에서 결정). 견적 전 추정치일 수 있음',

  scl_need_by_dt DATETIME NULL COMMENT '필요 시점(납기/생산 계획 기준). 운영상 스케줄링에 사용',

  -- 제조/BOM/분해 트리 지원(선택)
  scl_parent_scl_sn BIGINT UNSIGNED NULL COMMENT '상위 수급라인 FK (sourcing_case_lines.scl_sn). BOM/구성품 트리 표현 필요 시 사용',

  -- 메모/근거
  scl_note varchar(500) NULL COMMENT '스펙/조건/주의사항. 예: "고객 요구 16GB, 본체 8GB이므로 추가 RAM 필요"',

  -- 메타
  scl_create_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '레코드 생성일시',
  scl_update_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '레코드 수정일시',

  PRIMARY KEY (scl_sn),

  -- Indexes
  KEY idx_scl_sc_sn (scl_sc_sn),
  KEY idx_scl_ol_sn (scl_ol_sn),
  KEY idx_scl_olo_sn (scl_olo_sn),
  KEY idx_scl_status (scl_status),
  KEY idx_scl_g_sn (scl_g_sn),
  KEY idx_scl_parent (scl_parent_scl_sn),

  -- FK constraints
  CONSTRAINT fk_scl_sc
    FOREIGN KEY (scl_sc_sn) REFERENCES sourcing_cases(sc_sn),

  -- 아래 FK들은 테이블 존재/최종 스키마에 따라 활성화.
  -- order_line_overrides, goods 테이블이 core schema에 존재하는 경우 활성화 권장.
  CONSTRAINT fk_scl_ol
    FOREIGN KEY (scl_ol_sn) REFERENCES order_lines(ol_sn),

  CONSTRAINT fk_scl_olo
    FOREIGN KEY (scl_olo_sn) REFERENCES order_line_overrides(olo_sn),

  CONSTRAINT fk_scl_g
    FOREIGN KEY (scl_g_sn) REFERENCES goods(g_sn),

  CONSTRAINT fk_scl_parent
    FOREIGN KEY (scl_parent_scl_sn) REFERENCES sourcing_case_lines(scl_sn)

) COMMENT='수급 조달 라인(정본). RFQ/PO는 본 라인을 참조하여 요청한다(유추 금지).';


-- ======================================================================
-- TABLE: domestic_cases
-- DESC : 국내 수급 케이스(시도 인스턴스)
-- ======================================================================
CREATE TABLE domestic_cases (
  dc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '국내 수급 케이스 PK(시도 인스턴스)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  dc_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  dc_closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  dc_note VARCHAR(500) NULL COMMENT '비고',
  dc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (dc_sn),
  KEY idx_domestic_cases_sc_sn (sc_sn),
  CONSTRAINT fk_domestic_cases_sc
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='국내 수급 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: overseas_cases
-- DESC : 해외 수급 케이스(시도 인스턴스)
-- NOTE : incoterms는 견적/발주서에 넣는게 맞다. 나중에 필요하다고 하면 넣기.
-- ESD (Estimated Shipping Date), ETA (Estimated Time of Arrival) 등도 견적/발주서에서 다루는게 맞다.
-- ======================================================================
CREATE TABLE overseas_cases (
  oc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '해외 수급 케이스 PK(시도 인스턴스)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  oc_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  oc_closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  oc_note VARCHAR(500) NULL COMMENT '비고',
  oc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  oc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (oc_sn),
  KEY idx_overseas_cases_sc (sc_sn),
  CONSTRAINT fk_overseas_cases_sc
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='해외 수급 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: inhouse_cases
-- DESC : 자체제작 케이스(시도 인스턴스)
-- NOTE : 도면 등의 첨부는 documents + document_links로 연결하기
-- 자체 제작에 특화된 상태들이 있다면 여기에 필드들을 추가하자. 현업의 요구사항에 따라 그때그때 넣을수 있다. 예> planned_start, planned_finish, qc_required 등...
-- ======================================================================
CREATE TABLE inhouse_cases (
  ic_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '자체제작 케이스 PK(시도 인스턴스)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  ic_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  ic_closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  ic_expected_margin_rate DECIMAL(5,2) NULL COMMENT '제작 후 납품시 남길 수익 마진률(%)',
  ic_note VARCHAR(500) NULL COMMENT '비고',
  ic_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ic_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ic_sn),
  KEY idx_inhouse_cases_sc (sc_sn),
  CONSTRAINT fk_inhouse_cases_sc
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='자체제작 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: inhouse_bom_lines
-- DESC : 자체제작 BOM(자재 소요) ... 제작 자재가 있으면 구매도 있을텐데, 이건 어떻게 기록하지...고민 필요
-- ======================================================================
CREATE TABLE inhouse_bom_lines (
  ibl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '제작 BOM 라인 PK',
  ic_sn BIGINT UNSIGNED NOT NULL COMMENT '자체제작 케이스 PK(inhouse_cases)',
  ibl_item_name VARCHAR(255) NOT NULL COMMENT '자재명',
  ibl_item_qty DECIMAL(14,3) NOT NULL COMMENT '필요 수량',
  ibl_item_unit VARCHAR(20) NULL COMMENT '단위',

  ibl_item_name VARCHAR(128) NOT NULL COMMENT '(자체제작) 품목명(예: 십자 드라이버)',
  ibl_item_spec JSON NULL COMMENT '(자체제작) 규격/조건(자유형 JSON)',
  ibl_item_qty DECIMAL(14,3) NOT NULL COMMENT '(자체제작) 수량',
  ibl_item_unit VARCHAR(20) NULL COMMENT '(자체제작) 단위(예: EA, SET)',
  ibl_unit_price DECIMAL(18,2) NULL COMMENT '(자체제작) 판매 단가',

  ibl_note VARCHAR(500) NULL COMMENT '비고',
  ibl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ibl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ibl_sn),
  KEY idx_inhouse_bom_ic (ic_sn),
  CONSTRAINT fk_inhouse_bom_ic
    FOREIGN KEY (ic_sn) REFERENCES inhouse_cases(ic_sn)
) COMMENT='자체제작 BOM(자재 소요)';


-- ======================================================================
-- TABLE: inhouse_work_orders
-- DESC : 자체제작 작업지시/공정
-- ======================================================================
CREATE TABLE inhouse_work_orders (
  iwo_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '제작 작업지시 PK',
  ic_sn BIGINT UNSIGNED NOT NULL COMMENT '자체제작 케이스 PK(inhouse_cases)',
  iwo_process_name VARCHAR(255) NOT NULL COMMENT '공정/작업명',
  iwo_status ENUM('TODO','DOING','DONE','BLOCKED','CANCELLED')
    NOT NULL COMMENT '작업 상태(ENUM) | TODO:대기, DOING:진행, DONE:완료, BLOCKED:이슈, CANCELLED:취소',
  iwo_started_at DATETIME NULL COMMENT '작업 시작일시(업무 이벤트)',
  iwo_done_at DATETIME NULL COMMENT '작업 완료일시(업무 이벤트)',
  iwo_note VARCHAR(500) NULL COMMENT '비고',
  iwo_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  iwo_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (iwo_sn),
  KEY idx_inhouse_work_orders_ic (ic_sn),
  KEY idx_inhouse_work_orders_status (iwo_status),
  CONSTRAINT fk_inhouse_work_orders_ic
    FOREIGN KEY (ic_sn) REFERENCES inhouse_cases(ic_sn)
) COMMENT='자체제작 작업지시/공정';


-- ======================================================================
-- TABLE: rfqs
-- DESC : RFQ(견적요청서) 헤더 - 국내/해외 통합
-- ======================================================================
CREATE TABLE rfqs (
  rfq_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'RFQ PK(견적요청서) - 국내/해외 공용',

  /* 수급 케이스 연결 */
  rfq_primary_sc_sn BIGINT UNSIGNED NULL COMMENT '대표 수급 케이스 PK(sourcing_cases) | 단독 진행이면 설정, 혼합 RFQ면 NULL 가능',
  rfq_currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화(예: KRW, USD)',

  /* 업체/작성자 */
  rfq_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '대상 업체 PK(parties)',
  rfq_a_sn BIGINT UNSIGNED NOT NULL COMMENT '작성자 PK(assignees)',

  /* 상태 */
  rfq_status ENUM('DRAFT','SENT','REPLIED','DECLINED','CANCELLED','CLOSED')
    NOT NULL COMMENT 'RFQ 상태(ENUM)',

  /* 업무 이벤트 */
  rfq_issued_at DATETIME NOT NULL COMMENT 'RFQ 발행/발송일시(업무 이벤트)',
  rfq_valid_until DATE NULL COMMENT 'RFQ 유효기한(요청 시)',

  /* 해외에서만 주로 쓰는 필드(옵션) */
  rfq_trade_terms VARCHAR(20) NULL COMMENT '인도조건(Incoterms 등) | 예: EXW, FOB, CIF, DDP',
  rfq_ship_from_country CHAR(2) NULL COMMENT '발송국가(ISO-3166-1 alpha-2) | 예: CN, US',
  rfq_ship_to_country CHAR(2) NULL COMMENT '도착국가(ISO-3166-1 alpha-2) | 보통 KR',

  rfq_replied_at DATETIME NULL COMMENT '회신일시(업무 이벤트)',
  rfq_reply_lead_time_days INT NULL COMMENT '회신 납기(리드타임) 일수(선택)',

  rfq_req_pub_note VARCHAR(500) NULL COMMENT 'RFQ 요청 메모(업체 전달용)',
  rfq_res_pub_note VARCHAR(500) NULL COMMENT 'RFQ 응답 메모(업체가 보낸 코멘트)',
  rfq_note VARCHAR(500) NULL COMMENT 'RFQ 메모(내부 전용)',

  rfq_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  rfq_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (rfq_sn),
  KEY idx_rfqs_vendor (rfq_pt_sn),
  KEY idx_rfqs_creator (rfq_a_sn),
  KEY idx_rfqs_primary_sc (rfq_primary_sc_sn),
  KEY idx_rfqs_status (rfq_status),

  CONSTRAINT fk_rfqs_vendor FOREIGN KEY (rfq_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_rfqs_creator FOREIGN KEY (rfq_a_sn) REFERENCES assignees(a_sn)
) COMMENT='RFQ(견적요청서) 헤더 - 국내/해외 통합';


-- ======================================================================
-- TABLE: rfq_lines
-- DESC : RFQ 라인(견적 요청과 그 응답을 같이 기록하기록 정책 결정) - 국내/해외 통합
-- ======================================================================
CREATE TABLE rfq_lines (
  rfql_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'RFQ 라인 PK(업체에 보낸 실제 1줄) - 국내/해외 공용',
  rfq_sn BIGINT UNSIGNED NOT NULL COMMENT 'RFQ PK(rfqs)',
  rfql_no INT NOT NULL COMMENT 'RFQ 내 줄번호',
  rfql_g_sn BIGINT UNSIGNED NOT NULL COMMENT '기성상품 PK(goods)',

  /* 견적요청정보 */
  rfql_req_name VARCHAR(128) NOT NULL COMMENT '(견적요청) 품목명(예: 십자 드라이버)',
  rfql_req_model VARCHAR(128) NOT NULL default '' COMMENT '(견적요청) 모델명',
  rfql_req_qty DECIMAL(14,3) NOT NULL COMMENT '(견적요청) 수량(납품 약속 수량)',
  rfql_req_unit VARCHAR(20) NULL COMMENT '(견적요청) 단위(예: EA, SET)',
  rfql_req_unit_price DECIMAL(18,2) NULL COMMENT '(견적요청) 희망 단가',
  rfql_req_note VARCHAR(500) NULL COMMENT '라인 특이사항/요청사항(업체 전달용)',

  /* 견적응답정보 */
  rfql_res_name VARCHAR(128) NOT NULL COMMENT '(견적요청) 품목명(예: 십자 드라이버)',
  rfql_res_model VARCHAR(128) NOT NULL default '' COMMENT '(견적요청) 모델명',
  rfql_res_qty DECIMAL(14,3) NOT NULL COMMENT '(견적요청) 수량',
  rfql_res_unit VARCHAR(20) NULL COMMENT '(견적요청) 단위(예: EA, SET)',
  rfql_res_unit_price DECIMAL(18,2) NULL COMMENT '(견적요청) 견적받은 단가',
  rfql_res_note VARCHAR(500) NULL COMMENT '라인 특이사항/요청사항(업체 전달용)',

  rfql_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  rfql_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (rfql_sn),
  UNIQUE KEY uk_rfq_lines (rfq_sn, rfql_no),
  KEY idx_rfq_lines_rfq (rfq_sn),
  KEY idx_rfq_lines_g (rfql_g_sn),
  KEY idx_rfq_lines_reply_status (reply_status),

  CONSTRAINT fk_rfq_lines_rfq FOREIGN KEY (rfq_sn) REFERENCES rfqs(rfq_sn),
  CONSTRAINT fk_rfq_lines_g FOREIGN KEY (g_sn) REFERENCES goods(g_sn)
) COMMENT='RFQ 라인(요청 1줄 + 회신 값(reply_*), 덮어쓰기 정책) - 국내/해외 통합';


-- ======================================================================
-- TABLE: rfq_allocations
-- DESC : RFQ 라인 배분(여러 sc 혼합 RFQ 지원) - 국내/해외 통합
-- ======================================================================
CREATE TABLE rfq_allocations (
  rfqa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'RFQ 라인 배분 PK - 국내/해외 공용',
  rfql_sn BIGINT UNSIGNED NOT NULL COMMENT 'RFQ 라인 PK(rfq_lines)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  olo_sn BIGINT UNSIGNED NULL COMMENT 'BUNDLE/예외 구성품 식별자(선택, order_line_overrides.olo_sn)',
  allocated_qty DECIMAL(14,3) NOT NULL COMMENT '케이스 귀속 수량(내부 관리용)',
  note VARCHAR(500) NULL COMMENT '비고(배분 사유 등)',
  rfqa_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  rfqa_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (rfqa_sn),
  UNIQUE KEY uk_rfq_alloc (rfql_sn, sc_sn),
  KEY idx_rfq_alloc_rfql (rfql_sn),
  KEY idx_rfq_alloc_sc (sc_sn),
  KEY idx_rfq_alloc_olo (olo_sn),

  CONSTRAINT fk_rfq_alloc_rfql FOREIGN KEY (rfql_sn) REFERENCES rfq_lines(rfql_sn),
  CONSTRAINT fk_rfq_alloc_sc FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn),
  CONSTRAINT fk_rfq_alloc_olo FOREIGN KEY (olo_sn) REFERENCES order_line_overrides(olo_sn)
    ON DELETE SET NULL
    ON UPDATE RESTRICT
) COMMENT='RFQ 라인 배분(여러 sc 혼합 RFQ 지원) - 국내/해외 통합';


-- ======================================================================
-- TABLE: purchase_orders
-- DESC : 발주서(PO) 헤더 - 국내/해외 통합
-- ======================================================================
CREATE TABLE purchase_orders (

  po_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '발주서 PK - 국내/해외 공용',

  /* 수급 케이스 연결 */
  primary_sc_sn BIGINT UNSIGNED NULL COMMENT '대표 수급 케이스 PK(sourcing_cases) | 단독 진행이면 설정, 혼합이면 NULL 가능',
  sourcing_type ENUM('DOMESTIC','OVERSEAS','IN_HOUSE','SERVICE')
    NULL COMMENT '수급 방식(ENUM) | 헤더 편의/필터용(선택)',

  /* 업체/작성자 */
  vendor_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '대상 업체 PK(parties)',
  created_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '작성자 PK(assignees)',

  /* 근거 RFQ */
  source_rfq_sn BIGINT UNSIGNED NULL COMMENT '근거 RFQ PK(rfqs) | RFQ 기반 생성 시 연결',

  /* 발주 구분/상태 */
  po_kind ENUM('NORMAL','SAMPLE') NOT NULL DEFAULT 'NORMAL'
    COMMENT '발주 구분(ENUM) | NORMAL:본발주, SAMPLE:샘플발주',
  po_status ENUM('DRAFT','SENT','ACCEPTED','REJECTED','CANCELLED','CLOSED')
    NOT NULL COMMENT '발주 상태(ENUM)',

  /* 업무 이벤트 */
  issued_at DATETIME NOT NULL COMMENT '발주 발행일시(업무 이벤트)',
  accepted_at DATETIME NULL COMMENT '발주 수락일시(업무 이벤트)',
  expected_delivery_at DATE NULL COMMENT '예상 납기일(업무 이벤트)',

  /* 인도/납품/결제 */
  delivery_method VARCHAR(40) NULL COMMENT '발주 이후 1차 물류 방식(텍스트) | 권장: PICKUP_BY_LOGISTICS, SELLER_SHIP_TO_COMPANY, SELLER_SHIP_TO_CUSTOMER (해외 확장: FORWARDER_MANAGED, COURIER, FREIGHT_TRUCK) | 필요 시 확장 가능',
  delivery_address VARCHAR(500) NULL COMMENT '인도/납품 주소',
  trade_terms VARCHAR(20) NULL COMMENT '인도조건(Incoterms 등) | 해외용 주로 사용(옵션)',

  /* 프로세스/정책(선택) */
  fx_rate_policy ENUM('QUOTE_DATE','PO_DATE','PAYMENT_DATE','CUSTOMS_DATE','MANUAL') NULL COMMENT '환율 적용 기준(정책 ENUM) | 숫자 환율은 costs/cost_fx_applications에 고정 저장 | QUOTE_DATE:견적일, PO_DATE:발주일, PAYMENT_DATE:지급일, CUSTOMS_DATE:통관일, MANUAL:수동',

  payment_method VARCHAR(100) NULL COMMENT '결제 방식',
  payment_terms VARCHAR(200) NULL COMMENT '결제 조건',
  tax_type ENUM('TAX_INCLUDED','TAX_EXCLUDED','UNKNOWN')
    NOT NULL DEFAULT 'UNKNOWN'
    COMMENT '부가세 포함 여부(ENUM) | 국내/해외 모두 사용 가능',

  /* 해외에서만 주로 쓰는 필드(옵션) */
  ship_from_country CHAR(2) NULL COMMENT '발송국가(ISO-3166-1 alpha-2) | 예: CN, US',
  ship_to_country CHAR(2) NULL COMMENT '도착국가(ISO-3166-1 alpha-2) | 보통 KR',

  po_note VARCHAR(500) NULL COMMENT '발주 메모(헤더)',

  po_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  po_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (po_sn),
  KEY idx_pos_vendor (vendor_pt_sn),
  KEY idx_pos_creator (created_by_a_sn),
  KEY idx_pos_primary_sc (primary_sc_sn),
  KEY idx_pos_source_rfq (source_rfq_sn),
  KEY idx_pos_status (po_status),
  KEY idx_pos_sourcing_type (sourcing_type),

  CONSTRAINT fk_pos_vendor FOREIGN KEY (vendor_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_pos_creator FOREIGN KEY (created_by_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_pos_primary_sc FOREIGN KEY (primary_sc_sn) REFERENCES sourcing_cases(sc_sn),
  CONSTRAINT fk_pos_source_rfq FOREIGN KEY (source_rfq_sn) REFERENCES rfqs(rfq_sn)

) COMMENT='발주서(PO) 헤더 - 국내/해외 통합';


-- ======================================================================
-- TABLE: po_lines
-- DESC : 발주서 라인(PO 한줄) - 국내/해외 통합
-- ======================================================================
CREATE TABLE po_lines (
  pol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '발주서 라인 PK(업체에 보낸 실제 1줄) - 국내/해외 공용',
  po_sn BIGINT UNSIGNED NOT NULL COMMENT '발주서 PK(purchase_orders)',
  line_no INT NOT NULL COMMENT '발주서 내 줄번호',

  /* 품목 */
  g_sn BIGINT UNSIGNED NOT NULL COMMENT '기성상품 PK(goods)',
  qty DECIMAL(14,3) NOT NULL COMMENT '발주 수량(MOQ 등으로 더 클 수 있음)',

  /* 가격/통화(해외 포함) */
  unit_cost DECIMAL(18,2) NULL COMMENT '발주 단가(확정값)',
  currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '발주 통화(예: KRW, USD)',

  line_note VARCHAR(500) NULL COMMENT '라인 특이사항/요청사항(업체 전달용)',

  /* 샘플 관련 */
  is_sample TINYINT(1) NOT NULL DEFAULT 0 COMMENT '샘플 라인 여부(0/1)',
  sample_disposition ENUM('DISCARD','KEEP_INTERNAL','INCLUDE_IN_DELIVERY') NULL
    COMMENT '샘플 처리(ENUM) | DISCARD:폐기, KEEP_INTERNAL:내부보관, INCLUDE_IN_DELIVERY:납품포함',

  /* 근거 */
  source_rfql_sn BIGINT UNSIGNED NULL COMMENT '근거 RFQ 라인 PK(rfq_lines) | 선택',
  source_note VARCHAR(500) NULL COMMENT '근거 설명(구두견적/메일 등)',

  pol_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pol_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pol_sn),
  UNIQUE KEY uk_po_lines (po_sn, line_no),
  KEY idx_po_lines_po (po_sn),
  KEY idx_po_lines_g (g_sn),
  KEY idx_po_lines_source_rfql (source_rfql_sn),

  CONSTRAINT fk_po_lines_po FOREIGN KEY (po_sn) REFERENCES purchase_orders(po_sn),
  CONSTRAINT fk_po_lines_g FOREIGN KEY (g_sn) REFERENCES goods(g_sn),
  CONSTRAINT fk_po_lines_source_rfql FOREIGN KEY (source_rfql_sn) REFERENCES rfq_lines(rfql_sn)
) COMMENT='발주서 라인(PO 한줄) - 국내/해외 통합';


-- ======================================================================
-- TABLE: po_allocations
-- DESC : 발주 라인 배분(여러 sc 혼합 PO 지원) - 국내/해외 통합
-- ======================================================================
CREATE TABLE po_allocations (
  pa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '발주 라인 배분 PK - 국내/해외 공용',
  pol_sn BIGINT UNSIGNED NOT NULL COMMENT '발주 라인 PK(po_lines)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  olo_sn BIGINT UNSIGNED NULL COMMENT 'BUNDLE/예외 구성품 식별자(선택, order_line_overrides.olo_sn)',
  allocated_qty DECIMAL(14,3) NOT NULL COMMENT '케이스 귀속 수량(내부 관리용)',
  note VARCHAR(500) NULL COMMENT '비고(배분 사유 등)',
  pa_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pa_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pa_sn),
  UNIQUE KEY uk_po_alloc (pol_sn, sc_sn),
  KEY idx_po_alloc_pol (pol_sn),
  KEY idx_po_alloc_sc (sc_sn),
  KEY idx_po_alloc_olo (olo_sn),

  CONSTRAINT fk_po_alloc_pol FOREIGN KEY (pol_sn) REFERENCES po_lines(pol_sn),
  CONSTRAINT fk_po_alloc_sc FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn),
  CONSTRAINT fk_po_alloc_olo FOREIGN KEY (olo_sn) REFERENCES order_line_overrides(olo_sn)
    ON DELETE SET NULL
    ON UPDATE RESTRICT
) COMMENT='발주 라인 배분(여러 sc 혼합 PO 지원) - 국내/해외 통합';

ALTER TABLE departments
  ADD CONSTRAINT fk_departments_manager
  FOREIGN KEY (manager_a_sn) REFERENCES assignees(a_sn);

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

중요 변경 요약(기존 v7.8.2 대비)
- (삭제/대체 개념) cost_documents, payment_documents, shipment_documents, shipment_milestone_documents
  -> (대체) documents, document_links
- 비용 단계 근거는 shipment_milestone_cost_links(단계↔비용 링크)로 유지하며,
  문서는 해당 cost/payable/shipment/milestone/job 등에 document_links로 연결한다.

주의
- ALTER 없이 CREATE TABLE만 제공한다.
- target_type/target_sn은 polymorphic 참조로 FK를 강제하지 않는다(운영 정책/검증으로 보장).

버전: v7.8.2
작성일: 2026-01-19 (Asia/Seoul)
*/

/* 문서 허브: 모든 파일/서류는 여기로 수집 */
CREATE TABLE IF NOT EXISTS documents (
  doc_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'PK',
  doc_category VARCHAR(30) NOT NULL COMMENT '문서 카테고리: COST, PAYMENT, INVOICE, DELIVERY, CUSTOMS, QUALITY, CONTRACT, OTHER',
  doc_type VARCHAR(40) NOT NULL COMMENT '문서 타입(코드): 예) SELLER_RECEIPT, CARD_SLIP, BANK_TRANSFER_PROOF, TAX_INVOICE, STATEMENT, BL, AWB, PACKING_LIST, CUSTOMS_DOC, DELIVERY_PROOF, INSPECTION_REPORT, PHOTO, OTHER',
  issuer_name VARCHAR(120) NULL COMMENT '발행처/제공처(거래처/포워더/관세사/창고/검사기관 등)',
  issuer_party_sn BIGINT UNSIGNED NULL COMMENT 'parties.pt_sn (가능하면)',
  doc_no VARCHAR(80) NULL COMMENT '문서번호(있으면)',
  doc_date DATE NULL COMMENT '문서일자(있으면)',
  currency CHAR(3) NULL COMMENT '문서 금액 통화(있으면)',
  amount DECIMAL(18,2) NULL COMMENT '문서 금액(있으면)',
  tax_amount DECIMAL(18,2) NULL COMMENT '세액(있으면)',
  file_key VARCHAR(255) NOT NULL COMMENT '파일 식별자(스토리지 경로/키)',
  file_name VARCHAR(255) NULL COMMENT '원본 파일명(선택)',
  mime_type VARCHAR(80) NULL COMMENT 'MIME 타입(선택)',
  note VARCHAR(255) NULL COMMENT '비고',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  created_by_a_sn BIGINT UNSIGNED NULL COMMENT 'actors.a_sn (업로더/등록자)',
  KEY idx_doc_category_type (doc_category, doc_type),
  KEY idx_doc_issuer_party (issuer_party_sn),
  KEY idx_doc_docno (doc_no),
  KEY idx_doc_date (doc_date)
) COMMENT='문서 허브: 모든 증빙/서류/파일을 단일 테이블로 저장';

/* 문서 연결: 문서가 어떤 엔티티의 근거/증빙인지 연결(다대다) */
CREATE TABLE IF NOT EXISTS document_links (
  dl_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'PK',
  doc_sn BIGINT UNSIGNED NOT NULL COMMENT 'documents.doc_sn',
  target_type VARCHAR(30) NOT NULL COMMENT '연결 대상 타입: COST, PAYMENT, INVOICE, PAYABLE, PO, PO_LINE, SHIPMENT, SHIPMENT_MILESTONE, JOB, JOB_STOP, INVENTORY_UNIT, ORDER, ORDER_LINE, CONTRACT, OTHER',
  target_sn BIGINT UNSIGNED NOT NULL COMMENT '연결 대상 PK (type별로 의미)',
  link_role VARCHAR(30) NOT NULL DEFAULT 'EVIDENCE' COMMENT '연결 역할: EVIDENCE(근거), PROOF(완료증빙), REFERENCE(참고), REQUEST(요청서), OUTPUT(산출물)',
  note VARCHAR(255) NULL COMMENT '비고',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  UNIQUE KEY uk_dl_doc_target (doc_sn, target_type, target_sn, link_role),
  KEY idx_dl_target (target_type, target_sn),
  CONSTRAINT fk_dl_doc FOREIGN KEY (doc_sn) REFERENCES documents(doc_sn)
) COMMENT='문서 ↔ 업무/재무 엔티티 연결(다대다, polymorphic)';

/* 선택: 문서 간 관계(원본/정정/대체/첨부 묶음) */
CREATE TABLE IF NOT EXISTS document_relations (
  dr_sn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'PK',
  parent_doc_sn BIGINT UNSIGNED NOT NULL COMMENT '상위/원본 documents.doc_sn',
  child_doc_sn BIGINT UNSIGNED NOT NULL COMMENT '하위/첨부/정정 documents.doc_sn',
  relation_type VARCHAR(30) NOT NULL COMMENT '관계: ATTACHMENT, REVISION, REPLACEMENT, TRANSLATION, BUNDLE_MEMBER',
  note VARCHAR(255) NULL COMMENT '비고',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  UNIQUE KEY uk_dr_parent_child (parent_doc_sn, child_doc_sn, relation_type),
  CONSTRAINT fk_dr_parent FOREIGN KEY (parent_doc_sn) REFERENCES documents(doc_sn),
  CONSTRAINT fk_dr_child FOREIGN KEY (child_doc_sn) REFERENCES documents(doc_sn)
) COMMENT='문서 간 관계(첨부/정정/대체/묶음 등)';
