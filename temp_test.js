
var Vue = {
    createApp: function() {
        return {
            mount: function() {}
        };
    }
};
var localStorage = {
    getItem: function() { return '[]'; },
    setItem: function() {}
};
var window = {
    innerWidth: 1024,
    open: function() {}
};

            const { createApp } = Vue;

            createApp({
                data() {
                    return {
                        userRole: 'PURCHASE', // PURCHASE | CEO
                        showAuditLog: false,
                        auditLogFilter: 'all', // 'all' | 'mine'
                        isFinanceDirectModalOpen: false,
                        financeDirectForm: {
                            expenseType: '소액경비',
                            vendorName: '',
                            amount: 0,
                            date: new Date().toISOString().split('T')[0],
                            payMethod: '법인카드',
                            linkedProject: '',
                            note: ''
                        },
                        auditLogs: [
                            // ── 핵심 케이스: PO-20260405-0002 한 건의 전체 생애주기 ──
                            // 비용등록 → 기안 → 반려 → 재기안 → 승인 → 지급완료
                            // 이 흐름이 처리이력 조회의 존재 이유를 설명함
                            {
                                id: 1, time: '2026-04-05 09:00',
                                actor: '중간관리자',
                                action: '비용 등록',
                                action_code: 'COST_CREATED',
                                ref: 'PO-20260405-0002',
                                status: '비용등록',
                                amount: 12500000,
                                note: 'PO 수락 후 비용 원장 생성 (ct_type=PO, ct_kind=PO_COST)',
                                mine: true,
                            },
                            {
                                id: 2, time: '2026-04-05 09:30',
                                actor: '중간관리자',
                                action: '지급요청 기안',
                                action_code: 'PAYABLE_CREATED',
                                ref: 'PO-20260405-0002',
                                status: '지급요청중',
                                amount: 12500000,
                                note: '잔금 전액 — 계좌이체 기안',
                                mine: true,
                            },
                            // ── 다른 건들 (섞여 보이는 실제 업무 맥락) ──
                            {
                                id: 7, time: '2026-04-15 09:00',
                                actor: '팀원1',
                                action: '비용 등록',
                                action_code: 'COST_CREATED',
                                ref: 'PC-20260419-0007',
                                status: '비용등록',
                                amount: 2200000,
                                note: '안전 진단 용역 부대비용 등록',
                                mine: false,
                            },
                            {
                                id: 8, time: '2026-04-19 14:20',
                                actor: '팀원1',
                                action: '지급요청 기안',
                                action_code: 'PAYABLE_CREATED',
                                ref: 'PC-20260419-0007',
                                status: '지급요청중',
                                amount: 2200000,
                                note: '계좌이체 승인요청',
                                mine: false,
                            },
                            {
                                id: 9, time: '2026-04-20 11:00',
                                actor: '중간관리자',
                                action: '환불 확인 요청',
                                action_code: 'PAYABLE_CREATED',
                                ref: 'RF-20260421-0009',
                                status: '지급요청중',
                                amount: -2750000,
                                note: '자재 반품 — 계좌이체 환불 확인 요청 (ct_status=REFUND)',
                                mine: true,
                            },
                            {
                                id: 10, time: '2026-04-22 17:30',
                                actor: '중간관리자',
                                action: '현금 지출 보고 완료',
                                action_code: 'COST_CASH_REPORTED',
                                ref: 'CASH-20260422-0001',
                                status: '비용등록',
                                amount: 87000,
                                note: '영수증 첨부 완료 · payable/payment 없음',
                                mine: true,
                            },
                            // 나머지 건 이력
                            { id: 11, time: '2026-04-01 10:00', actor: '중간관리자', action: '비용 등록', action_code: 'COST_CREATED', ref: 'PO-20260401-0001', status: '비용등록', amount: 8706500, note: 'PO 수락 후 비용 원장 생성', mine: true },
                            { id: 12, time: '2026-04-10 09:00', actor: '중간관리자', action: '비용 등록', action_code: 'COST_CREATED', ref: 'PO-20260410-0003', status: '비용등록', amount: 20752996, note: 'PO 수락 후 비용 원장 생성', mine: true },
                            { id: 13, time: '2026-04-10 09:30', actor: '중간관리자', action: '지급요청 기안', action_code: 'PAYABLE_CREATED', ref: 'PO-20260410-0003', status: '지급요청중', amount: 20752996, note: '기성금 계좌이체 기안', mine: true },
                            { id: 14, time: '2026-04-10 14:00', actor: '대표이사', action: '지급 승인', action_code: 'PAYABLE_APPROVED', ref: 'PO-20260410-0003', status: '지급대기', amount: 20752996, note: null, mine: true },
                            { id: 15, time: '2026-04-12 09:00', actor: '중간관리자', action: '비용 등록', action_code: 'COST_CREATED', ref: 'PO-20260412-0004', status: '비용등록', amount: 5225000, note: 'PO 수락 후 비용 원장 생성', mine: true },
                            { id: 16, time: '2026-04-12 09:20', actor: '중간관리자', action: '지급요청 기안', action_code: 'PAYABLE_CREATED', ref: 'PO-20260412-0004', status: '지급요청중', amount: 5225000, note: '자재대금 계좌이체 기안', mine: true },
                            { id: 17, time: '2026-04-13 10:00', actor: '대표이사', action: '승인 반려', action_code: 'PAYABLE_REJECTED', ref: 'PO-20260412-0004', status: '승인반려', amount: 5225000, note: '세금계산서 발행 내역 미확인. 확인 후 재기안 바랍니다.', mine: true },
                            { id: 18, time: '2026-04-15 09:00', actor: '중간관리자', action: '비용 등록', action_code: 'COST_CREATED', ref: 'PO-20260415-0005', status: '비용등록', amount: 18260000, note: 'PO 수락 후 비용 원장 생성', mine: true },
                            { id: 19, time: '2026-04-15 09:30', actor: '중간관리자', action: '지급요청 기안', action_code: 'PAYABLE_CREATED', ref: 'PO-20260415-0005', status: '지급요청중', amount: 18260000, note: '전액기성 계좌이체 기안', mine: true },
                            { id: 20, time: '2026-04-15 11:00', actor: '대표이사', action: '지급 승인', action_code: 'PAYABLE_APPROVED', ref: 'PO-20260415-0005', status: '지급대기', amount: 18260000, note: null, mine: true },
                            { id: 21, time: '2026-04-16 15:00', actor: '재무관리자', action: '이체 처리 완료', action_code: 'PAYMENT_PROCESSED', ref: 'PO-20260415-0005', status: '지급완료', amount: 18260000, note: '국민은행 이체 완료 · TX#38291', mine: true },
                            { id: 22, time: '2026-04-18 10:00', actor: '팀원1', action: '비용 등록', action_code: 'COST_CREATED', ref: 'SH-20260418-0006', status: '비용등록', amount: 385000, note: '카드 즉시결제 — payable 없음', mine: false },
                            { id: 23, time: '2026-04-20 09:00', actor: '팀원1', action: '비용 등록', action_code: 'COST_CREATED', ref: 'PC-20260420-0008', status: '비용등록', amount: 880000, note: '시험 성적서 발급 부대비용', mine: false },
                            { id: 24, time: '2026-04-20 09:20', actor: '팀원1', action: '지급요청 기안', action_code: 'PAYABLE_CREATED', ref: 'PC-20260420-0008', status: '지급요청중', amount: 880000, note: '시험비 계좌이체 기안', mine: false },
                            { id: 25, time: '2026-04-20 13:00', actor: '대표이사', action: '지급 승인', action_code: 'PAYABLE_APPROVED', ref: 'PC-20260420-0008', status: '지급대기', amount: 880000, note: null, mine: false },
                            { id: 26, time: '2026-04-21 09:00', actor: '중간관리자', action: '환불 비용 등록', action_code: 'COST_CREATED', ref: 'RF-20260421-0009', status: '환불처리', amount: -2750000, note: '자재 반품 — negative cost 생성 (ct_status=REFUND)', mine: true },
                            { id: 27, time: '2026-04-23 09:00', actor: '팀원1', action: '비용 등록', action_code: 'COST_CREATED', ref: 'CASH-20260423-0002', status: '비용등록', amount: 43000, note: '현금 지출 — 영수증 미첨부', mine: false },
                        ], filterStatus: 'ALL',
                        filterUser: '중간관리자',
                        filterDateRange: 'custom',
                        startDate: '',
                        endDate: '',
                        searchText: '',
                        ceoComment: '',
                        teamMembers: [
                            { name: '중간관리자', role: '본인' },
                            { name: '팀원1', role: '팀원' },
                            { name: '팀원2', role: '팀원' }
                        ],
                        isDetailPinned: false,
                        selectedItem: null,
                        itemTaxMode: 'separate',
                        nextInstId: 1000,

                        /* Registration Modal States */
                        isAddModalOpen: false,
                        availableProjects: [
                            { id: 'P2026-005', name: '부산항 3공구' },
                            { id: 'P2026-006', name: '울산 해양플랜트' },
                            { id: 'P2026-007', name: '대구-북구C' }
                        ],
                        selectedProjects: ['P2026-005'],
                        newIncidentalCosts: [],
                        availableExpenseTypes: ['물류/운송비', '하역/장비비', '가공/제조/외주비', '인건비/용역비', '시험/품질/인증비', '통관/세금/금융비', '현장/공사/설치비', '일반경비/운영비', '추가 납품 (계약외)'],
                        availableSourcingMethods: ['국내구매', '해외구매', '자체제작'],
                        availableTaxApps: [
                            { label: '부가세 별도', value: 'separate' },
                            { label: '부가세 포함', value: 'inclusive' },
                            { label: '부가세 면세', value: 'exempt' },
                            { label: '부가세 영세', value: 'zero' }
                        ],
                        availablePayMethods: ['계좌이체', '카드', '현금'],
                        availableCostItems: ['현장 식대', '현장 숙박비', '현장 소모품', '현장 사무실 운영비', '정기 안전 진단 용역', '품질 시험 성적서 발급', '기타 프로젝트 간접비'],
                        availableMaterials: ['외벽 도료 EP-300', 'SUS 배관 자재', 'PHC 말뚝', '엔진오일 SET', '아스콘 자재', 'H-Beam 300x300', '강판 12T'],

                        /* Allocation Modal States */
                        isAllocationModalOpen: false,
                        allocationSearchKeyword: '',
                        allocationProjectB: { id: '', name: '배분 대상 프로젝트' },
                        allocationData: {
                            originSn: '',
                            vendor: '',
                            projectA: { id: 'P2025-A', name: '프로젝트 A' },
                            specialCosts: [],
                            negoCosts: []
                        },

                        /* Dev Guide States */
                        devGuideMode: false,
                        showPdfModal: false,
                        pdfTitle: '',
                        pdfUrl: '/Users/chloe/.gemini/antigravity/brain/78ef08fd-3ddd-4f85-8d53-3ba3c0c2d5ff/po_pdf_mockup_1776948910920.png',
                        memoVisible: false,
                        activeMemoKey: '',
                        memoPos: { x: 0, y: 0 },
                        memoDictionary: {
                            'page_title': '[화면 개요]\n- 통합 비용 관리 (All Costs): 모든 구매 발주 및 부대비용의 지급 요청과 승인을 관리하는 화면.\n- 기능: 결재 상신, 실시간 잔액 계산, 다중 분할 지급 관리, CEO 승인/반려 워크플로우.',
                            'role_switcher': '[RBAC 권한 제어]\n- 구매담당자: 본인이 등록한 건만 조회 및 기안 가능.\n- 중간관리자: 팀 전체 건 조회 가능 및 기안. 담당자별 필터 사용 가능.\n- 대표이사(CEO): 전사 승인요청 대기 건 통합 조회 및 승인(APPROVED)/반려(REJECTED) 수행.',
                            'team_filter': '[데이터 필터링 - 담당자]\n- CEO: 전체 담당자의 상신 건 노출.\n- 중간관리자: 소속 팀 전체의 데이터 조회 가능.\n- 구매담당자: 본인 데이터만 노출 (필터 버튼 비활성화).',
                            'filter_date': '[기간 조회]\n- 1/3/6개월 프리셋 제공.\n- 직접 입력 시 시작일이 종료일보다 클 수 없으며, 성능상 1년 이상의 조회는 제한함.',
                            'filter_status': '[진행상태 필터 — DDL 정본 기준]\n- 비용등록: costs만 존재 (ct_status=CREATE)\n- 지급요청중: payables.pbl_status=CREATED\n- 지급대기: payables.pbl_status=APPROVED (또는 ON_HOLD)\n- 승인반려: payables.pbl_status=REJECTED\n- 지급완료: payments.pay_status=PROCESSED\n- 환불처리: costs.ct_status=REFUND',
                            'grid_main': '[메인 데이터 그리드]\n- NO: 정렬 순서.\n- 종류: 발주비용(PO), 부대비용(Incidental), 직접비용(Direct), 환불(Refund) 구분.\n- 차기 지급요청일: installments 배열 중 상태가 [기안대기]인 첫 번째 행의 날짜를 매핑.',
                            'grid_amount': '[결제 금액]\n- 소수점 없는 정수형 원화 기준.\n- 환불 건은 붉은색 마이너스(-)로 표시하여 가독성 강화.',
                            'drawer_header': '[상세 패널 기능]\n- 패널 고정: 레이아웃을 50:50으로 유지하여 List-Detail을 동시 확인.\n- Sn 클릭 시 해당 원천 문서(발주서 등)로의 딥링크 제공 계획.',
                            'ceo_opinion_area': '[결재 의견 영역]\n- 상태가 [승인완료] 또는 [승인반려]일 때 가시화.\n- CEO가 입력한 실시간 코멘트를 표시하여 실무자에게 정확한 피드백 전달 (반려 사유 확인 등).',
                            'item_detail_section': '[항목 상세 내역]\n- 워크스페이스 에서 넘어온 원천 품목 데이터(Read-Only).\n- 부대비용(배송/설치 등) 모드일 경우 별도의 부가세 포함/별도 계산 테이블로 스위칭.',
                            'project_info_btn': '[프로젝트 심화 정보]\n- 클릭 시 project_info.html 팝업 호출.\n- 해당 프로젝트의 전체 손익 및 현장 사진, 좌표 등 기술 정보 확인.',
                            'refund_section': '[환불 특화 로직]\n- amount가 음수인 항목 전용.\n- 원본 cost를 덮어쓰지 않고 ct_parent_ct_sn으로 연결된 자식 REFUND cost를 취급 (DDL 원칙).',
                            'special_cost_table': '[특수 비용 집계]\n- 원가에 산입되지 않는 일회성 비용(통관료, 특수운송 등) 관리.\n- 과세 적용 여부에 따라 부가세(VAT) 실시간 10% 계산 루틴 포함.',
                            'grand_total_panel': '[최종 합계 계산식]\n- (품목 소계 + 특수비용 소계 - 할인액 - 환불액) = 세전 합계.\n- 세전 합계 * 0.1 = 부가세.\n- [미정산 배분]: 안분/귀속의 정본인 cost_allocations (ADR-009)를 통해 프로젝트별 정산 배분 수행.',
                            'installment_logic': '[분할 지급 관리 (ADR-002 기반)]\n- 계약금/중도금/잔금 다중 분할 지원.\n- cost 1건은 여러 payables로 나뉠 수 있음 (DDL 지원).\n- 추가 행(회차) 생성 조건: 이전 회차가 승인(APPROVED) 또는 지급완료(PROCESSED) 상태여야만 가능하도록 제한.\n- 특정 행들의 합계만 하단에 [지급 요청 금액]으로 합산되어 기안됨.',
                            'action_panel_logic': '[지급 요청 실행]\n- [승인 요청 기안하기]: 선택된 installment 행들의 상태를 [승인요청중]으로 변경 (payables.pbl_status=CREATED 생성).\n- [내용 확인 완료]: 카드결제 등 payable이 불필요한 직행 건의 사후 확인.',
                            'ceo_approval_btns': '[CEO 결재 처리]\n- [반려]: 의견 필수 입력, 상태를 [승인반려](REJECTED)로 회귀.\n- [최종 승인]: 상태를 [승인완료](APPROVED)로 변경, 재무 담당자가 처리할 수 있도록 이관.',
                            'row_type_PO': '[종류: 프로젝트 발주비용]\n- 항목: 자재, 장비 등 원천 발주서 기반 데이터.\n- 특징: PO 1건 = cost 1건 (ADR-012 불변식). 분할 지급(계약/중도/잔금) 가능.\n- 상세: 프로젝트 정보와 실시간 연동되어 손익 관리의 핵심 데이터가 됨.',
                            'row_type_PROJECT': '[종류: 프로젝트 부대비용]\n- 항목: 현장 식대, 숙박비, 사무실 운영비 등 프로젝트 수행에 수반되는 간접 비용.\n- 특징: 발주서 기반이 아닌 법인카드 결제 또는 사후 정산 성격이 강함.\n- 상세: 별도의 품목 검수가 불필요하며, 지급 요청 시 관련 증빙(영수증) 첨부 여부 확인이 핵심.',
                            'row_type_ITEM_COST': '[종류: 품목별 직접비용]\n- 항목: 현장 긴급 자재 구매, 소모품 등 특정 품목에 귀속되는 비용.\n- 특징: PO 없이 구매하지만 실물 자재나 용역이 수반되는 건.\n- 상세: 직접 등록 시 [품목별 직접비용]으로 분류되어 관리됨.',
                            'row_type_REFUND_Card': '[종류: 카드 환불]\n- 로직: PG사 결제 취소.\n- 특징: payable 없이 payments(pay_tx_type=REFUND, pay_method=CARD)로 바로 기록 (ADR-002 및 DDL 기준).',
                            'row_type_REFUND_Transfer': '[종류: 계좌 환불]\n- 로직: 계좌이체 환불 확인 요청.\n- 특징: 재무 처리 요청을 거치므로 payables(pbl_request_type=REFUND) 생성 후 payments로 연결됨 (DDL 기준).',
                            'installment_draft_btn': '[기안 추가/제외]\n- 기능: 선택한 회차의 지급 금액을 이번 결재 상신 건에 포함하거나 제외합니다.\n- 로직: 클릭 시 하단 Action Panel의 "지급 요청 금액"이 실시간으로 합산/차감되어 최종 기안 금액이 결정됩니다 (Computed: detailReqAmount).',
                            'proof_registration_area': '[지급 증빙/정보 등록]\n- 문서/증빙은 documents + document_links 로 통합 연결 (ADR-003).\n- 계좌이체: 거래처 검색으로 은행/예금주/계좌번호 스냅샷 복사(DDL). 이 데이터는 payables에 저장되어 재무 모듈 이관됨.',
                            'partner_master_data': '[거래처 마스터 데이터]\n- bank_accounts 에 저장된 정보를 기반으로 계좌 정보를 조회.\n- 다중 계좌 지원: 한 업체가 여러 계좌를 가진 경우 선택 버튼을 노출하여 편의성 제공.\n- 데이터 브릿징: 등록된 스냅샷 정보는 payables에 담겨 자동 전송됨.',
                            'grid_incidental_guide': '[기획 확인 대상]\n- 해당 항목은 부대비용/직접비용/환불건으로, 상세 보기에서 "지급수단 및 증빙 정보" 등록 가이드를 확인할 수 있습니다.',
                            'cash_payment_guide': '[현금 결제 처리 — DDL 정본 기준]\n- costs에만 등록되며 payables/payments에 기록되지 않음 (DDL line 393 명시).\n- 현금 영수증은 documents + document_links로 costs에 연결.\n- CEO 승인 큐를 거치지 않고 시스템에서 직접 비용 등록으로만 처리.'
                        },

                        costs: [
                            // ── 정본 기준 목업: ct_type × AP 흐름 단계별 1건씩 ──
                            // [1] PO 비용 | ct_type=PO, ct_kind=PO_COST | 비용등록만 (payable 없음)
                            {
                                ct_sn: 7001, vendor_name: '(주)동화페인트',
                                amount: 8706500, date: '2026-04-01',
                                origin_type: 'PO', origin_sn: 'PO-20260401-0001',
                                ct_type: 'PO', ct_kind: 'PO_COST',
                                ct_status: 'CREATE', pbl_status: null, pay_status: null,
                                manager: '중간관리자', origin_type_display: '발주비용 (PO_COST)',
                            },
                            // [2] PO 비용 | ct_type=PO | 지급요청중 (pbl_status=CREATED)
                            {
                                ct_sn: 7002, vendor_name: '마이넌 배관시스템',
                                amount: 14078460, date: '2026-04-05',
                                origin_type: 'PO', origin_sn: 'PO-20260405-0002',
                                ct_type: 'PO', ct_kind: 'PO_COST',
                                ct_status: 'CREATE', pbl_status: 'CREATED', pay_status: null,
                                manager: '중간관리자', origin_type_display: '발주비용 (PO_COST)',
                            },
                            // [3] PO 비용 | ct_type=PO | 지급대기 (pbl_status=APPROVED, 이체 전)
                            {
                                ct_sn: 7003, vendor_name: '대성기초건설',
                                amount: 20752996, date: '2026-04-10',
                                origin_type: 'PO', origin_sn: 'PO-20260410-0003',
                                ct_type: 'PO', ct_kind: 'PO_COST',
                                ct_status: 'CREATE', pbl_status: 'APPROVED', pay_status: null,
                                manager: '중간관리자', origin_type_display: '발주비용 (PO_COST)',
                            },
                            // [4] PO 비용 | ct_type=PO | 승인반려 (pbl_status=REJECTED)
                            {
                                ct_sn: 7004, vendor_name: '현대모비스',
                                amount: 5225000, date: '2026-04-12',
                                origin_type: 'PO', origin_sn: 'PO-20260412-0004',
                                ct_type: 'PO', ct_kind: 'PO_COST',
                                ct_status: 'CREATE', pbl_status: 'REJECTED', pay_status: null,
                                manager: '중간관리자', origin_type_display: '발주비용 (PO_COST)',
                                pbl_approval_comment: '세금계산서 발행 내역이 일치하지 않습니다. 다시 확인 후 재기안하세요.',
                                ceo_comment: '세금계산서 발행 내역 미확인. 확인 후 재기안 바랍니다.',
                            },
                            // [5] PO 비용 | ct_type=PO | 지급완료 (pay_status=PROCESSED, 계좌이체)
                            {
                                ct_sn: 7005, vendor_name: '한길포장',
                                amount: 18260000, date: '2026-04-15',
                                origin_type: 'PO', origin_sn: 'PO-20260415-0005',
                                ct_type: 'PO', ct_kind: 'PO_COST',
                                ct_status: 'CREATE', pbl_status: 'PROCESSED', pay_status: 'PROCESSED',
                                pay_method: 'TRANSFER',
                                manager: '중간관리자', origin_type_display: '발주비용 (PO_COST)',
                                pbl_approval_comment: '포장재 단가 인상분 반영 확인됨. 승인.',
                            },
                            // [7] PROJECT 부대비용 | ct_type=PROJECT, ct_kind=SITE_WORK | 지급요청중
                            {
                                ct_sn: 7007, vendor_name: '글로벌안전공사',
                                amount: 2200000, date: '2026-04-19',
                                origin_type: 'PROJECT', origin_sn: 'PC-20260419-0007',
                                ct_type: 'PROJECT', ct_kind: 'SITE_WORK',
                                ct_status: 'CREATE', pbl_status: 'CREATED', pay_status: null,
                                manager: '팀원1', origin_type_display: '현장/공사비 (SITE_WORK)',
                            },
                            // [8] PROJECT 부대비용 | ct_type=PROJECT, ct_kind=QUALITY_TEST | 지급대기 (ON_HOLD)
                            {
                                ct_sn: 7008, vendor_name: '한국품질시험원',
                                amount: 880000, date: '2026-04-20',
                                origin_type: 'PROJECT', origin_sn: 'PC-20260420-0008',
                                ct_type: 'PROJECT', ct_kind: 'QUALITY_TEST',
                                ct_status: 'CREATE', pbl_status: 'ON_HOLD', pay_status: null,
                                manager: '팀원1', origin_type_display: '시험/품질비 (QUALITY_TEST)',
                            },
                            // [9] PO 환불 | ct_status=REFUND, ct_parent_ct_sn=7005 | 환불처리
                            {
                                ct_sn: 7009, vendor_name: '한길포장',
                                amount: -2750000, date: '2026-04-21',
                                origin_type: 'REFUND', origin_sn: 'RF-20260421-0009',
                                ct_type: 'PO', ct_kind: 'PO_COST',
                                ct_status: 'REFUND', ct_parent_ct_sn: 7005,
                                pbl_status: 'CREATED', pay_status: null,
                                manager: '중간관리자', origin_type_display: '발주비용 환불 (REFUND)',
                                is_refund: true, refund_reason: '납품 자재 일부 반품 — 계좌이체 환불 확인 요청',
                            },
                            // [10] 현금 결제 | ct_type=PROJECT | 보고완료 (증빙 첨부)
                            // DDL NOTE: pay_method=CASH → costs만 등록, payable/payment 없음
                            {
                                ct_sn: 7010, vendor_name: '현장 마트',
                                amount: 87000, date: '2026-04-22',
                                origin_type: 'ITEM_COST', origin_sn: 'CASH-20260422-0001',
                                ct_type: 'PROJECT', ct_kind: 'GENERAL_EXPENSE',
                                ct_status: 'CREATE', pbl_status: null, pay_status: null,
                                pay_method: 'CASH',
                                cash_reported: true,
                                cash_proof_filename: 'receipt_20260422_mart.jpg',
                                manager: '중간관리자', origin_type_display: '품목별 직접비용 (현금)',
                            },
                            // [11] 현금 결제 | ct_type=PROJECT | 미보고 (증빙 미첨부)
                            {
                                ct_sn: 7011, vendor_name: '현장 식당',
                                amount: 43000, date: '2026-04-23',
                                origin_type: 'PROJECT', origin_sn: 'CASH-20260423-0002',
                                ct_type: 'PROJECT', ct_kind: 'GENERAL_EXPENSE',
                                ct_status: 'CREATE', pbl_status: null, pay_status: null,
                                pay_method: 'CASH',
                                cash_reported: false,
                                cash_proof_filename: '',
                                manager: '팀원1', origin_type_display: '일반경비/운영비 (현금)',
                            },
                        ],

                        origin_meta: {
                            // PO 발주비용 케이스들
                            'PO-20260401-0001': {
                                po_name: '부산항 3공구 페인트 납품', delivery_place: '부산 3공구', contractor: '동화페인트', manager: '중간관리자',
                                items: [
                                    { project: '부산항 3공구', name: '외벽 도료 EP-300', model: 'EP-300', spec: '무광/20kg', maker: '동화페인트', unit: 'KG', qty: 500, price: 12000, tax_application: 'separate' },
                                    { project: '부산항 3공구', name: '하도 프라이머 P-100', model: 'P-100', spec: '유성/18L', maker: '동화페인트', unit: 'CAN', qty: 20, price: 45000, tax_application: 'separate' },
                                    { project: '부산항 3공구', name: '전용 신너 T-500', model: 'T-500', spec: '20L', maker: '동화페인트', unit: 'CAN', qty: 10, price: 35000, tax_application: 'separate' },
                                    { project: '부산항 3공구', name: '수성 롤러 9인치', model: 'R-9', spec: '9 inch', maker: '삼화툴스', unit: 'EA', qty: 50, price: 3500, tax_application: 'separate' },
                                    { project: '부산항 3공구', name: '페인트 붓 3인치', model: 'B-3', spec: '3 inch', maker: '삼화툴스', unit: 'EA', qty: 100, price: 1500, tax_application: 'separate' },
                                    { project: '부산항 3공구', name: '마스킹 테이프', model: 'MT-50', spec: '50mm*40m', maker: '3M', unit: 'ROLL', qty: 200, price: 1200, tax_application: 'separate' }
                                ],
                                special_costs: [{ id: 1, name: '배송비', qty: 1, price: 100000, tax_application: 'separate' }],
                                installments: [{ id: 1, type: '전액지급', date: '2026-04-01', req_amount: 8706500, status: '작성중', note: '', _selected: false }]
                            },
                            'PO-20260405-0002': {
                                po_name: '울산 플랜트 배관자재', delivery_place: '울산 현장', contractor: '마이넌 배관시스템', manager: '중간관리자',
                                items: [
                                    { project: '울산 해양플랜트', name: 'SUS 배관 자재', model: 'SUS-316', spec: '16mm', maker: '마이넌', unit: 'M', qty: 100, price: 113636, tax_application: 'separate' },
                                    { project: '울산 해양플랜트', name: 'SUS 엘보 90도', model: 'ELB-16', spec: '16mm', maker: '마이넌', unit: 'EA', qty: 50, price: 8500, tax_application: 'separate' },
                                    { project: '울산 해양플랜트', name: 'SUS 티 90도', model: 'TEE-16', spec: '16mm', maker: '마이넌', unit: 'EA', qty: 30, price: 12000, tax_application: 'separate' },
                                    { project: '울산 해양플랜트', name: 'SUS 플랜지', model: 'FLG-16', spec: '16mm/10K', maker: '마이넌', unit: 'EA', qty: 20, price: 25000, tax_application: 'separate' },
                                    { project: '울산 해양플랜트', name: '가스켓 (비석면)', model: 'GSK-16', spec: '16mm/3T', maker: '청우', unit: 'EA', qty: 100, price: 1500, tax_application: 'separate' }
                                ],
                                installments: [{ id: 2, type: '잔금', date: '2026-04-05', req_amount: 14078460, status: '지급요청', note: '계좌이체 요청', _selected: true }]
                            },
                            'PO-20260410-0003': {
                                po_name: '대성기초건설 기초자재', delivery_place: '인천 현장', contractor: '대성기초건설', manager: '중간관리자',
                                items: [
                                    { project: '인천-공단B', name: 'PHC 말뚝', model: 'PHC-500', spec: '500mm×12m', maker: '대성산업', unit: 'EA', qty: 40, price: 390909, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '상부 캡', model: 'CAP-500', spec: '500mm', maker: '대성산업', unit: 'EA', qty: 40, price: 45000, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '용접봉 (E-4311)', model: 'E-4311', spec: '4.0mm', maker: '고려용접봉', unit: 'BOX', qty: 10, price: 55000, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '고강도 볼트 M24', model: 'B-M24', spec: 'M24*80', maker: 'KPF', unit: 'SET', qty: 200, price: 3500, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '와셔 M24', model: 'W-M24', spec: 'M24', maker: 'KPF', unit: 'EA', qty: 400, price: 450, tax_application: 'separate' }
                                ],
                                installments: [{ id: 3, type: '기성금', date: '2026-04-10', req_amount: 20752996, status: '승인완료', note: '대표 대표 승인 완료 — 재무 이체 대기', _selected: false }]
                            },
                            'PO-20260412-0004': {
                                po_name: '인천 현장 엔진오일 및 필터', delivery_place: '인천 현장', contractor: '현대모비스', manager: '중간관리자',
                                items: [
                                    { project: '인천-공단B', name: '엔진오일 SET', model: 'MOBIS-S1', spec: '상용차용', maker: '현대모비스', unit: 'SET', qty: 20, price: 175000, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '오일 필터', model: 'OF-300', spec: '대형', maker: '현대모비스', unit: 'EA', qty: 20, price: 12000, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '에어 클리너', model: 'AC-500', spec: '대형', maker: '현대모비스', unit: 'EA', qty: 20, price: 25000, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '연료 필터', model: 'FF-100', spec: '대형', maker: '현대모비스', unit: 'EA', qty: 20, price: 18000, tax_application: 'separate' },
                                    { project: '인천-공단B', name: '부동액 (4L)', model: 'AF-4', spec: '4L/사계절용', maker: '현대모비스', unit: 'EA', qty: 10, price: 15000, tax_application: 'separate' }
                                ],
                                installments: [{ id: 4, type: '자재대금', date: '2026-04-12', req_amount: 5225000, status: '승인 반려', note: '세금계산서 미발행 — 반려', _selected: false }]
                            },
                            'PO-20260415-0005': {
                                po_name: '한길포장 전구간 포장재', delivery_place: '대구 현장', contractor: '한길포장', manager: '중간관리자', has_pdf: true,
                                items: [
                                    { project: '대구-북구C', name: '아스콘 자재운반', model: '표층용', spec: '표준형', maker: '한길포장', unit: 'TON', qty: 100, price: 125000, tax_application: 'separate', payment_method: '계좌이체' },
                                    { project: '대구-북구C', name: '택코팅 (RSC-4)', model: 'RSC-4', spec: '200kg/Drum', maker: '한길포장', unit: 'DRUM', qty: 5, price: 280000, tax_application: 'separate', payment_method: '계좌이체' },
                                    { project: '대구-북구C', name: '프라임코팅 (MC-0)', model: 'MC-0', spec: '200kg/Drum', maker: '한길포장', unit: 'DRUM', qty: 3, price: 320000, tax_application: 'separate', payment_method: '계좌이체' },
                                    { project: '대구-북구C', name: '차선 도색 페인트 (백색)', model: 'LP-W', spec: '18L', maker: '노루페인트', unit: 'CAN', qty: 10, price: 85000, tax_application: 'separate', payment_method: '계좌이체' },
                                    { project: '대구-북구C', name: '차선 도색 페인트 (황색)', model: 'LP-Y', spec: '18L', maker: '노루페인트', unit: 'CAN', qty: 5, price: 90000, tax_application: 'separate', payment_method: '계좌이체' },
                                    { project: '대구-북구C', name: '유리알 (차선도색용)', model: 'GB-1', spec: '25kg', maker: '대성', unit: 'BAG', qty: 20, price: 22000, tax_application: 'separate', payment_method: '계좌이체' }
                                ],
                                installments: [{ id: 5, type: '전액기성', date: '2026-04-15', req_amount: 18260000, status: '지급완료', note: '국민은행 이체완료 TX#38291', _selected: false }]
                            },
                            // PROJECT 부대비용 케이스들
                            'PC-20260419-0007': {
                                po_name: '건설 현장 안전 진단 서비스', delivery_place: '전국 현장', contractor: '글로벌안전공사', manager: '팀원1',
                                items: [{ project: '-', name: '정기 안전 진단 용역', cost_type: '현장/공사', model: 'DIAG-Q', spec: '2분기 정기', maker: '글로벌안전공사', unit: '식', qty: 1, price: 2000000, tax_application: 'separate' }],
                                installments: [{ id: 7, type: '용역비', date: '2026-04-19', req_amount: 2200000, status: '지급요청', note: '계좌이체 승인요청', _selected: true }]
                            },
                            'PC-20260420-0008': {
                                po_name: '자재 품질 시험 성적서 발급', delivery_place: '한국품질시험원', contractor: '한국품질시험원', manager: '팀원1',
                                items: [{ project: '-', name: '인장강도/충격 시험 성적서', cost_type: '시험/품질', model: 'KS-Q', spec: '고강도볼트', maker: '한국품질시험원', unit: '식', qty: 1, price: 800000, tax_application: 'separate' }],
                                installments: [{ id: 8, type: '시험비', date: '2026-04-20', req_amount: 880000, status: '승인완료', note: '대표 대표 승인 완료 — 재무 이체 대기', _selected: false }]
                            },
                            // 현금 결제 케이스
                            'CASH-20260422-0001': {
                                po_name: '현장 소모품 현금 구매', delivery_place: '부산 3공구', contractor: '현장 마트', manager: '중간관리자',
                                items: [{ project: '부산항 3공구', name: '현장 소모품', cost_type: '일반경비', model: '-', spec: '-', maker: '-', unit: '식', qty: 1, price: 87000, tax_application: 'separate', payment_method: '현금', proof_filename: 'receipt_20260422_mart.jpg' }],
                                installments: [], cash_note: '현금영수증 발급 완료.',
                            },
                            'CASH-20260423-0002': {
                                po_name: '현장 인력 식대 현금 지급', delivery_place: '부산 3공구', contractor: '현장 식당', manager: '팀원1',
                                items: [{ project: '부산항 3공구', name: '현장 인력 식대', cost_type: '일반경비', model: '-', spec: '-', maker: '-', unit: '식', qty: 1, price: 43000, tax_application: 'separate', payment_method: '현금', proof_filename: '' }],
                                installments: [], cash_note: '영수증 미첨부.',
                            },
                            // 환불 케이스
                            'RF-20260421-0009': {
                                is_refund: true, refund_method: 'TRANSFER',
                                refund_reason: '납품 자재 일부 반품 — 계좌이체 환불 확인 요청 (ct_parent_ct_sn=7005)',
                                po_name: '한길포장 반품 환불', delivery_place: '대구 현장', contractor: '한길포장', manager: '중간관리자',
                                items: [{ project: '대구-북구C', name: '아스콘 반품', model: '표층용', spec: '표준형', maker: '한길포장', unit: 'TON', qty: 20, price: -125000, tax_application: 'separate' }],
                                installments: [{ id: 9, type: '환불 확인요청', date: '2026-04-21', req_amount: -2750000, status: '지급요청', note: 'refund payable CREATED 상태' }]
                            },
                        },
                        payables: [],
                        payable_cost_allocations: [],
                        nextPblSn: 20000
                    }
                },
                computed: {
                    mappedCosts() {
                        return this.costs.map(c => {
                            let meta = this.origin_meta[c.origin_sn] || { po_name: c.vendor_name, delivery_place: '본사', contractor: '-', items: [], special_costs: [], installments: [] };

                            // ── 정본 기준 6단계 상태 매핑 ──
                            // costs.ct_status(CREATE/CANCEL/REFUND) × payables.pbl_status × payments.pay_status
                            let statusKey = '비용등록';
                            let displayLabel = '비용등록';

                            if (c.ct_status === 'REFUND' || c.origin_type === 'REFUND') {
                                statusKey = '환불처리';
                                displayLabel = '환불처리';
                            } else if (c.pbl_status === 'PROCESSED' || c.pay_status === 'PROCESSED') {
                                // payments.pay_status = PROCESSED → 지급완료
                                statusKey = '지급완료';
                                displayLabel = '지급완료';
                            } else if (c.pbl_status === 'APPROVED' || c.pbl_status === 'ON_HOLD') {
                                // payables.pbl_status = APPROVED or ON_HOLD → 지급대기(재무 이체 전)
                                // ON_HOLD는 재무팀 내부 처리방식 차이일 뿐, 구매담당자 화면에서는 동일하게 '지급대기'로 표시
                                statusKey = '지급대기';
                                displayLabel = '지급대기';
                            } else if (c.pbl_status === 'REJECTED') {
                                statusKey = '승인반려';
                                displayLabel = '승인반려';
                            } else if (c.pbl_status === 'CREATED') {
                                // payables.pbl_status = CREATED → 지급요청중
                                statusKey = '지급요청중';
                                displayLabel = '지급요청중';
                            } else if (c.pay_method === 'CARD' && c.pay_status === 'PROCESSED') {
                                // 카드 즉시결제: payable 없이 cost→payment 직행
                                statusKey = '지급완료';
                                displayLabel = '지급완료(카드)';
                            } else {
                                // payable 없음 → costs만 존재
                                statusKey = '비용등록';
                                displayLabel = '비용등록';
                            }

                            return { ...c, ...meta, pblState: { status: statusKey, statusKey, displayLabel, note: null } };
                        });
                    },
                    filteredCosts() {
                        let arr = this.mappedCosts;

                        if (this.userRole === 'CEO') {
                            // CEO mode: Show '승인요청중' from ALL managers by default
                            arr = arr.filter(i => i.pblState.status === '지급요청중' || i.pblState.status === '지급대기');
                            if (this.filterUser !== 'ALL') {
                                arr = arr.filter(i => i.manager === this.filterUser);
                            }
                        } else {
                            // Procurement mode: Always filtered by a manager since 'ALL' is removed
                            const selectedManager = this.filterUser === 'ALL' ? '중간관리자' : this.filterUser;
                            arr = arr.filter(i => i.manager === selectedManager);

                            if (this.filterStatus !== 'ALL') arr = arr.filter(i => i.pblState.status === this.filterStatus || i.pblState.statusKey === this.filterStatus);
                        }
                        if (this.filterDateRange !== 'all' && this.startDate && this.endDate) {
                            const start = new Date(this.startDate);
                            const end = new Date(this.endDate);
                            arr = arr.filter(i => {
                                const itemDate = new Date(i.date);
                                return itemDate >= start && itemDate <= end;
                            });
                        }
                        if (this.searchText) {
                            const low = this.searchText.toLowerCase();
                            arr = arr.filter(i =>
                                i.vendor_name.toLowerCase().includes(low) ||
                                i.po_name.toLowerCase().includes(low)
                            );
                        }
                        return arr;
                    },
                    isIncidental() {
                        if (!this.selectedItem) return false;
                        const type = this.selectedItem.origin_type_display;
                        return type.includes('부대비용') || type.includes('직접비용');
                    },
                    isAlreadyPaid() {
                        if (!this.selectedItem || !this.selectedItem.items) return false;
                        return this.selectedItem.items.some(item => item.payment_method === '카드' || item.payment_method === '현금');
                    },
                    isPoCosts() {
                        if (!this.selectedItem) return false;
                        return this.selectedItem.origin_type_display.includes('발주비용');
                    },
                    isSubmitDisabled() {
                        if (!this.selectedItem || !this.selectedItem.items || this.selectedItem.items.length === 0) return false;
                        const itm = this.selectedItem.items[0];

                        // 1. 카드 결제 시: 증빙 파일 필수
                        if (itm.payment_method === '카드') {
                            if (this.isIncidental && !itm.proof_filename) return true;
                        }

                        // 1-2. 현금 결제 시: 영수증 첨부 필수
                        if (itm.payment_method === '현금') {
                            if (!this.selectedItem.cash_proof_filename) return true;
                        }

                        // 2. 계좌 이체 시: 계좌 정보 3종 필수 (은행, 예금주, 계좌번호) - PO 건 제외 (UI가 숨겨져 있음)
                        if (itm.payment_method === '계좌이체' && !this.isPoCosts) {
                            if (!itm.account_info || !itm.account_info.bank || !itm.account_info.holder || !itm.account_info.number) {
                                return true;
                            }
                        }

                        return false;
                    },
                    isItemFullySettled() {
                        if (!this.selectedItem || this.selectedItem.is_refund) return false;
                        const totalGoal = this.grandTotal.total;
                        const totalFinalized = (this.selectedItem.installments || [])
                            .filter(i => this.isInstFrozen(i))
                            .reduce((sum, i) => sum + i.req_amount, 0);
                        return totalFinalized >= totalGoal && this.selectedItem.pblState.status === '승인완료';
                    },
                    grandTotal() {
                        if (!this.selectedItem) return { subtotal: 0, special: 0, discount: 0, refund: 0, taxExcl: 0, vat: 0, total: 0 };

                        const isRefund = this.selectedItem.is_refund;
                        const sign = isRefund ? -1 : 1;

                        // 1. Items subtotal
                        const subtotal = (this.selectedItem.items || []).filter(i => !i.is_sub).reduce((s, i) => s + i.qty * (i.price || 0), 0);

                        // 2. Special Costs
                        const specialExcl = (this.selectedItem.special_costs || []).reduce((s, sc) => s + this.getSubtotal(sc), 0);
                        const specialVat = (this.selectedItem.special_costs || []).reduce((s, sc) => s + this.getVat(sc), 0);

                        const discount = this.selectedItem.discount_amount || 0;

                        // 3. Tax Exclusive Sum
                        const taxExcl = (subtotal + specialExcl - discount) * sign;

                        // 4. VAT Sum
                        const itemVat = Math.floor((subtotal - discount) * 0.1);
                        const totalVat = (itemVat + specialVat) * sign;

                        return {
                            subtotal: subtotal * sign,
                            special: (specialExcl + specialVat) * sign,
                            discount: discount * sign,
                            refund: isRefund ? (subtotal + itemVat) : 0, // Used for logical display in summary if needed
                            taxExcl,
                            vat: totalVat,
                            total: taxExcl + totalVat
                        };
                    },
                    detailReqAmount() {
                        if (!this.selectedItem) return 0;
                        // 기안 대상으로 선택된 항목 또는 현재 승인요청 중인 항목을 합산
                        const selected = this.selectedItem.installments.filter(i =>
                            i._selected || i.status === '승인요청중' || i.status === '지급대기'
                        );
                        return selected.reduce((s, i) => s + i.req_amount, 0);
                    },
                    detailDate() {
                        if (!this.selectedItem) return '';
                        const selected = this.selectedItem.installments.filter(i =>
                            i._selected || i.status === '승인요청중' || i.status === '지급대기'
                        );
                        return selected.length > 0 ? selected[0].date : '';
                    },
                    newIncidentalTotals() {
                        return this.newIncidentalCosts.reduce((acc, r) => {
                            const t = this.calculateRowTotals(r);
                            acc.subtotal += t.subtotal;
                            acc.vat += t.vat;
                            acc.total += (r.taxApp === 'separate' ? (t.subtotal + t.vat) : t.subtotal);
                            return acc;
                        }, { subtotal: 0, vat: 0, total: 0 });
                    },
                    /* Allocation Modal Computed */
                    filteredAuditLogs() {
                        if (this.auditLogFilter === 'mine') {
                            return this.auditLogs.filter(l => l.mine);
                        }
                        return this.auditLogs;
                    },
                    // 상세 패널 인라인 이력: 현재 열린 건의 ref에 해당하는 사건만
                    itemAuditLogs() {
                        if (!this.selectedItem) return [];
                        const ref = this.selectedItem.origin_sn;
                        return this.auditLogs
                            .filter(l => l.ref === ref)
                            .sort((a, b) => a.time.localeCompare(b.time));
                    },
                    groupedAuditLogs() {
                        // ref(발주번호/건 식별자)별로 사건 묶기 → 한 건의 흐름이 한눈에 보임
                        const map = new Map();
                        for (const log of this.filteredAuditLogs) {
                            if (!map.has(log.ref)) {
                                map.set(log.ref, { ref: log.ref, logs: [], finalStatus: '' });
                            }
                            map.get(log.ref).logs.push(log);
                        }
                        // 각 그룹의 마지막 사건 상태를 최종 상태로 사용
                        for (const group of map.values()) {
                            group.finalStatus = group.logs[group.logs.length - 1].status;
                        }
                        // ref 기준 첫 사건 시간순 정렬
                        return Array.from(map.values()).sort((a, b) =>
                            b.logs[0].time.localeCompare(a.logs[0].time)
                        );
                    },
                    allocationTotals() {
                        if (!this.allocationData) return { subtotal: 0, vat: 0, total: 0, remaining: 0 };
                        let subtotal = 0;
                        let vat = 0;

                        this.allocationData.specialCosts.forEach(row => {
                            subtotal += row.supply;
                            vat += row.vat;
                        });
                        this.allocationData.negoCosts.forEach(row => {
                            subtotal += row.supply;
                            vat += row.vat;
                        });

                        const total = subtotal + vat;

                        let allocated = 0;
                        [...this.allocationData.specialCosts, ...this.allocationData.negoCosts].forEach(row => {
                            allocated += (Number(row.allocA) || 0) + (Number(row.allocB) || 0);
                        });

                        return {
                            subtotal,
                            vat,
                            total,
                            remaining: total - allocated
                        };
                    },
                    isAllocationFullySettled() {
                        return Math.abs(this.allocationTotals.remaining) < 1;
                    }
                },
                methods: {
                    getSubtotal(sc) {
                        if (sc.tax_application === 'inclusive') return Math.round((sc.qty * (sc.price || 0)) / 1.1);
                        return Math.floor(sc.qty * (sc.price || 0));
                    },
                    getVat(sc) {
                        if (sc.tax_application === 'inclusive') return Math.floor(sc.qty * (sc.price || 0)) - this.getSubtotal(sc);
                        if (sc.tax_application === 'exempt' || sc.tax_application === 'zero') return 0;
                        return Math.floor(this.getSubtotal(sc) * 0.1);
                    },
                    // [신규] 거래처 검색 및 계좌 정보 자동 완성
                    searchPartner(e, item) {
                        const query = e.target.value.trim().toLowerCase();
                        if (!query) {
                            item._partnerResults = null;
                            return;
                        }
                        const results = this.partners.filter(p => p.name.toLowerCase().includes(query));
                        item._partnerResults = results.length > 0 ? results : null;
                    },
                    selectPartner(partner, item) {
                        if (!item.account_info) item.account_info = { bank: '', number: '', holder: '' };
                        item.account_info.holder = partner.holder;
                        // 첫 번째 계좌 기본 선택
                        if (partner.accounts && partner.accounts.length > 0) {
                            item.account_info.bank = partner.accounts[0].bank;
                            item.account_info.number = partner.accounts[0].number;
                        }
                        item._availableAccounts = partner.accounts;
                        item._partnerResults = null;
                    },
                    // [신규] 지급 증빙 파일 업로드 시뮬레이션
                    triggerFileUpload(item) {
                        const filename = prompt('업로드할 증빙 파일명을 입력하세요 (시뮬레이션):', 'receipt_' + new Date().getTime() + '.png');
                        if (filename) {
                            item.proof_filename = filename;
                        }
                    },
                    /* Registration Modal Methods */
                    openAddModal() {
                        this.isAddModalOpen = true;
                        this.newIncidentalCosts = [];
                        this.addIncidentalRow();
                    },
                    addIncidentalRow() {
                        this.newIncidentalCosts.push({
                            id: Date.now() + Math.random(),
                            division: '프로젝트',
                            itemName: '',
                            sourcingMethod: '국내구매',
                            vendorName: '',
                            expenseType: '일반경비/운영비',
                            taxApp: 'separate',
                            unitPrice: 0,
                            qty: 1,
                            payMethod: '계좌이체',
                            reqDate: new Date().toISOString().split('T')[0],
                            note: '',
                            _isRefund: false
                        });
                    },
                    duplicateIncidentalRow(row) {
                        const idx = this.newIncidentalCosts.indexOf(row);
                        const newRow = JSON.parse(JSON.stringify(row));
                        newRow.id = Date.now() + Math.random();
                        this.newIncidentalCosts.splice(idx + 1, 0, newRow);
                    },
                    removeIncidentalRow(row) {
                        const idx = this.newIncidentalCosts.indexOf(row);
                        this.newIncidentalCosts.splice(idx, 1);
                        if (this.newIncidentalCosts.length === 0) this.addIncidentalRow();
                    },
                    toggleRefundRow(row) {
                        row._isRefund = !row._isRefund;
                        if (row._isRefund) {
                            if (row.unitPrice > 0) row.unitPrice = -Math.abs(row.unitPrice);
                        } else {
                            row.unitPrice = Math.abs(row.unitPrice);
                        }
                    },
                    calculateRowTotals(row) {
                        const subtotal = row.unitPrice * row.qty;
                        let vat = 0;
                        if (row.taxApp === 'separate') vat = Math.floor(subtotal * 0.1);
                        else if (row.taxApp === 'inclusive') {
                            const excl = Math.round(subtotal / 1.1);
                            vat = subtotal - excl;
                        }
                        return { subtotal, vat, total: subtotal + (row.taxApp === 'separate' ? vat : 0) };
                    },
                    registerIncidentalCosts() {
                        const invalid = this.newIncidentalCosts.some(r => !r.vendorName || !r.itemName);
                        if (invalid) return alert('거래처명과 항목명(품목명)을 모두 입력해주세요.');

                        this.newIncidentalCosts.forEach(r => {
                            const totals = this.calculateRowTotals(r);
                            const ct_sn = 8000 + Math.floor(Math.random() * 1000);

                            let categoryDisplay = '프로젝트 부대비용';
                            let originType = 'PROJECT';
                            if (r.division === '품목별 직접비용') {
                                categoryDisplay = '품목별 직접비용';
                                originType = 'ITEM_COST';
                            }

                            if (r.unitPrice < 0) {
                                categoryDisplay += ' (환불건)';
                                originType = 'REFUND';
                            }

                            const isCash = r.payMethod === '현금';

                            const newCost = {
                                ct_sn,
                                vendor_name: r.vendorName,
                                amount: totals.total,
                                date: r.reqDate,
                                origin_type: originType,
                                origin_sn: (isCash ? 'CASH-' : originType === 'PO' ? 'PO-I-' : 'DIR-I-') + ct_sn,
                                ct_type: 'PROJECT',
                                ct_kind: 'GENERAL_EXPENSE',
                                ct_status: 'CREATE',
                                pbl_status: null,
                                pay_status: null,
                                // 현금: pay_method=CASH 세팅 → 상세에서 현금 UI로 분기
                                pay_method: isCash ? 'CASH' : null,
                                cash_reported: false,
                                cash_proof_filename: '',
                                manager: this.filterUser === 'ALL' ? '중간관리자' : this.filterUser,
                                origin_type_display: categoryDisplay + (isCash ? ' (현금)' : ''),
                            };

                            const newMeta = {
                                po_name: r.itemName,
                                delivery_place: '현장',
                                contractor: r.vendorName,
                                manager: newCost.manager,
                                associated_projects: [...this.selectedProjects],
                                items: [{
                                    name: r.itemName,
                                    client_name: r.vendorName,
                                    cost_type: r.expenseType,
                                    qty: r.qty,
                                    price: r.unitPrice,
                                    tax_application: r.taxApp,
                                    payment_method: r.payMethod
                                }],
                                // 현금: installment 없음 (payable 생성 안 함)
                                // 카드/계좌이체: 기안대기 상태로 생성
                                installments: isCash ? [] : [{
                                    id: this.nextInstId++,
                                    type: r.unitPrice < 0 ? '환불 기안' : '부대비용 기안',
                                    date: r.reqDate,
                                    req_amount: totals.total,
                                    status: '기안대기',
                                    note: r.note
                                }]
                            };

                            this.costs.unshift(newCost);
                            this.origin_meta[newCost.origin_sn] = newMeta;
                        });

                        this.isAddModalOpen = false;
                        alert('등록되었습니다. 리스트에서 확인 후 기안을 진행해주세요.');
                    },
                    getNextPaymentDate(item) {
                        const pending = (item.installments || []).find(i => i.status === '기안대기');
                        return pending ? pending.date : item.date;
                    },
                    openProjectInfo() {
                        window.open('project_info.html', '_blank', 'width=1400,height=900');
                    },
                    viewPoDetail(originSn) {
                        const po = this.origin_meta[originSn];
                        if (po && po.has_pdf) {
                            this.pdfTitle = `${originSn} - 발주서 (PDF Viewer)`;
                            this.showPdfModal = true;
                        } else {
                            // Fallback or alert
                            alert('발주서 PDF 파일이 존재하지 않는 거래입니다.');
                        }
                    },
                    openDetail(item) {
                        this.selectedItem = item;
                        this.ceoComment = item.pbl_approval_comment || '';

                        // Force re-calculation/refresh to ensure grandTotal is ready
                        this.$nextTick(() => {
                            const totalWithVAT = this.grandTotal.total;
                            if (!item.installments || item.installments.length === 0) {
                                item.installments = [{
                                    id: this.nextInstId++,
                                    type: '잔금 (전액지급)',
                                    date: item.date,
                                    req_amount: totalWithVAT,
                                    status: '작성중',
                                    note: '',
                                    _selected: true
                                }];
                            } else {
                                // 단일 미결 회차인 경우 금액을 부가세 포함 총액으로 자동 보정 (사용자 요청 사항)
                                const editableInsts = item.installments.filter(i => !this.isInstFrozen(i));
                                if (editableInsts.length === 1 && item.installments.length === 1) {
                                    editableInsts[0].req_amount = totalWithVAT;
                                }
                            }
                            // 기안 대기 중인 항목은 기본적으로 선택(체크)되어 하단 "지급 요청 금액"에 반영되도록 함
                            item.installments.forEach(i => {
                                if (i.status === '기안대기' || i.status === '작성중' || i.status.includes('반려')) {
                                    i._selected = true;
                                }
                            });
                        });
                    },
                    closeDetail() { this.selectedItem = null; },
                    reDraft(inst) {
                        if (confirm('해당 회차를 반려된 상태에서 해제하여 다시 기안하겠습니까?\n(상태가 기안대기로 변경되며 정산내역을 수정할 수 있게 됩니다)')) {
                            inst.status = '기안대기';
                            inst._selected = true; // 자동으로 다시 기안 대상으로 선택
                        }
                    },
                    addInstallmentRow() {
                        if (!this.selectedItem) return;
                        // [순차적 기안 강제] 마지막 행이 승인완료여야만 새로운 행 추가 가능
                        const insts = this.selectedItem.installments || [];
                        if (insts.length > 1) {
                            const lastInst = insts[insts.length - 1];
                            if (!['승인완료', '지급완료', '지급대기'].includes(lastInst.status)) {
                                alert('이전 회차의 승인이 완료되어야 다음 행을 추가할 수 있습니다.');
                                return;
                            }
                        }
                        const totalWithVAT = this.grandTotal.total;
                        const currentSum = this.selectedItem.installments.reduce((s, i) => s + i.req_amount, 0);
                        const remaining = totalWithVAT - currentSum;

                        this.selectedItem.installments.push({
                            id: this.nextInstId++,
                            type: '분할지급',
                            date: '',
                            req_amount: remaining > 0 ? remaining : 0,
                            status: '작성중',
                            note: '',
                            _selected: true // 추가 시 바로 기안 대상자로 포함
                        });
                    },
                    removeInstallmentRow(inst) {
                        const idx = this.selectedItem.installments.indexOf(inst);
                        if (idx > -1) this.selectedItem.installments.splice(idx, 1);
                        // After removal, balance the remaining rows if possible
                        if (this.selectedItem.installments.length > 0) {
                            const last = this.selectedItem.installments.find(i => !this.isInstFrozen(i));
                            if (last) this.balanceInstallments(null);
                        }
                    },
                    balanceInstallments(inst) {
                        if (!this.selectedItem) return;
                        const totalWithVAT = this.grandTotal.total;
                        const currentSum = this.selectedItem.installments.reduce((s, i) => s + i.req_amount, 0);
                        const diff = totalWithVAT - currentSum;

                        // Find a row to absorb the difference (last editable row that is NOT the one being changed)
                        const installments = this.selectedItem.installments;
                        const target = [...installments].reverse().find(i => !this.isInstFrozen(i) && i !== inst);

                        if (target) {
                            target.req_amount = Math.max(0, (target.req_amount || 0) + diff);
                        }
                    },
                    toggleInstallment(inst) {
                        if (this.isInstFrozen(inst)) return;
                        inst._selected = !inst._selected;
                    },
                    isInstFrozen(inst) { return ['승인완료', '승인요청중', '지급대기', '지급완료'].includes(inst.status); },
                    makeSingleRequest() {
                        if (this.isSubmitDisabled) return;
                        if (this.detailReqAmount === 0) return alert('금액을 확인해 주세요.');

                        const itm0 = this.selectedItem.items[0];
                        const isDirectPaid = itm0 && itm0.payment_method === '카드';

                        const msg = isDirectPaid ? '법인카드 결제 내역은 승인 단계 없이 재무 내역으로 즉시 반영됩니다. 제출하시겠습니까?' : '승인 요청되었습니다.';
                        if (isDirectPaid) {
                            if (!confirm(msg)) return;
                        } else {
                            if (this.detailReqAmount < 0 && !confirm('환불(차감) 승인 요청을 기안하시겠습니까?')) return;
                            alert(msg);
                        }

                        const item = this.costs.find(c => c.ct_sn === this.selectedItem.ct_sn);
                        if (item) {
                            const nextStatus = isDirectPaid ? '지급완료' : '승인요청중';
                            item.status = nextStatus;
                            if (item.installments) {
                                item.installments.forEach(i => {
                                    const target = this.selectedItem.installments.find(si => si.id === i.id);
                                    if (target && target._selected) i.status = nextStatus;
                                });
                            }
                        }

                        // 선택된 회차들의 비고(메모)를 취합
                        const installmentNotes = (this.selectedItem.installments || [])
                            .filter(i => i._selected)
                            .map(i => i.note)
                            .filter(n => n && n.trim() !== '')
                            .join(' / ');

                        this.createPayable(this.selectedItem, this.detailReqAmount, this.detailDate, installmentNotes, isDirectPaid);
                        this.closeDetail();
                    },
                    createPayable(item, amount, date, note, isDirectPaid) {
                        // 지급 상세 정보 취합 (계좌정보 또는 증빙파일)
                        const proofDetails = (item.items || []).map(itm => ({
                            name: itm.name,
                            method: itm.payment_method,
                            account: itm.account_info,
                            proof: itm.proof_filename
                        }));

                        const pbl = {
                            pbl_sn: this.nextPblSn++,
                            pbl_requested_at: new Date().toISOString().split('T')[0],
                            pbl_due_at: date || item.date,
                            pt_name: item.vendor_name,
                            pbl_total_amount: amount,
                            pbl_payable_status: 'CREATED',
                            pbl_note: note || '', // 재무 담당자에게 전달될 메모
                            pbl_proof_details: proofDetails, // [추가] 상세 지급 증빙/계좌 정보
                            // Added metadata for Finance module
                            manager: item.manager,
                            delivery_place: item.delivery_place,
                            contractor: item.contractor,
                            delivery_date: item.delivery_cond || item.delivery_date || date || item.date,
                            cost_info: {
                                ct_sn: item.ct_sn,
                                description: item.po_name || item.vendor_name
                            },
                            origin_info: {
                                type: item.origin_type || 'PO',
                                sn: item.origin_sn || 'N/A'
                            }
                        };
                        this.payables.push(pbl);
                        this.payable_cost_allocations.push({ pbl_sn: pbl.pbl_sn, ct_sn: item.ct_sn, amount: amount });

                        if (isDirectPaid) {
                            pbl.pbl_payable_status = 'PAID';
                            this.syncToPayments(pbl);
                        }
                    },
                    syncToFinance(payable) {
                        const sharedKey = 'erp_shared_payables';
                        let current = JSON.parse(localStorage.getItem(sharedKey) || '[]');

                        // [UI Unification] Expand metadata for Finance execution
                        const packet = {
                            ...payable,
                            pbl_payable_status: 'APPROVED',
                            // Add details for expanded Finance UI
                            pbl_vendor_contact: this.selectedItem.tel || '010-3344-5566',
                            pbl_bank_holder: (payable.pbl_proof_details && payable.pbl_proof_details[0]?.account?.holder) || payable.pt_name,
                            cost_items: this.selectedItem.items.map(itm => ({
                                name: itm.name,
                                type: itm.cost_type || '직접비용',
                                supply: (itm.price * itm.qty) / (itm.tax_application === 'inclusive' ? 1.1 : 1),
                                vat: itm.tax_application === 'separate' ? (itm.price * itm.qty * 0.1) : (itm.tax_application === 'inclusive' ? (itm.price * itm.qty / 11) : 0)
                            }))
                        };

                        current.push(packet);
                        localStorage.setItem(sharedKey, JSON.stringify(current));
                    },
                    syncToPayments(payable) {
                        const sharedKey = 'erp_shared_payments';
                        let current = JSON.parse(localStorage.getItem(sharedKey) || '[]');

                        const method = (payable.pbl_proof_details && payable.pbl_proof_details.length > 0)
                            ? (payable.pbl_proof_details[0].method === '법인카드' ? 'CARD' : 'CASH')
                            : 'CARD';

                        const packet = {
                            pay_sn: 'PAY-' + payable.pbl_sn,
                            pay_paid_at: new Date().toISOString().split('T')[0],
                            pay_method: method,
                            vendor_name: payable.pt_name,
                            description: `[선결제 확인] ${payable.contractor} - ${payable.pbl_note || '현장 결제 보고'}`,
                            amount: payable.pbl_total_amount,
                            has_doc: true,
                            manual_docs: []
                        };
                        current.push(packet);
                        localStorage.setItem(sharedKey, JSON.stringify(current));
                    },
                    ceoApprove() {
                        if (!confirm('최종 승인하시겠습니까?')) return;
                        const item = this.costs.find(c => c.ct_sn === this.selectedItem.ct_sn);
                        if (item) {
                            item.pbl_status = 'APPROVED'; // → 지급대기 (재무 이체 전)
                            item.pbl_approval_comment = this.ceoComment;

                            // Update installments status to '승인완료'
                            if (item.installments) item.installments.forEach(i => { if (i.status === '승인요청중') i.status = '승인완료'; });

                            // Find un-synced payables for this item and sync them
                            const allocs = this.payable_cost_allocations.filter(a => a.ct_sn === item.ct_sn);
                            allocs.forEach(alloc => {
                                const pbl = this.payables.find(p => p.pbl_sn === alloc.pbl_sn && p.pbl_payable_status === 'CREATED');
                                if (pbl) {
                                    if (this.isAlreadyPaid) {
                                        pbl.pbl_payable_status = 'PAID';
                                        pbl.pbl_approval_comment = this.ceoComment; // CEO 코멘트 전송
                                        this.syncToPayments(pbl);
                                    } else {
                                        pbl.pbl_payable_status = 'APPROVED';
                                        pbl.pbl_approval_comment = this.ceoComment; // CEO 코멘트 전송
                                        this.syncToFinance(pbl);
                                    }
                                }
                            });
                        }
                        alert('승인되었습니다.');
                        this.closeDetail();
                    },
                    ceoReject() {
                        if (!this.ceoComment) return alert('반려 사유(의견)를 입력해 주세요.');
                        if (!confirm('반려 처리하시겠습니까?')) return;
                        const item = this.costs.find(c => c.ct_sn === this.selectedItem.ct_sn);
                        if (item) {
                            item.pbl_status = 'REJECTED';
                            item.pbl_approval_comment = this.ceoComment;
                            // 해당 건의 installments 중 승인요청중이었던 것들을 모두 승인반려로 변경
                            if (item.installments) {
                                item.installments.forEach(i => {
                                    if (i.status === '승인요청중') i.status = '승인반려';
                                });
                            }
                        }
                        alert('반려되었습니다.');
                        this.closeDetail();
                    },
                    validateDateRange() {
                        const start = new Date(this.startDate);
                        const end = new Date(this.endDate);
                        if (start > end) {
                            alert('시작일이 종료일보다 늦을 수 없습니다.');
                            this.endDate = this.startDate;
                            return;
                        }
                        const diffTime = Math.abs(end - start);
                        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        if (diffDays > 365) {
                            alert('조회 기간은 최대 1년(365일)을 넘을 수 없습니다.');
                            const maxEnd = new Date(start);
                            maxEnd.setFullYear(maxEnd.getFullYear() + 1);
                            this.endDate = maxEnd.toISOString().split('T')[0];
                        }
                    },
                    /* Allocation Modal Methods */
                    openAllocationModal() {
                        const item = this.selectedItem;
                        if (!item) return;

                        this.allocationData = {
                            originSn: item.origin_sn,
                            vendor: item.vendor_name,
                            projectA: { id: 'P2025-A', name: item.items && item.items[0] ? item.items[0].project : '프로젝트 A' },
                            specialCosts: (item.special_costs || []).map(sc => {
                                const supply = this.getSubtotal(sc);
                                const vat = this.getVat(sc);
                                const total = supply + vat;
                                return {
                                    name: sc.name,
                                    total: total,
                                    supply: supply,
                                    vat: vat,
                                    allocA: 0,
                                    allocB: 0
                                };
                            }),
                            negoCosts: item.discount_amount ? [
                                {
                                    name: '자재단가 네고',
                                    supply: item.discount_amount,
                                    vat: Math.floor(item.discount_amount * 0.1),
                                    total: Math.floor(item.discount_amount * 1.1),
                                    allocA: 0,
                                    allocB: 0
                                }
                            ] : []
                        };
                        this.allocationProjectB = { id: '', name: '배분 대상 프로젝트' };
                        this.isAllocationModalOpen = true;
                    },
                    applyAllocation() {
                        if (!this.isAllocationFullySettled) {
                            return alert('잔여 금액이 0원이어야 배분 적용이 가능합니다.');
                        }
                        this.isAllocationModalOpen = false;
                        alert('배분 적용이 완료되었습니다.');
                    },
                    removeAllocationProjectB() {
                        this.allocationProjectB = { id: '', name: '배분 대상 프로젝트' };
                        [...this.allocationData.specialCosts, ...this.allocationData.negoCosts].forEach(row => row.allocB = 0);
                    },

                    openFinanceDirectModal() {
                        this.financeDirectForm = {
                            expenseType: '소액경비', vendorName: '', amount: 0,
                            date: new Date().toISOString().split('T')[0],
                            payMethod: '법인카드', linkedProject: '', note: ''
                        };
                        this.isFinanceDirectModalOpen = true;
                    },
                    submitFinanceDirect() {
                        if (!this.financeDirectForm.vendorName || !this.financeDirectForm.amount || !this.financeDirectForm.note) {
                            return alert('거래처명, 금액, 처리 사유는 필수 입력사항입니다.');
                        }
                        this.auditLogs.unshift({
                            id: this.auditLogs.length + 1,
                            time: new Date().toLocaleString('ko-KR'),
                            actor: '재무관리자',
                            action: '재무 직접 처리',
                            ref: 'FIN-' + String(this.auditLogs.length + 1).padStart(4, '0'),
                            status: '처리완료',
                            amount: this.financeDirectForm.amount,
                            note: '[' + this.financeDirectForm.expenseType + '] ' + this.financeDirectForm.note,
                            financeBypass: true
                        });
                        this.isFinanceDirectModalOpen = false;
                        alert('처리가 완료되었습니다. 감사 로그에 기록되었습니다.');
                    },
                    simulateCashProofUpload() {
                        const filename = prompt('업로드할 파일명 (시뮬레이션):', 'receipt_' + Date.now() + '.jpg');
                        if (filename && this.selectedItem) {
                            this.selectedItem.cash_proof_filename = filename;
                            const cost = this.costs.find(c => c.ct_sn === this.selectedItem.ct_sn);
                            if (cost) cost.cash_proof_filename = filename;
                        }
                    },
                    /* Dev Guide Methods */
                    showMemo(event, key) {
                        if (!this.devGuideMode) return;
                        this.activeMemoKey = key;
                        this.memoVisible = true;
                        const rect = event.currentTarget.getBoundingClientRect();
                        this.memoPos = {
                            x: rect.right + 10,
                            y: rect.top
                        };
                        // Viewport boundary check
                        if (this.memoPos.x + 480 > window.innerWidth) {
                            this.memoPos.x = rect.left - 490;
                        }
                    },
                    hideMemo() {
                        this.memoVisible = false;
                    },
                    keepMemo() {
                        this.memoVisible = true;
                    },
                    saveMemo(key) {
                        // Locally persist edited memos for current session
                        console.log(`Memo updated for ${key}`);
                    }
                },
                watch: {
                    filterDateRange(val) {
                        if (val === 'custom') return;
                        const end = new Date();
                        const start = new Date();
                        if (val === '1month') start.setMonth(start.getMonth() - 1);
                        else if (val === '3months') start.setMonth(start.getMonth() - 3);
                        else if (val === '6months') start.setMonth(start.getMonth() - 6);

                        this.endDate = end.toISOString().split('T')[0];
                        this.startDate = start.toISOString().split('T')[0];
                    },
                    startDate() { this.validateDateRange(); },
                    endDate() { this.validateDateRange(); },
                    userRole(val) {
                        if (val === 'CEO') {
                            this.filterUser = 'ALL';
                            this.filterStatus = 'ALL'; // CEO는 지급요청중 + 지급대기 모두 표시
                        } else {
                            this.filterUser = '중간관리자';
                            this.filterStatus = 'ALL';
                        }
                    }
                },
                mounted() {
                    // Initialize to 'custom' with a wide range to show everything without empty boxes
                    this.filterDateRange = 'custom';
                    this.startDate = '2026-01-01';
                    this.endDate = '2026-12-31';
                }
            }).mount('#app');
        