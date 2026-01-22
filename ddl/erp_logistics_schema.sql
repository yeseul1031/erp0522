/* =======================================================================
 * Balhea ERP - Logistics/Delivery Schema (DDL)
 * -----------------------------------------------------------------------
 * 목적
 * - 납품/물류 실행 레이어
 * - 문서(RFQ/PO) vs 실물(바코드 inventory_units) vs 작업(logistics_jobs) 분리
 * ======================================================================= */


-- ======================================================================
-- TABLE: deliveries
-- DESC : 납품(헤더)
-- ======================================================================
CREATE TABLE deliveries (
  dv_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '납품 PK',
  p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects)',
  delivered_at DATETIME NOT NULL COMMENT '납품일시(업무 이벤트)',
  memo VARCHAR(500) NULL COMMENT '메모',
  created_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  dv_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dv_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (dv_sn),
  KEY idx_deliveries_p (p_sn),
  CONSTRAINT fk_deliveries_project
    FOREIGN KEY (p_sn) REFERENCES projects(p_sn),
  CONSTRAINT fk_deliveries_creator
    FOREIGN KEY (created_by_a_sn) REFERENCES assignees(a_sn)
) COMMENT='납품(헤더)';


-- ======================================================================
-- TABLE: delivery_lines
-- DESC : 납품 라인(주문라인 분할 납품)
-- ======================================================================
CREATE TABLE delivery_lines (
  dvl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '납품 라인 PK',
  dv_sn BIGINT UNSIGNED NOT NULL COMMENT '납품 PK(deliveries)',
  ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines)',
  qty_delivered DECIMAL(14,3) NOT NULL COMMENT '납품 수량(분할 가능)',
  note VARCHAR(500) NULL COMMENT '비고',
  dvl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dvl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (dvl_sn),
  KEY idx_delivery_lines_dv (dv_sn),
  KEY idx_delivery_lines_ol (ol_sn),
  CONSTRAINT fk_delivery_lines_dv
    FOREIGN KEY (dv_sn) REFERENCES deliveries(dv_sn),
  CONSTRAINT fk_delivery_lines_ol
    FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn)
) COMMENT='납품 라인(주문라인 분할 납품)';

/* =======================================================================
 * 물류/납품(실행 레이어)
 * - 문서(RFQ/PO)와 분리: 실물(바코드)과 작업(사람 수행)을 명확히 구분
 * ======================================================================= */


-- ======================================================================
-- TABLE: shipments
-- DESC : 운송/선적(Shipment) - 흐름 단위(국내/해외 공용)
-- ======================================================================
CREATE TABLE shipments (
  sh_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '운송/선적 PK(국내/해외 공용) | 운송 단위(포워더/택배/화물 등)',

  po_sn BIGINT UNSIGNED NULL COMMENT '관련 발주서 PK(purchase_orders) | 발주와 1:1이 아닐 수 있어 NULL 허용(분할/병합)',
  vendor_pt_sn BIGINT UNSIGNED NULL COMMENT '운송사/포워더/택배사 등 업체 PK(parties) | 내부 수행이면 NULL 가능',

  sh_customs_status VARCHAR(16) NULL COMMENT '통관 상태. milestone의 최신 값 비정규화 or 정책레벨에서 지정한 값을 넣자. 구체화 필요.',
  delivery_method VARCHAR(40) NULL COMMENT '물류 방식(텍스트) | 권장: PICKUP_BY_LOGISTICS, SELLER_SHIP_TO_COMPANY, SELLER_SHIP_TO_CUSTOMER, FORWARDER_MANAGED, COURIER, FREIGHT_TRUCK | 필요 시 확장 가능',
  trade_terms VARCHAR(20) NULL COMMENT '인도조건(Incoterms 등) | 권장: EXW,FCA,FOB,CFR,CIF,CPT,CIP,DAP,DPU,DDP | 국내는 보통 NULL',
  ship_from_country CHAR(2) NULL COMMENT '출발국가(ISO-3166-1 alpha-2) | 예: CN, US',
  ship_to_country CHAR(2) NULL COMMENT '도착국가(ISO-3166-1 alpha-2) | 예: KR',

  tracking_no VARCHAR(100) NULL COMMENT '운송장/트래킹 번호(선택)',
  reference_no VARCHAR(100) NULL COMMENT '내부 참조번호(선택) | B/L, AWB, 포워더 오더번호 등',

  sh_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sh_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (sh_sn),
  KEY idx_shipments_po (po_sn),
  KEY idx_shipments_vendor (vendor_pt_sn),
  KEY idx_shipments_tracking (tracking_no),

  CONSTRAINT fk_shipments_po FOREIGN KEY (po_sn) REFERENCES purchase_orders(po_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_shipments_vendor FOREIGN KEY (vendor_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='운송/선적(Shipment) - 흐름 단위(국내/해외 공용)';


-- ======================================================================
-- TABLE: shipment_lines
-- DESC : 운송 라인(Shipment에 포함된 품목/수량)
-- ======================================================================
CREATE TABLE shipment_lines (
  shl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '운송 라인 PK | 어떤 발주 라인을 얼마나 실어 나르는지',
  sh_sn BIGINT UNSIGNED NOT NULL COMMENT '운송 PK(shipments)',
  pol_sn BIGINT UNSIGNED NOT NULL COMMENT '발주 라인 PK(po_lines)',
  qty DECIMAL(14,3) NOT NULL COMMENT '운송 수량(발주 수량과 다를 수 있음: 부분 선적)',
  note VARCHAR(200) NULL COMMENT '비고(선적 분할 사유 등)',

  shl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  shl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (shl_sn),
  UNIQUE KEY uk_shipment_lines (sh_sn, pol_sn),
  KEY idx_shipment_lines_sh (sh_sn),
  KEY idx_shipment_lines_pol (pol_sn),

  CONSTRAINT fk_shipment_lines_sh FOREIGN KEY (sh_sn) REFERENCES shipments(sh_sn),
  CONSTRAINT fk_shipment_lines_pol FOREIGN KEY (pol_sn) REFERENCES po_lines(pol_sn)
) COMMENT='운송 라인(Shipment에 포함된 품목/수량)';


-- ======================================================================
-- TABLE: shipment_milestones
-- DESC : 운송 이벤트/마일스톤(추적/증빙) 트래킹 이력 자동 수집이 안되니, 국내 해외 관계 없이 중요한 이벤트나 비용 청구 목적의 기록용으로 쓴다.
-- ======================================================================
CREATE TABLE shipment_milestones (
  sm_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '운송 이벤트 PK',
  sh_sn BIGINT UNSIGNED NOT NULL COMMENT '운송 PK(shipments)',
  milestone_type ENUM(
    'CREATED','PICKED_UP','IN_TRANSIT','ARRIVED','WAREHOUSE_IN','DELIVERED',
    'DEPARTURE','ARRIVAL_PORT','CUSTOMS_CLEARANCE_START','CUSTOMS_CLEARANCE_DONE','INSPECTION','DOMESTIC_DELIVERY'
  ) NOT NULL COMMENT '운송 이벤트 종류(ENUM) | 기본: CREATED,PICKED_UP,IN_TRANSIT,ARRIVED,WAREHOUSE_IN,DELIVERED | 해외 확장: DEPARTURE,ARRIVAL_PORT,CUSTOMS_CLEARANCE_START,CUSTOMS_CLEARANCE_DONE,INSPECTION,DOMESTIC_DELIVERY',
  occurred_at DATETIME NOT NULL COMMENT '이벤트 발생 시각(업무 이벤트)',
  location_note VARCHAR(200) NULL COMMENT '위치/메모(항만명/허브명 등)',
  evidence_doc_key VARCHAR(500) NULL COMMENT '증빙 파일 키(선택) | 송장, POD, 통관필증 등',

  sm_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sm_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (sm_sn),
  KEY idx_shipment_milestones_sh (sh_sn),
  KEY idx_shipment_milestones_type (milestone_type),
  KEY idx_shipment_milestones_occurred (occurred_at),

  CONSTRAINT fk_shipment_milestones_sh FOREIGN KEY (sh_sn) REFERENCES shipments(sh_sn)
) COMMENT='운송 이벤트/마일스톤(추적/증빙) 트래킹 이력 자동 수집이 안되니, 국내 해외 관계 없이 중요한 이벤트나 비용 청구 목적의 기록용으로 쓴다.';


-- ======================================================================
-- TABLE: inventory_units
-- DESC : 실물(바코드) 단위 - 회사 통제 하의 인벤토리
-- ======================================================================
CREATE TABLE inventory_units (
  iu_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '실물(바코드) PK | 회사가 통제하는 실물 단위',
  barcode VARCHAR(80) NOT NULL COMMENT '바코드/라벨 ID(유니크) | 내부 발급 또는 외부 라벨 매핑',

  pol_sn BIGINT UNSIGNED NULL COMMENT '출처 발주 라인 PK(po_lines) | 직송/비정형이면 NULL 가능',
  g_sn BIGINT UNSIGNED NULL COMMENT '상품 PK(goods) | pol_sn이 NULL인 경우에도 기록 권장(가능하면)',

  status ENUM('IN_TRANSIT','IN_OFFICE','IN_WAREHOUSE','RESERVED_FOR_DELIVERY','DELIVERED','DAMAGED','LOST')
    NOT NULL DEFAULT 'IN_TRANSIT'
    COMMENT '실물 상태(ENUM) | IN_TRANSIT:이동중, IN_OFFICE:사무실, IN_WAREHOUSE:창고, RESERVED_FOR_DELIVERY:납품예약, DELIVERED:납품완료, DAMAGED:파손, LOST:분실',
  location_type ENUM('VENDOR','OFFICE','WAREHOUSE','CUSTOMER','CUSTOMS','PORT','AIRPORT','IN_TRANSIT')
    NOT NULL DEFAULT 'IN_TRANSIT'
    COMMENT '현재 위치 유형(ENUM) | VENDOR/OFFICE/WAREHOUSE/CUSTOMER + 해외 확장(CUSTOMS/PORT/AIRPORT) + IN_TRANSIT',
  location_note VARCHAR(200) NULL COMMENT '현재 위치 상세(주소/창고구역/담당자 등)',

  received_at DATETIME NULL COMMENT '회사/창고에서 실물 수령 확인 시각(업무 이벤트)',
  delivered_at DATETIME NULL COMMENT '납품 완료 시각(업무 이벤트)',

  iu_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  iu_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (iu_sn),
  UNIQUE KEY uk_inventory_units_barcode (barcode),
  KEY idx_inventory_units_pol (pol_sn),
  KEY idx_inventory_units_g (g_sn),
  KEY idx_inventory_units_status (status),
  KEY idx_inventory_units_location (location_type),

  CONSTRAINT fk_inventory_units_pol FOREIGN KEY (pol_sn) REFERENCES po_lines(pol_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_inventory_units_g FOREIGN KEY (g_sn) REFERENCES goods(g_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='실물(바코드) 단위 - 회사 통제 하의 인벤토리';


-- ======================================================================
-- TABLE: delivery_requests
-- DESC : 배송 협의/요청(스케줄 조율/역제안 기록)
-- ======================================================================
CREATE TABLE delivery_requests (
  dr_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '배송 협의/요청 PK | 협의가 필요한 케이스에서 사용',
  p_sn BIGINT UNSIGNED NULL COMMENT '프로젝트 PK(projects) | 선택',
  o_sn BIGINT UNSIGNED NULL COMMENT '주문 PK(orders) | 선택',

  requested_by_a_sn BIGINT UNSIGNED NOT NULL COMMENT '요청자 PK(assignees)',
  vendor_pt_sn BIGINT UNSIGNED NULL COMMENT '협의 상대(물류/업체) PK(parties) | 내부 수행이면 NULL 가능',

  status ENUM('SUBMITTED','COUNTERED','ACCEPTED','REJECTED','CONFIRMED','CANCELED')
    NOT NULL DEFAULT 'SUBMITTED'
    COMMENT '요청 상태(ENUM) | SUBMITTED:제출, COUNTERED:역제안, ACCEPTED:수락, REJECTED:거절, CONFIRMED:확정, CANCELED:취소',

  requested_window_start DATETIME NULL COMMENT '요청 시간창 시작(선택)',
  requested_window_end DATETIME NULL COMMENT '요청 시간창 종료(선택)',

  note VARCHAR(500) NULL COMMENT '요청 메모',

  dr_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dr_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (dr_sn),
  KEY idx_delivery_requests_p (p_sn),
  KEY idx_delivery_requests_o (o_sn),
  KEY idx_delivery_requests_requester (requested_by_a_sn),
  KEY idx_delivery_requests_vendor (vendor_pt_sn),
  KEY idx_delivery_requests_status (status),

  CONSTRAINT fk_delivery_requests_p FOREIGN KEY (p_sn) REFERENCES projects(p_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_delivery_requests_o FOREIGN KEY (o_sn) REFERENCES orders(o_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_delivery_requests_requester FOREIGN KEY (requested_by_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_delivery_requests_vendor FOREIGN KEY (vendor_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='배송 협의/요청(스케줄 조율/역제안 기록)';


-- ======================================================================
-- TABLE: delivery_request_lines
-- DESC : 배송 요청 상세(대상 품목/실물)
-- ======================================================================
CREATE TABLE delivery_request_lines (
  drl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '배송 요청 라인 PK',
  dr_sn BIGINT UNSIGNED NOT NULL COMMENT '배송 요청 PK(delivery_requests)',

  ol_sn BIGINT UNSIGNED NULL COMMENT '주문라인 PK(order_lines) | 실물 생성 전 단계에서 사용 가능',
  iu_sn BIGINT UNSIGNED NULL COMMENT '실물 PK(inventory_units) | 실물 기준 납품/이동 시 사용',
  qty DECIMAL(14,3) NULL COMMENT '요청 수량(선택) | iu_sn 지정 시 보통 NULL',

  note VARCHAR(200) NULL COMMENT '비고',

  drl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  drl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (drl_sn),
  KEY idx_delivery_request_lines_dr (dr_sn),
  KEY idx_delivery_request_lines_ol (ol_sn),
  KEY idx_delivery_request_lines_iu (iu_sn),

  CONSTRAINT fk_delivery_request_lines_dr FOREIGN KEY (dr_sn) REFERENCES delivery_requests(dr_sn),
  CONSTRAINT fk_delivery_request_lines_ol FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_delivery_request_lines_iu FOREIGN KEY (iu_sn) REFERENCES inventory_units(iu_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='배송 요청 상세(대상 품목/실물)';


-- ======================================================================
-- TABLE: delivery_request_proposals
-- DESC : 배송 협의 제안/응답(역제안/수락/거절 이력)
-- ======================================================================
CREATE TABLE delivery_request_proposals (
  drp_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '배송 요청 제안/응답 PK',
  dr_sn BIGINT UNSIGNED NOT NULL COMMENT '배송 요청 PK(delivery_requests)',

  proposal_type ENUM('INITIAL','COUNTER','ACCEPT','REJECT')
    NOT NULL COMMENT '제안 유형(ENUM) | INITIAL:초기제안, COUNTER:역제안, ACCEPT:수락, REJECT:거절',

  proposed_window_start DATETIME NULL COMMENT '제안 시간창 시작(선택)',
  proposed_window_end DATETIME NULL COMMENT '제안 시간창 종료(선택)',

  proposed_by_a_sn BIGINT UNSIGNED NULL COMMENT '제안자(내부) PK(assignees) | 업체/외부면 NULL 가능',
  proposed_by_vendor_pt_sn BIGINT UNSIGNED NULL COMMENT '제안자(업체) PK(parties) | 내부면 NULL 가능',

  note VARCHAR(500) NULL COMMENT '제안 메모',
  created_at DATETIME NOT NULL COMMENT '제안 생성 시각(업무 이벤트)',

  drp_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  drp_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (drp_sn),
  KEY idx_delivery_request_proposals_dr (dr_sn),
  KEY idx_delivery_request_proposals_type (proposal_type),
  KEY idx_delivery_request_proposals_created (created_at),

  CONSTRAINT fk_delivery_request_proposals_dr FOREIGN KEY (dr_sn) REFERENCES delivery_requests(dr_sn),
  CONSTRAINT fk_delivery_request_proposals_proposer_a FOREIGN KEY (proposed_by_a_sn) REFERENCES assignees(a_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_delivery_request_proposals_proposer_vendor FOREIGN KEY (proposed_by_vendor_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='배송 협의 제안/응답(역제안/수락/거절 이력)';


-- ======================================================================
-- TABLE: logistics_jobs
-- DESC : 물류 작업(사람/업체가 수행)
-- ======================================================================
CREATE TABLE logistics_jobs (
  lj_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '물류 작업 PK | 사람이 수행하는 작업 단위',

  job_type ENUM('PICKUP','TRANSFER','DELIVERY','MIXED')
    NOT NULL COMMENT '작업 종류(ENUM) | PICKUP:수거, TRANSFER:이동, DELIVERY:납품, MIXED:수거+납품',

  assigned_a_sn BIGINT UNSIGNED NULL COMMENT '담당자 PK(assignees) | 내부 담당자(선택)',
  vendor_pt_sn BIGINT UNSIGNED NULL COMMENT '외부 수행 업체 PK(parties) | 퀵/화물/포워더 등(선택)',

  related_dr_sn BIGINT UNSIGNED NULL COMMENT '연결된 배송 요청 PK(delivery_requests) | 협의가 필요한 케이스에서 연결',
  related_sh_sn BIGINT UNSIGNED NULL COMMENT '연결된 운송 PK(shipments) | 운송 흐름과 작업을 연결(선택)',

  job_status ENUM('PLANNED','IN_PROGRESS','DONE','CANCELLED')
    NOT NULL DEFAULT 'PLANNED'
    COMMENT '작업 상태(ENUM) | PLANNED:계획, IN_PROGRESS:진행, DONE:완료, CANCELLED:취소',

  started_at DATETIME NULL COMMENT '작업 시작 시각(업무 이벤트)',
  completed_at DATETIME NULL COMMENT '작업 완료 시각(업무 이벤트)',

  note VARCHAR(500) NULL COMMENT '작업 메모',

  lj_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  lj_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (lj_sn),
  KEY idx_logistics_jobs_type (job_type),
  KEY idx_logistics_jobs_status (job_status),
  KEY idx_logistics_jobs_assignee (assigned_a_sn),
  KEY idx_logistics_jobs_vendor (vendor_pt_sn),
  KEY idx_logistics_jobs_dr (related_dr_sn),
  KEY idx_logistics_jobs_sh (related_sh_sn),

  CONSTRAINT fk_logistics_jobs_assignee FOREIGN KEY (assigned_a_sn) REFERENCES assignees(a_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_jobs_vendor FOREIGN KEY (vendor_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_jobs_dr FOREIGN KEY (related_dr_sn) REFERENCES delivery_requests(dr_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_jobs_sh FOREIGN KEY (related_sh_sn) REFERENCES shipments(sh_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='물류 작업(사람/업체가 수행)';


-- ======================================================================
-- TABLE: logistics_job_stops
-- DESC : 물류 작업 경유지/정차 지점
-- ======================================================================
CREATE TABLE logistics_job_stops (
  ljs_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '물류 작업 정차 지점 PK',
  lj_sn BIGINT UNSIGNED NOT NULL COMMENT '물류 작업 PK(logistics_jobs)',
  seq_no INT NOT NULL COMMENT '정차 순번(1부터)',

  stop_type ENUM('VENDOR','OFFICE','WAREHOUSE','CUSTOMER','PORT','AIRPORT','CUSTOMS','FORWARDER_HUB')
    NOT NULL COMMENT '정차 지점 종류(ENUM) | VENDOR/OFFICE/WAREHOUSE/CUSTOMER + 해외 확장(PORT/AIRPORT/CUSTOMS/FORWARDER_HUB)',

  address VARCHAR(500) NULL COMMENT '주소/장소(선택)',
  contact_name VARCHAR(100) NULL COMMENT '현장 담당자(선택)',
  contact_phone VARCHAR(50) NULL COMMENT '현장 연락처(선택)',

  planned_at DATETIME NULL COMMENT '예정 시각(선택)',
  arrived_at DATETIME NULL COMMENT '도착 시각(선택)',
  departed_at DATETIME NULL COMMENT '출발 시각(선택)',

  ljs_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ljs_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (ljs_sn),
  UNIQUE KEY uk_logistics_job_stops (lj_sn, seq_no),
  KEY idx_logistics_job_stops_lj (lj_sn),
  KEY idx_logistics_job_stops_type (stop_type),

  CONSTRAINT fk_logistics_job_stops_lj FOREIGN KEY (lj_sn) REFERENCES logistics_jobs(lj_sn)
) COMMENT='물류 작업 경유지/정차 지점';


-- ======================================================================
-- TABLE: logistics_job_lines
-- DESC : 물류 작업 상세(대상 실물/품목)
-- ======================================================================
CREATE TABLE logistics_job_lines (
  ljl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '물류 작업 라인 PK | 어떤 실물/품목을 다루는지',
  lj_sn BIGINT UNSIGNED NOT NULL COMMENT '물류 작업 PK(logistics_jobs)',

  iu_sn BIGINT UNSIGNED NULL COMMENT '실물 PK(inventory_units) | 회사 통제 실물 기준(권장)',
  ol_sn BIGINT UNSIGNED NULL COMMENT '주문라인 PK(order_lines) | 실물 생성 전/직송 케이스에서 사용',
  qty DECIMAL(14,3) NULL COMMENT '작업 수량(선택) | iu_sn 지정 시 보통 NULL',

  note VARCHAR(200) NULL COMMENT '비고',

  ljl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ljl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (ljl_sn),
  KEY idx_logistics_job_lines_lj (lj_sn),
  KEY idx_logistics_job_lines_iu (iu_sn),
  KEY idx_logistics_job_lines_ol (ol_sn),

  CONSTRAINT fk_logistics_job_lines_lj FOREIGN KEY (lj_sn) REFERENCES logistics_jobs(lj_sn),
  CONSTRAINT fk_logistics_job_lines_iu FOREIGN KEY (iu_sn) REFERENCES inventory_units(iu_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_job_lines_ol FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='물류 작업 상세(대상 실물/품목)';
