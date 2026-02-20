/* ============================================================================
 * Cost Origin Links (조달 도메인 비용 출처 링크)
 * ----------------------------------------------------------------------------
 * 목적:
 * - costs는 "비용원천 원장"이고, 비용이 어디서(어떤 출처 엔티티에서) 발생했는지
 *   출처를 명확히 남겨야 한다.
 * - cost_allocations처럼 하나의 테이블에 여러 출처 FK를 두는 방식은 금지(혼선/정합성 저하).
 * - 따라서 출처 엔티티별 *_cost_links 테이블을 분리한다.
 *
 * 운영 규칙(중요):
 * - 한 cost(ct_sn)는 '단 하나의 출처 테이블'에만 등장해야 한다(전역적으로 1 origin).
 *   (DB만으로 전역 유니크를 강제하긴 어려우므로 서비스 레벨에서 검증한다.)
 * - 출처 엔티티(예: project/order_line/SC/SCL)는 여러 cost를 가질 수 있다(1:N).
 *
 * UI 기대:
 * - costs 목록 화면에서 "출처 타입 + 출처 ID"를 바로 보여주기 위해,
 *   각 링크 테이블을 LEFT JOIN 하여 origin_type / origin_sn을 구성한다.
 * ============================================================================ */


-- ======================================================================
-- TABLE: project_cost_links
-- DESC : 비용이 특정 프로젝트(projects)에 의해 발생한 경우의 출처 링크(1 project : N costs)
-- NOTE : 조달 도메인에서는 PO/SC/SCL 등 더 구체 출처가 존재할 수 있다.
--        그러나 '프로젝트 직접 비용'(예: 프로젝트 단위 수수료/특별비용 등)을 표현할 때 사용한다.
-- ======================================================================
CREATE TABLE project_cost_links (
  pjcl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Project-Cost 연결 PK',
  p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects.p_sn)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',

  pjcl_note VARCHAR(500) NULL COMMENT '비고(출처 근거/예외 사유 등)',
  pjcl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pjcl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (pjcl_sn),

  -- 동일 cost가 이 테이블에서 중복 연결되는 실수 방지
  UNIQUE KEY uk_project_cost_ct (ct_sn),
  KEY idx_project_cost_p (p_sn),

  CONSTRAINT fk_project_cost_p
    FOREIGN KEY (p_sn) REFERENCES projects(p_sn),
  CONSTRAINT fk_project_cost_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용 출처: projects (1 project : N costs)';


-- ======================================================================
-- TABLE: order_line_cost_links
-- DESC : 비용이 특정 주문항목(order_lines)에 의해 발생한 경우의 출처 링크(1 ol : N costs)
-- NOTE : 검사비/시험성적서 비용처럼 "특정 납품 항목에 직접 귀속되는 비용"에 적합.
-- ======================================================================
CREATE TABLE order_line_cost_links (
  olcl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'OrderLine-Cost 연결 PK',
  ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문항목 PK(order_lines.ol_sn)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',

  olcl_note VARCHAR(500) NULL COMMENT '비고(출처 근거/예외 사유 등)',
  olcl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  olcl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (olcl_sn),

  UNIQUE KEY uk_order_line_cost_ct (ct_sn),
  KEY idx_order_line_cost_ol (ol_sn),

  CONSTRAINT fk_order_line_cost_ol
    FOREIGN KEY (ol_sn) REFERENCES order_lines(ol_sn),
  CONSTRAINT fk_order_line_cost_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용 출처: order_lines (1 ol : N costs)';


-- ======================================================================
-- TABLE: order_line_override_cost_links
-- DESC : 비용이 특정 주문항목 override(order_line_overrides)에 의해 발생한 경우의 출처 링크
-- NOTE : override 단위(구성품/대체품 등)에 직접 귀속되는 비용에 사용.
-- ======================================================================
CREATE TABLE order_line_override_cost_links (
  olocl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'OrderLineOverride-Cost 연결 PK',
  olo_sn BIGINT UNSIGNED NOT NULL COMMENT '주문항목 override PK(order_line_overrides.olo_sn)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',

  olocl_note VARCHAR(500) NULL COMMENT '비고(출처 근거/예외 사유 등)',
  olocl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  olocl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (olocl_sn),

  UNIQUE KEY uk_order_line_override_cost_ct (ct_sn),
  KEY idx_order_line_override_cost_olo (olo_sn),

  CONSTRAINT fk_order_line_override_cost_olo
    FOREIGN KEY (olo_sn) REFERENCES order_line_overrides(olo_sn),
  CONSTRAINT fk_order_line_override_cost_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용 출처: order_line_overrides (1 override : N costs)';


-- ======================================================================
-- TABLE: sourcing_case_cost_links
-- DESC : 비용이 특정 수급 케이스(sourcing_cases)에 의해 발생한 경우의 출처 링크
-- NOTE : 예: 특정 해외 케이스(sc)에서 발생한 통관/운송 관련 비용 등.
-- ======================================================================
CREATE TABLE sourcing_case_cost_links (
  sccl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'SourcingCase-Cost 연결 PK',
  sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases.sc_sn)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',

  sccl_note VARCHAR(500) NULL COMMENT '비고(출처 근거/예외 사유 등)',
  sccl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sccl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (sccl_sn),

  UNIQUE KEY uk_sourcing_case_cost_ct (ct_sn),
  KEY idx_sourcing_case_cost_sc (sc_sn),

  CONSTRAINT fk_sourcing_case_cost_sc
    FOREIGN KEY (sc_sn) REFERENCES sourcing_cases(sc_sn),
  CONSTRAINT fk_sourcing_case_cost_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용 출처: sourcing_cases (1 sc : N costs)';


-- ======================================================================
-- TABLE: sourcing_case_line_cost_links
-- DESC : 비용이 특정 수급 라인(sourcing_case_lines)에 의해 발생한 경우의 출처 링크
-- NOTE : 실행 단위(scl)에 직접 귀속되는 비용(예: 특정 조달 라인에 부과되는 추가 비용)에 사용.
-- ======================================================================
CREATE TABLE sourcing_case_line_cost_links (
  sclcl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'SourcingCaseLine-Cost 연결 PK',
  scl_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 라인 PK(sourcing_case_lines.scl_sn)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',

  sclcl_note VARCHAR(500) NULL COMMENT '비고(출처 근거/예외 사유 등)',
  sclcl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  sclcl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (sclcl_sn),

  UNIQUE KEY uk_sourcing_case_line_cost_ct (ct_sn),
  KEY idx_sourcing_case_line_cost_scl (scl_sn),

  CONSTRAINT fk_sourcing_case_line_cost_scl
    FOREIGN KEY (scl_sn) REFERENCES sourcing_case_lines(scl_sn),
  CONSTRAINT fk_sourcing_case_line_cost_ct
    FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용 출처: sourcing_case_lines (1 scl : N costs)';


/* =============================================================================
 * 아래 2개는 logistics DDL(erp_logistics_schema.sql)이 현재 세션에 로드되어 있지 않아
 * PK/테이블명/컬럼명을 확정할 수 없으므로, "FK 없이" 스텁으로 제공한다.
 *
 * - shipments / shipment_milestones의 PK 컬럼명(예: sh_sn, sm_sn 등)을 확인한 후
 *   FOREIGN KEY 제약을 추가하여 완성하길 권장.
 * ============================================================================= */


-- ======================================================================
-- TABLE: shipment_cost_links
-- DESC : 비용이 특정 shipment에 의해 발생한 경우의 출처 링크(운송비/포워더/통관 관련 등)
-- TODO : shipments 테이블 PK명 확인 후 FK 추가 권장
-- ======================================================================
CREATE TABLE shipment_cost_links (
  shcl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Shipment-Cost 연결 PK',
  sh_sn BIGINT UNSIGNED NOT NULL COMMENT 'Shipment PK(※ logistics schema의 shipments PK를 사용. 예: shipments.sh_sn)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',

  shcl_note VARCHAR(500) NULL COMMENT '비고(출처 근거/예외 사유 등)',
  shcl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  shcl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (shcl_sn),
  UNIQUE KEY uk_shipment_cost_ct (ct_sn),
  KEY idx_shipment_cost_sh (sh_sn),

  -- FK는 shipments DDL 확인 후 추가:
  CONSTRAINT fk_shipment_cost_sh FOREIGN KEY (sh_sn) REFERENCES shipments(sh_sn),
  CONSTRAINT fk_shipment_cost_ct FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용 출처: shipments (FK는 logistics schema 확인 후 추가 권장)';


-- ======================================================================
-- TABLE: shipment_milestone_cost_links
-- DESC : 비용이 특정 shipment_milestone(이벤트)에서 발생/확정된 경우의 출처 링크
-- NOTE : milestone 자체가 비용의 "귀속 단위"라기보다는 근거 이벤트인 경우가 많으므로,
--        운영상 shipment_cost_links로 충분하면 milestone 링크는 사용하지 않아도 된다(선택).
-- TODO : shipment_milestones 테이블 PK명 확인 후 FK 추가 권장
-- ======================================================================
CREATE TABLE shipment_milestone_cost_links (
  smcl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ShipmentMilestone-Cost 연결 PK',
  sm_sn BIGINT UNSIGNED NOT NULL COMMENT 'Shipment milestone PK(※ logistics schema의 shipment_milestones PK. 예: shipment_milestones.sm_sn)',
  ct_sn BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',

  smcl_note VARCHAR(500) NULL COMMENT '비고(출처 근거/예외 사유 등)',
  smcl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  smcl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (smcl_sn),
  UNIQUE KEY uk_shipment_milestone_cost_ct (ct_sn),
  KEY idx_shipment_milestone_cost_sm (sm_sn),

  -- FK는 shipment_milestones DDL 확인 후 추가:
  CONSTRAINT fk_shipment_milestone_cost_sm FOREIGN KEY (sm_sn) REFERENCES shipment_milestones(sm_sn),
  CONSTRAINT fk_shipment_milestone_cost_ct FOREIGN KEY (ct_sn) REFERENCES costs(ct_sn)
) COMMENT='비용 출처: shipment_milestones (FK는 logistics schema 확인 후 추가 권장)';