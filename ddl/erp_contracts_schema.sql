/* ============================================================================
 * Balhea ERP — Contracts / Sourcing Schema (DDL)
 * ----------------------------------------------------------------------------
 * [이 파일의 성격]
 * - 본 파일은 Balhea ERP 스키마 중 "contracts / sourcing" 레이어에 해당한다.
 * - 계약, 주문, 수급(국내/해외/자체제작), 견적(RFQ), 발주(PO) 등
 *   실제 업무 흐름과 의사결정 단위를 정의한다.
 * - 이 파일의 엔티티들은 업무 프로세스와 강하게 결합되어 있으며,
 *   finance / logistics 스키마의 상위 입력(source) 역할을 한다.
 *
 * ----------------------------------------------------------------------------
 * [의존 관계 — 중요]
 * - 본 파일은 erp_core_schema.sql에 정의된 공통 엔티티들을 전제로 한다.
 *   (본 파일에는 해당 엔티티의 정의를 포함하지 않는다.)
 *
 *   주요 의존 엔티티 예시는 다음과 같다:
 *   - departments / assignees : 업무 담당자 및 조직 단위
 *   - parties                 : 거래 상대방(발주처/공급처 등)
 *   - goods                   : 물품 기준 정보
 *   - documents / document_links
 *                             : 계약/주문/수급/견적/발주에 수반되는 모든 문서
 *   - audit_changes / activity_logs
 *                             : 상태 변경 및 주요 행위 이력
 *
 * ----------------------------------------------------------------------------
 * NOTE (DDL EDITING RULES)
 * - 본 파일의 ddl 편집 규율은 erp_core_schema.sql 상단 주석을 정본으로 한다.
 * - 사용자가 명시적으로 요청한 변경만 수행한다.
 * - 임의 개선/정리/축약은 금지되며, 필요 시 제안으로만 제시한다.
 *
 * ----------------------------------------------------------------------------
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
                      |     |     |
                      |     |     +---> N orders (주문서, order_lines를 묶는 그룹핑 단위, 실제 납품 단위는 order_lines(+order_line_overrides))
                      |     |              |
                      |     +---> N order_lines (주문항목, 뭘 납품할지 정의)
                      |              |    |
                      |              |    +---> N order_line_overrides (예외 케이스)
                      |              |              |
                      |              +---> (논리적 1) sourcing_cases (수급 담당자 지정, 물리적으로는 여러개지만 논리적으로는 1:1 매핑임. sourcing_cases.dc_is_active = true)
                      |                             |    |
수급 담당자 영역          |   (수급 담당자가 수락할때 생성)    |    +---> 1 subtype_cases (국내/해외/자체제작 등)
                      |                             |
                      |                              +-------> N sourcing_case_lines (조달 대상 정의, g_sn 또는 자유텍스트)
                      |                                                  /
(견적/발주 진행 과정)      |     +-------------------------------------------/
                      |      |
                      |  [rfq | po]_allocations (RFQ/PO - sc_lines 매핑 테이블)
                      |      |
                      |  rfqs/purchase_orders
                      |      |
                      |      +---> N rfq_lines/po_lines
                      |              (sourcing_case_lines 참조)


---
[계약 방식 유형 정리]
- TENDER: 입찰(공공/민간) | 공고/입찰 방식으로 계약이 성사되는 경우. 일반적으로 경쟁 입찰이 포함된다.
- DIRECT: 직접 계약(수의)
- FRAME: 기간/다건 계약으로 현장에서 '연간'계약이라 부르며, 총수량을 정해서 차감형으로 관리하는 계약 방식이다.

[계약방식에 따른 특징 및 운영 규칙]
- TENDER: project -> (default) order -> order_lines
  모든 project의 order_line은 항상 어딘가의 order에 소속된다. ol 생성전, project에 기본 order가 없다면 order를 생성 후, project에 기본 order로 지정
   이후 추가되는 모든 ol은 이 기본 order 포함시킨다. (이건 다른 계약 방식들도 모두 공통적으로 적용되는 운영 규칙이다.)

- DIRECT: project -> (default) order -> order_lines 와 같이 주문항목을 계속 누적해서 추가 하다가,
   (부분) 정산을 필요로 할때, 1) 일부 ol들을 선택해서, 2) order 주문서를 선택하고 (없다면 생성하고), 3) 기존 기본 order에서 이동할 신규 order로 이동한다.

- FRAME:
   1단계) 장기계약정보 생성(UI상 '원본'이라는 표현을 사용), project -> blanket_order_lines, 여기에 총 납품해야할 수량이 들어있다. blanket_order_line_overrides는 조합/대체이기 때문에 총 수량/구매수량 관리는 blanket_order_lines에서만 관리가 된다. 왜냐면 납품은 order_lines 단위로 나가는거지 order_line_overrides가 개별적으로 나가지는 않기 때문이다.
   2단계) 원본 계약정보에서 선택된 주문항목(blanket_order_lines) 에서 복제된 주문항목(order_lines)를 실제 주문/납품 단위로 생성한다. (이들은 기본 정산서에 포함되는 행위는 동일하다)

[주문서와 정산 관계]
- 주문서(order)는 실제 납품 단위인 order_lines를 묶기 위한 그룹핑 단위이다.
- 이 그룹핑된 주문서를 정산을 요할때, 정산서(receivable)이 생성되어 연결되며(receivable_order_links), 이때 주문서는 잠금 상태가 된다. (수량/금액 등의 OL/OLO 수정 불가, 프로그램적으로 구현하기)
- receivables 엔티티가 있는데 orders 엔티티를 별도로 둔 이유는, 재무 도메인과 경계를 구분하기 위함이며, orders 엔티티 없이, receivable_order_line_links로 바로 연결시, 계약 도메인이 재무도메인의 의존성을 가지게 된다. 주문서를 재무의 납품정산에 의존하게 된다는 의미임.

 * ======================================================================= */


-- ======================================================================
-- TABLE: projects
-- DESC : 프로젝트(=계약)
-- NOTE : p_sn 대신 코드를 쓰고 싶으면 P-[YYYY]-[p_sn] 을 쓰기
-- ======================================================================
CREATE TABLE projects (
  p_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '프로젝트(=계약 통합) PK',
  p_name VARCHAR(128) NOT NULL COMMENT '프로젝트명, 업체명+공고명+연도 등으로 조합해서 만들기',
  p_type ENUM('TENDER','DIRECT','FRAME')
    NOT NULL COMMENT '프로젝트 유형(ENUM) | TENDER:입찰(공공/민간), DIRECT:직접계약(수의), FRAME:기간/다건 계약(프레임/콜오프, 여러 주문서 생성)',
  p_customer_pt_sn BIGINT UNSIGNED NULL COMMENT '고객사 PK(parties)',
  p_contract_no VARCHAR(32) NULL COMMENT '계약서 번호(외부 식별자, 계약 전 NULL 가능)',
  p_signed_at DATE NULL COMMENT '계약 체결일(계약 전 NULL 가능)',
  p_contract_amount DECIMAL(18,2) NULL COMMENT '계약 총액(계약 전 NULL 가능)',
  p_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화(예: KRW, USD)',
  p_status ENUM('PRE_CONTRACT','ACTIVE','CLOSED','CANCELLED')
    NOT NULL COMMENT '프로젝트 상태(ENUM) | PRE_CONTRACT:계약전/입찰검토, ACTIVE:진행, CLOSED:종료, CANCELLED:취소',
  p_assign_status VARCHAR(2) NULL COMMENT '담당자 지정상태 , RR=담당자지정 / RO=담당자확인 / RC=견적확인요청 / BP=투찰진행 / DR=진행중단(취소) / PR=낙찰시담당자지정 / PO=담당자확인(낙찰시) / PC=완료',
  p_a_sn BIGINT UNSIGNED NOT NULL COMMENT '현재 프로젝트 담당자 PK(assignees)',
  p_started_at DATETIME NULL COMMENT '프로젝트 시작일시(업무 이벤트)',
  p_ended_at DATETIME NULL COMMENT '프로젝트 종료일시(업무 이벤트)',
  p_delivery_dt DATETIME NULL COMMENT '납기일시',
  p_delivery_dt_str VARCHAR(128) NOT NULL DEFAULT '' COMMENT '납기일시 문자열',
  p_contractor VARCHAR(60) NOT NULL DEFAULT '' COMMENT '계약자',
  p_site_name VARCHAR(100) NOT NULL DEFAULT '' COMMENT '현장명',
  p_ba_nego_price INT NOT NULL DEFAULT 0 COMMENT '공고처 네고금액 +/- 가능',
  p_ba_nego_reason VARCHAR(128) NOT NULL DEFAULT '' COMMENT '네고 사유',
  p_default_o_sn BIGINT UNSIGNED NULL COMMENT 'default 주문서 FK, 모든 프로젝트는 default 주문서를 1개 가진다. 다만 project 생성 시점엔 null으로 입력하고,추후 ol이 생성될때 order를 생성하고 실제 값을 반영한다.',
  p_default_sc_type ENUM('DOMESTIC','OVERSEAS','IN_HOUSE') NOT NULL DEFAULT 'DOMESTIC' COMMENT '기본 수급 방식, ol이 sourcing_case로 넘어갈때 기본으로 세팅되는 값',
  p_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  p_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (p_sn),
  KEY idx_projects_customer_pt_sn (p_customer_pt_sn),
  KEY idx_projects_manager (p_a_sn),
  KEY idx_projects_status (p_status),
  CONSTRAINT fk_projects_customer
      FOREIGN KEY (p_customer_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_default_order
      FOREIGN KEY (p_sn, p_default_o_sn) REFERENCES orders(o_p_sn, o_sn),
  CONSTRAINT fk_projects_manager
    FOREIGN KEY (p_a_sn) REFERENCES assignees(a_sn)
) COMMENT='프로젝트(=계약)';


-- ======================================================================
-- TABLE: announce_links
-- DESC : 프로젝트와 공고 도메인과의 연결, 1:1
-- NOTE : 포탈 도메인에 있는 공고, 포탈쪽에서 프로젝트 생성 요청시 포탈의 공고의 ba_sn을 가져와 심는다.
-- 도메인 밖에 있는 데이터라 그냥 이름 안넣었다.
-- ======================================================================

create table announce_links
(
    al_sn         bigint unsigned auto_increment comment 'PK'
        primary key,
    al_p_sn       bigint unsigned                    not null comment 'project sn',
    al_ba_sn      bigint unsigned                    not null comment 'ba_sn',
    al_ba_title varchar(320) not null comment '공고 제목',
    al_ba_announce_no varchar(32) not null comment '공고 번호',
    al_created_dt datetime default current_timestamp not null,
    constraint announce_links_projects_p_sn_fk
        foreign key (al_p_sn) references projects (p_sn)
)
    comment '프로젝트와 공고 도메인과의 연결, 1:1';

create unique index announce_links_al_p_sn_al_ba_sn_uindex
    on announce_links (al_p_sn, al_ba_sn);

create unique index announce_links_al_ba_sn_uindex
    on announce_links (al_ba_sn);



-- ======================================================================
-- TABLE: orders
-- DESC : 주문서
-- NOTE : 계약내 주문항목을 그룹핑 하기 위한 목적으로 존재하는 엔티티이다. 실제 납품 단위는 order_lines(+order_line_overrides)이다.
-- ======================================================================

CREATE TABLE orders (
  o_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문서 PK',
  o_p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects)',
  o_name VARCHAR(32) NOT NULL COMMENT '주문서명',

  o_a_sn BIGINT UNSIGNED NOT NULL COMMENT '생성자 PK(assignees)',
  o_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  o_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (o_sn),
  UNIQUE KEY uk_order_p_sn_o_sn (o_p_sn, o_sn),
  CONSTRAINT fk_order_projects
    FOREIGN KEY (o_p_sn) REFERENCES projects(p_sn)
) COMMENT='주문서';



-- ======================================================================
-- TABLE: blanket_order_lines
-- DESC : 주문총량(차감식) 계약용 주문라인
-- 장기 계약/프레임 계약에서 총량 관리 필요시 사용
-- order_lines은 실제 주문이 들어가는 것으로, SC(수급방식)과의 연결은 ol만 가지며, bol(blanekt_order_lines)는 ol과 1:1로 연결되는 보조정보로서만 활용한다.
-- bol의 필드들은 ol과 유사하나 주문된 총 수량(bol_released_qty) 만 특화되어 추가 된다. 이 필드는 receivables에 포함된 ol들의 final_item_qty의 합으로 ol이 receivable에 포함될때 업데이트해줘야한다!!!

-- ======================================================================

CREATE TABLE blanket_order_lines (
                                     bol_sn           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문총량(차감식) 계약용 주문라인 PK',
                                     bol_p_sn          BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects)',
                                     bol_no            INT            NOT NULL COMMENT '주문서 내 라인 번호',

                                     web_item_name    VARCHAR(128)   NOT NULL COMMENT '(사이트상) 요구 품목명(예: 십자 드라이버)',
                                     web_item_spec    JSON NULL COMMENT '(사이트상) 요구 규격/조건(자유형 JSON)',
                                     web_item_qty     DECIMAL(14, 3) NOT NULL COMMENT '(사이트상) 요구 수량(납품 약속 수량)',
                                     web_item_unit    VARCHAR(20) NULL COMMENT '(사이트상) 단위(예: EA, SET)',
                                     web_unit_price   DECIMAL(18, 2) NULL COMMENT '(사이트상) 판매 단가(고객에 납품 단가, 모르면 NULL)',

                                     doc_item_name    VARCHAR(128)   NOT NULL COMMENT '(문서상) 요구 품목명(예: 십자 드라이버)',
                                     doc_item_spec    JSON NULL COMMENT '(문서상) 요구 규격/조건(자유형 JSON)',
                                     doc_item_qty     DECIMAL(14, 3) NOT NULL COMMENT '(문서상) 요구 수량(납품 약속 수량)',
                                     doc_item_unit    VARCHAR(20) NULL COMMENT '(문서상) 단위(예: EA, SET)',
                                     doc_unit_price   DECIMAL(18, 2) NULL COMMENT '(문서상) 판매 단가(고객에 납품 단가, 모르면 NULL)',

                                     final_item_name  VARCHAR(128)   NOT NULL COMMENT '(검토된) 요구 품목명(예: 십자 드라이버)',
                                     final_item_spec  JSON NULL COMMENT '(검토된) 요구 규격/조건(자유형 JSON)',
                                     final_item_qty   DECIMAL(14, 3) NOT NULL COMMENT '(검토된) 요구 수량(납품 약속 수량)',
                                     final_item_unit  VARCHAR(20) NULL COMMENT '(검토된) 단위(예: EA, SET)',
                                     final_unit_price DECIMAL(18, 2) NULL COMMENT '(검토된) 판매 단가(고객에 납품 단가, 모르면 NULL)',

                                     bol_released_qty  DECIMAL(14, 3) NOT NULL COMMENT '현재까지 주문된 총 수량 필드, order(default order는제외)에 포함된 수량들의 집계로 업데이트 한다.',

                                     bol_status        ENUM('OPEN','IN_PROGRESS','DELIVERED','CANCELLED')
    NOT NULL COMMENT '라인 상태(ENUM) | OPEN:오픈, IN_PROGRESS:진행, DELIVERED:납품완료, CANCELLED:취소',
                                     bol_due_date      DATE NULL COMMENT '납품 예정일(업무 이벤트)',
                                     bol_create_dt     DATETIME       NOT NULL COMMENT '레코드 생성일시',
                                     bol_update_dt     DATETIME       NOT NULL COMMENT '레코드 수정일시',
                                     PRIMARY KEY (bol_sn),
                                     UNIQUE KEY uk_ol_bol_no (bol_p_sn, bol_no),
                                     KEY              idx_bol_status (bol_status),
                                     CONSTRAINT fk_bol_orders
                                         FOREIGN KEY (bol_p_sn) REFERENCES projects (p_sn)
) COMMENT='주문총량(차감식) 계약용 주문라인(고객 요구/납품 약속 단위)';


-- ======================================================================
-- TABLE: blanket_order_line_overrides
-- DESC : 주문총량(차감식) 계약용 주문라인 희소 케이스(분할/대체/추가/조합) 지원
-- NOTE : bol과 마찬가지로 주문된 총 수량 정보 필드가 추가 된다. 이 필드는 receivables에 포함된 olo들의 olo_item_qty 합으로 olo가 receivable에 포함될때 업데이트해줘야한다!!!
-- ======================================================================
CREATE TABLE blanket_order_line_overrides (
                                              bolo_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문총량(차감식) 계약용 주문라인 예외(override) PK',
                                              bolo_bol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines)',
                                              bolo_type ENUM('SPLIT','SUBSTITUTE','ADD_ON','BUNDLE')
    NOT NULL COMMENT '예외 유형(ENUM) | SPLIT:분할구매, SUBSTITUTE:대체품, ADD_ON:추가구매, BUNDLE:조합구성품',
                                              bolo_item_name VARCHAR(128) NOT NULL COMMENT '(override) 요구 품목명(예: 십자 드라이버)',
                                              bolo_item_spec JSON NULL COMMENT '(override) 요구 규격/조건(자유형 JSON)',
                                              bolo_item_qty DECIMAL(14,3) NOT NULL COMMENT '(override) 요구 수량(납품 약속 수량)',
                                              bolo_item_unit VARCHAR(20) NULL COMMENT '(override) 단위(예: EA, SET)',
    -- olo_unit_price 는 없다. 왜냐하면 주문라인의 단가 1개만 실 단가이고 남어지는 참조일뿐이다.

                                              bolo_released_qty  DECIMAL(14, 3) NOT NULL COMMENT '현재까지 주문된 총 수량 필드, receivables에 포함된 수량들의 집계로 업데이트 한다.',

                                              bolo_note VARCHAR(500) NULL COMMENT '사유/메모',
                                              bolo_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
                                              bolo_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
                                              PRIMARY KEY (bolo_sn),
                                              KEY idx_bolo_ol (bolo_bol_sn),
                                              KEY idx_bolo_type (bolo_type),
                                              CONSTRAINT fk_bolo_bol FOREIGN KEY (bolo_bol_sn) REFERENCES blanket_order_lines(bol_sn)
) COMMENT='주문총량(차감식) 계약용 주문라인 희소 케이스(분할/대체/추가/조합) 지원';





/* ======================================================================
 * TABLE: order_lines
 * DESC : 주문라인(고객 요구/납품 약속 단위)
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
 * - 문서/웹 원문 파일 자체는 documents + document_order_line_links로 연결한다. (1:N이므로, 여러 문서/웹 출처가 있을 수 있다.)
 * - 계약에서는 요구사항에 촛점을 맞추고, g_sn 과 매핑은 실제 수급 영역에서 다룬다.
 * ====================================================================== */

CREATE TABLE order_lines (
  ol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문라인 PK',
  ol_p_sn BIGINT UNSIGNED NOT NULL COMMENT '프로젝트 PK(projects)',
  ol_o_sn BIGINT UNSIGNED NOT NULL COMMENT '주문서 PK(orders)',
  ol_bol_sn BIGINT UNSIGNED NULL COMMENT '연간계약(차감식)일 경우 참조하는 blanket_order_lines PK',
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

  ol_req_dept varchar(32) default '' not null comment '요청 부서',
  ol_order_dt date null comment '수의/연간 계약등에서 개별 주문항목의 주문/수주일이 있을경우',
  ol_delivery_place varchar(32) null comment '개별 납품장소가 있을경우',

  ol_status ENUM('OPEN','IN_PROGRESS','DELIVERED','CANCELLED')
    NOT NULL COMMENT '라인 상태(ENUM) | OPEN:오픈, IN_PROGRESS:진행, DELIVERED:납품완료, CANCELLED:취소',
  ol_due_date DATE NULL COMMENT '납품 예정일(업무 이벤트)',
  ol_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ol_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ol_sn),
  UNIQUE KEY uk_order_lines_order_line_no (ol_o_sn, ol_no),
  KEY idx_order_lines_p_sn (ol_p_sn),
  KEY idx_order_lines_o_sn (ol_o_sn),
  KEY idx_order_lines_bol_sn (ol_bol_sn),
  KEY idx_order_lines_status (ol_status),
  CONSTRAINT fk_order_lines_projects
      FOREIGN KEY (ol_p_sn) REFERENCES projects(p_sn),
  CONSTRAINT fk_order_lines_orders
      FOREIGN KEY (ol_o_sn) REFERENCES orders(o_sn),
  CONSTRAINT fk_order_lines_blanket_order_lines
      FOREIGN KEY (ol_bol_sn) REFERENCES blanket_order_lines(bol_sn)
) COMMENT='주문라인(고객 요구/납품 약속 단위)';


-- ======================================================================
-- TABLE: order_line_overrides
-- DESC : 주문라인 희소 케이스(분할/대체/추가/조합) 지원
-- NOTE :
-- * - 계약에서는 요구사항에 촛점을 맞추고, g_sn 과 매핑은 실제 수급 영역에서 다룬다.
-- ======================================================================
CREATE TABLE order_line_overrides (
  olo_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '주문라인 예외(override) PK',
  olo_ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines)',
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
  KEY idx_olo_ol (olo_ol_sn),
  KEY idx_olo_type (olo_type),
  CONSTRAINT fk_olo_ol
    FOREIGN KEY (olo_ol_sn) REFERENCES order_lines(ol_sn)
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
 *   단, 서비스적인 측면에서 업무를 완료했다, 즉 더이상 다른 업무를 하지 않는다는 의미로 DONE 상태를 둔다. 이건 견적/발주와의 데이터적 무결성 완료를 보장하지는 않는다. 그러니 DONE은 서비스적으로 사람이 수동으로 선택한다.
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
 *
 * EXECUTION & QUANTITY INTERPRETATION
 * - sc_required_qty는 '목표/참조 수량'이며, 실행/진행 수량은 rfq_allocations / po_allocations 합계로 관찰한다.
 * - 실행 합계는 목표와 일치하지 않을 수 있으며, 이는 정상 케이스다:
 *   - 유실/파손 대비 여분 구매
 *   - 샘플 구매(납품 제외)
 *   - 공급처 최소발주단위(MOQ)로 인한 초과 구매
 *   - 향후 사용/재고 목적의 추가 구매
 * - 따라서 이 영역의 핵심은 '정합성 강제'가 아니라 '가시성(현재까지 실행/귀속된 수량의 추적)'이다.
 *
 * 담당자/협업자 변경이란, 퇴사 등의 사유로 관리자를 변경하는 경우를 뜻한다. 이때는 협업요청 절차를 통해서 진행하는 것이 아닌 sc_assignee_a_sn이나 sc_owner_a_sn을 직접 업데이트 한다. 상태는 유지 한다.
 * ----------------------------------------------------------------------- */

CREATE TABLE sourcing_cases (
  sc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수급 케이스 PK',
  sc_ol_sn BIGINT UNSIGNED NOT NULL COMMENT '주문라인 PK(order_lines) (1:1)',
  sc_required_qty DECIMAL(14,3) NOT NULL COMMENT '요구된 수급 수량(order_line 의 수량과는 다를 수 있음)',
  sc_type ENUM('DOMESTIC','OVERSEAS','IN_HOUSE')
    NOT NULL COMMENT '수급 방식(ENUM) | DOMESTIC:국내구매, OVERSEAS:해외구매, IN_HOUSE:자체제작',
  sc_assignee_a_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 수행 담당자 PK(assignees) | 협업 담당자 또는 프로젝트 담당자',
  sc_status ENUM('OPEN', 'SELF_ASSIGNED', 'ASSIGNING', 'ASSIGNEE_WORKING', 'CANCELLED', 'DONE') NOT NULL COMMENT
    '수급 케이스의 현재 처리 상태를 나타내는 코드이다.
    - OPEN               : 담당자 미확정 상태이다. 누구도 인수하지 않았으며, 담당자 지정 대기열에 해당한다.
    - SELF_ASSIGNED      : 케이스 생성자/프로젝트 담당자가 본인이 직접 처리하기로 인수한 상태이다.
    - ASSIGNING          : 특정 담당자에게 처리를 요청한 상태이다. 요청 대상의 수락/거절을 기다린다.
    - ASSIGNEE_WORKING   : 요청 받은 담당자가 수락하여 실제로 처리 중인 상태이다.
    - CANCELLED          : 케이스가 취소된 상태이다.
    - DONE               : 케이스 처리 완료 상태이다.',
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
  UNIQUE KEY uk_sourcing_cases_ol_sn (sc_ol_sn),
  KEY idx_sourcing_cases_assignee (sc_assignee_a_sn),
  KEY idx_sourcing_cases_status (sc_status),
  CONSTRAINT fk_sourcing_cases_order_lines
    FOREIGN KEY (sc_ol_sn) REFERENCES order_lines(ol_sn),
  CONSTRAINT fk_sourcing_cases_assignee
    FOREIGN KEY (sc_assignee_a_sn) REFERENCES assignees(a_sn)
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
  ) NOT NULL COMMENT 'scl_purpose_code (조달 목적/의도)
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
  -- order_line_overrides,
  -- goods 테이블이 core schema에 존재하는 경우 활성화 권장.
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
  dc_sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  dc_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  dc_closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  dc_note VARCHAR(500) NULL COMMENT '비고',
  dc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  dc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (dc_sn),
  KEY idx_domestic_cases_sc_sn (dc_sc_sn),
  CONSTRAINT fk_domestic_cases_sc
    FOREIGN KEY (dc_sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='국내 수급 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: overseas_cases
-- DESC : 해외 수급 케이스(시도 인스턴스)
-- NOTE : incoterms는 견적/발주서에 넣는게 맞다. 나중에 필요하다고 하면 넣기.
-- ESD (Estimated Shipping Date), ETA (Estimated Time of Arrival) 등도 견적/발주서에서 다루는게 맞다.
-- ======================================================================
CREATE TABLE overseas_cases (
  oc_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '해외 수급 케이스 PK(시도 인스턴스)',
  oc_sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  oc_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  oc_closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  oc_note VARCHAR(500) NULL COMMENT '비고',
  oc_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  oc_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (oc_sn),
  KEY idx_overseas_cases_sc (oc_sc_sn),
  CONSTRAINT fk_overseas_cases_sc
    FOREIGN KEY (oc_sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='해외 수급 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: inhouse_cases
-- DESC : 자체제작 케이스(시도 인스턴스)
-- NOTE : 도면 등의 첨부는 documents + document_links로 연결하기
-- 자체 제작에 특화된 상태들이 있다면 여기에 필드들을 추가하자. 현업의 요구사항에 따라 그때그때 넣을수 있다. 예> planned_start, planned_finish, qc_required 등...
-- ======================================================================
CREATE TABLE inhouse_cases (
  ic_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '자체제작 케이스 PK(시도 인스턴스)',
  ic_sc_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases)',
  ic_is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '현재 활성 케이스 여부(1=활성, 0=비활성/과거시도)',
  ic_closed_at DATETIME NULL COMMENT '종결일시(전환/중단 시, 업무 이벤트)',
  ic_expected_margin_rate DECIMAL(5,2) NULL COMMENT '제작 후 납품시 남길 수익 마진률(%)',
  ic_note VARCHAR(500) NULL COMMENT '비고',
  ic_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ic_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ic_sn),
  KEY idx_inhouse_cases_sc (ic_sc_sn),
  CONSTRAINT fk_inhouse_cases_sc
    FOREIGN KEY (ic_sc_sn) REFERENCES sourcing_cases(sc_sn)
) COMMENT='자체제작 케이스(시도 인스턴스)';


-- ======================================================================
-- TABLE: inhouse_bom_lines
-- DESC : 자체제작 BOM(자재 소요) ... 기본적인 견적/발주 프로세스는 scl을 이용하고, 여긴 제조 특화된 BOM 들을 다루자. 자세한건 추후 Develop하기
-- ======================================================================
CREATE TABLE inhouse_bom_lines (
  ibl_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '제작 BOM 라인 PK',
  ibl_ic_sn BIGINT UNSIGNED NOT NULL COMMENT '자체제작 케이스 PK(inhouse_cases)',
  ibl_item_name VARCHAR(128) NOT NULL COMMENT '(자체제작) 품목명(예: 십자 드라이버)',
  ibl_item_spec JSON NULL COMMENT '(자체제작) 규격/조건(자유형 JSON)',
  ibl_item_qty DECIMAL(14,3) NOT NULL COMMENT '(자체제작) 수량',
  ibl_item_unit VARCHAR(20) NULL COMMENT '(자체제작) 단위(예: EA, SET)',
  ibl_unit_price DECIMAL(18,2) NULL COMMENT '(자체제작) 판매 단가',

  ibl_note VARCHAR(500) NULL COMMENT '비고',
  ibl_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  ibl_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (ibl_sn),
  KEY idx_inhouse_bom_ic (ibl_ic_sn),
  CONSTRAINT fk_inhouse_bom_ic
    FOREIGN KEY (ibl_ic_sn) REFERENCES inhouse_cases(ic_sn)
) COMMENT='자체제작 BOM(자재 소요)';


-- ======================================================================
-- TABLE: inhouse_work_orders
-- DESC : 자체제작 작업지시/공정
-- ======================================================================
CREATE TABLE inhouse_work_orders (
  iwo_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '제작 작업지시 PK',
  iwo_ic_sn BIGINT UNSIGNED NOT NULL COMMENT '자체제작 케이스 PK(inhouse_cases)',
  iwo_process_name VARCHAR(255) NOT NULL COMMENT '공정/작업명',
  iwo_status ENUM('TODO','DOING','DONE','BLOCKED','CANCELLED')
    NOT NULL COMMENT '작업 상태(ENUM) | TODO:대기, DOING:진행, DONE:완료, BLOCKED:이슈, CANCELLED:취소',
  iwo_started_at DATETIME NULL COMMENT '작업 시작일시(업무 이벤트)',
  iwo_done_at DATETIME NULL COMMENT '작업 완료일시(업무 이벤트)',
  iwo_note VARCHAR(500) NULL COMMENT '비고',
  iwo_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  iwo_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
  PRIMARY KEY (iwo_sn),
  KEY idx_inhouse_work_orders_ic (iwo_ic_sn),
  KEY idx_inhouse_work_orders_status (iwo_status),
  CONSTRAINT fk_inhouse_work_orders_ic
    FOREIGN KEY (iwo_ic_sn) REFERENCES inhouse_cases(ic_sn)
) COMMENT='자체제작 작업지시/공정';


-- ======================================================================
-- TABLE: rfqs
-- DESC : RFQ(견적요청서) 헤더 - 국내/해외 통합
-- ======================================================================
CREATE TABLE rfqs (
  rfq_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'RFQ PK(견적요청서) - 국내/해외 공용',

  /* 수급 케이스 연결 */
  rfq_primary_sc_sn BIGINT UNSIGNED NULL COMMENT '대표 수급 케이스 PK(sourcing_cases) | 단독 진행이면 설정, 혼합 RFQ면 NULL 가능',
  rfq_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화(예: KRW, USD)',

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
  rfql_rfq_sn BIGINT UNSIGNED NOT NULL COMMENT 'RFQ PK(rfqs)',
  rfql_no INT NOT NULL COMMENT 'RFQ 내 줄번호',
-- g_sn은 수급쪽에서 관리하는거고, 견적서에서는 업체와 조율된 품목정보를 직접 쓰는게 맞다.
-- rfql_g_sn BIGINT UNSIGNED NOT NULL COMMENT '기성상품 PK(goods)',

  /* 견적요청정보 */
  rfql_req_name VARCHAR(128) NOT NULL COMMENT '(견적요청) 품목명(예: 십자 드라이버)',
  rfql_req_model VARCHAR(128) NOT NULL default '' COMMENT '(견적요청) 모델명',
  rfql_req_manufacturer_name VARCHAR(128) NULL COMMENT '제조사명(텍스트, 예: 삼성전자 / Panasonic / 华为)',
  rfql_req_qty DECIMAL(14,3) NOT NULL COMMENT '(견적요청) 수량(납품 약속 수량)',
  rfql_req_unit VARCHAR(20) NULL COMMENT '(견적요청) 단위(예: EA, SET)',
  rfql_req_unit_price DECIMAL(18,2) NULL COMMENT '(견적요청) 희망 단가',
  rfql_req_note VARCHAR(500) NULL COMMENT '(견적요청) 라인 특이사항/요청사항(업체 전달용)',

  /* 견적응답정보 */
  rfql_res_name VARCHAR(128) NOT NULL COMMENT '(견적응답) 품목명(예: 십자 드라이버)',
  rfql_res_model VARCHAR(128) NOT NULL default '' COMMENT '(견적응답) 모델명',
  rfql_res_manufacturer_name VARCHAR(128) NULL COMMENT '(견적응답) 제조사명(텍스트, 예: 삼성전자 / Panasonic / 华为)',
  rfql_res_qty DECIMAL(14,3) NOT NULL COMMENT '(견적응답) 수량',
  rfql_res_unit VARCHAR(20) NULL COMMENT '(견적응답) 단위(예: EA, SET)',
  rfql_res_unit_price DECIMAL(18,2) NULL COMMENT '(견적응답) 견적받은 단가',
  rfql_res_note VARCHAR(500) NULL COMMENT '(견적응답) 라인 특이사항/요청사항(업체 전달용)',

  rfql_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  rfql_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (rfql_sn),
  UNIQUE KEY uk_rfq_lines (rfql_rfq_sn, rfql_no),
  KEY idx_rfq_lines_rfq (rfql_rfq_sn),
  CONSTRAINT fk_rfq_lines_rfq FOREIGN KEY (rfql_rfq_sn) REFERENCES rfqs(rfq_sn)
) COMMENT='RFQ 라인(요청 1줄 + 회신 값(reply_*), 덮어쓰기 정책) - 국내/해외 통합';


-- ======================================================================
-- TABLE: rfq_allocations
-- DESC : RFQ 라인 배분(여러 sc 혼합 RFQ 지원) - 국내/해외 통합
-- NOTE : allocated_qty(및 합계)는 sc_required_qty(목표/참조)와 불일치할 수 있음(정상). 해석 기준은 sourcing_cases(Execution & Quantity Interpretation).
-- ======================================================================
CREATE TABLE rfq_allocations (
  rfqa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'RFQ 라인 배분 PK (실행 라인 기준)',

  rfq_sn  BIGINT UNSIGNED NOT NULL COMMENT 'RFQ PK(rfqs) - 조회 편의 캐시',
  rfql_sn BIGINT UNSIGNED NOT NULL COMMENT 'RFQ 라인 PK(rfq_lines)',
  sc_sn   BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases) - 조회 편의 캐시',
  scl_sn  BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 라인 PK(sourcing_case_lines) - 실행 단위(정본)',

  rfqa_qty DECIMAL(14,3) NOT NULL COMMENT '실행 라인(scl) 기준 요청 수량(배분)',
  rfqa_note VARCHAR(500) NULL COMMENT '비고(배분 사유 등)',

  rfqa_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  rfqa_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (rfqa_sn),

  -- 같은 RFQ 라인에 같은 실행 라인을 중복 배분하는 실수 방지
  UNIQUE KEY uk_rfq_alloc (rfql_sn, scl_sn),

  KEY idx_rfq_alloc_rfq  (rfq_sn),
  KEY idx_rfq_alloc_rfql (rfql_sn),
  KEY idx_rfq_alloc_sc   (sc_sn),
  KEY idx_rfq_alloc_scl  (scl_sn),

  CONSTRAINT fk_rfq_alloc_rfq  FOREIGN KEY (rfq_sn)  REFERENCES rfqs(rfq_sn),
  CONSTRAINT fk_rfq_alloc_rfql FOREIGN KEY (rfql_sn) REFERENCES rfq_lines(rfql_sn),
  CONSTRAINT fk_rfq_alloc_sc   FOREIGN KEY (sc_sn)   REFERENCES sourcing_cases(sc_sn),
  CONSTRAINT fk_rfq_alloc_scl  FOREIGN KEY (scl_sn)  REFERENCES sourcing_case_lines(scl_sn)
) COMMENT='RFQ 라인 ↔ 수급 실행 라인 배분(sc/rfq 캐시 포함, 실행 기준은 scl)';



-- ======================================================================
-- TABLE: purchase_orders
-- DESC : 발주서(PO) 헤더 - 국내/해외 통합
-- ======================================================================
CREATE TABLE purchase_orders (

  po_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '발주서 PK - 국내/해외 공용',

  /* 수급 케이스 연결 */
  po_primary_sc_sn BIGINT UNSIGNED NULL COMMENT '대표 수급 케이스 PK(sourcing_cases) | 단독 진행이면 설정, 혼합이면 NULL 가능',
-- 혹시 나중에 수급방식 필드가 필요할지도 모르겠는데, 그때 추가하자.
--  po_sourcing_type ENUM('DOMESTIC','OVERSEAS','IN_HOUSE','SERVICE') NULL COMMENT '수급 방식(ENUM) | 헤더 편의/필터용(선택)',

  /* 업체/작성자 */
  po_vendor_pt_sn BIGINT UNSIGNED NOT NULL COMMENT '대상 업체 PK(parties)',
  po_a_sn BIGINT UNSIGNED NOT NULL COMMENT '작성자 PK(assignees)',

  /* 근거 RFQ */
  po_source_rfq_sn BIGINT UNSIGNED NULL COMMENT '근거 RFQ PK(rfqs) | RFQ 기반 생성 시 연결',

  /* 발주 구분/상태 */
  po_status ENUM('DRAFT','SENT','ACCEPTED','REJECTED','CANCELLED','CLOSED')
    NOT NULL COMMENT '발주 상태(ENUM)',

  /* 업무 이벤트 */
  po_issued_at DATETIME NOT NULL COMMENT '발주 발행일시(업무 이벤트)',
  po_accepted_at DATETIME NULL COMMENT '발주 수락일시(업무 이벤트)',
  po_expected_delivery_at DATE NULL COMMENT '예상 납기일(업무 이벤트)',

  /* 인도/납품/결제 */
  po_delivery_method ENUM('PICKUP_BY_LOGISTICS', 'SELLER_SHIP_TO_COMPANY', 'SELLER_SHIP_TO_CUSTOMER') NULL COMMENT '판매처가 보내는 방식, 회사 관점의 흐름(회사로 오냐/직송이냐/직접 픽업이냐)',
  po_delivery_address VARCHAR(500) NULL COMMENT '인도/납품 주소',
  po_trade_terms VARCHAR(20) NULL COMMENT '인도조건(Incoterms 등) | 해외용 주로 사용(옵션)',

  /* 프로세스/정책(선택) */
  po_fx_rate_policy ENUM('QUOTE_DATE','PO_DATE','PAYMENT_DATE','CUSTOMS_DATE','MANUAL') NULL COMMENT '환율 적용 기준(정책 ENUM) | 숫자 환율은 costs/cost_fx_applications에 고정 저장 | QUOTE_DATE:견적일, PO_DATE:발주일, PAYMENT_DATE:지급일, CUSTOMS_DATE:통관일, MANUAL:수동',

  po_payment_method VARCHAR(100) NULL COMMENT '결제 방식',
  po_payment_terms VARCHAR(200) NULL COMMENT '결제 조건',
  po_tax_type ENUM('TAX_INCLUDED','TAX_EXCLUDED','UNKNOWN')
    NOT NULL DEFAULT 'UNKNOWN'
    COMMENT '부가세 포함 여부(ENUM) | 국내/해외 모두 사용 가능',

  /* 해외에서만 주로 쓰는 필드(옵션) */
  po_ship_from_country CHAR(2) NULL COMMENT '발송국가(ISO-3166-1 alpha-2) | 예: CN, US',
  po_ship_to_country CHAR(2) NULL COMMENT '도착국가(ISO-3166-1 alpha-2) | 보통 KR',

  po_note VARCHAR(500) NULL COMMENT '발주 메모(헤더)',

  po_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  po_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (po_sn),
  KEY idx_pos_vendor (po_vendor_pt_sn),
  KEY idx_pos_creator (po_a_sn),
  KEY idx_pos_primary_sc (po_primary_sc_sn),
  KEY idx_pos_source_rfq (po_source_rfq_sn),
  KEY idx_pos_status (po_status),

  CONSTRAINT fk_pos_vendor FOREIGN KEY (po_vendor_pt_sn) REFERENCES parties(pt_sn),
  CONSTRAINT fk_pos_creator FOREIGN KEY (po_a_sn) REFERENCES assignees(a_sn),
  CONSTRAINT fk_pos_primary_sc FOREIGN KEY (po_primary_sc_sn) REFERENCES sourcing_cases(sc_sn),
  CONSTRAINT fk_pos_source_rfq FOREIGN KEY (po_source_rfq_sn) REFERENCES rfqs(rfq_sn)

) COMMENT='발주서(PO) 헤더 - 국내/해외 통합';


-- ======================================================================
-- TABLE: project_purcharse_order_links
-- DESC : 프로젝트와 발주서 연결 테이블 (편의용)
-- NOTE : project->ol->olo->sc->po_allocation->po 까지의 연결은 너무 길다. 편의를 위해 proejct->po 연결을 만드는거지 이것이 project와 po의 관계를 정의하는 것은 아니다.
-- ======================================================================
CREATE TABLE project_purchase_order_links (
    ppol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PPOL PK',
    ppol_p_sn BIGINT UNSIGNED NOT NULL COMMENT 'projects.p_sn',
    ppol_po_sn BIGINT UNSIGNED NOT NULL COMMENT 'purcharse_orders.po_sn',
    ppol_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
    ppol_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',
    PRIMARY KEY (ppol_sn),
    UNIQUE KEY uk_project_po (ppol_p_sn, ppol_po_sn),
    CONSTRAINT fk_ppol_project FOREIGN KEY (ppol_p_sn) REFERENCES projects(p_sn),
    CONSTRAINT fk_ppol_po FOREIGN KEY (ppol_po_sn) REFERENCES purchase_orders(po_sn)
) COMMENT '프로젝트와 발주서 연결 테이블 (편의용)';


-- ======================================================================
-- TABLE: po_lines
-- DESC : 발주서 라인(PO 한줄) - 국내/해외 통합
-- NOTE : pol_item_name을 자체 보유, g_sn을 가지고 있지 않고, 업체에서 원하는 품목명을 관리한다.
-- 기획 요구사항에 따라, 별도의 독립된 물류 입출고 시스템과는 별개로, 발주 담당자가 스스로 자신의 물건들을 관리하기 위한 입출고 현황 필드들을 발주서에 자체 보유한다. 값을 입력하는 그대로 저장되며, 이력 관리는 별도로 하지 않는다 (activity log 제외). 이력을 원하면 추후 물류 입출고 구축 시점에서 가능. 물류 입출고가 구축되어도, 이곳의 입출고 시스템은 별개로 운영/유지 된다.
-- ======================================================================
CREATE TABLE po_lines (
  pol_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '발주서 라인 PK(업체에 보낸 실제 1줄) - 국내/해외 공용',
  pol_po_sn BIGINT UNSIGNED NOT NULL COMMENT '발주서 PK(purchase_orders)',
  pol_no INT NOT NULL COMMENT '발주서 내 줄번호',

  /* 품목 */
-- g_sn 은 수급쪽에서 관리하는거고, 발주서에서는 업체와 조율된 품목정보를 직접 쓰는게 맞다.
--  g_sn BIGINT UNSIGNED NOT NULL COMMENT '기성상품 PK(goods)',
  pol_item_name VARCHAR(128) NOT NULL COMMENT '발주서 품목명, 기본적으로 g_sn의 값을 넣어주지만 담당자가 변경할 수 있음',
  pol_qty DECIMAL(14,3) NOT NULL COMMENT '발주 수량(MOQ 등으로 더 클 수 있음)',

  /* 가격/통화(해외 포함) */
  pol_unit_cost DECIMAL(18,2) NULL COMMENT '발주 단가(확정값)',
  pol_ccy CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '발주 통화(예: KRW, USD)',

  pol_note VARCHAR(500) NULL COMMENT '라인 특이사항/요청사항(업체 전달용)',

  /* 샘플 관련 */
  pol_is_sample TINYINT(1) NOT NULL DEFAULT 0 COMMENT '샘플 라인 여부(0/1)',
  pol_sample_disposition ENUM('DISCARD','KEEP_INTERNAL','INCLUDE_IN_DELIVERY') NULL
    COMMENT '샘플 처리(ENUM) | DISCARD:폐기, KEEP_INTERNAL:내부보관, INCLUDE_IN_DELIVERY:납품포함',

  /* 어느 견적서로 부터 가져온 정보인가 */
  source_rfql_sn BIGINT UNSIGNED NULL COMMENT '근거 RFQ 라인 PK(rfq_lines) | 선택',
  source_note VARCHAR(500) NULL COMMENT '근거 설명(구두견적/메일 등)',

  pol_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  pol_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  /* 담당자 편의용 입출고 현황 필드 */
  pol_in_qty DECIMAL(14,3) NULL COMMENT '입고수량',
  pol_in_expected_dt DATETIME NULL COMMENT '입고예정일',
  pol_in_dt DATETIME NULL COMMENT '입고일자',

  pol_out_qty DECIMAL(14,3) NULL COMMENT '출고수량',
  pol_out_dt DATETIME NULL COMMENT '출고일자',
  pol_delivery_dt DATETIME NOT NULL COMMENT '계약납기일(OL과 관련없이 발주서용으로 별도 관리)',

  PRIMARY KEY (pol_sn),
  UNIQUE KEY uk_po_lines (pol_po_sn, pol_no),
  KEY idx_po_lines_po (pol_po_sn),
  KEY idx_po_lines_source_rfql (source_rfql_sn),
  CONSTRAINT fk_po_lines_po FOREIGN KEY (pol_po_sn) REFERENCES purchase_orders(po_sn),
  CONSTRAINT fk_po_lines_source_rfql FOREIGN KEY (source_rfql_sn) REFERENCES rfq_lines(rfql_sn)
) COMMENT='발주서 라인(PO 한줄) - 국내/해외 통합';


-- ======================================================================
-- TABLE: po_allocations
-- DESC : 발주 라인 배분(여러 sc 혼합 PO 지원) - 국내/해외 통합
-- NOTE : allocated_qty(및 합계)는 sc_required_qty(목표/참조)와 불일치할 수 있음(정상). 해석 기준은 sourcing_cases(Execution & Quantity Interpretation).
-- ======================================================================
CREATE TABLE po_allocations (
  poa_sn BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PO 라인 배분 PK (실행 라인 기준)',

  po_sn  BIGINT UNSIGNED NOT NULL COMMENT 'PO PK(purchase_orders) - 조회 편의 캐시',
  pol_sn BIGINT UNSIGNED NOT NULL COMMENT 'PO 라인 PK(po_lines)',
  sc_sn  BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 PK(sourcing_cases) - 조회 편의 캐시',
  scl_sn BIGINT UNSIGNED NOT NULL COMMENT '수급 케이스 라인 PK(sourcing_case_lines) - 실행 단위(정본)',

  poa_qty DECIMAL(14,3) NOT NULL COMMENT '실행 라인(scl) 기준 발주 수량(배분)',
  poa_note VARCHAR(500) NULL COMMENT '비고(배분 사유 등)',

  poa_create_dt DATETIME NOT NULL COMMENT '레코드 생성일시',
  poa_update_dt DATETIME NOT NULL COMMENT '레코드 수정일시',

  PRIMARY KEY (poa_sn),

  -- 같은 PO 라인에 같은 실행 라인을 중복 배분하는 실수 방지
  UNIQUE KEY uk_po_alloc (pol_sn, scl_sn),

  KEY idx_po_alloc_po  (po_sn),
  KEY idx_po_alloc_pol (pol_sn),
  KEY idx_po_alloc_sc  (sc_sn),
  KEY idx_po_alloc_scl (scl_sn),

  CONSTRAINT fk_po_alloc_po  FOREIGN KEY (po_sn)  REFERENCES purchase_orders(po_sn),
  CONSTRAINT fk_po_alloc_pol FOREIGN KEY (pol_sn) REFERENCES po_lines(pol_sn),
  CONSTRAINT fk_po_alloc_sc  FOREIGN KEY (sc_sn)  REFERENCES sourcing_cases(sc_sn),
  CONSTRAINT fk_po_alloc_scl FOREIGN KEY (scl_sn) REFERENCES sourcing_case_lines(scl_sn)
) COMMENT='PO 라인 ↔ 수급 실행 라인 배분(sc/po 캐시 포함, 실행 기준은 scl)';

