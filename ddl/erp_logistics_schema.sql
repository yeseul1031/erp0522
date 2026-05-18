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
 * [재고(Inventory) — logistics 레이어에서의 정본 모델]
 *
 * 1) inventory_units(iu)는 "회사 통제 하에 실물을 인수(수령)하고 바코드(관리번호)를 할당한 단위"이다.
 *    - 즉, '아직 우리에게 도착하지 않은 물건(벤더/운송사 보관, 미수령)'은 원칙적으로 IU로 만들지 않는다.
 *    - 미수령/운송중(예정/추적)은 shipments / (계약·수급 레이어의 실행 결과)로 관리한다.
 *
 * 2) iu_status는 "실물 상태(state)"만 표현한다. 위치(사무실/창고 등)는 iu_location_type이 정본이다.
 *    - 과거 IN_OFFICE 같은 위치성 상태값은 DDL 생성 과정에서 혼재된 값으로 판단되며,
 *      상태(state)와 위치(location)의 의미 충돌/모순을 유발하므로 본 설계에서 제거하였다.
 *    - 권장 iu_status:
 *      ACTIVE(보유/재고 집계 대상),
 *      RESERVED(예약/출고 예정으로 묶임),
 *      DELIVERED(납품완료/재고 집계 제외),
 *      DAMAGED(파손),
 *      LOST(분실),
 *      CONSUMED(소모/조립·가공 투입으로 재고 집계 제외)
 *
 * 3) 부품/완제품의 IU 운용 원칙(성능/운영 타협)
 *    - 부품류는 1박스/1로트를 IU 1행(iu_qty > 1)로 관리할 수 있다.
 *      * 사용 시 split(분할)하여 "사용분 IU(qty=1 또는 소량)"를 생성하고, 그 사용분 IU를 CONSUMED 처리한다.
 *      * 원 IU(박스/로트)는 잔량만 감소한다.
 *    - 완제품(노트북/PC 등)은 기본적으로 IU qty=1(개별) 추적을 전제로 한다.
 *
 * 4) 재고 변화의 정본(원장)은 inventory_operations(IO) + inventory_operation_lines(IOL)로 기록한다.
 *    - IO(헤더): 한 번의 재고 작업(입고/출고/조립/분해/조정/폐기)을 1건으로 묶는다.
 *      io_status는 "문서/작업 처리 상태"(DRAFT/POSTED/CANCELLED)이며 iu_status(실물 상태)와 다른 축이다.
 *    - IOL(라인): 품목별 입/출(IN/OUT) 수량을 기록하는 원장 라인이다.
 *      필요 시 iol_iu_sn으로 실물(IU)을 연결하여 "어떤 IU가 소모/생성되었는지"를 남긴다.
 *
 * 5) goods.g_stock(현재 잔고)
 *    - 재고 변화(IO/IOL 및 IU 상태 변화)가 발생할 때 트랜잭션으로 항상 최신화되는 현재잔고(balance)로 운영한다.
 *    - 운영 원칙: g_stock은 수동 수정 금지(오직 재고 작업/원장 반영으로만 변한다).
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
) COMMENT='납품(헤더)' AUTO_INCREMENT=100;

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
) COMMENT='납품 라인(주문라인 분할 납품)' AUTO_INCREMENT=100;

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
) COMMENT='운송/선적(Shipment) - 흐름 단위(국내/해외 공용)' AUTO_INCREMENT=100;

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
) COMMENT='운송 라인(Shipment에 포함된 품목/수량)' AUTO_INCREMENT=100;

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
) COMMENT='운송 이벤트/마일스톤(추적/증빙) 트래킹 이력 자동 수집이 안되니, 국내 해외 관계 없이 중요한 이벤트나 비용 청구 목적의 기록용으로 쓴다.' AUTO_INCREMENT=100;

-- ======================================================================
-- TABLE: inventory_units
-- DESC : 실물(바코드) 단위 - 회사 통제 하의 인벤토리
-- ======================================================================
CREATE TABLE inventory_units (
  iu_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '실물(바코드) PK | 회사가 통제하는 실물 단위',
  iu_barcode VARCHAR(80) NOT NULL COMMENT '바코드/라벨 ID(유니크) | 내부 발급 또는 외부 라벨 매핑',

  iu_pol_sn BIGINT UNSIGNED NULL COMMENT '출처 발주 라인 PK(po_lines) | 직송/비정형이면 NULL 가능',
  iu_g_sn BIGINT UNSIGNED NULL COMMENT '상품 PK(goods) | pol_sn이 NULL인 경우에도 기록 권장(가능하면)',

  iu_status ENUM('ACTIVE','RESERVED','DELIVERED','DAMAGED','LOST','CONSUMED')
    NOT NULL DEFAULT 'ACTIVE'
    COMMENT '실물 상태(ENUM, 상태축=state) |
            ACTIVE:보유(재고 집계 대상, 위치는 iu_location_type으로 표현),
            RESERVED:예약(출고/납품 예정으로 묶여있음; 보유 재고이되 다른 용도로 사용 금지),
            DELIVERED:납품완료(고객 인도 완료; 보유 재고 집계 제외),
            DAMAGED:파손(보유 재고 집계 제외 또는 별도 정책),
            LOST:분실(보유 재고 집계 제외),
            CONSUMED:소모(조립/가공 등으로 투입되어 더 이상 보유 재고로 집계되지 않음) |
            주의: 위치(OFFICE/WAREHOUSE 등)는 iu_status로 표현하지 않는다. 위치는 iu_location_type이 정본',
  iu_location_type ENUM('VENDOR','OFFICE','WAREHOUSE','CUSTOMER','CUSTOMS','PORT','AIRPORT','IN_TRANSIT')
    NOT NULL DEFAULT 'WAREHOUSE'
    COMMENT '현재 위치 유형(ENUM, 위치축=location, 정본) |
            실물의 "어디에 있는지"는 iu_location_type이 단일 정본이다.
            iu_status는 상태축(state)이며 OFFICE/WAREHOUSE 같은 위치를 포함하지 않는다.
            VENDOR:공급처, OFFICE:사무실, WAREHOUSE:창고, CUSTOMER:고객,
            해외 확장(CUSTOMS/PORT/AIRPORT), IN_TRANSIT:이동중(위치 노드 간 이동 상태)',

  iu_warehouse_code VARCHAR(30) NULL
    COMMENT '창고 코드 | 물건이 보관된 창고 식별자 |
            예: WH1, WH-SEOUL, WH-BUSAN 등 |
            location_type=WAREHOUSE일 때 사용 |
            OFFICE/CUSTOMER 등 다른 위치 유형일 경우 NULL 가능 |
            운영 원칙: warehouse_code는 제한된 코드 목록(드롭다운)으로 관리하여 오타/중복을 방지',

  iu_location_ref VARCHAR(50) NULL
    COMMENT '창고 내부 위치 참조 | 창고 내 실제 보관 위치(사람 기준 위치 표현) |
            예: 14-3, A-02-03, Z3-R14-S03 등 |
            일반적으로 zone-rack-shelf 형태를 "-"로 구분하여 사용 |
            본 값은 시스템이 해석/파싱하지 않고 사람이 이해하는 위치 문자열로 저장 |
            향후 WMS 확장 시 warehouse_locations 테이블로 매핑 가능',

  iu_pack_type ENUM('EA','BOX','PALLET')
    NOT NULL DEFAULT 'EA'
    COMMENT '포장 단위(ENUM) | EA:개별 단위, BOX:박스, PALLET:팔레트 |
            현장 작업 이해/지시를 돕는 보조 정보이며 재고 수량 계산의 정본은 iu_qty이다.
            예: CPU 100개 박스 → iu_pack_type=BOX, iu_qty=100 |
            운영 원칙: 시스템 로직은 iu_qty를 기준으로 동작하고, iu_pack_type은 사람 기준 포장/취급 단위를 표현',

  iu_parent_iu_sn BIGINT UNSIGNED NULL
    COMMENT '상위 IU PK(분할 계보) | split으로 생성된 IU의 원본 IU를 가리킨다 |
            예: 박스 IU(qty=100)에서 1개 사용 시 split IU(qty=1)가 생성되고 iu_parent_iu_sn은 원 박스 IU를 참조 |
            목적: "어느 묶음/박스에서 분할된 실물인지"를 빠르게 추적하기 위한 lineage 보조 정보 |
            주의: 재고 감소의 원인은 inventory_operations / inventory_operation_lines가 정본이며,
            본 컬럼은 원인 기록이 아니라 분할 계보 추적을 위한 참조용이다',

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
  KEY idx_inventory_units_wh_loc (iu_warehouse_code, iu_location_ref),
  KEY idx_inventory_units_parent (iu_parent_iu_sn),

  CONSTRAINT fk_inventory_units_pol FOREIGN KEY (iu_pol_sn) REFERENCES po_lines(pol_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_inventory_units_g FOREIGN KEY (iu_g_sn) REFERENCES goods(g_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT,
  CONSTRAINT fk_inventory_units_parent FOREIGN KEY (iu_parent_iu_sn) REFERENCES inventory_units(iu_sn)
    ON DELETE SET NULL ON UPDATE RESTRICT

) COMMENT='실물(바코드) 단위 - 회사 통제 하의 인벤토리' AUTO_INCREMENT=100;

-- ======================================================================
-- TABLE: inventory_operations
-- DESC : 재고 작업(헤더) - 재고 변화의 '원장(ledger) 문서' 단위
--        - 입고/출고/조립/분해/재고조정/폐기 등 "재고가 변하는 사건"을 1건으로 묶는다.
--        - io_status는 재고 반영 여부를 의미한다(DRAFT=미반영, POSTED=반영, CANCELLED=취소/무효).
--        - goods.g_stock(현재잔고)는 POSTED 시점에 본 작업의 라인 합을 적용하여 항상 최신화된다(수동 수정 금지).
-- ======================================================================
CREATE TABLE inventory_operations
(
    io_sn        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '재고 작업 PK | 재고 변화를 발생시키는 사건(문서) 1건',
    io_type      ENUM('RECEIPT','ISSUE','ASSEMBLY','DISASSEMBLY','ADJUSTMENT','SCRAP')
        NOT NULL COMMENT '작업 유형(ENUM) |
                     RECEIPT:입고(인수/수령 확정) / ISSUE:출고(납품/이동/반출) /
                     ASSEMBLY:조립(부품 CONSUMED + 완제품 생성) / DISASSEMBLY:분해(완제품 해체 + 부품 복귀) /
                     ADJUSTMENT:재고조정(실사/오류 수정) / SCRAP:폐기(사용불가 처리)',
    io_status    ENUM('DRAFT','POSTED','CANCELLED')
        NOT NULL DEFAULT 'POSTED'
        COMMENT '작업 상태(ENUM, 처리축=status) |
                DRAFT:작성중(재고 미반영) / POSTED:확정(재고 반영) / CANCELLED:취소(무효) |
                주의: 실물 상태(state=iu_status)와 혼용하지 않는다. io_status는 "문서/작업 처리 상태"이다',
    io_dt        DATETIME NOT NULL COMMENT '작업 기준일시 | 재고 반영 기준 시각(업무 이벤트)',
    io_a_sn      BIGINT UNSIGNED NOT NULL COMMENT '작업자 PK(assignees) | 누가 이 작업을 수행/확정했는지',
    io_note      VARCHAR(300) NULL COMMENT '작업 메모 | 비정형 사유/근거 기록',

    io_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
    io_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

    PRIMARY KEY (io_sn),
    KEY          idx_inventory_operations_type (io_type),
    KEY          idx_inventory_operations_status (io_status),
    KEY          idx_inventory_operations_dt (io_dt),
    KEY          idx_inventory_operations_actor (io_a_sn),
    CONSTRAINT fk_inventory_operations_actor
        FOREIGN KEY (io_a_sn) REFERENCES assignees (a_sn)
) COMMENT='재고 작업(헤더)' AUTO_INCREMENT=100;

-- ======================================================================
-- TABLE: inventory_operation_lines
-- DESC : 재고 작업 라인(원장 라인) - 재고 변화의 최소 단위(입/출)
--        - 본 테이블이 사실상 "재고 원장(ledger lines)"이며, 대부분의 이력/집계 조회는 이 테이블을 기준으로 한다.
--        - iol_direction=IN/OUT 으로 증감 방향을 명시한다(또는 qty_sign 모델로 변형 가능).
--        - iol_iu_sn은 선택적이다:
--          * 완제품(시리얼/바코드) 추적이 필요하거나,
--          * 박스/로트에서 split된 사용분 IU를 CONSUMED 처리하는 경우,
--          * 조립 산출물(새 PC IU)처럼 "어떤 실물이 생성/소모됐는지"를 남겨야 할 때 사용한다.
-- ======================================================================
CREATE TABLE inventory_operation_lines
(
    iol_sn        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '재고 작업 라인 PK | 작업 1건의 입/출 라인',
    iol_io_sn     BIGINT UNSIGNED NOT NULL COMMENT '재고 작업 PK(inventory_operations) | 라인이 속한 작업(문서)',
    iol_direction ENUM('IN','OUT')
    NOT NULL COMMENT '입출 방향(ENUM) | IN:재고 증가(입고/생성/복귀) / OUT:재고 감소(출고/소모/폐기)',
    iol_g_sn      BIGINT UNSIGNED NOT NULL COMMENT '상품 PK(goods) | 어떤 품목의 재고가 변했는지',
    iol_qty       INT UNSIGNED NOT NULL COMMENT '수량 | 라인 단위 증감 수량(양수) | 방향은 iol_direction으로 표현',
    iol_iu_sn     BIGINT UNSIGNED NULL COMMENT '실물 PK(inventory_units) | 선택: 바코드/로트 추적이 필요한 경우 연결',
    iol_note      VARCHAR(300) NULL COMMENT '라인 메모 | split 출처/조립 산출물/특이사항 등',

    iol_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
    iol_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

    PRIMARY KEY (iol_sn),
    KEY           idx_inventory_operation_lines_io (iol_io_sn),
    KEY           idx_inventory_operation_lines_g (iol_g_sn),
    KEY           idx_inventory_operation_lines_iu (iol_iu_sn),
    KEY           idx_inventory_operation_lines_dir (iol_direction),

    CONSTRAINT fk_inventory_operation_lines_io
        FOREIGN KEY (iol_io_sn) REFERENCES inventory_operations (io_sn),
    CONSTRAINT fk_inventory_operation_lines_g
        FOREIGN KEY (iol_g_sn) REFERENCES goods (g_sn),
    CONSTRAINT fk_inventory_operation_lines_iu
        FOREIGN KEY (iol_iu_sn) REFERENCES inventory_units (iu_sn)
) COMMENT='재고 작업 라인(원장 라인)' AUTO_INCREMENT=100;

-- ======================================================================
-- TABLE: delivery_requests
-- DESC : 배송 협의/요청(스케줄 조율/역제안 기록)
-- NOTE : delivery_requests는 물류 요청 컨테이너다(내부 요청/외주 요청 등). status는 md 정책의 추천값을 따른다.
-- NOTE : 권장 status: SUBMITTED/COUNTERED/ACCEPTED/REJECTED/CONFIRMED/CANCELLED.
-- ======================================================================
CREATE TABLE delivery_requests (
  dr_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '배송 협의/요청 PK | 협의가 필요한 케이스에서 사용',
  dr_p_sn BIGINT UNSIGNED NULL COMMENT '프로젝트 PK(projects) | 선택',

  dr_a_sn BIGINT UNSIGNED NOT NULL COMMENT '요청자 PK(assignees)',
  dr_pt_sn BIGINT UNSIGNED NULL COMMENT '협의 상대(물류/업체) PK(parties) | 내부 수행이면 NULL 가능',

  dr_status ENUM('SUBMITTED','COUNTERED','ACCEPTED','REJECTED','CONFIRMED','CANCELLED')
    NOT NULL DEFAULT 'SUBMITTED'
    COMMENT '요청 상태(ENUM) | SUBMITTED:제출, COUNTERED:역제안, ACCEPTED:수락, REJECTED:거절, CONFIRMED:확정, CANCELLED:취소',

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
    ON DELETE SET NULL ON UPDATE RESTRICT) COMMENT='배송 협의/요청(스케줄 조율/역제안 기록)' AUTO_INCREMENT=100;

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
) COMMENT='배송 요청 상세(대상 품목/실물)' AUTO_INCREMENT=100;

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
    ON DELETE SET NULL ON UPDATE RESTRICT) COMMENT='배송 협의 제안/응답(역제안/수락/거절 이력)' AUTO_INCREMENT=100;

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
    ON DELETE SET NULL ON UPDATE RESTRICT) COMMENT='물류 작업(사람/업체가 수행)' AUTO_INCREMENT=100;

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
) COMMENT='물류 작업 경유지/정차 지점' AUTO_INCREMENT=100;

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
) COMMENT='물류 작업 상세(대상 실물/품목)' AUTO_INCREMENT=100;