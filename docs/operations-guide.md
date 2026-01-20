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
