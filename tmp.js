const document = { querySelectorAll: () => [], getElementById: () => ({ style: {}, classList: { add: ()=>{}, remove: ()=>{} } }) };
const window = {};

        
        // ===================== 대표이사 전용 뷰 (3-Pane) =====================
        let selectedCeoPoId = null;

        function renderCeoView() {
          // Left Pane: List
          const listPane = document.getElementById('ceo-list-pane');
          if (!listPane) return;
          
          listPane.innerHTML = PO_APPROVAL_DATA.map(po => {
            const isSelected = po.id === selectedCeoPoId;
            const isPending = po.approvalStep === 'pending_ceo';
            const statusColor = isPending ? '#be123c' : (po.approvalStep === 'approved' ? '#16a34a' : '#d97706');
            const statusText = isPending ? '결재요청' : (po.approvalStep === 'approved' ? '승인완료' : '1차검토중');
            
            return `
              <div onclick="selectCeoPo('${po.id}')" style="background:#fff; border:1px solid ${isSelected ? '#3b82f6' : '#e2e8f0'}; border-radius:6px; padding:12px; cursor:pointer; box-shadow:${isSelected ? '0 0 0 1px #3b82f6' : '0 1px 2px rgba(0,0,0,0.05)'}; transition:all 0.15s;">
                <div style="font-size:10px; color:#64748b; margin-bottom:4px; display:flex; justify-content:space-between;">
                  <span>${po.id}</span>
                  <span style="color:${statusColor}; font-weight:700;">${statusText}</span>
                </div>
                <div style="font-size:13px; font-weight:700; color:#1e293b; margin-bottom:8px; line-height:1.3;">
                  ${po.name}
                </div>
                <div style="font-size:11px; color:#64748b; display:flex; flex-direction:column; gap:2px;">
                  <div style="display:flex; justify-content:space-between;"><span>거래처명</span><span style="font-weight:600; color:#475569;">${po.vendor}</span></div>
                  <div style="display:flex; justify-content:space-between;"><span>담당자명</span><span>${po.manager}</span></div>
                  <div style="display:flex; justify-content:space-between;"><span>합계</span><span style="font-family:monospace; font-weight:700;">${po.total.toLocaleString()}원</span></div>
                  <div style="display:flex; justify-content:space-between;"><span>요청일</span><span>${po.date}</span></div>
                </div>
              </div>
            `;
          }).join('');
          
          // Select first pending if none selected
          if (!selectedCeoPoId) {
             const pending = PO_APPROVAL_DATA.find(p => p.approvalStep === 'pending_ceo');
             if (pending) selectCeoPo(pending.id);
             else if (PO_APPROVAL_DATA.length > 0) selectCeoPo(PO_APPROVAL_DATA[0].id);
          } else {
             renderCeoDetail();
             renderCeoWorkspace();
          }
        }
        
        function selectCeoPo(poId) {
          selectedCeoPoId = poId;
          renderCeoView(); // re-render list for selection border
        }

        function renderCeoDetail() {
          const pane = document.getElementById('ceo-detail-pane');
          if (!pane || !selectedCeoPoId) return;
          
          const po = PO_APPROVAL_DATA.find(p => p.id === selectedCeoPoId);
          if (!po) return;
          
          const isPending = po.approvalStep === 'pending_ceo';
          const supply = Math.round(po.total / 1.1);
          const vat = po.total - supply;
          
          // Generate items HTML matching the image (품목명, 단위, 수량, 합계, 프로젝트명)
          const itemsHtml = (po._cartItems && po._cartItems.length > 0) ? po._cartItems.slice(0,4).map(it => `
            <tr>
              <td style="padding:6px; border-bottom:1px solid #f1f5f9;">${it.name}</td>
              <td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center;">${it.unit||'EA'}</td>
              <td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center;">${it.qty||1}</td>
              <td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:right; font-family:monospace;">${((it.price||0)*(it.qty||1)).toLocaleString()}</td>
              <td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center; font-size:10px;">보령-농협</td>
            </tr>
          `).join('') : `
            <tr>
              <td style="padding:6px; border-bottom:1px solid #f1f5f9;">베어링</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center;">EA</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center;">10</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:right;">600,000</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center; font-size:10px;">보령-농협</td>
            </tr>
            <tr>
              <td style="padding:6px; border-bottom:1px solid #f1f5f9;">커플링</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center;">EA</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center;">20</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:right;">1,080</td><td style="padding:6px; border-bottom:1px solid #f1f5f9; text-align:center; font-size:10px;">보령-농협</td>
            </tr>
          `;

          pane.innerHTML = `
            <div style="font-size:14px; font-weight:800; color:#1e293b; margin-bottom:12px;">조달청 거리측정기 납품건 발주</div>
            
            <table style="width:100%; border-collapse:collapse; font-size:11px; margin-bottom:16px; border-top:2px solid #94a3b8; border-bottom:1px solid #94a3b8;">
              <thead>
                <tr style="background:#f8fafc;">
                  <th style="padding:8px 6px; text-align:left; border-bottom:1px solid #e2e8f0;">품목명</th>
                  <th style="padding:8px 6px; border-bottom:1px solid #e2e8f0;">단위</th>
                  <th style="padding:8px 6px; border-bottom:1px solid #e2e8f0;">수량</th>
                  <th style="padding:8px 6px; text-align:right; border-bottom:1px solid #e2e8f0;">합계<br>(부가세 별도)</th>
                  <th style="padding:8px 6px; border-bottom:1px solid #e2e8f0;">프로젝트명</th>
                </tr>
              </thead>
              <tbody>
                ${itemsHtml}
              </tbody>
            </table>
            
            <div style="display:flex; flex-direction:column; gap:12px; margin-bottom:24px;">
              <div style="display:flex; gap:12px;">
                <div style="width:60px; font-size:11px; color:#64748b; font-weight:600; padding-top:8px;">내부용 메모</div>
                <div style="flex:1; background:#f8fafc; border:1px solid #e2e8f0; padding:8px 12px; font-size:12px; min-height:40px; border-radius:4px;">
                  추가 수수료가 없고 커플링, 볼조인트 단가 할인율이 큼
                </div>
              </div>
              <div style="display:flex; gap:12px;">
                <div style="width:60px; font-size:11px; color:#64748b; font-weight:600; padding-top:8px;">담당자 의견</div>
                <div style="flex:1; background:#f8fafc; border:1px solid #e2e8f0; padding:8px 12px; font-size:12px; min-height:40px; border-radius:4px;">
                  ${po.mgrComment || '계약금 2,000,000 지급 요청건 입니다. 추후 지급 요청 드리겠습니다.'}
                </div>
              </div>
              <div style="display:flex; gap:12px;">
                <div style="width:60px; font-size:11px; color:#64748b; font-weight:600; padding-top:8px;">대표님 의견</div>
                <div style="flex:1;">
                  ${isPending ? 
                    `<textarea id="ceo-pane-comment" placeholder="입력해 주세요." style="width:100%; border:1px solid #e2e8f0; border-radius:4px; padding:8px 12px; font-size:12px; font-family:inherit; min-height:60px; outline:none;"></textarea>`
                  : `<div style="background:#f0fdf4; border:1px solid #86efac; padding:8px 12px; font-size:12px; min-height:40px; border-radius:4px; color:#14532d;">${po.ceoComment}</div>`
                  }
                </div>
              </div>
            </div>
            
            ${isPending ? `
            <div style="display:flex; justify-content:center; gap:8px; margin-top:auto;">
              <button class="btn" onclick="submitCeoPaneReview('reject')" style="background:#fff; border:1px solid #e2e8f0; width:100px; justify-content:center; font-weight:700;">반려</button>
              <button class="btn" onclick="submitCeoPaneReview('approve')" style="background:#0f172a; color:#fff; border:none; width:100px; justify-content:center; font-weight:700;">승인</button>
            </div>
            ` : ''}
          `;
        }

        function submitCeoPaneReview(action) {
          const po = PO_APPROVAL_DATA.find(p => p.id === selectedCeoPoId);
          if (!po) return;
          const comment = document.getElementById('ceo-pane-comment')?.value?.trim();
          if (action === 'reject' && !comment) {
            toast('반려 사유를 입력해주세요.');
            document.getElementById('ceo-pane-comment').style.borderColor = '#ef4444';
            return;
          }
          const finalComment = comment || (action === 'approve' ? '검토 완료. 승인합니다.' : '');
          po.approvalStep = action === 'approve' ? 'approved' : 'rejected';
          po.ceoComment = finalComment;
          toast(action === 'approve' ? '✅ 발주가 승인되었습니다.' : '❌ 반려 처리되었습니다.');
          addLog(`대표이사 ${action === 'approve'?'승인':'반려'}: ${po.id}`);
          if (po.isMain && action === 'approve') {
             state.poMemoCeo = finalComment;
             loadPoDetail(po.vendor, state.poItems, '승인완료');
             syncToFinance();
          }
          renderCeoView();
        }

        function renderCeoWorkspace() {
          const tbody = document.getElementById('ceo-workspace-items');
          if (!tbody) return;
          
          const po = PO_APPROVAL_DATA.find(p => p.id === selectedCeoPoId);
          const isPending = po && po.approvalStep === 'pending_ceo';

          // Render mockup items similar to the screenshot workspace table
          tbody.innerHTML = `
            <tr style="background:${isPending ? '#fffbeb' : '#fff'}; transition:all 0.3s;">
              <td style="text-align:center;"><input type="checkbox" checked disabled></td>
              <td style="text-align:center;">1</td>
              <td style="padding:4px;"><div style="display:flex;flex-direction:column;gap:4px;">
                <div style="background:#f1f5f9;border:1px solid #e2e8f0;padding:2px 6px;border-radius:4px;font-size:10px;">우측통 세트</div>
                <div style="background:#f1f5f9;border:1px solid #e2e8f0;padding:2px 6px;border-radius:4px;font-size:10px;margin-left:10px;display:flex;align-items:center;gap:4px;"><span class="badge badge-amber" style="padding:1px 4px;">국내</span> 렌즈형태 및 본체...</div>
                <div style="background:#f1f5f9;border:1px solid #e2e8f0;padding:2px 6px;border-radius:4px;font-size:10px;margin-left:10px;display:flex;align-items:center;gap:4px;"><span class="badge badge-gray" style="padding:1px 4px;">해외</span> 방수 케이스...</div>
              </div></td>
              <td><span class="badge badge-green" style="font-size:10px;">발주 승인 완료</span></td>
              <td>진행완료</td>
              <td style="color:#2563eb;">4111161301</td>
              <td style="font-weight:600;">방탄용 레이저 측정기</td>
              <td>규격서 참조</td>
              <td>EL RANGE 8*42 TA</td>
              <td>SWAROVSKI OPTIK</td>
              <td style="text-align:center;">SET</td>
            </tr>
            <tr style="background:${isPending ? '#f0fdfa' : '#fff'}; border-left:3px solid #0d9488; transition:all 0.3s;">
              <td style="text-align:center;"><input type="checkbox" checked disabled></td>
              <td style="text-align:center;">2</td>
              <td style="padding:4px;"><div style="display:flex;flex-direction:column;gap:4px;">
                <div style="background:#fff;border:1px solid #0d9488;padding:2px 6px;border-radius:4px;font-size:10px;color:#0f766e;font-weight:600;">베어링 (발주서 하이라이트)</div>
                <div style="background:#f1f5f9;border:1px solid #e2e8f0;padding:2px 6px;border-radius:4px;font-size:10px;margin-left:10px;display:flex;align-items:center;gap:4px;"><span class="badge badge-amber" style="padding:1px 4px;">국내</span> 베어링 (발주대기)</div>
              </div></td>
              <td><span class="badge badge-purple" style="font-size:10px;">발주 대기</span></td>
              <td>발주진행중</td>
              <td style="color:#2563eb;">1221615161</td>
              <td style="font-weight:600;">베어링</td>
              <td>62322Z</td>
              <td>NSK,NYN</td>
              <td>-</td>
              <td style="text-align:center;">EA</td>
            </tr>
          `;
        }

        // ===================== 데이터 =====================
        const ITEMS_50 = [
          { name: '노트북 LG 그램 16', model: '16Z90R-K.AA5SK3', qty: 5, unit: 'EA', note: '' },
          { name: '노트북 삼성 갤럭시북4', model: 'NT960XGK-K71A', qty: 3, unit: 'EA', note: '' },
          { name: '무선 마우스 로지텍', model: 'MX Master 3S', qty: 20, unit: 'EA', note: '' },
          { name: '유선 키보드', model: 'Leopold FC750R', qty: 15, unit: 'EA', note: '' },
          { name: '무선 키보드', model: 'Apple Magic Keyboard', qty: 10, unit: 'EA', note: '한글/영문 혼용' },
          { name: '27인치 모니터', model: 'LG 27GP850-B', qty: 8, unit: 'EA', note: '144Hz IPS' },
          { name: '32인치 4K 모니터', model: 'Dell U3223QE', qty: 4, unit: 'EA', note: '' },
          { name: 'USB-C 허브 7in1', model: 'Anker A8346', qty: 25, unit: 'EA', note: '' },
          { name: 'USB-C 허브 4in1', model: 'Ugreen CM136', qty: 15, unit: 'EA', note: '' },
          { name: '모니터암 싱글', model: 'Ergotron LX', qty: 10, unit: 'EA', note: '' },
          { name: '모니터암 듀얼', model: 'North Bayou F160', qty: 5, unit: 'EA', note: '' },
          { name: '노트북 거치대', model: 'Nexstand K2', qty: 12, unit: 'EA', note: '' },
          { name: '웹캠 FHD', model: 'Logitech C920s', qty: 8, unit: 'EA', note: '화상회의용' },
          { name: 'USB 마이크', model: 'Blue Yeti Nano', qty: 4, unit: 'EA', note: '' },
          { name: '노이즈캔슬링 헤드셋', model: 'Sony WH-1000XM5', qty: 6, unit: 'EA', note: '' },
          { name: '무선 이어폰', model: 'Apple AirPods Pro 2', qty: 5, unit: 'EA', note: '' },
          { name: '외장 SSD 1TB', model: 'Samsung T7 Shield', qty: 10, unit: 'EA', note: '' },
          { name: '외장 HDD 4TB', model: 'WD My Passport', qty: 5, unit: 'EA', note: '' },
          { name: 'USB 메모리 64GB', model: 'SanDisk Ultra', qty: 30, unit: 'EA', note: '' },
          { name: 'USB 메모리 128GB', model: 'Samsung Bar Plus', qty: 20, unit: 'EA', note: '' },
          { name: '멀티탭 6구', model: 'Belkin 6-Outlet', qty: 20, unit: 'EA', note: '서지 프로텍터 포함' },
          { name: '멀티탭 3구 USB형', model: '스텔라 UPS-63', qty: 15, unit: 'EA', note: '' },
          { name: '충전기 65W USB-C', model: 'Anker Nano Pro', qty: 12, unit: 'EA', note: '' },
          { name: '충전기 140W USB-C', model: 'Apple 140W', qty: 5, unit: 'EA', note: '맥북 프로용' },
          { name: '케이블 USB-C 2m', model: 'Anker PowerLine III', qty: 40, unit: 'EA', note: '' },
          { name: '케이블 HDMI 2.1 2m', model: 'Belkin 8K', qty: 20, unit: 'EA', note: '4K@120Hz' },
          { name: '케이블 DP 1.4 2m', model: 'CableMod 8K', qty: 10, unit: 'EA', note: '' },
          { name: '마우스 패드 XL', model: 'SteelSeries QcK', qty: 15, unit: 'EA', note: '' },
          { name: '키보드 스킨', model: '범용 실리콘', qty: 20, unit: 'EA', note: '방수 실리콘' },
          { name: '모니터 클리너', model: '코리아코팅 KS-300', qty: 10, unit: 'SET', note: '스프레이+클리닝천' },
          { name: 'A4 복사용지', model: '더블에이 80g', qty: 50, unit: '박스', note: '500매×5권' },
          { name: 'A3 복사용지', model: '더블에이 80g', qty: 10, unit: '박스', note: '' },
          { name: '볼펜 세트', model: '모나미 153', qty: 20, unit: '박스', note: '12개입' },
          { name: '형광펜 세트', model: '아모스 형광', qty: 15, unit: '세트', note: '5색 세트' },
          { name: '포스트잇 3M', model: '654 76×76mm', qty: 30, unit: '묶음', note: '12패드 묶음' },
          { name: '스테이플러', model: '맥스 HD-45', qty: 8, unit: 'EA', note: '' },
          { name: '라벨 프린터', model: 'Brother PT-D610BT', qty: 3, unit: 'EA', note: '' },
          { name: '라벨 테이프', model: 'Brother TZe-231', qty: 20, unit: 'EA', note: '12mm 백지' },
          { name: '바코드 스캐너', model: 'Honeywell 1950g', qty: 4, unit: 'EA', note: '1D/2D 겸용' },
          { name: '태블릿 iPad', model: 'iPad 10세대 WiFi 64GB', qty: 3, unit: 'EA', note: '현장 모바일용' },
          { name: 'iPad 케이스', model: 'Smart Folio iPad 10세대', qty: 3, unit: 'EA', note: '' },
          { name: 'Apple Pencil', model: 'Apple Pencil 2세대', qty: 2, unit: 'EA', note: '' },
          { name: '스마트폰 거치대', model: 'Anker 540 Magnetic', qty: 10, unit: 'EA', note: '맥세이프 호환' },
          { name: '명함 스캐너', model: 'Fujitsu ScanSnap S1300i', qty: 2, unit: 'EA', note: '' },
          { name: '문서 파쇄기', model: 'Fellowes 125Ci', qty: 2, unit: 'EA', note: '5단계 보안' },
          { name: '전동 높낮이 책상', model: '플렉시스팟 E7', qty: 4, unit: 'EA', note: '전동 승강' },
          { name: '인체공학 의자', model: '허먼밀러 Aeron B', qty: 4, unit: 'EA', note: '' },
          { name: '발 받침대', model: '3M 폼 발받침', qty: 10, unit: 'EA', note: '인체공학' },
          { name: '모니터 보안 필름', model: '3M PF27.0W9', qty: 6, unit: 'EA', note: '27인치 와이드' },
          { name: 'CCTV IP카메라', model: 'Hikvision DS-2CD2143G2', qty: 2, unit: 'EA', note: '4MP 실내용' },
        ];

        const VENDORS = [
          { id: 'v1', name: '㈜대성상사', ceo: '김대성', email: 'bid@daesung.co.kr', tel: '02-555-1234', fax: '02-555-1235', addr: '서울시 구로구 디지털로 123' },
          { id: 'v2', name: '㈜한솔무역', ceo: '박한솔', email: 'rfq@hansol-trade.com', tel: '02-888-5678', fax: '02-888-5679', addr: '서울시 영등포구 경인로 456' },
          { id: 'v3', name: '㈜미래기술', ceo: '이미래', email: 'purchase@miratech.kr', tel: '031-777-9000', fax: '031-777-9001', addr: '경기도 판교 테크노밸리 789' },
          { id: 'v4', name: '㈜글로벌서플라이', ceo: '최글로', email: 'supply@global-sup.co.kr', tel: '02-111-2222', fax: '02-111-2223', addr: '서울시 마포구 양화로 12' },
          { id: 'v5', name: '㈜디지털파트너', ceo: '정디지', email: 'bid@dpartner.co.kr', tel: '02-333-4444', fax: '', addr: '서울시 성동구 성수동 34' },
          { id: 'v6', name: '㈜스마트오피스', ceo: '강스마', email: 'rfq@smartoffice.kr', tel: '02-555-6666', fax: '02-555-6667', addr: '서울시 강남구 테헤란로 56' },
          { id: 'v7', name: '㈜코리아IT', ceo: '윤코리', email: 'sales@korea-it.com', tel: '02-777-8888', fax: '02-777-8889', addr: '서울시 중구 세종대로 78' },
          { id: 'v8', name: '㈜베스트서플라이', ceo: '임베스', email: 'best@supply.co.kr', tel: '02-999-0000', fax: '02-999-0001', addr: '서울시 용산구 한강대로 90' },
        ];

        // ===================== 상태 =====================
        let state = {
          activePage: 'pg-project-manage',
          currentProject: 'G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매',
          items: ITEMS_50.slice(0, 15),
          selectedVendors: [],
          rfqCreated: false,
          rfqSent: false,
          vatPolicy: '별도',
          vendorStatuses: {},  // id -> {status, amount, amountVat}
          blockTarget: null,
          approvalStatus: 'drafting',
          poItems: [],
          specialCosts: [],
          poStatus: '작성중',
          poFinanceSync: null,
          poRefundMode: false,
          poRefundQtys: {},
          poRefundReason: '',
          poRefundRequestStatus: null, // null | requested | approved
          poMemoInternal: '',
          poMemoManager: '',
          poMemoCeo: ''
        };

        const VENDOR_IDS_SELECTED = ['v1', 'v2', 'v3', 'v4', 'v5'];
        let RFQP_LIST = [
          { no: 'RFQP-2026-0089', name: 'G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매', items: 15, vendors: 3, status: '발송완료', replied: '1/3', date: '2026-05-08' },
          { no: 'RFQP-2026-0088', name: '주름관 등 155품목 구매', items: 15, vendors: 3, status: '회신완료', replied: '3/3', date: '2026-05-08' },
          { no: 'RFQP-2026-0087', name: '[202605541] 2026년 국토교통정보 통합시스템 IT인프라 구축', items: 12, vendors: 3, status: '발송완료', replied: '1/3', date: '2026-05-08' },
          { no: 'RFQP-2026-0086', name: '팝업 품목 리스트', items: 8, vendors: 5, status: '발송완료', replied: '2/5', date: '2026-05-08' },
          { no: 'RFQP-2026-0085', name: '입출고 수정 테스트 프로젝트 1777523941', items: 5, vendors: 2, status: '작성중', replied: '0/2', date: '2026-05-08' },
        ];

        // 거래처 회신 시뮬레이션 데이터
        let VENDOR_REPLIES = {
          v1: { name: '㈜대성상사', subtotal: 0, status: '입력대기중', supply_na: 0, supply_alt: 0 },
          v2: { name: '㈜한솔무역', subtotal: 36850000, status: '회신완료', supply_na: 0, supply_alt: 1 },
          v3: { name: '㈜미래기술', subtotal: 0, status: '기한만료', supply_na: 0, supply_alt: 0 },
          v4: { name: '㈜글로벌서플라이', subtotal: 12500000, status: '회신완료', supply_na: 1, supply_alt: 0 },
          v5: { name: '㈜디지털파트너', subtotal: 0, status: '입력대기중', supply_na: 0, supply_alt: 0 },
          v6: { name: '㈜스마트오피스', subtotal: 0, status: '기한만료', supply_na: 0, supply_alt: 0 },
          v7: { name: '㈜코리아IT', subtotal: 0, status: '기한만료', supply_na: 0, supply_alt: 0 },
          v8: { name: '㈜베스트서플라이', subtotal: 42000000, status: '회신완료', supply_na: 0, supply_alt: 2 },
        };

        // ===================== 초기화 =====================
        function init() {
          // ── 새로고침 시 RFQP_LIST는 초기값 유지 (시뮬레이션 초기화)
          // VENDOR_REPLIES 회신 상태는 세션 유지
          try {
            const savedReplies = localStorage.getItem('rfq_vendor_replies');
            if (savedReplies) {
              const parsed = JSON.parse(savedReplies);
              if (parsed && typeof parsed === 'object') {
                Object.assign(VENDOR_REPLIES, parsed);
              }
            }
          } catch (e) { }
          try {
            const savedBuyerState = localStorage.getItem('rfq_buyer_state');
            if (savedBuyerState) {
              const parsed = JSON.parse(savedBuyerState);
              if (parsed && typeof parsed === 'object' && parsed.vendorStatuses) {
                Object.assign(state.vendorStatuses, parsed.vendorStatuses);
              }
            }
          } catch (e) { }

          // 날짜 기본값
          const today = new Date();
          const deadline = new Date(today); deadline.setDate(today.getDate() + 7);
          const deadlineEl = document.getElementById('rfq-deadline');
          if (deadlineEl) deadlineEl.value = deadline.toISOString().split('T')[0];
          const rfqpNameEl = document.getElementById('rfqp-name');
          if (rfqpNameEl) rfqpNameEl.value = '2026년 5월 IT장비 일괄구매';
          const poDateEl = document.getElementById('po-date');
          if (poDateEl) poDateEl.value = today.toISOString().split('T')[0];

          renderBasicInfo(state.currentProject);
          renderNeobhTable();
          renderItemsTable();
          renderRfqpList();
          renderVendorModalList();
          renderReplyTable();
          renderCompareTotal();
          renderCompareItem();
          renderCart();
          renderPoItems();
          renderPoList();

          document.addEventListener('click', closeReplyDropdowns);
          setInterval(() => {
            if (state.activePage === 'pg-po-detail') pollPoFinanceSync();
          }, 1200);

          // localStorage 동기화 수신
          window.addEventListener('storage', onStorageChange);
          // 주기적으로 상태 브로드캐스트
          setInterval(broadcastState, 1500);
          // vendor 제출 폴링 (storage 이벤트 미발생 케이스 커버)
          setInterval(pollVendorReply, 1000);
          broadcastState();
        }

        // ===================== localStorage 동기화 =====================
        function broadcastState() {
          try {
            // 거래처 회신 상태
            localStorage.setItem('rfq_buyer_state', JSON.stringify({
              vendorStatuses: state.vendorStatuses,
              rfqSent: state.rfqSent,
              ts: Date.now()
            }));
            // VENDOR_REPLIES만 영속화 (회신 상태는 유지)
            localStorage.setItem('rfq_vendor_replies', JSON.stringify(VENDOR_REPLIES));
          } catch (e) { }
        }
        // vendor 제출 폴링 함수 (1초마다 확인)
        let _lastVendorReplyTs = 0;
        let _lastVendorTypingTs = 0;

        // vendor.html은 항상 vendorId:'v2'(한솔무역)로 고정 발신
        // buyer에서 보낸 거래처 중 '외부입력대기' 상태인 첫 번째를 회신 대상으로 매핑
        function resolveReplyVendorId(receivedId) {
          // 1. 받은 vendorId가 현재 VENDOR_REPLIES에 있고 대기 중이면 그대로 사용
          if (VENDOR_REPLIES[receivedId] && VENDOR_REPLIES[receivedId].status !== '입력완료') {
            return receivedId;
          }
          // 2. 현재 rfqp의 vendorIds 중 대기 중인 첫 번째 거래처로 매핑
          const entry = state.currentRfqEntry;
          if (entry && entry.vendorIds) {
            const waiting = entry.vendorIds.find(id =>
              VENDOR_REPLIES[id] && VENDOR_REPLIES[id].status !== '입력완료'
            );
            if (waiting) return waiting;
          }
          // 3. fallback: VENDOR_REPLIES 전체에서 대기 중인 첫 번째
          return Object.keys(VENDOR_REPLIES).find(id =>
            VENDOR_REPLIES[id].status === '외부입력대기' || VENDOR_REPLIES[id].status === '외부입력중'
          ) || receivedId;
        }

        function pollVendorReply() {
          try {
            // 제출 완료 확인
            const replyRaw = localStorage.getItem('rfq_vendor_reply');
            if (replyRaw) {
              const d = JSON.parse(replyRaw);
              if (d && d.ts && d.ts !== _lastVendorReplyTs) {
                _lastVendorReplyTs = d.ts;
                const targetId = resolveReplyVendorId(d.vendorId);
                if (targetId && VENDOR_REPLIES[targetId]) {
                  const prevStatus = VENDOR_REPLIES[targetId].status;
                  if (prevStatus !== '입력완료') {
                    VENDOR_REPLIES[targetId].subtotal = d.subtotal;
                    VENDOR_REPLIES[targetId].status = '입력완료';
                    VENDOR_REPLIES[targetId].supply_na = d.supply_na || 0;
                    VENDOR_REPLIES[targetId].supply_alt = d.supply_alt || 0;
                    renderReplyTable();
                    renderCompareTotal();
                    renderCompareItem();
                    syncRfqListStatus();
                    broadcastState();
                    addLog(`거래처(${VENDOR_REPLIES[targetId].name}) 견적 제출 완료 ✅`);
                    toast(`✅ ${VENDOR_REPLIES[targetId].name} 견적 제출 완료!`);
                    updateRepliedCount();
                  }
                }
              }
            }
            // 입력 중 상태 확인
            const typingRaw = localStorage.getItem('rfq_vendor_typing');
            if (typingRaw) {
              const d = JSON.parse(typingRaw);
              if (d && d.ts && d.ts !== _lastVendorTypingTs && (Date.now() - d.ts) < 10000) {
                _lastVendorTypingTs = d.ts;
                const targetId = resolveReplyVendorId(d.vendorId);
                if (targetId && VENDOR_REPLIES[targetId] &&
                  VENDOR_REPLIES[targetId].status === '외부입력대기') {
                  VENDOR_REPLIES[targetId].status = '외부입력중';
                  renderReplyTable();
                }
              }
            }
          } catch (e) { }
        }

        function onStorageChange(e) {
          if (e.key === 'rfq_vendor_reply') {
            try {
              const d = JSON.parse(e.newValue);
              if (d && d.vendorId) {
                VENDOR_REPLIES[d.vendorId].subtotal = d.subtotal;
                VENDOR_REPLIES[d.vendorId].status = '입력완료';
                VENDOR_REPLIES[d.vendorId].supply_na = d.supply_na || 0;
                VENDOR_REPLIES[d.vendorId].supply_alt = d.supply_alt || 0;
                renderReplyTable();
                renderCompareTotal();
                renderCompareItem();
                addLog(`거래처(${VENDOR_REPLIES[d.vendorId].name}) 견적 최종 제출 완료 (외부 입력)`);
                toast(`✅ ${VENDOR_REPLIES[d.vendorId].name} 견적 제출 완료!`);
                updateRepliedCount();
                // ② RFQP_LIST 상태 실시간 갱신
                syncRfqListStatus();
              }
            } catch (e) { }
          }
          if (e.key === 'rfq_vendor_typing') {
            try {
              const d = JSON.parse(e.newValue);
              if (d && d.vendorId && VENDOR_REPLIES[d.vendorId].status === '외부입력대기') {
                VENDOR_REPLIES[d.vendorId].status = '외부입력중';
                renderReplyTable();
              }
            } catch (e) { }
          }
        }

        // ===================== 품목 테이블 =====================
        function renderItemsTable() {
          const tbody = document.getElementById('items-tbody');
          if (!tbody) return;
          tbody.innerHTML = state.items.map((item, i) => `
    <tr>
      <td style="color:#94a3b8;font-size:11px;">${i + 1}</td>
      <td><input type="text" value="${item.name}" oninput="state.items[${i}].name=this.value" style="min-width:160px;"></td>
      <td><input type="text" value="${item.model}" oninput="state.items[${i}].model=this.value" placeholder="선택 입력"></td>
      <td><input type="number" value="${item.qty}" min="1" oninput="state.items[${i}].qty=+this.value" style="width:70px;text-align:right;"></td>
      <td>
        <select oninput="state.items[${i}].unit=this.value" style="width:58px;">
          ${['EA', 'SET', '박스', '묶음', '세트', '권', '개'].map(u => `<option ${item.unit === u ? 'selected' : ''}>${u}</option>`).join('')}
        </select>
      </td>
      <td><input type="text" value="${item.note}" oninput="state.items[${i}].note=this.value" placeholder="요청사항"></td>
      <td><button class="btn btn-danger btn-sm" onclick="removeItem(${i})">✕</button></td>
    </tr>
  `).join('');
          document.getElementById('item-count-badge').textContent = state.items.length + '건';
        }

        function addItem() {
          state.items.push({ name: '', model: '', qty: 1, unit: 'EA', note: '' });
          renderItemsTable();
          setTimeout(() => { const rows = document.querySelectorAll('#items-tbody tr'); if (rows.length) rows[rows.length - 1].querySelector('input').focus(); }, 50);
        }
        function removeItem(i) { state.items.splice(i, 1); renderItemsTable(); }
        function clearItems() { if (confirm('품목 목록을 초기화하시겠습니까?')) { state.items = []; renderItemsTable(); } }

        // ===================== NEO BH 메인 테이블 =====================
        function renderNeobhTable() {
          const tbody = document.getElementById('neobh-tbody');
          if (!tbody) return;
          tbody.innerHTML = state.items.slice(0, 15).map((item, i) => `
    <tr>
      <td><input type="checkbox"></td>
      <td style="color:#94a3b8;font-size:11px;">${i + 1}</td>
      <td style="text-align:left; font-weight:500;">
        ${item.name} <button class="btn-nested" style="margin-left:4px;">하위추가</button>
      </td>
      <td><span class="badge-domestic">국내수급</span></td>
      <td class="font-mono" style="font-size:11px; color:#64748b;">${item.model || 'MAT-' + (1000 + i)}</td>
      <td style="text-align:left;">${item.name}</td>
      <td style="font-size:11px; color:#64748b;">${item.note || '표준 규격'}</td>
      <td></td>
      <td></td>
      <td></td>
      <td><button class="btn-nested" style="color:#64748b; border:none; background:transparent;">&gt;</button></td>
    </tr>
  `).join('');
        }
        function toggleAllNeobh(masterCb) {
          document.querySelectorAll('#neobh-tbody input[type="checkbox"]').forEach(cb => { cb.checked = masterCb.checked; });
        }

        // ===================== VAT =====================
        function selectVat(el, val) {
          document.querySelectorAll('.vat-btn').forEach(b => b.classList.remove('selected'));
          el.classList.add('selected');
          state.vatPolicy = val;
        }

        // ===================== 거래처 선택 =====================
        function openModal(id) {
          const el = document.getElementById(id);
          if (el) el.classList.add('open');
        }
        function closeModal(id) {
          const el = document.getElementById(id);
          if (el) el.classList.remove('open');
        }

        // 드래그 기능 구현
        function makeDraggable(el, handle) {
          let pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;
          handle.onmousedown = dragMouseDown;

          function dragMouseDown(e) {
            e = e || window.event;
            if (e.target.closest('button')) return; // 버튼 클릭시 드래그 방지

            // 초기 transform 제거 및 좌표 고정
            if (el.style.transform !== 'none') {
              const rect = el.getBoundingClientRect();
              el.style.transform = 'none';
              el.style.top = rect.top + 'px';
              el.style.left = rect.left + 'px';
              el.style.margin = '0';
            }

            pos3 = e.clientX;
            pos4 = e.clientY;
            document.onmouseup = closeDragElement;
            document.onmousemove = elementDrag;
          }

          function elementDrag(e) {
            e = e || window.event;
            e.preventDefault();
            pos1 = pos3 - e.clientX;
            pos2 = pos4 - e.clientY;
            pos3 = e.clientX;
            pos4 = e.clientY;
            el.style.top = (el.offsetTop - pos2) + "px";
            el.style.left = (el.offsetLeft - pos1) + "px";
          }

          function closeDragElement() {
            document.onmouseup = null;
            document.onmousemove = null;
          }
        }

        // 페이지 로드 후 드래그 활성화 및 모달 위치 이동 (숨김 부모의 display:none 상속 방지)
        window.addEventListener('DOMContentLoaded', () => {
          document.querySelectorAll('.modal-bg, .popup-window-bg').forEach(m => document.body.appendChild(m));

          const rfqModal = document.querySelector('#rfq-request-modal .popup-window');
          const rfqHeader = document.getElementById('rfq-request-header');
          if (rfqModal && rfqHeader) makeDraggable(rfqModal, rfqHeader);
        });

        function renderVendorModalList() {
          const q = document.getElementById('vendor-search')?.value?.toLowerCase() || '';
          const filtered = VENDORS.filter(v => v.name.toLowerCase().includes(q) || v.ceo.toLowerCase().includes(q));
          document.getElementById('vendor-modal-list').innerHTML = `
    <table><thead><tr><th style="width:36px;">선택</th><th>거래처명</th><th>대표자</th><th>이메일</th></tr></thead>
    <tbody>${filtered.map(v => `
      <tr>
        <td><input type="checkbox" class="vendor-check" value="${v.id}" ${state.selectedVendors.includes(v.id) ? 'checked' : ''} onchange="updateVendorCheckCount()"></td>
        <td><strong>${v.name}</strong></td><td>${v.ceo}</td><td class="text-muted font-mono" style="font-size:11px;">${v.email}</td>
      </tr>
    `).join('')}</tbody></table>`;
          updateVendorCheckCount();
        }
        function filterVendors() { renderVendorModalList(); }
        function updateVendorCheckCount() {
          const cnt = document.querySelectorAll('.vendor-check:checked').length;
          document.getElementById('vendor-check-cnt').textContent = cnt;
        }
        function confirmVendors() {
          state.selectedVendors = [...document.querySelectorAll('.vendor-check:checked')].map(c => c.value);
          closeModal('vendor-modal');
          renderSelectedVendors();
          document.getElementById('vendor-sel-count').textContent = state.selectedVendors.length + '개 선택';
        }
        function renderSelectedVendors() {
          const area = document.getElementById('selected-vendors-area');
          document.getElementById('no-vendor-msg')?.remove();
          if (state.selectedVendors.length === 0) { area.innerHTML = '<div class="text-muted text-sm" style="padding:16px 0;text-align:center;">선택된 거래처가 없습니다.</div>'; return; }
          area.innerHTML = state.selectedVendors.map(id => {
            const v = VENDORS.find(x => x.id === id);
            return `<div class="vendor-card"><div><strong>${v.name}</strong> <span class="text-xs text-muted">${v.ceo}</span></div><div class="text-xs font-mono text-muted">${v.email}</div><button class="btn btn-danger btn-sm" onclick="removeVendor('${id}')">제거</button></div>`;
          }).join('');
        }
        function removeVendor(id) { state.selectedVendors = state.selectedVendors.filter(x => x !== id); renderSelectedVendors(); document.getElementById('vendor-sel-count').textContent = state.selectedVendors.length + '개 선택'; }

        // ===================== 견적서 생성/송부 =====================
        function createRfq() {
          if (state.items.length === 0) { toast('품목을 등록해주세요.'); return; }
          if (state.selectedVendors.length === 0) { toast('거래처를 선택해주세요.'); return; }
          state.rfqCreated = true;
          document.getElementById('send-rfq-btn').disabled = false;
          document.getElementById('send-status-msg').textContent = `✅ ${state.selectedVendors.length}개사 견적서 생성 완료. 이제 송부 버튼을 클릭하세요.`;
          addLog(`견적서 ${state.selectedVendors.length}개사 생성 (품목 ${state.items.length}개)`);
          openRfqPreview();
        }

        function openRfqPreview(vendorId) {
          const vId = vendorId || state.selectedVendors[0];
          const vendor = VENDORS.find(v => v.id === vId) || VENDORS[0];
          const today = new Date().toLocaleDateString('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit' }).replace(/\. /g, '-').replace('.', '');
          const deadlineEl = document.getElementById('rfq-deadline');
          const deadline = deadlineEl ? deadlineEl.value : '2026-06-09';
          const rfqpNameEl = document.getElementById('rfqp-name');
          const rfqpName = rfqpNameEl ? rfqpNameEl.value : '2026년 5월 IT장비 일괄구매';
          const estNo = 'NB_251021_E_47';
          const tdS = 'padding:8px 10px;border:1px solid #ddd;font-size:12px;';
          const thS = 'padding:8px 10px;border:1px solid #555;background:#f0f0f0;font-size:12px;font-weight:600;text-align:center;';
          const emptyRow = `<tr>${Array(8).fill(`<td style="${tdS}">&nbsp;</td>`).join('')}</tr>`;
          const emptyRowCount = Math.max(0, 8 - Math.min(state.items.length, 10));
          // 견적요청 모달 품목 수집 (상세 테이블 기준)
          const rfqReqRows = [...(document.querySelectorAll('#rfq-req-tbody tr') || [])];
          let previewItems = rfqReqRows.map(tr => {
            const cells = tr.querySelectorAll('td');
            return {
              name: cells[2]?.innerText?.replace('하위추가', '')?.trim() || '',
              model: cells[3]?.textContent?.trim() || '',
              unit: cells[6]?.textContent?.trim() || 'EA',
              qty: cells[7]?.querySelector('input')?.value || '1',
              note: cells[8]?.querySelector('input')?.value || ''
            };
          }).filter(item => item.name);

          const project = PROJECT_DATA[state.currentProject] || PROJECT_DATA[Object.keys(PROJECT_DATA)[0]];
          const sourceItems = previewItems.length > 0 ? previewItems : (project.items || []).slice(0, 10);
          const actualEmptyCount = Math.max(0, 8 - Math.min(sourceItems.length, 10));
          const itemRows = sourceItems.slice(0, 10).map((item, i) => `
    <tr>
      <td style="${tdS}text-align:center;">${i + 1}</td>
      <td style="${tdS}">${item.name}</td>
      <td style="${tdS}font-size:11px;">${item.model || ''}</td>
      <td style="${tdS}text-align:center;">${item.unit}</td>
      <td style="${tdS}text-align:center;">${item.qty}</td>
      <td style="${tdS}text-align:right;background:#f0f4ff;"></td>
      <td style="${tdS}text-align:right;background:#f0f4ff;"></td>
      <td style="${tdS}font-size:11px;">${item.note || ''}</td>
    </tr>`).join('') + Array(actualEmptyCount).fill(emptyRow).join('');

          const logoSvg = `<img src="data:image/png;base64,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" alt="NEO BH" style="height:52px;object-fit:contain;">`;
          const previewEl = document.getElementById('rfq-preview-body');
          if (!previewEl) return;
          previewEl.innerHTML = `
  <div style="background:#fff;font-family:'Malgun Gothic','Apple SD Gothic Neo',sans-serif;max-width:760px;margin:0 auto;">
    <div style="display:flex;align-items:center;justify-content:space-between;padding:16px 24px;border-bottom:3px solid #e8501a;">
      ${logoSvg}
      <div style="font-size:11px;color:#444;text-align:right;line-height:1.8;">
        주소: 경기도 김포시 고촌읍 전호로 32 | 사업자번호: 822-87-00677 | 홈페이지: www.neobh.kr<br>
        TEL: 031-987-3069 | FAX: 031-998-3069 | E-mail: balhea@balhea.kr
      </div>
    </div>
    <div style="text-align:center;padding:18px 0 14px;font-size:22px;font-weight:700;letter-spacing:8px;">견 적 요 청 서</div>
    <div style="display:flex;justify-content:space-between;padding:0 20px 10px;font-size:12px;"><div>견적일자: <strong>${today}</strong></div><div>No. <strong>${estNo}</strong></div></div>
    <div style="display:grid;grid-template-columns:1fr 1fr;margin:0 20px 14px;border:1px solid #aaa;">
      <div style="border-right:1px solid #aaa;">
        <div style="background:#f0f0f0;text-align:center;padding:6px;font-size:12px;font-weight:700;border-bottom:1px solid #aaa;">수신처 (거래처)</div>
        <table style="width:100%;border-collapse:collapse;font-size:12px;">
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;width:60px;">업체명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;font-weight:600;">${vendor.name}</td></tr>
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;">연락처</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;">${vendor.tel || '—'}</td></tr>
          <tr><td style="padding:5px 10px;color:#555;">건명</td><td style="padding:5px 10px;">${rfqpName}</td></tr>
        </table>
      </div>
      <div>
        <div style="background:#f0f0f0;text-align:center;padding:6px;font-size:12px;font-weight:700;border-bottom:1px solid #aaa;">발신처 (발주사)</div>
        <table style="width:100%;border-collapse:collapse;font-size:12px;">
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;width:60px;">상호명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;font-weight:600;">네오비에이치</td></tr>
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;">대표자명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;">장재용</td></tr>
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;">담당자명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;">발해futech</td></tr>
          <tr><td style="padding:5px 10px;color:#555;">연락처</td><td style="padding:5px 10px;">031-987-3069</td></tr>
        </table>
      </div>
    </div>
    <div style="padding:4px 20px 10px;font-size:12px;">아래와 같이 견적을 요청합니다.</div>

    <div style="margin:0 20px;overflow-x:auto;">
      <table style="width:100%;border-collapse:collapse;">
        <thead><tr>
          <th style="${thS}width:36px;">No</th><th style="${thS}">품명</th><th style="${thS}">규격</th>
          <th style="${thS}width:50px;">단위</th><th style="${thS}width:50px;">수량</th>
          <th style="${thS}width:80px;background:#e8f0ff;">단가</th><th style="${thS}width:90px;background:#e8f0ff;">합계</th>
          <th style="${thS}">비고</th>
        </tr></thead>
        <tbody>${itemRows}</tbody>
      </table>
    </div>
  </div>`;
          document.getElementById('rfq-preview-modal').classList.add('open');
        }

        function downloadRfqPdf() {
          const content = document.getElementById('rfq-preview-body').innerHTML;
          const printWindow = window.open('', '_blank');
          printWindow.document.write('<html><head><title>견적요청서 다운로드</title>');
          printWindow.document.write('<style>body{margin:0;padding:20px;font-family:sans-serif;} table{width:100%;border-collapse:collapse;} td,th{border:1px solid #ddd;padding:8px;}</style></head><body>');
          printWindow.document.write(content);
          printWindow.document.write('</body></html>');
          printWindow.document.close();
          toast('📄 견적요청서 PDF 생성을 시작합니다.');
          setTimeout(() => {
            printWindow.print();
          }, 500);
        }
        function sendRfq() {
          if (!state.rfqCreated) { toast('먼저 견적서를 생성해주세요.'); return; }
          state.rfqSent = true;
          broadcastState();
          document.getElementById('send-status-msg').textContent = `✅ ${state.selectedVendors.length}개사 이메일 자동 발송 완료! 거래처별 고유 링크 발급됨.`;
          document.getElementById('send-rfq-btn').textContent = '✓ 송부 완료';
          document.getElementById('send-rfq-btn').style.background = '#10b981';
          toast('🚀 견적서 일괄 송부 완료! 거래처에 이메일이 발송되었습니다.');
          addLog('견적서 및 외부 링크 3개사 자동 발송 완료');
          // ③ 신규 견적 RFQP_LIST에 맨 앞 등록
          _registerNewRfqToList();
          renderRfqpList();
          setTimeout(() => { showPage('pg-rfqp-detail'); }, 1200);
        }


        // ═══════════════════════════════════════════════
        // 데이터 체인 연결 함수들
        // ═══════════════════════════════════════════════

        // A. 워크스페이스 견적요청 모달 → RFQP_LIST 등록 + pg-rfqp-detail 연결
        function submitRfqRequest() {
          const checkedVendors = document.querySelectorAll('.rfq-vendor-check:checked');
          if (checkedVendors.length === 0) { toast('⚠️ 거래처를 선택해주세요.'); return; }

          const checkedItems = document.querySelectorAll('#rfq-req-tbody tr');

          // ── localStorage: 선택 품목 vendor에 전달 (정확한 인덱스로 수집) ──
          const selectedItemsForVendor = [...checkedItems].filter(tr => {
            const chk = tr.querySelector('input[type="checkbox"]');
            return chk && chk.checked;
          }).map(tr => {
            const cells = tr.querySelectorAll('td');
            // rfq-req-tbody 구조: [0]체크 [1]No [2]품목명 [3]모델 [4]규격 [5]제조사 [6]단위 [7]수량 [8]비고
            return {
              name: (cells[2]?.textContent || '').trim(),
              model: (cells[3]?.textContent || '').trim(),
              spec: (cells[4]?.textContent || '').trim(),
              unit: (cells[6]?.textContent || 'EA').trim(),
              qty: parseInt(cells[7]?.querySelector('input')?.value || cells[7]?.textContent?.trim() || '1'),
              note: (cells[8]?.querySelector('input')?.value || '').trim()
            };
          }).filter(item => item.name);

          const itemCount = selectedItemsForVendor.length;
          const vendorCount = checkedVendors.length;
          const selectedVids = [...checkedVendors].map(c => c.value);

          const vendorIdMap = {};
          selectedVids.forEach(id => {
            const v = VENDORS.find(x => x.id === id);
            if (v) vendorIdMap[id] = v.name;
          });

          try {
            localStorage.setItem('rfq_items_for_vendor', JSON.stringify(selectedItemsForVendor));
            localStorage.setItem('rfq_vendor_targets', JSON.stringify(vendorIdMap));
            localStorage.setItem('rfq_project_name', state.currentProject || '프로젝트');
            localStorage.setItem('rfq_sent_ts', Date.now().toString());
            localStorage.setItem('rfq_no', `RFQP-2026-${String(90 + RFQP_LIST.length).padStart(4, '0')}`);
          } catch (e) { }

          const projectName = state.currentProject || '프로젝트';
          const today = new Date().toISOString().split('T')[0];
          const newNo = `RFQP-2026-${String(90 + RFQP_LIST.length).padStart(4, '0')}`;

          state.selectedVendors = selectedVids;
          state.rfqCreated = true;
          state.rfqSent = true;

          // VENDOR_REPLIES 초기화: 선택된 거래처만 활성화
          selectedVids.forEach(id => {
            const v = VENDORS.find(x => x.id === id);
            if (!v) return;
            VENDOR_REPLIES[id] = {
              name: v.name,
              subtotal: 0,
              status: '외부입력대기',
              supply_na: 0,
              supply_alt: 0
            };
          });

          try {
            localStorage.removeItem('rfq_vendor_reply');
            _lastVendorReplyTs = 0;
            _lastVendorTypingTs = 0;
          } catch (e) { }

          const newEntry = {
            no: newNo, name: projectName,
            items: itemCount, vendors: vendorCount,
            status: '발송완료', replied: `0/${vendorCount}`,
            date: today, vendorIds: selectedVids, isNew: true
          };
          RFQP_LIST.unshift(newEntry);
          state.currentRfqNo = newNo;
          state.currentRfqEntry = newEntry;

          closeModal('rfq-request-modal');

          // 상세 페이지 정보 즉시 업데이트
          try {
            const nameEl = document.getElementById('detail-rfqp-name');
            if (nameEl) nameEl.textContent = `${newNo} · ${projectName}`;

            const itemCntEl = document.getElementById('det-item-cnt');
            if (itemCntEl) {
              itemCntEl.textContent = itemCount;
              itemCntEl.style.display = 'inline';
            }
            const vendorCntEl = document.getElementById('det-vendor-cnt');
            if (vendorCntEl) vendorCntEl.textContent = `${vendorCount}개사`;

            const sendDateEl = document.getElementById('det-send-date');
            if (sendDateEl) sendDateEl.textContent = today;
          } catch (e) { }

          renderReplyTable();
          updateRepliedCount();

          setTimeout(() => { showPage('pg-rfqp-detail'); }, 300);
          toast(`🚀 견적서가 ${vendorCount}개사에 발송되었습니다.`);

          try { broadcastState(); } catch (e) { }
          try { addLog(`[${newNo}] ${projectName} 견적서 ${vendorCount}개사 자동 송부 완료`); } catch (e) { }
        }



        // B. 회신 완료 → RFQP_LIST 상태 자동 갱신

        function syncRfqListStatus() {
          const currentNo = state.currentRfqNo;
          if (!currentNo) return;
          const entry = RFQP_LIST.find(r => r.no === currentNo);
          if (!entry) return;

          const allReplies = Object.values(VENDOR_REPLIES);
          const vendorIds = entry.vendorIds || Object.keys(VENDOR_REPLIES);
          const targetReplies = allReplies.filter((v, i) => vendorIds.includes(Object.keys(VENDOR_REPLIES)[i]));
          const doneCount = Object.entries(VENDOR_REPLIES)
            .filter(([id]) => vendorIds.includes(id))
            .filter(([, v]) => v.status === '입력완료').length;
          const totalCount = vendorIds.length;

          entry.replied = `${doneCount}/${totalCount}`;
          entry.status = doneCount === totalCount ? '회신완료' : '발송완료';
          renderRfqpList();
        }

        // C. 워크스페이스 sendRfq용 (pg-rfqp-new에서 사용)
        function _registerNewRfqToList() {
          const rfqpName = document.getElementById('rfqp-name')?.value || '견적기안';
          const today = new Date().toISOString().split('T')[0];
          const newNo = `RFQP-2026-${String(90 + RFQP_LIST.length).padStart(4, '0')}`;
          const alreadyExists = RFQP_LIST.find(r => r.no === newNo);
          if (alreadyExists) return;
          const newEntry = {
            no: newNo, name: rfqpName,
            items: state.items.length, vendors: state.selectedVendors.length,
            status: '발송완료', replied: `0/${state.selectedVendors.length}`,
            date: today, vendorIds: [...state.selectedVendors], isNew: true
          };
          RFQP_LIST.unshift(newEntry);
          state.currentRfqNo = newNo;
          state.currentRfqEntry = newEntry;
        }

        // ===================== 가격비교 탭 전환 =====================
        function switchPriceView(view) {
          const priceView = document.getElementById('view-price');
          const vendorView = document.getElementById('view-vendor');
          const priceBtn = document.getElementById('tab-price-btn');
          const vendorBtn = document.getElementById('tab-vendor-btn');
          if (!priceView) return;
          if (view === 'price') {
            priceView.style.display = 'block';
            vendorView.style.display = 'none';
            priceBtn.style.borderBottomColor = '#2563eb';
            priceBtn.style.color = '#2563eb';
            priceBtn.style.fontWeight = '600';
            vendorBtn.style.borderBottomColor = 'transparent';
            vendorBtn.style.color = '#94a3b8';
            vendorBtn.style.fontWeight = '500';
          } else {
            priceView.style.display = 'none';
            vendorView.style.display = 'block';
            priceBtn.style.borderBottomColor = 'transparent';
            priceBtn.style.color = '#94a3b8';
            priceBtn.style.fontWeight = '500';
            vendorBtn.style.borderBottomColor = '#2563eb';
            vendorBtn.style.color = '#2563eb';
            vendorBtn.style.fontWeight = '600';
            renderVendorDetailTable();
          }
        }

        // ===================== 거래처별 뷰 (테이블 형태) =====================
        function renderVendorDetailTable() {
          const head = document.getElementById('vendor-detail-head');
          const body = document.getElementById('vendor-detail-body');
          if (!head || !body) return;

          const project = PROJECT_DATA[state.currentProject] || PROJECT_DATA['G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매'];
          const items = project.items;
          const compareData = project.compareData || [];
          const maxRanks = VIDS.length;
          const currentRanks = Math.min(expandedRanks, maxRanks);

          let headHtml = `
        <th style="width:30px;text-align:center;">No</th>
        <th>품목명</th>
        <th>규격/모델명</th>
        <th style="width:60px;text-align:center;">수량</th>
      `;

          for (let i = 0; i < currentRanks; i++) {
            const vid = VIDS[i];
            headHtml += `<th style="width:150px;text-align:right;${i >= 3 ? 'background:#f8fafc;' : ''}" class="${i >= 3 ? 'expand-col' : ''}">${VNAMES[vid]}</th>`;
          }

          if (maxRanks > 3) {
            const moreCount = maxRanks - 3;
            headHtml += `
          <th style="width:80px;text-align:center;background:#eff6ff;cursor:pointer;" onclick="toggleColumnExpand(${maxRanks})">
            <div style="font-size:11px;color:#2563eb;font-weight:700;">
              ${expandedRanks > 3 ? '접기 ◀' : `+ ${moreCount}개 더보기 ▶`}
            </div>
          </th>
        `;
          }
          head.innerHTML = headHtml;

          body.innerHTML = items.map((item, i) => {
            const row = compareData.find(r => r.name === item.name);
            const qtyStr = row ? `${row.qty}${row.unit}` : '1EA';
            let vendorCells = '';

            for (let r = 0; r < currentRanks; r++) {
              const vid = VIDS[r];
              const price = row ? row.prices[vid] : null;
              const cartKey = `${state.currentProject}_${i}`;
              const isSelected = cart[cartKey] && cart[cartKey].vendorId === vid;

              if (price != null && price > 0) {
                const supplyQ = (row.supplyQty || {})[vid];
                const supplyNum = (supplyQ !== undefined) ? supplyQ : row.qty;
                const shortage = row.qty - supplyNum;
                const isBest = VIDS.every(v2 => v2 === vid || !row.prices[v2] || row.prices[v2] >= price);

                const vRemark = (row.vendorRemarks || {})[vid] || '';

                vendorCells += `
              <td style="text-align:right; padding:8px; border-left:1px solid #f1f5f9; ${isSelected ? 'background:#f0f7ff;' : ''}">
                <div onclick="toggleCart(${i},'${vid}',${price},${supplyNum})"
                  style="cursor:pointer; padding:6px; border:1px solid ${isSelected ? '#2563eb' : '#e2e8f0'}; border-radius:6px; background:#fff;">
                  <div style="font-size:12px; font-weight:700; color:#1e293b;">
                    ${isSelected ? '✓ ' : ''}${price.toLocaleString()}원
                    ${isBest ? '<span class="badge badge-green" style="font-size:8px;background:#16a34a;color:#fff;padding:1px 3px;border-radius:2px;margin-left:2px;">BEST</span>' : ''}
                  </div>
                  <div style="font-size:9px; color:${shortage > 0 ? '#dc2626' : '#16a34a'}; margin-top:2px;">
                    매입 ${supplyNum}개 ${shortage > 0 ? '⚠' : '✓'}
                  </div>
                  ${vRemark ? `<div style="font-size:9px;color:#7c3aed;margin-top:4px;font-weight:500;text-align:left;">💬 ${vRemark}</div>` : ''}
                </div>
              </td>`;
              } else {
                vendorCells += `<td style="text-align:right; font-size:10px; color:#cbd5e1; padding:8px; border-left:1px solid #f1f5f9; background:#fafafa;">불가 ✗</td>`;
              }
            }

            if (maxRanks > 3 && expandedRanks === 3) {
              vendorCells += `<td style="background:#f8fafc;border:1px solid #f1f5f9;"></td>`;
            }

            return `<tr>
          <td style="text-align:center; color:#94a3b8; font-size:11px;">${i + 1}</td>
          <td style="font-size:12px; font-weight:500;">${item.name}</td>
          <td style="font-size:11px; color:#64748b;">${item.model}</td>
          <td style="text-align:center; font-size:11px;">${qtyStr}</td>
          ${vendorCells}
        </tr>`;
          }).join('');
        }

        // ===================== 첨부파일 처리 =====================
        let rfqAttachFiles = [];
        let poAttachFiles = [];
        let retryAttachFiles = [];
        let poSendAttachFiles = [];

        function onRfqAttachChange(input) {
          const newFiles = [...input.files];
          rfqAttachFiles = [...rfqAttachFiles, ...newFiles];
          renderAttachList('rfq-attach-list', rfqAttachFiles, 'rfq');
          input.value = '';
          try {
            const names = rfqAttachFiles.map(f => ({ name: f.name, size: f.size, type: f.type }));
            localStorage.setItem('rfq_attach_files', JSON.stringify(names));
          } catch (e) { }
          toast(`📎 ${newFiles.length}개 파일 첨부됨`);
        }

        function onPoAttachChange(input) {
          const newFiles = [...input.files];
          poAttachFiles = [...poAttachFiles, ...newFiles];
          renderAttachList('po-attach-list', poAttachFiles, 'po');
          input.value = '';
          toast(`📎 ${newFiles.length}개 파일 첨부됨`);
        }

        function onRetryAttachChange(input) {
          const newFiles = [...input.files];
          retryAttachFiles = [...retryAttachFiles, ...newFiles];
          renderAttachList('retry-attach-list', retryAttachFiles, 'retry');
          input.value = '';
          toast(`📎 ${newFiles.length}개 파일 첨부됨`);
        }

        function onPoSendAttachChange(input) {
          const newFiles = [...input.files];
          poSendAttachFiles = [...poSendAttachFiles, ...newFiles];
          renderAttachList('po-send-attach-list', poSendAttachFiles, 'po-send');
          input.value = '';
          toast(`📎 ${newFiles.length}개 추가 파일 첨부됨`);
        }

        function renderAttachList(containerId, files, type) {
          const container = document.getElementById(containerId);
          if (!container) return;
          container.innerHTML = files.map((f, i) => `
        <div style="display:flex;align-items:center;gap:6px;padding:4px 8px;background:#f1f5f9;border-radius:6px;font-size:11px;">
          <span>📄</span>
          <span style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${f.name}</span>
          <span style="color:#94a3b8;">${(f.size / 1024).toFixed(0)}KB</span>
          <button onclick="removeAttach('${type}',${i})"
            style="background:none;border:none;cursor:pointer;color:#dc2626;font-size:12px;padding:0 2px;">✕</button>
        </div>`).join('');
        }

        function removeAttach(type, idx) {
          if (type === 'rfq') {
            rfqAttachFiles.splice(idx, 1);
            renderAttachList('rfq-attach-list', rfqAttachFiles, 'rfq');
            try { localStorage.setItem('rfq_attach_files', JSON.stringify(rfqAttachFiles.map(f => ({ name: f.name, size: f.size })))); } catch (e) { }
          } else if (type === 'retry') {
            retryAttachFiles.splice(idx, 1);
            renderAttachList('retry-attach-list', retryAttachFiles, 'retry');
          } else if (type === 'po-send') {
            poSendAttachFiles.splice(idx, 1);
            renderAttachList('po-send-attach-list', poSendAttachFiles, 'po-send');
          } else {
            poAttachFiles.splice(idx, 1);
            renderAttachList('po-attach-list', poAttachFiles, 'po');
          }
        }

        function bulkAddVendorToCart(vid) {
          const project = PROJECT_DATA[state.currentProject] || PROJECT_DATA[Object.keys(PROJECT_DATA)[0]];
          if (!project) return;
          const items = project.items;
          const compareData = project.compareData || [];
          let added = 0;
          items.forEach((item, i) => {
            const row = compareData.find(r => r.name === item.name);
            if (!row || !row.prices[vid]) return;
            const orderQ = row.qty;
            const supplyQ = (row.supplyQty || {})[vid];
            const supplyNum = supplyQ !== undefined ? supplyQ : orderQ;
            const cartKey = `${state.currentProject}_${i}`;
            cart[cartKey] = { vendorId: vid, name: item.name, qty: supplyNum, orderQty: orderQ, unit: row.unit, price: row.prices[vid], project: state.currentProject };
            added++;
          });
          renderCompareItem();
          renderCart();
          toast(`🛒 ${VNAMES[vid]} ${added}개 품목 장바구니에 담았습니다.`);
        }

        function onBulkTypeChange(val) {
          const vsel = document.getElementById('bulk-vendor-select');
          if (!vsel) return;
          if (val === 'vendor') {
            vsel.style.display = 'inline-block';
            vsel.innerHTML = `<option value="">거래처 선택</option>` +
              VIDS.map(vid => `<option value="${vid}">${VNAMES[vid]}</option>`).join('');
          } else {
            vsel.style.display = 'none';
          }
        }

        function applyBulkOrder() {
          const type = document.getElementById('bulk-order-type')?.value;
          if (!type) { toast('일괄 담기 방식을 선택하세요.'); return; }
          const project = PROJECT_DATA[state.currentProject] || PROJECT_DATA[Object.keys(PROJECT_DATA)[0]];
          if (!project) return;
          const items = project.items;
          const compareData = project.compareData || [];

          if (type === 'best') {
            let added = 0;
            items.forEach((item, i) => {
              const row = compareData.find(r => r.name === item.name);
              if (!row) return;
              const priceList = VIDS.map(vid => ({ vid, price: row.prices[vid] }))
                .filter(p => p.price != null && p.price > 0)
                .sort((a, b) => a.price - b.price);
              if (!priceList.length) return;
              const best = priceList[0];
              const supplyQ = (row.supplyQty || {})[best.vid];
              const supplyNum = supplyQ !== undefined ? supplyQ : row.qty;
              const cartKey = `${state.currentProject}_${i}`;
              cart[cartKey] = { vendorId: best.vid, name: item.name, qty: supplyNum, orderQty: row.qty, unit: row.unit, price: best.price, project: state.currentProject };
              added++;
            });
            renderCompareItem(); renderCart();
            toast(`📊 최저가 기준 ${added}개 품목 담았습니다.`);
          } else if (type === 'vendor') {
            const vid = document.getElementById('bulk-vendor-select')?.value;
            if (!vid) { toast('거래처를 선택하세요.'); return; }
            bulkAddVendorToCart(vid);
          }
        }

        // ===================== 가격비교 더보기 (가로 확장) =====================
        let expandedRanks = 3; // 기본 3순위까지 노출

        function toggleColumnExpand(totalPossible) {
          expandedRanks = (expandedRanks === 3) ? totalPossible : 3;
          renderCompareItem();
          renderVendorDetailTable();
        }

        // ===================== 발주서 엑셀 다운로드 =====================
        function downloadPoExcel() {
          try {
            const rows = [...document.querySelectorAll('#po-items-tbody tr')].map(tr => {
              const cells = tr.querySelectorAll('td');
              return {
                '품목명': cells[1]?.textContent?.trim() || '',
                '모델명': cells[2]?.textContent?.trim() || '',
                '규격': cells[3]?.textContent?.trim() || '',
                '수량': cells[6]?.textContent?.trim() || '',
                '매입단가': cells[8]?.textContent?.trim() || '',
                '합계(부가세별도)': cells[9]?.textContent?.trim() || '',
                '부가세': cells[10]?.textContent?.trim() || '',
                '합계(부가세포함)': cells[11]?.textContent?.trim() || '',
                '비고': cells[12]?.querySelector('input')?.value || cells[12]?.textContent?.trim() || ''
              };
            });

            // SheetJS 없이 CSV로 다운로드 (실제 배포 시 SheetJS 사용)
            const headers = Object.keys(rows[0] || {});
            const csv = [
              headers.join(','),
              ...rows.map(r => headers.map(h => `"${(r[h] || '').replace(/"/g, '""')}"`).join(','))
            ].join('\n');
            const bom = '\uFEFF';
            const blob = new Blob([bom + csv], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `발주서_${new Date().toISOString().split('T')[0]}.csv`;
            a.click();
            URL.revokeObjectURL(url);
            toast('📊 발주서 엑셀(CSV) 다운로드 완료');
          } catch (e) {
            toast('다운로드 실패: ' + e.message);
          }
        }

        // ===================== 견적 현황 엑셀 다운로드 =====================
        function downloadRfqExcel() {
          try {
            const body = document.getElementById('reply-table-body');
            if (!body) return;
            const rows = [...body.querySelectorAll('tr')].map(tr => {
              const cells = tr.querySelectorAll('td');
              return {
                '거래처': cells[1]?.textContent?.trim() || '',
                '외부링크': cells[2]?.textContent?.trim() || '',
                '입력상태': cells[3]?.textContent?.trim() || '',
                '메일발송상태': cells[5]?.querySelector('[data-export="mail-status"]')?.textContent?.trim() || '',
                '팩스발송상태': cells[6]?.querySelector('[data-export="fax-status"]')?.textContent?.trim() || ''
              };
            });

            if (rows.length === 0) {
              toast('다운로드할 데이터가 없습니다.');
              return;
            }

            const headers = Object.keys(rows[0]);
            const csv = [
              headers.join(','),
              ...rows.map(r => headers.map(h => `"${(r[h] || '').replace(/"/g, '""')}"`).join(','))
            ].join('\n');
            const bom = '\uFEFF';
            const blob = new Blob([bom + csv], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            const rfqNo = document.getElementById('detail-rfqp-name')?.textContent?.split(' · ')[0] || 'RFQ';
            a.download = `견적요청현황_${rfqNo}_${new Date().toISOString().split('T')[0]}.csv`;
            a.click();
            URL.revokeObjectURL(url);
            toast('📊 견적 현황 엑셀(CSV) 다운로드 완료');
          } catch (e) {
            toast('다운로드 실패: ' + e.message);
          }
        }

        // ===================== 발주서 목록 엑셀 다운로드 =====================
        function downloadPoListExcel() {
          try {
            const body = document.getElementById('po-list-body');
            if (!body) return;
            const rows = [...body.querySelectorAll('tr')].map(tr => {
              const cells = tr.querySelectorAll('td');
              return {
                'NO.': cells[0]?.textContent?.trim() || '',
                '생성일': cells[1]?.textContent?.trim() || '',
                '거래처명': cells[2]?.textContent?.trim() || '',
                '발주서명': cells[3]?.textContent?.trim() || '',
                '합계': cells[4]?.textContent?.trim() || '',
                '진행상태': cells[5]?.textContent?.trim() || ''
              };
            });

            if (rows.length === 0) {
              toast('다운로드할 데이터가 없습니다.');
              return;
            }

            const headers = Object.keys(rows[0]);
            const csv = [
              headers.join(','),
              ...rows.map(r => headers.map(h => `"${(r[h] || '').replace(/"/g, '""')}"`).join(','))
            ].join('\n');
            const bom = '\uFEFF';
            const blob = new Blob([bom + csv], { type: 'text/csv;charset=utf-8;' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `발주서목록_${new Date().toISOString().split('T')[0]}.csv`;
            a.click();
            URL.revokeObjectURL(url);
            toast('📊 발주서 목록 엑셀(CSV) 다운로드 완료');
          } catch (e) {
            toast('다운로드 실패: ' + e.message);
          }
        }

        // ===================== 견적기안 목록 =====================
        function renderRfqpList() {
          const listBody = document.getElementById('rfqp-list-body');
          if (!listBody) return;
          listBody.innerHTML = RFQP_LIST.map(r => {
            const isNew = r.isNew;
            const statusBadge = r.status === '회신완료'
              ? `<span class="badge badge-green">회신완료</span>`
              : r.status === '발송완료'
                ? `<span class="badge badge-blue">발송완료</span>`
                : `<span class="badge badge-gray">${r.status}</span>`;
            const repliedParts = r.replied.split('/');
            const repliedDone = parseInt(repliedParts[0]);
            const repliedTotal = parseInt(repliedParts[1]);
            const repliedBadge = repliedDone === repliedTotal && repliedTotal > 0
              ? `<span style="color:#16a34a;font-weight:700;">${r.replied}</span>`
              : repliedDone > 0
                ? `<span style="color:#d97706;font-weight:600;">${r.replied}</span>`
                : `<span style="color:#94a3b8;">${r.replied}</span>`;
            return `
        <tr style="${isNew ? 'background:#f0f9ff;' : ''}">
          <td class="font-mono text-xs" style="${isNew ? 'color:#2563eb;font-weight:700;' : ''}">${r.no}${isNew ? ' <span class="badge badge-blue" style="font-size:10px;">NEW</span>' : ''}</td>
          <td><a href="#" onclick="openRfqDetail('${r.no}');return false;" style="color:#2563eb;font-weight:600;">${r.name}</a></td>
          <td class="text-center">${r.items}개</td>
          <td class="text-center">${r.vendors}개사</td>
          <td>${statusBadge}</td>
          <td>${repliedBadge}</td>
          <td class="text-muted text-xs">${r.date}</td>
          <td>
            <button class="btn btn-outline btn-sm" onclick="openRfqDetail('${r.no}')">상세</button>
            
          </td>
        </tr>`;
          }).join('');
        }

        function openRfqDetail(rfqNo) {
          const entry = RFQP_LIST.find(r => r.no === rfqNo);
          if (entry) {
            state.currentRfqNo = rfqNo;
            state.currentRfqEntry = entry;
            // 상세 헤더 업데이트
            const nameEl = document.getElementById('detail-rfqp-name');
            if (nameEl) nameEl.textContent = `${entry.no} · ${entry.name}`;
            // VENDOR_REPLIES 해당 거래처만 활성화
            if (entry.vendorIds) {
              Object.keys(VENDOR_REPLIES).forEach(id => {
                if (!entry.vendorIds.includes(id)) {
                  VENDOR_REPLIES[id].status = '외부입력대기';
                }
              });
            }
            renderReplyTable();
            updateRepliedCount();
          }
          showPage('pg-rfqp-detail');
        }

        function goToCompare(rfqNo) {
          openRfqDetail(rfqNo);
          setTimeout(() => { showPage('pg-compare'); }, 100);
        }

        // ===================== 회신 관리 =====================
        // Redundant renderReplyTable removed (merged into the one below)

        function updateRepliedCount() {
          const done = Object.values(VENDOR_REPLIES).filter(v => v.status === '입력완료').length
            + Object.values(state.vendorStatuses).filter(v => v === 'blocked').length;

          const r = document.getElementById('det-replied');
          if (r) r.textContent = `${done} / ${Object.keys(VENDOR_REPLIES).length}`;

          const o = document.getElementById('det-ongoing');
          if (o) o.textContent = Object.values(VENDOR_REPLIES).filter(v => v.status === '외부입력중').length;

          const b = document.getElementById('det-blocked');
          if (b) b.textContent = Object.values(state.vendorStatuses).filter(v => v === 'blocked').length;
        }


        // ===================== 링크 차단 =====================
        function openBlockModal(vendorId) {
          state.blockTarget = vendorId;
          const v = VENDOR_REPLIES[vendorId] || { name: VNAMES[vendorId] };
          document.getElementById('block-vendor-name').textContent = `대상 거래처: ${v.name}`;

          const project = PROJECT_DATA[state.currentProject] || PROJECT_DATA[Object.keys(PROJECT_DATA)[0]];
          const items = project.items || [];

          document.getElementById('block-input-body').innerHTML = items.slice(0, 15).map((item, i) => `
        <tr>
          <td class="text-muted text-xs">${i + 1}</td>
          <td style="max-width:140px;font-size:12px;">${item.name}</td>
          <td class="text-xs">${item.qty || 1}EA</td>
          <td><select class="block-supply" data-idx="${i}" style="font-size:11px;padding:3px 5px;" onchange="onBlockSupplyChange(this,${i})">
            <option value="ok">공급가능</option><option value="alt">대체제안</option><option value="na">공급불가</option>
          </select></td>
          <td><input type="number" class="block-price" data-idx="${i}" placeholder="단가" style="width:90px;font-size:12px;"></td>
          <td><input type="text" placeholder="비고" style="font-size:11px;width:80px;"></td>
        </tr>
      `).join('') + `<tr><td colspan="6" class="text-muted text-xs" style="padding:6px;text-align:center;">최근 15개 품목 기준</td></tr>`;

          openModal('block-modal');
        }
        function onBlockSupplyChange(sel, i) {
          const priceInput = sel.closest('tr').querySelector('.block-price');
          if (sel.value === 'na') { priceInput.value = 0; priceInput.disabled = true; priceInput.style.background = '#fee2e2'; }
          else { priceInput.disabled = false; priceInput.style.background = ''; }
        }
        function confirmBlock() {
          const id = state.blockTarget;
          const v = VENDOR_REPLIES[id];
          const reason = document.getElementById('block-reason').value;
          // 랜덤 합계 생성 (내부 입력)
          v.subtotal = Math.floor(Math.random() * 15000000) + 25000000;
          v.status = '입력완료';
          state.vendorStatuses[id] = 'blocked';
          closeModal('block-modal');
          renderReplyTable();
          renderCompareTotal();
          renderCompareItem();
          addLog(`${v.name} 링크 차단 완료 (사유: ${reason}) — 내부 대체 입력 확정`);
          toast(`🔒 ${v.name} 링크 차단 및 내부 입력 확정 완료`);
          updateRepliedCount();
          state.blockTarget = null;
        }

        // ===================== 회신 견적서 보기 =====================
        // 시뮬레이션용 회신 견적 데이터
        const REPLY_DATA = {
          v1: { // 대성상사
            items: [
              { name: '노트북 LG 그램 16', model: '16Z90R-K.AA5SK3', qty: 5, unit: 'EA', supply: 'ok', price: 1850000, remark: '', remark2: '정품 최신 재고' },
              { name: '무선 마우스 로지텍', model: 'MX Master 3S', qty: 20, unit: 'EA', supply: 'ok', price: 89000, remark: '', remark2: '' },
              { name: 'USB-C 허브 7in1', model: 'Anker A8346', qty: 25, unit: 'EA', supply: 'ok', price: 68000, remark: '', remark2: '' },
              { name: '27인치 모니터', model: 'LG 27GP850-B', qty: 8, unit: 'EA', supply: 'ok', price: 420000, remark: '', remark2: '' },
              { name: '노이즈캔슬링 헤드셋', model: 'Sony WH-1000XM5', qty: 6, unit: 'EA', supply: 'na', price: 0, remark: '', remark2: '재고 없음' },
              { name: '외장 SSD 1TB', model: 'Samsung T7 Shield', qty: 10, unit: 'EA', supply: 'ok', price: 98000, remark: '', remark2: '' },
              { name: 'A4 복사용지', model: '더블에이 80g', qty: 50, unit: '박스', supply: 'ok', price: 28000, remark: '', remark2: '' },
              { name: '전동 높낮이 책상', model: '플렉시스팟 E7', qty: 4, unit: 'EA', supply: 'alt', price: 520000, remark: '', remark2: '동급 Flexispot E5로 대체 제안' },
              { name: '인체공학 의자', model: '허먼밀러 Aeron B', qty: 4, unit: 'EA', supply: 'ok', price: 1250000, remark: '', remark2: '' },
              { name: '라벨 프린터', model: 'Brother PT-D610BT', qty: 3, unit: 'EA', supply: 'ok', price: 185000, remark: '', remark2: '' },
            ]
          },
          v2: { // 한솔무역
            items: [
              { name: '노트북 LG 그램 16', model: '16Z90R-K.AA5SK3', qty: 5, unit: 'EA', supply: 'ok', price: 1780000, remark: '', remark2: '' },
              { name: '무선 마우스 로지텍', model: 'MX Master 3S', qty: 20, unit: 'EA', supply: 'ok', price: 92000, remark: '', remark2: '' },
              { name: 'USB-C 허브 7in1', model: 'Anker A8346', qty: 25, unit: 'EA', supply: 'ok', price: 62000, remark: '', remark2: '신규 입고 확인' },
              { name: '27인치 모니터', model: 'LG 27GP850-B', qty: 8, unit: 'EA', supply: 'ok', price: 398000, remark: '', remark2: '' },
              { name: '노이즈캔슬링 헤드셋', model: 'Sony WH-1000XM5', qty: 6, unit: 'EA', supply: 'ok', price: 289000, remark: '', remark2: '소니 공식 파트너' },
              { name: '외장 SSD 1TB', model: 'Samsung T7 Shield', qty: 10, unit: 'EA', supply: 'ok', price: 94000, remark: '', remark2: '' },
              { name: 'A4 복사용지', model: '더블에이 80g', qty: 50, unit: '박스', supply: 'ok', price: 27500, remark: '', remark2: '50박스 이상 무료배송' },
              { name: '전동 높낮이 책상', model: '플렉시스팟 E7', qty: 4, unit: 'EA', supply: 'na', price: 0, remark: '', remark2: '현재 단종, 수급 불가' },
              { name: '인체공학 의자', model: '허먼밀러 Aeron B', qty: 4, unit: 'EA', supply: 'ok', price: 1190000, remark: '', remark2: '' },
              { name: '라벨 프린터', model: 'Brother PT-D610BT', qty: 3, unit: 'EA', supply: 'ok', price: 179000, remark: '', remark2: '' },
            ]
          },
        };

        // ===================== 회신 상세 데이터 mock =====================
        const REPLY_DATA2 = {
          'v1': {
            vendorName: '한솔시스템',
            items: [
              { name: 'CAT.6 LAN 케이블', model: 'Blue / 300m', qty: 5, unit: 'EA', supply: 'ok', price: 125000, remark: '정품', remark2: '당일배송' },
              { name: 'RJ-45 커넥터', model: 'CAT.6 / 100P', qty: 10, unit: 'EA', supply: 'alt', price: 18000, remark: '강원전자 대체', remark2: '재고보유' },
              { name: '무선 공유기', model: 'IPTIME AX2004', qty: 2, unit: 'EA', supply: 'na', price: 0, remark: '단종', remark2: '대체품 협의필요' }
            ]
          },
          'v2': {
            vendorName: '미래네트웍스',
            items: [
              { name: 'CAT.6 LAN 케이블', model: 'Blue / 300m', qty: 5, unit: 'EA', supply: 'ok', price: 121000, remark: '당사보유분', remark2: '오전배송' },
              { name: 'RJ-45 커넥터', model: 'CAT.6 / 100P', qty: 10, unit: 'EA', supply: 'ok', price: 19500, remark: '정품', remark2: '재고여유' },
              { name: '무선 공유기', model: 'IPTIME AX2004', qty: 2, unit: 'EA', supply: 'ok', price: 68000, remark: '최신모델', remark2: '익일배송' }
            ]
          }
        };

        function showReplyRfq(vendorId) {
          const v = VENDOR_REPLIES[vendorId];
          const data = REPLY_DATA[vendorId] || REPLY_DATA['v1'];
          const tdS = 'padding:7px 10px;border:1px solid #e2e8f0;font-size:12px;';
          const thS = 'padding:7px 10px;border:1px solid #aaa;background:#f0f0f0;font-size:11px;font-weight:600;text-align:center;';

          let sub = 0;
          const itemRows = data.items.map((item, i) => {
            const lineTotal = item.supply === 'na' ? 0 : item.price * item.qty;
            sub += lineTotal;
            const supplyBg = item.supply === 'na' ? 'background:#fff0f0;' : item.supply === 'alt' ? 'background:#fffbeb;' : '';
            const supplyLabel = item.supply === 'na'
              ? '<span style="color:#dc2626;font-weight:600;">공급불가</span>'
              : item.supply === 'alt'
                ? '<span style="color:#d97706;font-weight:600;">대체제안</span>'
                : '<span style="color:#16a34a;">공급가능</span>';
            return `<tr style="${supplyBg}">
      <td style="${tdS}text-align:center;">${i + 1}</td>
      <td style="${tdS}font-weight:500;">${item.name}</td>
      <td style="${tdS}font-size:11px;color:#64748b;">${item.model}</td>
      <td style="${tdS}text-align:center;">${item.qty}${item.unit}</td>
      <td style="${tdS}text-align:center;">${supplyLabel}</td>
      <td style="${tdS}text-align:center;">별도</td>
      <td style="${tdS}text-align:right;font-family:monospace;">${item.supply === 'na' ? '—' : (item.price.toLocaleString() + '원')}</td>
      <td style="${tdS}text-align:right;font-family:monospace;font-weight:600;">${item.supply === 'na' ? '—' : (lineTotal.toLocaleString() + '원')}</td>
      <td style="${tdS}font-size:11px;color:#94a3b8;background:#f0f9ff;">${item.remark || '—'}</td>
      <td style="${tdS}font-size:11px;background:#f0fdf4;">${item.remark2 || '—'}</td>
    </tr>`;
          }).join('');
          const vat = Math.round(sub * 0.1);
          const total = sub + vat;

          document.getElementById('reply-rfq-body').innerHTML = `
  <div style="font-family:'Malgun Gothic','Apple SD Gothic Neo',sans-serif;max-width:900px;margin:0 auto;background:#fff;">
    <!-- 회사 헤더 -->
    <div style="display:flex;align-items:center;justify-content:space-between;padding:14px 20px;border-bottom:3px solid #e8501a;">
      <img src="data:image/png;base64,..." alt="NEO BH" style="height:52px;object-fit:contain;">
      <div style="font-size:11px;color:#444;text-align:right;line-height:1.8;">
        주소: 경기도 김포시 고촌읍 전호로 32 | 사업자번호: 822-87-00677 | 홈페이지: www.neobh.kr<br>
        TEL: 031-987-3069 | FAX: 031-998-3069 | E-mail: balhea@balhea.kr
      </div>
    </div>
    <!-- 문서 제목 -->
    <div style="text-align:center;padding:16px 0 12px;font-size:20px;font-weight:700;letter-spacing:5px;">견 적 요 청 서 (회신본)</div>
    <div style="display:flex;justify-content:space-between;padding:0 20px 10px;font-size:12px;">
      <div>견적일자: <strong>2026-04-15</strong></div>
      <div>Estimate No. <strong>NB_251021_E_47</strong></div>
    </div>
    <!-- 수신/발신 -->
    <div style="display:grid;grid-template-columns:1fr 1fr;margin:0 20px 14px;border:1px solid #aaa;">
      <div style="border-right:1px solid #aaa;">
        <div style="background:#f0f0f0;text-align:center;padding:5px;font-size:12px;font-weight:700;border-bottom:1px solid #aaa;">수신처 (거래처)</div>
        <div style="display:grid;grid-template-columns:60px 1fr;font-size:12px;">
          <div style="padding:5px 10px;border-bottom:1px solid #f0f0f0;border-right:1px solid #f0f0f0;color:#555;">업체명</div><div style="padding:5px 10px;border-bottom:1px solid #f0f0f0;font-weight:600;">${v.name}</div>
          <div style="padding:5px 10px;border-right:1px solid #f0f0f0;color:#555;">건명</div><div style="padding:5px 10px;">${state.currentProject}</div>
        </div>
      </div>
      <div>
        <div style="background:#f0f0f0;text-align:center;padding:5px;font-size:12px;font-weight:700;border-bottom:1px solid #aaa;">발신처 (발주사)</div>
        <div style="display:grid;grid-template-columns:60px 1fr;font-size:12px;">
          <div style="padding:5px 10px;border-bottom:1px solid #f0f0f0;border-right:1px solid #f0f0f0;color:#555;">상호명</div><div style="padding:5px 10px;border-bottom:1px solid #f0f0f0;font-weight:600;">네오비에이치</div>
          <div style="padding:5px 10px;border-right:1px solid #f0f0f0;color:#555;">담당자</div><div style="padding:5px 10px;">구매팀</div>
        </div>
      </div>
    </div>
    <!-- 품목 테이블 -->
    <div style="margin:0 20px;overflow-x:auto;">
      <table style="width:100%;border-collapse:collapse;">
        <thead><tr>
          <th style="${thS}width:30px;">No</th>
          <th style="${thS}min-width:130px;">품명</th>
          <th style="${thS}min-width:100px;">규격</th>
          <th style="${thS}width:60px;">수량</th>
          <th style="${thS}width:80px;">공급상태</th>
          <th style="${thS}width:50px;">VAT</th>
          <th style="${thS}width:100px;">단가</th>
          <th style="${thS}width:100px;">합계</th>
          <th style="${thS}min-width:100px;background:#e0f2fe;">요청비고<br><span style="font-size:9px;font-weight:400;">(구매팀→거래처)</span></th>
          <th style="${thS}min-width:100px;background:#dcfce7;">회신비고<br><span style="font-size:9px;font-weight:400;">(거래처→구매팀)</span></th>
        </tr></thead>
        <tbody>${itemRows}</tbody>
      </table>
    </div>
    <!-- TOTAL -->
    <div style="margin:0 20px;border:1px solid #ddd;border-top:none;padding:10px 14px;">
      <div style="display:flex;justify-content:space-between;align-items:center;padding:3px 0;font-size:13px;">
        <div style="display:flex;align-items:center;gap:4px;flex:1;"><strong>TOTAL</strong><span style="border-bottom:1px dashed #aaa;flex:1;margin:0 10px;display:block;"></span></div>
        <div style="font-weight:700;">${sub.toLocaleString()} 원 <span style="font-size:11px;font-weight:400;color:#555;">[부가세 별도]</span></div>
      </div>
      <div style="display:flex;justify-content:space-between;align-items:center;padding:3px 0;font-size:13px;border-top:1px solid #eee;">
        <div style="display:flex;align-items:center;gap:4px;flex:1;"><strong>TOTAL(with Tax)</strong><span style="border-bottom:1px dashed #aaa;flex:1;margin:0 10px;display:block;"></span></div>
        <div style="font-size:15px;font-weight:700;">${total.toLocaleString()} 원 <span style="font-size:11px;font-weight:400;color:#555;">[부가세 포함]</span></div>
      </div>
    </div>
    <div style="margin:8px 20px 0;font-size:11px;color:#94a3b8;text-align:center;padding-bottom:8px;">
      ※ 파란색 열(요청비고)은 구매팀이 거래처에 전달한 내용 | 초록색 열(회신비고)은 거래처가 회신한 내용입니다.
    </div>
  </div>`;
          document.getElementById('reply-rfq-modal').classList.add('open');
        }

        // ===================== 비교 =====================
        function renderCompareTotal() {
          const tbody = document.getElementById('compare-total-body');
          if (!tbody) return;
          const rows = Object.entries(VENDOR_REPLIES)
            .filter(([id, v]) => v.subtotal > 0)
            .sort((a, b) => a[1].subtotal - b[1].subtotal);
          const medals = ['🥇', '🥈', '🥉'];
          tbody.innerHTML = rows.map(([id, v], i) => {
            const hasNa = (v.supply_na || 0) > 0;
            return `<tr class="${hasNa ? 'penalty-row' : ''}">
      <td>${medals[i] || ''} ${i + 1}위</td>
      <td><strong>${v.name}</strong></td>
      <td class="font-mono">${(v.subtotal || 0).toLocaleString()}원</td>
      <td class="font-mono font-bold">${Math.round((v.subtotal || 0) * 1.1).toLocaleString()}원</td>
      <td>${(v.supply_na || 0) > 0 ? `<span class="badge badge-red">⚠ ${v.supply_na}건</span>` : '<span class="badge badge-green">없음</span>'}</td>
      <td>${(v.supply_alt || 0) > 0 ? `<span class="badge badge-amber">${v.supply_alt}건</span>` : '—'}</td>
      <td><button class="btn btn-outline btn-sm" onclick="switchCompareTab('item')">품목별 선택 →</button></td>
    </tr>`;
          }).join('') || '<tr><td colspan="7" class="text-muted text-sm" style="text-align:center;padding:20px;">회신 완료된 거래처가 없습니다</td></tr>';
        }

        function switchCompareTab(tab) {
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
          if (tab === 'total') {
            document.getElementById('tab-btn-total').classList.add('active');
            document.getElementById('tab-total').style.display = '';
            document.getElementById('tab-item').style.display = 'none';
          } else {
            document.getElementById('tab-btn-item').classList.add('active');
            document.getElementById('tab-total').style.display = 'none';
            document.getElementById('tab-item').style.display = '';
          }
        }

        // ─── 장바구니 상태 ───
        // cart = { itemIdx: { vendorId, name, qty, unit, price } }
        let cart = {};

        const VNAMES = {
          v1: '㈜대성상사', v2: '㈜한솔무역', v3: '㈜미래기술', v4: '㈜글로벌서플라이',
          v5: '㈜디지털파트너', v6: '㈜스마트오피스', v7: '㈜코리아IT', v8: '㈜베스트서플라이'
        };
        const VIDS = VENDOR_IDS_SELECTED;

        const PROJECT_DATA = {
          'G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매': {
            basicInfo: {
              type: '일반계약', vendor: '벤더사', destination: '본사',
              name: 'G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매',
              no: 'G022600061', contractNo: 'CON-2026-001', manager: '구민성',
              orderDate: '2026-02-10', deliveryDate: '2026-05-30', itemCount: 15, remarks: ''
            },
            items: ITEMS_50.slice(0, 15),
            compareData: [
              // supplyQty: 거래처별 실제 공급 가능 수량 (qty보다 적으면 부족분 표시)
              { name: '노트북 LG 그램 16', qty: 5, unit: 'EA', prices: { v1: 1850000, v2: 1780000, v3: 1920000 }, supplyQty: { v1: 5, v2: 5, v3: 5 } },
              { name: '노트북 삼성 갤럭시북4', qty: 3, unit: 'EA', prices: { v1: 1650000, v2: 1700000, v3: 1620000 }, supplyQty: { v1: 3, v2: 3, v3: 2 } },
              { name: '무선 마우스 로지텍', qty: 20, unit: 'EA', prices: { v1: 89000, v2: 92000, v3: null }, supplyQty: { v1: 20, v2: 20, v3: 20 } },
              { name: '유선 키보드', qty: 15, unit: 'EA', prices: { v1: 120000, v2: 115000, v3: 130000 }, supplyQty: { v1: 15, v2: 15, v3: 15 } },
              { name: '무선 키보드', qty: 10, unit: 'EA', prices: { v1: 180000, v2: 175000, v3: 185000 }, supplyQty: { v1: 10, v2: 10, v3: 10 } },
              { name: '27인치 모니터', qty: 8, unit: 'EA', prices: { v1: 420000, v2: 398000, v3: 415000 }, supplyQty: { v1: 8, v2: 8, v3: 8 } },
              { name: '32인치 4K 모니터', qty: 5, unit: 'EA', prices: { v1: 780000, v2: 750000, v3: 790000 }, supplyQty: { v1: 5, v2: 5, v3: 5 } },
              { name: 'USB-C 허브 7in1', qty: 25, unit: 'EA', prices: { v1: 68000, v2: 62000, v3: 71000 }, supplyQty: { v1: 25, v2: 25, v3: 25 } },
              { name: 'USB-C 허브 4in1', qty: 15, unit: 'EA', prices: { v1: 45000, v2: 42000, v3: 48000 }, supplyQty: { v1: 15, v2: 15, v3: 15 } },
              { name: '모니터암 싱글', qty: 10, unit: 'EA', prices: { v1: 95000, v2: 92000, v3: 98000 }, supplyQty: { v1: 10, v2: 10, v3: 10 } },
              { name: '모니터암 듀얼', qty: 5, unit: 'EA', prices: { v1: 165000, v2: 158000, v3: 170000 }, supplyQty: { v1: 5, v2: 5, v3: 5 } },
              { name: '노이즈캔슬링 헤드셋', qty: 6, unit: 'EA', prices: { v1: null, v2: 289000, v3: null }, supplyQty: { v1: 6, v2: 6, v3: 6 } },
              { name: '외장 SSD 1TB', qty: 10, unit: 'EA', prices: { v1: 98000, v2: 94000, v3: 99000 }, supplyQty: { v1: 10, v2: 10, v3: 10 } },
              { name: 'A4 복사용지', qty: 50, unit: '박스', prices: { v1: 28000, v2: 27500, v3: 26800 }, supplyQty: { v1: 50, v2: 50, v3: 50 } },
              { name: '전동 높낮이 책상', qty: 4, unit: 'EA', prices: { v1: 580000, v2: null, v3: 550000 }, supplyQty: { v1: 4, v2: 4, v3: 4 } },
            ]
          },
          '주름관 등 155품목 구매': {
            basicInfo: {
              type: '연간단가', vendor: '한솔무역', destination: '포천 현장',
              name: '주름관 등 155품목 구매',
              no: 'P022600042', contractNo: 'CON-2026-008', manager: '이현우',
              orderDate: '2026-03-05', deliveryDate: '2026-04-15', itemCount: 155, remarks: '설비 자재 긴급'
            },
            items: [
              { name: 'KS 주름관 15mm', model: 'KS-15-P', note: '스테인리스' },
              { name: 'KS 주름관 20mm', model: 'KS-20-P', note: '스테인리스' },
              { name: '주름관 연결 소켓', model: 'SK-1520', note: '황동제' },
              { name: '엘보 15mm', model: 'EB-15', note: '나사타입' },
              { name: '테프론 테이프', model: 'TF-100', note: '밀봉용' },
              { name: '배관 지지대', model: 'ST-50', note: '벽부착형' },
              { name: '고무 패킹', model: 'PK-20', note: 'EPDM 재질' },
              { name: '주름관 커터', model: 'CT-200', note: '수동식' },
              { name: 'PVC 파이프 50mm', model: 'PVC-50', note: '4M 규격' },
              { name: 'PVC 본드', model: 'BD-100', note: '강력 접착' },
              { name: '게이트 밸브', model: 'GV-25', note: '황동 핸들' },
              { name: '스트레이너', model: 'STR-50', note: 'Y형' },
              { name: '동관 15A', model: 'CU-15', note: 'L형 냉동용' },
              { name: '동링직 15A', model: 'CR-15', note: '무용접' },
              { name: '보온재 15mm', model: 'INS-15', note: '고무발포' }
            ],
            compareData: [
              { name: 'KS 주름관 15mm', qty: 100, unit: 'M', prices: { v1: 2500, v2: 2300, v3: 2600 } },
              { name: 'KS 주름관 20mm', qty: 50, unit: 'M', prices: { v1: 3200, v2: 3400, v3: 3100 } },
              { name: '주름관 연결 소켓', qty: 40, unit: 'EA', prices: { v1: 1500, v2: 1200, v3: 1400 } },
              { name: '엘보 15mm', qty: 30, unit: 'EA', prices: { v1: 1800, v2: 1900, v3: 1750 } },
              { name: '테프론 테이프', qty: 20, unit: 'EA', prices: { v1: 800, v2: 750, v3: 900 } },
              { name: '배관 지지대', qty: 60, unit: 'EA', prices: { v1: 1200, v2: 1100, v3: 1300 } },
              { name: '고무 패킹', qty: 100, unit: 'EA', prices: { v1: 300, v2: 280, v3: 350 } },
              { name: '주름관 커터', qty: 2, unit: 'EA', prices: { v1: 45000, v2: 42000, v3: 48000 } },
              { name: 'PVC 파이프 50mm', qty: 10, unit: 'EA', prices: { v1: 12000, v2: 11500, v3: 13000 } },
              { name: 'PVC 본드', qty: 5, unit: 'EA', prices: { v1: 6500, v2: 6000, v3: 7000 } },
              { name: '게이트 밸브', qty: 8, unit: 'EA', prices: { v1: 18500, v2: 17800, v3: 19200 } },
              { name: '스트레이너', qty: 4, unit: 'EA', prices: { v1: 32000, v2: 31000, v3: 33500 } },
              { name: '동관 15A', qty: 15, unit: 'EA', prices: { v1: 28000, v2: 27500, v3: 29000 } },
              { name: '동링직 15A', qty: 30, unit: 'EA', prices: { v1: 4500, v2: 4200, v3: 4800 } },
              { name: '보온재 15mm', qty: 50, unit: 'EA', prices: { v1: 3500, v2: 3300, v3: 3800 } }
            ]
          },
          '팝업 품목 리스트': {
            basicInfo: {
              type: '수의계약', vendor: '대성상사', destination: '강남 지사',
              name: '팝업 품목 리스트',
              no: 'T022600015', contractNo: 'CON-2026-012', manager: '김지아',
              orderDate: '2026-04-20', deliveryDate: '2026-05-10', itemCount: 8, remarks: '테스트용 데이터'
            },
            items: ITEMS_50.slice(15, 23),
            compareData: [
              { name: '노트북 LG 그램 16', qty: 5, unit: 'EA', prices: { v1: 1800000, v2: 1750000, v3: 1850000 }, supplyQty: { v1: 5, v2: 3, v3: 5 } },
              { name: '무선 마우스', qty: 20, unit: 'EA', prices: { v1: 89000, v2: 85000, v3: 92000 }, supplyQty: { v1: 20, v2: 20, v3: 15 } },
              { name: '멀티탭 6구', qty: 10, unit: 'EA', prices: { v1: 22000, v2: 21000, v3: 23000 }, supplyQty: { v1: 10, v2: 8, v3: 10 } },
              { name: '27인치 모니터', qty: 8, unit: 'EA', prices: { v1: 420000, v2: 398000, v3: null }, supplyQty: { v1: 8, v2: 5, v3: 0 } }
            ]
          },
          '[202605541] 2026년 국토교통정보 통합시스템 IT인프라 구축': {
            basicInfo: {
              type: '공개입찰', vendor: '미래기술', destination: '세종시 국토부',
              name: '[202605541] 2026년 국토교통정보 통합시스템 IT인프라 구축',
              no: '202605541', contractNo: 'CON-2026-025', manager: '최동진',
              orderDate: '2026-05-01', deliveryDate: '2026-12-31', itemCount: 12, remarks: '공공기관 대형 프로젝트'
            },
            items: ITEMS_50.slice(23, 35),
            compareData: [
              { name: '서버 랙 42U', qty: 2, unit: 'EA', prices: { v1: 1200000, v2: 1150000, v3: 1300000 }, supplyQty: { v1: 2, v2: 2, v3: 2 } },
              { name: 'CCTV IP카메라', qty: 5, unit: 'EA', prices: { v1: 150000, v2: 145000, v3: 160000 }, supplyQty: { v1: 5, v2: 3, v3: 5 } }
            ]
          },
          '입출고 수정 테스트 프로젝트 1777523941': {
            basicInfo: {
              type: '테스트계약', vendor: '테스트업체', destination: '검증 센터',
              name: '입출고 수정 테스트 프로젝트 1777523941',
              no: '1777523941', contractNo: 'CON-TEST-999', manager: 'QA팀',
              orderDate: '2026-05-07', deliveryDate: '2026-05-08', itemCount: 5, remarks: '기능 검증 전용'
            },
            items: ITEMS_50.slice(35, 40),
            compareData: [
              { name: '테스트 품목 A', qty: 10, unit: 'EA', prices: { v1: 10000, v2: 12000, v3: 9000 } },
              { name: '테스트 품목 B', qty: 20, unit: 'EA', prices: { v1: 5000, v2: 4500, v3: 5500 } }
            ]
          }
        };

        function renderCompareItem() {
          const head = document.getElementById('compare-item-head');
          const body = document.getElementById('compare-item-body');
          if (!head || !body) return;

          const project = PROJECT_DATA[state.currentProject] || PROJECT_DATA['G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매'];
          const items = project.items;
          const compareData = project.compareData;

          // 최대 가능한 순위 계산 (거래처 수)
          const maxRanks = VIDS.length;
          const currentRanks = Math.min(expandedRanks, maxRanks);

          // 헤더
          let headHtml = `
        <th style="width:28px;text-align:center;">No</th>
        <th style="width:110px;">품목명</th>
        <th style="width:90px;">규격/모델명</th>
        <th style="width:60px;text-align:center;">발주수량</th>
      `;

          for (let r = 1; r <= currentRanks; r++) {
            const title = r === 1 ? '1순위 (최저)' : `${r}순위`;
            headHtml += `<th style="width:150px;text-align:right;${r > 3 ? 'background:#f8fafc;' : ''}" class="${r > 3 ? 'expand-col' : ''}">${title}</th>`;
          }

          // 더보기 버튼 컬럼
          if (maxRanks > 3) {
            const moreCount = maxRanks - 3;
            headHtml += `
          <th style="width:80px;text-align:center;background:#eff6ff;cursor:pointer;" onclick="toggleColumnExpand(${maxRanks})">
            <div style="font-size:11px;color:#2563eb;font-weight:700;">
              ${expandedRanks > 3 ? '접기 ◀' : `+ ${moreCount}개 더보기 ▶`}
            </div>
          </th>
        `;
          }
          head.innerHTML = headHtml;

          // 행
          body.innerHTML = items.map((item, i) => {
            const row = compareData.find(r => r.name === item.name);
            const cartKey = `${state.currentProject}_${i}`;
            const isCartItem = cart[cartKey] != null;
            const rowBg = isCartItem ? 'background:#f8fafc;' : '';

            let qtyStr = '';
            let rankingCells = '';

            if (row) {
              qtyStr = `${row.qty}${row.unit}`;
              const priceList = VIDS.map(vid => ({
                vid,
                price: row.prices[vid]
              })).filter(p => p.price != null && p.price > 0);

              priceList.sort((a, b) => a.price - b.price);

              for (let rank = 0; rank < currentRanks; rank++) {
                const pInfo = priceList[rank];
                if (pInfo) {
                  const isSelectedVendor = isCartItem && cart[cartKey].vendorId === pInfo.vid;
                  const cartIcon = isSelectedVendor ? '✓ ' : '';
                  const bestBadge = rank === 0 ? ' <span class="badge badge-green" style="font-size:9px;padding:1px 3px;margin-left:4px;">BEST</span>' : '';
                  const cellBorder = isSelectedVendor ? '2px solid #2563eb' : '1px solid #e2e8f0';
                  const cellBg = isSelectedVendor ? '#eff6ff' : '#fff';
                  const orderQ = row.qty;
                  const supplyQ = (row.supplyQty || {})[pInfo.vid];
                  const supplyNum = (supplyQ !== undefined) ? supplyQ : orderQ;
                  const shortage = orderQ - supplyNum;
                  const supplyLabel = shortage > 0
                    ? `<div style="font-size:10px;color:#dc2626;margin-top:2px;">매입 ${supplyNum}개 ⚠ ${shortage}개 부족</div>`
                    : `<div style="font-size:10px;color:#16a34a;margin-top:2px;">매입 ${supplyNum}개 ✓</div>`;

                  // 거래처 비고
                  const vRemark = (row.vendorRemarks || {})[pInfo.vid] || (rank === 0 ? '정품 최신재고' : '');

                  rankingCells += `
                <td style="text-align:right;padding:6px;border:1px solid #f1f5f9;" class="${rank >= 3 ? 'expand-col' : ''}">
                  <div onclick="toggleCart(${i},'${pInfo.vid}',${pInfo.price},${supplyNum})" 
                       style="cursor:pointer; padding:10px; border-radius:6px; border:${cellBorder}; background:${cellBg}; transition:all 0.1s; text-align:right;">
                    <div style="font-size:12px; font-weight:700; color:#1e293b; display:flex; align-items:center; justify-content:flex-end;">
                      ${cartIcon}${pInfo.price.toLocaleString()}원${bestBadge}
                    </div>
                    <div style="font-size:10px; color:#64748b; margin-top:2px;">${VNAMES[pInfo.vid]}</div>
                    ${supplyLabel}
                    ${vRemark ? `<div style="font-size:10px;color:#7c3aed;margin-top:4px;font-weight:500;text-align:left;">💬 ${vRemark}</div>` : ''}
                  </div>
                </td>`;
                } else {
                  rankingCells += `<td style="text-align:right;font-size:11px;color:#cbd5e1;padding:12px;background:#fcfcfc;border:1px solid #f1f5f9;" class="${rank >= 3 ? 'expand-col' : ''}">공급불가 ✗</td>`;
                }
              }

              if (maxRanks > 3 && expandedRanks === 3) {
                rankingCells += `<td style="background:#f8fafc;border:1px solid #f1f5f9;"></td>`;
              }
            }

            return `<tr id="cmp-row-${i}" style="${rowBg}">
          <td style="text-align:center;font-size:11px;color:#94a3b8;border-bottom:1px solid #f1f5f9;">${i + 1}</td>
          <td style="font-size:12px;font-weight:500;padding:12px 10px;border-bottom:1px solid #f1f5f9;word-break:break-all;">${item.name}
            ${isCartItem ? `<div style="font-size:10px;color:#2563eb;margin-top:2px;font-weight:600;">[${VNAMES[cart[`${state.currentProject}_${i}`].vendorId]}]</div>` : ''}
          </td>
          <td style="font-size:11px;color:#64748b;padding:12px 10px;border-bottom:1px solid #f1f5f9;">${item.model}</td>
          <td style="text-align:center;font-size:12px;border-bottom:1px solid #f1f5f9;">${qtyStr}<br><span style="font-size:10px;color:#94a3b8;">발주</span></td>
          ${rankingCells}
        </tr>`;
          }).join('');
        }

        function toggleCart(itemIdx, vendorId, price, supplyQty) {
          const project = PROJECT_DATA[state.currentProject];
          const item = project.items[itemIdx];
          const row = project.compareData.find(r => r.name === item.name);
          if (!row) return;

          const cartKey = `${state.currentProject}_${itemIdx}`;
          const orderQ = row.qty;
          const supplyNum = (supplyQty !== undefined) ? supplyQty : orderQ;

          // 이미 같은 거래처로 담겨 있으면 제거
          if (cart[cartKey] && cart[cartKey].vendorId === vendorId) {
            delete cart[cartKey];
            toast(`🗑 "${item.name}" 장바구니에서 제거했습니다.`);
          } else {
            cart[cartKey] = { vendorId, name: item.name, qty: supplyNum, orderQty: orderQ, unit: row.unit, price, project: state.currentProject };
            const shortage = orderQ - supplyNum;
            const msg = shortage > 0
              ? `🛒 "${item.name}" 담음 — ${VNAMES[vendorId]} · 매입 ${supplyNum}개 (${shortage}개 부족)`
              : `🛒 "${item.name}" — ${VNAMES[vendorId]} ${price.toLocaleString()}원 담았습니다.`;
            toast(msg);
          }
          renderCompareItem();
          renderCart();
        }

        function renderCart() {
          const keys = Object.keys(cart);
          document.getElementById('cart-count-badge').textContent = keys.length + '개';
          document.getElementById('cart-empty').style.display = keys.length ? 'none' : '';
          document.getElementById('cart-po-btn').disabled = keys.length === 0;

          // 거래처별 그룹핑
          const groups = {}; // vendorId -> { items[], sub }
          let totalSub = 0;
          keys.forEach(k => {
            const c = cart[k];
            if (!groups[c.vendorId]) groups[c.vendorId] = { items: [], sub: 0 };
            const lineTotal = c.price * c.qty;
            groups[c.vendorId].items.push({ ...c, lineTotal, key: k });
            groups[c.vendorId].sub += lineTotal;
            totalSub += lineTotal;
          });

          const vendorCount = Object.keys(groups).length;

          // 장바구니 렌더 — 거래처별 묶음으로 표시
          document.getElementById('cart-items').innerHTML = Object.entries(groups).map(([vid, g]) => {
            const itemRows = g.items.map((c, i) => {
              const orderQ = c.orderQty || c.qty;
              const shortage = orderQ - c.qty;
              const qtyColor = shortage > 0 ? '#dc2626' : '#16a34a';
              const qtyLabel = shortage > 0
                ? `발주 ${orderQ} / 매입 ${c.qty}${c.unit} <span style="color:#dc2626;">⚠ ${shortage}개 부족</span>`
                : `${c.qty}${c.unit}`;
              return `
      <div style="display:flex;justify-content:space-between;padding:6px 0;border-bottom:1px solid #f1f5f9;">
        <div style="flex:1;min-width:0;">
          <div style="font-size:10px;color:#94a3b8;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${c.project}</div>
          <div style="font-size:12px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${c.name}</div>
          <div style="font-size:11px;color:#64748b;">${qtyLabel} × ${c.price.toLocaleString()}원</div>
        </div>
        <div style="display:flex;align-items:center;gap:6px;flex-shrink:0;margin-left:8px;text-align:right;">
          <div style="font-family:monospace;font-size:11px;font-weight:600;">${c.lineTotal.toLocaleString()}원</div>
          <button onclick="toggleCartByKey('${c.key}')"
            style="background:none;border:none;cursor:pointer;color:#dc2626;font-size:13px;line-height:1;padding:0 2px;">✕</button>
        </div>
      </div>`;
            }).join('');

            return `<div style="border:1px solid #e2e8f0;border-radius:9px;overflow:hidden;margin-bottom:10px;">
      <div style="background:#1a1a2e;color:#fff;padding:8px 12px;display:flex;justify-content:space-between;align-items:center;">
        <div style="font-size:12px;font-weight:600;">${VNAMES[vid]}</div>
        <div style="font-size:11px;opacity:.75;">발주서 1건</div>
      </div>
      <div style="padding:4px 12px 8px;">${itemRows}</div>
      <div style="background:#f8fafc;padding:7px 12px;display:flex;justify-content:space-between;font-size:12px;border-top:1px solid #e2e8f0;">
        <span style="color:#64748b;">소계</span>
        <span style="font-family:monospace;font-weight:700;">${g.sub.toLocaleString()}원</span>
      </div>
    </div>`;
          }).join('');

          // 발주서 생성 버튼 텍스트 업데이트
          const btn = document.getElementById('cart-po-btn');
          if (btn && vendorCount > 0) {
            btn.textContent = `📦 발주서 ${vendorCount}건 생성 (거래처 ${vendorCount}개사)`;
          }

          document.getElementById('cart-sub').textContent = totalSub.toLocaleString() + '원';
          document.getElementById('cart-total').textContent = Math.round(totalSub * 1.1).toLocaleString() + '원';
        }

        function clearCart() {
          if (!Object.keys(cart).length) return;
          if (!confirm('장바구니를 비우시겠습니까?')) return;
          cart = {};
          renderCompareItem();
          renderCart();
        }

        function toggleCartByKey(key) {
          delete cart[key];
          renderCompareItem();
          renderCart();
          toast('🗑 장바구니에서 제거되었습니다.');
        }

        function createPoFromCart() {
          const keys = Object.keys(cart);
          if (!keys.length) { toast('담긴 품목이 없습니다.'); return; }

          // 거래처별 그룹핑
          const groups = {};
          keys.forEach(k => {
            const c = cart[k];
            if (!groups[c.vendorId]) groups[c.vendorId] = [];
            groups[c.vendorId].push({ ...c, key: k });
          });

          const vendorIds = Object.keys(groups);

          // 확인 모달 렌더
          const summaryHtml = vendorIds.map((vid, idx) => {
            const items = groups[vid];
            const sub = items.reduce((s, c) => s + c.price * c.qty, 0);
            const poNo = `PO-2026-${String(157 + idx).padStart(4, '0')}`;
            return `
    <div style="border:1px solid #e2e8f0;border-radius:9px;overflow:hidden;margin-bottom:10px;">
      <div style="background:#f8fafc;padding:10px 14px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #e2e8f0;">
        <div>
          <div style="font-size:13px;font-weight:700;">${VNAMES[vid]}</div>
          <div style="font-size:11px;color:#64748b;margin-top:1px;">발주번호: ${poNo} · ${items.length}개 품목</div>
        </div>
        <div style="text-align:right;">
          <div style="font-size:12px;color:#64748b;">발주 총액 (VAT포함)</div>
          <div style="font-size:15px;font-weight:700;font-family:monospace;color:#1a1a2e;">${Math.round(sub * 1.1).toLocaleString()}원</div>
        </div>
      </div>
      <div style="padding:8px 14px;">
        ${items.map((c, i) => `
          <div style="display:flex;justify-content:space-between;font-size:12px;padding:4px 0;border-bottom:1px solid #f8fafc;">
            <span>${i + 1}. ${c.name} (${c.qty}${c.unit})</span>
            <div style="text-align:right;">
              <div style="font-size:10px;color:#94a3b8;">${c.project}</div>
              <span style="font-family:monospace;color:#374151;">${(c.price * c.qty).toLocaleString()}원</span>
            </div>
          </div>`).join('')}
      </div>
    </div>`;
          }).join('');

          document.getElementById('po-create-modal-body').innerHTML = `
    <div style="margin-bottom:14px;" class="info-blue info-box">
      <span>💡</span>
      <div>장바구니에 담긴 품목을 <strong>거래처별로 분리</strong>하여 발주서 <strong>${vendorIds.length}건</strong>을 생성합니다.</div>
    </div>
    ${summaryHtml}
    <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;padding:12px 14px;display:flex;justify-content:space-between;align-items:center;">
      <span style="font-size:13px;font-weight:700;">전체 발주 총액 (VAT포함)</span>
      <span style="font-size:17px;font-weight:700;font-family:monospace;">
        ${Math.round(Object.values(groups).flat().reduce((s, c) => s + c.price * c.qty, 0) * 1.1).toLocaleString()}원
      </span>
    </div>`;

          document.getElementById('po-create-modal').classList.add('open');
          // 생성할 그룹 저장
          window._pendingPoGroups = groups;
        }

        function confirmPoCreate() {
          const groups = window._pendingPoGroups;
          if (!groups) return;
          closeModal('po-create-modal');

          const vendorIds = Object.keys(groups);

          // 발주서 목록에 추가
          const today = new Date().toISOString().split('T')[0];
          const newRows = vendorIds.map((vid, idx) => {
            const items = groups[vid];
            const total = Math.round(items.reduce((s, c) => s + c.price * c.qty, 0) * 1.1);
            const poNo = `PO-2026-${String(157 + idx).padStart(4, '0')}`;
            return { poNo, vendor: VNAMES[vid], total, date: today, items, vendorId: vid };
          });
          window._generatedPos = newRows;
          renderPoListWithCart(newRows);

          toast(`✅ 발주서 ${vendorIds.length}건이 생성되었습니다.`);
          addLog(`장바구니 선택 품목 → 발주서 ${vendorIds.length}건 자동 생성 (${vendorIds.map(id => VNAMES[id]).join(', ')})`);
          showPage('pg-po-list');
        }

        function renderPoListWithCart(newRows) {
          // 신규 발주서를 PO_APPROVAL_DATA에 추가 (중복 방지)
          const today = new Date().toISOString().split('T')[0];
          newRows.forEach(po => {
            if (!PO_APPROVAL_DATA.find(p => p.id === po.poNo)) {
              PO_APPROVAL_DATA.unshift({
                id: po.poNo, date: today, vendor: po.vendor,
                name: `${po.items[0]?.name || ''} 외 ${Math.max(po.items.length - 1, 0)}건`,
                total: po.total, manager: '구매담당자', role: 'buyer',
                approvalStep: 'pending_mgr', mgrComment: '', ceoComment: '',
                _cartItems: po.items
              });
            }
          });
          renderPoListFull();
        }

        function loadPoDetail(vname, items, status) {
          state.poStatus = status || '작성중';

          // Initialize payment method
          state.poPaymentMethod = state.poPaymentMethod || '계좌이체';
          updatePoPayMethodUI();

          // Show/Hide CEO Simulation Actions
          const ceoSimActionsEl = document.getElementById('ceo-sim-actions');
          if (ceoSimActionsEl) {
            if (state.poStatus === '결재중' || state.poStatus === '승인요청중') {
              ceoSimActionsEl.style.display = 'flex';
            } else {
              ceoSimActionsEl.style.display = 'none';
            }
          }

          // Update PO status badge in detail page
          const statusBadgeEl = document.getElementById('po-detail-status-badge');
          if (statusBadgeEl) {
            statusBadgeEl.textContent = state.poStatus;
            statusBadgeEl.className = 'badge'; // reset
            if (state.poStatus === '승인완료') {
              statusBadgeEl.classList.add('badge-green');
            } else if (state.poStatus === '승인반려') {
              statusBadgeEl.classList.add('badge-red');
            } else if (state.poStatus === '결재중' || state.poStatus === '승인요청중') {
              statusBadgeEl.classList.add('badge-amber');
            } else {
              statusBadgeEl.classList.add('badge-amber');
            }
          }

          const isReadOnly = (state.poStatus === '결재중' || state.poStatus === '승인요청중' || state.poStatus === '승인완료');
          const saveBtn = document.getElementById('btn-po-save');
          const reqBtn = document.getElementById('btn-po-req');
          const sendBtn = document.getElementById('btn-po-send');
          const dateInput = document.getElementById('po-date');
          const specialCostBtn = document.querySelector('button[onclick="addSpecialCost()"]');
          const negoReasonInput = document.getElementById('nego-reason');
          const negoAmountInput = document.getElementById('nego-amount');
          const negoVatSelect = document.getElementById('nego-vat-type');

          if (saveBtn) saveBtn.disabled = isReadOnly;
          if (reqBtn) reqBtn.disabled = isReadOnly;
          if (sendBtn) sendBtn.disabled = isReadOnly;
          if (dateInput) dateInput.readOnly = isReadOnly;
          if (specialCostBtn) specialCostBtn.disabled = isReadOnly;
          if (negoReasonInput) negoReasonInput.readOnly = isReadOnly;
          if (negoAmountInput) negoAmountInput.readOnly = isReadOnly;
          if (negoVatSelect) negoVatSelect.disabled = isReadOnly;

          // Populate opinions/memos
          if (state.poStatus === '결재중' || state.poStatus === '승인요청중') {
            state.poMemoInternal = '배송일정 긴급 조율 건';
            state.poMemoManager = '상반기 자재 소요 조기 수급을 위한 긴급 기안입니다. 빠른 재가 부탁드립니다.';
            state.poMemoCeo = '(검토 대기 중)';
          } else if (state.poStatus === '승인완료') {
            state.poMemoInternal = '식판 취급설비 납품 계약건';
            state.poMemoManager = '계약 조건에 따른 선금 지급 및 발주입니다.';
            state.poMemoCeo = '단가 조율이 양호하여 즉시 승인합니다.';
          } else if (state.poStatus === '승인반려') {
            state.poMemoInternal = '자재 수량 및 예산 초과분 긴급 검토';
            state.poMemoManager = '기존 단가 대비 할인율 적용하여 재상신합니다.';
            state.poMemoCeo = '예산 범위 한도를 5% 초과했습니다. 특수비용 항목(배송비/통관비) 단가 재협상하거나 수량 축소하여 재결재 기안하세요.';
          } else {
            // '작성중' or empty
            state.poMemoInternal = state.poMemoInternal || '';
            state.poMemoManager = state.poMemoManager || '';
            state.poMemoCeo = '';
          }

          const memoInternalEl = document.getElementById('po-memo-internal');
          const memoManagerEl = document.getElementById('po-memo-manager');
          const memoCeoEl = document.getElementById('po-memo-ceo');

          if (memoInternalEl) {
            memoInternalEl.value = state.poMemoInternal;
            memoInternalEl.readOnly = isReadOnly;
            memoInternalEl.style.background = isReadOnly ? '#f8fafc' : '#fff';
          }
          if (memoManagerEl) {
            memoManagerEl.value = state.poMemoManager;
            memoManagerEl.readOnly = isReadOnly;
            memoManagerEl.style.background = isReadOnly ? '#f8fafc' : '#fff';
          }
          if (memoCeoEl) {
            memoCeoEl.value = state.poMemoCeo;
          }

          // Render/Populate CEO Opinion Box at the top (Reference: docs_proc/pro.html)
          const ceoOpinionBox = document.getElementById('po-ceo-opinion-box');
          const ceoOpinionDot = document.getElementById('po-ceo-opinion-dot');
          const ceoOpinionTitle = document.getElementById('po-ceo-opinion-title');
          const ceoOpinionText = document.getElementById('po-ceo-opinion-text');

          if (ceoOpinionBox) {
            if (state.poStatus === '승인완료') {
              ceoOpinionBox.style.display = 'block';
              ceoOpinionBox.style.borderColor = '#bbf7d0';
              ceoOpinionBox.style.background = 'rgba(240, 253, 244, 0.6)';
              if (ceoOpinionDot) ceoOpinionDot.style.background = '#16a34a';
              if (ceoOpinionTitle) {
                ceoOpinionTitle.textContent = '최종 승인 의견 (CEO DECISION MEMO)';
                ceoOpinionTitle.style.color = '#15803d';
              }
              if (ceoOpinionText) {
                ceoOpinionText.textContent = state.poMemoCeo;
                ceoOpinionText.style.color = '#166534';
              }
            } else if (state.poStatus === '승인반려') {
              ceoOpinionBox.style.display = 'block';
              ceoOpinionBox.style.borderColor = '#fecdd3';
              ceoOpinionBox.style.background = 'rgba(255, 241, 242, 0.6)';
              if (ceoOpinionDot) ceoOpinionDot.style.background = '#e11d48';
              if (ceoOpinionTitle) {
                ceoOpinionTitle.textContent = '최종 반려 의견 (CEO REJECTION MEMO)';
                ceoOpinionTitle.style.color = '#be123c';
              }
              if (ceoOpinionText) {
                ceoOpinionText.textContent = state.poMemoCeo;
                ceoOpinionText.style.color = '#9f1239';
              }
            } else if (state.poStatus === '결재중' || state.poStatus === '승인요청중') {
              ceoOpinionBox.style.display = 'block';
              ceoOpinionBox.style.borderColor = '#fde047';
              ceoOpinionBox.style.background = 'rgba(254, 243, 199, 0.3)';
              if (ceoOpinionDot) ceoOpinionDot.style.background = '#d97706';
              if (ceoOpinionTitle) {
                ceoOpinionTitle.textContent = '대표 검토 의견 (CEO REVIEW PENDING)';
                ceoOpinionTitle.style.color = '#b45309';
              }
              if (ceoOpinionText) {
                ceoOpinionText.textContent = state.poMemoCeo;
                ceoOpinionText.style.color = '#78350f';
              }
            } else {
              ceoOpinionBox.style.display = 'none';
            }
          }

          const descEl = document.getElementById('po-detail-desc');
          const badgeEl = document.querySelector('#pg-po-detail .badge-teal');
          if (descEl) descEl.textContent = `${vname} · PO-2026-0156 — 발주 정보를 확인하고 확정합니다`;
          if (badgeEl) badgeEl.textContent = vname;

          if (items && items.length) {
            // 품목명+모델명으로 그룹핑
            const grouped = {};
            items.forEach((c, i) => {
              const key = `${c.name}_${c.model || ''}`;
              if (!grouped[key]) {
                grouped[key] = {
                  name: c.name,
                  model: c.model || 'MAT-' + (1000 + i),
                  spec: c.spec || '표준규격',
                  maker: c.maker || 'LG/삼성',
                  unit: c.unit || 'EA',
                  price: c.price,
                  note: '',
                  projects: []
                };
              }
              grouped[key].projects.push({
                projectName: c.project || '기본 프로젝트',
                qty: c.qty,
                key: c.key // 장바구니 키 (필요시)
              });
            });
            state.poItems = Object.values(grouped);
          } else {
            // 더미 데이터 (그룹핑 예시 포함)
            state.poItems = [
              {
                name: '베어링', model: '6232ZZ', spec: '6232ZZ,윤활유포함', maker: 'NYN', unit: 'EA', price: 600000, note: '',
                projects: [{ projectName: '보령-늘품업체', qty: 10 }]
              },
              {
                name: '커플링', model: 'DRB-SUS-16C', spec: '16mm', maker: 'NYN', unit: 'EA', price: 1080, note: '',
                projects: [
                  { projectName: '보령-늘품업체', qty: 13 },
                  { projectName: '근지단-우리업체', qty: 7 }
                ]
              },
              {
                name: '볼조인트', model: 'FJ 18', spec: '18mm', maker: 'NYN', unit: 'EA', price: 2040, note: '당진',
                projects: [{ projectName: '당진-현진업체', qty: 8 }]
              }
            ];
          }
          if (state.poStatus !== '승인완료') {
            state.poRefundMode = false;
            state.poRefundRequestStatus = null;
          }
          pollPoFinanceSync();
          updatePoPayRefundUI();
          updatePoItemsTbody();
          showPage('pg-po-detail');
        }

        // ===================== 발주서 ↔ 통합비용관리 연동 =====================
        const PO_ORIGIN_SN = 'PO-2026-0156';
        const PO_FINANCE_SYNC_KEY = 'erp_po_finance_sync';

        function getPoFinanceSync() {
          try {
            const all = JSON.parse(localStorage.getItem(PO_FINANCE_SYNC_KEY) || '{}');
            return all[PO_ORIGIN_SN] || null;
          } catch (e) { return null; }
        }

        function publishPoFinanceSyncFromNeo(patch) {
          try {
            const all = JSON.parse(localStorage.getItem(PO_FINANCE_SYNC_KEY) || '{}');
            all[PO_ORIGIN_SN] = { ...(all[PO_ORIGIN_SN] || {}), ...patch, updatedAt: Date.now() };
            localStorage.setItem(PO_FINANCE_SYNC_KEY, JSON.stringify(all));
          } catch (e) { }
        }

        function pollPoFinanceSync() {
          state.poFinanceSync = getPoFinanceSync();
          updatePoPayRefundUI();
        }

        // ===================== 발주서 환불 처리 =====================
        function canUsePoRefund() {
          const sync = state.poFinanceSync;
          return state.poStatus === '승인완료'
            && sync?.allowPoRefund
            && state.poRefundRequestStatus !== 'requested';
        }

        function updatePoPayRefundUI() {
          const sync = state.poFinanceSync;
          const payBadge = document.getElementById('po-pay-approval-badge');
          const detailEl = document.getElementById('po-finance-sync-detail');
          const preGuide = document.getElementById('po-pre-refund-guide');
          const refundBtn = document.getElementById('btn-po-refund-toggle');
          const hintEl = document.getElementById('po-refund-hint');
          const section = document.getElementById('po-refund-section');
          const banner = document.getElementById('po-refund-status-banner');

          const badgeClass = {
            '비용등록': 'badge-gray', '지급요청중': 'badge-blue', '지급대기': 'badge-amber',
            '승인반려': 'badge-red', '지급완료': 'badge-green', '발주종결': 'badge-red',
            '환불처리': 'badge-purple', '일부지급': 'badge-amber'
          };

          if (payBadge) {
            const label = sync?.financeStatus || (state.poStatus === '승인완료' ? '비용등록(대기)' : '미연동');
            payBadge.textContent = label;
            payBadge.className = 'badge ' + (badgeClass[label] || 'badge-gray');
          }

          if (detailEl) {
            if (!sync && state.poStatus !== '승인완료') {
              detailEl.textContent = '발주 결재 승인 후 통합비용관리로 비용이 등록됩니다.';
            } else if (!sync) {
              detailEl.textContent = '통합비용관리에서 비용 등록·지급 기안을 진행하세요.';
            } else {
              const paid = (sync.paidAmount || 0).toLocaleString();
              const total = (sync.totalAmount || 0).toLocaleString();
              detailEl.textContent = sync.message || `기지급 ${paid}원 / 총 ${total}원`;
            }
          }

          if (preGuide) {
            const showPre = state.poStatus === '승인완료' && sync && !sync.allowPoRefund && sync.financeStatus !== '발주종결';
            preGuide.style.display = showPre ? 'flex' : 'none';
          }

          if (hintEl) {
            if (state.poRefundRequestStatus === 'requested') {
              hintEl.textContent = '환불 승인 요청이 접수되었습니다. 통합비용관리에서 환불처리 상태로 추적됩니다.';
            } else if (state.poRefundMode) {
              const cap = sync?.paidAmount ? ` (환불 상한: 부가세 포함 약 ${Math.round(sync.paidAmount * 1.1).toLocaleString()}원)` : '';
              hintEl.textContent = `환불 수량·사유 입력 후 승인 요청하세요.${cap}`;
            } else if (canUsePoRefund()) {
              hintEl.textContent = '이미 지급된 금액 범위에서 환불 등록합니다. 미지급분은 통합비용관리에서 발주 종결로 처리하세요.';
            } else if (sync?.financeStatus === '발주종결') {
              hintEl.textContent = '발주가 종결되었습니다. 기지급분 환불은 통합비용관리 환불 건을 확인하세요.';
            } else if (state.poStatus === '승인완료') {
              hintEl.textContent = '통합비용관리에서 지급 기안·승인·이체 완료(또는 일부 이체) 후 환불 처리가 활성화됩니다.';
            } else {
              hintEl.textContent = '발주 결재 승인 후 통합비용관리 연동 → 지급 완료 후 환불 등록';
            }
          }

          if (refundBtn) {
            const inRefundMode = state.poRefundMode;
            const canStart = canUsePoRefund();
            refundBtn.disabled = !inRefundMode && !canStart;
            if (inRefundMode) {
              refundBtn.textContent = '환불 취소';
              refundBtn.className = 'btn btn-sm';
              refundBtn.style.cssText = 'background:#fecaca;border:1px solid #fca5a5;color:#991b1b;';
            } else {
              refundBtn.textContent = '환불 처리';
              refundBtn.className = 'btn btn-outline btn-sm';
              refundBtn.style.cssText = '';
            }
            refundBtn.title = canStart || inRefundMode
              ? '품목별 환불 수량 입력 (기지급 범위)'
              : '통합비용관리에서 지급 완료 후 이용';
          }

          if (section) {
            section.classList.toggle('open', !!state.poRefundMode);
          }

          if (banner) {
            if (state.poRefundRequestStatus === 'requested') {
              banner.style.display = 'block';
              banner.style.background = '#fef2f2';
              banner.style.border = '1px solid #fecaca';
              banner.style.color = '#991b1b';
              banner.textContent = `🔄 환불 승인 요청 접수 — ${state.poRefundReason || '(사유 없음)'}`;
            } else {
              banner.style.display = 'none';
            }
          }
        }

        function togglePoRefundMode() {
          if (state.poRefundMode) {
            cancelPoRefundMode();
            return;
          }
          if (!canUsePoRefund()) {
            toast(state.poStatus !== '승인완료'
              ? '발주 결재 승인 완료 후 이용할 수 있습니다.'
              : '통합비용관리에서 지급 완료(또는 일부 이체) 후 환불 처리가 가능합니다.');
            return;
          }
          state.poRefundMode = true;
          state.poRefundQtys = {};
          state.poItems.forEach((_, i) => { state.poRefundQtys[i] = 0; });
          const reasonEl = document.getElementById('po-refund-reason');
          if (reasonEl && !reasonEl.value) {
            reasonEl.value = '';
          }
          renderPoRefundTable();
          updatePoPayRefundUI();
        }

        function cancelPoRefundMode() {
          state.poRefundMode = false;
          updatePoPayRefundUI();
        }

        function renderPoRefundTable() {
          const tbody = document.getElementById('po-refund-tbody');
          if (!tbody) return;
          tbody.innerHTML = state.poItems.map((item, i) => {
            const maxQty = item.projects.reduce((s, p) => s + p.qty, 0);
            const projectLabel = item.projects.map(p => `${p.projectName}(${p.qty})`).join(', ');
            const qty = state.poRefundQtys[i] ?? 0;
            return `
        <tr style="border-bottom:1px solid #f1f5f9;">
          <td style="text-align:center;">${i + 1}</td>
          <td style="font-weight:600;">${item.name}</td>
          <td style="color:#64748b;">${item.model}</td>
          <td style="color:#64748b;font-size:12px;">${item.spec}</td>
          <td style="color:#64748b;">${item.maker}</td>
          <td style="text-align:center;">${item.unit}</td>
          <td style="text-align:center;">
            <input type="number" class="po-refund-qty-input" min="0" max="${maxQty}" value="${qty}"
              oninput="updatePoRefundQty(${i}, this.value, ${maxQty})" title="최대 ${maxQty}">
          </td>
          <td style="font-size:11px;color:#1e40af;">${projectLabel}</td>
          <td style="text-align:right;font-family:monospace;">${item.price.toLocaleString()}</td>
        </tr>`;
          }).join('');
          calcPoRefundAmount();
        }

        function updatePoRefundQty(idx, val, maxQty) {
          state.poRefundQtys[idx] = Math.min(maxQty, Math.max(0, parseInt(val, 10) || 0));
          calcPoRefundAmount();
        }

        function calcPoRefundAmount() {
          let supply = 0;
          state.poItems.forEach((item, i) => {
            supply += (state.poRefundQtys[i] || 0) * item.price;
          });
          const vat = Math.round(supply * 0.1);
          const el = document.getElementById('po-refund-amount');
          if (el) el.textContent = (supply + vat).toLocaleString() + '원';
          return supply + vat;
        }

        function requestPoRefundApproval() {
          const reason = (document.getElementById('po-refund-reason')?.value || '').trim();
          const totalQty = Object.values(state.poRefundQtys).reduce((s, q) => s + (q || 0), 0);
          if (!reason) {
            toast('환불 사유를 입력해주세요.');
            return;
          }
          if (totalQty === 0) {
            toast('환불 수량을 1개 이상 입력해주세요.');
            return;
          }
          const amount = calcPoRefundAmount();
          const cap = Math.round((state.poFinanceSync?.paidAmount || 0) * 1.1);
          if (cap > 0 && amount > cap) {
            toast(`환불 금액은 기지급 범위(${cap.toLocaleString()}원)를 초과할 수 없습니다.`);
            return;
          }
          state.poRefundReason = reason;
          state.poRefundRequestStatus = 'requested';
          state.poRefundMode = false;
          publishPoFinanceSyncFromNeo({
            financeStatus: '환불처리',
            allowPoRefund: false,
            message: `발주서 환불 요청 접수 — ${amount.toLocaleString()}원`
          });
          updatePoPayRefundUI();
          addLog(`발주서 ${PO_ORIGIN_SN} 환불 승인 요청 — ${amount.toLocaleString()}원 (${reason})`);
          toast(`🔄 환불 승인 요청 접수. 통합비용관리에서 마이너스 비용으로 연동됩니다.`);
        }

        function updatePoItemsTbody() {
          const tbody = document.getElementById('po-items-tbody');
          if (!tbody) return;

          const isReadOnly = (state.poStatus === '결재중' || state.poStatus === '승인요청중' || state.poStatus === '승인완료');

          let html = '';
          state.poItems.forEach((item, i) => {
            const totalQty = item.projects.reduce((s, p) => s + p.qty, 0);
            const subtotal = totalQty * item.price;
            const vat = Math.round(subtotal * 0.1);
            const total = subtotal + vat;

            // 메인 행
            html += `
      <tr style="background:#fff; font-weight:500;">
        <td style="text-align:center; color:#1a1a2e;">${i + 1}</td>
        <td><span style="color:#64748b; margin-right:4px;">▲</span> ${item.name}</td>
        <td style="color:#64748b;">${item.model}</td>
        <td style="color:#64748b;">${item.spec}</td>
        <td style="color:#64748b;">${item.maker}</td>
        <td style="text-align:center;">${item.unit}</td>
        <td style="text-align:center;">
          <input type="number" value="${totalQty}" readonly style="width:60px; text-align:center; border:1px solid #cbd5e1; border-radius:4px; background:#f8fafc; padding:4px;">
        </td>
        <td></td>
        <td style="text-align:right; font-family:monospace;">
          <input type="number" id="po-item-price-${i}" value="${item.price}" oninput="updatePoItemPrice(${i}, this.value)" onblur="updatePoItemsTbody()" style="width:100px; text-align:right; border:1px solid #cbd5e1; border-radius:4px; padding:4px; ${isReadOnly ? 'background:#f8fafc; color:#64748b;' : ''}" ${isReadOnly ? 'readonly' : ''}>
        </td>
        <td id="po-item-sub-${i}" style="text-align:right; font-family:monospace;">${subtotal.toLocaleString()}</td>
        <td id="po-item-vat-${i}" style="text-align:right; font-family:monospace; color:#64748b;">${vat.toLocaleString()}</td>
        <td id="po-item-total-${i}" style="text-align:right; font-family:monospace; font-weight:700;">${total.toLocaleString()}</td>
        <td><input type="text" value="${item.note}" oninput="state.poItems[${i}].note=this.value" style="width:100%; border:1px solid #cbd5e1; border-radius:4px; padding:4px; ${isReadOnly ? 'background:#f8fafc; color:#64748b;' : ''}" placeholder="${isReadOnly ? '' : '입력해 주세요.'}" ${isReadOnly ? 'readonly' : ''}></td>
        <td></td>
      </tr>
    `;

            // 서브 행 (프로젝트별)
            item.projects.forEach((p, pi) => {
              html += `
        <tr style="background:#fcfcfc; border-bottom:1px solid #f1f5f9;">
          <td></td>
          <td style="color:#94a3b8; padding-left:24px;">└ ${item.name}</td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
          <td style="text-align:center; color:#1e293b;">${p.qty}</td>
          <td style="color:#1e3a8a; font-weight:500;">${p.projectName}</td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
          <td style="text-align:center;">
            ${isReadOnly ? '' : `<button onclick="deletePoProject(${i}, ${pi})" style="color:#94a3b8; border:1px solid #e2e8f0; background:#fff; border-radius:4px; padding:2px 6px; cursor:pointer;">✕</button>`}
          </td>
        </tr>
      `;
            });
          });

          tbody.innerHTML = html;
          calcPoTotal();
        }

        function updatePoItemPrice(idx, val) {
          const price = parseInt(val) || 0;
          state.poItems[idx].price = price;

          const item = state.poItems[idx];
          const totalQty = item.projects.reduce((s, p) => s + p.qty, 0);
          const subtotal = totalQty * price;
          const vat = Math.round(subtotal * 0.1);
          const total = subtotal + vat;

          const subEl = document.getElementById(`po-item-sub-${idx}`);
          const vatEl = document.getElementById(`po-item-vat-${idx}`);
          const totEl = document.getElementById(`po-item-total-${idx}`);

          if (subEl) subEl.textContent = subtotal.toLocaleString();
          if (vatEl) vatEl.textContent = vat.toLocaleString();
          if (totEl) totEl.textContent = total.toLocaleString();

          calcPoTotal();
        }

        function deletePoProject(itemIdx, projIdx) {
          state.poItems[itemIdx].projects.splice(projIdx, 1);
          if (state.poItems[itemIdx].projects.length === 0) {
            state.poItems.splice(itemIdx, 1);
          }
          updatePoItemsTbody();
          toast('🗑 해당 프로젝트 품목이 발주에서 제외되었습니다.');
        }

        state.specialCosts = [];
        function addSpecialCost() {
          const msg = document.getElementById('no-special-msg');
          const tbl = document.getElementById('sc-table');
          if (msg) msg.style.display = 'none';
          if (tbl) tbl.style.display = 'table';

          const sc = { id: Date.now(), name: '', qty: 1, price: 0, vatType: '별도' };
          state.specialCosts.push(sc);
          renderSpecialCosts();
        }

        function updateSC(id, field, val) {
          const sc = state.specialCosts.find(s => s.id === id);
          if (!sc) return;

          if (field === 'qty' || field === 'price') sc[field] = parseInt(val) || 0;
          else sc[field] = val;

          // 개별 행 업데이트
          const idx = state.specialCosts.indexOf(sc);
          const subtotal = sc.qty * sc.price;
          let vat = 0;
          if (sc.vatType === '별도') vat = Math.round(subtotal * 0.1);
          else if (sc.vatType === '포함') vat = Math.round(subtotal - (subtotal / 1.1));
          const total = sc.vatType === '별도' ? subtotal + vat : subtotal;
          const supply = sc.vatType === '포함' ? subtotal - vat : subtotal;

          const supEl = document.getElementById(`sc-sup-${idx}`);
          const vatEl = document.getElementById(`sc-vat-${idx}`);
          const totEl = document.getElementById(`sc-tot-${idx}`);

          if (supEl) supEl.textContent = supply.toLocaleString();
          if (vatEl) vatEl.textContent = vat.toLocaleString();
          if (totEl) totEl.textContent = total.toLocaleString();

          calcPoTotal();
        }

        function removeSC(id) {
          state.specialCosts = state.specialCosts.filter(s => s.id !== id);
          if (state.specialCosts.length === 0) {
            document.getElementById('no-special-msg').style.display = 'block';
            document.getElementById('sc-table').style.display = 'none';
          }
          renderSpecialCosts();
        }

        function renderSpecialCosts() {
          const tbody = document.getElementById('sc-tbody');
          if (!tbody) return;

          const isReadOnly = (state.poStatus === '결재중' || state.poStatus === '승인요청중' || state.poStatus === '승인완료');

          tbody.innerHTML = state.specialCosts.map((sc, i) => {
            const sub = sc.qty * sc.price;
            const vat = sc.vatType === '별도' ? Math.round(sub * 0.1) : (sc.vatType === '포함' ? Math.round(sub - (sub / 1.1)) : 0);
            const total = sc.vatType === '별도' ? sub + vat : sub;
            const supply = sc.vatType === '포함' ? sub - vat : sub;

            return `
      <tr>
        <td style="text-align:center;color:#94a3b8;font-size:11px;">${i + 1}</td>
        <td><input type="text" value="${sc.name}" oninput="updateSC(${sc.id}, 'name', this.value)" style="width:100%;border:1px solid #cbd5e1;border-radius:4px;padding:4px; ${isReadOnly ? 'background:#f8fafc; color:#64748b;' : ''}" ${isReadOnly ? 'readonly' : ''}></td>
        <td style="text-align:center;"><input type="number" value="${sc.qty}" oninput="updateSC(${sc.id}, 'qty', this.value)" style="width:60px;text-align:center;border:1px solid #cbd5e1;border-radius:4px;padding:4px; ${isReadOnly ? 'background:#f8fafc; color:#64748b;' : ''}" ${isReadOnly ? 'readonly' : ''}></td>
        <td style="text-align:right;"><input type="number" value="${sc.price}" oninput="updateSC(${sc.id}, 'price', this.value)" style="width:100px;text-align:right;border:1px solid #cbd5e1;border-radius:4px;padding:4px; ${isReadOnly ? 'background:#f8fafc; color:#64748b;' : ''}" ${isReadOnly ? 'readonly' : ''}></td>
        <td>
          <select onchange="updateSC(${sc.id}, 'vatType', this.value); renderSpecialCosts();" style="width:100%;border:1px solid #cbd5e1;border-radius:4px;font-size:11px;padding:4px;" ${isReadOnly ? 'disabled' : ''}>
            <option value="별도" ${sc.vatType === '별도' ? 'selected' : ''}>부가세 별도</option>
            <option value="포함" ${sc.vatType === '포함' ? 'selected' : ''}>부가세 포함</option>
            <option value="면세" ${sc.vatType === '면세' ? 'selected' : ''}>면세</option>
          </select>
        </td>
        <td id="sc-sup-${i}" style="text-align:right;font-family:monospace;font-size:12px;">${supply.toLocaleString()}</td>
        <td id="sc-vat-${i}" style="text-align:right;font-family:monospace;font-size:12px;">${vat.toLocaleString()}</td>
        <td id="sc-tot-${i}" style="text-align:right;font-family:monospace;font-size:12px;font-weight:700;">${total.toLocaleString()}</td>
        <td style="text-align:center;">
          ${isReadOnly ? '' : `<button onclick="removeSC(${sc.id})" style="color:#dc2626;border:none;background:none;cursor:pointer;font-size:14px;">✕</button>`}
        </td>
      </tr>
    `;
          }).join('');
          calcPoTotal();
        }

        function calcPoTotal() {
          // 품목 소계
          let itemSub = state.poItems.reduce((s, item) => {
            const totalQty = item.projects.reduce((qs, p) => qs + p.qty, 0);
            return s + (item.price * totalQty);
          }, 0);

          // 특수비용 계산
          let scSupply = 0;
          let scVat = 0;
          state.specialCosts.forEach(sc => {
            const sub = sc.qty * sc.price;
            if (sc.vatType === '별도') {
              scSupply += sub;
              scVat += Math.round(sub * 0.1);
            } else if (sc.vatType === '포함') {
              const v = Math.round(sub - (sub / 1.1));
              scSupply += (sub - v);
              scVat += v;
            } else {
              scSupply += sub;
            }
          });

          // 할인 계산
          const negoAmt = parseInt(document.getElementById('nego-amount')?.value) || 0;
          const negoType = document.getElementById('nego-vat-type')?.value || '별도';
          let negoSupply = 0;
          let negoVat = 0;
          if (negoType === '별도') {
            negoSupply = negoAmt;
            negoVat = Math.round(negoAmt * 0.1);
          } else if (negoType === '포함') {
            negoVat = Math.round(negoAmt - (negoAmt / 1.1));
            negoSupply = negoAmt - negoVat;
          } else {
            negoSupply = negoAmt;
          }

          // 최종 합산
          const totalSupply = itemSub + scSupply - negoSupply;
          const itemVat = Math.round(itemSub * 0.1);
          const totalVat = itemVat + scVat - negoVat;

          const subEl = document.getElementById('po-subtotal');
          const specEl = document.getElementById('po-special');
          const negoEl = document.getElementById('po-nego');
          const supplyEl = document.getElementById('po-supply');
          const vatEl = document.getElementById('po-vat-amt');
          const finalEl = document.getElementById('po-final');

          if (subEl) subEl.textContent = itemSub.toLocaleString() + '원';
          if (specEl) specEl.textContent = (scSupply + scVat).toLocaleString() + '원';
          if (negoEl) negoEl.textContent = (negoAmt).toLocaleString() + '원';
          if (supplyEl) supplyEl.textContent = totalSupply.toLocaleString() + '원';
          if (vatEl) vatEl.textContent = totalVat.toLocaleString() + '원';
          if (finalEl) finalEl.textContent = (totalSupply + totalVat).toLocaleString() + '원';

          // 선택현황 업데이트
          const cntEl = document.getElementById('po-sel-count');
          const barEl = document.getElementById('po-sel-bar');
          if (cntEl) cntEl.textContent = `${state.poItems.length} / ${state.poItems.length}개`;
          if (barEl) barEl.style.width = '100%';
        }

        function selectPoPayMethod(method) {
          if (state.poStatus === '결재중' || state.poStatus === '승인요청중' || state.poStatus === '승인완료') {
            return; // locked in read-only statuses
          }
          state.poPaymentMethod = method;
          updatePoPayMethodUI();
        }

        function updatePoPayMethodUI() {
          const methods = ['계좌이체', '카드', '현금'];
          const ids = {
            '계좌이체': 'po-pay-transfer',
            '카드': 'po-pay-card',
            '현금': 'po-pay-cash'
          };

          methods.forEach(m => {
            const btn = document.getElementById(ids[m]);
            if (!btn) return;
            const isReadOnly = (state.poStatus === '결재중' || state.poStatus === '승인요청중' || state.poStatus === '승인완료');
            btn.disabled = isReadOnly;
            btn.style.cursor = isReadOnly ? 'not-allowed' : 'pointer';
            btn.style.opacity = (isReadOnly && state.poPaymentMethod !== m) ? '0.5' : '1';

            if (state.poPaymentMethod === m) {
              btn.style.borderColor = '#2563eb';
              btn.style.background = '#eff6ff';
              btn.style.color = '#1d4ed8';
              btn.style.boxShadow = '0 0 0 2px rgba(37,99,235,0.2)';
            } else {
              btn.style.borderColor = '#cbd5e1';
              btn.style.background = isReadOnly ? '#f8fafc' : '#fff';
              btn.style.color = '#64748b';
              btn.style.boxShadow = 'none';
            }
          });
        }

        // ===================== 발주서 목록 — 역할/탭 관리 =====================
        // 목업 발주서 데이터 (역할별 승인 시뮬레이션용)
        const PO_APPROVAL_DATA = [
          {
            id: 'PO-2026-0156', date: '2026-05-20', vendor: '㈜한솔무역',
            name: '2026년 상반기 통신 경상자재 납품', total: 36850000,
            manager: '구매담당자', role: 'buyer',
            approvalStep: 'pending_mgr',  // pending_mgr | pending_ceo | approved | rejected
            mgrComment: '', ceoComment: '',
            items: [], isMain: true  // 주 시뮬레이션 건
          },
          {
            id: 'PO-2026-0155', date: '2026-05-18', vendor: '㈜글로벌서플라이',
            name: '현장 소모품 정기 구매', total: 12500000,
            manager: '구매담당자', role: 'buyer',
            approvalStep: 'pending_ceo',
            mgrComment: '품목·단가 검토 완료. 대표 승인 요청합니다.', ceoComment: '',
          },
          {
            id: 'PO-2026-0154', date: '2026-05-15', vendor: '통신산업',
            name: '식판 취급설비 납품 건', total: 855000,
            manager: '중간관리자', role: 'mgr',
            approvalStep: 'approved',
            mgrComment: '', ceoComment: '검토 완료. 즉시 발주 진행 승인.',
          },
          {
            id: 'PO-2026-0153', date: '2026-05-12', vendor: '유진공업',
            name: '경상자재 예비 부품 건', total: 340000,
            manager: '구매담당자', role: 'buyer',
            approvalStep: 'rejected',
            mgrComment: '세금계산서 미발행. 수정 후 재기안 요청.', ceoComment: '',
          },
          {
            id: 'PO-2026-0152', date: '2026-05-10', vendor: '㈜미래기술',
            name: 'IT 인프라 장비 구매', total: 22000000,
            manager: '팀원A', role: 'buyer',
            approvalStep: 'pending_mgr',
            mgrComment: '', ceoComment: '',
          },
        ];

        let poListRole = 'buyer';    // buyer | mgr | ceo
        let poListTab = 'mine';      // mine | all

        function setPoListRole(role) {
          poListRole = role;
          if (role === 'ceo') { 
             showPage('pg-ceo-approval');
             renderCeoView();
             return;
          }
          else { 
             showPage('pg-po-list');
             poListTab = 'mine'; switchPoTab('mine', true); 
          }

          ['buyer','mgr','ceo'].forEach(r => {
            const btn = document.getElementById(`po-role-btn-${r}`);
            if (!btn) return;
            const isActive = r === role;
            btn.style.background = isActive ? (r === 'ceo' ? '#be123c' : r === 'mgr' ? '#7c3aed' : '#2563eb') : '#fff';
            btn.style.color = isActive ? '#fff' : '#64748b';
          });

          const bannerEl = document.getElementById('po-list-role-banner-text');
          const descEl = document.getElementById('po-list-role-desc');
          const bannerBox = document.getElementById('po-list-role-banner');
          const banners = {
            buyer: { text: '내가 기안한 발주서 목록입니다. 각 건의 <strong>진행상태</strong>를 확인할 수 있습니다.', bg: '#eff6ff', border: '#3b82f6', desc: '구매담당자 · 내 발주서' },
            mgr:   { text: '<strong>내 발주서</strong>는 본인 기안 건, <strong>전체 발주관리</strong>는 팀원 발주서를 포함한 전체 목록을 조회합니다. (승인/반려 권한 없음)', bg: '#faf5ff', border: '#7c3aed', desc: '중간관리자 · 발주서 조회' },
            ceo:   { text: '승인 대기 발주서는 <strong>검토하기</strong> 버튼을 눌러 발주 내용을 직접 확인한 후 최종 승인 또는 반려합니다.', bg: '#fff1f2', border: '#be123c', desc: '대표이사 · 전체 발주 최종 결재' },
          };
          if (bannerEl) bannerEl.innerHTML = banners[role].text;
          if (descEl) descEl.textContent = banners[role].desc;
          if (bannerBox) { bannerBox.style.background = banners[role].bg; bannerBox.style.borderLeftColor = banners[role].border; }

          // buyer: 전체 발주관리 탭 숨기기
          const allTabEl = document.getElementById('po-tab-all');
          if (allTabEl) allTabEl.style.display = role === 'buyer' ? 'none' : 'flex';

          renderPoListFull();
        }

        function switchPoTab(tab, skipRender) {
          poListTab = tab;
          const mineTab = document.getElementById('po-tab-mine');
          const allTab = document.getElementById('po-tab-all');
          if (mineTab) {
            mineTab.style.borderBottomColor = tab === 'mine' ? '#2563eb' : 'transparent';
            mineTab.style.color = tab === 'mine' ? '#2563eb' : '#64748b';
            mineTab.style.fontWeight = tab === 'mine' ? '600' : '500';
          }
          if (allTab) {
            allTab.style.borderBottomColor = tab === 'all' ? '#2563eb' : 'transparent';
            allTab.style.color = tab === 'all' ? '#2563eb' : '#64748b';
            allTab.style.fontWeight = tab === 'all' ? '600' : '500';
          }
          if (!skipRender) renderPoListFull();
        }

        function renderPoListFull() {
          const tbody = document.getElementById('po-list-body');
          if (!tbody) return;

          // 역할에 따라 "액션" 컬럼 헤더 표시/숨기기
          const actionTh = document.getElementById('po-list-th-action');
          if (actionTh) actionTh.style.display = poListRole === 'buyer' ? 'none' : '';

          // 역할/탭에 따라 데이터 필터
          let filtered = PO_APPROVAL_DATA.filter(po => {
            if (poListRole === 'buyer') {
              // 구매담당자: 본인(buyer role) 발주서만
              return poListTab === 'mine' ? po.role === 'buyer' && po.manager === '구매담당자' : po.role === 'buyer';
            } else if (poListRole === 'mgr') {
              // 중간관리자: mine=본인기안, all=팀원(buyer) 기안 + 본인기안 전체
              if (poListTab === 'mine') return po.role === 'mgr';
              return true; // 전체: 팀원+본인
            } else {
              // CEO: all만 (전체 표시)
              return true;
            }
          });

          // 역할별 승인 대기 건 배지 업데이트
          const pendingAll = PO_APPROVAL_DATA.filter(po => {
            if (poListRole === 'mgr') return po.approvalStep === 'pending_mgr';
            if (poListRole === 'ceo') return po.approvalStep === 'pending_ceo';
            return false;
          });
          const badgeEl = document.getElementById('po-tab-all-badge');
          if (badgeEl) {
            badgeEl.textContent = pendingAll.length > 0 ? pendingAll.length : '';
            badgeEl.style.display = pendingAll.length > 0 ? 'inline-flex' : 'none';
          }

          // 결재단계 라벨
          const stepLabel = {
            pending_mgr: { text: '중간관리자 검토', color: '#d97706', bg: '#fffbeb', border: '#fcd34d' },
            pending_ceo: { text: '대표이사 검토', color: '#be123c', bg: '#fff1f2', border: '#fecdd3' },
            approved:    { text: '최종 승인', color: '#16a34a', bg: '#f0fdf4', border: '#86efac' },
            rejected:    { text: '반려', color: '#dc2626', bg: '#fef2f2', border: '#fca5a5' },
          };

          // 역할별 액션 버튼 생성
          function getActionBtn(po) {
            // 구매담당자: 액션 없음 (진행상태만 표시)
            if (poListRole === 'buyer') return '';
            // 중간관리자: 상세 보기만 (승인/반려 없음)
            if (poListRole === 'mgr') {
              return `<button class="btn btn-outline btn-sm" onclick="loadPoDetail('${po.vendor}', [], '${po.approvalStep === 'approved' ? '승인완료' : po.approvalStep === 'rejected' ? '승인반려' : '결재중'}')">상세 보기</button>`;
            }
            // 대표이사: 검토 모달 열기 (목록에서 바로 승인/반려 불가)
            if (poListRole === 'ceo') {
              if (po.approvalStep === 'pending_ceo') {
                return `<button class="btn btn-sm" style="background:#be123c;color:#fff;border:none;" onclick="openCeoReview('${po.id}')">🔍 검토하기</button>`;
              }
              return `<button class="btn btn-outline btn-sm" onclick="openCeoReview('${po.id}')">내용 보기</button>`;
            }
            return '';
          }

          if (filtered.length === 0) {
            tbody.innerHTML = `<tr><td colspan="9" style="text-align:center;padding:32px;color:#94a3b8;">조건에 맞는 발주서가 없습니다.</td></tr>`;
            return;
          }

          tbody.innerHTML = filtered.map((po, idx) => {
            const step = stepLabel[po.approvalStep] || stepLabel['approved'];
            const isHighlight = (poListRole === 'ceo' && po.approvalStep === 'pending_ceo');
            const statusBadge = `<span class="badge ${po.approvalStep === 'approved' ? 'badge-green' : po.approvalStep === 'rejected' ? 'badge-red' : po.approvalStep === 'pending_ceo' ? 'badge-purple' : 'badge-amber'}">${po.approvalStep === 'approved' ? '승인완료' : po.approvalStep === 'rejected' ? '반려' : po.approvalStep === 'pending_ceo' ? '대표검토중' : '1차검토중'}</span>`;
            const actionCell = poListRole === 'buyer' ? '' : `<td style="text-align:center;">${getActionBtn(po)}</td>`;
            return `
              <tr style="${isHighlight ? 'background:#fff8f8;border-left:3px solid #be123c;' : ''}cursor:pointer;" onclick="poListRole==='ceo'?openCeoReview('${po.id}'):void(0)">
                <td style="text-align:center;color:#94a3b8;">${idx + 1}</td>
                <td style="font-size:11px;color:#64748b;">${po.date}</td>
                <td style="font-size:12px;font-weight:600;color:#475569;">${po.manager}</td>
                <td style="font-weight:600;">${po.vendor}</td>
                <td style="color:#2563eb;font-weight:600;">${po.id} <span style="color:#334155;font-weight:500;">${po.name}</span></td>
                <td style="font-family:monospace;text-align:right;font-weight:700;">${po.total.toLocaleString()}원</td>
                <td style="text-align:center;">${statusBadge}</td>
                ${actionCell}
              </tr>`;
          }).join('');
        }

        // 중간관리자 1차 승인
        function poMgrApprove(poId) {
          const po = PO_APPROVAL_DATA.find(p => p.id === poId);
          if (!po) return;
          const comment = prompt(`[${poId}] 1차 승인 의견 (선택사항, 생략 시 기본 메시지 사용):`, '품목·단가 검토 완료. 대표 승인 요청합니다.');
          if (comment === null) return; // 취소
          po.approvalStep = 'pending_ceo';
          po.mgrComment = comment || '품목·단가 검토 완료. 대표 승인 요청합니다.';
          toast(`✅ [${poId}] 1차 승인 완료 — 대표이사 결재 상신되었습니다.`);
          addLog(`중간관리자 1차 승인: ${poId} → 대표이사 결재 상신`);
          renderPoListFull();
        }

        // 중간관리자 반려
        function poMgrReject(poId) {
          const po = PO_APPROVAL_DATA.find(p => p.id === poId);
          if (!po) return;
          const comment = prompt(`[${poId}] 반려 사유를 입력하세요:`);
          if (!comment) { toast('반려 사유를 입력해야 합니다.'); return; }
          po.approvalStep = 'rejected';
          po.mgrComment = comment;
          toast(`❌ [${poId}] 반려 처리 — 담당자에게 수정 요청됩니다.`);
          addLog(`중간관리자 반려: ${poId} — ${comment}`);
          renderPoListFull();
        }

        // 대표이사 검토 모달 열기
        function openCeoReview(poId) {
          const po = PO_APPROVAL_DATA.find(p => p.id === poId);
          if (!po) return;
          const modal = document.getElementById('ceo-review-modal');
          if (!modal) return;

          const isPending = po.approvalStep === 'pending_ceo';
          const stepText = { pending_mgr: '1차 검토중', pending_ceo: '대표 검토 대기', approved: '승인완료', rejected: '반려' };
          const stepColor = { pending_mgr: '#d97706', pending_ceo: '#be123c', approved: '#16a34a', rejected: '#dc2626' };

          // 모달 품목 목업 (실제 품목이 없으면 기본 목업 표시)
          const itemRows = (po._cartItems && po._cartItems.length > 0)
            ? po._cartItems.slice(0, 5).map((it, i) => `
              <tr>
                <td style="text-align:center;color:#94a3b8;">${i+1}</td>
                <td style="font-weight:500;">${it.name || '-'}</td>
                <td style="color:#64748b;">${it.model || '-'}</td>
                <td style="text-align:center;">${it.qty || 1}${it.unit || 'EA'}</td>
                <td style="text-align:right;font-family:monospace;">${(it.price||0).toLocaleString()}원</td>
                <td style="text-align:right;font-family:monospace;font-weight:700;">${((it.price||0)*(it.qty||1)).toLocaleString()}원</td>
              </tr>`).join('')
            : `<tr>
                <td style="text-align:center;color:#94a3b8;">1</td>
                <td style="font-weight:500;">경상자재 (품목 일괄)</td>
                <td style="color:#64748b;">—</td>
                <td style="text-align:center;">일식</td>
                <td style="text-align:right;font-family:monospace;">${po.total.toLocaleString()}원</td>
                <td style="text-align:right;font-family:monospace;font-weight:700;">${po.total.toLocaleString()}원</td>
              </tr>`;

          const supply = Math.round(po.total / 1.1);
          const vat = po.total - supply;

          document.getElementById('ceo-review-content').innerHTML = `
            <!-- 상단: 발주서 기본 정보 -->
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px;">
              <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;padding:14px 16px;">
                <div style="font-size:10px;font-weight:700;color:#94a3b8;letter-spacing:.08em;margin-bottom:10px;">발주서 정보</div>
                <div style="display:flex;flex-direction:column;gap:6px;font-size:12px;">
                  <div style="display:flex;justify-content:space-between;"><span style="color:#64748b;">발주번호</span><span style="font-weight:700;font-family:monospace;">${po.id}</span></div>
                  <div style="display:flex;justify-content:space-between;"><span style="color:#64748b;">거래처</span><span style="font-weight:700;">${po.vendor}</span></div>
                  <div style="display:flex;justify-content:space-between;"><span style="color:#64748b;">담당자</span><span style="font-weight:600;">${po.manager}</span></div>
                  <div style="display:flex;justify-content:space-between;"><span style="color:#64748b;">기안일</span><span>${po.date}</span></div>
                  <div style="display:flex;justify-content:space-between;"><span style="color:#64748b;">결재단계</span><span style="font-weight:700;color:${stepColor[po.approvalStep]}">${stepText[po.approvalStep]}</span></div>
                </div>
              </div>
              <div style="background:#1a1a2e;border-radius:10px;padding:14px 16px;color:#fff;">
                <div style="font-size:10px;font-weight:700;color:#94a3b8;letter-spacing:.08em;margin-bottom:10px;">발주 금액</div>
                <div style="display:flex;flex-direction:column;gap:6px;font-size:12px;">
                  <div style="display:flex;justify-content:space-between;opacity:.8;"><span>공급가액</span><span style="font-family:monospace;">${supply.toLocaleString()}원</span></div>
                  <div style="display:flex;justify-content:space-between;opacity:.8;"><span>부가세 (10%)</span><span style="font-family:monospace;">${vat.toLocaleString()}원</span></div>
                  <div style="display:flex;justify-content:space-between;border-top:1px solid rgba(255,255,255,.2);padding-top:8px;margin-top:4px;">
                    <span style="font-size:14px;font-weight:700;">최종 발주 총액</span>
                    <span style="font-size:18px;font-weight:800;font-family:monospace;">${po.total.toLocaleString()}원</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- 발주 명세 -->
            <div style="margin-bottom:20px;">
              <div style="font-size:12px;font-weight:700;color:#1e293b;margin-bottom:8px;">📋 발주 품목 내역</div>
              <div style="border:1px solid #e2e8f0;border-radius:8px;overflow:hidden;">
                <table style="width:100%;border-collapse:collapse;font-size:12px;">
                  <thead><tr style="background:#f8fafc;">
                    <th style="padding:8px 10px;text-align:center;color:#64748b;font-weight:600;width:36px;">No</th>
                    <th style="padding:8px 10px;text-align:left;color:#64748b;font-weight:600;">품목명</th>
                    <th style="padding:8px 10px;color:#64748b;font-weight:600;">모델/규격</th>
                    <th style="padding:8px 10px;text-align:center;color:#64748b;font-weight:600;width:60px;">수량</th>
                    <th style="padding:8px 10px;text-align:right;color:#64748b;font-weight:600;width:110px;">단가</th>
                    <th style="padding:8px 10px;text-align:right;color:#64748b;font-weight:600;width:120px;">소계</th>
                  </tr></thead>
                  <tbody>${itemRows}</tbody>
                </table>
              </div>
            </div>

            <!-- 중간관리자 의견 -->
            ${po.mgrComment ? `
            <div style="background:#faf5ff;border:1px solid #e9d5ff;border-radius:8px;padding:12px 14px;margin-bottom:16px;">
              <div style="font-size:10px;font-weight:700;color:#7c3aed;letter-spacing:.08em;margin-bottom:6px;">💬 중간관리자 검토 의견</div>
              <div style="font-size:13px;color:#3b0764;font-weight:500;">${po.mgrComment}</div>
            </div>` : ''}

            <!-- CEO 의견 입력 또는 결과 표시 -->
            ${isPending ? `
            <div style="margin-bottom:4px;">
              <label style="font-size:11px;font-weight:700;color:#64748b;display:block;margin-bottom:6px;">✍️ 결재 의견 (선택사항)</label>
              <textarea id="ceo-review-comment" placeholder="승인 또는 반려 사유를 입력하세요..." style="width:100%;padding:10px 12px;border:1px solid #e2e8f0;border-radius:8px;font-size:13px;font-family:inherit;resize:vertical;min-height:72px;outline:none;"></textarea>
            </div>` : po.ceoComment ? `
            <div style="background:#f0fdf4;border:1px solid #86efac;border-radius:8px;padding:12px 14px;">
              <div style="font-size:10px;font-weight:700;color:#16a34a;letter-spacing:.08em;margin-bottom:6px;">✅ 대표이사 결재 의견</div>
              <div style="font-size:13px;color:#14532d;font-weight:500;">${po.ceoComment}</div>
            </div>` : ''}
          `;

          // 승인/반려 버튼 표시 여부
          const footerBtns = document.getElementById('ceo-review-footer-btns');
          if (footerBtns) footerBtns.style.display = isPending ? 'flex' : 'none';
          // 현재 검토 대상 poId 저장
          modal.dataset.currentPoId = poId;
          modal.classList.add('open');
        }

        function closeCeoReview() {
          const modal = document.getElementById('ceo-review-modal');
          if (modal) modal.classList.remove('open');
        }

        function submitCeoReview(action) {
          const modal = document.getElementById('ceo-review-modal');
          const poId = modal?.dataset?.currentPoId;
          const po = PO_APPROVAL_DATA.find(p => p.id === poId);
          if (!po) return;
          const comment = document.getElementById('ceo-review-comment')?.value?.trim();
          if (action === 'reject' && !comment) {
            document.getElementById('ceo-review-comment').style.borderColor = '#ef4444';
            document.getElementById('ceo-review-comment').placeholder = '반려 시 사유 입력은 필수입니다.';
            return;
          }
          const finalComment = comment || (action === 'approve' ? '검토 완료. 발주 진행 승인합니다.' : '');
          po.approvalStep = action === 'approve' ? 'approved' : 'rejected';
          po.ceoComment = finalComment;
          closeCeoReview();
          if (action === 'approve') {
            toast(`✅ [${poId}] 최종 승인 완료 — 거래처에 발주서 PDF가 자동 발송됩니다.`);
            addLog(`대표이사 최종 승인: ${poId} — ${finalComment}`);
            if (po.isMain) { state.poMemoCeo = finalComment; loadPoDetail(po.vendor, state.poItems, '승인완료'); syncToFinance(); }
          } else {
            toast(`❌ [${poId}] 반려 처리 완료. 담당자에게 수정이 요청됩니다.`);
            addLog(`대표이사 반려: ${poId} — ${finalComment}`);
            if (po.isMain) { state.poMemoCeo = finalComment; loadPoDetail(po.vendor, state.poItems, '승인반려'); }
          }
          renderPoListFull();
        }

        // 대표이사 최종 승인 (구 방식 — 하위 호환)
        function poCeoApprove(poId) { openCeoReview(poId); }

        // 대표이사 반려 (구 방식 — 하위 호환)
        function poCeoReject(poId) { openCeoReview(poId); }

        function requestApproval() {
          // 구매담당자가 기안 → 중간관리자 1차 승인 대기로 상신
          toast('📝 결재 요청이 중간관리자에게 상신되었습니다. 중간관리자 역할로 전환하여 1차 승인을 해보세요.');
          addLog(`발주서 PO-2026-0156 결재 상신 (결제수단: ${state.poPaymentMethod}) → 중간관리자 1차 검토 대기`);
          // 주 시뮬레이션 건 상태 업데이트
          const mainPo = PO_APPROVAL_DATA.find(p => p.isMain);
          if (mainPo) mainPo.approvalStep = 'pending_mgr';
          const vname = document.querySelector('#pg-po-detail .badge-teal')?.textContent || '㈜한솔무역';
          loadPoDetail(vname, state.poItems, '결재중');
        }

        function approvePoSim() {
          toast('✅ 승인 완료! 해당 발주 정보가 통합비용관리(AP 대장)로 즉시 이관됩니다.');
          addLog(`대표이사 발주 승인 완료 → 통합비용관리 이관 (결제수단: ${state.poPaymentMethod})`);

          const vname = document.querySelector('#pg-po-detail .badge-teal')?.textContent || '㈜한솔무역';
          state.poMemoCeo = '단가 조율이 양호하며 담당자 검토 의견에 따라 즉시 승인합니다.';
          state.poRefundRequestStatus = null;
          state.poRefundMode = false;
          loadPoDetail(vname, state.poItems, '승인완료');

          // Sync directly with Consolidated Finance
          syncToFinance();
        }

        function rejectPoSim() {
          toast('❌ 발주서 반려 완료. 담당자가 품목 정보 및 의견을 보완하여 재기안할 수 있습니다.');
          addLog('대표이사 발주 반려 처리');

          const vname = document.querySelector('#pg-po-detail .badge-teal')?.textContent || '㈜한솔무역';
          state.poMemoCeo = '예산 범위 한도를 5% 초과했습니다. 특수비용 항목 단가 재협상하거나 수량 축소하여 재결재 기안하세요.';
          loadPoDetail(vname, state.poItems, '승인반려');
        }

        function syncToFinance() {
          const sharedKey = 'erp_shared_payables';
          let current = [];
          try {
            current = JSON.parse(localStorage.getItem(sharedKey) || '[]');
          } catch (e) {
            current = [];
          }

          // Calculate total amount
          let itemSupply = 0;
          state.poItems.forEach(item => {
            const totalQty = item.projects.reduce((s, p) => s + p.qty, 0);
            itemSupply += item.price * totalQty;
          });

          // Special costs
          let specialSum = 0;
          (state.specialCosts || []).forEach(sc => {
            specialSum += sc.amount || 0;
          });

          // Nego / discount
          const negoVal = parseFloat(document.getElementById('nego-amount')?.value || 0);

          const supply = itemSupply + specialSum - negoVal;
          const vat = Math.round(supply * 0.1);
          const total = supply + vat;

          const vname = document.querySelector('#pg-po-detail .badge-teal')?.textContent || '㈜한솔무역';

          const pbl = {
            pbl_sn: 'PBL-' + Date.now(),
            pbl_payable_status: 'APPROVED',
            pt_name: vname,
            pbl_total_amount: total,
            pbl_proof_details: [{
              method: state.poPaymentMethod || '계좌이체',
              proof_filename: '발주서_PO-2026-0156.pdf',
              account: {
                bank: '기업은행',
                number: '110-482-192801',
                holder: vname
              }
            }],
            cost_items: state.poItems.map(itm => {
              const totalQty = itm.projects.reduce((s, p) => s + p.qty, 0);
              return {
                name: itm.name,
                type: '발주자재',
                supply: itm.price * totalQty,
                vat: Math.round(itm.price * totalQty * 0.1)
              };
            }),
            origin_info: {
              type: 'PO',
              sn: 'PO-2026-0156'
            }
          };

          current.push(pbl);
          localStorage.setItem(sharedKey, JSON.stringify(current));

          publishPoFinanceSyncFromNeo({
            financeStatus: '비용등록',
            paidAmount: 0,
            totalAmount: total,
            allowPoRefund: false,
            message: '통합비용관리에서 지급 기안·승인 후 이체 완료 시 환불 가능'
          });
        }

        function renderPoList() {
          document.getElementById('po-list-body').innerHTML = `
    <tr>
      <td style="text-align:center;">1</td>
      <td class="text-xs">2026-05-08</td>
      <td>㈜한솔무역</td>
      <td style="color:#2563eb; font-weight:600;">
        <i class="ri-file-list-3-line"></i> PO-2026-0156 팝업 품목 리스트 외 건
      </td>
      <td class="font-mono" style="text-align:right;">15,400,000원</td>
      <td><span class="badge badge-amber">결재중</span></td>
      <td style="text-align:center;"><button class="btn btn-outline btn-sm" onclick="loadPoDetail('㈜한솔무역', [], '결재중')">상세</button></td>
    </tr>
    <tr>
      <td style="text-align:center;">2</td>
      <td class="text-xs">2026-02-10</td>
      <td>통신산업</td>
      <td style="color:#2563eb; font-weight:600;">
        <i class="ri-file-list-3-line"></i> PO-20260203-0003 식판 취급설비 납품 건
      </td>
      <td class="font-mono" style="text-align:right;">855,000원</td>
      <td><span class="badge badge-green">승인완료</span></td>
      <td style="text-align:center;"><button class="btn btn-outline btn-sm" onclick="loadPoDetail('통신산업', [], '승인완료')">상세</button></td>
    </tr>
    <tr>
      <td style="text-align:center;">3</td>
      <td class="text-xs">2026-02-05</td>
      <td>유진공업</td>
      <td style="color:#2563eb; font-weight:600;">
        <i class="ri-file-list-3-line"></i> PO-20260203-0002 경상자재 예비 부품 건
      </td>
      <td class="font-mono" style="text-align:right;">340,000원</td>
      <td><span class="badge badge-red">승인반려</span></td>
      <td style="text-align:center;"><button class="btn btn-purple btn-sm" onclick="loadPoDetail('유진공업', [], '승인반려')">상세 →</button></td>
    </tr>
  `;
        }

        function approveOrder() {
          toast('✅ 승인 완료! ㈜한솔무역에 발주서 PDF가 자동 발송됩니다.');
          document.getElementById('approval-result').style.display = 'flex';
          document.getElementById('approval-result-msg').textContent = '발주서 PO-2026-0156 승인 완료. ㈜한솔무역에 PDF가 자동 발송되었습니다.';
          addLog('발주서 PO-2026-0156 승인 → 거래처 PDF 자동 송부 완료');
        }
        function rejectOrder() {
          toast('❌ 발주서가 반려되었습니다. 수정 후 재상신 필요합니다.');
          document.getElementById('approval-result').style.display = 'none';
        }
        function sendPo() {
          const poDate = document.getElementById('po-date')?.value || '2026-02-26';
          const vname = document.querySelector('#pg-po-detail .badge-teal')?.textContent || '㈜한솔무역';
          const orderNo = 'NB_O_3941';

          const vendorInfo = VENDORS.find(v => v.name === vname) || VENDORS[1];

          poSendAttachFiles = [];
          const attachList = document.getElementById('po-send-attach-list');
          if (attachList) attachList.innerHTML = '';

          const emailInput = document.getElementById('po-send-email');
          if (emailInput) emailInput.value = vendorInfo.email || '';

          const vendorNameDiv = document.getElementById('po-send-vendor-name');
          if (vendorNameDiv) vendorNameDiv.textContent = vendorInfo.name;

          const tdS = 'padding:8px 10px;border:1px solid #ddd;font-size:12px;';
          const thS = 'padding:8px 10px;border:1px solid #555;background:#f0f0f0;font-size:12px;font-weight:600;text-align:center;';

          // 1. 품목 내역 (그룹화된 수량 합산)
          let itemSupply = 0;
          const itemRows = state.poItems.map((item, i) => {
            const totalQty = item.projects.reduce((s, p) => s + p.qty, 0);
            const sub = item.price * totalQty;
            itemSupply += sub;
            return `
      <tr>
        <td style="${tdS}text-align:center;">${i + 1}</td>
        <td style="${tdS}">${item.name}</td>
        <td style="${tdS}font-size:11px;">${item.model}</td>
        <td style="${tdS}text-align:center;">${item.unit}</td>
        <td style="${tdS}text-align:center;">${totalQty}</td>
        <td style="${tdS}text-align:right;">${item.price.toLocaleString()}</td>
        <td style="${tdS}text-align:right;">${sub.toLocaleString()}</td>
        <td style="${tdS}"></td>
      </tr>`;
          }).join('');

          // 2. 특수비용 내역
          let scSupply = 0;
          let scVatTotal = 0;
          const scRows = state.specialCosts.map((sc, i) => {
            const sub = sc.qty * sc.price;
            let vat = 0;
            if (sc.vatType === '별도') vat = Math.round(sub * 0.1);
            else if (sc.vatType === '포함') vat = Math.round(sub - (sub / 1.1));

            scSupply += (sc.vatType === '포함' ? sub - vat : sub);
            scVatTotal += vat;

            return `
      <tr style="background:#f9fafb;">
        <td style="${tdS}text-align:center;color:#6b7280;">SC</td>
        <td style="${tdS}color:#374151;">${sc.name}</td>
        <td style="${tdS}font-size:11px;color:#6b7280;">(특수비용)</td>
        <td style="${tdS}text-align:center;">EA</td>
        <td style="${tdS}text-align:center;">${sc.qty}</td>
        <td style="${tdS}text-align:right;">${sc.price.toLocaleString()}</td>
        <td style="${tdS}text-align:right;">${sub.toLocaleString()}</td>
        <td style="${tdS}font-size:10px;color:#9ca3af;">${sc.vatType}</td>
      </tr>`;
          }).join('');

          // 3. 네고(할인) 내역
          const negoAmt = parseInt(document.getElementById('nego-amount')?.value) || 0;
          const negoType = document.getElementById('nego-vat-type')?.value || '별도';
          let negoSupply = 0;
          let negoVat = 0;
          if (negoType === '별도') {
            negoSupply = negoAmt;
            negoVat = Math.round(negoAmt * 0.1);
          } else if (negoType === '포함') {
            negoVat = Math.round(negoAmt - (negoAmt / 1.1));
            negoSupply = negoAmt - negoVat;
          } else {
            negoSupply = negoAmt;
          }

          const negoRow = negoAmt > 0 ? `
    <tr style="color:#dc2626;background:#fef2f2;">
      <td style="${tdS}text-align:center;">-</td>
      <td style="${tdS}font-weight:600;">[할인] 네고 금액</td>
      <td style="${tdS}"></td>
      <td style="${tdS}text-align:center;">EA</td>
      <td style="${tdS}text-align:center;">1</td>
      <td style="${tdS}text-align:right;">-${negoAmt.toLocaleString()}</td>
      <td style="${tdS}text-align:right;font-weight:700;">-${negoAmt.toLocaleString()}</td>
      <td style="${tdS}font-size:10px;">${negoType}</td>
    </tr>` : '';

          // 4. 최종 합계 계산 (calcPoTotal 로직과 동일하게)
          const finalSupply = itemSupply + scSupply - negoSupply;
          const itemVat = Math.round(itemSupply * 0.1);
          const finalVat = itemVat + scVatTotal - negoVat;
          const finalTotal = finalSupply + finalVat;

          const emptyRowCount = Math.max(0, 10 - state.poItems.length - state.specialCosts.length - (negoAmt > 0 ? 1 : 0));
          const emptyRows = Array(emptyRowCount).fill(`<tr>${Array(8).fill(`<td style="${tdS}">&nbsp;</td>`).join('')}</tr>`).join('');

          const allRows = itemRows + scRows + negoRow + emptyRows;
          const logoSvg = `<img src="data:image/png;base64,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AJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgKYIgAACApAiCAAAAkiIIAgAASIogCAAAICmCIAAAgKQIggAAAJIiCAIAAEiKIAgAACApgiAAAICkCIIAAACSIggCAABIiiAIAAAgqf8HDfNkfyhjiIcAAAAASUVORK5CYII=" alt="NEO BH" style="height:52px;object-fit:contain;">`;
          document.getElementById('po-preview-body').innerHTML = `
  <div style="background:#fff;font-family:'Malgun Gothic','Apple SD Gothic Neo',sans-serif;max-width:760px;margin:0 auto;">
    <div style="display:flex;align-items:center;justify-content:space-between;padding:16px 24px;border-bottom:3px solid #e8501a;">${logoSvg}<div style="font-size:11px;color:#444;text-align:right;line-height:1.8;">주소: 경기도 김포시 고촌읍 전호로 32 | 사업자번호: 822-87-00677 | 홈페이지: www.neobh.kr<br>TEL: 031-987-3069 | FAX: 031-998-3069 | E-mail: balhea@balhea.kr</div></div>
    <div style="text-align:center;padding:18px 0 14px;font-size:22px;font-weight:700;letter-spacing:8px;">발 주 서</div>
    <div style="display:flex;justify-content:space-between;padding:0 20px 10px;font-size:12px;"><div>발주일자: <strong>${poDate}</strong></div><div>Order No. <strong>${orderNo}</strong></div></div>
    <div style="display:grid;grid-template-columns:1fr 1fr;margin:0 20px 14px;border:1px solid #aaa;">
      <div style="border-right:1px solid #aaa;">
        <div style="background:#f0f0f0;text-align:center;padding:6px;font-size:12px;font-weight:700;border-bottom:1px solid #aaa;">수신처 (거래처)</div>
        <table style="width:100%;border-collapse:collapse;font-size:12px;">
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;width:60px;">업체명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;font-weight:600;">${vendorInfo.name}</td></tr>
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;">연락처</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;">${vendorInfo.tel}</td></tr>
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;">담당자</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;">${vendorInfo.ceo} 대표</td></tr>
          <tr><td style="padding:5px 10px;color:#555;">주소</td><td style="padding:5px 10px;">${vendorInfo.addr}</td></tr>
        </table>
      </div>
      <div>
        <div style="background:#f0f0f0;text-align:center;padding:6px;font-size:12px;font-weight:700;border-bottom:1px solid #aaa;">발신처 (발주사)</div>
        <table style="width:100%;border-collapse:collapse;font-size:12px;">
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;width:60px;">상호명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;font-weight:600;">네오비에이치</td></tr>
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;">대표자명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;">장재용</td></tr>
          <tr><td style="padding:5px 10px;border-bottom:1px solid #ddd;color:#555;">담당자명</td><td style="padding:5px 10px;border-bottom:1px solid #ddd;">발해futech</td></tr>
          <tr><td style="padding:5px 10px;color:#555;">연락처</td><td style="padding:5px 10px;">031-987-3069</td></tr>
        </table>
      </div>
    </div>
    <div style="padding:4px 20px 10px;font-size:12px;">아래와 같이 발주합니다.</div>
    <div style="margin:0 20px;overflow-x:auto;">
      <table style="width:100%;border-collapse:collapse;">
        <thead><tr>
          <th style="${thS}width:36px;">No</th><th style="${thS}">품명</th><th style="${thS}">규격</th>
          <th style="${thS}width:50px;">단위</th><th style="${thS}width:50px;">수량</th>
          <th style="${thS}width:90px;">단가</th><th style="${thS}width:90px;">합계</th>
          <th style="${thS}">비고</th>
        </tr></thead>
        <tbody>${allRows}</tbody>
      </table>
    </div>
    <div style="margin:0 20px;border:1px solid #ddd;border-top:none;padding:10px 14px;">
      <div style="display:flex;justify-content:space-between;align-items:center;padding:4px 0;font-size:13px;"><div style="display:flex;align-items:center;gap:4px;flex:1;"><strong>TOTAL</strong><span style="border-bottom:1px dashed #aaa;flex:1;margin:0 10px;display:block;"></span></div><div style="font-size:15px;font-weight:700;">${finalSupply.toLocaleString()} 원 <span style="font-size:11px;font-weight:400;color:#555;">[부가세 별도]</span></div></div>
      <div style="display:flex;justify-content:space-between;align-items:center;padding:4px 0;font-size:13px;border-top:1px solid #eee;"><div style="display:flex;align-items:center;gap:4px;flex:1;"><strong>TOTAL(with Tax)</strong><span style="border-bottom:1px dashed #aaa;flex:1;margin:0 10px;display:block;"></span></div><div style="font-size:15px;font-weight:700;">${finalTotal.toLocaleString()} 원 <span style="font-size:11px;font-weight:400;color:#555;">[부가세 포함]</span></div></div>
    </div>
    <div style="margin:8px 20px 0;font-size:12px;line-height:2.2;"><div>납기 &nbsp;&nbsp; —</div><div>결제조건 &nbsp;&nbsp; 귀사내규</div><div>납품조건 &nbsp;&nbsp; 방문수령</div><div>유효기간 &nbsp;&nbsp; —</div></div>
    <div style="margin:8px 20px 0;border:1px solid #ddd;padding:8px 12px;font-size:12px;min-height:48px;"><div style="font-weight:700;margin-bottom:4px;">비고</div></div>
  </div>`;
          openModal('po-preview-modal');
        }

        // ===================== 발주서 PDF 자동 송부 완료 처리 =====================
        function confirmPoSend() {
          const vname = document.querySelector('#pg-po-detail .badge-teal')?.textContent || '㈜한솔무역';
          const newEmail = document.getElementById('po-send-email')?.value.trim();
          if (!newEmail) { toast('이메일 주소를 입력해주세요.'); return; }

          const fileNames = poSendAttachFiles.map(f => f.name).join(', ');
          closeModal('po-preview-modal');

          toast(`📧 발주서 PDF 자동 송부 완료! 수신: ${newEmail}${fileNames ? ` (첨부: ${fileNames})` : ''}`);

          const approvalResult = document.getElementById('approval-result');
          if (approvalResult) approvalResult.style.display = 'block';

          try {
            addLog(`[발주서 자동송부] ${vname} (${newEmail}) 발송 완료${fileNames ? ` - 첨부파일: ${fileNames}` : ''}`);
          } catch (e) { }
        }

        // ===================== 견적요청 모달 =====================
        let rfqReqSelectedVendors = [];

        function openRfqRequestModal() {
          console.log('openRfqRequestModal called');
          // 체크된 행 수집
          const checkedBoxes = document.querySelectorAll('#neobh-tbody input[type="checkbox"]:checked');
          if (checkedBoxes.length === 0) {
            toast('⚠️ 견적을 요청할 품목을 먼저 선택해주세요.');
            return;
          }

          // 프로젝트명 설정
          const projectName = state.currentProject || '프로젝트 미선택';
          const nameEl = document.getElementById('rfq-req-project-name');
          if (nameEl) nameEl.textContent = projectName;

          // 선택된 품목 수집 (neobh-tbody 행 기반)
          const rows = [];
          checkedBoxes.forEach(cb => {
            const tr = cb.closest('tr');
            if (!tr) return;
            const cells = tr.querySelectorAll('td');
            /*
              neobh-tbody 구조 (renderNeobhTable 참조):
              0: checkbox
              1: No
              2: 품목명 (item.name) + 하위추가 버튼
              3: 수급정보 (badge)
              4: 자재번호 (item.model)
              5: 품목명 (item.name) - 첨부용
              6: 규격 (item.note)
              7: 카테고리 (Empty)
              8: 제조사 (Empty)
              9: 단위 (Empty)
            */
            rows.push({
              name: cells[2]?.innerText?.replace('하위추가', '')?.trim() || '',
              model: cells[4]?.textContent?.trim() || '',
              spec: cells[6]?.textContent?.trim() || '',
              maker: cells[8]?.textContent?.trim() || '-',
              unit: cells[9]?.textContent?.trim() || 'EA',
              qty: (() => {
                // 현재 프로젝트의 compareData에서 수량 조회
                const proj = PROJECT_DATA[state.currentProject];
                if (proj && proj.compareData) {
                  const matched = proj.compareData.find(r => r.name === cells[2]?.innerText?.replace('하위추가', '')?.trim());
                  if (matched) return String(matched.qty);
                }
                return '1';
              })(),
              note: ''
            });
          });

          // 품목 테이블 렌더
          const tbody = document.getElementById('rfq-req-tbody');
          if (tbody) {
            tbody.innerHTML = rows.map((item, i) => `
      <tr style="border-bottom:1px solid #f1f5f9;">
        <td style="text-align:center;padding:10px;"><input type="checkbox" class="rfq-req-item-check" checked></td>
        <td style="text-align:center;padding:10px;color:#94a3b8;">${i + 1}</td>
        <td style="padding:10px;font-weight:500;">${item.name}</td>
        <td style="padding:10px;color:#64748b;font-family:monospace;">${item.model}</td>
        <td style="padding:10px;font-size:11px;color:#475569;">${item.spec}</td>
        <td style="padding:10px;">${item.maker}</td>
        <td style="text-align:center;padding:10px;">${item.unit}</td>
        <td style="text-align:center;padding:10px;"><input type="number" value="${item.qty}" style="width:50px;text-align:center;border:1px solid #cbd5e1;border-radius:4px;padding:3px;"></td>
        <td style="padding:10px;"><input type="text" placeholder="비고" style="border:none;background:transparent;font-size:12px;width:100%;outline:none;"></td>
      </tr>
    `).join('');
          }

          // 데이터 초기화
          rfqReqSelectedVendors = [];

          const selectedVendorsEl = document.getElementById('rfq-req-selected-vendors');
          if (selectedVendorsEl) selectedVendorsEl.textContent = '거래처를 선택해주세요.';

          const infoTitleEl = document.getElementById('rfq-info-title');
          if (infoTitleEl) infoTitleEl.value = `[견적요청] ${projectName}_${new Date().toISOString().split('T')[0]}`;

          const infoVendorEl = document.getElementById('rfq-info-vendor');
          if (infoVendorEl) infoVendorEl.value = '';

          renderRfqReqVendorRows();

          const modal = document.getElementById('rfq-request-modal');
          if (modal) modal.classList.add('open');
        }

        function renderRfqReqVendorRows() {
          const area = document.getElementById('rfq-req-vendor-rows');
          if (!area) return;

          const today = new Date().toISOString().split('T')[0];
          const thS = 'padding:10px;border-bottom:1px solid #e2e8f0;font-size:12px;color:#475569;font-weight:600;';

          const header = `<tr style="background:#f8fafc;">
    <th style="${thS}width:32px;text-align:center;"></th>
    <th style="${thS}text-align:left;">거래처</th>
    <th style="${thS}width:70px;text-align:left;">대표자</th>
    <th style="${thS}width:110px;text-align:left;">견적요청일</th>
    <th style="${thS}width:120px;text-align:left;">연락처</th>
    <th style="${thS}width:120px;text-align:left;">팩스</th>
    <th style="${thS}text-align:left;">이메일</th>
  </tr>`;

          if (rfqReqSelectedVendors.length === 0) {
            area.innerHTML = `
      <div style="border:1px solid #e2e8f0;border-radius:10px;overflow:hidden;background:#fff;">
        <table style="width:100%;border-collapse:collapse;font-size:12px;">
          <thead>${header}</thead>
          <tbody><tr><td colspan="7" style="padding:24px;text-align:center;color:#94a3b8;font-size:13px;background:#fcfcfc;">거래처 정보가 없습니다. 우측 패널에서 거래처를 선택해주세요.</td></tr></tbody>
        </table>
      </div>`;
            return;
          }

          const iS = 'font-size:12px;border:1px solid #e2e8f0;border-radius:6px;padding:4px 8px;width:100%;background:#fff;';
          const rows = rfqReqSelectedVendors.map((id, idx) => {
            const v = VENDORS.find(x => x.id === id) || {};
            return `
      <tr style="border-bottom:1px solid #f1f5f9;">
        <td style="text-align:center;padding:10px;color:#94a3b8;">${idx + 1}</td>
        <td style="padding:10px;font-weight:700;color:#1e293b;">${v.name || ''}</td>
        <td style="padding:10px;">${v.ceo || ''}</td>
        <td style="padding:10px;"><input type="date" value="${today}" style="${iS}"></td>
        <td style="padding:10px;"><input type="text" value="${v.tel || ''}" style="${iS}"></td>
        <td style="padding:10px;"><input type="text" value="${v.fax || ''}" placeholder="팩스 번호" style="${iS}"></td>
        <td style="padding:10px;color:#64748b;font-family:monospace;font-size:11px;">${v.email || ''}</td>
      </tr>`;
          }).join('');

          area.innerHTML = `
    <div style="border:1px solid #e2e8f0;border-radius:10px;overflow:hidden;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,0.02);">
      <table style="width:100%;border-collapse:collapse;font-size:12px;">
        <thead>${header}</thead>
        <tbody style="background:#fff;">${rows}</tbody>
      </table>
    </div>`;
        }

        function toggleAllRfqReq(masterCb) {
          document.querySelectorAll('.rfq-req-item-check').forEach(cb => { cb.checked = masterCb.checked; });
        }

        function deleteRfqReqItems() {
          const checked = document.querySelectorAll('.rfq-req-item-check:checked');
          if (checked.length === 0) { toast('삭제할 품목을 선택해주세요.'); return; }
          checked.forEach(cb => cb.closest('tr').remove());
          // 번호 재정렬
          document.querySelectorAll('#rfq-req-tbody tr').forEach((tr, i) => {
            const cells = tr.querySelectorAll('td');
            if (cells[1]) cells[1].textContent = i + 1;
          });
          toast(`${checked.length}개 품목이 삭제되었습니다.`);
        }

        function openRfqVendorModal() {
          document.getElementById('rfq-vendor-search').value = '';
          renderRfqVendorModalList();
          openModal('rfq-vendor-modal');
        }

        function renderRfqVendorModalList() {
          const q = document.getElementById('rfq-vendor-search')?.value?.toLowerCase() || '';
          const filtered = VENDORS.filter(v => v.name.toLowerCase().includes(q) || v.ceo.toLowerCase().includes(q));
          document.getElementById('rfq-vendor-modal-list').innerHTML = `
    <table style="width:100%;border-collapse:collapse;font-size:13px;">
      <thead>
        <tr style="border-bottom:1px solid #e2e8f0;">
          <th style="padding:8px 10px;text-align:center;width:40px;color:#64748b;font-weight:600;">선택</th>
          <th style="padding:8px 10px;color:#64748b;font-weight:600;">거래처명</th>
          <th style="padding:8px 10px;color:#64748b;font-weight:600;">대표자</th>
          <th style="padding:8px 10px;color:#64748b;font-weight:600;">이메일</th>
        </tr>
      </thead>
      <tbody>${filtered.map(v => `
        <tr style="border-bottom:1px solid #f1f5f9;">
          <td style="text-align:center;padding:10px;">
            <input type="checkbox" class="rfq-vendor-check" value="${v.id}"
              ${rfqReqSelectedVendors.includes(v.id) ? 'checked' : ''}
              onchange="updateRfqVendorCount()">
          </td>
          <td style="padding:10px;font-weight:700;">${v.name}</td>
          <td style="padding:10px;color:#374151;">${v.ceo}</td>
          <td style="padding:10px;color:#94a3b8;font-family:monospace;font-size:12px;">${v.email}</td>
        </tr>
      `).join('')}</tbody>
    </table>`;
          updateRfqVendorCount();
        }

        function filterRfqVendors() { renderRfqVendorModalList(); }

        function updateRfqVendorCount() {
          const cnt = document.querySelectorAll('.rfq-vendor-check:checked').length;
          document.getElementById('rfq-vendor-check-cnt').textContent = cnt;
        }

        function confirmRfqVendors() {
          rfqReqSelectedVendors = [...document.querySelectorAll('.rfq-vendor-check:checked')].map(c => c.value);
          closeModal('rfq-vendor-modal');

          const infoEl = document.getElementById('rfq-info-vendor');
          const selectedVendorsEl = document.getElementById('rfq-req-selected-vendors');

          if (rfqReqSelectedVendors.length === 0) {
            if (infoEl) infoEl.value = '';
            if (selectedVendorsEl) selectedVendorsEl.textContent = '';
          } else {
            const names = rfqReqSelectedVendors.map(id => VENDORS.find(v => v.id === id)?.name || id);
            const label = names[0] + (names.length > 1 ? ` 외 ${names.length - 1}개사` : '');
            if (infoEl) infoEl.value = label;
            if (selectedVendorsEl) selectedVendorsEl.textContent = `총 ${rfqReqSelectedVendors.length}개 거래처가 선택되었습니다.`;
          }
          renderRfqReqVendorRows();
        }

        // ===================== 로그 =====================
        function addLog(msg) {
          const list = document.getElementById('log-list');
          const now = new Date();
          const t = now.getHours().toString().padStart(2, '0') + ':' + now.getMinutes().toString().padStart(2, '0');
          const div = document.createElement('div');
          div.className = 'log-item';
          div.innerHTML = `<div class="log-time">2026-05-08 ${t}</div><div>${msg}</div>`;
          list.insertBefore(div, list.firstChild);
        }

        // ===================== 네비게이션 =====================
        function showPage(id) {
          state.activePage = id;
          document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
          const targetPage = document.getElementById(id);
          if (targetPage) targetPage.classList.add('active');
          if (id === 'pg-po-detail') pollPoFinanceSync();
          if (id === 'pg-po-list') renderPoListFull();
          if (id === 'pg-ceo-approval') document.getElementById('pg-ceo-approval').style.display = 'flex';
          else { const el = document.getElementById('pg-ceo-approval'); if(el) el.style.display = 'none'; }

          // 프로젝트 관리 페이지 진입 시 내부 탭 초기화
          if (id === 'pg-project-manage') {
            switchProjectTab('item');
          }

          const navMap = { 'pg-rfqp-list': 'nav-rfqp-list', 'pg-rfqp-detail': 'nav-rfqp-list', 'pg-compare': 'nav-compare', 'pg-po-list': 'nav-po-list', 'pg-po-detail': 'nav-po-detail' };
          const navId = navMap[id];
          const navEl = navId ? document.getElementById(navId) : null;
          if (navEl) navEl.classList.add('active');

          const bc = { 'pg-rfqp-list': '견적기안 목록', 'pg-rfqp-detail': '회신 관리', 'pg-compare': '견적 비교', 'pg-po-list': '발주서 목록', 'pg-po-detail': '발주서 상세' };
          const breadcrumbSub = document.getElementById('breadcrumb-sub');
          if (breadcrumbSub) breadcrumbSub.textContent = bc[id] || '';
        }

        function renderBasicInfo(name) {
          const project = PROJECT_DATA[name] || PROJECT_DATA['G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매'];
          if (!project || !project.basicInfo) return;

          const info = project.basicInfo;
          document.getElementById('bi-type').textContent = info.type || '-';
          document.getElementById('bi-vendor').textContent = info.vendor || '-';
          document.getElementById('bi-destination').textContent = info.destination || '-';
          document.getElementById('bi-name').textContent = info.name || '-';
          document.getElementById('bi-no').textContent = info.no || '-';
          document.getElementById('bi-contract-no').textContent = info.contractNo || '-';
          document.getElementById('bi-manager').textContent = info.manager || '-';
          document.getElementById('bi-order-date').textContent = info.orderDate || '-';
          document.getElementById('bi-delivery-date').textContent = info.deliveryDate || '-';
          document.getElementById('bi-item-count').textContent = info.itemCount || '0';
          document.getElementById('bi-remarks').textContent = info.remarks || '-';
        }

        function selectProject(name) {
          state.currentProject = name;
          const project = PROJECT_DATA[name] || PROJECT_DATA['G022600061 · 2026년 상반기 통신 경상자재 및 전산소모품 구매'];
          state.items = project.items;

          // UI 업데이트
          document.querySelectorAll('.neobh-project-card').forEach(c => {
            c.classList.remove('active');
            if (c.textContent.includes(name)) c.classList.add('active');
          });

          renderBasicInfo(name);
          renderNeobhTable();
          renderCompareItem();
          toast(`📂 프로젝트 변경: ${name}`);
        }

        function switchProjectTab(tab) {
          const tableArea = document.getElementById('neobh-table-area');
          const priceArea = document.getElementById('neobh-price-area');
          const btnArea = document.getElementById('project-manage-btns');
          const tabs = document.querySelectorAll('#pg-project-manage .neobh-tab');

          tabs.forEach(t => t.classList.remove('active'));

          if (tab === 'item') {
            if (tableArea) tableArea.style.display = 'block';
            if (priceArea) priceArea.style.display = 'none';
            if (btnArea) btnArea.style.display = 'flex';
            if (tabs[0]) tabs[0].classList.add('active');
          } else if (tab === 'price') {
            if (tableArea) tableArea.style.display = 'none';
            if (priceArea) priceArea.style.display = 'flex';
            if (btnArea) btnArea.style.display = 'none';
            if (tabs[1]) tabs[1].classList.add('active');
            renderCompareItemWithLimit();
          }
        }

        function scrollToSection(id) { document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' }); }

        // ===================== 토스트 =====================
        let toastTimer;
        function toast(msg) {
          const t = document.getElementById('toast');
          t.textContent = msg;
          t.classList.add('show');
          clearTimeout(toastTimer);
          toastTimer = setTimeout(() => t.classList.remove('show'), 3500);
        }

        // ===================== 발송 히스토리 로직 (Task 5) =====================
        let SEND_HISTORY = [
          { id: 0, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v1', vendorEmail: 'sales@daesung.com', sentAt: '2026-05-12 09:15', status: 'success', retryCount: 0 },
          { id: 1, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v2', vendorEmail: 'rfq@hansol.com', sentAt: '2026-05-12 09:16', status: 'success', retryCount: 0 },
          { id: 2, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v3', vendorEmail: 'info@mira.kr', sentAt: '2026-05-12 09:17', status: 'failed', failReason: '이메일 오류 (수신거부)', retryCount: 0 },
          { id: 3, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v4', vendorEmail: 'supply@global.co.kr', sentAt: '2026-05-12 09:18', status: 'success', retryCount: 0 },
          { id: 4, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v5', vendorEmail: 'bid@dpartner.kr', sentAt: '2026-05-12 09:19', status: 'success', retryCount: 0 },
          { id: 5, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v6', vendorEmail: 'admin@smart.com', sentAt: '2026-05-12 09:20', status: 'success', retryCount: 0 },
          { id: 6, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v7', vendorEmail: 'sales@koreait.kr', sentAt: '2026-05-12 09:21', status: 'success', retryCount: 0 },
          { id: 7, type: '견적', docNo: 'RFQP-2025-0089', vendorId: 'v8', vendorEmail: 'best@supply.com', sentAt: '2026-05-12 09:22', status: 'success', retryCount: 0 }
        ];

        // 웹팩스 전송내역 (외부 웹팩스 시스템 연동 — ERP에서 건별 상세 미제공)
        const WEBFAX_SENDER = { name: '오제록', no: '031-987-3069' };
        let FAX_WEB_HISTORY = [
          { id: 1, vendorId: 'v1', docNo: 'RFQP-2025-0089', sender: '오제록', senderNo: '031-987-3069', recvCompany: '㈜대성상사', recvName: '김대성', recvNo: '02-555-1235', sentAt: '2026-05-12 09:16:02', completedAt: '2026-05-12 09:17:15', status: 'success', totalPages: 3, successPages: 3, failPages: 0, fileName: 'RFQP-0089_대성상사.pdf' },
          { id: 2, vendorId: 'v2', docNo: 'RFQP-2025-0089', sender: '오제록', senderNo: '031-987-3069', recvCompany: '㈜한솔무역', recvName: '박한솔', recvNo: '02-888-5679', sentAt: '2026-05-12 09:17:08', completedAt: '2026-05-12 09:18:22', status: 'success', totalPages: 3, successPages: 3, failPages: 0, fileName: 'RFQP-0089_한솔무역.pdf' },
          { id: 3, vendorId: 'v3', docNo: 'RFQP-2025-0089', sender: '오제록', senderNo: '031-987-3069', recvCompany: '㈜미래기술', recvName: '이미래', recvNo: '031-777-9001', sentAt: '2026-05-12 09:18:11', completedAt: '2026-05-12 09:19:45', status: 'failed', totalPages: 3, successPages: 0, failPages: 3, fileName: 'RFQP-0089_미래기술.pdf', failReason: '수신거부/통화중' },
          { id: 4, vendorId: 'v4', docNo: 'RFQP-2025-0089', sender: '김구매', senderNo: '031-987-3069', recvCompany: '㈜글로벌서플라이', recvName: '최글로', recvNo: '02-111-2223', sentAt: '2026-05-12 09:19:30', completedAt: '2026-05-12 09:20:41', status: 'success', totalPages: 3, successPages: 3, failPages: 0, fileName: 'RFQP-0089_글로벌.pdf' },
          { id: 5, vendorId: 'v6', docNo: 'RFQP-2025-0089', sender: '오제록', senderNo: '031-987-3069', recvCompany: '㈜스마트오피스', recvName: '강스마', recvNo: '02-555-6667', sentAt: '2026-05-12 09:21:05', completedAt: '2026-05-12 09:22:18', status: 'success', totalPages: 3, successPages: 3, failPages: 0, fileName: 'RFQP-0089_스마트오피스.pdf' },
          { id: 6, vendorId: 'v8', docNo: 'RFQP-2025-0089', sender: '김구매', senderNo: '031-987-3069', recvCompany: '㈜베스트서플라이', recvName: '임베스', recvNo: '02-999-0001', sentAt: '2026-05-12 09:23:12', completedAt: '2026-05-12 09:24:30', status: 'success', totalPages: 3, successPages: 3, failPages: 0, fileName: 'RFQP-0089_베스트.pdf' },
          { id: 7, vendorId: 'v2', docNo: 'RFQP-2025-0087', sender: '오제록', senderNo: '031-987-3069', recvCompany: '㈜한솔무역', recvName: '박한솔', recvNo: '02-888-5679', sentAt: '2026-05-08 14:02:33', completedAt: '2026-05-08 14:03:50', status: 'success', totalPages: 2, successPages: 2, failPages: 0, fileName: 'RFQP-0087_한솔무역.pdf' },
          { id: 8, vendorId: 'v1', docNo: 'RFQP-2025-0086', sender: '김구매', senderNo: '031-987-3069', recvCompany: '㈜대성상사', recvName: '김대성', recvNo: '02-555-1235', sentAt: '2026-05-08 11:20:15', completedAt: '2026-05-08 11:21:02', status: 'partial', totalPages: 4, successPages: 2, failPages: 2, fileName: 'RFQP-0086_대성상사.pdf' }
        ];

        let webfaxFilterState = { tab: 'recent', page: 1, pageSize: 10 };

        function getVendorFaxSummary(vid) {
          const vendor = VENDORS.find(v => v.id === vid);
          if (!vendor?.fax) return { code: 'no_fax', label: '번호없음' };
          const rows = FAX_WEB_HISTORY.filter(h => h.vendorId === vid)
            .sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt));
          if (!rows.length) return { code: 'pending', label: '대기중' };
          const last = rows[0];
          if (last.status === 'success') return { code: 'success', label: '전송성공' };
          if (last.status === 'failed') return { code: 'failed', label: '전송실패' };
          if (last.status === 'partial') return { code: 'partial', label: '부분성공' };
          if (last.status === 'sending') return { code: 'sending', label: '전송중' };
          return { code: 'pending', label: '대기중' };
        }

        function renderMailStatusBadge(vid, history, lastStatus) {
          if (lastStatus === 'success') {
            return `<span class="badge badge-teal fax-status-link" onclick="showSendHistory('${vid}')">발송성공</span>`;
          }
          if (lastStatus === 'failed') {
            return `<span class="badge badge-red fax-status-link" onclick="showSendHistory('${vid}')">발송실패</span>`;
          }
          return '<span class="badge badge-amber">대기중</span>';
        }

        function renderFaxStatusBadge(vid) {
          const s = getVendorFaxSummary(vid);
          if (s.code === 'no_fax') return `<span class="badge badge-gray">${s.label}</span>`;
          const cls = s.code === 'success' ? 'badge-teal'
            : s.code === 'failed' ? 'badge-red'
              : s.code === 'partial' ? 'badge-amber' : 'badge-amber';
          return `<span class="badge ${cls} fax-status-link" onclick="openWebFaxHistory('${vid}')" title="클릭 시 웹팩스 전송내역 조회">${s.label}</span>`;
        }

        function renderReplyActionsCell(vid) {
          const isBlocked = state.vendorStatuses[vid] === 'blocked';
          const directBtn = isBlocked
            ? `<button type="button" class="btn btn-outline btn-sm" disabled title="링크 차단·직접입력 완료">입력완료</button>`
            : `<button type="button" class="btn btn-outline btn-sm reply-direct-btn" onclick="openBlockModal('${vid}')" title="거래처 링크 비활성 후 담당자가 단가 직접 입력">직접입력</button>`;
          return `
            <td>
              <div class="reply-actions-cell">
                <div class="reply-dropdown">
                  <button type="button" class="btn btn-outline btn-sm" onclick="toggleReplyDropdown(event)">양식 ▾</button>
                  <div class="reply-dropdown-menu">
                    <button type="button" class="reply-dropdown-item" onclick="openRfqPreview('${vid}'); closeReplyDropdowns()">📄 PDF 다운로드</button>
                    <button type="button" class="reply-dropdown-item excel" onclick="downloadVendorExcel('${vid}'); closeReplyDropdowns()">📊 Excel 다운로드</button>
                  </div>
                </div>
                ${directBtn}
              </div>
            </td>`;
        }

        function toggleReplyDropdown(e) {
          e.stopPropagation();
          const wrap = e.currentTarget.closest('.reply-dropdown');
          document.querySelectorAll('.reply-dropdown.open').forEach(d => {
            if (d !== wrap) d.classList.remove('open');
          });
          wrap.classList.toggle('open');
        }

        function closeReplyDropdowns() {
          document.querySelectorAll('.reply-dropdown.open').forEach(d => d.classList.remove('open'));
        }

        function renderSendChannelCell(vid, channel) {
          const vendor = VENDORS.find(v => v.id === vid) || {};
          if (channel === 'mail') {
            const history = SEND_HISTORY.filter(h => h.vendorId === vid).sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt));
            const lastStatus = history[0]?.status || 'pending';
            const statusHtml = renderMailStatusBadge(vid, history, lastStatus);
            return `
            <td class="send-channel-cell">
              <div class="send-channel-status" data-export="mail-status">${statusHtml}</div>
              <div class="send-channel-actions">
                <button type="button" class="btn btn-primary btn-sm" onclick="retrySend('${vid}')">재발송</button>
              </div>
            </td>`;
          }
          const hasFax = !!vendor.fax;
          const statusHtml = renderFaxStatusBadge(vid);
          const resendBtn = hasFax
            ? `<button type="button" class="btn btn-outline btn-sm" onclick="retryFaxSend('${vid}')">재발송</button>`
            : `<button type="button" class="btn btn-outline btn-sm" disabled title="팩스번호 미등록">재발송</button>`;
          return `
            <td class="send-channel-cell">
              <div class="send-channel-status" data-export="fax-status">${statusHtml}</div>
              <div class="send-channel-actions">
                ${resendBtn}
              </div>
            </td>`;
        }

        function renderReplyTable() {
          const body = document.getElementById('reply-table-body');
          if (!body) return;
          const vids = Object.keys(VNAMES);

          body.innerHTML = vids.map(vid => {
            const vname = VNAMES[vid];
            const reply = VENDOR_REPLIES[vid] || { status: '입력대기중', subtotal: 0 };
            let displayStatus = reply.status;
            let statusBadgeClass = 'badge-amber';
            if (reply.status === '회신완료' || reply.status === '입력완료') {
              statusBadgeClass = 'badge-green';
              displayStatus = '회신완료';
            } else if (reply.status === '기한만료') {
              statusBadgeClass = 'badge-red';
            } else if (reply.status === '입력대기중') {
              statusBadgeClass = 'badge-gray';
            }

            let linkHtml = `<a href="vendor.html?vendorId=${vid}&direct=1" target="_blank" class="link-active" style="text-decoration:underline;">🔗 활성화 ✓</a>`;
            if (state.vendorStatuses[vid] === 'blocked') {
              displayStatus = '직접입력';
              statusBadgeClass = 'badge-blue';
              linkHtml = `<span class="link-blocked">🔒 링크차단 ✕</span>`;
            }

            return `
          <tr>
            <td><input type="checkbox" class="reply-check" data-vid="${vid}" data-status="${reply.status}" onchange="updateDeleteBtn()"></td>
            <td><strong>${vname}</strong></td>
            <td>${linkHtml}</td>
            <td><span class="badge ${statusBadgeClass}">${displayStatus}</span></td>
            ${renderReplyActionsCell(vid)}
            ${renderSendChannelCell(vid, 'mail')}
            ${renderSendChannelCell(vid, 'fax')}
          </tr>
        `;
          }).join('');
          updateDeleteBtn();
          if (typeof updateRepliedCount === 'function') updateRepliedCount();
        }

        function toggleAllReplies(chk) {
          document.querySelectorAll('.reply-check').forEach(c => c.checked = chk.checked);
          updateDeleteBtn();
        }

        function updateDeleteBtn() {
          const checked = Array.from(document.querySelectorAll('.reply-check:checked'));
          const hasExpired = checked.some(c => c.dataset.status === '기한만료');
          const btn = document.getElementById('delete-expired-btn');
          if (btn) btn.style.display = (checked.length > 0 && hasExpired) ? 'inline-flex' : 'none';
        }

        function deleteSelectedReplies() {
          const checked = Array.from(document.querySelectorAll('.reply-check:checked'));
          const vidsToDelete = checked.filter(c => c.dataset.status === '기한_만료' || c.dataset.status === '기한만료').map(c => c.dataset.vid);

          if (vidsToDelete.length === 0) return;
          if (!confirm(`선택한 ${vidsToDelete.length}개의 기한만료 항목을 삭제하시겠습니까?`)) return;

          vidsToDelete.forEach(vid => {
            delete VENDOR_REPLIES[vid];
            delete VNAMES[vid];
          });
          broadcastState();
          renderReplyTable();
          toast('기한만료 항목이 삭제되었습니다.');
        }

        function downloadVendorExcel(vid) {
          const vname = VNAMES[vid];
          toast(`${vname} 견적 상세 내역을 엑셀로 추출합니다...`);
          // 실제 구현 시 엑셀 라이브러리 연동
        }

        function showSendHistory(vid) {
          const vname = VNAMES[vid];
          const history = SEND_HISTORY.filter(h => h.vendorId === vid).sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt));
          const vendor = VENDORS.find(v => v.id === vid) || {};

          const titleEl = document.getElementById('history-modal-title');
          if (titleEl) titleEl.textContent = '📡 메일 발송 이력 상세';

          const infoEl = document.getElementById('history-vendor-info');
          if (infoEl) infoEl.textContent = `${vname} — ${history[0]?.vendorEmail || vendor.email || ''}`;

          const body = document.getElementById('history-table-body');
          body.innerHTML = history.length === 0
            ? `<tr><td colspan="5" style="padding:24px;text-align:center;color:#94a3b8;">발송 이력이 없습니다.</td></tr>`
            : history.map(h => `
        <tr>
          <td style="padding-left:20px;">${h.sentAt}</td>
          <td><span class="status-badge ${h.status === 'success' ? 'status-success' : 'status-failed'}">${h.status === 'success' ? '발송성공' : '발송실패'}</span></td>
          <td>${h.vendorEmail}</td>
          <td style="text-align:center;">${h.retryCount + 1}회</td>
          <td style="padding-right:20px; color:#64748b; font-size:11px;">${h.failReason || '정상 처리'}</td>
        </tr>
      `).join('');

          openModal('send-history-modal');
        }

        function openWebFaxHistory(prefillVid) {
          const today = new Date();
          const from = new Date(today);
          from.setMonth(from.getMonth() - 1);
          const fmt = d => d.toISOString().split('T')[0];

          const dateFrom = document.getElementById('webfax-date-from');
          const dateTo = document.getElementById('webfax-date-to');
          if (dateFrom && !dateFrom.value) dateFrom.value = fmt(from);
          if (dateTo && !dateTo.value) dateTo.value = fmt(today);

          if (prefillVid && VNAMES[prefillVid]) {
            const recvCo = document.getElementById('webfax-recv-company');
            if (recvCo) recvCo.value = VNAMES[prefillVid];
          }

          webfaxFilterState.page = 1;
          switchWebFaxTab('recent');
          renderWebFaxList();
          openModal('webfax-history-modal');
        }

        function switchWebFaxTab(tab) {
          webfaxFilterState.tab = tab;
          document.querySelectorAll('.webfax-tab').forEach(el => {
            el.classList.toggle('active', el.dataset.tab === tab);
          });
          const hint = document.getElementById('webfax-tab-hint');
          if (hint) {
            hint.textContent = tab === 'recent'
              ? '최근 1년 이내 전송 건을 조회합니다. 담당자별 발신·수신 정보로 본인 건을 찾아보세요.'
              : '1년 이전 과거 전송 내역입니다.';
          }
          renderWebFaxList();
        }

        function getWebFaxStatusLabel(status) {
          const map = {
            success: '전송성공',
            failed: '전송실패',
            partial: '부분성공',
            sending: '전송중',
            waiting: '예약대기',
            canceled: '예약취소'
          };
          return map[status] || status;
        }

        function filterWebFaxRows() {
          const dateFrom = document.getElementById('webfax-date-from')?.value || '';
          const dateTo = document.getElementById('webfax-date-to')?.value || '';
          const senderNo = (document.getElementById('webfax-sender-no')?.value || '').trim();
          const recvNo = (document.getElementById('webfax-recv-no')?.value || '').trim();
          const recvCo = (document.getElementById('webfax-recv-company')?.value || '').trim();
          const recvName = (document.getElementById('webfax-recv-name')?.value || '').trim();

          const statusFilters = [];
          document.querySelectorAll('.webfax-status-filter:checked').forEach(chk => {
            statusFilters.push(chk.value);
          });

          return FAX_WEB_HISTORY.filter(row => {
            const sentDate = row.sentAt.split(' ')[0];
            if (dateFrom && sentDate < dateFrom) return false;
            if (dateTo && sentDate > dateTo) return false;
            if (webfaxFilterState.tab === 'recent') {
              const oneYearAgo = new Date();
              oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
              if (new Date(sentDate) < oneYearAgo) return false;
            } else {
              const oneYearAgo = new Date();
              oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
              if (new Date(sentDate) >= oneYearAgo) return false;
            }
            if (senderNo && !row.senderNo.includes(senderNo)) return false;
            if (recvNo && !row.recvNo.includes(recvNo)) return false;
            if (recvCo && !row.recvCompany.includes(recvCo)) return false;
            if (recvName && !row.recvName.includes(recvName)) return false;
            if (statusFilters.length && !statusFilters.includes(row.status)) return false;
            return true;
          }).sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt));
        }

        function renderWebFaxList() {
          const rows = filterWebFaxRows();
          const total = rows.length;
          const { page, pageSize } = webfaxFilterState;
          const totalPages = Math.max(1, Math.ceil(total / pageSize));
          const safePage = Math.min(page, totalPages);
          webfaxFilterState.page = safePage;
          const start = (safePage - 1) * pageSize;
          const pageRows = rows.slice(start, start + pageSize);

          const countEl = document.getElementById('webfax-result-count');
          if (countEl) countEl.textContent = String(total);

          const body = document.getElementById('webfax-table-body');
          if (!body) return;

          if (pageRows.length === 0) {
            body.innerHTML = `<tr><td colspan="10" style="padding:32px;color:#94a3b8;">검색 결과가 없습니다. 검색 조건을 변경해 주세요.</td></tr>`;
          } else {
            body.innerHTML = pageRows.map((row, i) => {
              const statusCls = row.status === 'success' ? 'webfax-status-success'
                : row.status === 'failed' ? 'webfax-status-failed' : 'webfax-status-success';
              const statusLabel = getWebFaxStatusLabel(row.status);
              return `
            <tr>
              <td>${start + i + 1}</td>
              <td class="text-left">${row.sender}<br><span style="color:#64748b;font-size:11px;">${row.senderNo}</span></td>
              <td class="text-left">${row.recvCompany} / ${row.recvName}<br><span style="color:#64748b;font-size:11px;">${row.recvNo}</span></td>
              <td>${row.sentAt}</td>
              <td>${row.completedAt || '-'}</td>
              <td><span class="${statusCls}">${statusLabel}</span></td>
              <td>${row.totalPages}</td>
              <td>${row.successPages}</td>
              <td>${row.failPages}</td>
              <td><button type="button" class="webfax-file-btn" title="${row.fileName}" onclick="toast('📄 ${row.fileName} 미리보기 (웹팩스 연동)')">💾</button></td>
            </tr>`;
            }).join('');
          }

          const pagEl = document.getElementById('webfax-pagination');
          if (pagEl) {
            let html = '';
            for (let p = 1; p <= totalPages; p++) {
              html += `<button type="button" class="webfax-page-btn${p === safePage ? ' active' : ''}" onclick="goWebFaxPage(${p})">${p}</button>`;
            }
            pagEl.innerHTML = html + `<span style="margin-left:12px;color:#64748b;">${pageSize}개씩 보기</span>`;
          }
        }

        function goWebFaxPage(p) {
          webfaxFilterState.page = p;
          renderWebFaxList();
        }

        function searchWebFax() {
          webfaxFilterState.page = 1;
          renderWebFaxList();
        }

        function resetWebFaxSearch() {
          ['webfax-sender-no', 'webfax-recv-no', 'webfax-recv-company', 'webfax-recv-name'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.value = '';
          });
          document.querySelectorAll('.webfax-status-filter').forEach(chk => {
            chk.checked = ['success', 'failed', 'partial'].includes(chk.value);
          });
          searchWebFax();
        }

        function downloadWebFaxExcel() {
          toast('웹팩스 전송내역 엑셀 다운로드 (연동 예정)');
        }

        let retryTargetVid = null;
        let retryFaxTargetVid = null;

        function retrySend(vid) {
          retryTargetVid = vid;
          retryAttachFiles = [];
          const attachListContainer = document.getElementById('retry-attach-list');
          if (attachListContainer) attachListContainer.innerHTML = '';
          const vendor = VENDORS.find(v => v.id === vid) || {};
          const history = SEND_HISTORY.filter(h => h.vendorId === vid).sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt));
          const last = history[0];

          document.getElementById('retry-vname').textContent = vendor.name || '';
          document.getElementById('retry-vceo').textContent = vendor.ceo || '';
          document.getElementById('retry-vtel').value = vendor.tel || '';
          document.getElementById('retry-vemail').value = last ? last.vendorEmail : (vendor.email || '');

          const reasonEl = document.getElementById('retry-fail-reason');
          if (last && last.status === 'failed') {
            reasonEl.style.display = 'block';
            reasonEl.textContent = `⚠️ 최근 실패사유: ${last.failReason || '알 수 없는 오류'}`;
          } else {
            reasonEl.style.display = 'none';
          }

          openModal('retry-send-modal');
        }

        function retryFaxSend(vid) {
          const vendor = VENDORS.find(v => v.id === vid) || {};
          if (!vendor.fax) {
            toast('팩스 번호가 등록되지 않았습니다. 거래처 마스터에서 번호를 등록해 주세요.');
            return;
          }
          retryFaxTargetVid = vid;
          document.getElementById('retry-fax-vname').textContent = vendor.name || VNAMES[vid] || '';
          document.getElementById('retry-fax-no').value = vendor.fax || '';
          const faxSummary = getVendorFaxSummary(vid);
          const hintEl = document.getElementById('retry-fax-hint');
          if (hintEl) {
            hintEl.textContent = faxSummary.code === 'failed'
              ? '최근 팩스 전송이 실패했습니다. 번호 확인 후 웹팩스로 재전송됩니다.'
              : '웹팩스 시스템으로 견적요청서가 재전송됩니다. 전송 결과는 전송내역에서 확인하세요.';
          }
          openModal('retry-fax-modal');
        }

        function confirmRetrySend() {
          const vid = retryTargetVid;
          const newEmail = document.getElementById('retry-vemail').value;
          const newTel = document.getElementById('retry-vtel').value;

          if (!newEmail) { toast('이메일 주소를 입력해주세요.'); return; }

          const fileNames = retryAttachFiles.map(f => f.name).join(', ');

          closeModal('retry-send-modal');
          toast(`${VNAMES[vid]}님께 메일 재발송 중...`);

          setTimeout(() => {
            const now = new Date();
            const dateStr = now.getFullYear() + '-' +
              String(now.getMonth() + 1).padStart(2, '0') + '-' +
              String(now.getDate()).padStart(2, '0') + ' ' +
              String(now.getHours()).padStart(2, '0') + ':' +
              String(now.getMinutes()).padStart(2, '0');

            SEND_HISTORY.push({
              id: SEND_HISTORY.length + 1,
              type: '견적',
              docNo: 'RFQP-2025-0089',
              vendorId: vid,
              vendorEmail: newEmail,
              sentAt: dateStr,
              status: 'success',
              retryCount: SEND_HISTORY.filter(h => h.vendorId === vid).length,
              failReason: fileNames ? '첨부파일: ' + fileNames : '메일 재발송 완료'
            });

            const vendor = VENDORS.find(v => v.id === vid);
            if (vendor) {
              vendor.email = newEmail;
              vendor.tel = newTel;
            }

            renderReplyTable();
            toast(`✅ ${VNAMES[vid]} 메일 재발송 성공!`);
          }, 800);
        }

        function confirmRetryFaxSend() {
          const vid = retryFaxTargetVid;
          const newFax = (document.getElementById('retry-fax-no')?.value || '').trim();
          if (!newFax) { toast('팩스 번호를 입력해주세요.'); return; }

          closeModal('retry-fax-modal');
          toast(`${VNAMES[vid]}님께 팩스 재발송 중... (웹팩스)`);

          setTimeout(() => {
            const now = new Date();
            const dateStr = now.getFullYear() + '-' +
              String(now.getMonth() + 1).padStart(2, '0') + '-' +
              String(now.getDate()).padStart(2, '0') + ' ' +
              String(now.getHours()).padStart(2, '0') + ':' +
              String(now.getMinutes()).padStart(2, '0');
            const v = VENDORS.find(x => x.id === vid) || {};

            FAX_WEB_HISTORY.unshift({
              id: FAX_WEB_HISTORY.length + 1,
              vendorId: vid,
              docNo: 'RFQP-2025-0089',
              sender: WEBFAX_SENDER.name,
              senderNo: WEBFAX_SENDER.no,
              recvCompany: v.name || VNAMES[vid],
              recvName: v.ceo || '',
              recvNo: newFax,
              sentAt: dateStr + ':00',
              completedAt: dateStr + ':30',
              status: 'success',
              totalPages: 3,
              successPages: 3,
              failPages: 0,
              fileName: `RFQP-0089_${(v.name || '').replace(/㈜/g, '')}.pdf`
            });

            if (v.id) v.fax = newFax;

            renderReplyTable();
            toast(`✅ ${VNAMES[vid]} 팩스 재발송 요청 완료! 전송내역에서 확인하세요.`);
          }, 800);
        }

        // ===================== 초기 =====================
        window.addEventListener('DOMContentLoaded', () => {
          init();
          renderReplyTable();
        });
      
setPoListRole('ceo');
