# Balhea ERP Operations Guide v7.9.3
## (Cost / Payable / Payment & Document Classification)

본 문서는 Balhea ERP의 **운영 관점 정본 가이드**이다.
과거 버전 언급 없이, 현재 스키마(v7.9.x 기준)를 어떻게 사용하는지가 목적이다.

---

## 1. 핵심 개념 요약

### 1.1 cost
- 비용(원가/채무)의 **발생 사실**
- 손익/원가 관리의 기준
- 지급 여부와 무관하게 먼저 발생 가능

### 1.2 payment
- 실제 **돈이 나간 행위**
- 현금흐름 관리의 기준
- **1 cost : N payment** 가능 (분할지급)
  - 예: 선금/중도금/잔금, 일부 입금, 카드+이체 혼합 등

### 1.3 payable
- 지급을 위한 **요청/승인/집행 관리 단위**
- 계좌이체 등 승인 프로세스가 필요한 경우에만 사용
- 카드 즉시결제 등은 생략 가능
- payables는 “지급을 나가게 하는 내부 프로세스 단위”이며, 실제 자금 유출은 payments에 기록한다.

---

## 2. documents vs documents 분류 원칙

### 2.1 documents (거래/비용 내용 증빙)
- "무엇을/왜 샀는가"를 증명하는 문서
- 거래 내용, 품목, 수량, 단가, 용역 범위 중심

### 2.2 documents (지급 사실 증빙)
- "돈이 실제로 나갔는가"를 증명하는 문서
- 지급 수단, 승인, 이체, 취소 등 현금흐름 중심

**결정 질문**
> 이 문서의 핵심은 ‘거래 내용(무엇을 샀나)’인가, ‘지급 사실(돈이 나갔나)’인가?

- 거래 내용 → documents
- 지급 사실 → documents

---


> 참고: v7.9.6부터 문서는 `documents`에 통합 저장하며, 근거 연결은 `document_links`로만 표현한다.

## 3. 문서 타입 표준 분류표

## 3.4 문서 타입 코드 표준(DDL ENUM)

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


### 3.1 documents에 첨부 (거래 내용/원가 증빙)
- 구매명세서 (구매 항목 정보; 온라인 쇼핑 시 카드결제 1장에 대해 셀러별로 N개 발생 가능)
- 거래명세서 / 지급요청서
  - 발주서에 대한 회신이 지연될 수 있으며, **여러 발주 건을 묶어 1장의 거래명세서로 오는 경우** 포함
- 세금계산서(전자/종이) / 계산서
- 납품서 / 검수확인서 (수령/성과 증빙)
- 운송장 / 배송내역(택배 송장, 인수증 등)
- 플랫폼/PG 정산서(월 단위 정산, 수수료/차감 포함)

### 3.2 documents에 첨부 (지급/현금흐름 증빙)
- 현금영수증(현금 지급 사실 증빙)
- 카드 승인 내역(승인번호/금액/일시)
- 계좌이체 영수증(송금확인)
- 카드 취소/환불 전표
- 카드사 청구서(월 단위 결제/취소/할부/수수료 포함)

### 3.3 업무 문서(참고)
- 발주서(PO 문서)
  - 비용/지급 ‘증빙’이라기보다 **조달 의사결정/업무 문서**
  - 가능하면 별도 업무 문서 저장소(예: documents)에 관리 권장
  - 여건상 documents에 둘 경우, 문서 타입(PO_DOC 등)을 명확히 표시하여 혼선을 방지

---

## 4. 대표 운영 시나리오 (촘촘 버전)

### 시나리오 A: 온라인 주문 + 카드 즉시결제 (재무 이체 요청 없음)
**상황**
- 발주서(PO)대로 구매 진행
- 결제는 즉시 카드 승인
- 재무 담당자에게 이체 요청 불필요

**입력 흐름**
1) purchase_order 생성(검토/승인 후 발행)
2) cost 생성(원가 인식)
   - 필요 시 cost_allocations로 주문항목(order_line) 또는 수급케이스(sourcing_case)에 귀속
3) payment 생성(pay_method=CARD)
4) documents에 카드 승인 내역 첨부
5) documents에 구매명세서(셀러별 N개 가능) 첨부
6) (선택) 현금영수증이 발급되면 documents에 추가 첨부

**메모**
- payable은 생성하지 않는다(요청/승인 프로세스 불필요)

---

### 시나리오 B: 발주 기반 + 계좌이체 (재무 승인/집행 필요)
**상황**
- 발주서는 존재
- 지급은 계좌이체로 진행
- 내부 승인/지급요청 단계 필요

**입력 흐름**
1) purchase_order 생성(검토/승인 후 발행)
2) cost 생성(원가/채무 인식)
3) payable 생성(지급요청/승인 단위)
   - 지급 예정일, 우선순위, 지급 사유 등을 기록
4) 승인 후 payment 생성(pay_method=TRANSFER)
5) documents에 이체 영수증 첨부
6) 필요 시 payment_lines로 cost와 금액 연결(분할지급 대응)

**메모**
- 한 cost를 여러 번 이체할 수 있으므로 payment를 여러 건 생성 가능

---

### 시나리오 C: 비발주 비용(배송료/운송료/미팅 음료/주유비/검수비 등)
**상황**
- 발주서 없이 발생하는 비용
- 비용 내역만 costs에 기록
- 주문항목에 기인한 비용이면 선택적으로 귀속

**입력 흐름**
1) cost 직접 생성(비PO 비용)
   - 예: “주문항목 3번 물품 검수비”, “업체 미팅 음료비”, “주유비” 등
2) (선택) cost_allocations로 order_line 또는 sourcing_case에 귀속
3) payment 생성
   - 카드 결제면 CARD
   - 직원이 현금 지출이면 CASH (재무 정산/환급 프로세스는 논외)
4) documents에 영수증/현금영수증 첨부
5) 지급이 발생했다면 documents에 해당 지급증빙(카드승인/이체확인)을 첨부

---

### 시나리오 D: Invoice 1건이 여러 PO 묶음 + PO 외 부대비용 포함
**상황**
- 업체가 지급요청서/거래명세서 형태로 송부
- 여러 PO를 묶어 청구
- 탁송료/부대비 등 PO에 없는 비용 라인이 포함될 수 있음

**입력 흐름**
1) invoice 생성(문서 컨테이너)
2) invoice_lines 생성
   - 여러 purchase_order(또는 po_line)에 연결 가능
   - PO 외 부대비용은 별도 invoice_line으로 추가
3) cost 생성(필요한 원가/채무 인식)
   - PO 기반이면 PO/PO line 연결
   - 부대비용은 비용 항목(cost)으로 별도 생성 가능
4) payable 생성(이체 승인/집행이 필요하면)
5) 승인 후 payment 생성(TRANSFER)
6) documents에 거래명세서/지급요청서 및 세금계산서 첨부
7) documents에 이체확인 첨부

---

### 시나리오 E: 1 cost를 여러 번 분할 지급(선금/중도금/잔금)
**상황**
- 총 비용(cost) 1건
- 지급(payment) 여러 번

**입력 흐름**
1) cost 1건 생성(총액)
2) payment 1건 생성(선금) + payment_lines로 cost에 일부 연결
3) payment 1건 생성(중도금) + payment_lines로 cost에 일부 연결
4) payment 1건 생성(잔금) + payment_lines로 cost에 잔액 연결
5) 각 payment마다 documents로 지급 증빙 첨부

---

## 5. 운영 체크리스트(팀 공통)

- 비용이 발생했는가? → **cost**
- 돈이 실제로 나갔는가? → **payment**
- 승인/이체 프로세스가 필요한가? → **payable**
- 문서의 핵심이 거래 내용인가? → **documents**
- 문서의 핵심이 지급 사실인가? → **documents**

---

본 문서는 운영/감사/정산 시 혼선을 막기 위한 기준 문서이며,
모든 팀은 본 가이드를 따른다.

## 6. cost / payable / payment 결정 트리(체크리스트)

아래는 “무엇을 생성해야 하는지”를 빠르게 판단하기 위한 **결정 트리**다.

### 6.1 결정 트리(질문 순서)

1) **비용이 발생했나?** (무엇을/왜 샀는지, 원가/채무를 인식해야 하는가?)
- YES → `costs` 생성
- NO → (아직 비용이 확정되지 않았다면) 문서(견적/초안 등)만 보관하고 종료

2) **그 비용이 특정 프로젝트/주문항목/수급케이스에 기인하나?**
- YES → `cost_allocations`로 `p_sn`/`o_sn`/`ol_sn`/`sc_sn` 중 적절한 키에 배부
- NO → `costs`에만 기록(추후 배부 가능)

3) **돈이 실제로 나갔나?** (카드 승인/이체/현금 지출 등)
- YES → `payments` 생성
  - pay_method = `CARD` / `TRANSFER` / `CASH`
- NO → 아직 미지급 상태로 유지(추후 지급 시 payments 생성)

4) **지급이 승인/요청 프로세스를 거쳐야 하나?**
- YES → `payables` 생성(요청/승인/보류/부분지급 관리)
  - 승인 후 `payments` 생성 및 연결
- NO → `payables` 생략 가능(예: 온라인 카드 즉시 결제)

5) **1개의 비용(cost)이 여러 번 나눠 지급될 수 있나?**
- YES → `payments`를 여러 건 생성하고, 각 `payment_lines`로 같은 `costs`에 분할 연결
- NO → 1:1로 연결해도 됨

### 6.2 문서 첨부 결정 트리(요약)

- “무엇을/왜 샀나” → `documents`
- “돈이 나갔나/어떻게 나갔나” → `documents`

### 6.3 현금영수증 정본 규칙(중요)
- **현금영수증은 ‘지급 사실’ 증빙이므로 `documents`에 첨부한다.**
- 비용의 발생(왜/무엇 때문에)은 `costs`에 기록하고, 현금 지급 행위는 `payments(pay_method=CASH)`로 기록한다.
- 화면(UI)에서는 `payment_lines`로 연결된 지급 증빙을 비용 화면에서도 함께 조회할 수 있게 구성한다(데이터 모델은 분리, 사용자 경험은 통합).


## 7. 감사/정산 관점 최소 요구 증빙(필수 문서 세트)

아래는 운영·감사·정산에서 “최소한 이 정도는 남겨야 한다”는 **권장 최소 세트**다.
(업무/거래 특성에 따라 추가 문서가 필요할 수 있다.)

### 7.1 카드 결제(온라인 즉시결제 포함) - 최소 세트
- `documents`
  - 카드 승인 내역(`CARD_APPROVAL`) **필수**
  - (월 정산 필요 시) 카드사 청구서(`CARD_STATEMENT`) 권장
- `documents`
  - 구매명세서/구매항목정보(`PURCHASE_DETAILS`) **필수**
  - 세금계산서/계산서(`INVOICE_TAX`) 발급 시 첨부

### 7.2 계좌이체 - 최소 세트
- `documents`
  - 이체 영수증/송금확인(`BANK_TRANSFER_RECEIPT`) **필수**
- `documents`
  - 거래명세서/지급요청서(`STATEMENT`) **필수**
  - 세금계산서/계산서(`INVOICE_TAX`) 발급 시 첨부
- (승인 프로세스가 있는 경우) `payables` 상태 이력(승인자/승인일 등)은 시스템 로그로 남기는 것을 권장

### 7.3 현금 지출(직원 현금 지출 포함) - 최소 세트
- `documents`
  - 현금영수증(`CASH_RECEIPT`) **필수**
- `costs`
  - 비용 내역(예: 퀵서비스/주유비/미팅비 등)을 `costs`에 기록 **필수**
  - 특정 프로젝트/주문항목에 기인한 비용이면 `cost_allocations`로 귀속 **권장**
- (권장) `payments(pay_method=CASH)` 기록
  - 현금이 실제로 지급되었다는 사실을 시스템 내에도 남김
  - 직원 정산/환급 프로세스는 별도 정책(본 범위 외)

### 7.4 Invoice(지급요청서/거래명세서)로 여러 PO를 묶는 경우 - 최소 세트
- `documents`
  - 거래명세서/지급요청서(`STATEMENT`) **필수**
  - 세금계산서/계산서(`INVOICE_TAX`) 발급 시 첨부
- `documents`
  - 지급 방식에 따른 증빙(카드 승인 또는 이체 영수증) **필수**
- (가능하면) invoice_lines에 PO/PO line 연결, PO 외 부대비용 라인은 별도 invoice_line으로 분리

## 8. 문서 허브(documents + document_links) 운영 규칙

## 8.1 문서 허브 코드 표준 (권장; 확장 가능)

### doc_category
| 코드 | 설명 |
|---|---|
| `COST` | 비용/원가/부채 관련 근거 문서 |
| `PAYMENT` | 지급/현금흐름 관련 증빙 |
| `INVOICE` | 청구/요청/거래명세(인보이스) |
| `PURCHASE` | 조달/구매(발주, 견적 등) |
| `DELIVERY` | 배송/물류(운송, 인수, 검수) |
| `CUSTOMS` | 통관/무역 서류(B/L, 신고필증 등) |
| `QUALITY` | 품질/검수/시험 성적서 |
| `CONTRACT` | 계약/약정/합의서 |
| `TAX` | 세무(세금계산서, 계산서 등) |
| `SETTLEMENT` | 정산/대사(플랫폼/PG/카드사 청구 등) |
| `REFUND` | 환불/취소 관련 |
| `OTHER` | 기타(설명은 note에 기재) |


### doc_type
| 코드 | 설명 |
|---|---|
| `CASH_RECEIPT` | 현금영수증 |
| `CARD_APPROVAL` | 카드 승인 내역(승인번호/금액/일시) |
| `BANK_TRANSFER_RECEIPT` | 계좌이체 영수증/송금확인 |
| `CARD_STATEMENT` | 카드사 청구서(월 단위) |
| `TAX_INVOICE` | 전자/종이 세금계산서 |
| `BILL` | 계산서(면세 등) |
| `STATEMENT` | 거래명세서/지급요청서(여러 발주 묶음 가능) |
| `INVOICE` | 청구서/인보이스(요청) |
| `PURCHASE_DETAILS` | 구매명세서/구매항목정보(셀러별 N개 가능) |
| `QUOTE` | 견적서 |
| `PO_DOC` | 발주서(업무 문서) |
| `DELIVERY_NOTE` | 납품서/인수증/검수확인서 |
| `SHIPMENT_PROOF` | 운송장/배송내역/송장(B/L 포함) |
| `CUSTOMS_CLEARANCE` | 통관서류(수입신고필증 등) |
| `QUALITY_REPORT` | 시험성적서/검사성적서/품질보고서 |
| `PLATFORM_SETTLEMENT` | 플랫폼/PG 정산서(수수료/차감 포함) |
| `REFUND_PROOF` | 환불/취소 증빙(카드취소전표 등) |
| `ETC` | 기타(설명은 note에 기재) |


### document_links.target_type
| 코드 | 설명 |
|---|---|
| `PROJECT` | projects(p_sn) |
| `ORDER` | orders(o_sn) |
| `ORDER_LINE` | order_lines(ol_sn) |
| `SOURCING_CASE` | sourcing_cases(sc_sn) |
| `RFQ` | rfqs(rfq_sn) |
| `RFQ_LINE` | rfq_lines(rfql_sn) |
| `PURCHASE_ORDER` | purchase_orders(po_sn) |
| `PO_LINE` | po_lines(pol_sn) |
| `COST` | costs(ct_sn) |
| `PAYABLE` | payables(pv_sn) |
| `PAYMENT` | payments(pay_sn) |
| `INVOICE` | invoices(inv_sn) |
| `INVOICE_LINE` | invoice_lines(invl_sn) |
| `DELIVERY` | deliveries(dv_sn) |
| `DELIVERY_LINE` | delivery_lines(dvl_sn) |
| `SHIPMENT` | shipments(sh_sn) |
| `OTHER` | 기타(설명은 note에 기재) |


본 시스템은 문서/증빙/서류를 **단일 테이블 `documents`** 에 저장하고,
문서가 무엇의 근거인지(비용/지급/인보이스/배송 등)는 **`document_links`** 로만 표현한다.

### 8.1 핵심 원칙
- 비용 사실은 `costs`에 기록한다.
- 지급(현금흐름) 사실은 `payments`에 기록한다.
- 문서 파일/증빙/서류는 모두 `documents`에 저장한다.
- “무엇의 근거인가?”는 `document_links(target_type, target_sn)`로만 연결한다.
- 동일 문서를 여러 엔티티에 연결할 수 있으며(다대다), **문서 저장은 1회(`documents`) + 연결만 복수(`document_links`)** 로 처리한다.

### 8.2 권장 doc_category / doc_type 표준
- doc_category (상위 분류, 권장 값): `COST`, `PAYMENT`, `INVOICE`, `DELIVERY`, `CUSTOMS`, `QUALITY`, `CONTRACT`, `OTHER`
- doc_type (세부 유형, 예시):
  - `CASH_RECEIPT` : 현금영수증
  - `CARD_APPROVAL` : 카드 승인 내역
  - `BANK_TRANSFER_RECEIPT` : 계좌이체 영수증/송금확인
  - `PURCHASE_DETAILS` : 구매명세서/구매항목정보(셀러별 N개 가능)
  - `STATEMENT` : 거래명세서/지급요청서(여러 발주 묶음 가능)
  - `INVOICE_TAX` : 세금계산서/계산서
  - `DELIVERY_NOTE` : 납품서/검수확인
  - `SHIPMENT_PROOF` : 운송장/배송내역
  - `PLATFORM_SETTLEMENT` : 플랫폼/PG 정산서
  - `REFUND_PROOF` : 환불/취소 증빙
  - `OTHER` : 기타

### 8.3 document_links target_type 권장 값(예시)
- `COST` → costs(ct_sn)
- `PAYMENT` → payments(pay_sn)
- `INVOICE` → invoices(inv_sn)
- `PAYABLE` → payables(pv_sn)
- `PURCHASE_ORDER` → purchase_orders(po_sn)
- `RFQ` → rfqs(rfq_sn)
- `DELIVERY` → deliveries(dv_sn)
- `DELIVERY_LINE` → delivery_lines(dvl_sn)

> 주의: document_links는 polymorphic이므로 DB FK로 모든 대상에 강제 연결하지 않는다.
> 대신 target_type + target_sn 유효성은 애플리케이션에서 검증한다.

### 8.4 예시: 퀵서비스 + 현금 지급
1) `costs`에 “퀵서비스 비용” 기록
2) `payments(pay_method=CASH)`에 실제 지급 기록
3) 현금영수증 파일을 `documents`에 저장(doc_category=PAYMENT, doc_type=CASH_RECEIPT)
4) `document_links`로 문서를 payments에 연결(target_type=PAYMENT, target_sn=<pay_sn>)
5) (선택) 동일 문서를 costs에도 연결 가능(target_type=COST, target_sn=<ct_sn>)

---

## (정본 통합) 운영 가이드 — Data Examples + Policy & Assumptions (v7.9.7)

본 섹션은 다음 두 문서에서 **현재 정본(v7.9.7) 구조에도 유효한 내용만**을 선별하여,
운영 관점(점검/재처리/정산/증빙 연결/샘플발주→본발주 전환 등)에 맞게 **병합/정리**한 것이다.

- 과거/폐지 엔티티(domestic_*, overseas_*, *_documents 등)를 전제로 한 표현은 본문에 남기지 않는다.
- “풍부한 내용 유지”는 원문을 그대로 붙이는 것이 아니라, **동일 목적의 운영 템플릿/절차/검증 포인트를 최신 구조로 통일**해 유지하는 것을 뜻한다.

### 1) 운영 우선 정책(99% 경로)과 희소 케이스 처리

## 3. 99% 경로(운영 편의성 우선)
- 대부분의 케이스는 **주문라인 1개 = 실제 구매/납품 상품(goods) 1개**다.
- 업무자는 주문서를 작성/검토하는 시점에 “실제로 어떤 기성품(goods)을 수급해서 납품할지”를 결정한다.
- 이를 위해 `order_lines.ol_default_g_sn`(기본 goods FK)을 제공한다.
- RFQ/PO 생성 시:
  - override가 없다면 `ol_default_g_sn`을 사용해 문서 라인을 자동 생성한다.

## 4. 희소 케이스(1% 내외) — Override 패턴
희소 케이스(재고부족 분할, 대체품 일부, 불량 추가구매, PC 조합 등)는
전체 스키마를 복잡하게 만들지 않기 위해 `order_line_overrides`로만 수용한다.

- override 유형:
  - `SPLIT` : 수량을 나누어 여러 상품/여러 발주로 처리
  - `SUBSTITUTE` : 일부를 유사 대체품으로 처리
  - `ADD_ON` : 불량/추가요청 등으로 추가 구매
  - `BUNDLE` : 조합 납품(PC 등) 구성품 구매 단위
- 문서 생성 규칙:
  - override가 있으면 override를 우선 전개하여 RFQ/PO 라인을 만든다.
  - override가 없으면 default goods를 사용한다.
- 변경 이력은 `audit_changes`에 JSON 기반으로 남긴다.

### 2) 샘플 발주 → 본발주 운영 절차(해외 포함)

## 8. 샘플 발주 정책
- 샘플 발주는 PO 헤더/라인에서 구분한다.
- 샘플 이후 케이스:
  1) 샘플은 납품 불가(폐기) → 본발주를 별도로
  2) 샘플은 내부 보관(납품 제외) → 잔량만 본발주
  3) 샘플도 납품 포함 가능 → 잔량만 본발주 + 납품 계산에 포함
- 샘플 관련 비용은 `costs` 및 `*_po_cost_links`를 통해 별도로 기록/배분 가능하다.


---

### 예시 5) 해외구매(OVERSEAS) 샘플 발주 → 본발주 + 환율 고정

#### 상황 A: 샘플 2개 테스트 후 폐기(납품 불가) → 본발주 100개 별도

`goods`
- (g_sn=9101) manufacturer_name='Shenzhen ABC', goods_name='Sensor Module X v2', model_no='SMX-V2'

`order_lines` / `sourcing_cases`
- (ol_sn=1002) qty_required=100, ol_default_g_sn=9101
- (sc_sn=5002) ol_sn=1002, sourcing_type='OVERSEAS', sc_status='OPEN'

#### 1) 샘플 PO(폐기)
- `purchase_orders`
  - (po_sn=9002) vendor_pt_sn=401(해외업체), sourcing_type='OVERSEAS', po_kind='SAMPLE', po_status='SENT'
  - (선택) trade_terms='EXW', ship_from_country='CN', ship_to_country='KR'
- `po_lines`
  - (pol_sn=9102) po_sn=9002, line_no=1, g_sn=9101, po_qty=2, unit_price=..., currency='USD', is_sample=1, sample_disposition='DISCARD'
- `po_allocations`
  - (poa_sn=...) pol_sn=9102, sc_sn=5002, olo_sn=NULL, allocated_qty=2

#### 2) 본발주 PO(샘플과 별개로 100개)
- `purchase_orders`
  - (po_sn=9003) vendor_pt_sn=401, sourcing_type='OVERSEAS', po_kind='NORMAL', po_status='SENT'
- `po_lines`
  - (pol_sn=9103) po_sn=9003, line_no=1, g_sn=9101, po_qty=100, unit_price=..., currency='USD', is_sample=0
- `po_allocations`
  - (poa_sn=...) pol_sn=9103, sc_sn=5002, olo_sn=NULL, allocated_qty=100

#### 3) 해외 비용(USD) + 환율 고정(감사 재현)

예: 통관비/포워딩/국제운송 등

- `costs`
  - (ct_sn=8101) cost_type='CUSTOMS', vendor_pt_sn=402(관세사/통관대행), occurred_at='2026-01-18', amount=300, currency='USD', description='통관비(USD)'
- (선택) `po_cost_links`
  - (pcl_sn=...) po_sn=9003, ct_sn=8101  (조회/탐색 편의; 원가 계산의 근거는 아님)
- `cost_allocations`
  - (ca_sn=...) ct_sn=8101, sc_sn=5002, ol_sn=1002, olo_sn=NULL, allocated_amount=300, note='해외 통관비를 해당 수급에 귀속'

정산/회계 재현을 위한 환율 고정
- `cost_fx_applications`
  - (cfa_sn=...) ct_sn=8101
    - src_currency='USD', src_amount=300
    - applied_fx_rate=1,350.00
    - as_of_dt='2026-01-18'
    - base_amount=405,000  (KRW)

#### 상황 B: 샘플 2개 내부 보관(납품 제외) → 잔량 98개만 본발주
- 샘플 PO: sample_disposition='KEEP_INTERNAL', po_qty=2
- 본발주 PO: po_qty=98

#### 운영 주의(정본)
- “납품 약속 수량(qty_required)”을 샘플 포함 여부에 따라 어떻게 충족할지 회사 정책을 고정해야 한다.
  - 샘플이 납품 불가면 본발주를 100으로 해야 함
  - 샘플이 납품 가능이면 본발주 98 + 샘플 2로 100 납품 가능

---

### 3) 문서/증빙 운영: documents 저장 + document_links 연결

### 0-3. 문서/증빙: 문서 허브 단일화(정본)
- 모든 파일/증빙/서류 원본은 **`documents`** 에 저장
- “무엇의 근거인지(비용/지급/인보이스/배송 등)” 연결은 **`document_links`** 로만 표현

> 문서 코드값(권장; 확장 가능)
> - `documents.doc_category`: COST, PAYMENT, INVOICE, PURCHASE, DELIVERY, CUSTOMS, QUALITY, CONTRACT, TAX, SETTLEMENT, REFUND, OTHER
> - `documents.doc_type`: CASH_RECEIPT, CARD_APPROVAL, BANK_TRANSFER_RECEIPT, CARD_STATEMENT, TAX_INVOICE, BILL, STATEMENT, INVOICE,
>   PURCHASE_DETAILS, QUOTE, PO_DOC, DELIVERY_NOTE, SHIPMENT_PROOF, CUSTOMS_CLEARANCE, QUALITY_REPORT, PLATFORM_SETTLEMENT, REFUND_PROOF, ETC

---

## 1) 엔티티 흐름 (요약)

정본 기준의 대표 흐름(국내/해외 공통):

`projects` → `orders` → `order_lines`
(+ 필요 시 `order_line_overrides`)
→ `sourcing_cases(sc_sn)`
→ `rfqs` / `rfq_lines` / `rfq_allocations`
→ `purchase_orders` / `po_lines` / `po_allocations`
→ (비용) `costs` / `cost_allocations` (+ 선택: `po_cost_links`)
→ (지급) `payments` / `payment_lines`
→ (증빙) `documents` + `document_links`

메모
- 국내/해외 구분은 **소스 오브 트루스가 `sourcing_cases.sourcing_type`** 이다.
- RFQ/PO의 `sourcing_type` 는 조회/필터용으로만 두고, 필수는 아니다(정책 선택).
- 샘플 발주는 `purchase_orders.po_kind = SAMPLE` 로 표준화한다.

---

## 2) 정본 예시 (v7.9.7+ 스키마 기준)

### 예시 6) 오픈마켓 1회 결제 + 셀러 영수증 N장 (문서 허브 정본)

#### 목표/원칙
- ERP는 **정산 주체(플랫폼)** 만 party로 기억한다.
- 셀러 N곳은 `parties`로 만들지 않는다.
- 셀러 표시명/발행자명은 `documents.issuer_name`(또는 issuer_display_name) 텍스트로만 보존한다.
- 영수증/정산서/카드전표 등 파일은 `documents`에 넣고,
  어떤 결제(payments)의 근거인지 `document_links` 로 연결한다.

#### 상황
- 네이버에서 1회 결제(3,240,000원)
- 셀러 영수증은 여러 장(예: 100장)

#### 입력
`parties`
- (pt_sn=90000001) name='네이버(정산 주체)'

`costs` (비용 발생)
- (ct_sn=7001) vendor_pt_sn=90000001, occurred_at='2026-01-15 10:00', amount=3,240,000, currency='KRW', description='네이버 구매(여러 셀러 합산)'

(선택) `cost_allocations` (귀속)
- 단일 주문라인에 전액 귀속: (ca_sn=...) ct_sn=7001, ol_sn=1001, allocated_amount=3,240,000
- 여러 주문라인에 분할 귀속: (ca_sn=...) ct_sn=7001, ol_sn=..., allocated_amount=... ... (N줄)

`payments` (실제 지급)
- (pay_sn=9001) pay_method='CARD', pay_status='PAID', payee_pt_sn=90000001, paid_at='2026-01-15 10:01', amount=3,240,000, currency='KRW', ref_no='CARD-APPROVAL-1234'

`payment_lines` (지급-비용 연결)
- (pyl_sn=...) pay_sn=9001, ct_sn=7001, paid_amount=3,240,000, note='일괄 결제'

`documents` (원본 파일)
- 카드 승인 내역(카드전표):
  - (doc_sn=60000) doc_category='PAYMENT', doc_type='CARD_APPROVAL', issuer_name='네이버', file_name='card_approval.pdf', storage_key='s3://.../card_approval.pdf'
- 플랫폼 정산서(수수료/차감 포함):
  - (doc_sn=60010) doc_category='SETTLEMENT', doc_type='PLATFORM_SETTLEMENT', issuer_name='네이버', file_name='settlement_202601.pdf', storage_key='s3://.../settlement_202601.pdf'
- 셀러별 영수증 N장(발행 주체는 셀러 표시명):
  - (doc_sn=60001) doc_category='PAYMENT', doc_type='PURCHASE_DETAILS', issuer_name='스마트스토어 A상점', file_name='receipt_a.pdf', storage_key='s3://.../receipt_a.pdf'
  - (doc_sn=60002) doc_category='PAYMENT', doc_type='PURCHASE_DETAILS', issuer_name='스마트스토어 B상점', file_name='receipt_b.pdf', storage_key='s3://.../receipt_b.pdf'
  - ...

`document_links` (증빙 연결: payment 근거)
- (dl_sn=61000) doc_sn=60000, target_type='PAYMENT', target_sn=9001
- (dl_sn=61010) doc_sn=60010, target_type='PAYMENT', target_sn=9001
- (dl_sn=61001) doc_sn=60001, target_type='PAYMENT', target_sn=9001
- (dl_sn=61002) doc_sn=60002, target_type='PAYMENT', target_sn=9001
- ...

#### 운영 팁
- “영수증 모아보기”는 `document_links WHERE target_type='PAYMENT' AND target_sn=9001` 로 구현한다.
- 셀러명을 party로 만들지 않으므로, 셀러 단위 집계가 필요하면 `documents.issuer_name` 텍스트를 기준으로 집계한다.

---

### 4) 비용/지급/정산 운영 레시피

### 예시 7) 퀵/대행 비용 (PO와 무관) + 특정 주문라인/수급(sc)에 귀속

#### 상황
- 긴급 퀵 배송비 18,000원 발생
- 특정 수급건(sc) / 주문라인(ol)에 원가로 귀속해야 함
- 지급은 다음날 이체로 처리

#### 입력
`parties`
- (pt_sn=90000099) name='퀵/대행(예약 거래처)'

`costs`
- (ct_sn=7101) cost_type='SHIPPING', vendor_pt_sn=90000099, occurred_at='2026-01-15 14:30', amount=18,000, currency='KRW', description='긴급 퀵 배송'

`cost_allocations` (귀속)
- (ca_sn=...) ct_sn=7101, sc_sn=9001, ol_sn=1001, olo_sn=NULL, allocated_amount=18,000, note='드라이버 납품용 퀵'

`payments`
- (pay_sn=70002) pay_method='TRANSFER', pay_status='PAID', payee_pt_sn=90000099, paid_at='2026-01-16 18:00', amount=18,000, currency='KRW'

`payment_lines`
- (pyl_sn=...) pay_sn=70002, ct_sn=7101, paid_amount=18,000

`documents` + `document_links` (선택: 증빙)
- `documents`
  - (doc_sn=62001) doc_category='PAYMENT', doc_type='BANK_TRANSFER_RECEIPT', issuer_name='은행', file_name='transfer_70002.png', storage_key='s3://.../transfer_70002.png'
- `document_links`
  - (dl_sn=63001) doc_sn=62001, target_type='PAYMENT', target_sn=70002

---

### 예시 8) 선금/중도금/잔금 분할 지급 (비용 1건, 지급 3건)

#### 상황
- 동일 비용(ct) 1건에 대해 3회 분할 지급
  - 선금 3,000,000
  - 중도금 5,000,000
  - 잔금 2,000,000

#### 입력
`costs`
- (ct_sn=7201) description='공급업체 A 대금(총액)', amount=10,000,000, currency='KRW'

`payments`
- (pay_sn=9201) pay_method='TRANSFER', pay_status='PAID', paid_at='2026-01-10', amount=3,000,000, currency='KRW'
- (pay_sn=9202) pay_method='TRANSFER', pay_status='PAID', paid_at='2026-02-10', amount=5,000,000, currency='KRW'
- (pay_sn=9203) pay_method='TRANSFER', pay_status='PAID', paid_at='2026-03-10', amount=2,000,000, currency='KRW'

`payment_lines`
- (pyl_sn=...) pay_sn=9201, ct_sn=7201, paid_amount=3,000,000, note='선금'
- (pyl_sn=...) pay_sn=9202, ct_sn=7201, paid_amount=5,000,000, note='중도금'
- (pyl_sn=...) pay_sn=9203, ct_sn=7201, paid_amount=2,000,000, note='잔금'

`documents` + `document_links` (선택: 각 지급에 대한 증빙 첨부)
- documents: (doc_sn=...) doc_category='PAYMENT', doc_type='BANK_TRANSFER_RECEIPT', file_name='deposit_9201.pdf'
- document_links: (dl_sn=...) doc_sn=..., target_type='PAYMENT', target_sn=9201

---

### 5) 거래처/재무 운영 원칙(정본)

## (정본) 거래처(Parties) 운영 원칙 — v7.9.7 기준

## (정본) 비용/지급/증빙(재무) 모델 — v7.9.7 기준

---

## (정본 통합) PO After 물류/배송 운영 정책 — v7.9.7

> 출처: “수급/발주 이후(PO After) + 수급 도메인 통합 정책” 문서에서 **현재 정본에도 유효한 내용만**을 선별해,
> 최신 스키마 구조(RFQ/PO 단일화, 문서 허브 단일화)를 전제로 재작성/병합했다.

### 1) PO After는 4축으로 모델링한다(정본)

발주 이후(PO After) 영역은 “국내/해외”가 아니라 **실무 추적 단위**에 따라 아래 4축으로 분리한다.

1. **실물 단위(바코드 단위)**: `inventory_units`
2. **운송 단위(외부/구간 추적)**: `shipments` + `shipment_milestones` (+ `shipment_items`)
3. **사람이 수행하는 작업 단위(수거/이송/납품, 수동 담기)**:  
   `logistics_jobs` + `logistics_job_stops` + `logistics_job_lines`
4. **구매팀↔물류팀 협의/역제안(요일/시간창 요청)**:  
   `delivery_requests` + `delivery_request_lines` + `delivery_request_proposals`

이 4축을 분리하면,
- 회사가 실물을 만지지 않는 **직송**과, 바코드 기반 **입고/출고/재고** 흐름을 동시에 수용하고
- 물류팀이 수행하는 “작업(배차/수거/이송/납품)”을 1급 엔티티로 남길 수 있으며
- 구매팀과 물류팀의 **협의(역제안/수락/거절)** 로그를 “요청”으로 독립시켜 운영할 수 있다.

### 2) 배송요청(협의/역제안) 상태 전이(권장)

- `SUBMITTED`(요청) → `COUNTERED`(역제안) → `ACCEPTED`(수락) → `SCHEDULED`(배차 확정) → `DONE`(완료)
- 거절은 `REJECTED`로 종료

#### 권장 데이터 규칙
- `delivery_requests`: 요청 헤더(요청 창/요청자/상태)
- `delivery_request_lines`: 요청 대상 목록
  - 대상은 `order_lines`(납품 목적), `order_line_overrides`(override), `inventory_units`(실물) 중 **운영 편의에 맞게 선택**
- `delivery_request_proposals`: 역제안/수락/거절 로그(시간창, 메시지)
- 합의 후 실제 수행은 `logistics_jobs`로 생성하고 연결 테이블로 매핑한다.

> **주의:** 배송요청은 “협의가 필요할 때만” 사용한다.  
> 요청 없이 긴급 출고/납품이 발생해도, **실행 이력은 반드시 `logistics_jobs`로 남긴다.**

### 3) 현업 3가지 운영 케이스(권장 흐름)

#### 케이스 A: 물류팀이 판매처 방문 수거 → (A1) 직납 또는 (A2) 창고 입고
공통:
- 구매팀이 협의가 필요하면 `delivery_requests`를 생성하고, 합의되면 `logistics_jobs`와 연결한다.

(A1) **직납(수거→납품처)**
- 권장: `logistics_jobs.job_type = 'PICKUP_DELIVERY'`
- `logistics_job_stops`: `VENDOR` → `CUSTOMER_SITE`
- 바코드가 필요하면: 수거 시점에 `inventory_units` 생성 후 `logistics_job_lines`에 담는다.
- 바코드가 불필요하면: `inventory_units`는 생략 가능. 대신 납품 증빙은 **문서 허브로 연결**한다.  
  - `documents`에 저장 → `document_links`로 `logistics_jobs` 또는 `shipment_milestones`에 연결

(A2) **수거→창고 입고**
- `logistics_job_stops`: `VENDOR` → `WAREHOUSE`(또는 `OFFICE`)
- 창고 도착 시 `inventory_units` 생성(바코드 발급) 후 적치한다.
- 이후 납품은 별도 `logistics_jobs(job_type='DELIVERY')`로 실행한다.

#### 케이스 B: 판매처에서 사무실/창고로 배송 → 물류팀 분류 후 이동
- 도착 시점에 `inventory_units` 생성 + 바코드 할당
- 사무실→창고 이동은 `logistics_jobs(job_type='TRANSFER')`로 기록
  - `logistics_job_stops`: `OFFICE` → `WAREHOUSE`
  - 이동 대상은 `logistics_job_lines`에 `inventory_units`를 수동으로 담는다.

#### 케이스 C: 판매처에서 납품처로 직접 배송(직송)
- 권장: `shipments`로 운송을 기록하고, 필요 시 `shipment_milestones`에 송장/상태를 남긴다.
- 회사가 실물을 만지지 않는다면 `inventory_units`는 생성하지 않아도 된다.
- 납품 완료 증빙은 문서 허브로 연결한다.
  - 예: `shipment_milestones(milestone_type='DELIVERED')`에 `document_links`로 연결

### 4) 비용/환율/정산 운영 원칙(정본)

- 정산의 “정답”은 항상 `cost_allocations`다.
- 빠른 조회/분류를 위한 보조 링크는 허용한다(회계 기준 아님):
  - `po_cost_links`, `shipment_cost_links`, `logistics_job_cost_links`
- 해외 비용은 감사/재현을 위해 **적용 환율/원화 환산 결과를 고정 저장**한다:
  - 권장: `cost_fx_applications`(+ 필요 시 `fx_rates` 참조)

---

## (추가) Payable/Invoice 기반 지급 운영 (촘촘 시나리오)

이 섹션은 “지급수단(카드/계좌이체/현금) + 비용발생원(PO/비PO/Invoice)”을 한 프레임으로 정리한다.
(v7.9.x 운영 가이드에서 축적된 실무 흐름을 **현재 정본(v7.9.7) 스키마**에 맞게 재작성하여 병합)

### 0) 테이블 역할 빠른 맵(운영 관점)

- **PO(발주)**: `purchase_orders`, `po_lines`, `po_allocations`
- **비용 원장(무조건)**: `costs`
- **비용 귀속(선택/권장)**: `cost_allocations` (프로젝트/주문/주문라인/override/수급케이스 등)
- **실지급(카드/이체/현금)**: `payments`
- **지급-비용 연결(필수)**: `payment_lines` (부분지급/일괄지급 지원)
- **외부 문서(청구/명세/세금계산 등)**: `invoices`, `invoice_lines` (있는 경우에만)
- **내부 지급 단위(승인/보류/분할지급)**: `payables` (필요한 경우에만)
- **Payable 연결(필요 시)**:
  - `payable_invoice_allocations` (payable ↔ invoice / invoice_lines)
  - `payable_cost_allocations` (payable ↔ costs)
  - `payment_payable_allocations` (payment ↔ payable)

#### 문서/증빙(정본)
- 모든 문서/증빙/첨부는 `documents`에 저장한다.
- 문서가 무엇의 근거인지(비용/지급/Invoice/배송/작업 등)는 `document_links`로 연결한다.
- 운영에서 흔히 쓰는 분류:
  - **거래/원가 증빙**: `documents.doc_category = 'COST'` (예: 세금계산서, 거래명세서, 납품서, 운송장, 플랫폼 정산서 등)
  - **지급/현금흐름 증빙**: `documents.doc_category = 'PAYMENT'` (예: 카드승인, 이체확인, 환불전표, 카드사 청구서 등)
- “발주서(PO 문서)”는 비용/지급 증빙이라기보다 **업무 문서**이므로,
  필요하면 `documents.doc_category='WORK'`(예시)로 분리하고 `document_links(target_type='purchase_orders', target_sn=po_sn)`로 연결한다.

### 1) 시나리오 A — 온라인 발주(PO) + 즉시 카드결제(재무 이체 요청 없음)

**상황**
- 발주서(PO)대로 구매 진행
- 결제는 즉시 카드 승인
- 재무 담당자에게 이체 요청 불필요

**입력 흐름(권장)**
1) `purchase_orders` / `po_lines` 생성(필요 시 내부 승인 후 발행)
2) `costs` 생성(원가/채무 인식)
   - 필요하면 `cost_allocations`로 주문항목(`ol_sn`) 또는 수급케이스(`sc_sn`)에 귀속
3) `payments` 생성 (`pay_method='CARD'`, `pay_status='PAID'`)
4) `payment_lines`로 payments ↔ costs 연결
5) 문서 허브에 증빙 저장 + 연결
   - 카드 승인내역/취소전표 등(지급 증빙): `documents(doc_category='PAYMENT')` → `document_links(target_type='payments', target_sn=pay_sn)`
   - 구매명세/거래내용 증빙(셀러별 N장 가능): `documents(doc_category='COST')` → `document_links(target_type='costs', target_sn=ct_sn)`
   - 현금영수증이 발급되면(거래 증빙 성격): 보통 `doc_category='COST'`로 둔다.

### 2) 시나리오 B — PO 발주 + 계좌이체 필요(재무 승인/집행)

**상황**
- 발주서는 존재
- 지급은 계좌이체로 진행
- 내부 승인/지급요청 단계가 필요

**입력 흐름(권장)**
1) `purchase_orders` / `po_lines` 생성(필요 시 내부 승인)
2) (선택) 외부 청구/명세가 있으면 `invoices` / `invoice_lines` 생성
   - GOODS 라인은 가능하면 `po_sn`/`pol_sn`에 연결
   - 부대비용은 `invoice_lines(line_type='CHARGE')`로 분리
3) `costs` 생성(원가/채무 인식) + 필요 시 `po_cost_links`
4) `payables` 생성(지급요청/승인 단위)
   - `payable_status`로 CREATED → APPROVED → PARTIALLY_PAID/PAID 등 운용
5) (선택) `payable_invoice_allocations`로 payable ↔ invoice 연결(문서 기반 지급요청이면 권장)
6) `payable_cost_allocations`로 payable ↔ costs 연결(원가 관점의 정산 기준)
7) 실제 이체 실행 후 `payments` 생성 (`pay_method='TRANSFER'`)
8) `payment_payable_allocations`로 payment ↔ payable 연결(부분지급/복수 payable 지원)
9) `payment_lines`로 payment ↔ costs 연결(실제 돈 흐름의 최종 귀결)
10) 문서 허브에 증빙 저장 + 연결
    - 이체확인(지급): `documents(doc_category='PAYMENT')` → `document_links(payments)`
    - 청구서/세금계산/거래명세(거래): `documents(doc_category='COST')` → `document_links(invoices)` 또는 `document_links(costs)`

### 3) 시나리오 C — 비PO 비용(배송료/운송료/미팅/주유/검수 등) + 선택적 귀속

**상황**
- 발주서 없이 발생하는 비용
- 비용 내역을 `costs`에 기록
- 주문항목에 기인한 비용이면 선택적으로 귀속

**입력 흐름**
1) `costs` 직접 생성(비PO 비용)
2) (선택) `cost_allocations`로 `ol_sn` 또는 `sc_sn` 등에 귀속
3) 지급 수단에 따라 `payments` 생성(CARD/TRANSFER/CASH)
   - 승인/보류/분할지급이 필요하면 `payables`를 끼운다.
4) `payment_lines`로 payments ↔ costs 연결
5) 문서 허브에 증빙 저장 + 연결
   - 영수증/현금영수증/거래증빙: `doc_category='COST'` → `document_links(costs)`
   - 지급증빙(카드승인/이체확인): `doc_category='PAYMENT'` → `document_links(payments)`

### 4) 시나리오 D — Invoice 1건이 여러 PO 묶음 + PO 외 부대비용 포함

**상황**
- 업체가 지급요청서/거래명세서 형태로 송부
- 여러 PO를 묶어 청구
- 탁송료/부대비 등 PO에 없는 비용 라인이 포함될 수 있음

**입력 흐름(권장)**
1) `invoices` 생성(외부 문서 컨테이너)
2) `invoice_lines` 생성
   - GOODS 라인: `po_sn`/`pol_sn`에 다중 연결 가능
   - CHARGE 라인: 별도 라인으로 추가(예: 운송/탁송/검수)
3) (권장) CHARGE를 `costs`로도 남겨 원가 귀속을 확보
   - 만들었다면 `invoice_lines.ct_sn` 같은 연결(설계 선택)을 사용
4) 이 문서를 근거로 이체를 해야 하면 `payables` 생성 + `payable_invoice_allocations`
5) 실제 원가를 `costs`로 정리하고 `cost_allocations`로 귀속
6) `payable_cost_allocations`로 payable ↔ costs 연결
7) 실제 이체 후 `payments` + `payment_payable_allocations` + (필요 시) `payment_lines`
8) 문서 허브 연결
   - invoice/세금계산서/명세서: `doc_category='COST'` → `document_links(invoices)`
   - 이체확인: `doc_category='PAYMENT'` → `document_links(payments)`

### 5) 시나리오 E — 1 cost를 여러 번 분할 지급(선금/중도금/잔금)

**상황**
- 총 비용(cost) 1건
- 지급(payment) 여러 번

**입력 흐름**
1) `costs` 1건 생성(총액)
2) `payments` 1건 생성(선금) + `payment_lines`로 cost에 일부 연결
3) `payments` 1건 생성(중도금) + `payment_lines`로 cost에 일부 연결
4) `payments` 1건 생성(잔금) + `payment_lines`로 cost에 잔액 연결
5) 각 `payments`마다 지급 증빙 문서를 `documents(doc_category='PAYMENT')`로 저장 후 `document_links(payments)`로 연결

### 6) 운영 체크리스트(팀 공통)

- 비용이 발생했는가? → **`costs`**
- 돈이 실제로 나갔는가? → **`payments`**
- 승인/이체 프로세스가 필요한가? → **`payables`**
- 문서의 핵심이 거래 내용(무엇을/왜 샀나)인가? → `documents.doc_category='COST'` + `document_links(costs/invoices/shipments/...)`
- 문서의 핵심이 지급 사실(돈이 나갔나)인가? → `documents.doc_category='PAYMENT'` + `document_links(payments)`

### 7) 운영 규칙/제약(스키마로 100% 강제하지 않는 부분)

- “PO 기반 지급은 카드/이체만 가능” 같은 규칙은 DB 제약보다는 **애플리케이션 검증 규칙**으로 강제하는 것을 권장한다.
  (현장에서 예외 케이스가 발생할 수 있어 DB에서 완전히 막으면 운영이 더 어려워질 수 있음)
- “발주 승인(상위 매니저 검토)”은 별도 요청 테이블 없이도 운용 가능하다.
  - 최소 운용: `po_status` 전환(예: DRAFT → SENT) + 감사 로그(`audit_changes`) 기록
  - 승인자/승인일시를 강하게 남겨야 한다면: `purchase_orders`에 승인자/승인일시 컬럼을 추가하는 방식이 가장 단순하다.

---

## (추가 병합) 운영 코드북 — v7.8.0에서 유효 내용 보강 (정본 v7.9.7)

아래 코드/상태/종류 값 가이드는 `Balhea_Operations_Guide_FINAL_v7.8.0.md`의 “코드북” 섹션에서
**현재 정본(v7.9.7)에도 유효한 부분만**을 선별해, deprecated 표현을 정본 구조로 **재작성(Rewrite)** 한 뒤 병합한 것이다.

- 정본(소스 오브 트루스)은 `schema-policy-and-naming`의 코드북이며,
  이 섹션은 **운영 입력(드롭다운/검증 규칙)** 관점으로 빠르게 참고하기 위한 용도다.

## 10. 코드/상태/종류 컬럼 “값 가이드(코드북)” (중요)

이 섹션은 `*_sn` 같은 FK 숫자값/국가코드처럼 “자명한 값”이 아니라,
`trade_terms`, `delivery_method`처럼 **코드/상태/종류**로 보이는 컬럼에 대해
**실제 운영 시나리오에서 어떤 값을 넣어야 하는지**를 표준화한다.

> 원칙: **코드값은 가능한 한 “열거형(enum)처럼 고정”**한다.  
> UI/백엔드에서 드롭다운으로 관리하고, 텍스트 임의 입력을 금지한다.

### 10.1 trade_terms (인도조건 / Incoterms)
**추천 값 집합(Incoterms 2020 기반, 대문자 고정):**
- `EXW` : 공장인도 (판매처/공장 인도, 구매자가 거의 전부 부담)
- `FCA` : 운송인 인도
- `FOB` : 본선인도 (해상)
- `CFR` : 운임포함 인도 (해상)
- `CIF` : 운임+보험료 포함 (해상)
- `CPT` : 운송비지급 인도
- `CIP` : 운송비+보험료지급 인도
- `DAP` : 도착지 인도(하역 제외)
- `DPU` : 도착지 인도(하역 포함)  *(구 DAT 대체)*
- `DDP` : 관세지급 인도(판매자가 관세/세금까지 부담)

**운영 입력 규칙(핵심):**
- 국내 구매: 보통 Incoterms를 쓰지 않으므로 **NULL 허용**(권장)  
  - 단, 국내에서도 계약서가 “인도조건”을 명시한다면 `DAP`(납품처 인도에 준함) 정도로 내부 표준화 가능
- 해외 구매: 가급적 **필수 입력**(권장)
  - 포워더/통관/관세 책임을 누가 지는지 판단 근거가 됨

**시나리오별 권장 매핑:**
- 해외 판매처 → 한국 창고까지 판매처 책임(문전 인도) + 관세는 구매자: `DAP`
- 해외 판매처가 관세/세금까지 모두 처리: `DDP`
- 해상 운송 + 보험 포함 조건: `CIF`
- 구매자가 모든 운송을 잡고 판매처에서 픽업: `EXW` 또는 `FCA`

**주의(데이터 품질):**
- `trade_terms`는 “가격조건”이 아니라 **책임경계선**이다.  
- 운송/통관 비용 귀속(costs/allocations) 정책과 **반드시 함께** 맞춰야 한다.

---

### 10.2 delivery_method (발주 이후 물류 흐름의 방식)
너희 운영 케이스(국내/해외 공통) 3가지를 “코드값”으로 표준화한다.

**추천 코드값(대문자, snake 없이 단어 2~3개):**
1) 물류팀이 판매처 방문 수거
- `PICKUP_BY_LOGISTICS`  
  - 물류팀 담당자가 직접 판매처 방문 수거
  - 이후 경로는 logistics_job / stops로 표현 (직납/창고입고)

2) 판매처가 회사로 배송
- `SELLER_SHIP_TO_COMPANY`  
  - 온라인몰/택배로 사무실 또는 회사 지정 주소로 도착
  - “사무실 → 창고” 이동은 별도 `logistics_job(TRANSFER)`로 기록

3) 판매처가 납품처로 직송
- `SELLER_SHIP_TO_CUSTOMER`  
  - 회사가 실물을 통제하지 않으므로 inventory_unit 생략 가능
  - 단, 납품 증빙(송장/인수증)과 납품 완료 이력은 job/milestone로 남김(권장)

**추가로 해외에서 자주 필요한 값(선택 확장):**
- `FORWARDER_MANAGED` : 포워더 주도(해상/항공/내륙 연계)로 이동하는 케이스(보통 shipment가 주축)
- `COURIER` : 국제 특송(UPS/DHL/FedEx) 중심
- `FREIGHT_TRUCK` : 국내 화물/용달 중심

**입력 규칙:**
- `delivery_method`는 “PO 이후의 1차 방식”을 의미한다.  
  실제 세부 흐름은 `shipments` 또는 `logistics_jobs`가 책임진다.
- 하나의 PO가 분할되어 여러 방식이 섞이면:
  - **PO 단위로 하나를 강제하지 말고**, shipment/job 단위로 기록한다.
  - (가능하면) PO에는 “대표값”으로만 두고, 실 흐름은 shipment/job의 method로 둔다.

---

### 10.3 procurement_mode (국내/해외/자체제작 등)
- `DOMESTIC`
- `OVERSEAS`
- `IN_HOUSE` (자체제작)
- (필요 시) `SERVICE` (용역성 구매)

**입력 규칙:**
- PO 생성 시 가능한 입력(권장). 이후 물류/환율 정책의 기본값에 영향.

---

### 10.4 fx_rate_policy (환율 적용 기준 “정책”)
이 값은 “자동 환율 계산”이 아니라, **팀이 어떤 기준을 쓰겠다는 메모/정책**이다.
실제 환율 숫자는 costs에 고정 저장한다.

**추천 값:**
- `QUOTE_DATE` : 견적일 기준 환율
- `PO_DATE` : 발주일 기준 환율
- `PAYMENT_DATE` : 지급일 기준 환율(회계/정산 관점)
- `CUSTOMS_DATE` : 통관일 기준 환율(관세/부가세 관점)
- `MANUAL` : 수동 입력(특수 케이스)

**운영 권장:**
- 원가/관리 목적이면 `PO_DATE` 또는 `CUSTOMS_DATE`가 현실적
- 회계/정산 일치가 중요하면 `PAYMENT_DATE`

---

### 10.5 logistics_jobs.job_type (작업 종류)
**추천 값:**
- `PICKUP` : 판매처 수거
- `TRANSFER` : 사무실↔창고, 창고↔창고 이동
- `DELIVERY` : 납품처 배송
- `MIXED` : 수거+납품 같이 수행(한 번에 끝)

---

### 10.6 logistics_job_stops.stop_type (정차 지점 종류)
- `VENDOR`
- `OFFICE`
- `WAREHOUSE`
- `CUSTOMER`
- (해외 확장) `PORT`, `AIRPORT`, `CUSTOMS`, `FORWARDER_HUB`

---

### 10.7 shipment_milestones.milestone_type (운송 이벤트)
**기본 값(국내/해외 공통):**
- `CREATED`
- `PICKED_UP`
- `IN_TRANSIT`
- `ARRIVED`
- `WAREHOUSE_IN`
- `DELIVERED`

**해외 확장(필요 시):**
- `DEPARTURE`
- `ARRIVAL_PORT`
- `CUSTOMS_CLEARANCE_START`
- `CUSTOMS_CLEARANCE_DONE`
- `INSPECTION`
- `DOMESTIC_DELIVERY`

---

### 10.8 inventory_units.status (바코드 실물 상태)
- `IN_TRANSIT`
- `IN_OFFICE`
- `IN_WAREHOUSE`
- `RESERVED_FOR_DELIVERY`
- `DELIVERED`
- `DAMAGED`
- `LOST`

**권장 상태 전이:**
IN_OFFICE → IN_WAREHOUSE → RESERVED_FOR_DELIVERY → DELIVERED

---

### 10.9 delivery_requests.status / proposals
**delivery_requests.status 추천:**
- `SUBMITTED`
- `COUNTERED`
- `ACCEPTED`
- `REJECTED`
- `CONFIRMED`
- `CANCELED`

**delivery_request_proposals.proposal_type 추천:**
- `INITIAL`
- `COUNTER`
- `ACCEPT`
- `REJECT`

---

## 11. 시나리오별 “어떤 코드값을 넣는지” 빠른 표

### 11.1 물류팀이 판매처 방문 수거 후 직납
- delivery_method: `PICKUP_BY_LOGISTICS`
- trade_terms: 국내면 NULL(또는 내부 표준 `DAP`), 해외면 실제 계약 Incoterms
- logistics_job: `MIXED`
- stops: `VENDOR → CUSTOMER`
- inventory_units: 현장 바코드 발급(권장) 또는 생략(정책 선택)

### 11.2 온라인몰 배송 → 사무실 도착 → 창고 이동
- delivery_method: `SELLER_SHIP_TO_COMPANY`
- logistics_job: `TRANSFER` (OFFICE → WAREHOUSE)
- inventory_units: 사무실 도착 시점에 필수 생성 + barcode

### 11.3 판매처 직송(회사 미경유)
- delivery_method: `SELLER_SHIP_TO_CUSTOMER`
- inventory_units: 보통 생략
- 납품 이력: logistics_job(DELIVERY, assignee=vendor or internal) 또는 shipment_milestones로 증빙

---

## (추가) 재무 불변식 요약 (Invoice/Payable/Payment) — v7.8.2 → v7.9.7 정본

운영에서 혼동이 잦은 3가지를 **정본 불변식**으로 고정한다.

1) **Invoice는 지급 단위가 아니다.**  
   - invoice는 외부 문서 컨테이너이며, 지급은 payable 단위로 이루어진다.

2) **Payable이 지급 단위(재무 업무 단위)이다.**  
   - 승인/보류/기한/부분지급/마감 등의 업무 상태는 payables에서만 관리한다.

3) **Payment는 실제 돈이 나간 결과이다.**  
   - payment는 “지급 사실”만 기록하며, 무엇을 얼마나 정산했는지는 `payment_lines`(cost 기준)로 정리한다.
   - payment ↔ payable은 `payment_payable_allocations`로 연결한다(분할/묶음 지급 지원).

추가로, 운영 정책:
- **PO 1건 = cost 1건**을 기본으로 유지한다(`po_cost_links` 1:1 권장).  
  멀티셀러/사업자 분리가 필요하면 PO를 분할하고, 분할이 불필요하면 PO=cost로 묶는다.

문서/증빙:
- 모든 증빙은 `documents`에 저장하고, 연결은 `document_links`로 한다.
- invoice/payable 관련 코드값(예: `invoice_status`, `invoice_type`, `charge_category`, `priority_level`)은
  `schema-policy-and-naming`의 코드북을 정본으로 따른다.
