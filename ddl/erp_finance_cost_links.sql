/* ============================================================================
 * Cost Origin Links / Allocations (조달 도메인 비용 출처 및 배분관리)
 * ----------------------------------------------------------------------------

## 설계 의도

`costs`는 비용 발생 원장이다.
`ct_type`은 비용이 어떤 종류의 대상에 부과/배분되는지를 나타내는 discriminator이며,
현재 값은 PROJECT 또는 PO만 사용한다.

하나의 cost는 하나의 `ct_type`만 가진다.
따라서 서로 다른 대상 타입을 섞어 배분하지 않는다.

다만, 복합 비용과 단순 비용에 따라 연결 방식이 다르다.
- 복합 비용
   - 현재는 ct_type=PO 하나
   - 발주서는 발주서 전체를 단순 N분할하지 않고, 내부 항목 정보를 기반으로 해석해야 하는 복합 비용 케이스이다.
   - 발주서에서 발생한 cost는 ct_type=PO로 기록하고, PO에 연관된 비용은 po_cost_links로 1:1 연결하여 조회한다(PO 1건 = cost 1건 정책).
   - PO 환불/차감 cost는 별도 po_cost_links를 만들지 않는다.
     환불/차감 cost는 ct_parent_ct_sn으로 원 PO cost를 참조하고, 원 PO cost의 po_cost_links를 따라 PO 귀속을 해석한다.
   - PO 내부 상품 비용은 po_allocations의 분배 정보를 활용해 해석한다.
   - PO 특수 비용(po_cost_lines)을 등록하는 경우, 해당 비용 라인은 반드시 po_cost_line_allocations를 함께 생성해 프로젝트에 배분해야 한다.
     정산/원가 집계 시 누락되지 않도록, "나중에 배분"하는 운영을 허용하지 않는다.

- 단순 비용
   - 나머지 단순 비용들은 ct_type=PROJECT로 기록하고 프로젝트 레벨에서만 부과한다.
   - OL/OLO/SC/SCL에 비용을 직접 부과하지 않는다. 비용은 보통 여러 물건/작업에 묶여 발생하므로,
     개별 라인이나 수급 단위에 일일이 매핑하는 방식은 운영상 현실성이 낮다.

   단순비용의 애플리케이션 검증 규칙
- 각 cost의 배분 합계는 반드시 원장 금액과 일치해야 한다.
   - SUM(pca_price) = costs.ct_price
   - SUM(pca_tax)   = costs.ct_tax
- 외화 비용의 경우 allocation 금액을 원통화 기준으로 할지, KRW 환산 기준으로 할지는 별도 정책으로 고정해야 한다.
- allocation 테이블의 UNIQUE(cost, target)은 동일 cost가 동일 대상에 중복 배분되는 실수를 막기 위한 것이다.

 * ============================================================================ */




-- ======================================================================
-- TABLE: po_cost_links
-- DESC : PO 1건 = cost 1건 정책을 위한 1:1 연결
-- NOTE : po_cost_links는 cost와 PO를 1:1로 연결하는 열린 관계 테이블이다.
--        costs나 purchase_orders 본체에 서로를 직접 고정하는 FK를 늘리지 않고, PO 비용 관계를 외부에서 표현한다.
--        PO 내부 상품 비용은 po_allocations, PO 특수 비용 라인은 po_cost_line_allocations로 해석한다.
--        PO 환불/차감 cost는 이 테이블에 새 연결을 만들지 않고, costs.ct_parent_ct_sn으로 원 PO cost를 따라가서 해석한다.
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
) COMMENT='PO 1건 = cost 1건 정책을 위한 1:1 연결' AUTO_INCREMENT=100;


-- ======================================================================
-- TABLE: po_cost_line_allocations
-- DESC : PO 복합 비용 라인 배분. po_cost_lines 항목별로 Project에 배분한다.
-- NOTE : po_cost_links는 cost와 po를 연결하는거고, po_cost_line_allocations는 po_cost_lines의 각 항목별로 세세하게 배분하는 테이블이다. po_cost_links와 po_cost_line_allocations는 서로 다른 목적과 정책을 가진 별도의 연결/배분 테이블이다.
-- ======================================================================
CREATE TABLE po_cost_line_allocations
(
    pcla_sn        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PO Cost Line 배분 PK',

    pcla_pocl_sn   BIGINT UNSIGNED NOT NULL COMMENT '발주 특수 비용 라인 PK(po_cost_lines.pocl_sn)',
    pcla_p_sn      BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects.p_sn) | 프로젝트 기준 조회를 위한 비정규화 고정값',

    pcla_po_sn     BIGINT UNSIGNED NOT NULL COMMENT '발주서 PK(purchase_orders.po_sn) | po_cost_lines.pocl_po_sn의 조회 편의 캐시',

    pcla_price     DECIMAL(18, 2)  NOT NULL COMMENT '이 대상에 배분된 비용 금액(세금 제외)',
    pcla_tax       DECIMAL(18, 2)  NOT NULL DEFAULT 0 COMMENT '이 대상에 배분된 세금 금액',
    pcla_note      VARCHAR(500)    NULL COMMENT '배분 근거/사유',

    pcla_create_dt DATETIME        NOT NULL COMMENT '레코드 생성일시',
    pcla_update_dt DATETIME        NOT NULL COMMENT '레코드 수정일시',

    PRIMARY KEY (pcla_sn),

    KEY idx_pcla_pocl (pcla_pocl_sn),
    KEY idx_pcla_p (pcla_p_sn),
    KEY idx_pcla_po (pcla_po_sn),

    CONSTRAINT fk_pcla_pocl
        FOREIGN KEY (pcla_pocl_sn) REFERENCES po_cost_lines (pocl_sn),

    CONSTRAINT fk_pcla_p
        FOREIGN KEY (pcla_p_sn) REFERENCES projects (p_sn),

    CONSTRAINT fk_pcla_po
        FOREIGN KEY (pcla_po_sn) REFERENCES purchase_orders (po_sn)
) COMMENT ='PO 복합 비용 라인 배분. po_cost_lines 항목별로 PO 라인/PO 배분/수급 단위에 금액 기준 배분한다.' AUTO_INCREMENT=100;


-- ======================================================================
-- TABLE: po_nego_allocations
-- DESC : PO 헤더 네고 금액 배분. purchase_orders.po_nego_price를 Project에 배분한다.
-- NOTE : po_nego_price는 발주서 헤더 단위 조정 금액이므로, PO가 여러 프로젝트를 커버할 때 프로젝트별 원가 해석을 위해 별도 배분한다.
--        애플리케이션은 SUM(pona_price) = purchase_orders.po_nego_price를 검증해야 한다.
-- ======================================================================
CREATE TABLE po_nego_allocations
(
    pona_sn        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PO 네고 금액 배분 PK',

    pona_po_sn     BIGINT UNSIGNED NOT NULL COMMENT '발주서 PK(purchase_orders.po_sn)',
    pona_p_sn      BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects.p_sn) | 프로젝트 기준 조회를 위한 비정규화 고정값',

    pona_price     INT             NOT NULL COMMENT '이 프로젝트에 배분된 발주서 네고 금액(+/- 가능). 배분 합계는 purchase_orders.po_nego_price와 일치해야 한다',
    pona_note      VARCHAR(500)    NULL COMMENT '배분 근거/사유',

    pona_create_dt DATETIME        NOT NULL COMMENT '레코드 생성일시',
    pona_update_dt DATETIME        NOT NULL COMMENT '레코드 수정일시',

    PRIMARY KEY (pona_sn),

    UNIQUE KEY uq_pona_po_p (pona_po_sn, pona_p_sn),
    KEY idx_pona_po (pona_po_sn),
    KEY idx_pona_p (pona_p_sn),

    CONSTRAINT fk_pona_po
        FOREIGN KEY (pona_po_sn) REFERENCES purchase_orders (po_sn),

    CONSTRAINT fk_pona_p
        FOREIGN KEY (pona_p_sn) REFERENCES projects (p_sn)
) COMMENT='PO 헤더 네고 금액을 프로젝트에 배분한다.' AUTO_INCREMENT=100;


-- ===============================================
-- 발주서가 아닌 기타 다른 녀석들. 단순 비용들이라 할수 있다.
-- ===============================================

CREATE TABLE project_cost_allocations
(
    pca_sn        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Project-Cost 배분 PK',

    pca_ct_sn     BIGINT UNSIGNED NOT NULL COMMENT '비용 PK(costs.ct_sn)',
    pca_p_sn      BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects.p_sn)',
    pca_o_sn      BIGINT UNSIGNED NOT NULL COMMENT '주문서 PK(orders.o_sn)',

    pca_price     DECIMAL(18, 2)  NOT NULL COMMENT '이 프로젝트에 배분된 비용 금액(세금 제외)',
    pca_tax       DECIMAL(18, 2)  NOT NULL DEFAULT 0 COMMENT '이 프로젝트에 배분된 세금 금액',
    pca_note      VARCHAR(500)    NULL COMMENT '배분 근거/사유',

    pca_create_dt DATETIME        NOT NULL COMMENT '레코드 생성일시',
    pca_update_dt DATETIME        NOT NULL COMMENT '레코드 수정일시',

    PRIMARY KEY (pca_sn),
    UNIQUE KEY uq_pca_ct_p (pca_ct_sn, pca_p_sn, pca_o_sn),
    KEY idx_pca_ct (pca_ct_sn),
    KEY idx_pca_p (pca_p_sn),

    CONSTRAINT fk_pca_ct
        FOREIGN KEY (pca_ct_sn) REFERENCES costs (ct_sn),
    CONSTRAINT fk_pca_p
        FOREIGN KEY (pca_p_sn) REFERENCES projects (p_sn),
    CONSTRAINT fk_pca_o
        FOREIGN KEY (pca_o_sn) REFERENCES orders (o_sn)
) COMMENT ='비용 배분: costs.ct_type=PROJECT일 때 프로젝트에 금액/세금을 배분한다.' AUTO_INCREMENT=100;
