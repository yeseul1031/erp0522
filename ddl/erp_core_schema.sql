/* =======================================================================
 * Balhea ERP - Core Schema (DDL)
 * -----------------------------------------------------------------------
 * 목적
 * - 프로젝트/주문/수급(국내·해외·자체제작)과 RFQ/PO(견적/발주)까지의 핵심 도메인
 * - 99% 경로(order_lines.ol_default_g_sn) + 1% 예외(order_line_overrides) 패턴 유지
 * - 주석/ENUM/코드값 설명은 운영자/개발자 가이드 역할을 하므로 축약하지 않음
 * ======================================================================= */


-- ======================================================================
-- TABLE: departments
-- DESC : 부서(조직 단위)
-- ======================================================================
CREATE TABLE departments (
  d_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '부서 PK',
  name VARCHAR(100) NOT NULL COMMENT '부서명',
  manager_a_sn BIGINT UNSIGNED NULL COMMENT '부서 매니저(팀장) 담당자 PK',
  d_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  d_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (d_sn),
  UNIQUE KEY uk_departments_name (name)
) COMMENT='부서(조직 단위)';


-- ======================================================================
-- TABLE: assignees
-- DESC : 업무 담당자(직원/협업 담당자 공용)
-- ======================================================================
CREATE TABLE assignees (
  a_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '담당자 PK',
  d_sn BIGINT UNSIGNED NULL COMMENT '부서 PK',
  name VARCHAR(100) NOT NULL COMMENT '담당자 이름',
  email VARCHAR(255) NULL COMMENT '이메일',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '재직/활성 여부(1=활성, 0=비활성)',
  a_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  a_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (a_sn),
  KEY idx_assignees_d_sn (d_sn),
  KEY idx_assignees_email (email),
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
  name VARCHAR(255) NOT NULL COMMENT '업체명',
  country_code CHAR(2) NULL COMMENT '국가코드(ISO 2자리, 예: KR, US)',
  biz_no VARCHAR(50) NULL COMMENT '사업자번호/등록번호',
  contact_name VARCHAR(100) NULL COMMENT '담당자명',
  contact_phone VARCHAR(50) NULL COMMENT '연락처',
  contact_email VARCHAR(255) NULL COMMENT '이메일',
  pt_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pt_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (pt_sn),
  KEY idx_parties_name (name)
) COMMENT='업체/기관(고객사/공급사/물류/중개 등)';


-- ======================================================================
-- TABLE: projects
-- DESC : 프로젝트(=계약)
-- ======================================================================
CREATE TABLE projects (
  p_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '프로젝트(=계약 통합) PK',
  project_code VARCHAR(50) NOT NULL COMMENT '내부 관리 코드(유니크)',
  project_name VARCHAR(255) NOT NULL COMMENT '프로젝트명',
  project_type ENUM('TENDER','DIRECT','FRAME')
    NOT NULL COMMENT '프로젝트 유형(ENUM) | TENDER:입찰(공공/민간), DIRECT:직접계약, FRAME:기간/다건 계약(프레임/콜오프)',
  customer_pt_sn BIGINT UNSIGNED NULL COMMENT '고객사 PK(parties)',
  contract_no VARCHAR(100) NULL COMMENT '계약서 번호(외부 식별자, 계약 전 NULL 가능)',
  signed_at DATE NULL COMMENT '계약 체결일(계약 전 NULL 가능)',
  contract_amount DECIMAL(18,2) NULL COMMENT '계약 총액(계약 전 NULL 가능)',
  currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화(예: KRW, USD)',
  p_status ENUM('PRE_CONTRACT','ACTIVE','CLOSED','CANCELLED')
    NOT NULL COMMENT '프로젝트 상태(ENUM) | PRE_CONTRACT:계약전/입찰검토, ACTIVE:진행, CLOSED:종료, CANCELLED:취소',
  current_manager_a_sn BIGINT UNSIGNED NOT NULL COMMENT '현재 프로젝트 담당자 PK(assignees)',
  started_at DATETIME NULL COMMENT '프로젝트 시작일시(업무 이벤트)',
  ended_at DATETIME NULL COMMENT '프로젝트 종료일시(업무 이벤트)',
  p_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  p_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (p_sn),
  UNIQUE KEY uk_projects_project_code (project_code),
  KEY idx_projects_customer_pt_sn (customer_pt_sn),
  KEY idx_projects_manager (current_manager_a_sn),
  KEY idx_projects_status (p_status),
  CONSTRAINT fk_projects_customer
    FOREIGN KEY (customer_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_projects_manager
    FOREIGN KEY (current_manager_a_sn) REFERENCES assignees(a_sn)
) COMMENT='프로젝트(=계약)';


-- ======================================================================
-- TABLE: orders
-- DESC : 주문서(프로젝트 하위)
-- ======================================================================
CREATE TABLE orders (
  o_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문서 PK',
  p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects)',
  order_no VARCHAR(100) NULL COMMENT '주문서 번호(외부/내부 식별용)',
  order_type ENUM('CONTRACT_ORDER','PRE_CONTRACT_ORDER')
    NOT NULL DEFAULT 'CONTRACT_ORDER'
    COMMENT '주문서 유형(ENUM) | CONTRACT_ORDER:실제 주문서, PRE_CONTRACT_ORDER:계약전(입찰검토/사전견적) 용도',
  o_status ENUM('OPEN','IN_PROGRESS','CLOSED','CANCELLED')
    NOT NULL COMMENT '주문서 상태(ENUM) | OPEN:오픈, IN_PROGRESS:진행, CLOSED:종결, CANCELLED:취소',
  ordered_at DATETIME NULL COMMENT '주문서 생성/접수 일시(업무 이벤트)',
  memo VARCHAR(500) NULL COMMENT '메모',
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
-- ======================================================================
CREATE TABLE order_lines (
  ol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문라인 PK',
  o_sn BIGINT UNSIGNED NOT NULL COMMENT '주문서 PK(orders)',
  line_no INT NOT NULL COMMENT '주문서 내 라인 번호',
  requirement_name VARCHAR(255) NOT NULL COMMENT '요구 품목명(예: 십자 드라이버)',
  requirement_spec_json JSON NULL COMMENT '요구 규격/조건(자유형 JSON)',
  qty_required DECIMAL(14,3) NOT NULL COMMENT '요구 수량(납품 약속 수량)',
  ol_default_g_sn BIGINT UNSIGNED NULL COMMENT '기본 수급 기성상품 PK(goods) | 99% 케이스에서 사용',
  unit VARCHAR(20) NULL COMMENT '단위(예: EA, SET)',
  unit_price_sales DECIMAL(18,2) NULL COMMENT '판매 단가(고객에 납품 단가, 모르면 NULL)',
  ol_status ENUM('OPEN','IN_PROGRESS','DELIVERED','CANCELLED')
    NOT NULL COMMENT '라인 상태(ENUM) | OPEN:오픈, IN_PROGRESS:진행, DELIVERED:납품완료, CANCELLED:취소',
  due_date DATE NULL COMMENT '납품 예정일(업무 이벤트)',
  ol_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ol_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ol_sn),
  UNIQUE KEY uk_order_lines_order_line_no (o_sn, line_no),
  KEY idx_order_lines_o_sn (o_sn),
  KEY idx_order_lines_status (ol_status),
  KEY idx_order_lines_default_g (ol_default_g_sn),
  CONSTRAINT fk_order_lines_orders
    FOREIGN KEY (o_sn) REFERENCES orders(o_sn),
  CONSTRAINT fk_order_lines_default_g
    FOREIGN KEY (ol_default_g_sn) REFERENCES goods(g_sn)
) COMMENT='주문라인(고객 요구/납품 약속 단위)';


-- ======================================================================
-- TABLE: order_line_overrides
-- DESC : 주문라인 희소 케이스(분할/대체/추가/조합) 지원
-- ======================================================================
CREATE TABLE order_line_overrides (
  olo_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문라인 예외(override) PK',
  ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines)',
  override_type ENUM('SPLIT','SUBSTITUTE','ADD_ON','BUNDLE')
    NOT NULL COMMENT '예외 유형(ENUM) | SPLIT:분할구매, SUBSTITUTE:대체품, ADD_ON:추가구매, BUNDLE:조합구성품',
  g_sn BIGINT UNSIGNED NULL COMMENT '대상 기성상품 PK(goods) | BUNDLE/SUBSTITUTE 등에서 사용',
  qty DECIMAL(14,3) NOT NULL COMMENT 'override 수량',
  note VARCHAR(500) NULL COMMENT '사유/메모',
  olo_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  olo_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (olo_sn),
  KEY idx_olo_ol (ol_sn),
  KEY idx_olo_g (g_sn),
  KEY idx_olo_type (override_type),
  CONSTRAINT fk_olo_ol
    FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn),
  CONSTRAINT fk_olo_g
    FOREIGN KEY (g_sn) REFERENCES goods(g_sn)
) COMMENT='주문라인 희소 케이스(분할/대체/추가/조합) 지원';


-- ======================================================================
-- TABLE: sourcing_cases
-- DESC : 수급 케이스(주문라인 단위 공통 컨테이너)
-- ======================================================================
CREATE TABLE sourcing_cases (
  sc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수급 케이스 PK',
  ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines) (1:1)',
  sourcing_type ENUM('DOMESTIC','OVERSEAS','IN_HOUSE')
    NOT NULL COMMENT '수급 방식(ENUM) | DOMESTIC:국내구매, OVERSEAS:해외구매, IN_HOUSE:자체제작',
  sourcing_assignee_a_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 수행 담당자 PK(assignees) | 협업 담당자 또는 프로젝트 담당자',
  sc_status ENUM('OPEN','IN_PROGRESS','READY_TO_HANDOFF','HANDED_OFF','CANCELLED')
    NOT NULL COMMENT '수급 케이스 상태(ENUM) | OPEN:오픈, IN_PROGRESS:진행, READY_TO_HANDOFF:인계준비, HANDED_OFF:인계완료, CANCELLED:취소',
  handed_off_to_a_sn BIGINT UNSIGNED NULL COMMENT '인계 대상자 PK(assignees) | 보통 프로젝트 담당자',
  handed_off_at DATETIME NULL COMMENT '인계일시(업무 이벤트)',
  summary VARCHAR(500) NULL COMMENT '진행 요약(담당자 메모)',
  sc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (sc_sn),
  UNIQUE KEY uk_sourcing_cases_ol_sn (ol_sn),
  KEY idx_sourcing_cases_assignee (sourcing_assignee_a_sn),
  KEY idx_sourcing_cases_status (sc_status),
  CONSTRAINT fk_sourcing_cases_order_lines
    FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn),
  CONSTRAINT fk_sourcing_cases_assignee
    FOREIGN KEY (sourcing_assignee_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_sourcing_cases_handoff_to
    FOREIGN KEY (handed_off_to_a_sn) REFERENCES assignees(a_sn)
) COMMENT='수급 케이스(주문라인 단위 공통 컨테이너)';


-- ======================================================================
-- TABLE: domestic_cases
-- DESC : 국내 수급 케이스(시도 인스턴스)
-- ======================================================================
CREATE TABLE domestic_cases (
  dc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '국내 수급 케이스 PK(시도 인스턴스)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  note VARCHAR(500) NULL COMMENT '비고',
  dc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (dc_sn),
  KEY idx_domestic_cases_sc_sn (sc_sn),
  CONSTRAINT fk_domestic_cases_sc
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='국내 수급 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: goods
-- DESC : 기성상품(재사용 카탈로그/품목 마스터)
-- ======================================================================
CREATE TABLE goods (
  g_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '기성상품 PK',
  manufacturer_name VARCHAR(64) NULL COMMENT '제조사명(텍스트, 예: 삼성전자 / Panasonic / 华为)',
  goods_name VARCHAR(255) NOT NULL COMMENT '상품명(카탈로그명)',
  model_no VARCHAR(100) NULL COMMENT '모델번호',
  spec_json JSON NULL COMMENT '규격/옵션(JSON)',
  note VARCHAR(500) NULL COMMENT '비고',
  g_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  g_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (g_sn),
  KEY idx_goods_name (goods_name),
  KEY idx_goods_manufacturer_name (manufacturer_name)
) COMMENT='기성상품(재사용 카탈로그/품목 마스터)';


-- ======================================================================
-- TABLE: overseas_cases
-- DESC : 해외 수급 케이스(시도 인스턴스)
-- ======================================================================
CREATE TABLE overseas_cases (
  oc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '해외 수급 케이스 PK(시도 인스턴스)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  incoterms VARCHAR(20) NULL COMMENT '인코텀즈',
  currency CHAR(3) NULL COMMENT '거래 통화',
  etd DATE NULL COMMENT '출항 예정일(업무 이벤트)',
  eta DATE NULL COMMENT '도착 예정일(업무 이벤트)',
  tracking_no VARCHAR(100) NULL COMMENT '트래킹 번호',
  customs_status VARCHAR(50) NULL COMMENT '통관 상태',
  note VARCHAR(500) NULL COMMENT '비고',
  oc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  oc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (oc_sn),
  KEY idx_overseas_cases_sc (sc_sn),
  CONSTRAINT fk_overseas_cases_sc
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='해외 수급 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: overseas_steps
-- DESC : 해외 수급 단계(체크리스트)
-- ======================================================================
CREATE TABLE overseas_steps (
  os_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '해외 단계 PK',
  oc_sn BIGINT UNSIGNED NOT NULL COMMENT '해외 케이스 PK(overseas_cases)',
  step_code ENUM('RFQ','SUPPLIER_SELECTED','PAYMENT','SHIPMENT','CUSTOMS','DELIVERY','QC')
    NOT NULL COMMENT '단계 코드(ENUM) | RFQ:견적요청, SUPPLIER_SELECTED:업체선정, PAYMENT:결제, SHIPMENT:선적, CUSTOMS:통관, DELIVERY:인도, QC:검수',
  os_status ENUM('TODO','DOING','DONE','BLOCKED','CANCELLED')
    NOT NULL COMMENT '단계 상태(ENUM) | TODO:대기, DOING:진행, DONE:완료, BLOCKED:이슈, CANCELLED:취소',
  started_at DATETIME NULL COMMENT '시작일시(업무 이벤트)',
  done_at DATETIME NULL COMMENT '완료일시(업무 이벤트)',
  note VARCHAR(500) NULL COMMENT '비고',
  os_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  os_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (os_sn),
  KEY idx_overseas_steps_oc (oc_sn),
  KEY idx_overseas_steps_status (os_status),
  CONSTRAINT fk_overseas_steps_oc
    FOREIGN KEY (oc_sn) REFERENCES overseas_cases(oc_sn)
) COMMENT='해외 수급 단계(체크리스트)';


-- ======================================================================
-- TABLE: inhouse_cases
-- DESC : 자체제작 케이스(시도 인스턴스)
-- ======================================================================
CREATE TABLE inhouse_cases (
  ic_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '자체제작 케이스 PK(시도 인스턴스)',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  product_name VARCHAR(255) NOT NULL COMMENT '제작품명(프로젝트성, 재사용 카탈로그 아님)',
  drawing_ref VARCHAR(255) NULL COMMENT '도면 참조',
  planned_start DATE NULL COMMENT '계획 시작일(업무 이벤트)',
  planned_finish DATE NULL COMMENT '계획 종료일(업무 이벤트)',
  qc_required TINYINT(1) NOT NULL DEFAULT 1 COMMENT '검수 필요 여부(1=필요, 0=불필요)',
  note VARCHAR(500) NULL COMMENT '비고',
  ic_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ic_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ic_sn),
  KEY idx_inhouse_cases_sc (sc_sn),
  CONSTRAINT fk_inhouse_cases_sc
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='자체제작 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: inhouse_bom_lines
-- DESC : 자체제작 BOM(자재 소요)
-- ======================================================================
CREATE TABLE inhouse_bom_lines (
  ibl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '제작 BOM 라인 PK',
  ic_sn BIGINT UNSIGNED NOT NULL COMMENT '자체제작 케이스 PK(inhouse_cases)',
  material_name VARCHAR(255) NOT NULL COMMENT '자재명',
  qty_required DECIMAL(14,3) NOT NULL COMMENT '필요 수량',
  unit VARCHAR(20) NULL COMMENT '단위',
  note VARCHAR(500) NULL COMMENT '비고',
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
  process_name VARCHAR(255) NOT NULL COMMENT '공정/작업명',
  iwo_status ENUM('TODO','DOING','DONE','BLOCKED','CANCELLED')
    NOT NULL COMMENT '작업 상태(ENUM) | TODO:대기, DOING:진행, DONE:완료, BLOCKED:이슈, CANCELLED:취소',
  started_at DATETIME NULL COMMENT '작업 시작일시(업무 이벤트)',
  done_at DATETIME NULL COMMENT '작업 완료일시(업무 이벤트)',
  note VARCHAR(500) NULL COMMENT '비고',
  iwo_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  iwo_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (iwo_sn),
  KEY idx_inhouse_work_orders_ic (ic_sn),
  KEY idx_inhouse_work_orders_status (iwo_status),
  CONSTRAINT fk_inhouse_work_orders_ic
    FOREIGN KEY (ic_sn) REFERENCES inhouse_cases(ic_sn)
) COMMENT='자체제작 작업지시/공정';


-- ======================================================================
-- TABLE: activity_logs
-- DESC : 행위 로그(요약)
-- ======================================================================
CREATE TABLE activity_logs (
  al_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '행위 로그 PK',
  actor_a_sn BIGINT UNSIGNED NOT NULL COMMENT '행위 수행자 PK(assignees)',
  action_code VARCHAR(100) NOT NULL COMMENT '행위 코드(예: PROJECT_UPDATED, SOURCING_ASSIGNEE_CHANGED, RFQ_SENT, RFQ_REPLY_UPDATED, PO_SENT 등)',
  target_table VARCHAR(100) NOT NULL COMMENT '대상 테이블명',
  target_pk BIGINT UNSIGNED NOT NULL COMMENT '대상 PK 값',
  p_sn BIGINT UNSIGNED NULL COMMENT '관련 프로젝트 PK(검색 편의)',
  occurred_at DATETIME NOT NULL COMMENT '발생일시(업무 이벤트)',
  summary VARCHAR(500) NULL COMMENT '요약',
  metadata_json JSON NULL COMMENT '부가 정보(JSON)',
  al_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  PRIMARY KEY (al_sn),
  KEY idx_activity_logs_actor (actor_a_sn),
  KEY idx_activity_logs_project (p_sn),
  KEY idx_activity_logs_target (target_table, target_pk),
  CONSTRAINT fk_activity_logs_actor
    FOREIGN KEY (actor_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_activity_logs_project
    FOREIGN KEY (p_sn) REFERENCES projects(p_sn)
) COMMENT='행위 로그(요약)';


-- ======================================================================
-- TABLE: audit_changes
-- DESC : 변경 상세(diff/스냅샷)
-- ======================================================================
CREATE TABLE audit_changes (
  ac_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '변경 상세 PK',
  al_sn BIGINT UNSIGNED NOT NULL COMMENT '행위 로그 PK(activity_logs)',
  target_table VARCHAR(100) NOT NULL COMMENT '대상 테이블명',
  target_pk BIGINT UNSIGNED NOT NULL COMMENT '대상 PK 값',
  changed_fields_json JSON NOT NULL COMMENT '변경된 필드 diff(JSON: from/to)',
  before_json JSON NULL COMMENT '변경 전 스냅샷(JSON, 필요 시)',
  after_json JSON NULL COMMENT '변경 후 스냅샷(JSON, 필요 시)',
  ac_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  PRIMARY KEY (ac_sn),
  KEY idx_audit_changes_al (al_sn),
  KEY idx_audit_changes_target (target_table, target_pk),
  CONSTRAINT fk_audit_changes_activity
    FOREIGN KEY (al_sn) REFERENCES activity_logs(al_sn)
) COMMENT='변경 상세(diff/스냅샷)';


-- ======================================================================
-- TABLE: rfqs
-- DESC : RFQ(견적요청서) 헤더 - 국내/해외 통합
-- ======================================================================
CREATE TABLE rfqs (
  rfq_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'RFQ PK(견적요청서) - 국내/해외 공용',

  /* 수급 케이스 연결 */
  primary_sc_sn BIGINT UNSIGNED NULL COMMENT '대표 수급 케이스 PK(sourcing_cases) | 단독 진행이면 설정, 혼합 RFQ면 NULL 가능',
  sourcing_type ENUM('DOMESTIC','OVERSEAS','IN_HOUSE')
    NULL COMMENT '수급 방식(ENUM) | sourcing_cases.sourcing_type와 동일. 헤더 단위 편의/필터용(선택)',

  /* 업체/작성자 */
  vendor_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '대상 업체 PK(parties)',
  created_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '작성자 PK(assignees)',

  /* 상태 */
  rfq_status ENUM('DRAFT','SENT','REPLIED','CANCELLED','CLOSED')
    NOT NULL COMMENT 'RFQ 상태(ENUM)',

  /* 업무 이벤트 */
  issued_at DATETIME NOT NULL COMMENT 'RFQ 발행/발송일시(업무 이벤트)',
  valid_until DATE NULL COMMENT 'RFQ 유효기한(요청 시)',

  /* 해외에서만 주로 쓰는 필드(옵션) */
  trade_terms VARCHAR(20) NULL COMMENT '인도조건(Incoterms 등) | 예: EXW, FOB, CIF, DDP',
  ship_from_country CHAR(2) NULL COMMENT '발송국가(ISO-3166-1 alpha-2) | 예: CN, US',
  ship_to_country CHAR(2) NULL COMMENT '도착국가(ISO-3166-1 alpha-2) | 보통 KR',

  memo VARCHAR(500) NULL COMMENT 'RFQ 메모(헤더 단위)',

  rfq_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  rfq_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (rfq_sn),
  KEY idx_rfqs_vendor (vendor_pt_sn),
  KEY idx_rfqs_creator (created_by_a_sn),
  KEY idx_rfqs_primary_sc (primary_sc_sn),
  KEY idx_rfqs_status (rfq_status),
  KEY idx_rfqs_sourcing_type (sourcing_type),

  CONSTRAINT fk_rfqs_vendor FOREIGN KEY (vendor_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_rfqs_creator FOREIGN KEY (created_by_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_rfqs_primary_sc FOREIGN KEY (primary_sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='RFQ(견적요청서) 헤더 - 국내/해외 통합';


-- ======================================================================
-- TABLE: rfq_lines
-- DESC : RFQ 라인(요청 1줄 + 회신 값(reply_*), 덮어쓰기 정책) - 국내/해외 통합
-- ======================================================================
CREATE TABLE rfq_lines (
  rfql_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'RFQ 라인 PK(업체에 보낸 실제 1줄) - 국내/해외 공용',
  rfq_sn BIGINT UNSIGNED NOT NULL COMMENT 'RFQ PK(rfqs)',
  line_no INT NOT NULL COMMENT 'RFQ 내 줄번호',

  /* 품목 */
  g_sn BIGINT UNSIGNED NOT NULL COMMENT '기성상품 PK(goods)',
  qty DECIMAL(14,3) NOT NULL COMMENT '견적 요청 수량(MOQ 고려)',

  /* 요청 힌트 */
  unit_cost_hint DECIMAL(18,2) NULL COMMENT '희망/참고 단가(선택)',
  currency_hint CHAR(3) NULL COMMENT '희망 통화(선택) | 예: KRW, USD',
  line_note VARCHAR(500) NULL COMMENT '라인 특이사항/요청사항(업체 전달용)',

  /* 회신(Reply) */
  reply_status ENUM('PENDING','REPLIED','DECLINED')
    NOT NULL DEFAULT 'PENDING'
    COMMENT '회신 상태(ENUM)',
  replied_at DATETIME NULL COMMENT '회신일시(업무 이벤트)',
  reply_unit_cost DECIMAL(18,2) NULL COMMENT '회신 단가(덮어쓰기)',
  reply_currency CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '회신 통화(예: KRW, USD)',
  reply_lead_time_days INT NULL COMMENT '회신 납기(리드타임) 일수(선택)',
  reply_note VARCHAR(500) NULL COMMENT '회신 비고(업체 코멘트)',
  is_selected TINYINT(1) NOT NULL DEFAULT 0 COMMENT '선정 여부(1=선정, 0=미선정)',

  rfql_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  rfql_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (rfql_sn),
  UNIQUE KEY uk_rfq_lines (rfq_sn, line_no),
  KEY idx_rfq_lines_rfq (rfq_sn),
  KEY idx_rfq_lines_g (g_sn),
  KEY idx_rfq_lines_reply_status (reply_status),
  KEY idx_rfq_lines_selected (is_selected),

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

  memo VARCHAR(500) NULL COMMENT '발주 메모(헤더)',

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
