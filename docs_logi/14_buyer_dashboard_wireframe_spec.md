# 14. 구매담당자 수급 터미널 와이어프레임 및 애니메이션 명세서

본 문서는 `buyer_dashboard_simulation.html`에 구현된 UI의 모든 시각적 요소, 레이아웃 규격, 컬러 시스템, 타이포그래피, 상호작용(Interaction) 및 애니메이션을 프론트엔드 개발 단계에서 1:1로 구현할 수 있도록 **최대한 상세하게 작성된 와이어프레임 명세서**입니다.

---

## 1. 글로벌 레이아웃 구조 (Global Layout)
화면은 크게 상단 네비게이션(GNB) 영역과 콘텐츠 영역(사이드바 + 메인 컨테이너)으로 분리됩니다.
- 디바이스 기준: `1440 * 960` 이상의 데스크탑 뷰 최적화
- 최상위 컨테이너: `<div id="app" class="h-screen bg-gray-50 flex flex-col font-sans">`
    - `font-sans`: 기본 브라우저 산세리프 폰트 (예: Inter, Noto Sans KR 등 지원)
    - `bg-gray-50`: `#F9FAFB` 배경색

---

## 2. GNB (Global Navigation Bar)
- **크기 및 배치**: 높이 `64px` (`h-16`), 너비 `100%`, `bg-white` 배경, 하단 `border-b border-gray-200`
- **Flex Layout**: `flex justify-between items-center px-6`

### 2.1 좌측 메뉴 그룹
- 로고: `text-blue-600` (`#2563EB`), `font-bold text-2xl tracking-tighter` (NEO BH)
- 메뉴 항목: 5개의 텍스트 링크 (`flex space-x-8 ml-10`)
  - 기본 상태: `text-gray-500 hover:text-gray-900 font-medium cursor-pointer`
  - 활성 상태 (입출고관리): `text-blue-600 font-bold relative`
    - **Active Indicator**: 메뉴 텍스트 하단에 `<div class="absolute -bottom-5 left-0 w-full h-0.5 bg-blue-600"></div>` 라인(`2px`) 표시

### 2.2 우측 유틸리티 그룹
- **Role Switcher (상단 중앙)**:
  - 컨테이너: `flex bg-gray-100 p-1 rounded-full border border-gray-200`
  - 옵션: '김철수(Owner)' / '이영희(Associate)'
  - 스타일: `px-3 py-1 text-[11px] rounded-full transition-all` (Active: `bg-blue-600 text-white`, Inactive: `text-gray-500`)
- **DEV GUIDE 토글**:
  - 스타일: `px-3 py-1 bg-indigo-100 text-indigo-700 text-[11px] font-bold rounded-full border border-indigo-200 hover:bg-indigo-200`
- **글로벌 거래처명 검색 인풋**:
  - 컨테이너: `relative w-64` (`256px`)
  - 필드: `w-full pl-10 pr-4 py-2 bg-gray-100 border-none rounded-full text-sm focus:ring-2 focus:ring-blue-500 focus:bg-white transition-all`
  - 아이콘: 좌측 `left-3 top-2.5`, `text-gray-400`, `16x16 px SVG 돋보기`
- **알림 및 프로필**: 상동.

---

## 3. LNB 사이드바 (프로젝트 및 발주서 뷰 영역)
좌측에 고정된 프로젝트 및 발주서 필터링 패널입니다. 상단의 뷰 토글을 통해 두 가지 관점으로 목록을 전환할 수 있으며, 사용자가 화면을 넓게 쓰기 위해 `<` `>` 화살표 버튼으로 슬림 모드 전환이 가능합니다.

### 3.1 레이아웃 및 트랜지션
- **상태별 너비**:
  - Open (열림): `w-[260px]`
  - Closed (닫힘): `w-[52px]`
- **애니메이션**: `transition-all duration-300 ease-in-out` 속성을 컨테이너에 부여.
- **외관 스타일**: `bg-white border-r border-gray-200 flex flex-col`

### 3.2 LNB 헤더 및 뷰 토글 영역
- **헤더 영역**: `h-[56px] px-3 py-4 flex items-center`
  - 열림 시 `justify-between`, 닫힘 시 `justify-center`로 배치 반응.
  - 헤더 텍스트 (열림 시): "입출고 수기 터미널" (`font-bold text-[15px] text-gray-800 tracking-tight whitespace-nowrap`).
  - 접기/펼치기 버튼: `<`/`>` SVG 아이콘 버튼 (`hover:bg-gray-100`).
- **뷰 토글 (Segmented Control)**:
  - 헤더 하단에 배치: `px-3 pb-3`
  - 컨테이너: `flex bg-gray-100 p-1 rounded-lg w-full mb-2`
  - 모드 버튼: '프로젝트' / '발주서' 
    - Active 상태: `bg-white text-gray-800 shadow-sm font-bold flex-1 text-center py-1.5 text-[12px] rounded-md transition-all`
    - Inactive 상태: `text-gray-500 hover:text-gray-700 flex-1 text-center py-1.5 text-[12px] font-medium transition-all`

### 3.3 검색 및 리스트 영역 (열림 상태)
- **통합 검색창**: 뷰 토글 하단에 배치. 내부 인풋은 뷰 모드에 맞춰 Placeholder 변경 ('프로젝트 검색' / '발주서 검색'). `text-[12px] pl-8 py-2 bg-gray-50 border border-gray-200 rounded text-gray-700 w-full`
- **데이터 리스트 (Scrollable)**: `flex-1 overflow-y-auto min-w-[260px]`
  - 기본 아이템 컴포넌트: `p-3 min-w-[260px] cursor-pointer border-l-4 transition-colors`
  - 선택(Active) 상태: `bg-blue-50/50 border-blue-500`
  - 미선택(Inactive) 상태: `border-transparent hover:bg-gray-50`
  - **리스트 상세 (프로젝트 뷰)**:
    - **듀얼 진척도**: `flex gap-1 mt-1`
      - 입고: `bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded text-[9px] font-bold` (Blue)
      - 출고: `bg-green-100 text-green-700 px-1.5 py-0.5 rounded text-[9px] font-bold` (Green)
    - 타이틀: "프로젝트 명" (`text-[13px] font-bold text-gray-800`).
  - **리스트 상세 (발주서 뷰)**:
    - 입고 진행률: `bg-blue-100 text-blue-700 px-2 py-0.5 rounded text-[10px] font-bold`.
    - 타이틀: 발주번호 "PO-2023-0801" (`text-[13px] font-bold text-gray-800`).
    - 보조 내용: 거래처명 "삼성전자 외 2건" (`text-[11px] text-gray-500`).

### 3.4 닫힘(Closed) 슬림 텍스트 모드
- `isSidebarOpen === false` 일 때: 리스트 구역을 숨기고(v-show), 중앙에 세로 텍스트 출력.
- 텍스트 컨테이너: `flex-1 flex flex-col items-center pt-8`
- **텍스트 컴포넌트**: `<div class="text-gray-400 font-bold tracking-[0.2em] whitespace-nowrap">`
  - CSS 적용: `writing-mode: vertical-rl; transform: rotate(180deg); text-orientation: mixed;`

---

## 4. 메인 컨테이너 (우측 작업 영역)
사이드바 우측에 위치하며, 하이라이트 요약 대시보드와 데이터 그리드 표를 포함합니다. 전체 뷰는 `flex-1 flex flex-col p-6 overflow-hidden gap-5` 구조입니다.

### 4.1 메인 헤더 타이틀 (입고 처리)
- **높이 및 구성**: `flex items-center justify-between`
- 좌측: 청색 스퀘어 아이콘 (`w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center text-white font-bold text-xl`) 옆에 타이틀 "입고 처리" (`text-[22px] font-bold text-gray-900 tracking-tight`) 및 "SCR-INB-001" (`text-sm text-gray-500`).
- 우측: 시스템 가이드라인 버튼 등 공간 확보.

### 4.2 수급 요약 지표 카드 (3 Columns)
- **컨테이너**: `grid grid-cols-3 gap-6 w-full max-w-7xl mx-auto` (화면 최상단 Sticky 영역 배치)
- **개별 카드 디자인**:
  - `flex items-center justify-between border-gray-200 border-l-4 pl-3 py-1`
  - 좌측 장식 테두리 라인 컬러: `bg-red-500`(지연), `bg-blue-500`(오늘 입고), `bg-green-500`(금주 출고).
  - 타이틀 텍스트: `text-[13px] text-gray-700 font-bold tracking-tight`.
  - 수치: `text-xl font-black` (+ '건/품목' `text-xs font-medium text-gray-400`).

### 4.3 프로젝트/PO별 진행률 카드 (2 Columns - Contextual)
- **출력 조건**: 좌측 LNB에서 특정 프로젝트 또는 발주서가 선택되었을 때만 그리드 상단에 동적으로 노출.
- **컨테이너**: `grid grid-cols-2 gap-4 shrink-0`
- **디자인**:
  - `bg-white p-4 rounded-lg shadow-sm border border-gray-200 flex justify-between items-center relative overflow-hidden`
  - 좌측 장식 테두리: `bg-blue-500`(입고 진행률), `bg-green-500`(출고 진행률).
  - 수치: `text-3xl font-black` (+ '%' `text-sm font-medium text-gray-400`).

---

## 5. 핵심: 하단 데이터 그리드 컴포넌트 (Tree Table)
가장 많은 상호작용이 일어나는 계층형 엑셀 표(그리드) 영역입니다.

### 5.1 그리드 구조 (Grid Box)
- **메인 컨테이너**: `flex-1 bg-white rounded-lg shadow-sm border border-gray-200 flex flex-col min-h-0 overflow-hidden`
- **레이아웃 비례**: 
  - **Project View (13 Columns)**: `grid-template-columns: 30px 2fr 1.2fr 1fr 1fr 1fr 80px 100px 90px 80px 90px 100px 2fr`
  - **PO View (11 Columns)**: 출고 관련 2개 열(출고실행, 출고일자) 제외 후 자동 배분.

### 5.2 헤더 로우 (Header Row)
- 설정: `h-[46px] bg-gray-50 border-b border-gray-200 flex items-center shrink-0`
- 폰트: `text-[12px] font-bold text-gray-600` (입력 가능한 열은 `text-blue-600` 색상).
- 입력 가능 열 구분을 위해 '입고수량', '출고수량' 등의 텍스트 끝에 ✏️ (Pencil Emoji)나 Edit 아이콘 추가.

### 5.3 계층별 로우 (Level 1, 2, 3) 렌더링 스타일
> 각 행 밑바닥에 실선/점선 속성으로 뎁스(Depth)를 표현합니다. 모든 셀 높이는 `items-center`를 갖춘 Grid 구조 안에서 처리됩니다.

#### Level 1 (프로젝트/공고 Row)
- **높이 및 색상**: `h-[42px] bg-gray-50 border-b border-gray-200 hover:bg-gray-100 cursor-pointer`
- **텍스트**: "[프로젝트/공고 명]" (`text-blue-600 font-bold text-[13px]`). 좌측 토글 기호(▼) 렌더링.
- **메타데이터**: "수급률: 100%" (`text-gray-500 text-[12px]`).

#### Level 2 (거래처/발주서(PO) Row)
- **높이 및 색상**: `h-[40px] bg-white border-b border-gray-100` (hover 시 반응 없음, 그룹핑 용도)
- **텍스트**: "[발주서 번호]" (`text-gray-900 font-bold text-[13px]`).
- **[일괄입력] 버튼**: 
  - 배치 위치: Level 2 행의 10번째 또는 11번째 컬럼 영역 (Flex box로 우측 정렬). 
  - 외관: `px-2 py-1 text-[11px] font-medium text-gray-500 bg-white border border-gray-200 rounded hover:bg-gray-50 hover:text-blue-600 transition-colors`.

#### Level 3 (실물 품목 Item Row : Inline Editing Area)
- **높이 및 색상**: `min-h-[44px] bg-white border-b border-gray-100 border-dashed hover:bg-blue-50/30 transition-colors`
- **Over-delivery Highlight**: `item.inboundQty > item.poQty` 인 경우 해당 셀(입고수량) 배경색을 `bg-[#818CF8]` (Indigo 400), 텍스트 `text-white`로 변경. 우측 상단에 'OVER' 배지 출력.
- **Locking Layer (Associate Role)**: 타 담당자 품목인 경우 `relative overflow-hidden` 컨테이너 위에 사선 스트라이프 가상 요소(`::after`) 오버레이.
  - 스타일: `background-image: repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(229, 231, 235, 0.4) 10px, rgba(229, 231, 235, 0.4) 20px)`

### 5.4 인라인 편집 (Inline Edit) 폼 필드
- **상태 정의 (Dirty Form)**: `item._edited === true` 거나 값이 기존 값과 다를 시 필드 백그라운드를 `bg-yellow-50`으로 변경하고, 테두리 값을 `border-yellow-300`, 텍스트 `text-yellow-800`로 입혀 실시간 변경 여부를 시각적으로 피드백.
- **수량 필드 (수량 Input)**: 
  - `w-full h-[28px] border rounded text-center text-[12px] font-bold text-gray-700 bg-white outline-none focus:ring-2 focus:ring-blue-400 focus:border-blue-400`
- **일자 필드 (Date Input)**: 
  - `<input type="date">` 사용. `w-full text-[11px] `. 
  - 특정일 이전 날짜를 지연 상태로 간주할 경우 클래스 조건부 렌더: `:class="item.dueDate < '오늘날짜' ? 'text-red-500 font-bold' : ''"`
- **배송비 필드**: 
  - 단위 우측 정렬(`text-right`). 천단위 콤마(,) 서식화된 텍스트 출력(예: `20,000`).
- **비고 필드 (Note Overlay UI)**: 
  - 공간 파괴 방지 레이아웃. `relative items-center flex h-full min-h-[28px] min-w-0`.
  - 기본 뷰: `<div class="truncate text-[11px] text-gray-700 cursor-text p-1 hover:bg-white hover:border-gray-200 border border-transparent">`
  - 커서 진입 / 클릭 시: DOM 트리를 대체하여 `<input type="text" class="absolute left-1 right-1 top-[3px] bottom-[3px] z-10 border border-blue-400 shadow-sm rounded px-1.5 ...">` 텍스트 필드를 올려 포커스가 해제될 때(Blur/Enter)까지 편집되게 구현.

---

## 6. 빈 상태 (Empty States) 디자인

### 6.1 '글로벌 거래처 검색 결과' 없음
- **출력 조건**: 상단 헤더의 검색창에 값을 입력했으나 해당하는 데이터가 아무 프로젝트에도 없을 때 메인 그리드 영역에 단독 표시 (Tree 행 삭제).
- **컴포넌트**: `flex-1 bg-white rounded-lg flex flex-col items-center justify-center text-gray-500`
- **구조**:
  1. 이모지/아이콘: `<div class="text-4xl mb-3">🔍</div>`
  2. 큰 텍스트: `<div class="text-lg font-medium text-gray-600 mb-1">검색 결과가 없습니다</div>`
  3. 작은 텍스트: "입력하신 거래처명에 일치하는 발주서가 존재하지 않습니다."

### 6.2 '선택된 데이터' 없음
- **출력 조건**: 사용자가 좌측 LNB 사이드바에서 아무 목록도 클릭하지 않은 초기 화면 구성 시.
- **컴포넌트 구성**:
  1. 이모지/아이콘: `<div class="text-4xl mb-3">📋</div>`
  2. 큰 텍스트: `<div class="text-lg font-medium text-gray-600 mb-1">항목을 선택하세요</div>`
  3. 작은 텍스트: "좌측 목록에서 현황을 확인할 프로젝트 또는 발주서를 클릭해주세요."

---

## 7. Auto-Save 토스트 알림 (애니메이션 명세)

버튼 [저장] 없이 실시간 Auto-Save 작동 및 사용자에게 시각적 안정감을 주도록 화면 우측 하단에 플로팅 알람 출력.

### 7.1 컨테이너 컴포넌트 규격
- **Postion & Z-index**: `fixed bottom-6 right-6 z-50`
- **외관**: `bg-gray-800 text-white px-4 py-3 rounded-lg shadow-lg flex items-center pointer-events-none`
- **콘텐츠**: `<svg>` 체크마크 요소(`text-green-400`) + **"입력 내용이 자동 저장되었습니다"** 텍스트 (`font-bold text-sm`).

### 7.2 애니메이션 매개변수 (Vue Transition)
Vue.js 의 `<transition>` 태그를 이용한 부드러운 Fade In/Out 및 Slide Up 효과.
- **Enter (등장)**: 
  - `enter-active-class="transition ease-out duration-300 transform"`
  - `enter-from-class="translate-y-2 opacity-0"`
  - `enter-to-class="translate-y-0 opacity-100"`
- **Leave (퇴장)**:
  - `leave-active-class="transition ease-in duration-200 transform"`
  - `leave-from-class="translate-y-0 opacity-100"`
  - `leave-to-class="translate-y-2 opacity-0"`

### 7.3 이벤트 타이밍
- 사용자가 `blur` 이벤트로 Input 박스를 빠져나가거나 Enter를 칠 때 즉시 `showSaveToast = true` 트리거.
- 내장 `setTimeout` 함수로 2초 (2000ms) 동안 화면에 유지된 후 `showSaveToast = false` 처리되어 사라짐. (연속 반복 입력 시 Timeout 타이머 갱신 처리).

---

## 8. 개발자 가이드 (Sticky Memo) 시스템
- **활성화 조건**: `showDevGuide === true` 인 경우 메인 화면 주요 컴포넌트 근처에 고정 메모 노출.
- **메모 디자인**:
  - `bg-yellow-100 border-l-4 border-yellow-400 p-2 text-[11px] text-yellow-800 shadow-sm max-w-[200px] z-20`
  - 수정 가능 여부: 메모 텍스트 클릭 시 직접 타이핑하여 시뮬레이션 기획 수정 가능.
