/* ============================================================================
 * Balhea ERP — Logistics / Delivery Schema (DDL)
 * ----------------------------------------------------------------------------
 * [이 파일의 성격]
 * - 본 파일은 Balhea ERP 스키마 중 "logistics" 레이어에 해당한다.
 * - 실물 이동(운송/선적)과 물류팀 작업(수거/이동/납품)을 구분하여 기록한다.
 * - contracts/sourcing 레이어의 실행 결과를 물류 관점에서 추적·집계하기 위한 엔티티들을 정의한다.
 *
 * ----------------------------------------------------------------------------
 * [의존 관계 — 중요]
 * - 본 파일은 다음 schema들을 전제로 한다:
 *   - erp_core_schema.sql      : 조직/담당자/업체/물품/문서/로그 등 공통 기준 엔티티
 *   - erp_contracts_schema.sql : 주문/수급/PO 등 조달 실행의 정본 엔티티(논리적 연계 대상)
 *
 * ----------------------------------------------------------------------------
 * [Shipment vs Delivery — 역할 분리(현 버전 기준)]
 * - shipments : 수급처로부터 구매한 물건의 운송/선적 흐름을 기록한다.
 *   - 운송 이벤트는 shipment_milestones로 추적한다.
 * - deliveries : 회사 물류팀의 업무(수거/창고이동/납품) 단위를 기록한다.
 *   - deliveries는 shipments와 분리되어 기록되며, 양쪽을 1:1로 고정하지 않는다(필요 시 링크/참조로만 연결).
 *
 * ----------------------------------------------------------------------------
 * [코드값/이벤트 표준화]
 * - delivery_method(물류 방식), job_type(작업 종류), stop_type(정차 지점),
 *   milestone_type(운송 이벤트), delivery_requests.status/proposals 등은
 *   md 정책의 추천 코드값을 따른다(필요 시 확장 가능).
 *
 * ----------------------------------------------------------------------------
 * [DDL 편집 및 유지 원칙 — 요약]
 * - 본 파일의 ddl 편집 규율은 erp_core_schema.sql 상단 주석을 정본으로 따른다.
 * - 사용자가 명시적으로 요청한 변경만 수행한다.
 * - 임의 개선/정리/축약은 금지하며, 필요 시 제안으로만 제시하고 동의 후 적용한다.
 *
 * ----------------------------------------------------------------------------
 * [ChatGPT / LLM 협업 규율 — 요약]
 * - 설계 의도(특히 Shipment vs Delivery 역할 분리)를 임의로 변경하지 않는다.
 * - 편집 범위가 확대될 가능성이 있으면 작업 전에 영향 범위를 먼저 설명한다.
 * ============================================================================
 */

-- ======================================================================
-- TABLE: deliveries
-- DESC : 납품(헤더)
-- NOTE : deliveries는 회사 물류팀의 업무 단위를 기록한다(수거/이동/납품). shipments(운송/선적)과 분리되어 기록되며 1:1 고정 전제를 두지 않는다.
-- ======================================================================
CREATE TABLE deliveries (
  dv_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '납품 PK',
  dv_p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects)',
  dv_delivered_at DATETIME NOT NULL COMMENT '납품일시(업무 이벤트)',
  dv_memo VARCHAR(500) NULL COMMENT '메모',
  dv_a_sn BIGINT UNSIGNED NOT NULL COMMENT '등록자 PK(assignees)',
  dv_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dv_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (dv_sn),
  KEY idx_deliveries_p (dv_p_sn),
  CONSTRAINT fk_deliveries_project
    FOREIGN KEY (dv_p_sn) REFERENCES projects(p_sn),
  CONSTRAINT fk_deliveries_creator
    FOREIGN KEY (dv_a_sn) REFERENCES assignees(a_sn)
) COMMENT='납품(헤더)';


-- ======================================================================
-- TABLE: delivery_lines
-- DESC : 납품 라인(주문라인 분할 납품)
-- ======================================================================
CREATE TABLE delivery_lines (
  dvl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '납품 라인 PK',
  dvl_dv_sn BIGINT UNSIGNED NOT NULL COMMENT '납품 PK(deliveries)',
  dvl_ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines)',
  dvl_qty_delivered DECIMAL(14,3) NOT NULL COMMENT '납품 수량(분할 가능)',
  dvl_note VARCHAR(500) NULL COMMENT '비고',
  dvl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dvl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (dvl_sn),
  KEY idx_delivery_lines_dv (dvl_dv_sn),
  KEY idx_delivery_lines_ol (dvl_ol_sn),
  CONSTRAINT fk_delivery_lines_dv
    FOREIGN KEY (dvl_dv_sn) REFERENCES deliveries(dv_sn),
  CONSTRAINT fk_delivery_lines_ol
    FOREIGN KEY (dvl_ol_sn) REFERENCES order_lines(ol_sn)
) COMMENT='납품 라인(주문라인 분할 납품)';

/* =======================================================================
 * 물류/납품(실행 레이어)
 * - 문서(RFQ/PO)와 분리: 실물(바코드)과 작업(사람 수행)을 명확히 구분
 * ======================================================================= */


-- ======================================================================
-- TABLE: shipments
-- DESC : 운송/선적(Shipment) - 흐름 단위(국내/해외 공용)
-- NOTE : shipments는 수급처로부터 구매한 물건의 운송/선적 흐름을 기록한다.
-- NOTE : delivery_method(물류 방식)는 md 정책의 추천 코드값을 따른다(확장 가능). 예: PICKUP_BY_LOGISTICS / SELLER_SHIP_TO_COMPANY / SELLER_SHIP_TO_CUSTOMER (확장: FORWARDER_MANAGED).
-- ======================================================================
CREATE TABLE shipments (
  sh_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '운송/선적 PK(국내/해외 공용) | 운송 단위(포워더/택배/화물 등)',

  sh_po_sn BIGINT UNSIGNED NULL COMMENT '관련 발주서 PK(purchase_orders) | 발주와 1:1이 아닐 수 있어 NULL 허용(분할/병합)',
  sh_pt_sn BIGINT UNSIGNED NULL COMMENT '운송사/포워더/택배사 등 업체 PK(parties) | 내부 수행이면 NULL 가능',

  sh_customs_status VARCHAR(16) NULL COMMENT '통관 상태. milestone의 최신 값 비정규화 or 정책레벨에서 지정한 값을 넣자. 구체화 필요.',
  sh_delivery_method VARCHAR(40) NULL COMMENT '물류 방식(텍스트) | 권장: PICKUP_BY_LOGISTICS, SELLER_SHIP_TO_COMPANY, SELLER_SHIP_TO_CUSTOMER, FORWARDER_MANAGED, COURIER, FREIGHT_TRUCK | 필요 시 확장 가능',
  sh_trade_terms VARCHAR(20) NULL COMMENT '인도조건(Incoterms 등) | 권장: EXW,FCA,FOB,CFR,CIF,CPT,CIP,DAP,DPU,DDP | 국내는 보통 NULL',
  sh_ship_from_country CHAR(2) NULL COMMENT '출발국가(ISO-3166-1 alpha-2) | 예: CN, US',
  sh_ship_to_country CHAR(2) NULL COMMENT '도착국가(ISO-3166-1 alpha-2) | 예: KR',

  sh_tracking_no VARCHAR(100) NULL COMMENT '운송장/트래킹 번호(선택)',
  sh_reference_no VARCHAR(100) NULL COMMENT '내부 참조번호(선택) | B/L, AWB, 포워더 오더번호 등',

  sh_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sh_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (sh_sn),
  KEY idx_shipments_po (sh_po_sn),
  KEY idx_shipments_vendor (sh_pt_sn),
  KEY idx_shipments_tracking (sh_tracking_no),

  CONSTRAINT fk_shipments_po FOREIGN KEY (sh_po_sn) REFERENCES purchase_orders(po_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_shipments_vendor FOREIGN KEY (sh_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='운송/선적(Shipment) - 흐름 단위(국내/해외 공용)';


-- ======================================================================
-- TABLE: shipment_lines
-- DESC : 운송 라인(Shipment에 포함된 품목/수량)
-- ======================================================================
CREATE TABLE shipment_lines (
  shl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '운송 라인 PK | 어떤 발주 라인을 얼마나 실어 나르는지',
  shl_sh_sn BIGINT UNSIGNED NOT NULL COMMENT '운송 PK(shipments)',
  shl_pol_sn BIGINT UNSIGNED NOT NULL COMMENT '발주 라인 PK(po_lines)',
  shl_qty DECIMAL(14,3) NOT NULL COMMENT '운송 수량(발주 수량과 다를 수 있음: 부분 선적)',
  shl_note VARCHAR(200) NULL COMMENT '비고(선적 분할 사유 등)',

  shl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  shl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (shl_sn),
  UNIQUE KEY uk_shipment_lines (shl_sh_sn, shl_pol_sn),
  KEY idx_shipment_lines_sh (shl_sh_sn),
  KEY idx_shipment_lines_pol (shl_pol_sn),

  CONSTRAINT fk_shipment_lines_sh FOREIGN KEY (shl_sh_sn) REFERENCES shipments(sh_sn),
  CONSTRAINT fk_shipment_lines_pol FOREIGN KEY (shl_pol_sn) REFERENCES po_lines(pol_sn)
) COMMENT='운송 라인(Shipment에 포함된 품목/수량)';


-- ======================================================================
-- TABLE: shipment_milestones
-- DESC : 운송 이벤트/마일스톤(추적/증빙) 트래킹 이력 자동 수집이 안되니, 국내 해외 관계 없이 중요한 이벤트나 비용 청구 목적의 기록용으로 쓴다.
-- NOTE : shipment_milestones는 shipments의 운송 이벤트(이력) 로그다. milestone_type은 md 정책의 추천값을 따른다(해외 확장 포함).
-- ======================================================================
CREATE TABLE shipment_milestones (
  sm_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '운송 이벤트 PK',
  sm_sh_sn BIGINT UNSIGNED NOT NULL COMMENT '운송 PK(shipments)',
  sm_milestone_type ENUM(
    'CREATED','PICKED_UP','IN_TRANSIT','ARRIVED','WAREHOUSE_IN','DELIVERED',
    'DEPARTURE','ARRIVAL_PORT','CUSTOMS_CLEARANCE_START','CUSTOMS_CLEARANCE_DONE','INSPECTION','DOMESTIC_DELIVERY'
  ) NOT NULL COMMENT '운송 이벤트 종류(ENUM) | 기본: CREATED,PICKED_UP,IN_TRANSIT,ARRIVED,WAREHOUSE_IN,DELIVERED | 해외 확장: DEPARTURE,ARRIVAL_PORT,CUSTOMS_CLEARANCE_START,CUSTOMS_CLEARANCE_DONE,INSPECTION,DOMESTIC_DELIVERY',
  sm_occurred_at DATETIME NOT NULL COMMENT '이벤트 발생 시각(업무 이벤트)',
  sm_location_note VARCHAR(200) NULL COMMENT '위치/메모(항만명/허브명 등)',
  sm_evidence_doc_key VARCHAR(500) NULL COMMENT '증빙 파일 키(선택) | 송장, POD, 통관필증 등',

  sm_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sm_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (sm_sn),
  KEY idx_shipment_milestones_sh (sm_sh_sn),
  KEY idx_shipment_milestones_type (sm_milestone_type),
  KEY idx_shipment_milestones_occurred (sm_occurred_at),

  CONSTRAINT fk_shipment_milestones_sh FOREIGN KEY (sm_sh_sn) REFERENCES shipments(sh_sn)
) COMMENT='운송 이벤트/마일스톤(추적/증빙) 트래킹 이력 자동 수집이 안되니, 국내 해외 관계 없이 중요한 이벤트나 비용 청구 목적의 기록용으로 쓴다.';


-- ======================================================================
-- TABLE: inventory_units
-- DESC : 실물(바코드) 단위 - 회사 통제 하의 인벤토리
-- ======================================================================
CREATE TABLE inventory_units (
  iu_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '실물(바코드) PK | 회사가 통제하는 실물 단위',
  iu_barcode VARCHAR(80) NOT NULL COMMENT '바코드/라벨 ID(유니크) | 내부 발급 또는 외부 라벨 매핑',

  iu_pol_sn BIGINT UNSIGNED NULL COMMENT '출처 발주 라인 PK(po_lines) | 직송/비정형이면 NULL 가능',
  iu_g_sn BIGINT UNSIGNED NULL COMMENT '상품 PK(goods) | pol_sn이 NULL인 경우에도 기록 권장(가능하면)',

  iu_status ENUM('IN_TRANSIT','IN_OFFICE','IN_WAREHOUSE','RESERVED_FOR_DELIVERY','DELIVERED','DAMAGED','LOST')
    NOT NULL DEFAULT 'IN_TRANSIT'
    COMMENT '실물 상태(ENUM) | IN_TRANSIT:이동중, IN_OFFICE:사무실, IN_WAREHOUSE:창고, RESERVED_FOR_DELIVERY:납품예약, DELIVERED:납품완료, DAMAGED:파손, LOST:분실',
  iu_location_type ENUM('VENDOR','OFFICE','WAREHOUSE','CUSTOMER','CUSTOMS','PORT','AIRPORT','IN_TRANSIT')
    NOT NULL DEFAULT 'IN_TRANSIT'
    COMMENT '현재 위치 유형(ENUM) | VENDOR/OFFICE/WAREHOUSE/CUSTOMER + 해외 확장(CUSTOMS/PORT/AIRPORT) + IN_TRANSIT',
  iu_location_note VARCHAR(200) NULL COMMENT '현재 위치 상세(주소/창고구역/담당자 등)',

  iu_received_at DATETIME NULL COMMENT '회사/창고에서 실물 수령 확인 시각(업무 이벤트)',
  iu_delivered_at DATETIME NULL COMMENT '납품 완료 시각(업무 이벤트)',

  iu_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  iu_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (iu_sn),
  UNIQUE KEY uk_inventory_units_barcode (iu_barcode),
  KEY idx_inventory_units_pol (iu_pol_sn),
  KEY idx_inventory_units_g (iu_g_sn),
  KEY idx_inventory_units_status (iu_status),
  KEY idx_inventory_units_location (iu_location_type),

  CONSTRAINT fk_inventory_units_pol FOREIGN KEY (iu_pol_sn) REFERENCES po_lines(pol_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_inventory_units_g FOREIGN KEY (iu_g_sn) REFERENCES goods(g_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='실물(바코드) 단위 - 회사 통제 하의 인벤토리';


-- ======================================================================
-- TABLE: delivery_requests
-- DESC : 배송 협의/요청(스케줄 조율/역제안 기록)
-- NOTE : delivery_requests는 물류 요청 컨테이너다(내부 요청/외주 요청 등). status는 md 정책의 추천값을 따른다.
-- NOTE : 권장 status: SUBMITTED/COUNTERED/ACCEPTED/REJECTED/CONFIRMED/CANCELED.
-- ======================================================================
CREATE TABLE delivery_requests (
  dr_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '배송 협의/요청 PK | 협의가 필요한 케이스에서 사용',
  dr_p_sn BIGINT UNSIGNED NULL COMMENT '프로젝트 PK(projects) | 선택',

  dr_a_sn BIGINT UNSIGNED NOT NULL COMMENT '요청자 PK(assignees)',
  dr_pt_sn BIGINT UNSIGNED NULL COMMENT '협의 상대(물류/업체) PK(parties) | 내부 수행이면 NULL 가능',

  dr_status ENUM('SUBMITTED','COUNTERED','ACCEPTED','REJECTED','CONFIRMED','CANCELED')
    NOT NULL DEFAULT 'SUBMITTED'
    COMMENT '요청 상태(ENUM) | SUBMITTED:제출, COUNTERED:역제안, ACCEPTED:수락, REJECTED:거절, CONFIRMED:확정, CANCELED:취소',

  dr_requested_window_start DATETIME NULL COMMENT '요청 시간창 시작(선택)',
  dr_requested_window_end DATETIME NULL COMMENT '요청 시간창 종료(선택)',

  dr_note VARCHAR(500) NULL COMMENT '요청 메모',

  dr_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dr_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (dr_sn),
  KEY idx_delivery_requests_p (dr_p_sn),
  KEY idx_delivery_requests_requester (dr_a_sn),
  KEY idx_delivery_requests_vendor (dr_pt_sn),
  KEY idx_delivery_requests_status (dr_status),

  CONSTRAINT fk_delivery_requests_p FOREIGN KEY (dr_p_sn) REFERENCES projects(p_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_delivery_requests_requester FOREIGN KEY (dr_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_delivery_requests_vendor FOREIGN KEY (dr_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT) COMMENT='배송 협의/요청(스케줄 조율/역제안 기록)';


-- ======================================================================
-- TABLE: delivery_request_lines
-- DESC : 배송 요청 상세(대상 품목/실물)
-- ======================================================================
CREATE TABLE delivery_request_lines (
  drl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '배송 요청 라인 PK',
  drl_dr_sn BIGINT UNSIGNED NOT NULL COMMENT '배송 요청 PK(delivery_requests)',

  drl_ol_sn BIGINT UNSIGNED NULL COMMENT '주문라인 PK(order_lines) | 실물 생성 전 단계에서 사용 가능',
  drl_iu_sn BIGINT UNSIGNED NULL COMMENT '실물 PK(inventory_units) | 실물 기준 납품/이동 시 사용',
  drl_qty DECIMAL(14,3) NULL COMMENT '요청 수량(선택) | iu_sn 지정 시 보통 NULL',

  drl_note VARCHAR(200) NULL COMMENT '비고',

  drl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  drl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (drl_sn),
  KEY idx_delivery_request_lines_dr (drl_dr_sn),
  KEY idx_delivery_request_lines_ol (drl_ol_sn),
  KEY idx_delivery_request_lines_iu (drl_iu_sn),

  CONSTRAINT fk_delivery_request_lines_dr FOREIGN KEY (drl_dr_sn) REFERENCES delivery_requests(dr_sn),
  CONSTRAINT fk_delivery_request_lines_ol FOREIGN KEY (drl_ol_sn) REFERENCES order_lines(ol_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_delivery_request_lines_iu FOREIGN KEY (drl_iu_sn) REFERENCES inventory_units(iu_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='배송 요청 상세(대상 품목/실물)';


-- ======================================================================
-- TABLE: delivery_request_proposals
-- DESC : 배송 협의 제안/응답(역제안/수락/거절 이력)
-- NOTE : delivery_request_proposals는 요청에 대한 제안/카운터/수락/거절 히스토리를 남긴다. proposal_type은 md 정책의 추천값을 따른다.
-- NOTE : 권장 proposal_type: INITIAL/COUNTER/ACCEPT/REJECT.
-- ======================================================================
CREATE TABLE delivery_request_proposals (
  drp_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '배송 요청 제안/응답 PK',
  drp_dr_sn BIGINT UNSIGNED NOT NULL COMMENT '배송 요청 PK(delivery_requests)',

  drp_proposal_type ENUM('INITIAL','COUNTER','ACCEPT','REJECT')
    NOT NULL COMMENT '제안 유형(ENUM) | INITIAL:초기제안, COUNTER:역제안, ACCEPT:수락, REJECT:거절',

  drp_proposed_window_start DATETIME NULL COMMENT '제안 시간창 시작(선택)',
  drp_proposed_window_end DATETIME NULL COMMENT '제안 시간창 종료(선택)',

  drp_a_sn BIGINT UNSIGNED NULL COMMENT '제안자(내부) PK(assignees) | 업체/외부면 NULL 가능',
  drp_pt_sn BIGINT UNSIGNED NULL COMMENT '제안자(업체) PK(parties) | 내부면 NULL 가능',

  drp_note VARCHAR(500) NULL COMMENT '제안 메모',
  drp_created_at DATETIME NOT NULL COMMENT '제안 생성 시각(업무 이벤트)',

  drp_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  drp_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (drp_sn),
  KEY idx_delivery_request_proposals_dr (drp_dr_sn),
  KEY idx_delivery_request_proposals_type (drp_proposal_type),
  KEY idx_delivery_request_proposals_created (drp_created_at),

  CONSTRAINT fk_delivery_request_proposals_dr FOREIGN KEY (drp_dr_sn) REFERENCES delivery_requests(dr_sn),
  CONSTRAINT fk_delivery_request_proposals_proposer_a FOREIGN KEY (drp_a_sn) REFERENCES assignees(a_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_delivery_request_proposals_proposer_vendor FOREIGN KEY (drp_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT) COMMENT='배송 협의 제안/응답(역제안/수락/거절 이력)';


-- ======================================================================
-- TABLE: logistics_jobs
-- DESC : 물류 작업(사람/업체가 수행)
-- NOTE : logistics_jobs는 물류팀 작업 컨테이너다. job_type은 md 정책의 추천값을 따른다.
-- NOTE : 권장 job_type: PICKUP / TRANSFER / DELIVERY / MIXED.
-- ======================================================================
CREATE TABLE logistics_jobs (
  lj_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '물류 작업 PK | 사람이 수행하는 작업 단위',

  lj_job_type ENUM('PICKUP','TRANSFER','DELIVERY','MIXED')
    NOT NULL COMMENT '작업 종류(ENUM) | PICKUP:수거, TRANSFER:이동, DELIVERY:납품, MIXED:수거+납품',

  lj_a_sn BIGINT UNSIGNED NULL COMMENT '담당자 PK(assignees) | 내부 담당자(선택)',
  lj_pt_sn BIGINT UNSIGNED NULL COMMENT '외부 수행 업체 PK(parties) | 퀵/화물/포워더 등(선택)',

  lj_dr_sn BIGINT UNSIGNED NULL COMMENT '연결된 배송 요청 PK(delivery_requests) | 협의가 필요한 케이스에서 연결',
  lj_sh_sn BIGINT UNSIGNED NULL COMMENT '연결된 운송 PK(shipments) | 운송 흐름과 작업을 연결(선택)',

  lj_job_status ENUM('PLANNED','IN_PROGRESS','DONE','CANCELLED')
    NOT NULL DEFAULT 'PLANNED'
    COMMENT '작업 상태(ENUM) | PLANNED:계획, IN_PROGRESS:진행, DONE:완료, CANCELLED:취소',

  lj_started_at DATETIME NULL COMMENT '작업 시작 시각(업무 이벤트)',
  lj_completed_at DATETIME NULL COMMENT '작업 완료 시각(업무 이벤트)',

  lj_note VARCHAR(500) NULL COMMENT '작업 메모',

  lj_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  lj_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (lj_sn),
  KEY idx_logistics_jobs_type (lj_job_type),
  KEY idx_logistics_jobs_status (lj_job_status),
  KEY idx_logistics_jobs_assignee (lj_a_sn),
  KEY idx_logistics_jobs_vendor (lj_pt_sn),
  KEY idx_logistics_jobs_dr (lj_dr_sn),
  KEY idx_logistics_jobs_sh (lj_sh_sn),

  CONSTRAINT fk_logistics_jobs_assignee FOREIGN KEY (lj_a_sn) REFERENCES assignees(a_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_jobs_vendor FOREIGN KEY (lj_pt_sn) REFERENCES parties(pt_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_jobs_dr FOREIGN KEY (lj_dr_sn) REFERENCES delivery_requests(dr_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_jobs_sh FOREIGN KEY (lj_sh_sn) REFERENCES shipments(sh_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT) COMMENT='물류 작업(사람/업체가 수행)';


-- ======================================================================
-- TABLE: logistics_job_stops
-- DESC : 물류 작업 경유지/정차 지점
-- NOTE : logistics_job_stops는 한 물류 작업의 정차 지점/순서를 기록한다. stop_type은 md 정책의 추천값을 따른다.
-- NOTE : 권장 stop_type: VENDOR / OFFICE / WAREHOUSE / CUSTOMER (확장: PORT/AIRPORT/CUSTOMS/FORWARDER_HUB).
-- ======================================================================
CREATE TABLE logistics_job_stops (
  ljs_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '물류 작업 정차 지점 PK',
  ljs_lj_sn BIGINT UNSIGNED NOT NULL COMMENT '물류 작업 PK(logistics_jobs)',
  ljs_seq_no INT NOT NULL COMMENT '정차 순번(1부터)',

  ljs_stop_type ENUM('VENDOR','OFFICE','WAREHOUSE','CUSTOMER','PORT','AIRPORT','CUSTOMS','FORWARDER_HUB')
    NOT NULL COMMENT '정차 지점 종류(ENUM) | VENDOR/OFFICE/WAREHOUSE/CUSTOMER + 해외 확장(PORT/AIRPORT/CUSTOMS/FORWARDER_HUB)',

  ljs_address VARCHAR(500) NULL COMMENT '주소/장소(선택)',
  ljs_contact_name VARCHAR(100) NULL COMMENT '현장 담당자(선택)',
  ljs_contact_phone VARCHAR(50) NULL COMMENT '현장 연락처(선택)',

  ljs_planned_at DATETIME NULL COMMENT '예정 시각(선택)',
  ljs_arrived_at DATETIME NULL COMMENT '도착 시각(선택)',
  ljs_departed_at DATETIME NULL COMMENT '출발 시각(선택)',

  ljs_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ljs_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (ljs_sn),
  UNIQUE KEY uk_logistics_job_stops (ljs_lj_sn, ljs_seq_no),
  KEY idx_logistics_job_stops_lj (ljs_lj_sn),
  KEY idx_logistics_job_stops_type (ljs_stop_type),

  CONSTRAINT fk_logistics_job_stops_lj FOREIGN KEY (ljs_lj_sn) REFERENCES logistics_jobs(lj_sn)
) COMMENT='물류 작업 경유지/정차 지점';


-- ======================================================================
-- TABLE: logistics_job_lines
-- DESC : 물류 작업 상세(대상 실물/품목)
-- ======================================================================
CREATE TABLE logistics_job_lines (
  ljl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '물류 작업 라인 PK | 어떤 실물/품목을 다루는지',
  ljl_lj_sn BIGINT UNSIGNED NOT NULL COMMENT '물류 작업 PK(logistics_jobs)',

  ljl_iu_sn BIGINT UNSIGNED NULL COMMENT '실물 PK(inventory_units) | 회사 통제 실물 기준(권장)',
  ljl_ol_sn BIGINT UNSIGNED NULL COMMENT '주문라인 PK(order_lines) | 실물 생성 전/직송 케이스에서 사용',
  ljl_qty DECIMAL(14,3) NULL COMMENT '작업 수량(선택) | iu_sn 지정 시 보통 NULL',

  ljl_note VARCHAR(200) NULL COMMENT '비고',

  ljl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ljl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (ljl_sn),
  KEY idx_logistics_job_lines_lj (ljl_lj_sn),
  KEY idx_logistics_job_lines_iu (ljl_iu_sn),
  KEY idx_logistics_job_lines_ol (ljl_ol_sn),

  CONSTRAINT fk_logistics_job_lines_lj FOREIGN KEY (ljl_lj_sn) REFERENCES logistics_jobs(lj_sn),
  CONSTRAINT fk_logistics_job_lines_iu FOREIGN KEY (ljl_iu_sn) REFERENCES inventory_units(iu_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_logistics_job_lines_ol FOREIGN KEY (ljl_ol_sn) REFERENCES order_lines(ol_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT
) COMMENT='물류 작업 상세(대상 실물/품목)';
